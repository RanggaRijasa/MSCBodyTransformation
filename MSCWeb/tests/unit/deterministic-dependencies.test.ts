import { describe, expect, it } from "vitest";

import { FixedClock } from "@/core/clock/clock";
import { FixedIdentifierGenerator } from "@/core/identifiers/identifier-generator";

describe("dependency deterministik", () => {
  it("mengembalikan waktu fixture tanpa membocorkan mutable Date", () => {
    const clock = new FixedClock(new Date("2026-08-10T00:00:00.000Z"));
    const firstRead = clock.now();
    firstRead.setUTCFullYear(2030);

    expect(clock.now().toISOString()).toBe("2026-08-10T00:00:00.000Z");
  });

  it("mengembalikan identifier fixture yang stabil", () => {
    const identifiers = new FixedIdentifierGenerator("fixture-participant-001");

    expect(identifiers.makeIdentifier()).toBe("fixture-participant-001");
    expect(identifiers.makeIdentifier()).toBe("fixture-participant-001");
  });
});
