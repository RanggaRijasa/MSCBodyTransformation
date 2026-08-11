import { NextResponse } from "next/server";

import {
  approvePaymentOperation,
  rejectPaymentOperation,
} from "@/application/payments/payment-operations";
import { loadVerifiedProfile } from "@/features/auth/server/profile-repository";

export async function POST(
  request: Request,
  { params }: Readonly<{ params: Promise<{ paymentId: string }> }>,
) {
  const profile = await loadVerifiedProfile();
  if (!profile.isSuccess)
    return NextResponse.json({ code: "authentication_required" }, { status: 401 });
  if (profile.value.role !== "admin")
    return NextResponse.json({ code: "permission_denied" }, { status: 403 });
  let body: Record<string, unknown>;
  try {
    body = (await request.json()) as Record<string, unknown>;
  } catch {
    return NextResponse.json({ code: "request_invalid" }, { status: 400 });
  }
  const paymentId = (await params).paymentId;
  const version = body.version;
  if ((body.decision !== "approve" && body.decision !== "reject") || typeof version !== "number")
    return NextResponse.json({ code: "validation_failed" }, { status: 422 });
  const result =
    body.decision === "approve"
      ? typeof body.amountMinor === "string" &&
        typeof body.reconciliationReference === "string" &&
        typeof body.destinationMatches === "boolean"
        ? await approvePaymentOperation({
            amountMinor: body.amountMinor,
            destinationMatches: body.destinationMatches,
            orderId: paymentId,
            reconciliationReference: body.reconciliationReference,
            version,
          })
        : null
      : typeof body.reason === "string"
        ? await rejectPaymentOperation({
            orderId: paymentId,
            reason: body.reason,
            version,
          })
        : null;
  if (!result) return NextResponse.json({ code: "validation_failed" }, { status: 422 });
  if (!result.isSuccess)
    return NextResponse.json(
      { code: result.error.code, message: result.error.message },
      {
        status:
          result.error.code === "conflict"
            ? 409
            : result.error.code === "validation_failed"
              ? 422
              : result.error.code === "forbidden"
                ? 403
                : 503,
        headers: { "Cache-Control": "private, no-store" },
      },
    );
  return NextResponse.json(
    { status: result.value.status },
    { headers: { "Cache-Control": "private, no-store" } },
  );
}
