import type { Json } from '@/shared/supabase/database.types';
import { normalizeBrowserImageOffMainThread } from '@/shared/media/image-normalization';
import { SupabasePrivateMediaAdapter } from '@/shared/media/supabase-private-media-adapter';
import { getSupabaseBrowserClient } from '@/shared/supabase/client';

import {
  adminAuditSchema,
  adminClosureSchema,
  adminDashboardSchema,
  adminEvidenceSchema,
  adminFoodOperationSchema,
  adminModerationItemSchema,
  adminPosterSchema,
  adminPersonSchema,
  adminProgramSchema,
  adminWinnerPreviewSchema,
  adminWinnerSnapshotSchema,
  type AdminAudit,
  type AdminClosure,
  type AdminDashboard,
  type AdminEvidence,
  type AdminFoodOperation,
  type AdminModerationItem,
  type AdminPoster,
  type AdminPerson,
  type AdminProgram,
  type AdminWinnerPreview,
  type AdminWinnerSnapshot,
} from './admin-models';
import { normalizeQuestionPromptMedia } from './admin-question-media';

export class AdminRepositoryError extends Error {
  constructor(readonly code = 'unknown') {
    super(adminErrorMessage(code));
    this.name = 'AdminRepositoryError';
  }
}

export type AdminPersonOperations = Readonly<{
  enrollments: { id: string; program_id: string; program_title: string; status: string; activity_points: number; quiz_points: number; weight_points: number; adjustment_points: number; progress_percentage: number }[];
  weighIns: { id: string; enrollment_id: string; kind: string; weight_kg: number; recorded_at: string }[];
}>;

const programGraphSelect = `
  id,source_program_id,title,summary,category,cover_path,cover_alt_text,status,pace,duration_mode,
  starts_on,ends_on,timezone,participant_limit,registration_closes_at,past_step_policy,future_step_policy,
  wellness_disclaimer,points_per_activity,points_per_weight_kg,quiz_passing_percentage,default_verification_mode,pricing_mode,desired_price,
  published_at,created_at,updated_at,
  program_days(
    id,day_number,title,summary,scheduled_on,
    program_steps(
      id,step_order,title,instructions,content_kind,completion_policy,verification_mode,media_path,media_alt_text,
      video_required,video_threshold,video_autoplay,
      program_questions(
        id,question_order,kind,prompt,analysis_mode,analysis_rubric,analysis_rubric_version,media_kind,media_path,media_alt_text,
        program_question_options(id,option_order,title,media_path,media_alt_text),
        program_answer_keys(question_id,accepted_text_values,number_value,selected_option_ids,matching_mode)
      )
    )
  )`;

export interface AdminRepository {
  getDashboard(): Promise<AdminDashboard>;
  listPrograms(): Promise<AdminProgram[]>;
  getProgram(programId: string): Promise<AdminProgram>;
  saveProgram(program: AdminProgram): Promise<string>;
  createProgram(): Promise<string>;
  duplicateProgram(program: AdminProgram): Promise<string>;
  hasCurrentPaymentDestination(): Promise<boolean>;
  publishProgram(programId: string): Promise<void>;
  archiveProgram(programId: string, reason: string): Promise<void>;
  uploadPublicImage(file: Blob, namespace: 'programs' | 'winners'): Promise<string>;
  uploadQuestionPromptMedia(file: Blob): Promise<{ mediaKind: 'image' | 'video'; mediaPath: string }>;
  publicMediaUrl(path?: string | null): string | undefined;
  questionPromptMediaUrl(path?: string | null): string | undefined;
  listPeople(): Promise<AdminPerson[]>;
  getPerson(personId: string): Promise<AdminPerson>;
  getPersonOperations(participantId: string): Promise<AdminPersonOperations>;
  enrollParticipant(participantId: string, programId: string, reason: string): Promise<void>;
  transferCoach(participantId: string, coachId: string, reason: string): Promise<void>;
  adjustScore(enrollmentId: string, points: number, reason: string): Promise<void>;
  listEvidence(): Promise<AdminEvidence[]>;
  listModeration(): Promise<AdminModerationItem[]>;
  moderateItem(item: AdminModerationItem, decision: 'approved' | 'rejected', note: string): Promise<void>;
  listFoodOperations(): Promise<AdminFoodOperation[]>;
  correctFoodRating(operation: AdminFoodOperation, rating: number, reason: string): Promise<void>;
  listAudit(): Promise<AdminAudit[]>;
  getClosure(programId: string): Promise<AdminClosure>;
  previewWinners(programId: string): Promise<AdminWinnerPreview[]>;
  completeProgram(programId: string, reason: string): Promise<void>;
  lockWinners(programId: string): Promise<void>;
  publishWinnerPoster(programId: string, snapshotId: string, mediaPath: string, altText: string): Promise<void>;
  listPosters(): Promise<AdminPoster[]>;
  listWinnerSnapshots(): Promise<AdminWinnerSnapshot[]>;
  archivePoster(posterId: string, reason: string): Promise<void>;
}

export class SupabaseAdminRepository implements AdminRepository {
  private readonly client = getSupabaseBrowserClient();
  private readonly privateMedia = new SupabasePrivateMediaAdapter(this.client);

  async getDashboard() {
    const response = await this.client.rpc('get_admin_dashboard');
    return parseOne(response.data, response.error, adminDashboardSchema);
  }

  async listPrograms() {
    const response = await this.client.from('programs').select(programGraphSelect).order('updated_at', { ascending: false });
    if (response.error) throw mapError(response.error);
    return (response.data ?? []).map(normalizeProgramGraph).map((row) => adminProgramSchema.parse(row));
  }

  async getProgram(programId: string) {
    const response = await this.client.from('programs').select(programGraphSelect).eq('id', programId).single();
    if (response.error) throw mapError(response.error);
    return adminProgramSchema.parse(normalizeProgramGraph(response.data));
  }

  async createProgram() {
    const program = makeDefaultProgram();
    await this.saveProgram(program);
    return program.id;
  }

  async saveProgram(program: AdminProgram) {
    const response = await this.client.rpc('save_admin_program_draft', {
      program_payload: toProgramPayload(program), request_idempotency_key: operationKey('admin-program-save'),
    });
    if (response.error) throw mapError(response.error);
    return response.data.id;
  }

  async duplicateProgram(program: AdminProgram) {
    const targetId = crypto.randomUUID();
    const response = await this.client.rpc('duplicate_admin_program_as_draft', {
      target_program_id: targetId, source_program_id: program.id,
      target_title: `${program.title} — Salinan`, target_start_date: futureDate(7),
      request_idempotency_key: operationKey('admin-program-duplicate'),
    });
    if (response.error) throw mapError(response.error);
    return targetId;
  }

  async hasCurrentPaymentDestination() {
    const now = new Date().toISOString();
    const response = await this.client
      .from('payment_destinations')
      .select('id')
      .in('status', ['active', 'scheduled'])
      .lte('effective_from', now)
      .or(`effective_until.is.null,effective_until.gt.${now}`)
      .order('version', { ascending: false })
      .limit(1)
      .maybeSingle();
    if (response.error) throw mapError(response.error);
    return response.data !== null;
  }

  async publishProgram(programId: string) {
    const response = await this.client.rpc('publish_program', { target_program_id: programId, request_idempotency_key: operationKey('admin-program-publish') });
    if (response.error) throw mapError(response.error);
  }

  async archiveProgram(programId: string, reason: string) {
    const response = await this.client.rpc('archive_admin_program', { target_program_id: programId, reason: reason.trim(), request_idempotency_key: operationKey('admin-program-archive') });
    if (response.error) throw mapError(response.error);
  }

  async uploadPublicImage(file: Blob, namespace: 'programs' | 'winners') {
    const normalized = await normalizeBrowserImageOffMainThread(file, { maxWidth: namespace === 'winners' ? 1_080 : 1_600, maxHeight: namespace === 'winners' ? 1_920 : 1_200 });
    const path = `${namespace}/${crypto.randomUUID()}.jpg`;
    const response = await this.client.storage.from('public-media').upload(path, normalized.blob, { contentType: normalized.mimeType, upsert: false });
    if (response.error) throw mapError(response.error);
    return path;
  }

  async uploadQuestionPromptMedia(file: Blob) {
    const mediaKind = file.type.startsWith('image/') ? 'image' : 'video';
    let body = file;
    let contentType = file.type;
    let extension = videoExtension(file.type);
    if (mediaKind === 'image') {
      const normalized = await normalizeBrowserImageOffMainThread(file, { maxWidth: 1_600, maxHeight: 1_600 });
      body = normalized.blob;
      contentType = normalized.mimeType;
      extension = 'jpg';
    } else if (!extension || file.size <= 0 || file.size > MAX_QUESTION_VIDEO_BYTES) {
      throw new AdminRepositoryError('question_media_invalid');
    }
    const mediaPath = `questions/${crypto.randomUUID()}.${extension}`;
    const response = await this.client.storage.from('program-question-media').upload(mediaPath, body, {
      contentType, cacheControl: '31536000', upsert: false,
    });
    if (response.error) throw mapError(response.error);
    return { mediaKind, mediaPath } as const;
  }

  publicMediaUrl(path?: string | null) {
    return path ? this.client.storage.from('public-media').getPublicUrl(path).data.publicUrl : undefined;
  }

  questionPromptMediaUrl(path?: string | null) {
    return path ? this.client.storage.from('program-question-media').getPublicUrl(path).data.publicUrl : undefined;
  }

  async listPeople() {
    const response = await this.client.rpc('list_admin_people');
    return parseMany(response.data, response.error, adminPersonSchema);
  }

  async getPerson(personId: string) {
    const response = await this.client.rpc('get_admin_person_detail', { target_user_id: personId });
    return parseOne(response.data, response.error, adminPersonSchema);
  }

  async getPersonOperations(participantId: string): Promise<AdminPersonOperations> {
    const enrollments = await this.client.from('program_enrollments').select('id,program_id,status').eq('participant_id', participantId).order('enrolled_at', { ascending: false });
    if (enrollments.error) throw mapError(enrollments.error);
    const enrollmentRows = enrollments.data ?? [];
    const enrollmentIds = enrollmentRows.map((row) => row.id);
    const programIds = [...new Set(enrollmentRows.map((row) => row.program_id))];
    const [programs, scores, weighIns] = await Promise.all([
      programIds.length ? this.client.from('programs').select('id,title').in('id', programIds) : Promise.resolve({ data: [], error: null }),
      enrollmentIds.length ? this.client.from('program_scores').select('enrollment_id,activity_points,quiz_points,weight_points,adjustment_points,progress_percentage').in('enrollment_id', enrollmentIds) : Promise.resolve({ data: [], error: null }),
      enrollmentIds.length ? this.client.from('weigh_ins').select('id,enrollment_id,kind,weight_kg,recorded_at').in('enrollment_id', enrollmentIds).order('recorded_at') : Promise.resolve({ data: [], error: null }),
    ]);
    if (programs.error || scores.error || weighIns.error) throw new AdminRepositoryError();
    const programById = new Map((programs.data ?? []).map((program) => [program.id, program.title]));
    const scoreByEnrollment = new Map((scores.data ?? []).map((score) => [score.enrollment_id, score]));
    return {
      enrollments: enrollmentRows.map((enrollment) => {
        const score = scoreByEnrollment.get(enrollment.id);
        return { id: enrollment.id, program_id: enrollment.program_id, program_title: programById.get(enrollment.program_id) ?? 'Program', status: enrollment.status,
          activity_points: score?.activity_points ?? 0, quiz_points: score?.quiz_points ?? 0, weight_points: score?.weight_points ?? 0,
          adjustment_points: score?.adjustment_points ?? 0, progress_percentage: score?.progress_percentage ?? 0 };
      }),
      weighIns: (weighIns.data ?? []).map((row) => ({ ...row, weight_kg: Number(row.weight_kg) })),
    };
  }

  async enrollParticipant(participantId: string, programId: string, reason: string) {
    const response = await this.client.rpc('admin_enroll_participant', { target_participant_id: participantId, target_program_id: programId, reason: reason.trim() });
    if (response.error) throw mapError(response.error);
  }

  async transferCoach(participantId: string, coachId: string, reason: string) {
    const response = await this.client.rpc('admin_transfer_coach', { target_participant_id: participantId, target_coach_id: coachId, reason: reason.trim() });
    if (response.error) throw mapError(response.error);
  }

  async adjustScore(enrollmentId: string, points: number, reason: string) {
    const response = await this.client.rpc('admin_adjust_score', { target_enrollment_id: enrollmentId, points, reason: reason.trim(), request_idempotency_key: operationKey('admin-score-adjust') });
    if (response.error) throw mapError(response.error);
  }

  async listEvidence() {
    const response = await this.client.rpc('list_admin_pending_evidence');
    return parseMany(response.data, response.error, adminEvidenceSchema);
  }

  async listModeration() {
    const response = await this.client.rpc('list_admin_profile_moderation_items');
    const items = parseMany(response.data, response.error, adminModerationItemSchema);
    return Promise.all(items.map(async (item) => {
      if (!item.media_object_path) return item;
      const preview = await this.privateMedia.createSignedUrl({
        bucket: 'coach-public-media',
        objectPath: item.media_object_path,
      });
      return { ...item, media_preview_url: preview.url };
    }));
  }

  async moderateItem(item: AdminModerationItem, decision: 'approved' | 'rejected', note: string) {
    const response = await this.client.rpc('moderate_admin_coach_profile_item', {
      target_item_id: item.id, expected_version: item.moderation_version, decision, note: note.trim(),
      request_idempotency_key: operationKey('admin-profile-moderation'),
    });
    if (response.error) throw mapError(response.error);
  }

  async listFoodOperations() {
    const response = await this.client.rpc('list_admin_food_insight_operations');
    return parseMany(response.data, response.error, adminFoodOperationSchema);
  }

  async correctFoodRating(operation: AdminFoodOperation, rating: number, reason: string) {
    if (!operation.result_id || !operation.result_version) throw new AdminRepositoryError('insight_unavailable');
    const response = await this.client.rpc('correct_food_insight_rating', {
      target_result_id: operation.result_id, expected_version: operation.result_version,
      corrected_rating: rating, correction_reason: reason.trim(), request_idempotency_key: operationKey('admin-food-correction'),
    });
    if (response.error) throw mapError(response.error);
  }

  async listAudit() {
    const response = await this.client.rpc('list_admin_audit_events', { result_limit: 100 });
    return parseMany(response.data, response.error, adminAuditSchema);
  }

  async getClosure(programId: string) {
    const response = await this.client.rpc('get_admin_closure_preflight', { target_program_id: programId });
    return parseOne(response.data, response.error, adminClosureSchema);
  }

  async previewWinners(programId: string) {
    const response = await this.client.rpc('preview_admin_program_winners', { target_program_id: programId });
    return parseMany(response.data, response.error, adminWinnerPreviewSchema);
  }

  async completeProgram(programId: string, reason: string) {
    const response = await this.client.rpc('complete_program', { target_program_id: programId, reason: reason.trim(), request_idempotency_key: operationKey('admin-program-complete') });
    if (response.error) throw mapError(response.error);
  }

  async lockWinners(programId: string) {
    const response = await this.client.rpc('lock_program_winners', { target_program_id: programId, request_idempotency_key: operationKey('admin-winner-lock') });
    if (response.error) throw mapError(response.error);
  }

  async publishWinnerPoster(programId: string, snapshotId: string, mediaPath: string, altText: string) {
    const response = await this.client.rpc('publish_winner_poster', {
      target_program_id: programId, target_snapshot_id: snapshotId, media_path: mediaPath,
      alt_text: altText.trim(), request_idempotency_key: operationKey('admin-winner-poster'),
    });
    if (response.error) throw mapError(response.error);
  }

  async listPosters() {
    const response = await this.client.from('winner_posters').select('id,program_id,winner_snapshot_id,media_path,alt_text,is_published,published_at,deleted_at').is('deleted_at', null).order('published_at', { ascending: false });
    if (response.error) throw mapError(response.error);
    return (response.data ?? []).map((row) => adminPosterSchema.parse(row));
  }

  async listWinnerSnapshots() {
    const response = await this.client.from('winner_snapshots').select('id,program_id,locked_at').order('locked_at', { ascending: false });
    if (response.error) throw mapError(response.error);
    return (response.data ?? []).map((row) => adminWinnerSnapshotSchema.parse(row));
  }

  async archivePoster(posterId: string, reason: string) {
    const response = await this.client.rpc('archive_admin_winner_poster', { target_poster_id: posterId, reason: reason.trim(), request_idempotency_key: operationKey('admin-poster-archive') });
    if (response.error) throw mapError(response.error);
  }
}

export function normalizeProgramGraph(value: unknown) {
  const row = value as Record<string, unknown>;
  return {
    ...row,
    days: ((row.program_days as Record<string, unknown>[] | null) ?? []).map((day) => ({
      ...day,
      steps: ((day.program_steps as Record<string, unknown>[] | null) ?? []).map((step) => ({
        ...step,
        questions: ((step.program_questions as Record<string, unknown>[] | null) ?? []).map((question) => ({
          ...question,
          options: (question.program_question_options as unknown[]) ?? [],
          answer_key: normalizeSingleRelation(question.program_answer_keys),
        })).sort(byOrder('question_order')),
      })).sort(byOrder('step_order')),
    })).sort(byOrder('day_number')),
  };
}

function normalizeSingleRelation(value: unknown) {
  if (Array.isArray(value)) return value[0] ?? null;
  return value && typeof value === 'object' ? value : null;
}

function byOrder(key: string) {
  return (left: Record<string, unknown>, right: Record<string, unknown>) => Number(left[key]) - Number(right[key]);
}

function toProgramPayload(program: AdminProgram): Json {
  return JSON.parse(JSON.stringify({
    ...program,
    days: program.days.map((day) => ({
      ...day,
      steps: day.steps.map((step) => ({
        ...step,
        questions: step.questions.map(normalizeQuestionPromptMedia),
      })),
    })),
  })) as Json;
}

function makeDefaultProgram(): AdminProgram {
  const now = new Date().toISOString();
  return adminProgramSchema.parse({
    id: crypto.randomUUID(), source_program_id: null, title: 'Program kebiasaan baru', summary: 'Draft lokal untuk latihan CMS Admin.',
    category: 'Transformasi', cover_path: null, cover_alt_text: null, status: 'draft', pace: 'scheduled', duration_mode: 'specific_dates',
    starts_on: futureDate(1), ends_on: futureDate(7), timezone: 'Asia/Makassar', participant_limit: 30, registration_closes_at: null,
    past_step_policy: 'available', future_step_policy: 'locked', wellness_disclaimer: 'Program ini mendukung kebiasaan hidup sehat dan bukan pengganti diagnosis atau perawatan medis.',
    points_per_activity: 10, points_per_weight_kg: 0, quiz_passing_percentage: 70, default_verification_mode: 'coach_review', pricing_mode: 'free', desired_price: null,
    published_at: null, created_at: now, updated_at: now,
    days: [{ id: crypto.randomUUID(), day_number: 1, title: 'Hari ke-1', summary: 'Mulai program', scheduled_on: futureDate(1), steps: [] }],
  });
}

function futureDate(offsetDays: number) {
  return new Date(Date.now() + offsetDays * 86_400_000).toISOString().slice(0, 10);
}

function operationKey(prefix: string) { return `${prefix}-${crypto.randomUUID()}`; }

function parseOne<T>(data: unknown, error: { message?: string } | null, schema: { parse(value: unknown): T }): T {
  if (error) throw mapError(error);
  return schema.parse(data);
}

function parseMany<T>(data: unknown, error: { message?: string } | null, schema: { parse(value: unknown): T }): T[] {
  if (error) throw mapError(error);
  return (Array.isArray(data) ? data : []).map((row) => schema.parse(row));
}

function mapError(error: { message?: string }) {
  if (error.message?.includes('program_questions_prompt_media_check')) {
    return new AdminRepositoryError('question_media_alt_text_required');
  }
  if (error.message?.includes('phase12_payment_handoff') || error.message?.includes('payment_destination_unavailable')) {
    return new AdminRepositoryError('program_paid_not_ready');
  }
  const known = ['permission_denied', 'program_not_found', 'program_not_draft', 'published_program_read_only', 'program_days_required', 'program_step_required', 'question_prompt_required', 'quiz_answer_key_required', 'weigh_in_configuration_invalid', 'program_paid_not_ready', 'pending_reviews_exist', 'final_weight_missing', 'winners_already_locked', 'reason_required', 'moderation_conflict', 'correction_conflict', 'question_media_invalid'];
  return new AdminRepositoryError(known.find((code) => error.message?.includes(code)) ?? 'unknown');
}

function adminErrorMessage(code: string) {
  return ({
    permission_denied: 'Akun ini tidak memiliki wewenang Admin.', program_not_found: 'Program tidak ditemukan.',
    published_program_read_only: 'Program yang sudah diterbitkan hanya dapat dibaca. Duplikasikan sebagai draft untuk mengubahnya.',
    program_days_required: 'Tambahkan minimal satu hari program.', program_step_required: 'Setiap hari perlu memiliki minimal satu langkah.',
    program_not_draft: 'Program ini bukan draft atau sudah diterbitkan. Muat ulang untuk melihat status terbaru.',
    question_prompt_required: 'Setiap pertanyaan perlu memiliki teks.',
    quiz_answer_key_required: 'Kuis memerlukan kunci jawaban lengkap.',
    weigh_in_configuration_invalid: 'Poin berat membutuhkan tepat satu timbang awal dan satu timbang akhir.',
    program_paid_not_ready: 'Program berbayar belum dapat diterbitkan karena tujuan pembayaran belum dikonfigurasi.',
    pending_reviews_exist: 'Masih ada pemeriksaan bukti yang belum selesai.', final_weight_missing: 'Timbang akhir peserta belum lengkap.',
    winners_already_locked: 'Snapshot pemenang sudah dikunci.', reason_required: 'Alasan wajib diisi.',
    moderation_conflict: 'Konten telah diperiksa dari sesi lain. Muat ulang.', correction_conflict: 'Rating telah dikoreksi dari sesi lain. Muat ulang.',
    question_media_invalid: 'Media pertanyaan harus berupa gambar atau video yang didukung dengan ukuran maksimal 50 MB.',
    question_media_alt_text_required: 'Isi deskripsi media agar lampiran dapat disimpan.',
    insight_unavailable: 'Hasil AI belum tersedia untuk dikoreksi.', unknown: 'Operasi Admin belum dapat diselesaikan. Muat ulang lalu coba lagi.',
  } as Record<string, string>)[code] ?? 'Operasi Admin belum dapat diselesaikan.';
}

const MAX_QUESTION_VIDEO_BYTES = 50 * 1_024 * 1_024;
function videoExtension(contentType: string) {
  return ({ 'video/mp4': 'mp4', 'video/quicktime': 'mov', 'video/webm': 'webm' } as Record<string, string>)[contentType];
}

let repository: AdminRepository | undefined;
export function getAdminRepository() { repository ??= new SupabaseAdminRepository(); return repository; }
