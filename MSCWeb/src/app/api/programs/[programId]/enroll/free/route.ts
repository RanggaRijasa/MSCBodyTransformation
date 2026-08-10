import { NextResponse } from "next/server";

import { enrollFreeProgramOperation } from "@/application/programs/program-enrollment-operations";

export async function POST(
  request: Request,
  { params }: Readonly<{ params: Promise<{ programId: string }> }>,
) {
  let body: { coachQrPayload?: unknown };
  try {
    body = (await request.json()) as { coachQrPayload?: unknown };
  } catch {
    return NextResponse.json({ code: "request_invalid" }, { status: 400 });
  }
  if (typeof body.coachQrPayload !== "string") {
    return NextResponse.json({ code: "coach_qr_required" }, { status: 422 });
  }
  const result = await enrollFreeProgramOperation((await params).programId, body.coachQrPayload);
  if (!result.isSuccess) {
    const status =
      result.error.code === "unauthorized"
        ? 401
        : result.error.code === "forbidden"
          ? 403
          : result.error.code === "validation_failed"
            ? 422
            : result.error.code === "conflict"
              ? 409
              : 503;
    return NextResponse.json(
      { code: result.error.code, message: result.error.message },
      { status, headers: { "Cache-Control": "private, no-store" } },
    );
  }
  return NextResponse.json(result.value, {
    headers: { "Cache-Control": "private, no-store" },
  });
}
