import type { AppRole, OnboardingStatus } from "@/features/auth/model/auth-model";

export type SessionRootState =
  | Readonly<{ kind: "guest" }>
  | Readonly<{ kind: "offline"; canRetry: true }>
  | Readonly<{ kind: "expired"; canRetry: true }>
  | Readonly<{ kind: "revoked"; canRetry: false }>
  | Readonly<{ kind: "onboarding" }>
  | Readonly<{ kind: "authenticated"; role: AppRole }>
  | Readonly<{ kind: "stale_role"; destinationRole: AppRole }>;

type SessionSignal = Readonly<{
  claimedRole?: AppRole | undefined;
  hasIdentity: boolean;
  isExpired?: boolean | undefined;
  isOffline?: boolean | undefined;
  isRevoked?: boolean | undefined;
  onboardingStatus?: OnboardingStatus | undefined;
  protectedRole?: AppRole | undefined;
}>;

export function resolveSessionRoot(signal: SessionSignal): SessionRootState {
  if (signal.isOffline) return { canRetry: true, kind: "offline" };
  if (!signal.hasIdentity) return { kind: "guest" };
  if (signal.isRevoked) return { canRetry: false, kind: "revoked" };
  if (signal.isExpired) return { canRetry: true, kind: "expired" };
  if (!signal.protectedRole || !signal.onboardingStatus) return { canRetry: true, kind: "expired" };
  if (signal.onboardingStatus !== "active") return { kind: "onboarding" };
  if (signal.claimedRole && signal.claimedRole !== signal.protectedRole) {
    return { destinationRole: signal.protectedRole, kind: "stale_role" };
  }
  return { kind: "authenticated", role: signal.protectedRole };
}
