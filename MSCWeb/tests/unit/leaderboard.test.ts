import { describe, expect, it } from "vitest";

import {
  leaderboardOffset,
  leaderboardPageSize,
  normalizeLeaderboardPage,
  sliceLeaderboardPage,
} from "@/domain/scoring/leaderboard";

describe("kontrak pagination papan peringkat", () => {
  it.each([
    [Number.NaN, 1],
    [0, 1],
    [-2, 1],
    [2.5, 1],
    [2, 2],
    [50_000, 10_000],
  ])("menormalkan halaman %s", (input, expected) => {
    expect(normalizeLeaderboardPage(input)).toBe(expected);
  });

  it("menghasilkan offset stabil dan mendeteksi halaman berikutnya", () => {
    const values = Array.from({ length: leaderboardPageSize + 1 }, (_, index) => index + 1);
    expect(leaderboardOffset(3)).toBe(50);
    expect(sliceLeaderboardPage(values)).toEqual({
      entries: values.slice(0, leaderboardPageSize),
      hasNextPage: true,
    });
  });

  it("tidak mengklaim halaman berikutnya pada data pendek", () => {
    expect(sliceLeaderboardPage([1, 2])).toEqual({ entries: [1, 2], hasNextPage: false });
  });
});
