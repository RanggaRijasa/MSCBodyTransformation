import {
  paymentOrderStatuses,
  type AdminPaymentQueueFilters,
  type AdminPaymentQueueItem,
  type PaymentOrderStatus,
} from "@/domain/payments/payment";
import { PaymentStatus } from "@/features/payments/components/payment-status";
import { formatCurrencyIDR } from "@/shared/formatting/indonesian-formatters";
import { AppButton, AppLink, Metric, Surface } from "@/shared/ui";

export function AdminPaymentQueue({
  filters,
  items,
}: Readonly<{
  filters: AdminPaymentQueueFilters;
  items: readonly AdminPaymentQueueItem[];
}>) {
  const statusLabels: Record<PaymentOrderStatus, string> = {
    approved: "Terverifikasi",
    awaiting_evidence: "Menunggu bukti",
    cancelled: "Dibatalkan",
    correction_required: "Perlu perbaikan",
    expired: "Kedaluwarsa",
    rejected: "Tidak dapat diverifikasi",
    reversal_pending: "Penyelesaian khusus diproses",
    reversed: "Penyelesaian khusus selesai",
    under_review: "Menunggu pemeriksaan",
  };
  return (
    <div className="payment-page">
      <header className="payment-page__header">
        <p className="program-eyebrow">Antrean privat</p>
        <h1>Pembayaran</h1>
        <p>Periksa nominal, rekening tujuan, referensi mutasi, dan bukti sebelum memutuskan.</p>
      </header>
      <div className="payment-metrics">
        <Surface>
          <Metric
            label="Menunggu pemeriksaan"
            value={String(items.filter((item) => item.status === "under_review").length)}
          />
        </Surface>
        <Surface>
          <Metric
            label="Perlu perbaikan"
            value={String(items.filter((item) => item.status === "correction_required").length)}
          />
        </Surface>
        <Surface>
          <Metric
            label="Penyelesaian khusus"
            value={String(items.filter((item) => item.status === "reversal_pending").length)}
          />
        </Surface>
      </div>
      <Surface className="payment-filters">
        <h2>Filter antrean</h2>
        <form action="/admin/pembayaran" method="get">
          <label>
            Cari
            <input
              defaultValue={filters.search}
              name="q"
              placeholder="Nama atau program"
              type="search"
            />
          </label>
          <label>
            Jenis pembayaran
            <select defaultValue={filters.purpose ?? ""} name="jenis">
              <option value="">Semua jenis</option>
              <option value="program_enrollment">Program</option>
              <option value="coach_access">Akses Coach</option>
            </select>
          </label>
          <label>
            Status
            <select defaultValue={filters.status ?? ""} name="status">
              <option value="">Semua status</option>
              {paymentOrderStatuses.map((status) => (
                <option key={status} value={status}>
                  {statusLabels[status]}
                </option>
              ))}
            </select>
          </label>
          <label>
            Dari tanggal
            <input defaultValue={filters.createdFrom} name="dari" type="date" />
          </label>
          <label>
            Sampai tanggal
            <input defaultValue={filters.createdTo} name="sampai" type="date" />
          </label>
          <div className="media-action-row">
            <AppButton type="submit">Terapkan filter</AppButton>
            <AppLink href="/admin/pembayaran" variant="secondary">
              Hapus filter
            </AppLink>
          </div>
        </form>
      </Surface>
      <div className="payment-queue" aria-label="Antrean pembayaran">
        {items.length === 0 ? (
          <Surface>
            <h2>Antrean kosong</h2>
            <p>Belum ada pembayaran yang perlu ditampilkan.</p>
          </Surface>
        ) : (
          items.map((item) => (
            <Surface className="payment-queue__item" key={item.id}>
              <div>
                <PaymentStatus status={item.status} />
                <h2>{item.ownerDisplayName}</h2>
                <p>{item.purpose === "program_enrollment" ? "Program" : "Akses Coach"}</p>
                <p>{item.relatedLabel}</p>
                <strong className="monospaced-numeric">
                  {formatCurrencyIDR.format(Number(item.amountMinor))}
                </strong>
              </div>
              <AppLink href={`/admin/pembayaran/${item.id}`} variant="secondary">
                Periksa detail
              </AppLink>
            </Surface>
          ))
        )}
      </div>
    </div>
  );
}
