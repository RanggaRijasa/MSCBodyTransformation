import { NextResponse } from "next/server";

import { downloadPaymentQrisOperation } from "@/application/payments/payment-operations";

export async function GET(
  _request: Request,
  { params }: Readonly<{ params: Promise<{ paymentId: string }> }>,
) {
  const { paymentId } = await params;
  const result = await downloadPaymentQrisOperation(paymentId);
  if (!result.isSuccess)
    return NextResponse.json(
      { message: "QRIS pembayaran tidak tersedia." },
      { headers: { "Cache-Control": "no-store" }, status: 404 },
    );
  return new NextResponse(Uint8Array.from(result.value.bytes).buffer, {
    headers: {
      "Cache-Control": "private, no-store, max-age=0",
      "Content-Type": result.value.mimeType,
      "X-Content-Type-Options": "nosniff",
    },
  });
}
