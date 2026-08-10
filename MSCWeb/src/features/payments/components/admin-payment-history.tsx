import type {
  AdminPaymentEvent,
  AdminPaymentLedgerEntry,
  PaymentOrder,
} from "@/domain/payments/payment";
import {
  cancelPaymentOrderAction,
  recordExceptionalReversalAction,
} from "@/application/admin/admin-mutations";
import {
  createProgramDateTimeFormatter,
  formatCurrencyIDR,
} from "@/shared/formatting/indonesian-formatters";
import { AppButton, ListRow, Surface } from "@/shared/ui";

const eventLabels: Readonly<Record<string, string>> = {
  order_created: "Pesanan dibuat",
  reservation_expired: "Reservasi kedaluwarsa",
  reservation_restored: "Reservasi dipulihkan",
  upload_intent_created: "Slot bukti dibuat",
  evidence_submitted: "Bukti dikirim",
  evidence_rejected: "Bukti ditolak",
  payment_approved: "Pembayaran disetujui",
  order_cancelled: "Pesanan dibatalkan",
  reversal_required: "Penyelesaian khusus diperlukan",
  reversal_recorded: "Penyelesaian khusus dicatat",
  entitlement_projected: "Hak akses diproyeksikan",
  enrollment_projected: "Enrollment diproyeksikan",
  evidence_deleted: "Bukti dihapus sesuai retensi",
};

export function AdminPaymentHistory({
  events,
  ledger,
  order,
}: Readonly<{
  events: readonly AdminPaymentEvent[];
  ledger: readonly AdminPaymentLedgerEntry[];
  order: PaymentOrder;
}>) {
  const formatter = createProgramDateTimeFormatter(order.timezone);
  const canCancel = ["awaiting_evidence", "correction_required", "expired"].includes(order.status);
  const canReverse = order.status === "approved" || order.status === "reversal_pending";
  return (
    <>
      <Surface>
        <h2>Ledger immutable</h2>
        {ledger.length ? (
          ledger.map((entry) => (
            <ListRow
              detail={`${formatCurrencyIDR.format(Number(entry.amountMinor))} • ${entry.reconciliationReference} • ${formatter.format(new Date(entry.verifiedAt))}`}
              key={`${entry.kind}-${entry.verifiedAt}`}
              title={entry.kind === "verified" ? "Verifikasi" : "Penyelesaian khusus"}
            />
          ))
        ) : (
          <p>Belum ada entri ledger.</p>
        )}
      </Surface>
      <Surface>
        <h2>Riwayat peristiwa</h2>
        {events.map((event) => (
          <ListRow
            detail={formatter.format(new Date(event.createdAt))}
            key={event.id}
            title={eventLabels[event.type] ?? "Peristiwa pembayaran"}
          />
        ))}
      </Surface>
      {canCancel ? (
        <Surface>
          <h2>Batalkan pesanan</h2>
          <p>Pembatalan tidak tersedia setelah pembayaran disetujui.</p>
          <form action={cancelPaymentOrderAction}>
            <input name="orderId" type="hidden" value={order.id} />
            <AppButton type="submit" variant="destructive">
              Batalkan pesanan
            </AppButton>
          </form>
        </Surface>
      ) : null}
      {canReverse ? (
        <Surface className="payment-reversal">
          <h2>Penyelesaian khusus</h2>
          <p>
            Bukan refund yang dapat diminta peserta. Gunakan hanya untuk koreksi operasional yang
            disetujui.
          </p>
          <form action={recordExceptionalReversalAction}>
            <input name="orderId" type="hidden" value={order.id} />
            <label>
              Referensi transaksi balik
              <input name="reference" required />
            </label>
            <label>
              Alasan dan catatan penyelesaian
              <textarea name="reason" required />
            </label>
            <label className="payment-decision__check">
              <input name="completed" type="checkbox" />
              Transfer balik sudah diselesaikan
            </label>
            <AppButton type="submit" variant="destructive">
              Catat penyelesaian khusus
            </AppButton>
          </form>
        </Surface>
      ) : null}
    </>
  );
}
