import { NextResponse } from "next/server";

import { changeParticipantCoachOperation } from "@/application/participant/participant-profile-operations";

export async function POST(request: Request) {
  let body: { coachQrPayload?: unknown; idempotencyKey?: unknown };
  try {
    body = (await request.json()) as typeof body;
  } catch {
    return NextResponse.json({ code: "request_invalid" }, { status: 400 });
  }
  if (typeof body.coachQrPayload !== "string" || typeof body.idempotencyKey !== "string") {
    return NextResponse.json({ code: "validation_failed" }, { status: 422 });
  }
  const result = await changeParticipantCoachOperation({
    coachQrPayload: body.coachQrPayload,
    idempotencyKey: body.idempotencyKey,
  });
  if (!result.isSuccess)
    return NextResponse.json(
      { code: result.error.code },
      { status: result.error.code === "unauthorized" ? 401 : 422 },
    );
  return NextResponse.json(result.value, { headers: { "Cache-Control": "no-store" } });
}
