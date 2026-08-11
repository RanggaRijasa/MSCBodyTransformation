export type InstallStateKind =
  | "dismissed"
  | "ios-guidance"
  | "manual-guidance"
  | "not-ready"
  | "prompt-ready"
  | "standalone"
  | "unsupported";

export type InstallState = Readonly<{
  kind: InstallStateKind;
}>;

export type InstallCapability = Readonly<{
  hasCustomPrompt: boolean;
  isIOS: boolean;
  isInstallReadinessGateOpen: boolean;
  isStandalone: boolean;
  supportsManualInstall: boolean;
}>;

export type InstallTransition =
  | Readonly<{ type: "capability-detected"; capability: InstallCapability }>
  | Readonly<{ type: "custom-prompt-available" }>
  | Readonly<{ outcome: "accepted" | "dismissed"; type: "prompt-consumed" }>
  | Readonly<{ type: "standalone-detected" }>;

export const initialInstallState: InstallState = { kind: "not-ready" };

export function resolveInstallState(capability: InstallCapability): InstallState {
  if (capability.isStandalone) return { kind: "standalone" };
  if (capability.hasCustomPrompt) return { kind: "prompt-ready" };
  if (!capability.isInstallReadinessGateOpen) return { kind: "not-ready" };
  if (capability.isIOS) return { kind: "ios-guidance" };
  if (capability.supportsManualInstall) return { kind: "manual-guidance" };
  return { kind: "unsupported" };
}

export function transitionInstallState(
  state: InstallState,
  transition: InstallTransition,
): InstallState {
  switch (transition.type) {
    case "capability-detected":
      return resolveInstallState(transition.capability);
    case "custom-prompt-available":
      return state.kind === "standalone" ? state : { kind: "prompt-ready" };
    case "prompt-consumed":
      return transition.outcome === "dismissed" ? { kind: "dismissed" } : { kind: "not-ready" };
    case "standalone-detected":
      return { kind: "standalone" };
  }
}
