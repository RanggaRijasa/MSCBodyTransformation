import type { SupabaseClient } from '@supabase/supabase-js';
import { z } from 'zod';

import { normalizeBrowserImageOffMainThread } from '@/shared/media/image-normalization';
import { SupabasePrivateMediaAdapter } from '@/shared/media/supabase-private-media-adapter';
import { getSupabaseBrowserClient } from '@/shared/supabase/client';
import {
  paymentAttemptSchema,
  paymentEventSchema,
  paymentOrderSchema,
  paymentQueueItemSchema,
  type PaymentAttempt,
  type PaymentEvent,
  type PaymentOrder,
  type PaymentQueueItem,
} from './payment-models';

type PaymentDatabase = {
  public: {
    Tables: Record<string, { Row: Record<string, unknown>; Insert: Record<string, unknown>; Update: Record<string, unknown>; Relationships: [] }>;
    Views: Record<string, never>;
    Functions: Record<string, { Args: Record<string, unknown>; Returns: unknown }>;
    Enums: Record<string, never>;
    CompositeTypes: Record<string, never>;
  };
};

export type PaymentRepositoryFailure = 'offline' | 'forbidden' | 'sessionExpired' | 'conflict' | 'invalidCoachQr' | 'coachMismatch' | 'validation' | 'unknown';

export class PaymentRepositoryError extends Error {
  constructor(readonly failure: PaymentRepositoryFailure) {
    super({
      offline: 'Koneksi tidak tersedia. Sambungkan perangkat lalu coba lagi.',
      forbidden: 'Akun ini tidak memiliki akses ke pembayaran tersebut.',
      sessionExpired: 'Sesi berakhir. Masuk kembali untuk melanjutkan.',
      conflict: 'Pembayaran sudah diproses di perangkat lain. Data telah dimuat ulang.',
      invalidCoachQr: 'QR Coach tidak valid atau sudah tidak aktif. Minta QR terbaru dari Coach lalu pindai kembali.',
      coachMismatch: 'QR tersebut tidak sesuai dengan Coach yang terhubung ke akun Anda.',
      validation: 'Data pembayaran belum lengkap atau tidak valid.',
      unknown: 'Pembayaran belum dapat diproses. Coba lagi.',
    }[failure]);
    this.name = 'PaymentRepositoryError';
  }
}

export interface PaymentRepository {
  ensureRepeatableLocalFixtures(): Promise<boolean>;
  enrollFree(programId: string, rawPayload: string): Promise<void>;
  createProgramOrder(programId: string, rawPayload: string, idempotencyKey: string): Promise<PaymentOrder>;
  listOwnOrders(programId: string): Promise<PaymentOrder[]>;
  listAttempts(orderId: string): Promise<PaymentAttempt[]>;
  submitEvidence(orderId: string, file: Blob, idempotencyKey: string, onProgress?: (value: number, message: string) => void): Promise<PaymentOrder>;
  downloadDestinationAsset(objectPath: string): Promise<Blob>;
  listAdminQueue(): Promise<PaymentQueueItem[]>;
  listAdminAttempts(orderId: string): Promise<PaymentAttempt[]>;
  listAdminEvents(orderId: string): Promise<PaymentEvent[]>;
  downloadEvidence(objectPath: string): Promise<Blob>;
  approve(order: PaymentOrder, reference: string, destinationMatches: boolean): Promise<PaymentOrder>;
  reject(order: PaymentOrder, reason: string): Promise<PaymentOrder>;
}

export class SupabasePaymentRepository implements PaymentRepository {
  private readonly client = getSupabaseBrowserClient() as unknown as SupabaseClient<PaymentDatabase>;
  private readonly media = new SupabasePrivateMediaAdapter(getSupabaseBrowserClient());

  async ensureRepeatableLocalFixtures(): Promise<boolean> {
    const response = await this.client.rpc('ensure_repeatable_local_program_fixtures');
    if (response.error) throw mapPaymentError(response.error);
    return response.data === true;
  }

  async enrollFree(programId: string, rawPayload: string): Promise<void> {
    const response = await this.client.rpc('enroll_free_program', { target_program_id: programId, scanned_coach_qr: rawPayload });
    if (response.error) throw mapPaymentError(response.error);
  }

  async createProgramOrder(programId: string, rawPayload: string, idempotencyKey: string): Promise<PaymentOrder> {
    const response = await this.client.rpc('create_program_payment_order', {
      target_program_id: programId,
      coach_qr_payload: rawPayload,
      // Compatibility value for the existing RPC. Participants receive both
      // bank and QRIS destination snapshots and no longer choose a method.
      payment_method: 'bank_transfer',
      request_idempotency_key: idempotencyKey,
    });
    return parseOne(response.data, response.error, paymentOrderSchema);
  }

  async listOwnOrders(programId: string): Promise<PaymentOrder[]> {
    const response = await this.client.from('payment_orders').select(paymentOrderColumns).eq('program_id', programId).order('created_at', { ascending: false });
    return parseMany(response.data, response.error, paymentOrderSchema);
  }

  async listAttempts(orderId: string): Promise<PaymentAttempt[]> {
    const response = await this.client.from('payment_evidence_attempts').select(paymentAttemptColumns).eq('order_id', orderId).order('attempt_number', { ascending: false });
    return parseMany(response.data, response.error, paymentAttemptSchema);
  }

  async submitEvidence(orderId: string, file: Blob, idempotencyKey: string, onProgress?: (value: number, message: string) => void): Promise<PaymentOrder> {
    onProgress?.(0.08, 'Menyiapkan unggahan aman');
    const preparedResponse = await this.client.rpc('prepare_payment_evidence_attempt', {
      target_order_id: orderId,
      request_idempotency_key: idempotencyKey,
    });
    const prepared = parseOne(preparedResponse.data, preparedResponse.error, paymentAttemptSchema);
    onProgress?.(0.28, 'Menormalkan foto dan menghapus metadata');
    const normalized = await normalizeBrowserImageOffMainThread(file, { maxWidth: 2_048, maxHeight: 2_048 });
    const hash = await sha256Hex(await normalized.blob.arrayBuffer());
    const reference = { bucket: 'payment-evidence' as const, objectPath: prepared.object_path };
    let uploaded = false;
    try {
      onProgress?.(0.62, 'Mengunggah bukti pribadi');
      await this.media.upload(reference, normalized.blob, 'image/jpeg');
      uploaded = true;
      onProgress?.(0.88, 'Mengirim bukti untuk pemeriksaan');
      const response = await this.client.rpc('submit_payment_evidence', {
        target_attempt_id: prepared.id,
        content_sha256_hex: hash,
        content_byte_size: normalized.byteSize,
        content_pixel_width: normalized.width,
        content_pixel_height: normalized.height,
      });
      const order = parseOne(response.data, response.error, paymentOrderSchema);
      onProgress?.(1, 'Bukti berhasil dikirim');
      return order;
    } catch (error) {
      if (uploaded) await this.media.remove(reference).catch(() => undefined);
      throw error instanceof PaymentRepositoryError ? error : mapPaymentError(error as { message: string });
    }
  }

  downloadDestinationAsset(objectPath: string) {
    return this.media.download({ bucket: 'payment-destination-assets', objectPath });
  }

  async listAdminQueue(): Promise<PaymentQueueItem[]> {
    const orderResponse = await this.client.from('payment_orders').select(paymentOrderColumns).eq('purpose', 'program_enrollment').not('owner_user_id', 'is', null).not('pending_enrollment_id', 'is', null).order('created_at', { ascending: true });
    const orders = parseMany(orderResponse.data, orderResponse.error, paymentOrderSchema);
    if (!orders.length) return [];
    const [profiles, programs] = await Promise.all([
      this.client.from('profiles').select('user_id,display_name,provider_avatar_url').in('user_id', unique(orders.map((order) => order.owner_user_id))),
      this.client.from('programs').select('id,title').in('id', unique(orders.map((order) => order.program_id))),
    ]);
    if (profiles.error) throw mapPaymentError(profiles.error);
    if (programs.error) throw mapPaymentError(programs.error);
    const profileById = new Map((profiles.data ?? []).map((row) => [row.user_id, row]));
    const programById = new Map((programs.data ?? []).map((row) => [row.id, row]));
    return orders.map((order) => {
      const parsed = paymentQueueItemSchema.safeParse({ order, participant: profileById.get(order.owner_user_id), program: programById.get(order.program_id) });
      if (!parsed.success) throw new PaymentRepositoryError('unknown');
      return parsed.data;
    });
  }

  async listAdminAttempts(orderId: string): Promise<PaymentAttempt[]> {
    return this.listAttempts(orderId);
  }

  async listAdminEvents(orderId: string): Promise<PaymentEvent[]> {
    const response = await this.client.from('payment_events').select('id,order_id,attempt_id,event_type,created_at').eq('order_id', orderId).order('created_at', { ascending: false });
    return parseMany(response.data, response.error, paymentEventSchema);
  }

  downloadEvidence(objectPath: string) {
    return this.media.download({ bucket: 'payment-evidence', objectPath });
  }

  async approve(order: PaymentOrder, reference: string, destinationMatches: boolean): Promise<PaymentOrder> {
    const response = await this.client.rpc('approve_payment_order', {
      target_order_id: order.id,
      expected_version: order.version,
      reconciled_amount_minor: order.amount_minor,
      reconciliation_reference: reference.trim(),
      destination_matches: destinationMatches,
    });
    return parseOne(response.data, response.error, paymentOrderSchema);
  }

  async reject(order: PaymentOrder, reason: string): Promise<PaymentOrder> {
    if (reason.trim().length < 5) throw new PaymentRepositoryError('validation');
    const response = await this.client.rpc('reject_payment_evidence', {
      target_order_id: order.id,
      expected_version: order.version,
      rejection_reason: reason.trim(),
    });
    return parseOne(response.data, response.error, paymentOrderSchema);
  }
}

const paymentOrderColumns = 'id,owner_user_id,purpose,program_id,pending_enrollment_id,coach_user_id_snapshot,amount_minor,currency,declared_method,destination_version,bank_code_snapshot,bank_name_snapshot,account_name_snapshot,account_reference_snapshot,qris_object_path_snapshot,instructions_snapshot,reservation_expires_at,evidence_submitted_at,correction_expires_at,status,latest_rejection_reason,version,created_at,updated_at';
const paymentAttemptColumns = 'id,order_id,attempt_number,object_path,mime_type,byte_size,pixel_width,pixel_height,status,prepared_at,submitted_at,reviewed_at,rejection_reason';

function parseOne<T>(data: unknown, error: { message: string; code?: string; status?: number } | null, schema: z.ZodType<T>): T {
  if (error) throw mapPaymentError(error);
  const row = Array.isArray(data) ? data[0] : data;
  const parsed = schema.safeParse(row);
  if (!parsed.success) throw new PaymentRepositoryError('unknown');
  return parsed.data;
}

function parseMany<T>(data: unknown, error: { message: string; code?: string; status?: number } | null, schema: z.ZodType<T>): T[] {
  if (error) throw mapPaymentError(error);
  const parsed = z.array(schema).safeParse(data ?? []);
  if (!parsed.success) throw new PaymentRepositoryError('unknown');
  return parsed.data;
}

export function mapPaymentError(error: { message: string; code?: string; status?: number }): PaymentRepositoryError {
  if (typeof navigator !== 'undefined' && navigator.onLine === false) return new PaymentRepositoryError('offline');
  if (error.status === 401 || error.code === 'PGRST301' || /authentication_required/iu.test(error.message)) return new PaymentRepositoryError('sessionExpired');
  if (error.status === 403 || error.code === '42501' || /permission_denied/iu.test(error.message)) return new PaymentRepositoryError('forbidden');
  if (/coach_qr_invalid/iu.test(error.message)) return new PaymentRepositoryError('invalidCoachQr');
  if (/coach_mismatch/iu.test(error.message)) return new PaymentRepositoryError('coachMismatch');
  if (/version_conflict|already_|duplicate|idempotency_conflict|not_reviewable|enrollment_conflict/iu.test(error.message)) return new PaymentRepositoryError('conflict');
  if (/invalid|required|unavailable|expired|closed|full|mismatch|limit|not_uploadable/iu.test(error.message)) return new PaymentRepositoryError('validation');
  return new PaymentRepositoryError('unknown');
}

async function sha256Hex(value: ArrayBuffer): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-256', value);
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, '0')).join('');
}

function unique(values: string[]): string[] {
  return [...new Set(values)];
}

let repository: PaymentRepository | undefined;
export function getPaymentRepository(): PaymentRepository {
  repository ??= new SupabasePaymentRepository();
  return repository;
}
