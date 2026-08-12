import { describe, expect, it } from "vitest";

import {
  coachQrSvgContentSecurityPolicy,
  selectResponseContentSecurityPolicy,
} from "@/shared/security/content-security-policy";

describe("response Content Security Policy", () => {
  it("mempertahankan boundary SVG ketat hanya pada route QR Coach exact", () => {
    const defaultPolicy = "default-src 'self'";

    expect(selectResponseContentSecurityPolicy("/api/coach/qr-image", defaultPolicy)).toBe(
      coachQrSvgContentSecurityPolicy,
    );
    expect(selectResponseContentSecurityPolicy("/api/coach/qr-image/extra", defaultPolicy)).toBe(
      defaultPolicy,
    );
    expect(selectResponseContentSecurityPolicy("/coach-area/qr", defaultPolicy)).toBe(
      defaultPolicy,
    );
  });

  it("menutup eksekusi, object, base, dan framing pada SVG QR", () => {
    expect(coachQrSvgContentSecurityPolicy).toContain("default-src 'none'");
    expect(coachQrSvgContentSecurityPolicy).toContain("object-src 'none'");
    expect(coachQrSvgContentSecurityPolicy).toContain("base-uri 'none'");
    expect(coachQrSvgContentSecurityPolicy).toContain("frame-ancestors 'none'");
  });
});
