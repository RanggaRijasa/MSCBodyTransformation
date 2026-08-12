import { NextResponse, type NextRequest } from "next/server";

import { emitSafeOperationalEvent } from "@/application/observability/safe-operational-event";
import { updateSupabaseSession } from "@/infrastructure/supabase/session/update-session";
import {
  buildContentSecurityPolicy,
  selectResponseContentSecurityPolicy,
} from "@/shared/security/content-security-policy";
import { hasTrustedMutationOrigin } from "@/shared/security/mutation-origin";

const unsafeMethods = new Set(["DELETE", "PATCH", "POST", "PUT"]);

export async function proxy(request: NextRequest) {
  const correlationId = crypto.randomUUID();
  if (
    request.nextUrl.pathname.startsWith("/api/") &&
    unsafeMethods.has(request.method) &&
    !hasTrustedMutationOrigin(request)
  ) {
    emitSafeOperationalEvent({ correlationId, event: "request_origin_rejected" });
    return NextResponse.json(
      { code: "origin_rejected", message: "Asal permintaan tidak diizinkan." },
      {
        headers: {
          "Cache-Control": "private, no-store",
          "X-Correlation-ID": correlationId,
        },
        status: 403,
      },
    );
  }
  const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
  const policy = buildContentSecurityPolicy({
    isDevelopment: process.env.NODE_ENV === "development",
    nonce,
    requestOrigin: request.nextUrl.origin,
    supabaseUrl: process.env.NEXT_PUBLIC_SUPABASE_URL,
  });
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("Content-Security-Policy", policy);
  requestHeaders.set("x-nonce", nonce);
  requestHeaders.set("x-msc-correlation-id", correlationId);
  const response = await updateSupabaseSession(request, requestHeaders);
  response.headers.set(
    "Content-Security-Policy",
    selectResponseContentSecurityPolicy(request.nextUrl.pathname, policy),
  );
  response.headers.set("X-Correlation-ID", correlationId);
  return response;
}

export const config = {
  matcher: [
    "/((?!_next/static|_next/image|favicon.ico|sw.js|offline.html|manifest.webmanifest|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)",
  ],
};
