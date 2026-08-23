import { describe, expect, it, vi } from 'vitest';

import { buildOpenAICompatibleRequest, createFoodVisionProvider, OpenAICompatibleFoodVisionProvider } from '../../../supabase/functions/_shared/food-insight/providers';
import { validateFoodInsight } from '../../../supabase/functions/_shared/food-insight/validate-food-insight';

const plausible = {
  detectedKind: 'food',
  proteinGrams: 25,
  carbohydrateGrams: 40,
  fatGrams: 12,
  calorieKcal: 370,
  confidence: 0.8,
  insightSentences: ['Foto tampak menunjukkan nasi, lauk, dan sayuran.'],
};

describe('food_rating_policy_v2_image_only', () => {
  it.each([
    ['food', 4, 'food_or_drink_detected'],
    ['drink', 4, 'food_or_drink_detected'],
    ['shake', 4, 'shake_detected'],
    ['uncertain', 3, 'image_uncertain'],
    ['not_food', 1, 'not_food_detected'],
  ] as const)('derives rating and reason only from detected image kind %s', (detectedKind, rating, reasonCode) => {
    const result = validateFoodInsight({ ...plausible, detectedKind });
    expect(result).toMatchObject({ detected_kind: detectedKind, rating, reason_code: reasonCode });
  });

  it('normalizes every detected shake to the approved estimate', () => {
    const result = validateFoodInsight({
      ...plausible,
      detectedKind: 'shake',
      proteinGrams: 80,
      carbohydrateGrams: 90,
      fatGrams: 30,
      calorieKcal: 900,
      insightSentences: ['Shake tampak sesuai dengan kebutuhan langkah.'],
    });
    expect(result).toMatchObject({
      detected_kind: 'shake',
      protein_grams: 10,
      carbohydrate_grams: 3,
      fat_grams: 1,
      calorie_kcal: 100,
      insight_sentences: ['Foto tampak menunjukkan satu porsi shake.'],
    });
  });

  it.each([
    [['Foto sesuai dengan kebutuhan langkah.']],
    [['Pilihan ini cocok dengan panduan program.']],
    [['This meal is healthy and safe.']],
    [['Makanan ini aman dikonsumsi.']],
    [['Kalimat ini sangat panjang dan sengaja melewati delapan puluh karakter agar validator menggunakan fallback Bahasa Indonesia yang deterministik.']],
  ])('replaces contextual, unsafe, English, or overlong model copy', (insightSentences) => {
    const result = validateFoodInsight({ ...plausible, insightSentences });
    expect(result.insight_sentences).toEqual(['Foto tampak menunjukkan satu porsi makanan.']);
  });

  it('clears macro estimates when the image is not food or remains uncertain', () => {
    for (const detectedKind of ['not_food', 'uncertain'] as const) {
      const result = validateFoodInsight({ ...plausible, detectedKind });
      expect(result).toMatchObject({
        protein_grams: null,
        carbohydrate_grams: null,
        fat_grams: null,
        calorie_kcal: null,
      });
      expect(result.insight_sentences.join(' ')).not.toMatch(/kebutuhan|langkah|program|panduan/iu);
    }
  });

  it('accepts optional image estimates and rejects invalid provider values', () => {
    const result = validateFoodInsight({ ...plausible, carbohydrateGrams: undefined, calorieKcal: undefined });
    expect(result).toMatchObject({ protein_grams: 25, carbohydrate_grams: null, fat_grams: 12, calorie_kcal: null });
    expect(() => validateFoodInsight({ ...plausible, carbohydrateGrams: -1 })).toThrow('invalid_output');
    expect(() => validateFoodInsight({ ...plausible, calorieKcal: 99999 })).toThrow('invalid_output');
    expect(() => validateFoodInsight({ ...plausible, detectedKind: 'dessert' })).toThrow('invalid_output');
    expect(() => validateFoodInsight({ ...plausible, confidence: 2 })).toThrow('invalid_output');
  });
});

describe('FoodVisionProvider contract', () => {
  it.each(['food', 'drink', 'shake', 'not_food', 'ambiguous', 'invalid'])('returns deterministic %s fixture', async (scenario) => {
    const provider = createFoodVisionProvider({ FOOD_AI_PROVIDER: 'fake', FOOD_AI_FAKE_SCENARIO: scenario });
    const result = await provider.analyze({ imageBytes: new Uint8Array([1]), mimeType: 'image/jpeg' });
    expect(result.detectedKind).toBeDefined();
  });

  it('sends only a generic image-analysis instruction and image bytes', () => {
    const request = buildOpenAICompatibleRequest(
      ['vendor/primary-model', 'vendor/fallback-model'],
      { imageBytes: new Uint8Array([1, 2]), mimeType: 'image/jpeg' },
    );
    const serialized = JSON.stringify(request);
    expect(request.models).toEqual(['vendor/primary-model', 'vendor/fallback-model']);
    expect(request).not.toHaveProperty('reasoning');
    expect(request.max_tokens).toBe(350);
    expect(request.response_format.json_schema.strict).toBe(true);
    expect(request.response_format.json_schema.schema.required).toEqual(['detectedKind', 'confidence', 'insightSentences']);
    expect(request.provider).toEqual({
      require_parameters: true,
      sort: 'price',
      max_price: { prompt: 0.10, completion: 0.40 },
    });
    expect(serialized).toContain('data:image/jpeg;base64,');
    for (const forbidden of [
      'Ada sayur dan protein.', 'submission_id', 'private_photo_path',
      'analysis_rubric', 'rubricVersion', 'question_id',
    ]) expect(serialized).not.toContain(forbidden);
  });

  it('switches compatible endpoints and models through configuration only', async () => {
    let requestIndex = 0;
    const selectedModels = ['one/selected', 'two/selected'];
    const fetcher = vi.fn(async () => new Response(JSON.stringify({ model: selectedModels[requestIndex++], choices: [{ message: { content: JSON.stringify(plausible) } }] }), { status: 200 }));
    const first = createFoodVisionProvider({ FOOD_AI_PROVIDER: 'openai_compatible', FOOD_AI_BASE_URL: 'https://one.example/v1', FOOD_AI_API_KEY: 'runtime-only', FOOD_AI_MODELS: '["one/primary","one/fallback"]' }, fetcher);
    const second = createFoodVisionProvider({ FOOD_AI_PROVIDER: 'openai_compatible', FOOD_AI_BASE_URL: 'https://two.example/v1', FOOD_AI_API_KEY: 'runtime-only', FOOD_AI_MODEL: 'two/model' }, fetcher);
    await first.analyze({ imageBytes: new Uint8Array([1]), mimeType: 'image/jpeg' });
    await second.analyze({ imageBytes: new Uint8Array([1]), mimeType: 'image/jpeg' });
    const calls = fetcher.mock.calls as unknown as Array<[string]>;
    expect(calls[0]?.[0]).toBe('https://one.example/v1/chat/completions');
    expect(calls[1]?.[0]).toBe('https://two.example/v1/chat/completions');
    expect(first.modelAlias).toBe('one/selected');
    expect(second.modelAlias).toBe('two/selected');
  });

  it('rejects malformed or empty model fallback configuration', () => {
    for (const FOOD_AI_MODELS of ['not-json', '[]', '["invalid"]', '["one/model",3]']) {
      expect(() => createFoodVisionProvider({
        FOOD_AI_PROVIDER: 'openai_compatible',
        FOOD_AI_BASE_URL: 'https://provider.example/v1',
        FOOD_AI_API_KEY: 'runtime-only',
        FOOD_AI_MODELS,
      })).toThrow('configuration_invalid');
    }
  });

  it('fails incompatible configuration only at provider boundary', async () => {
    expect(() => createFoodVisionProvider({})).toThrow('configuration_invalid');
    expect(() => createFoodVisionProvider({ FOOD_AI_PROVIDER: 'universal-api-key' })).toThrow('configuration_invalid');
    const provider = new OpenAICompatibleFoodVisionProvider({ baseUrl: '', apiKey: '', models: [], fetcher: fetch });
    await expect(provider.preflight()).rejects.toThrow('configuration_invalid');
  });

  it.each([
    [429, 'rate_limited'],
    [503, 'provider_unavailable'],
  ])('maps provider HTTP %s to a typed safe failure', async (status, code) => {
    const provider = new OpenAICompatibleFoodVisionProvider({ baseUrl: 'https://provider.example/v1', apiKey: 'runtime-only', models: ['fixture/model'], fetcher: vi.fn(async () => new Response('', { status })) });
    await expect(provider.analyze({ imageBytes: new Uint8Array([1]), mimeType: 'image/jpeg' })).rejects.toThrow(code);
  });

  it('maps malformed provider JSON to invalid_output', async () => {
    const fetcher = vi.fn(async () => new Response(JSON.stringify({ choices: [{ message: { content: '{not-json' } }] }), { status: 200 }));
    const provider = new OpenAICompatibleFoodVisionProvider({ baseUrl: 'https://provider.example/v1', apiKey: 'runtime-only', models: ['fixture/model'], fetcher });
    await expect(provider.analyze({ imageBytes: new Uint8Array([1]), mimeType: 'image/jpeg' })).rejects.toMatchObject({
      message: 'invalid_output',
      retryable: true,
    });
  });
});
