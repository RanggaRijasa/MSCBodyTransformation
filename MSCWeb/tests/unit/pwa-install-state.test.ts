import { describe, expect, it } from "vitest";

import { getInstallPresentation } from "@/features/pwa-install/model/install-presentation";
import {
  initialInstallState,
  resolveInstallState,
  transitionInstallState,
  type InstallCapability,
} from "@/features/pwa-install/model/install-state";

const baselineCapability: InstallCapability = {
  hasCustomPrompt: false,
  isIOS: false,
  isInstallReadinessGateOpen: true,
  isStandalone: false,
  supportsManualInstall: false,
};

describe("install state machine", () => {
  it.each([
    [{ ...baselineCapability, hasCustomPrompt: true }, "prompt-ready"],
    [{ ...baselineCapability, isIOS: true }, "ios-guidance"],
    [{ ...baselineCapability, supportsManualInstall: true }, "manual-guidance"],
    [{ ...baselineCapability, isStandalone: true }, "standalone"],
    [baselineCapability, "unsupported"],
    [{ ...baselineCapability, isInstallReadinessGateOpen: false }, "not-ready"],
  ] as const)("memetakan capability ke %s", (capability, expectedKind) => {
    expect(resolveInstallState(capability)).toEqual({ kind: expectedKind });
  });

  it("mengonsumsi prompt sekali dan tetap mengutamakan standalone", () => {
    const ready = transitionInstallState(initialInstallState, {
      type: "custom-prompt-available",
    });
    expect(ready).toEqual({ kind: "prompt-ready" });
    expect(
      transitionInstallState(ready, { outcome: "dismissed", type: "prompt-consumed" }),
    ).toEqual({
      kind: "dismissed",
    });
    expect(transitionInstallState(ready, { outcome: "accepted", type: "prompt-consumed" })).toEqual(
      { kind: "not-ready" },
    );
    expect(transitionInstallState(ready, { type: "standalone-detected" })).toEqual({
      kind: "standalone",
    });
  });

  it("memberi label dan aksi jujur untuk tiap state", () => {
    expect(getInstallPresentation("prompt-ready")).toMatchObject({
      action: "prompt",
      label: "Pasang aplikasi",
    });
    expect(getInstallPresentation("ios-guidance").action).toBe("guidance");
    expect(getInstallPresentation("standalone")).toMatchObject({
      action: "navigate",
      label: "Buka aplikasi",
    });
    expect(getInstallPresentation("not-ready")).toMatchObject({
      action: "navigate",
      label: "Gunakan di browser",
    });
  });
});
