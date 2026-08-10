export const paymentOrderStatuses = [
  "awaiting_evidence",
  "under_review",
  "correction_required",
  "approved",
  "expired",
  "cancelled",
  "rejected",
  "reversal_pending",
  "reversed",
] as const;

export type PaymentOrderStatus = (typeof paymentOrderStatuses)[number];
export type PaymentPurpose = "program_enrollment" | "coach_access";

export type PaymentEvidenceAttempt = Readonly<{
  attemptNumber: number;
  id: string;
  rejectionReason: string | null;
  status: "prepared" | "submitted" | "rejected" | "approved" | "deleted";
  submittedAt: string | null;
}>;

export type PaymentOrder = Readonly<{
  accountName: string;
  accountReference: string;
  amountMinor: string;
  bankName: string;
  correctionExpiresAt: string | null;
  createdAt: string;
  currency: "IDR";
  evidenceAttempts: readonly PaymentEvidenceAttempt[];
  id: string;
  latestRejectionReason: string | null;
  programId: string | null;
  purpose: PaymentPurpose;
  qrisObjectPath: string | null;
  reservationExpiresAt: string | null;
  status: PaymentOrderStatus;
  timezone: "Asia/Jakarta" | "Asia/Makassar" | "Asia/Jayapura";
  version: number;
}>;

export type AdminPaymentQueueItem = PaymentOrder &
  Readonly<{
    ownerDisplayName: string;
    ownerEmailHint: string;
    relatedLabel: string;
  }>;

export type AdminPaymentQueueFilters = Readonly<{
  createdFrom?: string;
  createdTo?: string;
  purpose?: PaymentPurpose;
  search?: string;
  status?: PaymentOrderStatus;
}>;

export type AdminPaymentEvent = Readonly<{
  createdAt: string;
  id: string;
  type: string;
}>;

export type AdminPaymentLedgerEntry = Readonly<{
  amountMinor: string;
  kind: "reversal" | "verified";
  reconciliationReference: string;
  resolutionDueAt: string | null;
  resolutionNote: string | null;
  verifiedAt: string;
}>;

export type PaymentDestinationSummary = Readonly<{
  accountName: string;
  accountReference: string;
  bankName: string;
  effectiveFrom: string;
  effectiveUntil: string | null;
  id: string;
  status: "active" | "retired" | "scheduled";
  version: number;
}>;

export function isPaymentOrderStatus(value: unknown): value is PaymentOrderStatus {
  return (paymentOrderStatuses as readonly unknown[]).includes(value);
}
