import type { SupabaseClient } from '@supabase/supabase-js';
import { z } from 'zod';

import { normalizeBrowserImageOffMainThread } from '@/shared/media/image-normalization';
import { SupabasePrivateMediaAdapter } from '@/shared/media/supabase-private-media-adapter';
import { getSupabaseBrowserClient } from '@/shared/supabase/client';
import { paymentAttemptSchema, type PaymentAttempt } from '@/features/payment/payment-models';
import {
  coachApplicationAggregateSchema,
  coachActivityFeedSchema,
  coachLeaderboardEntrySchema,
  coachParticipantDetailSchema,
  coachParticipantDirectorySchema,
  coachPaymentOrderSchema,
  coachProfileDraftSchema,
  coachWorkspaceSchema,
  publicCoachProfileSchema,
  type CoachApplicationAggregate,
  type CoachActivityFeed,
  type CoachLeaderboardEntry,
  type CoachParticipantDetail,
  type CoachParticipantDirectory,
  type CoachPaymentOrder,
  type CoachProfileDraft,
  type CoachWorkspace,
  type MemberLevel,
  type PublicCoachProfile,
} from './coach-experience-models';

type LooseDatabase = {
  public: {
    Tables: Record<string, { Row: Record<string, unknown>; Insert: Record<string, unknown>; Update: Record<string, unknown>; Relationships: [] }>;
    Views: Record<string, never>;
    Functions: Record<string, { Args: Record<string, unknown>; Returns: unknown }>;
    Enums: Record<string, never>;
    CompositeTypes: Record<string, never>;
  };
};

export class CoachExperienceError extends Error {
  constructor(readonly code: 'forbidden' | 'inactive' | 'validation' | 'conflict' | 'unknown', message?: string) {
    super(message ?? {
      forbidden: 'Akun ini tidak memiliki akses ke fitur Coach.',
      inactive: 'Masa akses Coach sudah berakhir atau dicabut. Hubungi Admin untuk melanjutkan.',
      validation: 'Periksa kembali data yang belum lengkap.',
      conflict: 'Data telah berubah. Muat ulang lalu coba lagi.',
      unknown: 'Data Coach belum dapat diproses. Coba lagi.',
    }[code]);
    this.name = 'CoachExperienceError';
  }
}

export type CoachApplicationDraftCommand = Readonly<{
  memberLevel: MemberLevel;
  hasCompletedHomSts: boolean;
  hasCompletedIct: boolean;
  termsVersion: string;
  idempotencyKey: string;
}>;

export type CoachProfileDraftCommand = Readonly<{
  handle: string;
  photoObjectPath: string | null;
  professionalHeadline: string;
  biography: string;
  serviceArea: string;
  instagramUrl: string;
  tiktokUrl: string;
  websiteUrl: string;
  whatsappNumber: string;
  phoneNumber: string;
  showInstagram: boolean;
  showTiktok: boolean;
  showWebsite: boolean;
  showWhatsapp: boolean;
  showPhone: boolean;
}>;

export type CoachApplicationQueueItem = Readonly<{
  aggregate: CoachApplicationAggregate;
  order: CoachPaymentOrder | null;
}>;

export class SupabaseCoachExperienceRepository {
  private readonly rawClient = getSupabaseBrowserClient();
  private readonly client = this.rawClient as unknown as SupabaseClient<LooseDatabase>;
  private readonly privateMedia = new SupabasePrivateMediaAdapter(this.rawClient);

  async getMyApplication(): Promise<CoachApplicationAggregate | null> {
    const response = await this.client.rpc('get_my_coach_application');
    if (response.error) throw mapCoachError(response.error);
    if (response.data === null) return null;
    return parse(response.data, coachApplicationAggregateSchema);
  }

  async saveApplicationDraft(command: CoachApplicationDraftCommand): Promise<void> {
    const response = await this.client.rpc('save_my_coach_application_draft', {
      member_level: command.memberLevel,
      applicant_has_completed_hom_sts: command.hasCompletedHomSts,
      applicant_has_completed_ict: command.hasCompletedIct,
      accepted_terms_version: command.termsVersion,
      request_idempotency_key: command.idempotencyKey,
    });
    if (response.error) throw mapCoachError(response.error);
  }

  async submitApplication(applicationId: string, idempotencyKey: string): Promise<void> {
    const response = await this.client.rpc('submit_my_coach_application', {
      target_application_id: applicationId,
      request_idempotency_key: idempotencyKey,
    });
    if (response.error) throw mapCoachError(response.error);
  }

  async createCoachPaymentOrder(applicationId: string, idempotencyKey: string): Promise<CoachPaymentOrder> {
    const response = await this.client.rpc('create_coach_payment_order', {
      target_application_id: applicationId,
      request_idempotency_key: idempotencyKey,
    });
    if (response.error) throw mapCoachError(response.error);
    return parse(response.data, coachPaymentOrderSchema);
  }

  async listMyCoachPaymentOrders(): Promise<CoachPaymentOrder[]> {
    const response = await this.client.from('payment_orders').select(coachPaymentColumns)
      .eq('purpose', 'coach_access').order('created_at', { ascending: false });
    if (response.error) throw mapCoachError(response.error);
    return parse(response.data ?? [], z.array(coachPaymentOrderSchema));
  }

  async listAttempts(orderId: string): Promise<PaymentAttempt[]> {
    const response = await this.client.from('payment_evidence_attempts')
      .select('id,order_id,attempt_number,object_path,mime_type,byte_size,pixel_width,pixel_height,status,prepared_at,submitted_at,reviewed_at,rejection_reason')
      .eq('order_id', orderId).order('attempt_number', { ascending: false });
    if (response.error) throw mapCoachError(response.error);
    return parse(response.data ?? [], z.array(paymentAttemptSchema));
  }

  async submitPaymentEvidence(orderId: string, file: Blob, idempotencyKey: string, onProgress?: (value: number, message: string) => void, onboarding = false): Promise<CoachPaymentOrder> {
    onProgress?.(0.08, 'Menyiapkan unggahan aman');
    const preparedResponse = await this.client.rpc('prepare_payment_evidence_attempt', {
      target_order_id: orderId,
      request_idempotency_key: idempotencyKey,
    });
    if (preparedResponse.error) throw mapCoachError(preparedResponse.error);
    const prepared = parse(preparedResponse.data, paymentAttemptSchema);
    onProgress?.(0.28, 'Menormalkan foto dan menghapus metadata');
    const normalized = await normalizeBrowserImageOffMainThread(file, { maxWidth: 2_048, maxHeight: 2_048 });
    const hash = await sha256Hex(await normalized.blob.arrayBuffer());
    const reference = { bucket: 'payment-evidence' as const, objectPath: prepared.object_path };
    let uploaded = false;
    try {
      onProgress?.(0.62, 'Mengunggah bukti pribadi');
      // The idempotent prepare RPC may return an earlier prepared path after a
      // lost response. A prepared object is not financial history yet, so it
      // is safe to replace before retrying the upload.
      await this.privateMedia.remove(reference).catch(() => undefined);
      await this.privateMedia.upload(reference, normalized.blob, 'image/jpeg');
      uploaded = true;
      const response = await this.client.rpc(onboarding ? 'submit_coach_onboarding_payment_evidence' : 'submit_payment_evidence', {
        target_attempt_id: prepared.id,
        content_sha256_hex: hash,
        content_byte_size: normalized.byteSize,
        content_pixel_width: normalized.width,
        content_pixel_height: normalized.height,
      });
      if (response.error) throw mapCoachError(response.error);
      onProgress?.(1, 'Bukti berhasil dikirim');
      return parse(response.data, coachPaymentOrderSchema);
    } catch (error) {
      // Do not delete on an ambiguous response. The atomic RPC may already
      // have committed the submitted attempt and Participant activation.
      try {
        const [attempts, orders] = await Promise.all([
          this.listAttempts(orderId),
          this.listMyCoachPaymentOrders(),
        ]);
        const currentAttempt = attempts.find((attempt) => attempt.id === prepared.id);
        const currentOrder = orders.find((order) => order.id === orderId);
        if (currentAttempt?.status === 'submitted' && currentOrder?.status === 'under_review') {
          onProgress?.(1, 'Bukti berhasil dikirim');
          return currentOrder;
        }
        if (uploaded && currentAttempt?.status === 'prepared') {
          await this.privateMedia.remove(reference).catch(() => undefined);
        }
      } catch {
        // Preserve the object when reconciliation itself is unavailable.
      }
      throw error;
    }
  }

  downloadDestinationAsset(objectPath: string): Promise<Blob> {
    return this.privateMedia.download({ bucket: 'payment-destination-assets', objectPath });
  }

  downloadEvidence(objectPath: string): Promise<Blob> {
    return this.privateMedia.download({ bucket: 'payment-evidence', objectPath });
  }

  async listAdminApplications(): Promise<CoachApplicationQueueItem[]> {
    const [applicationsResponse, ordersResponse] = await Promise.all([
      this.client.rpc('list_coach_applications_for_admin'),
      this.client.from('payment_orders').select(coachPaymentColumns)
        .eq('purpose', 'coach_access')
        .not('coach_application_id', 'is', null)
        .order('created_at', { ascending: false }),
    ]);
    if (applicationsResponse.error) throw mapCoachError(applicationsResponse.error);
    if (ordersResponse.error) throw mapCoachError(ordersResponse.error);
    const applications = parse(applicationsResponse.data ?? [], z.array(coachApplicationAggregateSchema));
    const orders = parse(ordersResponse.data ?? [], z.array(coachPaymentOrderSchema));
    const orderByApplication = new Map(orders.map((order) => [order.coach_application_id, order]));
    return applications.map((aggregate) => ({ aggregate, order: orderByApplication.get(aggregate.application.id) ?? null }));
  }

  async approveCoach(order: CoachPaymentOrder, reference: string, destinationMatches: boolean, idempotencyKey: string): Promise<void> {
    const response = await this.client.rpc('approve_coach_payment_and_activate', {
      target_order_id: order.id,
      expected_version: order.version,
      reconciled_amount_minor: order.amount_minor,
      reconciliation_reference: reference.trim(),
      destination_matches: destinationMatches,
      request_idempotency_key: idempotencyKey,
    });
    if (response.error) throw mapCoachError(response.error);
  }

  async rejectCoach(order: CoachPaymentOrder, reason: string, idempotencyKey: string): Promise<void> {
    const response = await this.client.rpc('reject_coach_application_and_payment', {
      target_order_id: order.id,
      expected_version: order.version,
      rejection_reason: reason.trim(),
      request_idempotency_key: idempotencyKey,
    });
    if (response.error) throw mapCoachError(response.error);
  }

  async requestCoachCorrection(order: CoachPaymentOrder, reason: string, idempotencyKey: string): Promise<void> {
    const response = await this.client.rpc('request_coach_payment_correction', {
      target_order_id: order.id,
      expected_version: order.version,
      correction_reason: reason.trim(),
      request_idempotency_key: idempotencyKey,
    });
    if (response.error) throw mapCoachError(response.error);
  }

  async getWorkspace(): Promise<CoachWorkspace> {
    const response = await this.client.rpc('get_my_coach_workspace');
    if (response.error) throw mapCoachError(response.error);
    return parse(response.data, coachWorkspaceSchema);
  }

  async getActivityFeed(): Promise<CoachActivityFeed> {
    const response = await this.client.rpc('get_my_coach_activity_feed');
    if (response.error) throw mapCoachError(response.error);
    return parse(response.data, coachActivityFeedSchema);
  }

  async getLeaderboard(programId: string): Promise<CoachLeaderboardEntry[]> {
    const response = await this.client.rpc('get_my_coach_leaderboard', {
      target_program_id: programId,
      result_limit: 100,
      result_offset: 0,
    });
    if (response.error) throw mapCoachError(response.error);
    return parse(response.data ?? [], z.array(coachLeaderboardEntrySchema));
  }

  async getParticipantDirectory(): Promise<CoachParticipantDirectory> {
    const response = await this.client.rpc('get_my_coach_participant_directory');
    if (response.error) throw mapCoachError(response.error);
    return parse(response.data, coachParticipantDirectorySchema);
  }

  async getParticipantDetail(
    participantId: string,
    enrollmentId?: string,
  ): Promise<CoachParticipantDetail> {
    const response = await this.client.rpc('get_my_coach_participant_detail', {
      target_participant_id: participantId,
      target_enrollment_id: enrollmentId ?? null,
    });
    if (response.error) throw mapCoachError(response.error);
    return parse(response.data, coachParticipantDetailSchema);
  }

  async getMyPublicProfileDraft(): Promise<CoachProfileDraft> {
    const response = await this.client.rpc('get_my_coach_public_profile_draft');
    if (response.error) throw mapCoachError(response.error);
    return parse(response.data, coachProfileDraftSchema);
  }

  async savePublicProfileDraft(command: CoachProfileDraftCommand): Promise<void> {
    const response = await this.client.rpc('save_my_coach_public_profile_draft', {
      requested_handle: command.handle,
      photo_object_path: command.photoObjectPath,
      professional_headline: command.professionalHeadline,
      biography: command.biography,
      service_area: command.serviceArea,
      instagram_url: command.instagramUrl,
      tiktok_url: command.tiktokUrl,
      website_url: command.websiteUrl,
      whatsapp_number: command.whatsappNumber,
      phone_number: command.phoneNumber,
      show_instagram: command.showInstagram,
      show_tiktok: command.showTiktok,
      show_website: command.showWebsite,
      show_whatsapp: command.showWhatsapp,
      show_phone: command.showPhone,
    });
    if (response.error) throw mapCoachError(response.error);
  }

  async uploadPublicProfileImage(file: Blob, folder: 'avatar' | 'items'): Promise<string> {
    const normalized = await normalizeBrowserImageOffMainThread(file, { maxWidth: 2_048, maxHeight: 2_048 });
    const allocated = await this.client.rpc('allocate_my_coach_public_media_path', { media_folder: folder });
    if (allocated.error || typeof allocated.data !== 'string') throw mapCoachError(allocated.error ?? new Error('profile_media_path_invalid'));
    const objectPath = allocated.data;
    const response = await this.rawClient.storage.from('coach-public-media')
      .upload(objectPath, normalized.blob, { contentType: 'image/jpeg', upsert: false });
    if (response.error) throw mapCoachError(response.error);
    return objectPath;
  }

  async importProviderAvatar(providerAvatarUrl: string): Promise<string> {
    try {
      const response = await fetch(providerAvatarUrl, {
        credentials: 'omit',
        referrerPolicy: 'no-referrer',
      });
      if (!response.ok) throw new Error('provider_avatar_unavailable');
      return await this.uploadPublicProfileImage(await response.blob(), 'avatar');
    } catch {
      throw new CoachExperienceError(
        'validation',
        'Foto akun belum dapat diimpor. Pilih foto profil untuk melanjutkan.',
      );
    }
  }

  async submitProfileItem(command: { kind: 'testimonial' | 'before_after'; title: string; body: string; mediaObjectPath: string | null; includesThirdParty: boolean; permissionAttested: boolean }): Promise<void> {
    const response = await this.client.rpc('submit_my_coach_public_profile_item', {
      item_kind: command.kind,
      title: command.title,
      body: command.body,
      media_object_path: command.mediaObjectPath,
      includes_third_party: command.includesThirdParty,
      permission_attested: command.permissionAttested,
    });
    if (response.error) throw mapCoachError(response.error);
  }

  async publishPublicProfile(): Promise<PublicCoachProfile> {
    const response = await this.client.rpc('publish_my_coach_public_profile');
    if (response.error) throw mapCoachError(response.error);
    return parse(response.data, publicCoachProfileSchema);
  }

  async getPublicProfile(handle: string): Promise<PublicCoachProfile | null> {
    const response = await this.client.rpc('get_public_coach_profile', { target_handle: handle });
    if (response.error) throw mapCoachError(response.error);
    if (response.data === null) return null;
    return parse(response.data, publicCoachProfileSchema);
  }

  publicMediaUrl(objectPath: string): string {
    return this.rawClient.storage.from('coach-public-media').getPublicUrl(objectPath).data.publicUrl;
  }
}

const coachPaymentColumns = 'id,owner_user_id,purpose,coach_application_id,program_id,pending_enrollment_id,coach_user_id_snapshot,amount_minor,currency,declared_method,destination_version,bank_code_snapshot,bank_name_snapshot,account_name_snapshot,account_reference_snapshot,qris_object_path_snapshot,instructions_snapshot,status,latest_rejection_reason,evidence_submitted_at,version,created_at,updated_at';

function parse<T>(value: unknown, schema: z.ZodType<T>): T {
  const result = schema.safeParse(value);
  if (!result.success) throw new CoachExperienceError('unknown');
  return result.data;
}

function mapCoachError(error: { message: string; status?: number; code?: string }): CoachExperienceError {
  if (/coach_entitlement_inactive/iu.test(error.message)) return new CoachExperienceError('inactive');
  if (error.status === 403 || error.code === '42501' || /permission_denied/iu.test(error.message)) return new CoachExperienceError('forbidden');
  if (/version_conflict|already_decided|idempotency|unavailable/iu.test(error.message)) return new CoachExperienceError('conflict');
  if (/invalid|incomplete|required|not_eligible|profile_photo|reason_required|amount_mismatch/iu.test(error.message)) return new CoachExperienceError('validation');
  return new CoachExperienceError('unknown');
}

async function sha256Hex(value: ArrayBuffer): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-256', value);
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, '0')).join('');
}

let repository: SupabaseCoachExperienceRepository | undefined;
export function getCoachExperienceRepository(): SupabaseCoachExperienceRepository {
  repository ??= new SupabaseCoachExperienceRepository();
  return repository;
}
