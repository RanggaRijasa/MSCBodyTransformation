import { beforeEach, describe, expect, it } from "vitest";

import {
  consumeRequestLimit,
  opaqueRequestFingerprint,
  resetRequestLimitsForTests,
} from "@/shared/security/request-rate-limiter";

describe("request rate limiter", () => {
  beforeEach(resetRequestLimitsForTests);

  it("membatasi fingerprint tanpa menyimpan alamat mentah", () => {
    const headers = new Headers({
      "user-agent": "Browser uji",
      "x-forwarded-for": "192.0.2.5",
    });
    const fingerprint = opaqueRequestFingerprint(headers);
    expect(fingerprint).toMatch(/^[a-f0-9]{64}$/);
    expect(fingerprint).not.toContain("192.0.2.5");

    expect(
      consumeRequestLimit("auth", fingerprint, { limit: 2, now: 1_000, windowMs: 1_000 }),
    ).toMatchObject({ allowed: true, remaining: 1 });
    expect(
      consumeRequestLimit("auth", fingerprint, { limit: 2, now: 1_100, windowMs: 1_000 }),
    ).toMatchObject({ allowed: true, remaining: 0 });
    expect(
      consumeRequestLimit("auth", fingerprint, { limit: 2, now: 1_200, windowMs: 1_000 }),
    ).toEqual({ allowed: false, retryAfterSeconds: 1 });
  });

  it("membuka bucket baru setelah jendela berakhir", () => {
    expect(
      consumeRequestLimit("auth", "actor", { limit: 1, now: 1_000, windowMs: 500 }),
    ).toMatchObject({ allowed: true });
    expect(
      consumeRequestLimit("auth", "actor", { limit: 1, now: 1_501, windowMs: 500 }),
    ).toMatchObject({ allowed: true });
  });
});
