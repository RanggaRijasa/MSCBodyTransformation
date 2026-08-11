import { AppError } from "@/domain/errors/app-error";
import {
  isPaymentOrderStatus,
  type AdminPaymentQueueItem,
  type PaymentEvidenceAttempt,
  type PaymentOrder,
  type PaymentPurpose,
} from "@/domain/payments/payment";

export type UnknownRow = Readonly<Record<string, unknown>>;

export function paymentError(error: unknown): AppError {
  const message =
    typeof error === "object" && error !== null && "message" in error
      ? String(error.message)
      : "unknown";
  if (message.includes("authentication_required"))
    return new AppError("unauthorized", "Masuk kembali untuk melanjutkan.");
  if (message.includes("permission_denied"))
    return new AppError("forbidden", "Akun ini tidak memiliki izin.");
  if (
    message.includes("conflict") ||
    message.includes("already_enrolled") ||
    message.includes("full") ||
    message.includes("expired") ||
    message.includes("attempt_limit")
  )
    return new AppError("conflict", "Status pembayaran telah berubah. Muat ulang halaman.");
  if (
    message.includes("invalid") ||
    message.includes("required") ||
    message.includes("mismatch") ||
    message.includes("unavailable") ||
    message.includes("closed") ||
    message.includes("not_")
  )
    return new AppError("validation_failed", "Pembayaran belum dapat diproses.");
  return new AppError("unknown", "Layanan pembayaran belum dapat diakses.");
}

function textValue(value: unknown): string | null {
  return typeof value === "string" && value.length > 0 ? value : null;
}

function mapAttempt(value: unknown): PaymentEvidenceAttempt | null {
  if (!value || typeof value !== "object") return null;
  const row = value as UnknownRow;
  const id = textValue(row.id);
  const attemptNumber = typeof row.attempt_number === "number" ? row.attempt_number : null;
  const status = textValue(row.status);
  if (
    !id ||
    !attemptNumber ||
    !status ||
    !new Set(["prepared", "submitted", "rejected", "approved", "deleted"]).has(status)
  )
    return null;
  return {
    attemptNumber,
    id,
    rejectionReason: textValue(row.rejection_reason),
    status: status as PaymentEvidenceAttempt["status"],
    submittedAt: textValue(row.submitted_at),
  };
}

export function mapOrder(value: unknown): PaymentOrder | null {
  if (!value || typeof value !== "object") return null;
  const row = value as UnknownRow;
  const id = textValue(row.id);
  const purpose = textValue(row.purpose);
  const currency = textValue(row.currency);
  const status = row.status;
  const amount = row.amount_minor;
  const version = typeof row.version === "number" ? row.version : null;
  const timezone = textValue(row.timezone_snapshot);
  if (
    !id ||
    (purpose !== "program_enrollment" && purpose !== "coach_access") ||
    currency !== "IDR" ||
    !isPaymentOrderStatus(status) ||
    (typeof amount !== "string" && typeof amount !== "number") ||
    !version ||
    !new Set(["Asia/Jakarta", "Asia/Makassar", "Asia/Jayapura"]).has(timezone ?? "")
  )
    return null;
  const attempts = Array.isArray(row.payment_evidence_attempts)
    ? row.payment_evidence_attempts.map(mapAttempt).filter((item) => item !== null)
    : [];
  return {
    accountName: textValue(row.account_name_snapshot) ?? "",
    accountReference: textValue(row.account_reference_snapshot) ?? "",
    amountMinor: String(amount),
    bankName: textValue(row.bank_name_snapshot) ?? "",
    correctionExpiresAt: textValue(row.correction_expires_at),
    createdAt: textValue(row.created_at) ?? "",
    currency: "IDR",
    evidenceAttempts: attempts,
    id,
    latestRejectionReason: textValue(row.latest_rejection_reason),
    programId: textValue(row.program_id),
    purpose: purpose as PaymentPurpose,
    qrisObjectPath: textValue(row.qris_object_path_snapshot),
    reservationExpiresAt: textValue(row.reservation_expires_at),
    status,
    timezone: timezone as PaymentOrder["timezone"],
    version,
  };
}

export const orderSelect = `
  id, purpose, program_id, amount_minor, currency, bank_name_snapshot,
  account_name_snapshot, account_reference_snapshot, reservation_expires_at,
  correction_expires_at, status, latest_rejection_reason, version, created_at,
  timezone_snapshot, qris_object_path_snapshot,
  payment_evidence_attempts(
    id, attempt_number, status, submitted_at, rejection_reason
  )
`;

export const adminOrderSelect = `${orderSelect},
  profiles!payment_orders_owner_user_id_fkey(display_name),
  programs!payment_orders_program_id_fkey(title),
  coach_applications!payment_orders_coach_application_id_fkey(display_name_snapshot)
`;

export function mapAdminOrder(raw: unknown): AdminPaymentQueueItem | null {
  const order = mapOrder(raw);
  if (!order || !raw || typeof raw !== "object") return null;
  const row = raw as UnknownRow;
  const profile = row.profiles as UnknownRow | null;
  const program = row.programs as UnknownRow | null;
  const application = row.coach_applications as UnknownRow | null;
  const applicationName = textValue(application?.display_name_snapshot);
  return {
    ...order,
    ownerDisplayName: textValue(profile?.display_name) ?? "Akun dihapus",
    ownerEmailHint: "Identitas privat",
    relatedLabel:
      textValue(program?.title) ??
      (applicationName ? `Pengajuan Coach: ${applicationName}` : "Arsip transaksi"),
  };
}
