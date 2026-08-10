import { NextResponse } from "next/server";

import { submitParticipantWeighInOperation } from "@/application/participant/participant-submission-operations";

export async function POST(request: Request) {
  let body: {
    enrollmentId?: unknown;
    idempotencyKey?: unknown;
    kind?: unknown;
    stepId?: unknown;
    weight?: unknown;
  };
  try {
    body = (await request.json()) as typeof body;
  } catch {
    return NextResponse.json({ code: "request_invalid" }, { status: 400 });
  }
  if (
    typeof body.enrollmentId !== "string" ||
    typeof body.idempotencyKey !== "string" ||
    !["initial", "daily", "final"].includes(String(body.kind)) ||
    typeof body.stepId !== "string" ||
    typeof body.weight !== "string"
  ) {
    return NextResponse.json({ code: "validation_failed" }, { status: 422 });
  }
  const result = await submitParticipantWeighInOperation({
    enrollmentId: body.enrollmentId,
    idempotencyKey: body.idempotencyKey,
    kind: body.kind as "daily" | "final" | "initial",
    stepId: body.stepId,
    weight: body.weight,
  });
  if (!result.isSuccess) {
    const status =
      result.error.code === "unauthorized" ? 401 : result.error.code === "conflict" ? 409 : 422;
    return NextResponse.json({ code: result.error.code }, { status });
  }
  return NextResponse.json(result.value, { headers: { "Cache-Control": "no-store" } });
}
