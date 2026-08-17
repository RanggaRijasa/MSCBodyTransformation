export const FOOD_ANALYSIS_VERSION = 'food_insight_v1';
export const FOOD_RATING_POLICY_VERSION = 'food_rating_policy_v1';
export const FOOD_OUTPUT_POLICY_VERSION = 'food_insight_output_v1';

export type FoodKind = 'food' | 'drink' | 'shake' | 'not_food' | 'uncertain';
export type FoodReasonCode =
  | 'strong_rubric_match'
  | 'plausible_food'
  | 'ambiguous_or_mixed'
  | 'not_food_for_required_food'
  | 'severe_explicit_rubric_mismatch'
  | 'invalid_provider_output';

export type FoodVisionInput = Readonly<{
  imageBytes: Uint8Array;
  mimeType: 'image/jpeg';
  rubric?: string;
  rubricVersion?: string;
}>;

export type RawFoodVisionResult = Readonly<{
  detectedKind?: unknown;
  proteinGrams?: unknown;
  carbohydrateGrams?: unknown;
  fatGrams?: unknown;
  calorieKcal?: unknown;
  rating?: unknown;
  confidence?: unknown;
  reasonCode?: unknown;
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
