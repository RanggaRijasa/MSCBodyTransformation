import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

import { paymentAttemptSchema, paymentOrderSchema, paymentStatusPresentation } from '@/features/payment/payment-models';
import { mapPaymentError } from '@/features/payment/payment-repository';

const order = {
  id: '11111111-1111-4111-8111-111111111111',
  owner_user_id: '22222222-2222-4222-8222-222222222222',
  purpose: 'program_enrollment',
  program_id: '33333333-3333-4333-8333-333333333333',
  pending_enrollment_id: '44444444-4444-4444-8444-444444444444',
  coach_user_id_snapshot: '55555555-5555-4555-8555-555555555555',
  amount_minor: 125_000,
  currency: 'IDR',
  declared_method: 'bank_transfer',
  destination_version: 1,
  bank_code_snapshot: 'TST',
  bank_name_snapshot: 'Bank Uji',
  account_name_snapshot: 'FIXTURE',
  account_reference_snapshot: '0000',
  qris_object_path_snapshot: null,
  instructions_snapshot: 'Jangan melakukan pembayaran nyata.',
  reservation_expires_at: '2026-08-13T00:00:00Z',
  evidence_submitted_at: null,
  correction_expires_at: null,
  status: 'awaiting_evidence',
  latest_rejection_reason: null,
  version: 1,
  created_at: '2026-08-12T00:00:00Z',
  updated_at: '2026-08-12T00:00:00Z',
};

describe('manual payment contract', () => {
  it('accepts immutable IDR destination snapshots and rejects unknown states', () => {
    expect(paymentOrderSchema.parse(order).amount_minor).toBe(125_000);
    expect(paymentOrderSchema.safeParse({ ...order, status: 'auto_verified' }).success).toBe(false);
    expect(paymentOrderSchema.safeParse({ ...order, currency: 'USD' }).success).toBe(false);
  });

  it('represents prepared, submitted, rejected, and approved attempt history', () => {
    for (const status of ['prepared', 'submitted', 'rejected', 'approved'] as const) {
      expect(paymentAttemptSchema.safeParse({
        id: '66666666-6666-4666-8666-666666666666', order_id: order.id,
        attempt_number: 1, object_path: 'orders/private/normalized.jpg', mime_type: null,
        byte_size: null, pixel_width: null, pixel_height: null, status,
        prepared_at: order.created_at, submitted_at: null, reviewed_at: null,
        rejection_reason: status === 'rejected' ? 'Bukti buram.' : null,
      }).success).toBe(true);
    }
  });

  it('uses manual-review Indonesian copy for every payment state', () => {
    expect(paymentStatusPresentation('under_review').message).toContain('memeriksa bukti secara manual');
    expect(paymentStatusPresentation('correction_required')).toEqual(expect.objectContaining({ label: 'Perlu perbaikan', tone: 'destructive' }));
    expect(paymentStatusPresentation('approved').message).toContain('program sudah aktif');
    expect(paymentStatusPresentation('expired').label).toBe('Kedaluwarsa');
    expect(paymentStatusPresentation('cancelled').label).toBe('Dibatalkan');
  });

  it('maps authority errors without exposing backend detail', () => {
    expect(mapPaymentError({ message: 'version_conflict: internal row detail' })).toEqual(expect.objectContaining({ failure: 'conflict', message: expect.not.stringContaining('internal') }));
    expect(mapPaymentError({ message: 'coach_qr_invalid: raw payload' })).toEqual(expect.objectContaining({ failure: 'invalidCoachQr', message: 'QR Coach tidak valid atau sudah tidak aktif. Minta QR terbaru dari Coach lalu pindai kembali.' }));
    expect(mapPaymentError({ message: 'coach_mismatch: internal identifiers' })).toEqual(expect.objectContaining({ failure: 'coachMismatch', message: expect.not.stringContaining('identifiers') }));
    expect(mapPaymentError({ message: 'permission_denied' })).toEqual(expect.objectContaining({ failure: 'forbidden' }));
  });

  it('opens the payment proof picker without forcing the Android emulator camera', () => {
    const source = readFileSync('src/features/payment/ParticipantPaymentFlow.tsx', 'utf8');
    expect(source).toContain('style={fileInputOverlayStyle}');
    expect(source).toContain("event.currentTarget.value = ''");
    expect(source.indexOf("event.currentTarget.value = ''")).toBeGreaterThan(source.indexOf('onChange={(event) =>'));
    expect(source).not.toContain('capture="environment"');
  });

  it('places the native file input over the full visual button for direct Android activation', () => {
    const paymentSource = readFileSync('src/features/payment/ParticipantPaymentFlow.tsx', 'utf8');
    expect(paymentSource).toContain('<label');
    expect(paymentSource).toContain('aria-label={uploadLabel}');
    expect(paymentSource).toContain('className="payment-native-file-input"');
    expect(paymentSource).toContain("height: '100%'");
    expect(paymentSource).toContain('inset: 0');
    expect(paymentSource).not.toContain('setUploadPressed');
    expect(paymentSource).toContain('className="payment-file-button"');
    const globalStyles = readFileSync('src/global.css', 'utf8');
    expect(globalStyles).toContain('.payment-file-button:has(input:active)');
    expect(globalStyles).toContain('.payment-native-file-input::file-selector-button');
    expect(globalStyles).toContain('width: 100%');
    expect(paymentSource).toContain("file ? 'Ganti bukti pembayaran' : 'Upload bukti pembayaran'");
  });

  it('makes the production lock explicit and enables a non-authoritative repeat loop only locally', () => {
    const source = readFileSync('src/features/payment/ParticipantPaymentFlow.tsx', 'utf8');
    expect(source).toContain('title="Upload dikunci sementara"');
    expect(source).toContain('Admin menolak');
    expect(source).toContain("order.status === 'under_review'");
    expect(source).toContain('isLocalDevelopmentEnvironment()');
    expect(source).toContain('program.category === repeatableLocalFixtureCategory');
    expect(source).toContain("file ? 'Ganti foto uji lokal' : 'Upload foto uji lokal'");
    expect(source).toContain('Bukti yang sedang diperiksa Admin tidak diubah.');
  });

  it('submits the selected proof without a redundant confirmation step', () => {
    const source = readFileSync('src/features/payment/ParticipantPaymentFlow.tsx', 'utf8');
    expect(source).toContain("canRepeatLocalUpload ? 'Selesaikan uji upload lokal' : 'Kirim bukti pembayaran'");
    expect(source).not.toContain('Kirim bukti sekarang?');
    expect(source).not.toContain('label="Periksa lagi"');
    expect(source).not.toContain('setConfirming');
  });

  it('keeps rotating test fixtures in the local-only dev script', () => {
    const source = readFileSync('supabase/dev/ensure_continuous_payment_preview.local.sql', 'utf8');
    expect(source).toContain('ensure_repeatable_local_program_fixtures');
    expect(source).toContain('Program uji lokal berbayar');
    expect(source).toContain('Program uji lokal gratis');
    expect(source).toContain("program.status in ('scheduled', 'active')");
    expect(source).toContain('revoke all on function public.ensure_repeatable_local_program_fixtures()');
  });
});
