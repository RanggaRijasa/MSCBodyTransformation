export const FOOD_ANALYSIS_VERSION = 'food_insight_v1';
export const FOOD_RATING_POLICY_VERSION = 'food_rating_policy_v2_image_only';
export const FOOD_OUTPUT_POLICY_VERSION = 'food_insight_output_v2_image_only';

export type FoodKind = 'food' | 'drink' | 'shake' | 'not_food' | 'uncertain';
export type FoodReasonCode =
  | 'food_or_drink_detected'
  | 'shake_detected'
  | 'image_uncertain'
  | 'not_food_detected';

export type FoodVisionInput = Readonly<{
  imageBytes: Uint8Array;
  mimeType: 'image/jpeg';
}>;

export type RawFoodVisionResult = Readonly<{
  detectedKind?: unknown;
  proteinGrams?: unknown;
  carbohydrateGrams?: unknown;
  fatGrams?: unknown;
  calorieKcal?: unknown;
  confidence?: unknown;
  insightSentences?: unknown;
}>;

export type ValidatedFoodInsight = Readonly<{
  detected_kind: FoodKind;
  protein_grams: number | null;
  carbohydrate_grams: number | null;
  fat_grams: number | null;
  calorie_kcal: number | null;
  rating: number;
  confidence: number;
  reason_code: FoodReasonCode;
  insight_sentences: string[];
}>;

export interface FoodVisionProvider {
  readonly providerName: string;
  readonly modelAlias: string;
  preflight(): Promise<void>;
  analyze(input: FoodVisionInput): Promise<RawFoodVisionResult>;
}

export class FoodVisionProviderError extends Error {
  constructor(
    readonly code: 'provider_unavailable' | 'rate_limited' | 'invalid_output' | 'incompatible_model' | 'configuration_invalid',
    readonly retryable: boolean,
  ) {
    super(code);
    this.name = 'FoodVisionProviderError';
  }
}
