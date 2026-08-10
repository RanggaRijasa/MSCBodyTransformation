import { cookies } from "next/headers";
import { NextResponse, type NextRequest } from "next/server";

import { exchangeAuthorizationCode } from "@/application/auth/server-auth-operations";
import {
  AUTH_FLOW_COOKIE,
  type AuthFlowAttempt,
  safeReturnTo,
  validateAuthFlowAttempt,
} from "@/features/auth/model/auth-flow";
import { readAuthServerEnvironment } from "@/features/auth/server/auth-environment";
import { unsealCookie } from "@/features/auth/server/sealed-cookie";

function failureRedirect(request: NextRequest, reason: string) {
  const url = new URL("/masuk", request.nextUrl.origin);
  url.searchParams.set("error", reason);
  return NextResponse.redirect(url);
}

export async function GET(request: NextRequest) {
  const cookieStore = await cookies();
  const clearAttempt = () => cookieStore.delete(AUTH_FLOW_COOKIE);

  try {
    const code = request.nextUrl.searchParams.get("code");
    const state = request.nextUrl.searchParams.get("state");
    const providerError = request.nextUrl.searchParams.get("error");
    if (providerError) {
      clearAttempt();
      return failureRedirect(request, providerError === "access_denied" ? "cancelled" : "provider");
    }
    if (!code || !state) {
      clearAttempt();
      return failureRedirect(request, "callback");
    }

    const serverEnvironment = readAuthServerEnvironment();
    const sealedAttempt = cookieStore.get(AUTH_FLOW_COOKIE)?.value;
    const attempt = sealedAttempt
      ? await unsealCookie<AuthFlowAttempt>(sealedAttempt, serverEnvironment.cookieSecret)
      : null;
    if (
      !attempt ||
      !validateAuthFlowAttempt(attempt, {
        environment: serverEnvironment.environmentName,
        now: Math.floor(Date.now() / 1000),
        state,
      })
    ) {
      clearAttempt();
      return failureRedirect(request, "state");
    }

    const didExchange = await exchangeAuthorizationCode(code);
    clearAttempt();
    if (!didExchange) {
      return failureRedirect(request, "exchange");
    }

    if (attempt.mode === "register") {
      return NextResponse.redirect(new URL("/onboarding", request.nextUrl.origin));
    }
    return NextResponse.redirect(new URL(safeReturnTo(attempt.returnTo), request.nextUrl.origin));
  } catch {
    clearAttempt();
    return failureRedirect(request, "callback");
  }
}
