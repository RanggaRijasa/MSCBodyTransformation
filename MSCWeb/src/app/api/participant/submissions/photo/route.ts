import { NextResponse } from "next/server";

import { uploadParticipantQuestionPhotoOperation } from "@/application/participant/participant-submission-operations";

export async function POST(request: Request) {
  let form: FormData;
  try {
    form = await request.formData();
  } catch {
    return NextResponse.json({ code: "request_invalid" }, { status: 400 });
  }
  const image = form.get("image");
  const questionId = form.get("questionId");
  const submissionId = form.get("submissionId");
  if (
    !(image instanceof File) ||
    typeof questionId !== "string" ||
    typeof submissionId !== "string"
  ) {
    return NextResponse.json({ code: "validation_failed" }, { status: 422 });
  }
  const result = await uploadParticipantQuestionPhotoOperation({
    bytes: new Uint8Array(await image.arrayBuffer()),
    declaredMimeType: image.type,
    questionId,
    submissionId,
  });
  if (!result.isSuccess) {
    const status =
      result.error.code === "unauthorized" ? 401 : result.error.code === "forbidden" ? 403 : 422;
    return NextResponse.json({ code: result.error.code }, { status });
  }
  return NextResponse.json(result.value, { headers: { "Cache-Control": "no-store" } });
}
