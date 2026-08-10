import { NextResponse } from "next/server";

import { reviewCoachSubmissionOperation } from "@/application/coach/coach-operations";

export async function POST(
  request: Request,
  { params }: Readonly<{ params: Promise<{ submissionId: string }> }>,
) {
  let body: { decision?: unknown; idempotencyKey?: unknown; reason?: unknown };
  try {
    body = (await request.json()) as typeof body;
  } catch {
    return NextResponse.json({ code: "request_invalid" }, { status: 400 });
  }
  const { submissionId } = await params;
  if (
    (body.decision !== "approved" && body.decision !== "rejected") ||
    typeof body.idempotencyKey !== "string" ||
    (body.reason !== undefined && typeof body.reason !== "string")
  )
    return NextResponse.json({ code: "validation_failed" }, { status: 422 });
  const result = await reviewCoachSubmissionOperation({
    decision: body.decision,
    idempotencyKey: body.idempotencyKey,
    ...(typeof body.reason === "string" ? { reason: body.reason } : {}),
    submissionId,
  });
  if (!result.isSuccess)
    return NextResponse.json(
      { code: result.error.code },
      {
        status:
          result.error.code === "unauthorized"
            ? 401
            : result.error.code === "forbidden"
              ? 403
              : result.error.code === "conflict"
                ? 409
                : 422,
        headers: { "Cache-Control": "no-store" },
      },
    );
  return NextResponse.json(result.value, { headers: { "Cache-Control": "no-store" } });
}
