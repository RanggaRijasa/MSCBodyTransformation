import type { FoodVisionInput, FoodVisionProvider, RawFoodVisionResult } from './contracts';
import { FoodVisionProviderError } from './contracts';

export type FoodProviderEnvironment = Readonly<{
  FOOD_AI_PROVIDER?: string;
  FOOD_AI_BASE_URL?: string;
  FOOD_AI_API_KEY?: string;
  FOOD_AI_MODEL?: string;
  FOOD_AI_FAKE_SCENARIO?: string;
}>;

export function createFoodVisionProvider(environment: FoodProviderEnvironment, fetcher: typeof fetch = fetch): FoodVisionProvider {
  if (environment.FOOD_AI_PROVIDER === 'fake') {
    return new DeterministicFakeFoodVisionProvider(environment.FOOD_AI_FAKE_SCENARIO ?? 'food');
  }
  if (environment.FOOD_AI_PROVIDER !== 'openai_compatible') {
    throw new FoodVisionProviderError('configuration_invalid', false);
  }
  return new OpenAICompatibleFoodVisionProvider({
    baseUrl: environment.FOOD_AI_BASE_URL ?? 'https://openrouter.ai/api/v1',
    apiKey: environment.FOOD_AI_API_KEY ?? '',
    model: environment.FOOD_AI_MODEL ?? 'google/gemma-4-31b-it:free',
    fetcher,
  });
}

export class DeterministicFakeFoodVisionProvider implements FoodVisionProvider {
  readonly providerName = 'fake';
  readonly modelAlias = 'deterministic-food-fixture-v1';
  constructor(private readonly scenario: string) {}
  async preflight() {}
  async analyze(_input: FoodVisionInput): Promise<RawFoodVisionResult> {
    const fixtures: Record<string, RawFoodVisionResult> = {
      food: { detectedKind: 'food', proteinGrams: 28, carbohydrateGrams: 42, fatGrams: 14, calorieKcal: 410, rating: 4, confidence: 0.84, reasonCode: 'plausible_food', insightSentences: ['Porsi tampak cukup seimbang untuk panduan program.'] },
      drink: { detectedKind: 'drink', carbohydrateGrams: 18, calorieKcal: 90, rating: 4, confidence: 0.82, reasonCode: 'plausible_food', insightSentences: ['Minuman tampak cukup sesuai dengan panduan program.'] },
      shake: { detectedKind: 'shake', proteinGrams: 24, carbohydrateGrams: 20, fatGrams: 5, calorieKcal: 220, rating: 5, confidence: 0.94, reasonCode: 'strong_rubric_match', insightSentences: ['Shake tampak sangat sesuai dengan panduan yang diterbitkan.'] },
      not_food: { detectedKind: 'not_food', rating: 1, confidence: 0.96, reasonCode: 'not_food_for_required_food', insightSentences: ['Foto belum menunjukkan makanan yang diminta.'] },
      ambiguous: { detectedKind: 'uncertain', rating: 3, confidence: 0.51, reasonCode: 'ambiguous_or_mixed', insightSentences: ['Isi foto belum cukup jelas untuk perkiraan yang yakin.'] },
      invalid: { detectedKind: 'food', rating: 1, confidence: 0.2, reasonCode: 'plausible_food', insightSentences: ['This meal is healthy and safe.'] },
    };
    return fixtures[this.scenario] ?? fixtures.food!;
  }
}

type CompatibleProviderConfig = Readonly<{ baseUrl: string; apiKey: string; model: string; fetcher: typeof fetch }>;

export class OpenAICompatibleFoodVisionProvider implements FoodVisionProvider {
  readonly providerName = 'openai_compatible';
  readonly modelAlias: string;
  constructor(private readonly config: CompatibleProviderConfig) { this.modelAlias = config.model; }

  async preflight(): Promise<void> {
    if (!this.config.apiKey || !this.config.model || !/^https?:\/\//u.test(this.config.baseUrl)) {
      throw new FoodVisionProviderError('configuration_invalid', false);
    }
  }

  async analyze(input: FoodVisionInput): Promise<RawFoodVisionResult> {
    await this.preflight();
    const response = await this.config.fetcher(`${this.config.baseUrl.replace(/\/$/u, '')}/chat/completions`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${this.config.apiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify(buildOpenAICompatibleRequest(this.config.model, input)),
    });
    if (response.status === 429) throw new FoodVisionProviderError('rate_limited', true);
    if (!response.ok) throw new FoodVisionProviderError('provider_unavailable', response.status >= 500);
    const body = await response.json() as { choices?: Array<{ message?: { content?: string } }> };
    const content = body.choices?.[0]?.message?.content;
    if (!content) throw new FoodVisionProviderError('invalid_output', false);
    try { return JSON.parse(content) as RawFoodVisionResult; }
    catch { throw new FoodVisionProviderError('invalid_output', false); }
  }
}

export function buildOpenAICompatibleRequest(model: string, input: FoodVisionInput) {
  return {
    model,
    reasoning: { effort: 'none', exclude: true },
    max_tokens: 350,
    messages: [{ role: 'user', content: [
      { type: 'text', text: `Analisis foto secara suportif. Rubrik: ${input.rubric ?? 'Tidak ada rubrik eksplisit'}. Jangan simpulkan diagnosis, alergi, keamanan, karakter, disiplin, atau bentuk tubuh.` },
      { type: 'image_url', image_url: { url: `data:${input.mimeType};base64,${bytesToBase64(input.imageBytes)}` } },
    ] }],
    response_format: { type: 'json_schema', json_schema: { name: 'food_insight', strict: true, schema: foodInsightSchema } },
  };
}

const foodInsightSchema = {
  type: 'object', additionalProperties: false,
  required: ['detectedKind', 'rating', 'confidence', 'reasonCode', 'insightSentences'],
  properties: {
    detectedKind: { type: 'string', enum: ['food', 'drink', 'shake', 'not_food', 'uncertain'] },
    proteinGrams: { type: ['number', 'null'], minimum: 0, maximum: 1000 },
    carbohydrateGrams: { type: ['number', 'null'], minimum: 0, maximum: 1000 },
    fatGrams: { type: ['number', 'null'], minimum: 0, maximum: 1000 },
    calorieKcal: { type: ['number', 'null'], minimum: 0, maximum: 10000 },
    rating: { type: 'integer', minimum: 1, maximum: 5 },
    confidence: { type: 'number', minimum: 0, maximum: 1 },
    reasonCode: { type: 'string', enum: ['strong_rubric_match', 'plausible_food', 'ambiguous_or_mixed', 'not_food_for_required_food', 'severe_explicit_rubric_mismatch'] },
    insightSentences: { type: 'array', minItems: 1, maxItems: 2, items: { type: 'string', maxLength: 80 } },
  },
} as const;

function bytesToBase64(bytes: Uint8Array): string {
  if (typeof Buffer !== 'undefined') return Buffer.from(bytes).toString('base64');
  let binary = ''; for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary);
}
