import { NextResponse } from "next/server";

import { createProgramPaymentOrderOperation } from "@/application/payments/payment-operations";
import { isProgramIdentifier } from "@/domain/programs/enrollment";

export async function POST(
  request: Request,
  { params }: Readonly<{ params: Promise<{ programId: string }> }>,
) {
  let body: { coachQrPayload?: unknown; idempotencyKey?: unknown };
  try {
    body = (await request.json()) as { coachQrPayload?: unknown; idempotencyKey?: unknown };
  } catch {
    return NextResponse.json({ code: "request_invalid" }, { status: 400 });
  }
  const programId = (await params).programId;
  if (
    !isProgramIdentifier(programId) ||
    typeof body.coachQrPayload !== "string" ||
    body.coachQrPayload.length < 16 ||
    body.coachQrPayload.length > 128 ||
    typeof body.idempotencyKey !== "string" ||
    body.idempotencyKey.length < 8 ||
    body.idempotencyKey.length > 128
  ) {
    return NextResponse.json({ code: "validation_failed" }, { status: 422 });
  }
  const result = await createProgramPaymentOrderOperation({
    coachQrPayload: body.coachQrPayload,
    idempotencyKey: body.idempotencyKey,
    programId,
  });
  return result.isSuccess
    ? NextResponse.json(result.value, { headers: { "Cache-Control": "private, no-store" } })
    : NextResponse.json(
        { code: result.error.code, message: result.error.message },
        {
          status:
            result.error.code === "unauthorized"
              ? 401
              : result.error.code === "forbidden"
                ? 403
                : result.error.code === "conflict"
                  ? 409
                  : result.error.code === "validation_failed"
                    ? 422
                    : 503,
          headers: { "Cache-Control": "private, no-store" },
        },
      );
}
