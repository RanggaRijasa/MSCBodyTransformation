import { describe, expect, it } from "vitest";

import {
  buildCatalogSections,
  evaluateProgramOffer,
  programRouteMode,
} from "@/domain/programs/program-catalog";
import { parsePublicProgram } from "@/domain/programs/program-contract";
import type { PublicProgram } from "@/domain/programs/program";

function program(overrides: Partial<PublicProgram> = {}): PublicProgram {
  return {
    category: "Transformasi",
    coverAlternativeText: null,
    coverImageUrl: null,
    days: [],
    desiredPrice: null,
    endsOn: "2026-09-30",
    futureStepPolicy: "locked",
    id: "program-1",
    participantLimit: 50,
    pastStepPolicy: "available",
    pointsPerActivity: 10,
    pointsPerWeightKilogram: "100.00",
    pricingMode: "free",
    quizPassingPercentage: 80,
    registrationClosesAt: "2026-08-20T00:00:00Z",
    startsOn: "2026-09-01",
    status: "scheduled",
    summary: "Program sehat.",
    timezone: "Asia/Makassar",
    title: "MSC September",
    wellnessDisclaimer: "Program kebugaran non-diagnostik.",
    ...overrides,
  };
}

describe("katalog program", () => {
  it("menutup pendaftaran tepat pada cutoff server", () => {
    const target = program();
    expect(evaluateProgramOffer(target, new Date("2026-08-19T23:59:59Z"))).toBe("available");
    expect(evaluateProgramOffer(target, new Date("2026-08-20T00:00:00Z"))).toBe(
      "registration_closed",
    );
  });

  it("memisahkan Diikuti, Tersedia, dan Riwayat tanpa state antarprogram bocor", () => {
    const active = program({ id: "active" });
    const available = program({ id: "available" });
    const completed = program({ id: "completed", status: "completed" });
    const sections = buildCatalogSections(
      [active, available, completed],
      [{ enrollmentId: "enrollment-active", programId: "active", status: "active" }],
      new Date("2026-08-10T00:00:00Z"),
    );
    expect(sections.followed.map(({ program }) => program.id)).toEqual(["active"]);
    expect(sections.available.map((item) => item.id)).toEqual(["available"]);
    expect(sections.history.map((item) => item.id)).toEqual(["completed"]);
    expect(
      programRouteMode("active", [
        { enrollmentId: "enrollment-active", programId: "active", status: "active" },
      ]),
    ).toEqual({
      enrollmentId: "enrollment-active",
      mode: "activity",
    });
    expect(programRouteMode("available", [])).toEqual({ mode: "offer" });
  });

  it("memetakan DTO snake_case dan menolak enum atau harga yang tidak konsisten", () => {
    const raw = {
      category: "Transformasi",
      cover_alt_text: null,
      desired_price: null,
      ends_on: "2026-09-30",
      id: "program-1",
      participant_limit: 50,
      points_per_activity: 10,
      points_per_weight_kg: 100,
      pricing_mode: "free",
      program_days: [],
      quiz_passing_percentage: 80,
      registration_closes_at: null,
      starts_on: "2026-09-01",
      status: "scheduled",
      summary: "Program sehat.",
      timezone: "Asia/Makassar",
      title: "MSC September",
      wellness_disclaimer: "Non-diagnostik.",
    };
    expect(parsePublicProgram(raw).isSuccess).toBe(true);
    expect(parsePublicProgram({ ...raw, status: "unknown" }).isSuccess).toBe(false);
    expect(parsePublicProgram({ ...raw, pricing_mode: "paid" }).isSuccess).toBe(false);
  });
});
