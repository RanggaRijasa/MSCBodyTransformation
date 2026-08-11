import type { PaymentDestinationSummary } from "@/domain/payments/payment";
import { createPaymentDestinationAction } from "@/application/admin/admin-mutations";
import { createProgramDateTimeFormatter } from "@/shared/formatting/indonesian-formatters";
import { AppButton, StatusBadge, Surface } from "@/shared/ui";

export function AdminPaymentDestinations({
  destinations,
}: Readonly<{ destinations: readonly PaymentDestinationSummary[] }>) {
  const formatter = createProgramDateTimeFormatter("Asia/Jakarta");
  return (
    <details className="payment-destinations">
      <summary>Tujuan pembayaran</summary>
      <div className="payment-destination-grid">
        {destinations.map((destination) => (
          <Surface key={destination.id}>
            <StatusBadge tone={destination.status === "active" ? "success" : "neutral"}>
              {destination.status}
            </StatusBadge>
            <h3>
              Versi {destination.version} • {destination.bankName}
            </h3>
            <p>{destination.accountName}</p>
            <p>{destination.accountReference}</p>
            <p>Berlaku {formatter.format(new Date(destination.effectiveFrom))}</p>
          </Surface>
        ))}
      </div>
      <Surface>
        <h3>Buat versi tujuan baru</h3>
        <p>
          Pesanan lama tetap menyimpan snapshot versi sebelumnya. QRIS dikelola sebagai aset privat
          terpisah.
        </p>
        <form action={createPaymentDestinationAction}>
          <label>
            Kode bank
            <input name="bankCode" required />
          </label>
          <label>
            Nama bank
            <input name="bankName" required />
          </label>
          <label>
            Nama pemilik
            <input name="accountName" required />
          </label>
          <label>
            Referensi rekening
            <input name="accountReference" required />
          </label>
          <label>
            Mulai berlaku
            <input name="effectiveAt" required type="datetime-local" />
          </label>
          <AppButton type="submit">Buat versi baru</AppButton>
        </form>
      </Surface>
    </details>
  );
}
