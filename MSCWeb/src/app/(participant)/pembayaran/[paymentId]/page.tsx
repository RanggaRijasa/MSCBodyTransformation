import type { Metadata } from "next";
import { notFound } from "next/navigation";

import { loadPaymentOrderOperation } from "@/application/payments/payment-operations";
import { PaymentOrderView } from "@/features/payments";
import { requireVerifiedProfile } from "@/features/auth/server/session-routing";

export const metadata: Metadata = { title: "Pembayaran" };

export default async function PaymentPage({
  params,
}: Readonly<{ params: Promise<{ paymentId: string }> }>) {
  const { paymentId } = await params;
  await requireVerifiedProfile(`/pembayaran/${paymentId}`);
  const order = await loadPaymentOrderOperation(paymentId);
  if (!order.isSuccess) notFound();
  return <PaymentOrderView initialOrder={order.value} />;
}
