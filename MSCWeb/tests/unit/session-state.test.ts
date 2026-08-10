import { describe, expect, it } from "vitest";

import { resolveCoachQrCapability } from "@/features/auth/model/coach-qr-capability";
import { resolveSessionRoot } from "@/features/auth/model/session-state";

describe("session state machine", () => {
  it("membedakan Guest, expiry, revoked, dan offline", () => {
    expect(resolveSessionRoot({ hasIdentity: false })).toEqual({ kind: "guest" });
    expect(resolveSessionRoot({ hasIdentity: true, isExpired: true })).toEqual({
      canRetry: true,
      kind: "expired",
    });
    expect(resolveSessionRoot({ hasIdentity: true, isRevoked: true })).toEqual({
      canRetry: false,
      kind: "revoked",
    });
    expect(resolveSessionRoot({ hasIdentity: true, isOffline: true })).toEqual({
      canRetry: true,
      kind: "offline",
    });
  });

  it("mengutamakan protected role saat claim lama berbeda", () => {
    expect(
      resolveSessionRoot({
        claimedRole: "coach",
        hasIdentity: true,
        onboardingStatus: "active",
        protectedRole: "participant",
      }),
    ).toEqual({ destinationRole: "participant", kind: "stale_role" });
  });

  it("menahan profil provisional di onboarding", () => {
    expect(
      resolveSessionRoot({
        hasIdentity: true,
        onboardingStatus: "provisional",
        protectedRole: "participant",
      }),
    ).toEqual({ kind: "onboarding" });
  });
});

describe("Coach QR browser capability seam", () => {
  it("hanya tersedia pada secure context dengan kamera dan BarcodeDetector", () => {
    expect(
      resolveCoachQrCapability({
        hasBarcodeDetector: true,
        hasCamera: true,
        isSecureContext: true,
      }),
    ).toEqual({ kind: "available" });
    expect(
      resolveCoachQrCapability({
        hasBarcodeDetector: true,
        hasCamera: true,
        isSecureContext: false,
      }),
    ).toEqual({ kind: "insecure_context" });
    expect(
      resolveCoachQrCapability({
        hasBarcodeDetector: false,
        hasCamera: true,
        isSecureContext: true,
      }),
    ).toEqual({ kind: "barcode_detector_unavailable" });
  });
});
