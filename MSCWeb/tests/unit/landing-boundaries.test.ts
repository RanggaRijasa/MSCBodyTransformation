import { describe, expect, it } from "vitest";

import { resolveLandingDestination } from "@/features/landing/model/landing-actor";
import {
  loadLandingPublicData,
  type LandingPublicRepository,
} from "@/features/landing/model/landing-public-data";
import { allowPublicCoach, allowPublicProgram } from "@/features/landing/model/public-teaser";

describe("landing public boundaries", () => {
  it.each([
    [{ kind: "anonymous" } as const, "/program"],
    [{ kind: "authenticated", role: "participant" } as const, "/hari-ini"],
    [{ kind: "authenticated", role: "coach" } as const, "/coach-area"],
    [{ kind: "authenticated", role: "admin" } as const, "/admin"],
  ])("memetakan actor server ke destination", (actor, destination) => {
    expect(resolveLandingDestination(actor)).toBe(destination);
  });

  it("mengeluarkan hanya allowlist program publik", () => {
    const publicProgram = allowPublicProgram({
      id: "program-public",
      title: "Program sehat",
      scheduleLabel: "Agustus 2026",
      summary: "Aktivitas terstruktur",
      privateEnrollmentCount: 99,
    });
    expect(publicProgram).toEqual({
      id: "program-public",
      title: "Program sehat",
      scheduleLabel: "Agustus 2026",
      summary: "Aktivitas terstruktur",
    });
    expect(publicProgram).not.toHaveProperty("privateEnrollmentCount");
  });

  it("menyembunyikan Coach yang belum approved atau tidak visible", () => {
    const source = {
      id: "coach-public",
      displayName: "Coach MSC",
      publicSummary: "Pendamping program",
      isApproved: true,
      isVisible: true,
      privateEmail: "private@example.test",
    };
    expect(allowPublicCoach(source)).not.toHaveProperty("privateEmail");
    expect(allowPublicCoach({ ...source, isApproved: false })).toBeUndefined();
    expect(allowPublicCoach({ ...source, isVisible: false })).toBeUndefined();
  });

  it("gagal tertutup ke landing statis saat repository error", async () => {
    const repository: LandingPublicRepository = {
      loadPublicLandingData: () => Promise.reject(new Error("raw backend error")),
    };
    await expect(loadLandingPublicData(repository)).resolves.toEqual({
      availability: "unavailable",
      coaches: [],
      programs: [],
    });
  });
});
