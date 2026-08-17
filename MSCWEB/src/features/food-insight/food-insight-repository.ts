import { getSupabaseBrowserClient } from '@/shared/supabase/client';
import { foodInsightJobSchema, foodInsightResultSchema, type FoodInsightResult, type FoodInsightState } from './food-insight-models';

export class FoodInsightRepositoryError extends Error {
  constructor() { super('Insight makanan belum dapat dimuat. Coba lagi.'); this.name = 'FoodInsightRepositoryError'; }
}

export interface FoodInsightRepository {
  getForSubmission(submissionId: string): Promise<FoodInsightState | null>;
  correctRating(command: { result: FoodInsightResult; rating: number; reason: string; idempotencyKey: string }): Promise<void>;
}

export class SupabaseFoodInsightRepository implements FoodInsightRepository {
  private readonly client = getSupabaseBrowserClient();

  async getForSubmission(submissionId: string): Promise<FoodInsightState | null> {
    const [jobResponse, resultResponse] = await Promise.all([
      this.client.from('food_insight_jobs').select('id,submission_id,status,attempt_count,max_attempts,terminal_error_code,updated_at').eq('submission_id', submissionId).maybeSingle(),
      this.client.from('food_insight_results').select('id,submission_id,analysis_version,detected_kind,protein_grams,carbohydrate_grams,fat_grams,calorie_kcal,ai_rating,effective_rating,confidence,reason_code,insight_sentences,version,updated_at').eq('submission_id', submissionId).maybeSingle(),
    ]);
    if (jobResponse.error || resultResponse.error) throw new FoodInsightRepositoryError();
    if (!jobResponse.data) return null;
    const job = foodInsightJobSchema.safeParse(jobResponse.data);
    const result = resultResponse.data ? foodInsightResultSchema.safeParse(resultResponse.data) : undefined;
    if (!job.success || (result && !result.success)) throw new FoodInsightRepositoryError();
    return { job: job.data, result: result?.data };
  }

  async correctRating(command: { result: FoodInsightResult; rating: number; reason: string; idempotencyKey: string }) {
    if (!Number.isInteger(command.rating) || command.rating < 1 || command.rating > 5 || command.reason.trim().length < 8) {
      throw new FoodInsightRepositoryError();
    }
    const response = await this.client.rpc('correct_food_insight_rating', {
      target_result_id: command.result.id, expected_version: command.result.version,
      corrected_rating: command.rating, correction_reason: command.reason.trim(),
      request_idempotency_key: command.idempotencyKey,
    });
    if (response.error) throw new FoodInsightRepositoryError();
  }
}

let repository: FoodInsightRepository | undefined;
export function getFoodInsightRepository() { repository ??= new SupabaseFoodInsightRepository(); return repository; }
