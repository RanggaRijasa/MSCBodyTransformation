export type CoachQrCapability =
  | Readonly<{ kind: "available" }>
  | Readonly<{ kind: "insecure_context" }>
  | Readonly<{ kind: "camera_unavailable" }>
  | Readonly<{ kind: "barcode_detector_unavailable" }>;

type BrowserCapabilitySource = Readonly<{
  hasBarcodeDetector: boolean;
  hasCamera: boolean;
  isSecureContext: boolean;
}>;

export function resolveCoachQrCapability(source: BrowserCapabilitySource): CoachQrCapability {
  if (!source.isSecureContext) return { kind: "insecure_context" };
  if (!source.hasCamera) return { kind: "camera_unavailable" };
  if (!source.hasBarcodeDetector) return { kind: "barcode_detector_unavailable" };
  return { kind: "available" };
}

// Phase 04 memasang adapter pemindai yang menghasilkan payload opaque langsung
// ke boundary onboarding; Phase 03 hanya mendefinisikan capability seam-nya.
