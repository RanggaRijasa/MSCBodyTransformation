import { NextResponse } from "next/server";

import { updateCoachProfileOperation } from "@/application/coach/coach-operations";

export async function PATCH(request: Request) {
  let body: { biography?: unknown; city?: unknown; displayName?: unknown; isPublic?: unknown };
  try {
    body = (await request.json()) as typeof body;
  } catch {
    return NextResponse.json({ code: "request_invalid" }, { status: 400 });
  }
  if (
    typeof body.biography !== "string" ||
    typeof body.city !== "string" ||
    typeof body.displayName !== "string" ||
    typeof body.isPublic !== "boolean"
  )
    return NextResponse.json({ code: "validation_failed" }, { status: 422 });
  const result = await updateCoachProfileOperation({
    biography: body.biography,
    city: body.city,
    displayName: body.displayName,
    isPublic: body.isPublic,
  });
  return result.isSuccess
    ? NextResponse.json(result.value, { headers: { "Cache-Control": "no-store" } })
    : NextResponse.json(
        { code: result.error.code },
        {
          status:
            result.error.code === "unauthorized"
              ? 401
              : result.error.code === "forbidden"
                ? 403
                : 422,
        },
      );
}
