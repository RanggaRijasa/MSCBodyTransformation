import type { PaymentOrderStatus } from "@/domain/payments/payment";
import { StatusBadge, type StatusTone } from "@/shared/ui";

const statusPresentation: Readonly<
  Record<PaymentOrderStatus, Readonly<{ label: string; tone: StatusTone }>>
> = {
  approved: { label: "Terverifikasi", tone: "success" },
  awaiting_evidence: { label: "Menunggu bukti", tone: "warning" },
  cancelled: { label: "Dibatalkan", tone: "neutral" },
  correction_required: { label: "Perlu perbaikan", tone: "error" },
  expired: { label: "Kedaluwarsa", tone: "neutral" },
  rejected: { label: "Tidak dapat diverifikasi", tone: "error" },
  reversal_pending: { label: "Penyelesaian khusus diproses", tone: "warning" },
  reversed: { label: "Penyelesaian khusus selesai", tone: "neutral" },
  under_review: { label: "Menunggu pemeriksaan", tone: "info" },
};

export function PaymentStatus({ status }: Readonly<{ status: PaymentOrderStatus }>) {
  const presentation = statusPresentation[status];
  return <StatusBadge tone={presentation.tone}>{presentation.label}</StatusBadge>;
}
