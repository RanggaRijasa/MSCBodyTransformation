import { cookies } from "next/headers";
import { NextResponse, type NextRequest } from "next/server";

import { createGoogleAuthorizationUrl } from "@/application/auth/server-auth-operations";
import {
  AUTH_FLOW_COOKIE,
  createAuthFlowAttempt,
  safeReturnTo,
} from "@/features/auth/model/auth-flow";
import { readAuthServerEnvironment } from "@/features/auth/server/auth-environment";
import { sealCookie } from "@/features/auth/server/sealed-cookie";
import {
  consumeRequestLimit,
  opaqueRequestFingerprint,
} from "@/shared/security/request-rate-limiter";

export async function GET(request: NextRequest) {
  const requestLimit = consumeRequestLimit(
    "auth-google-start",
    opaqueRequestFingerprint(request.headers),
    { limit: 10, windowMs: 60_000 },
  );
  if (!requestLimit.allowed) {
    return NextResponse.json(
      { code: "rate_limited", message: "Terlalu banyak percobaan. Coba lagi sebentar." },
      {
        headers: {
          "Cache-Control": "private, no-store",
          "Retry-After": String(requestLimit.retryAfterSeconds),
        },
        status: 429,
      },
    );
  }
  try {
    const serverEnvironment = readAuthServerEnvironment();
    const modeValue = request.nextUrl.searchParams.get("mode");
    const mode = modeValue === "register" || modeValue === "reauthenticate" ? modeValue : "login";
    const state = crypto.randomUUID();
    const returnTo = safeReturnTo(request.nextUrl.searchParams.get("returnTo"));
    const attempt = createAuthFlowAttempt({
      environment: serverEnvironment.environmentName,
      mode,
      now: Math.floor(Date.now() / 1000),
      returnTo,
      state,
    });
    const callbackUrl = new URL("/auth/callback", request.nextUrl.origin);
    callbackUrl.searchParams.set("state", state);

    const authorizationUrl = await createGoogleAuthorizationUrl(callbackUrl.toString());
    if (!authorizationUrl) {
      return NextResponse.redirect(new URL("/masuk?error=provider", request.url));
    }

    (await cookies()).set(
      AUTH_FLOW_COOKIE,
      await sealCookie(attempt, serverEnvironment.cookieSecret),
      {
        httpOnly: true,
        maxAge: 10 * 60,
        path: "/",
        sameSite: "lax",
        secure: request.nextUrl.protocol === "https:",
      },
    );
    return NextResponse.redirect(authorizationUrl);
  } catch {
    return NextResponse.redirect(new URL("/masuk?error=configuration", request.url));
  }
}
