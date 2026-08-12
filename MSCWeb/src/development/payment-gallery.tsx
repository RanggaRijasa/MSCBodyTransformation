import type { PaymentOrder } from "@/domain/payments/payment";
import { AdminPaymentDecision, AdminPaymentQueue, PaymentOrderView } from "@/features/payments";

export const simulatorPaymentOrder: PaymentOrder = {
  accountName: "MSC Body Transformation",
  accountReference: "1234567890",
  amountMinor: "250000",
  bankName: "Bank Central Asia",
  correctionExpiresAt: null,
  createdAt: "2026-08-10T08:00:00Z",
  currency: "IDR",
  evidenceAttempts: [],
  id: "00000000-0000-4000-8000-000000000601",
  latestRejectionReason: null,
  programId: "00000000-0000-4000-8000-000000000501",
  purpose: "program_enrollment",
  qrisObjectPath: null,
  reservationExpiresAt: "2026-08-11T08:00:00Z",
  status: "awaiting_evidence",
  timezone: "Asia/Makassar",
  version: 1,
};

export function PaymentGallery() {
  return (
    <div className="state-gallery__stack">
      <div data-testid="payment-owner-gallery">
        <PaymentOrderView initialOrder={simulatorPaymentOrder} />
      </div>
      <div data-testid="payment-admin-gallery">
        <AdminPaymentQueue
          filters={{ status: "under_review" }}
          items={[
            {
              ...simulatorPaymentOrder,
              ownerDisplayName: "Peserta Aman",
              ownerEmailHint: "Identitas privat",
              relatedLabel: "Program Transformasi Agustus",
              status: "under_review",
              version: 2,
            },
          ]}
        />
        <AdminPaymentDecision
          order={{ ...simulatorPaymentOrder, status: "under_review", version: 2 }}
        />
      </div>
    </div>
  );
}
