import {
  FoodVisionProviderError,
  type FoodKind,
  type RawFoodVisionResult,
  type ValidatedFoodInsight,
} from './contracts.ts';

const kinds = new Set<FoodKind>(['food', 'drink', 'shake', 'not_food', 'uncertain']);
const forbiddenClaims = /\b(diagnosis|diagnose|alergi|allergen|basi|busuk|aman dikonsumsi|food safety|disiplin|karakter|bentuk tubuh|body shape)\b/iu;
const programContextClaims = /\b(sesuai|kebutuhan|langkah|pertanyaan|tugas|program|panduan|rubrik|target(?: diet)?)\b/iu;
const englishMarkers = /\b(the|this|is|are|with|and|your|looks|meal|food|contains|estimated)\b/iu;

const shakeEstimate = Object.freeze({
  protein_grams: 10,
  carbohydrate_grams: 3,
  fat_grams: 1,
  calorie_kcal: 100,
});

export function validateFoodInsight(raw: RawFoodVisionResult): ValidatedFoodInsight {
  if (!kinds.has(raw.detectedKind as FoodKind)) {
    throw new FoodVisionProviderError('invalid_output', true);
  }
  const kind = raw.detectedKind as FoodKind;
  const confidence = numberInRange(raw.confidence, 0, 1);
  if (confidence === null) throw new FoodVisionProviderError('invalid_output', true);

  if (kind === 'shake') {
    return {
      detected_kind: kind,
      ...shakeEstimate,
      rating: 4,
      confidence,
      reason_code: 'shake_detected',
      insight_sentences: ['Foto tampak menunjukkan satu porsi shake.'],
    };
  }

  if (kind === 'not_food' || kind === 'uncertain') {
    return {
      detected_kind: kind,
      protein_grams: null,
      carbohydrate_grams: null,
      fat_grams: null,
      calorie_kcal: null,
      rating: kind === 'not_food' ? 1 : 3,
      confidence,
      reason_code: kind === 'not_food' ? 'not_food_detected' : 'image_uncertain',
      insight_sentences: fallbackSentences(kind),
    };
  }

  const sentences = validImageOnlyIndonesianSentences(raw.insightSentences)
    ? raw.insightSentences as string[]
    : fallbackSentences(kind);

  return {
    detected_kind: kind,
    protein_grams: optionalNumber(raw.proteinGrams, 0, 1000),
    carbohydrate_grams: optionalNumber(raw.carbohydrateGrams, 0, 1000),
    fat_grams: optionalNumber(raw.fatGrams, 0, 1000),
    calorie_kcal: optionalNumber(raw.calorieKcal, 0, 10000),
    rating: 4,
    confidence,
    reason_code: 'food_or_drink_detected',
    insight_sentences: sentences,
  };
}

function validImageOnlyIndonesianSentences(value: unknown): boolean {
  if (!Array.isArray(value) || value.length < 1 || value.length > 2) return false;
  if (!value.every((sentence) => typeof sentence === 'string'
    && sentence.trim().length >= 4
    && sentence.trim().length <= 80
    && /[.!?]$/u.test(sentence.trim())
    && !englishMarkers.test(sentence)
    && !forbiddenClaims.test(sentence)
    && !programContextClaims.test(sentence))) return false;
  return value.join(' ').length <= 160;
}

function fallbackSentences(kind: FoodKind): string[] {
  if (kind === 'not_food') return ['Makanan atau minuman belum dapat dikenali dari foto.'];
  if (kind === 'uncertain') return ['Isi foto belum cukup jelas untuk membuat perkiraan.'];
  if (kind === 'drink') return ['Foto tampak menunjukkan satu porsi minuman.'];
  return ['Foto tampak menunjukkan satu porsi makanan.'];
}

function numberInRange(value: unknown, minimum: number, maximum: number): number | null {
  return typeof value === 'number' && Number.isFinite(value)
    && value >= minimum && value <= maximum ? value : null;
}

function optionalNumber(value: unknown, minimum: number, maximum: number): number | null {
  if (value === null || value === undefined) return null;
  const validated = numberInRange(value, minimum, maximum);
  if (validated === null) throw new FoodVisionProviderError('invalid_output', true);
  return validated;
}
