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
}

export class SupabasePublicRepository implements PublicRepository {
  private readonly client = getSupabaseBrowserClient();

  async listPrograms(): Promise<PublicProgram[]> {
    const { data, error } = await this.client.rpc('list_public_programs', {
      target_program_id: undefined,
      result_limit: 50,
      result_offset: 0,
    });
    return parseRows(data, error, publicProgramSchema);
  }

  async getProgram(id: string): Promise<PublicProgram | null> {
    const { data, error } = await this.client.rpc('list_public_programs', {
      target_program_id: id,
      result_limit: 1,
      result_offset: 0,
    });
    return parseRows(data, error, publicProgramSchema)[0] ?? null;
  }

  async listCoaches(): Promise<PublicCoach[]> {
    const { data, error } = await this.client.rpc('list_public_coaches', {
      result_limit: 100,
      result_offset: 0,
    });
    return parseRows(data, error, publicCoachSchema);
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
    return parseRows(data, error, publicLeaderboardRowSchema);
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
