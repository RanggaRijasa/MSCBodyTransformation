import { z } from 'zod';

export const paymentOrderStatusSchema = z.enum([
  'awaiting_evidence',
  'under_review',
  'correction_required',
  'approved',
  'expired',
  'cancelled',
  'rejected',
  'reversal_pending',
  'reversed',
]);

export const paymentOrderSchema = z.object({
  id: z.string().uuid(),
  owner_user_id: z.string().uuid(),
  purpose: z.literal('program_enrollment'),
  program_id: z.string().uuid(),
  pending_enrollment_id: z.string().uuid(),
  coach_user_id_snapshot: z.string().uuid(),
  amount_minor: z.number().int().nonnegative(),
  currency: z.literal('IDR'),
  declared_method: z.enum(['bank_transfer', 'static_qris']),
  destination_version: z.number().int().positive(),
  bank_code_snapshot: z.string(),
  bank_name_snapshot: z.string(),
  account_name_snapshot: z.string(),
  account_reference_snapshot: z.string(),
  qris_object_path_snapshot: z.string().nullable(),
  instructions_snapshot: z.string(),
  reservation_expires_at: z.string().nullable(),
  evidence_submitted_at: z.string().nullable(),
  correction_expires_at: z.string().nullable(),
  status: paymentOrderStatusSchema,
  latest_rejection_reason: z.string().nullable(),
  version: z.number().int().nonnegative(),
  created_at: z.string(),
  updated_at: z.string(),
});

export const paymentAttemptSchema = z.object({
  id: z.string().uuid(),
  order_id: z.string().uuid(),
  attempt_number: z.number().int().positive(),
  object_path: z.string(),
  mime_type: z.string().nullable(),
  byte_size: z.number().int().nullable(),
  pixel_width: z.number().int().nullable(),
  pixel_height: z.number().int().nullable(),
  status: z.enum(['prepared', 'submitted', 'approved', 'rejected']),
  prepared_at: z.string(),
  submitted_at: z.string().nullable(),
  reviewed_at: z.string().nullable(),
  rejection_reason: z.string().nullable(),
});

export const paymentEventSchema = z.object({
  id: z.number().int(),
  order_id: z.string().uuid(),
  attempt_id: z.string().uuid().nullable(),
  event_type: z.string(),
  created_at: z.string(),
});

export const paymentQueueItemSchema = z.object({
  order: paymentOrderSchema,
  participant: z.object({ user_id: z.string().uuid(), display_name: z.string().min(1), provider_avatar_url: z.string().nullable() }),
  program: z.object({ id: z.string().uuid(), title: z.string().min(1) }),
});

export type PaymentOrder = z.infer<typeof paymentOrderSchema>;
export type PaymentAttempt = z.infer<typeof paymentAttemptSchema>;
export type PaymentEvent = z.infer<typeof paymentEventSchema>;
export type PaymentQueueItem = z.infer<typeof paymentQueueItemSchema>;

export function paymentStatusPresentation(status: PaymentOrder['status']): {
  label: string;
  message: string;
  tone: 'success' | 'warning' | 'destructive' | 'info';
} {
  const presentations: Record<PaymentOrder['status'], { label: string; message: string; tone: 'success' | 'warning' | 'destructive' | 'info' }> = {
    awaiting_evidence: { label: 'Menunggu bukti', message: 'Unggah bukti setelah menyelesaikan pembayaran.', tone: 'info' },
    under_review: { label: 'Sedang diperiksa', message: 'Admin akan memeriksa bukti secara manual. Anda belum terdaftar sampai pembayaran disetujui.', tone: 'warning' },
    correction_required: { label: 'Perlu perbaikan', message: 'Periksa alasan Admin lalu kirim bukti baru.', tone: 'destructive' },
    approved: { label: 'Disetujui', message: 'Pembayaran disetujui dan program sudah aktif.', tone: 'success' },
    expired: { label: 'Kedaluwarsa', message: 'Batas waktu pembayaran telah berakhir.', tone: 'destructive' },
    cancelled: { label: 'Dibatalkan', message: 'Permintaan pembayaran ini dibatalkan.', tone: 'info' },
    rejected: { label: 'Ditolak', message: 'Pembayaran ditolak. Hubungi Admin bila Anda memerlukan bantuan.', tone: 'destructive' },
    reversal_pending: { label: 'Pembalikan diproses', message: 'Status pembayaran sedang ditinjau kembali.', tone: 'warning' },
    reversed: { label: 'Dibatalkan setelah persetujuan', message: 'Akses program dari pembayaran ini telah dibatalkan.', tone: 'destructive' },
  };
  return presentations[status];
}
