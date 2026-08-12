import { coachReviewItemSchema, type CoachReviewItem } from './coach-review-models';
import { SupabasePrivateMediaAdapter } from '@/shared/media/supabase-private-media-adapter';
import { getSupabaseBrowserClient } from '@/shared/supabase/client';

export type CoachReviewRepositoryFailure = 'offline' | 'forbidden' | 'sessionExpired' | 'conflict' | 'validation' | 'unknown';

export class CoachReviewRepositoryError extends Error {
  constructor(readonly failure: CoachReviewRepositoryFailure) {
    super({
      offline: 'Koneksi tidak tersedia. Sambungkan perangkat lalu coba lagi.',
      forbidden: 'Akun Coach ini tidak memiliki akses ke bukti tersebut.',
      sessionExpired: 'Sesi berakhir. Masuk kembali untuk melanjutkan.',
      conflict: 'Bukti sudah diperiksa di perangkat lain. Daftar telah dimuat ulang.',
      validation: 'Alasan penolakan wajib diisi.',
      unknown: 'Bukti belum dapat dimuat. Coba lagi.',
    }[failure]);
    this.name = 'CoachReviewRepositoryError';
  }
}

export interface CoachReviewRepository {
  listReviews(): Promise<CoachReviewItem[]>;
  decide(command: { submissionId: string; decision: 'approved' | 'rejected'; reason?: string; idempotencyKey: string }): Promise<void>;
  createPhotoUrl(objectPath: string): Promise<{ url: string; expiresAt: Date }>;
}

export class SupabaseCoachReviewRepository implements CoachReviewRepository {
  private readonly client = getSupabaseBrowserClient();
  private readonly privateMedia = new SupabasePrivateMediaAdapter(this.client);

  async listReviews(): Promise<CoachReviewItem[]> {
    const submissions = await this.client
      .from('step_submissions')
      .select('id,enrollment_id,step_id,status,submitted_at,reviewed_at,review_note')
      .neq('status', 'draft')
      .order('submitted_at', { ascending: false });
    if (submissions.error !== null) throw mapCoachError(submissions.error);
    const rows = submissions.data ?? [];
    if (rows.length === 0) return [];

    const enrollmentIds = unique(rows.map((row) => row.enrollment_id));
    const stepIds = unique(rows.map((row) => row.step_id));
    const submissionIds = unique(rows.map((row) => row.id));
    const [enrollments, steps, answers] = await Promise.all([
      this.client.from('program_enrollments').select('id,program_id,participant_id').in('id', enrollmentIds),
      this.client.from('program_steps').select('id,program_day_id,title,content_kind').in('id', stepIds),
      this.client.from('step_submission_answers').select('id,submission_id,question_id,text_value,number_value,selected_option_ids,private_photo_path').in('submission_id', submissionIds),
    ]);
    assertResponses(enrollments, steps, answers);

    const participantIds = unique((enrollments.data ?? []).map((row) => row.participant_id));
    const programIds = unique((enrollments.data ?? []).map((row) => row.program_id));
    const dayIds = unique((steps.data ?? []).map((row) => row.program_day_id));
    const questionIds = unique((answers.data ?? []).map((row) => row.question_id));
    const [profiles, programs, days, questions] = await Promise.all([
      this.client.from('profiles').select('user_id,display_name,provider_avatar_url').in('user_id', participantIds),
      this.client.from('programs').select('id,title').in('id', programIds),
      this.client.from('program_days').select('id,day_number,title').in('id', dayIds),
      this.client.from('program_questions').select('id,prompt').in('id', questionIds),
    ]);
    assertResponses(profiles, programs, days, questions);

    const enrollmentById = indexBy(enrollments.data ?? [], 'id');
    const stepById = indexBy(steps.data ?? [], 'id');
    const profileById = indexBy(profiles.data ?? [], 'user_id');
    const programById = indexBy(programs.data ?? [], 'id');
    const dayById = indexBy(days.data ?? [], 'id');
    const questionById = indexBy(questions.data ?? [], 'id');

    return rows.map((submission) => {
      const enrollment = enrollmentById.get(submission.enrollment_id);
      const step = stepById.get(submission.step_id);
      const participant = enrollment ? profileById.get(enrollment.participant_id) : undefined;
      const program = enrollment ? programById.get(enrollment.program_id) : undefined;
      const day = step ? dayById.get(step.program_day_id) : undefined;
      if (!enrollment || !step || !participant || !program || !day || !submission.submitted_at) {
        throw new CoachReviewRepositoryError('unknown');
      }
      const result = coachReviewItemSchema.safeParse({
        ...submission,
        participant: { id: participant.user_id, display_name: participant.display_name, avatar_url: participant.provider_avatar_url },
        program,
        day,
        step,
        answers: (answers.data ?? []).filter((answer) => answer.submission_id === submission.id).map((answer) => ({
          ...answer,
          prompt: questionById.get(answer.question_id)?.prompt ?? 'Jawaban peserta',
        })),
      });
      if (!result.success) throw new CoachReviewRepositoryError('unknown');
      return result.data;
    });
  }

  async decide(command: { submissionId: string; decision: 'approved' | 'rejected'; reason?: string; idempotencyKey: string }): Promise<void> {
    if (command.decision === 'rejected' && !command.reason?.trim()) throw new CoachReviewRepositoryError('validation');
    const response = await this.client.rpc('review_step_submission', {
      target_submission_id: command.submissionId,
      review_decision: command.decision,
      review_reason: command.reason?.trim() ?? '',
      request_idempotency_key: command.idempotencyKey,
    });
    if (response.error !== null) throw mapCoachError(response.error);
  }

  createPhotoUrl(objectPath: string) {
    return this.privateMedia.createSignedUrl({ bucket: 'question-photos', objectPath });
  }
}

function unique(values: string[]): string[] {
  return [...new Set(values)];
}

function indexBy<T extends Record<string, unknown>>(rows: T[], key: keyof T): Map<string, T> {
  return new Map(rows.map((row) => [String(row[key]), row]));
}

function assertResponses(...responses: { error: { message: string; code?: string; status?: number } | null }[]): void {
  const failure = responses.find((response) => response.error !== null)?.error;
  if (failure) throw mapCoachError(failure);
}

function mapCoachError(error: { message: string; code?: string; status?: number }): CoachReviewRepositoryError {
  if (typeof navigator !== 'undefined' && navigator.onLine === false) return new CoachReviewRepositoryError('offline');
  if (error.status === 401 || error.code === 'PGRST301') return new CoachReviewRepositoryError('sessionExpired');
  if (error.status === 403 || error.code === '42501' || /permission|entitlement/iu.test(error.message)) return new CoachReviewRepositoryError('forbidden');
  if (/already_reviewed|not_reviewable|conflict/iu.test(error.message)) return new CoachReviewRepositoryError('conflict');
  if (/reason_required|invalid/iu.test(error.message)) return new CoachReviewRepositoryError('validation');
  return new CoachReviewRepositoryError('unknown');
}

let repository: CoachReviewRepository | undefined;
export function getCoachReviewRepository(): CoachReviewRepository {
  repository ??= new SupabaseCoachReviewRepository();
  return repository;
}
