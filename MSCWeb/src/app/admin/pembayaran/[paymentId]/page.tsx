import type { Metadata } from "next";
import Image from "next/image";
import { notFound } from "next/navigation";

import {
  loadAdminPaymentHistoryOperation,
  loadAdminPaymentOrderOperation,
} from "@/application/payments/payment-operations";
import { requireRole } from "@/features/auth/server/session-routing";
import { AdminPaymentDecision, PaymentStatus } from "@/features/payments";
import { AdminPaymentHistory } from "@/features/payments/components/admin-payment-history";
import {
  createProgramDateTimeFormatter,
  formatCurrencyIDR,
  programTimezoneLabel,
} from "@/shared/formatting/indonesian-formatters";
import { Surface } from "@/shared/ui";

export const metadata: Metadata = { title: "Periksa pembayaran" };

export default async function AdminPaymentDetailPage({
  params,
}: Readonly<{ params: Promise<{ paymentId: string }> }>) {
  const { paymentId } = await params;
  await requireRole("admin", `/admin/pembayaran/${paymentId}`);
  const order = await loadAdminPaymentOrderOperation(paymentId);
  if (!order.isSuccess) notFound();
  const history = await loadAdminPaymentHistoryOperation(paymentId);
  const hasEvidence = order.value.evidenceAttempts.some((attempt) => attempt.submittedAt);
  return (
    <div className="payment-page">
      <header className="payment-page__header">
        <p className="program-eyebrow">Pemeriksaan privat</p>
        <h1>Detail pembayaran</h1>
        <PaymentStatus status={order.value.status} />
      </header>
      <Surface className="payment-instructions">
        <dl>
          <div>
            <dt>Nominal pesanan</dt>
            <dd>{formatCurrencyIDR.format(Number(order.value.amountMinor))}</dd>
          </div>
          <div>
            <dt>Bank tujuan</dt>
            <dd>{order.value.bankName}</dd>
          </div>
          <div>
            <dt>Nama pemilik</dt>
            <dd>{order.value.accountName}</dd>
          </div>
          <div>
            <dt>Referensi rekening</dt>
            <dd>{order.value.accountReference}</dd>
          </div>
          <div>
            <dt>Pemilik akun</dt>
            <dd>{order.value.ownerDisplayName}</dd>
          </div>
          <div>
            <dt>Terkait</dt>
            <dd>{order.value.relatedLabel}</dd>
          </div>
          <div>
            <dt>Jenis</dt>
            <dd>{order.value.purpose === "program_enrollment" ? "Program" : "Akses Coach"}</dd>
          </div>
          <div>
            <dt>Dibuat</dt>
            <dd>
              {createProgramDateTimeFormatter(order.value.timezone).format(
                new Date(order.value.createdAt),
              )}{" "}
              {programTimezoneLabel(order.value.timezone)}
            </dd>
          </div>
          <div>
            <dt>Versi keputusan</dt>
            <dd className="monospaced-numeric">{order.value.version}</dd>
          </div>
        </dl>
      </Surface>
      {hasEvidence ? (
        <Surface>
          <h2>Bukti terbaru</h2>
          <div className="payment-evidence-viewer">
            <Image
              alt="Bukti transfer privat"
              height={800}
              loading="eager"
              src={`/api/payments/${order.value.id}/evidence`}
              unoptimized
              width={800}
            />
          </div>
          <h3>Riwayat attempt</h3>
          <ol>
            {order.value.evidenceAttempts.map((attempt) => (
              <li key={attempt.id}>
                Attempt {attempt.attemptNumber}: {attempt.status}
                {attempt.submittedAt
                  ? ` — ${createProgramDateTimeFormatter(order.value.timezone).format(new Date(attempt.submittedAt))} ${programTimezoneLabel(order.value.timezone)}`
                  : ""}
                {attempt.rejectionReason ? ` — ${attempt.rejectionReason}` : ""}
              </li>
            ))}
          </ol>
        </Surface>
      ) : null}
      <AdminPaymentDecision order={order.value} />
      {history.isSuccess ? (
        <AdminPaymentHistory
          events={history.value.events}
          ledger={history.value.ledger}
          order={order.value}
        />
      ) : null}
    </div>
  );
}
