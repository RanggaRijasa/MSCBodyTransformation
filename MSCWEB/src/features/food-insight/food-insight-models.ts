import { z } from 'zod';

export const foodInsightJobSchema = z.object({
  id: z.string().uuid(),
  submission_id: z.string().uuid(),
  status: z.enum(['queued', 'processing', 'retry_scheduled', 'completed', 'failed', 'unavailable']),
  attempt_count: z.number().int().nonnegative(),
  max_attempts: z.number().int().positive(),
  terminal_error_code: z.string().nullable(),
  updated_at: z.string(),
});

export const foodInsightResultSchema = z.object({
  id: z.string().uuid(), submission_id: z.string().uuid(), analysis_version: z.string(),
  detected_kind: z.enum(['food', 'drink', 'shake', 'not_food', 'uncertain']),
  protein_grams: z.coerce.number().nullable(), carbohydrate_grams: z.coerce.number().nullable(),
  fat_grams: z.coerce.number().nullable(), calorie_kcal: z.coerce.number().nullable(),
  ai_rating: z.number().int().min(1).max(5), effective_rating: z.number().int().min(1).max(5),
  confidence: z.coerce.number().min(0).max(1), reason_code: z.string(),
  insight_sentences: z.array(z.string()).min(1).max(2), version: z.number().int().positive(),
  updated_at: z.string(),
});

export type FoodInsightJob = z.infer<typeof foodInsightJobSchema>;
export type FoodInsightResult = z.infer<typeof foodInsightResultSchema>;
export type FoodInsightState = Readonly<{ job: FoodInsightJob; result?: FoodInsightResult }>;
