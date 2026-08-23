import { z } from 'zod';

import {
  publicCoachSchema,
  publicLeaderboardRowSchema,
  publicProgramSchema,
  publicWinnerPosterSchema,
  publicWinnerSchema,
  type PublicCoach,
  type PublicLeaderboardRow,
  type PublicProgram,
  type PublicWinner,
  type PublicWinnerPoster,
} from './public-models';
import { getSupabaseBrowserClient } from '@/shared/supabase/client';
import { publicCoachMediaUrl } from '@/shared/media/public-coach-media';

export class PublicRepositoryError extends Error {
  constructor() {
    super('Data publik belum dapat dimuat. Coba lagi.');
    this.name = 'PublicRepositoryError';
  }
}

export interface PublicRepository {
  listPrograms(): Promise<PublicProgram[]>;
  getProgram(id: string): Promise<PublicProgram | null>;
  listCoaches(): Promise<PublicCoach[]>;
  getCoach(id: string): Promise<PublicCoach | null>;
  listLeaderboard(programId: string): Promise<PublicLeaderboardRow[]>;
  listWinners(programId: string): Promise<PublicWinner[]>;
  listWinnerPosters(): Promise<PublicWinnerPoster[]>;
  questionPromptMediaUrl(path?: string | null): string | undefined;
}

export class SupabasePublicRepository implements PublicRepository {
  private readonly client = getSupabaseBrowserClient();

  async listPrograms(): Promise<PublicProgram[]> {
    const { data, error } = await this.client.rpc('list_public_programs', {
      target_program_id: undefined,
      result_limit: 50,
      result_offset: 0,
    });
    return this.hydrateFoodQuestionConfigs(parseRows(data, error, publicProgramSchema));
  }

  async getProgram(id: string): Promise<PublicProgram | null> {
    const { data, error } = await this.client.rpc('list_public_programs', {
      target_program_id: id,
      result_limit: 1,
      result_offset: 0,
    });
    return (await this.hydrateFoodQuestionConfigs(parseRows(data, error, publicProgramSchema)))[0] ?? null;
  }

  async listCoaches(): Promise<PublicCoach[]> {
    const { data, error } = await this.client.rpc('list_public_coaches', {
      result_limit: 100,
      result_offset: 0,
    });
    return parseRows(data, error, publicCoachSchema).map((coach) => ({
      ...coach,
      photo_reference: publicCoachMediaUrl(coach.photo_reference) ?? null,
    }));
  }

  async getCoach(id: string): Promise<PublicCoach | null> {
    return (await this.listCoaches()).find((coach) => coach.id === id) ?? null;
  }

  async listLeaderboard(programId: string): Promise<PublicLeaderboardRow[]> {
    const { data, error } = await this.client.rpc('list_public_leaderboard', {
      target_program_id: programId,
      result_limit: 100,
      result_offset: 0,
    });
    return parseRows(data, error, publicLeaderboardRowSchema).map((row) => ({
      ...row,
      avatar_url: publicCoachMediaUrl(row.avatar_reference) ?? row.avatar_url,
    }));
  }

  async listWinners(programId: string): Promise<PublicWinner[]> {
    const { data, error } = await this.client.rpc('list_public_winners', {
      target_program_id: programId,
      result_limit: 5,
      result_offset: 0,
    });
    return parseRows(data, error, publicWinnerSchema);
  }

  async listWinnerPosters(): Promise<PublicWinnerPoster[]> {
    const { data, error } = await this.client.rpc('list_public_winner_posters', {
      result_limit: 20,
      result_offset: 0,
    });
    return parseRows(data, error, publicWinnerPosterSchema);
  }

  questionPromptMediaUrl(path?: string | null) {
    return path ? this.client.storage.from('program-question-media').getPublicUrl(path).data.publicUrl : undefined;
  }

  private async hydrateFoodQuestionConfigs(programs: PublicProgram[]): Promise<PublicProgram[]> {
    const questionIds = programs.flatMap((program) => program.program_days.flatMap((day) => day.program_steps.flatMap((step) => step.program_questions.map((question) => question.id))));
    if (questionIds.length === 0) return programs;
    const [foodResponse, mediaResponse] = await Promise.all([
      this.client.rpc('list_public_food_question_configs', { target_question_ids: questionIds }),
      this.client.rpc('list_public_question_media', { target_question_ids: questionIds }),
    ]);
    if (foodResponse.error || mediaResponse.error) throw new PublicRepositoryError();
    const foodSchema = z.array(z.object({ id: z.string().uuid(), analysis_mode: z.enum(['none', 'food']), analysis_rubric: z.string().nullable(), analysis_rubric_version: z.string().nullable() }));
    const mediaSchema = z.array(z.object({ id: z.string().uuid(), media_kind: z.enum(['image', 'video']).nullable(), media_path: z.string().nullable(), media_alt_text: z.string().nullable() }));
    const food = foodSchema.safeParse(foodResponse.data ?? []);
    const media = mediaSchema.safeParse(mediaResponse.data ?? []);
    if (!food.success || !media.success) throw new PublicRepositoryError();
    const configs = new Map(food.data.map((config) => [config.id, config]));
    const mediaByQuestion = new Map(media.data.map((config) => [config.id, config]));
    return programs.map((program) => ({ ...program, program_days: program.program_days.map((day) => ({ ...day, program_steps: day.program_steps.map((step) => ({ ...step, program_questions: step.program_questions.map((question) => ({ ...question, ...(configs.get(question.id) ?? {}), ...(mediaByQuestion.get(question.id) ?? {}) })) })) })) }));
  }
}

function parseRows<T>(
  data: unknown,
  error: { message: string } | null,
  schema: z.ZodType<T>,
): T[] {
  if (error !== null) throw new PublicRepositoryError();
  const result = z.array(schema).safeParse(data ?? []);
  if (!result.success) throw new PublicRepositoryError();
  return result.data;
}

let repository: PublicRepository | undefined;

export function getPublicRepository(): PublicRepository {
  repository ??= new SupabasePublicRepository();
  return repository;
}
