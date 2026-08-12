import { cookies } from "next/headers";

import { loadCoachQrSvgOperation } from "@/application/media/coach-qr-image";
import { coachQrSvgContentSecurityPolicy } from "@/shared/security/content-security-policy";

export const dynamic = "force-dynamic";

export async function GET() {
  const cookieStore = await cookies();
  const hasSupabaseSessionCookie = cookieStore
    .getAll()
    .some(({ name }) => /^sb-.+-auth-token(?:\.\d+)?$/.test(name));
  if (!hasSupabaseSessionCookie) {
    return Response.json(
      { code: "qr_unavailable" },
      { status: 401, headers: { "Cache-Control": "private, no-store" } },
    );
  }
  const result = await loadCoachQrSvgOperation();
  if (!result.isSuccess) {
    const status =
      result.error.code === "unauthorized" ? 401 : result.error.code === "forbidden" ? 403 : 503;
    return Response.json(
      { code: result.error.code === "forbidden" ? "coach_qr_unavailable" : "qr_unavailable" },
      { status, headers: { "Cache-Control": "private, no-store" } },
    );
  }
  return new Response(result.value, {
    headers: {
      "Cache-Control": "private, no-store",
      "Content-Disposition": 'inline; filename="qr-coach-msc.svg"',
      "Content-Security-Policy": coachQrSvgContentSecurityPolicy,
      "Content-Type": "image/svg+xml; charset=utf-8",
      "X-Content-Type-Options": "nosniff",
    },
  });
}
