import type { FoodVisionInput, FoodVisionProvider, RawFoodVisionResult } from './contracts.ts';
import { FoodVisionProviderError } from './contracts.ts';

export type FoodProviderEnvironment = Readonly<{
  FOOD_AI_PROVIDER?: string;
  FOOD_AI_BASE_URL?: string;
  FOOD_AI_API_KEY?: string;
  FOOD_AI_MODELS?: string;
  FOOD_AI_MODEL?: string;
  FOOD_AI_FAKE_SCENARIO?: string;
}>;

export function createFoodVisionProvider(
  environment: FoodProviderEnvironment,
  fetcher: typeof fetch = fetch,
): FoodVisionProvider {
  if (environment.FOOD_AI_PROVIDER === 'fake') {
    return new DeterministicFakeFoodVisionProvider(
      environment.FOOD_AI_FAKE_SCENARIO ?? 'food',
    );
  }
  if (environment.FOOD_AI_PROVIDER !== 'openai_compatible') {
    throw new FoodVisionProviderError('configuration_invalid', false);
  }
  return new OpenAICompatibleFoodVisionProvider({
    baseUrl: environment.FOOD_AI_BASE_URL ?? 'https://openrouter.ai/api/v1',
    apiKey: environment.FOOD_AI_API_KEY ?? '',
    models: parseConfiguredModels(environment),
    fetcher,
  });
}

const defaultModels = [
  'google/gemma-4-26b-a4b-it',
  'google/gemma-3-12b-it',
] as const;

function parseConfiguredModels(environment: FoodProviderEnvironment): string[] {
  const configuredModels = environment.FOOD_AI_MODELS?.trim();
  if (configuredModels) {
    try {
      const parsed = JSON.parse(configuredModels) as unknown;
      if (!Array.isArray(parsed) || parsed.length < 1 || parsed.length > 3
        || !parsed.every((model) => typeof model === 'string' && /^[a-z0-9_.-]+\/[a-z0-9_.:-]+$/u.test(model))) {
        throw new Error('invalid_models');
      }
      return [...new Set(parsed)];
    } catch {
      throw new FoodVisionProviderError('configuration_invalid', false);
    }
  }
  const legacyModel = environment.FOOD_AI_MODEL?.trim();
  return legacyModel ? [legacyModel] : [...defaultModels];
}

export class DeterministicFakeFoodVisionProvider implements FoodVisionProvider {
  readonly providerName = 'fake';
  readonly modelAlias = 'deterministic-food-fixture-v1';
  constructor(private readonly scenario: string) {}
  async preflight() {}
  async analyze(_input: FoodVisionInput): Promise<RawFoodVisionResult> {
    const fixtures: Record<string, RawFoodVisionResult> = {
      food: { detectedKind: 'food', proteinGrams: 28, carbohydrateGrams: 42, fatGrams: 14, calorieKcal: 410, confidence: 0.84, insightSentences: ['Foto tampak menunjukkan satu porsi makanan.'] },
      drink: { detectedKind: 'drink', carbohydrateGrams: 18, calorieKcal: 90, confidence: 0.82, insightSentences: ['Foto tampak menunjukkan satu porsi minuman.'] },
      shake: { detectedKind: 'shake', proteinGrams: 24, carbohydrateGrams: 20, fatGrams: 5, calorieKcal: 220, confidence: 0.94, insightSentences: ['Foto tampak menunjukkan satu porsi shake.'] },
      not_food: { detectedKind: 'not_food', confidence: 0.96, insightSentences: ['Makanan atau minuman belum dapat dikenali dari foto.'] },
      ambiguous: { detectedKind: 'uncertain', confidence: 0.51, insightSentences: ['Isi foto belum cukup jelas untuk membuat perkiraan.'] },
      invalid: { detectedKind: 'dessert', confidence: 0.2, insightSentences: ['This meal is healthy and safe.'] },
    };
    return fixtures[this.scenario] ?? fixtures.food!;
  }
}

type CompatibleProviderConfig = Readonly<{
  baseUrl: string;
  apiKey: string;
  models: readonly string[];
  fetcher: typeof fetch;
}>;

export class OpenAICompatibleFoodVisionProvider implements FoodVisionProvider {
  readonly providerName = 'openai_compatible';
  private selectedModel: string | undefined;
  constructor(private readonly config: CompatibleProviderConfig) {}

  get modelAlias(): string {
    return this.selectedModel ?? this.config.models.join(' -> ');
  }

  async preflight(): Promise<void> {
    if (!this.config.apiKey || this.config.models.length < 1 || !/^https?:\/\//u.test(this.config.baseUrl)) {
      throw new FoodVisionProviderError('configuration_invalid', false);
    }
  }

  async analyze(input: FoodVisionInput): Promise<RawFoodVisionResult> {
    await this.preflight();
    const response = await this.config.fetcher(
      `${this.config.baseUrl.replace(/\/$/u, '')}/chat/completions`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${this.config.apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(buildOpenAICompatibleRequest(this.config.models, input)),
      },
    );
    if (response.status === 429) throw new FoodVisionProviderError('rate_limited', true);
    if (!response.ok) {
      throw new FoodVisionProviderError('provider_unavailable', response.status >= 500);
    }
    const body = await response.json() as {
      model?: string;
      choices?: Array<{ message?: { content?: string } }>;
    };
    if (typeof body.model === 'string' && /^[a-z0-9_.-]+\/[a-z0-9_.:-]+$/u.test(body.model)) {
      this.selectedModel = body.model;
    }
    const content = body.choices?.[0]?.message?.content;
    if (!content) throw new FoodVisionProviderError('invalid_output', true);
    try {
      return JSON.parse(content) as RawFoodVisionResult;
    } catch {
      throw new FoodVisionProviderError('invalid_output', true);
    }
  }
}

export function buildOpenAICompatibleRequest(models: readonly string[], input: FoodVisionInput) {
  return {
    models,
    max_tokens: 350,
    messages: [{
      role: 'user',
      content: [
        { type: 'text', text: 'Analisis hanya isi visual foto ini. Identifikasi makanan, minuman, shake atau protein shake, bukan makanan, atau gambar yang tidak pasti. Perkirakan makronutrien dan kalori hanya dari objek yang terlihat. Jangan membandingkan foto dengan pertanyaan, langkah, tugas, program, panduan, target diet, atau kebutuhan apa pun. Jangan menilai kepatuhan. Jangan simpulkan diagnosis, alergi, keamanan, karakter, disiplin, atau bentuk tubuh. Tulis insight singkat dalam Bahasa Indonesia hanya tentang objek pada foto.' },
        { type: 'image_url', image_url: { url: `data:${input.mimeType};base64,${bytesToBase64(input.imageBytes)}` } },
      ],
    }],
    response_format: {
      type: 'json_schema',
      json_schema: { name: 'food_insight', strict: true, schema: foodInsightSchema },
    },
    provider: {
      require_parameters: true,
      sort: 'price',
      max_price: { prompt: 0.10, completion: 0.40 },
    },
  };
}

const foodInsightSchema = {
  type: 'object',
  additionalProperties: false,
  required: ['detectedKind', 'confidence', 'insightSentences'],
  properties: {
    detectedKind: { type: 'string', enum: ['food', 'drink', 'shake', 'not_food', 'uncertain'] },
    proteinGrams: { type: ['number', 'null'], minimum: 0, maximum: 1000 },
    carbohydrateGrams: { type: ['number', 'null'], minimum: 0, maximum: 1000 },
    fatGrams: { type: ['number', 'null'], minimum: 0, maximum: 1000 },
    calorieKcal: { type: ['number', 'null'], minimum: 0, maximum: 10000 },
    confidence: { type: 'number', minimum: 0, maximum: 1 },
    insightSentences: { type: 'array', minItems: 1, maxItems: 2, items: { type: 'string', maxLength: 80 } },
  },
} as const;

function bytesToBase64(bytes: Uint8Array): string {
  let binary = '';
  const chunkSize = 0x8000;
  for (let offset = 0; offset < bytes.length; offset += chunkSize) {
    binary += String.fromCharCode(...bytes.subarray(offset, offset + chunkSize));
  }
  return btoa(binary);
}
