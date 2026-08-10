import { describe, expect, it } from "vitest";

import { buildCoachQrUrl, parseCoachQrUrl } from "@/domain/media/qr-payload";

describe("kontrak QR Coach", () => {
  const origin = "https://msc.example.id";

  it("menerima URL HTTPS same-origin dan menjaga token opaque", () => {
    const result = parseCoachQrUrl(`${origin}/gabung/coach/coach_ABC-123`, [origin]);
    expect(result).toEqual({ isSuccess: true, value: "coach_ABC-123" });
  });

  it.each([
    "http://msc.example.id/gabung/coach/coach_ABC-123",
    "https://evil.example/gabung/coach/coach_ABC-123",
    "https://msc.example.id/gabung/coach/coach_ABC-123?next=evil",
    "https://msc.example.id/gabung/coach/a",
    "https://msc.example.id/gabung/coach/coach%2Fother",
  ])("menolak payload yang tidak canonical: %s", (value) => {
    expect(parseCoachQrUrl(value, [origin]).isSuccess).toBe(false);
  });

  it("membangun deep link canonical dan hanya mengizinkan HTTP localhost", () => {
    const production = buildCoachQrUrl("coach-1234", new URL(origin));
    expect(production.isSuccess).toBe(true);
    if (production.isSuccess) {
      expect(production.value.toString()).toBe(`${origin}/gabung/coach/coach-1234`);
    }
    expect(buildCoachQrUrl("coach-1234", new URL("http://localhost:3000")).isSuccess).toBe(true);
    expect(buildCoachQrUrl("coach-1234", new URL("http://lan.local")).isSuccess).toBe(false);
  });
});
