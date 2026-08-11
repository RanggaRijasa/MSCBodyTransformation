import { NextResponse } from "next/server";

import { createCoachPaymentOrderOperation } from "@/application/payments/payment-operations";

const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export async function POST(
  request: Request,
  { params }: Readonly<{ params: Promise<{ applicationId: string }> }>,
) {
  const { applicationId } = await params;
  const payload = (await request.json().catch(() => null)) as { idempotencyKey?: string } | null;
  if (
    !uuidPattern.test(applicationId) ||
    !payload?.idempotencyKey ||
    payload.idempotencyKey.length < 8 ||
    payload.idempotencyKey.length > 128
  )
    return NextResponse.json({ message: "Permintaan pembayaran tidak valid." }, { status: 400 });
  const result = await createCoachPaymentOrderOperation({
    applicationId,
    idempotencyKey: payload.idempotencyKey,
  });
  if (!result.isSuccess)
    return NextResponse.json(
      { message: result.error.message },
      { status: result.error.code === "unauthorized" ? 401 : 409 },
    );
  return NextResponse.json(result.value, {
    headers: { "Cache-Control": "no-store" },
    status: 201,
  });
}
