export const AUTH_FLOW_COOKIE = "msc_auth_flow";
export const PENDING_PROGRAM_COOKIE = "msc_pending_program";
export const AUTH_FLOW_TTL_SECONDS = 10 * 60;
export const PENDING_PROGRAM_TTL_SECONDS = 30 * 60;

export type AuthFlowAttempt = Readonly<{
  environment: string;
  expiresAt: number;
  issuedAt: number;
  mode: "login" | "register" | "reauthenticate";
  returnTo: string;
  state: string;
}>;

export type PendingProgramIntent = Readonly<{
  environment: string;
  expiresAt: number;
  programId: string;
}>;

const allowedReturnRoots = [
  "/hari-ini",
  "/program",
  "/peringkat",
  "/profil",
  "/onboarding",
  "/coach-area",
  "/admin",
] as const;

export function safeReturnTo(value: string | null | undefined, fallback = "/hari-ini"): string {
  if (!value || !value.startsWith("/") || value.startsWith("//") || value.includes("\\")) {
    return fallback;
  }

  let parsed: URL;
  try {
    parsed = new URL(value, "https://local.invalid");
  } catch {
    return fallback;
  }

  if (parsed.origin !== "https://local.invalid" || parsed.username || parsed.password) {
    return fallback;
  }

  const isAllowed = allowedReturnRoots.some(
    (root) => parsed.pathname === root || parsed.pathname.startsWith(`${root}/`),
  );
  return isAllowed ? `${parsed.pathname}${parsed.search}${parsed.hash}` : fallback;
}

export function createAuthFlowAttempt(input: {
  environment: string;
  mode: AuthFlowAttempt["mode"];
  now: number;
  returnTo?: string | null;
  state: string;
}): AuthFlowAttempt {
  return {
    environment: input.environment,
    expiresAt: input.now + AUTH_FLOW_TTL_SECONDS,
    issuedAt: input.now,
    mode: input.mode,
    returnTo: safeReturnTo(input.returnTo),
    state: input.state,
  };
}

export function validateAuthFlowAttempt(
  attempt: AuthFlowAttempt,
  input: Readonly<{ environment: string; now: number; state: string }>,
): boolean {
  return (
    attempt.environment === input.environment &&
    attempt.state === input.state &&
    attempt.issuedAt <= input.now &&
    input.now < attempt.expiresAt &&
    attempt.expiresAt - attempt.issuedAt <= AUTH_FLOW_TTL_SECONDS
  );
}

export function createPendingProgramIntent(input: {
  environment: string;
  now: number;
  programId: string;
}): PendingProgramIntent | null {
  if (
    !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(
      input.programId,
    )
  ) {
    return null;
  }
  return {
    environment: input.environment,
    expiresAt: input.now + PENDING_PROGRAM_TTL_SECONDS,
    programId: input.programId,
  };
}

export function isPendingProgramIntentValid(
  intent: PendingProgramIntent,
  input: Readonly<{ environment: string; now: number }>,
): boolean {
  return intent.environment === input.environment && input.now < intent.expiresAt;
}
