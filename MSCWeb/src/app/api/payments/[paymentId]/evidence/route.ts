import { NextResponse } from "next/server";

import {
  downloadLatestPaymentEvidenceOperation,
  uploadPaymentEvidenceOperation,
} from "@/application/payments/payment-operations";
import { loadVerifiedProfile } from "@/features/auth/server/profile-repository";

const privateHeaders = {
  "Cache-Control": "private, no-store, max-age=0",
  Pragma: "no-cache",
  "X-Content-Type-Options": "nosniff",
} as const;

export async function GET(
  _request: Request,
  { params }: Readonly<{ params: Promise<{ paymentId: string }> }>,
) {
  const profile = await loadVerifiedProfile();
  if (!profile.isSuccess)
    return NextResponse.json(
      {
        code: "authentication_required",
        message: "Sesi berakhir. Masuk kembali untuk melanjutkan.",
      },
      { status: 401, headers: privateHeaders },
    );
  const evidence = await downloadLatestPaymentEvidenceOperation((await params).paymentId);
  if (!evidence.isSuccess)
    return NextResponse.json(
      { code: evidence.error.code },
      { status: 404, headers: privateHeaders },
    );
  return new NextResponse(Uint8Array.from(evidence.value.bytes).buffer, {
    headers: { ...privateHeaders, "Content-Type": evidence.value.mimeType },
  });
}

export async function POST(
  request: Request,
  { params }: Readonly<{ params: Promise<{ paymentId: string }> }>,
) {
  const profile = await loadVerifiedProfile();
  if (!profile.isSuccess)
    return NextResponse.json(
      {
        code: "authentication_required",
        message: "Sesi berakhir. Masuk kembali untuk melanjutkan.",
      },
      { status: 401, headers: privateHeaders },
    );
  let body: FormData;
  try {
    body = await request.formData();
  } catch {
    return NextResponse.json({ code: "request_invalid" }, { status: 400, headers: privateHeaders });
  }
  const evidence = body.get("evidence");
  const idempotencyKey = body.get("idempotencyKey");
  if (
    !(evidence instanceof File) ||
    evidence.size <= 0 ||
    evidence.size > 5 * 1024 * 1024 ||
    evidence.type !== "image/jpeg" ||
    typeof idempotencyKey !== "string" ||
    idempotencyKey.length < 8 ||
    idempotencyKey.length > 128
  )
    return NextResponse.json(
      { code: "validation_failed", message: "Bukti pembayaran tidak valid." },
      { status: 422, headers: privateHeaders },
    );
  const result = await uploadPaymentEvidenceOperation({
    idempotencyKey,
    image: new Uint8Array(await evidence.arrayBuffer()),
    mimeType: evidence.type,
    orderId: (await params).paymentId,
  });
  if (!result.isSuccess)
    return NextResponse.json(
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
        headers: privateHeaders,
      },
    );
  return NextResponse.json({ status: result.value.status }, { headers: privateHeaders });
}
