import type { Metadata } from "next";
import { notFound } from "next/navigation";

import { requireRole } from "@/features/auth/server/session-routing";
import { CoachPaymentEntry } from "@/features/payments";

export const metadata: Metadata = { title: "Pembayaran akses Coach" };

const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export default async function CoachAccessPaymentPage({
  params,
}: Readonly<{ params: Promise<{ applicationId: string }> }>) {
  const { applicationId } = await params;
  if (!uuidPattern.test(applicationId)) notFound();
  await requireRole("participant", `/akses-coach/${applicationId}`);
  return (
    <div className="payment-page">
      <header className="payment-page__header">
        <p className="program-eyebrow">Pengajuan Coach</p>
        <h1>Pembayaran akses Coach</h1>
        <p>Pembayaran hanya tersedia setelah kelayakan disetujui Admin.</p>
      </header>
      <CoachPaymentEntry applicationId={applicationId} />
    </div>
  );
}
