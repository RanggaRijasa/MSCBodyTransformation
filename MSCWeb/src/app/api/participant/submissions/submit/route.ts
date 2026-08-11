import { NextResponse } from "next/server";

import { submitParticipantAnswersOperation } from "@/application/participant/participant-submission-operations";
import { parseParticipantAnswers } from "@/domain/participant/participant-answer-input";

export async function POST(request: Request) {
  let body: { answers?: unknown; idempotencyKey?: unknown; submissionId?: unknown };
  try {
    body = (await request.json()) as typeof body;
  } catch {
    return NextResponse.json({ code: "request_invalid" }, { status: 400 });
  }
  const answers = parseParticipantAnswers(body.answers);
  if (
    !answers ||
    typeof body.idempotencyKey !== "string" ||
    typeof body.submissionId !== "string"
  ) {
    return NextResponse.json({ code: "validation_failed" }, { status: 422 });
  }
  const result = await submitParticipantAnswersOperation({
    answers,
    idempotencyKey: body.idempotencyKey,
    submissionId: body.submissionId,
  });
  if (!result.isSuccess) {
    const status =
      result.error.code === "unauthorized" ? 401 : result.error.code === "conflict" ? 409 : 422;
    return NextResponse.json({ code: result.error.code }, { status });
  }
  return NextResponse.json(result.value, { headers: { "Cache-Control": "no-store" } });
}
