import { cookies } from "next/headers";
import type { NextRequest } from "next/server";

import { exchangeAuthorizationCode } from "@/application/auth/server-auth-operations";
import {
  AUTH_FLOW_COOKIE,
  type AuthFlowAttempt,
  safeReturnTo,
  validateAuthFlowAttempt,
} from "@/features/auth/model/auth-flow";
import { readAuthServerEnvironment } from "@/features/auth/server/auth-environment";
import { unsealCookie } from "@/features/auth/server/sealed-cookie";
import { relativeRedirect } from "@/shared/security/relative-redirect";

function failureRedirect(reason: string) {
  return relativeRedirect(`/masuk?${new URLSearchParams({ error: reason }).toString()}`);
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
      return failureRedirect(providerError === "access_denied" ? "cancelled" : "provider");
    }
    if (!code || !state) {
      clearAttempt();
      return failureRedirect("callback");
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
      return failureRedirect("state");
    }

    const didExchange = await exchangeAuthorizationCode(code);
    clearAttempt();
    if (!didExchange) {
      return failureRedirect("exchange");
    }

    if (attempt.mode === "register") {
      return relativeRedirect("/onboarding");
    }
    return relativeRedirect(safeReturnTo(attempt.returnTo));
  } catch {
    clearAttempt();
    return failureRedirect("callback");
  }
}
