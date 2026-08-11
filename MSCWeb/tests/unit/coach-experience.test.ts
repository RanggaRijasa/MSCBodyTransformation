import { describe, expect, it } from "vitest";

import type { CoachRosterEntry } from "@/domain/coach/coach-experience";
import {
  coachActivityStart,
  coachAttentionState,
  filterAndSortCoachRoster,
} from "@/domain/services/coach-experience";
import { canAccessRole } from "@/features/auth/model/auth-model";

function entry(overrides: Partial<CoachRosterEntry>): CoachRosterEntry {
  return {
    activeEnrollmentCount: 1,
    attentionState: "on_track",
    avatarUrl: null,
    city: "Denpasar",
    displayName: "Peserta",
    lastActivityAt: "2026-08-10T02:00:00Z",
    memberLevel: "member",
    participantId: crypto.randomUUID(),
    pendingReviewCount: 0,
    points: 10,
    programId: "program-a",
    programTitle: "Program A",
    progressPercentage: 60,
    publicProfileId: crypto.randomUUID(),
    ...overrides,
  };
}

describe("domain pengalaman Coach", () => {
  it.each([
    [0, 0, "not_enrolled"],
    [1, 0, "not_started"],
    [1, 40, "falling_behind"],
    [1, 60, "on_track"],
    [1, 100, "complete"],
  ] as const)("memetakan attention dengan teks berbeda", (count, progress, expected) => {
    expect(coachAttentionState(count, progress)).toBe(expected);
  });

  it("memfilter dan mengurutkan roster secara stabil", () => {
    const entries = [
      entry({ displayName: "Budi", points: 20, progressPercentage: 50 }),
      entry({
        attentionState: "falling_behind",
        displayName: "Ani",
        points: 20,
        progressPercentage: 40,
      }),
      entry({
        attentionState: "falling_behind",
        displayName: "Citra",
        points: 10,
        progressPercentage: 30,
      }),
    ];
    expect(
      filterAndSortCoachRoster(entries, { attention: "falling_behind", sort: "points" }).map(
        ({ displayName }) => displayName,
      ),
    ).toEqual(["Ani", "Citra"]);
    expect(filterAndSortCoachRoster(entries, { query: "denpa" })).toHaveLength(3);
  });

  it("menghitung rentang hari UTC deterministik", () => {
    expect(coachActivityStart(new Date("2026-08-10T12:00:00Z"), "7").toISOString()).toBe(
      "2026-08-04T00:00:00.000Z",
    );
  });

  it("menghitung awal hari berdasarkan timezone program", () => {
    expect(
      coachActivityStart(new Date("2026-08-10T18:00:00Z"), "1", "Asia/Makassar").toISOString(),
    ).toBe("2026-08-10T16:00:00.000Z");
  });

  it("memberi Coach capability Peserta tanpa memberi Peserta capability Coach", () => {
    expect(canAccessRole("participant", "coach")).toBe(true);
    expect(canAccessRole("coach", "participant")).toBe(false);
  });
});
