import { describe, expect, it, vi } from 'vitest';

import { buildOpenAICompatibleRequest, createFoodVisionProvider, OpenAICompatibleFoodVisionProvider } from '../../server/food-insight/providers';
import { validateFoodInsight } from '../../server/food-insight/validate-food-insight';

const plausible = { detectedKind: 'food', rating: 4, confidence: 0.8, reasonCode: 'plausible_food', insightSentences: ['Pilihan tampak cukup sesuai dengan panduan program.'] };

describe('food_rating_policy_v1', () => {
  it.each([
    [1, 0.89, 'not_food_for_required_food', true],
    [1, 0.9, 'not_food_for_required_food', false],
    [2, 0.99, 'severe_explicit_rubric_mismatch', false],
    [2, 0.9, 'plausible_food', true],
    [1, 0.95, 'provider_invented_reason', true],
  ])('clamps rating %s unless the exact severe condition is met', (rating, confidence, reasonCode, expectedClamp) => {
    const result = validateFoodInsight({ ...plausible, detectedKind: rating === 1 ? 'not_food' : 'food', rating, confidence, reasonCode }, true);
    expect(result.rating === 3).toBe(expectedClamp);
  });

  it('permits both severe reason codes only at confidence 0.90 with explicit rubric', () => {
    expect(validateFoodInsight({ ...plausible, detectedKind: 'not_food', rating: 1, confidence: 0.9, reasonCode: 'not_food_for_required_food' }, true).rating).toBe(1);
    expect(validateFoodInsight({ ...plausible, rating: 2, confidence: 0.9, reasonCode: 'severe_explicit_rubric_mismatch' }, true).rating).toBe(2);
    expect(validateFoodInsight({ ...plausible, rating: 2, confidence: 1, reasonCode: 'severe_explicit_rubric_mismatch' }, false).rating).toBe(3);
    expect(validateFoodInsight({ ...plausible, rating: 1, confidence: 1, reasonCode: 'not_food_for_required_food' }, true).rating).toBe(3);
    expect(validateFoodInsight({ ...plausible, detectedKind: 'not_food', rating: 2, confidence: 1, reasonCode: 'severe_explicit_rubric_mismatch' }, true).rating).toBe(3);
  });

  it('uses 4 as plausible default, 5 only for strong published rubric, and 3 for ambiguity', () => {
    expect(validateFoodInsight(plausible, false).rating).toBe(4);
    expect(validateFoodInsight({ ...plausible, rating: 5, reasonCode: 'plausible_food' }, true).rating).toBe(4);
    expect(validateFoodInsight({ ...plausible, rating: 5, reasonCode: 'strong_rubric_match' }, true).rating).toBe(5);
    expect(validateFoodInsight({ ...plausible, detectedKind: 'uncertain', rating: 3, reasonCode: 'ambiguous_or_mixed' }, false).rating).toBe(3);
  });

  it.each([
    [['This meal is healthy and safe.']],
    [['Foto cukup jelas.', 'This looks balanced.']],
    [['Kalimat ini sangat panjang dan sengaja melewati delapan puluh karakter agar validator menggunakan fallback Bahasa Indonesia yang deterministik.']],
    [['Makanan ini aman dikonsumsi.']],
  ])('replaces unsafe, mixed-language, English, or overlong copy', (insightSentences) => {
    const result = validateFoodInsight({ ...plausible, insightSentences }, false);
    expect(result.insight_sentences).toEqual(['Pilihan pada foto tampak cukup sesuai dengan panduan program.']);
  });

  it('accepts optional macro values and rejects values outside the schema range', () => {
    const result = validateFoodInsight({ ...plausible, proteinGrams: 25, fatGrams: 12 }, false);
    expect(result).toMatchObject({ protein_grams: 25, carbohydrate_grams: null, fat_grams: 12, calorie_kcal: null });
    expect(() => validateFoodInsight({ ...plausible, carbohydrateGrams: -1 }, false)).toThrow('invalid_output');
    expect(() => validateFoodInsight({ ...plausible, calorieKcal: 99999 }, false)).toThrow('invalid_output');
    expect(() => validateFoodInsight({ ...plausible, detectedKind: 'dessert' }, false)).toThrow('invalid_output');
    expect(() => validateFoodInsight({ ...plausible, rating: 6 }, false)).toThrow('invalid_output');
  });
});

describe('FoodVisionProvider contract', () => {
  it.each(['food', 'drink', 'shake', 'not_food', 'ambiguous', 'invalid'])('returns deterministic %s fixture', async (scenario) => {
    const provider = createFoodVisionProvider({ FOOD_AI_PROVIDER: 'fake', FOOD_AI_FAKE_SCENARIO: scenario });
    const result = await provider.analyze({ imageBytes: new Uint8Array([1]), mimeType: 'image/jpeg' });
    expect(result.detectedKind).toBeDefined();
  });

  it('reads model from environment and sends structured image request with reasoning disabled and output cap', async () => {
    const request = buildOpenAICompatibleRequest('vendor/alternate-model', { imageBytes: new Uint8Array([1, 2]), mimeType: 'image/jpeg', rubric: 'Ada sayur dan protein.' });
    expect(request.model).toBe('vendor/alternate-model');
    expect(request.reasoning).toEqual({ effort: 'none', exclude: true });
    expect(request.max_tokens).toBe(350);
    expect(request.response_format.json_schema.strict).toBe(true);
    expect(JSON.stringify(request)).toContain('data:image/jpeg;base64,');
    expect(JSON.stringify(request)).not.toContain('submission_id');
    expect(JSON.stringify(request)).not.toContain('private_photo_path');
  });

  it('switches compatible endpoints and models through configuration only', async () => {
    const fetcher = vi.fn(async () => new Response(JSON.stringify({ choices: [{ message: { content: JSON.stringify(plausible) } }] }), { status: 200 }));
    const first = createFoodVisionProvider({ FOOD_AI_PROVIDER: 'openai_compatible', FOOD_AI_BASE_URL: 'https://one.example/v1', FOOD_AI_API_KEY: 'runtime-only', FOOD_AI_MODEL: 'one/model' }, fetcher);
    const second = createFoodVisionProvider({ FOOD_AI_PROVIDER: 'openai_compatible', FOOD_AI_BASE_URL: 'https://two.example/v1', FOOD_AI_API_KEY: 'runtime-only', FOOD_AI_MODEL: 'two/model' }, fetcher);
    await first.analyze({ imageBytes: new Uint8Array([1]), mimeType: 'image/jpeg' });
    await second.analyze({ imageBytes: new Uint8Array([1]), mimeType: 'image/jpeg' });
    const calls = fetcher.mock.calls as unknown as Array<[string]>;
    expect(calls[0]?.[0]).toBe('https://one.example/v1/chat/completions');
    expect(calls[1]?.[0]).toBe('https://two.example/v1/chat/completions');
    expect(first.modelAlias).toBe('one/model'); expect(second.modelAlias).toBe('two/model');
  });

  it('fails incompatible configuration only at provider boundary', async () => {
    expect(() => createFoodVisionProvider({})).toThrow('configuration_invalid');
    expect(() => createFoodVisionProvider({ FOOD_AI_PROVIDER: 'universal-api-key' })).toThrow('configuration_invalid');
    const provider = new OpenAICompatibleFoodVisionProvider({ baseUrl: '', apiKey: '', model: '', fetcher: fetch });
    await expect(provider.preflight()).rejects.toThrow('configuration_invalid');
  });

  it.each([
    [429, 'rate_limited'],
    [503, 'provider_unavailable'],
  ])('maps provider HTTP %s to a typed safe failure', async (status, code) => {
    const provider = new OpenAICompatibleFoodVisionProvider({ baseUrl: 'https://provider.example/v1', apiKey: 'runtime-only', model: 'fixture/model', fetcher: vi.fn(async () => new Response('', { status })) });
    await expect(provider.analyze({ imageBytes: new Uint8Array([1]), mimeType: 'image/jpeg' })).rejects.toThrow(code);
  });

  it('maps malformed provider JSON to invalid_output', async () => {
    const fetcher = vi.fn(async () => new Response(JSON.stringify({ choices: [{ message: { content: '{not-json' } }] }), { status: 200 }));
    const provider = new OpenAICompatibleFoodVisionProvider({ baseUrl: 'https://provider.example/v1', apiKey: 'runtime-only', model: 'fixture/model', fetcher });
    await expect(provider.analyze({ imageBytes: new Uint8Array([1]), mimeType: 'image/jpeg' })).rejects.toThrow('invalid_output');
  });
});
