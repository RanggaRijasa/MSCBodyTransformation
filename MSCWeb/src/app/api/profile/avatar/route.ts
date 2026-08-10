import { NextResponse } from "next/server";

import { updateParticipantAvatarOperation } from "@/application/participant/participant-profile-operations";

export async function POST(request: Request) {
  let form: FormData;
  try {
    form = await request.formData();
  } catch {
    return NextResponse.json({ code: "request_invalid" }, { status: 400 });
  }
  const image = form.get("image");
  const idempotencyKey = form.get("idempotencyKey");
  if (!(image instanceof File) || typeof idempotencyKey !== "string") {
    return NextResponse.json({ code: "validation_failed" }, { status: 422 });
  }
  const result = await updateParticipantAvatarOperation({
    bytes: new Uint8Array(await image.arrayBuffer()),
    declaredMimeType: image.type,
    idempotencyKey,
  });
  if (!result.isSuccess)
    return NextResponse.json(
      { code: result.error.code },
      { status: result.error.code === "unauthorized" ? 401 : 422 },
    );
  return NextResponse.json(result.value, { headers: { "Cache-Control": "no-store" } });
}
