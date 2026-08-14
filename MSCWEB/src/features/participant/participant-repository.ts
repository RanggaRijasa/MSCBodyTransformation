import { z } from 'zod';

import type { PublicProgramQuestion, PublicProgramStep } from '@/features/public/public-models';
import { normalizeBrowserImageOffMainThread } from '@/shared/media/image-normalization';
import {
  SupabasePrivateMediaAdapter,
  type PrivateMediaObjectReference,
} from '@/shared/media/supabase-private-media-adapter';

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

export type ParticipantRepositoryFailure =
  | 'offline'
  | 'forbidden'
  | 'sessionExpired'
  | 'validation'
  | 'conflict'
  | 'unknown';

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
  submitAnswers(command: ParticipantAnswerSubmissionCommand): Promise<ParticipantSubmission>;
  submitWeighIn(command: ParticipantWeighInCommand): Promise<void>;
}

export type ParticipantQuestionAnswer = Readonly<{
  questionId: string;
  textValue?: string;
  numberValue?: number;
  selectedOptionIds?: string[];
  photo?: Blob;
}>;

export type ParticipantAnswerSubmissionCommand = Readonly<{
  enrollmentId: string;
  step: PublicProgramStep;
  answers: ParticipantQuestionAnswer[];
  idempotencyKey: string;
  onProgress?: (value: number, message: string) => void;
}>;

export type ParticipantWeighInCommand = Readonly<{
  enrollmentId: string;
  stepId: string;
  kind: 'initial' | 'daily' | 'final';
  kilograms: string;
  idempotencyKey: string;
}>;

export class SupabaseParticipantRepository implements ParticipantRepository {
  private readonly client = getSupabaseBrowserClient();
  private readonly privateMedia = new SupabasePrivateMediaAdapter(this.client);

  async getProfile(): Promise<ParticipantProfile | null> {
    const actorId = await this.getAuthenticatedUserId();
    const response = await this.client
      .from('profiles')
      .select('public_profile_id, display_name, city, provider_avatar_url')
      .eq('user_id', actorId)
      .maybeSingle();
    if (response.error !== null) throw mapRepositoryError(response.error);
    if (response.data === null) return null;
    const result = participantProfileSchema.safeParse(response.data);
    if (!result.success) throw new ParticipantRepositoryError('unknown');
    return result.data;
  }

  async listEnrollments(): Promise<ParticipantEnrollment[]> {
    const actorId = await this.getAuthenticatedUserId();
    const response = await this.client
      .from('program_enrollments')
      .select('id, program_id, coach_id, status, enrolled_at, completed_at')
      .eq('participant_id', actorId)
      .order('enrolled_at', { ascending: false });
    return parseRows(response.data, response.error, enrollmentSchema);
  }

  async listDayAccess(): Promise<ParticipantDayAccess[]> {
    const response = await this.client.rpc('list_my_program_day_access');
    return parseRows(response.data, response.error, dayAccessSchema);
  }

  async listSubmissions(): Promise<ParticipantSubmission[]> {
    const enrollmentIds = (await this.listEnrollments()).map((enrollment) => enrollment.id);
    if (enrollmentIds.length === 0) return [];
    const response = await this.client
      .from('step_submissions')
      .select('id, enrollment_id, step_id, attempt_sequence, status, review_note, submitted_at')
      .in('enrollment_id', enrollmentIds)
      .order('attempt_sequence', { ascending: false });
    return parseRows(response.data, response.error, submissionSchema);
  }

  async listScores(): Promise<ParticipantScore[]> {
    const enrollmentIds = (await this.listEnrollments()).map((enrollment) => enrollment.id);
    if (enrollmentIds.length === 0) return [];
    const response = await this.client
      .from('program_scores')
      .select('enrollment_id, activity_points, quiz_points, weight_points, adjustment_points, progress_percentage, rank, recalculated_at')
      .in('enrollment_id', enrollmentIds);
    return parseRows(response.data, response.error, scoreSchema);
  }

  async getAssignedCoach(): Promise<ParticipantAssignedCoach | null> {
    const response = await this.client.rpc('get_my_assigned_coach');
    return parseRows(response.data, response.error, assignedCoachSchema)[0] ?? null;
  }

  async submitAnswers(command: ParticipantAnswerSubmissionCommand): Promise<ParticipantSubmission> {
    const required = interactiveQuestions(command.step);
    const answerByQuestion = new Map(command.answers.map((answer) => [answer.questionId, answer]));
    if (required.some((question) => !isCompleteAnswer(question, answerByQuestion.get(question.id)))) {
      throw new ParticipantRepositoryError('validation');
    }

    command.onProgress?.(0.1, 'Menyiapkan pengiriman aman');
    const prepared = await this.client.rpc('prepare_step_submission', {
      target_enrollment_id: command.enrollmentId,
      target_step_id: command.step.id,
      request_idempotency_key: command.idempotencyKey,
    });
    if (prepared.error !== null || prepared.data === null) {
      throw mapRepositoryError(prepared.error ?? { message: 'prepare_failed' });
    }
    const preparedRow = Array.isArray(prepared.data) ? prepared.data[0] : prepared.data;
    const submissionId = (preparedRow as { id?: unknown }).id;
    if (typeof submissionId !== 'string') throw new ParticipantRepositoryError('unknown');

    const user = await this.client.auth.getUser();
    if (user.error !== null || user.data.user === null) throw new ParticipantRepositoryError('sessionExpired');
    const uploaded: PrivateMediaObjectReference[] = [];
    try {
      const payload = [];
      for (const question of required) {
        const answer = answerByQuestion.get(question.id) as ParticipantQuestionAnswer;
        let privatePhotoPath: string | undefined;
        if (answer.photo) {
          command.onProgress?.(0.3, 'Memproses foto tanpa metadata');
          const normalized = await normalizeBrowserImageOffMainThread(answer.photo, { maxWidth: 1_600, maxHeight: 1_600 });
          privatePhotoPath = [
            user.data.user.id,
            command.enrollmentId,
            submissionId,
            question.id,
            `${crypto.randomUUID()}.jpg`,
          ].join('/');
          const reference = { bucket: 'question-photos' as const, objectPath: privatePhotoPath };
          command.onProgress?.(0.6, 'Mengunggah bukti pribadi');
          await this.privateMedia.upload(reference, normalized.blob, normalized.mimeType);
          uploaded.push(reference);
        }
        payload.push({
          question_id: question.id,
          text_value: answer.textValue,
          number_value: answer.numberValue,
          selected_option_ids: answer.selectedOptionIds ?? [],
          private_photo_path: privatePhotoPath,
        });
      }
      command.onProgress?.(0.85, 'Menyimpan jawaban');
      const response = await this.client.rpc('submit_step_answers', {
        target_submission_id: submissionId,
        submitted_answers: payload,
        request_idempotency_key: command.idempotencyKey,
      });
      if (response.error !== null || response.data === null) {
        throw mapRepositoryError(response.error ?? { message: 'submit_failed' });
      }
      const row = Array.isArray(response.data) ? response.data[0] : response.data;
      const result = submissionSchema.safeParse(row);
      if (!result.success) throw new ParticipantRepositoryError('unknown');
      command.onProgress?.(1, 'Bukti berhasil dikirim');
      return result.data;
    } catch (error) {
      await Promise.allSettled(uploaded.map((reference) => this.privateMedia.remove(reference)));
      throw error;
    }
  }

  async submitWeighIn(command: ParticipantWeighInCommand): Promise<void> {
    const normalized = command.kilograms.trim().replace(',', '.');
    if (!/^\d+(?:\.\d)?$/u.test(normalized)) throw new ParticipantRepositoryError('validation');
    const value = Number(normalized);
    if (!Number.isFinite(value) || value <= 0 || value > 500) {
      throw new ParticipantRepositoryError('validation');
    }
    const response = await this.client.rpc('submit_weigh_in', {
      target_enrollment_id: command.enrollmentId,
      target_step_id: command.stepId,
      weigh_in_kind: command.kind,
      weight_kg: value,
      request_idempotency_key: command.idempotencyKey,
    });
    if (response.error !== null) throw mapRepositoryError(response.error);
  }

  private async getAuthenticatedUserId(): Promise<string> {
    const response = await this.client.auth.getUser();
    if (response.error !== null || response.data.user === null) {
      throw new ParticipantRepositoryError('sessionExpired');
    }
    return response.data.user.id;
  }
}

function interactiveQuestions(step: PublicProgramStep): PublicProgramQuestion[] {
  return step.program_questions.filter((question) => question.kind !== 'heading' && question.kind !== 'text');
}

function isCompleteAnswer(question: PublicProgramQuestion, answer?: ParticipantQuestionAnswer): boolean {
  if (!answer) return false;
  if (question.kind === 'photo_upload') return answer.photo !== undefined;
  if (question.kind === 'number') return answer.numberValue !== undefined;
  if (['single_choice', 'multiple_choice', 'image_choice'].includes(question.kind)) {
    return (answer.selectedOptionIds?.length ?? 0) > 0;
  }
  return (answer.textValue?.trim().length ?? 0) > 0;
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
  if (/already|finalized|idempotency|duplicate|reviewed/iu.test(error.message)) {
    return new ParticipantRepositoryError('conflict');
  }
  if (/invalid|incomplete|required|unavailable/iu.test(error.message)) {
    return new ParticipantRepositoryError('validation');
  }
  return new ParticipantRepositoryError('unknown');
}

function repositoryErrorMessage(failure: ParticipantRepositoryFailure): string {
  return {
    offline: 'Koneksi tidak tersedia. Sambungkan perangkat lalu coba lagi.',
    forbidden: 'Akun ini tidak memiliki akses ke data program peserta.',
    sessionExpired: 'Sesi berakhir. Masuk kembali untuk melanjutkan.',
    validation: 'Lengkapi semua jawaban wajib dengan nilai yang valid.',
    conflict: 'Status aktivitas sudah berubah. Muat ulang sebelum melanjutkan.',
    unknown: 'Data program peserta belum dapat dimuat. Coba lagi.',
  }[failure];
}

let repository: ParticipantRepository | undefined;

export function getParticipantRepository(): ParticipantRepository {
  repository ??= new SupabaseParticipantRepository();
  return repository;
}
