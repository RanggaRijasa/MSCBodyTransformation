import { z } from 'zod';

import {
  assignedCoachSchema,
  dayAccessSchema,
  enrollmentSchema,
  participantProfileSchema,
  scoreSchema,
  submissionSchema,
  type ParticipantAssignedCoach,
  type ParticipantDayAccess,
  type ParticipantEnrollment,
  type ParticipantProfile,
  type ParticipantScore,
  type ParticipantSubmission,
} from './participant-models';
import { getSupabaseBrowserClient } from '@/shared/supabase/client';

export type ParticipantRepositoryFailure = 'offline' | 'forbidden' | 'sessionExpired' | 'unknown';

export class ParticipantRepositoryError extends Error {
  constructor(readonly failure: ParticipantRepositoryFailure) {
    super(repositoryErrorMessage(failure));
    this.name = 'ParticipantRepositoryError';
  }
}

export interface ParticipantRepository {
  getProfile(): Promise<ParticipantProfile | null>;
  listEnrollments(): Promise<ParticipantEnrollment[]>;
  listDayAccess(): Promise<ParticipantDayAccess[]>;
  listSubmissions(): Promise<ParticipantSubmission[]>;
  listScores(): Promise<ParticipantScore[]>;
  getAssignedCoach(): Promise<ParticipantAssignedCoach | null>;
}

export class SupabaseParticipantRepository implements ParticipantRepository {
  private readonly client = getSupabaseBrowserClient();

  async getProfile(): Promise<ParticipantProfile | null> {
    const response = await this.client
      .from('profiles')
      .select('public_profile_id, display_name, city, provider_avatar_url')
      .maybeSingle();
    if (response.error !== null) throw mapRepositoryError(response.error);
    if (response.data === null) return null;
    const result = participantProfileSchema.safeParse(response.data);
    if (!result.success) throw new ParticipantRepositoryError('unknown');
    return result.data;
  }

  async listEnrollments(): Promise<ParticipantEnrollment[]> {
    const response = await this.client
      .from('program_enrollments')
      .select('id, program_id, coach_id, status, enrolled_at, completed_at')
      .order('enrolled_at', { ascending: false });
    return parseRows(response.data, response.error, enrollmentSchema);
  }

  async listDayAccess(): Promise<ParticipantDayAccess[]> {
    const response = await this.client.rpc('list_my_program_day_access');
    return parseRows(response.data, response.error, dayAccessSchema);
  }

  async listSubmissions(): Promise<ParticipantSubmission[]> {
    const response = await this.client
      .from('step_submissions')
      .select('id, enrollment_id, step_id, attempt_sequence, status, review_note, submitted_at')
      .order('attempt_sequence', { ascending: false });
    return parseRows(response.data, response.error, submissionSchema);
  }

  async listScores(): Promise<ParticipantScore[]> {
    const response = await this.client
      .from('program_scores')
      .select('enrollment_id, activity_points, quiz_points, weight_points, adjustment_points, progress_percentage, rank, recalculated_at');
    return parseRows(response.data, response.error, scoreSchema);
  }

  async getAssignedCoach(): Promise<ParticipantAssignedCoach | null> {
    const response = await this.client.rpc('get_my_assigned_coach');
    return parseRows(response.data, response.error, assignedCoachSchema)[0] ?? null;
  }
}

function parseRows<T>(
  data: unknown,
  error: { code?: string; message: string; status?: number } | null,
  schema: z.ZodType<T>,
): T[] {
  if (error !== null) throw mapRepositoryError(error);
  const result = z.array(schema).safeParse(data ?? []);
  if (!result.success) throw new ParticipantRepositoryError('unknown');
  return result.data;
}

function mapRepositoryError(error: { code?: string; message: string; status?: number }): ParticipantRepositoryError {
  if (typeof navigator !== 'undefined' && navigator.onLine === false) {
    return new ParticipantRepositoryError('offline');
  }
  if (error.status === 401 || error.code === 'PGRST301') {
    return new ParticipantRepositoryError('sessionExpired');
  }
  if (error.status === 403 || error.code === '42501') {
    return new ParticipantRepositoryError('forbidden');
  }
  return new ParticipantRepositoryError('unknown');
}

function repositoryErrorMessage(failure: ParticipantRepositoryFailure): string {
  return {
    offline: 'Koneksi tidak tersedia. Sambungkan perangkat lalu coba lagi.',
    forbidden: 'Akun ini tidak memiliki akses ke data program peserta.',
    sessionExpired: 'Sesi berakhir. Masuk kembali untuk melanjutkan.',
    unknown: 'Data program peserta belum dapat dimuat. Coba lagi.',
  }[failure];
}

let repository: ParticipantRepository | undefined;

export function getParticipantRepository(): ParticipantRepository {
  repository ??= new SupabaseParticipantRepository();
  return repository;
}
