import { FoodVisionProviderError, type FoodKind, type FoodReasonCode, type RawFoodVisionResult, type ValidatedFoodInsight } from './contracts';

const kinds = new Set<FoodKind>(['food', 'drink', 'shake', 'not_food', 'uncertain']);
const reasons = new Set<FoodReasonCode>([
  'strong_rubric_match', 'plausible_food', 'ambiguous_or_mixed',
  'not_food_for_required_food', 'severe_explicit_rubric_mismatch', 'invalid_provider_output',
]);
const forbiddenClaims = /\b(diagnosis|diagnose|alergi|allergen|basi|busuk|aman dikonsumsi|food safety|disiplin|karakter|bentuk tubuh|body shape)\b/iu;
const englishMarkers = /\b(the|this|is|are|with|and|your|looks|meal|food|contains|estimated)\b/iu;

export function validateFoodInsight(raw: RawFoodVisionResult, explicitRubric: boolean): ValidatedFoodInsight {
  if (!kinds.has(raw.detectedKind as FoodKind)) throw new FoodVisionProviderError('invalid_output', false);
  const validatedRating = integerInRange(raw.rating, 1, 5);
  const validatedConfidence = numberInRange(raw.confidence, 0, 1);
  if (validatedRating === null || validatedConfidence === null) throw new FoodVisionProviderError('invalid_output', false);
  let kind = raw.detectedKind as FoodKind;
  let rating = validatedRating;
  const confidence = validatedConfidence;
  const reasonIsKnown = reasons.has(raw.reasonCode as FoodReasonCode);
  if (!reasonIsKnown && rating > 2) throw new FoodVisionProviderError('invalid_output', false);
  let reason: FoodReasonCode = reasonIsKnown ? raw.reasonCode as FoodReasonCode : 'invalid_provider_output';

  const severeAllowed = explicitRubric && confidence >= 0.9 && (
    (rating === 1 && kind === 'not_food' && reason === 'not_food_for_required_food')
    || (rating === 2 && ['food', 'drink', 'shake'].includes(kind) && reason === 'severe_explicit_rubric_mismatch')
  );
  if (rating <= 2 && !severeAllowed) {
    rating = 3;
    kind = 'uncertain';
    reason = 'ambiguous_or_mixed';
  }
  if (rating === 5 && (!explicitRubric || reason !== 'strong_rubric_match')) {
    rating = 4;
    reason = 'plausible_food';
  }
  if (rating === 4 && !['food', 'drink', 'shake'].includes(kind)) {
    rating = 3;
    reason = 'ambiguous_or_mixed';
  }

  const sentences = validIndonesianSentences(raw.insightSentences)
    ? raw.insightSentences as string[]
    : fallbackSentences(kind, rating);

  return {
    detected_kind: kind,
    protein_grams: optionalNumber(raw.proteinGrams, 0, 1000),
    carbohydrate_grams: optionalNumber(raw.carbohydrateGrams, 0, 1000),
    fat_grams: optionalNumber(raw.fatGrams, 0, 1000),
    calorie_kcal: optionalNumber(raw.calorieKcal, 0, 10000),
    rating,
    confidence,
    reason_code: reason,
    insight_sentences: sentences,
  };
}

function validIndonesianSentences(value: unknown): boolean {
  if (!Array.isArray(value) || value.length < 1 || value.length > 2) return false;
  if (!value.every((sentence) => typeof sentence === 'string'
    && sentence.trim().length >= 4 && sentence.trim().length <= 80
    && /[.!?]$/u.test(sentence.trim())
    && !englishMarkers.test(sentence) && !forbiddenClaims.test(sentence))) return false;
  return value.join(' ').length <= 160;
}

function fallbackSentences(kind: FoodKind, rating: number): string[] {
  if (kind === 'not_food') return ['Foto belum menunjukkan makanan sesuai kebutuhan langkah.'];
  if (kind === 'uncertain' || rating === 3) return ['Isi foto belum cukup jelas untuk perkiraan yang yakin.'];
  if (rating === 5) return ['Pilihan pada foto tampak sangat sesuai dengan panduan program.'];
  return ['Pilihan pada foto tampak cukup sesuai dengan panduan program.'];
}

function integerInRange(value: unknown, minimum: number, maximum: number): number | null {
  return typeof value === 'number' && Number.isInteger(value) && value >= minimum && value <= maximum ? value : null;
}

function numberInRange(value: unknown, minimum: number, maximum: number): number | null {
  return typeof value === 'number' && Number.isFinite(value) && value >= minimum && value <= maximum ? value : null;
}

function optionalNumber(value: unknown, minimum: number, maximum: number): number | null {
  if (value === null || value === undefined) return null;
  const validated = numberInRange(value, minimum, maximum);
  if (validated === null) throw new FoodVisionProviderError('invalid_output', false);
  return validated;
}
