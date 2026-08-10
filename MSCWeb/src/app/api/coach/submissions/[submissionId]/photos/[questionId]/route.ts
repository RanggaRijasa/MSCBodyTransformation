import { NextResponse } from "next/server";

import { downloadCoachQuestionPhotoOperation } from "@/application/coach/coach-operations";

export async function GET(
  _request: Request,
  { params }: Readonly<{ params: Promise<{ questionId: string; submissionId: string }> }>,
) {
  const { questionId, submissionId } = await params;
  const result = await downloadCoachQuestionPhotoOperation(submissionId, questionId);
  if (!result.isSuccess)
    return NextResponse.json(
      { code: result.error.code },
      {
        status: result.error.code === "unauthorized" ? 401 : 403,
        headers: { "Cache-Control": "no-store" },
      },
    );
  return new NextResponse(result.value, {
    headers: {
      "Cache-Control": "private, no-store, max-age=0",
      "Content-Disposition": "inline",
      "Content-Type": "image/jpeg",
      Pragma: "no-cache",
      Vary: "Cookie",
    },
  });
}
