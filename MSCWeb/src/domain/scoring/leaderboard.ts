export const leaderboardPageSize = 25;

export function normalizeLeaderboardPage(value: number) {
  return Number.isInteger(value) && value > 0 ? Math.min(value, 10_000) : 1;
}

export function leaderboardOffset(page: number) {
  return (normalizeLeaderboardPage(page) - 1) * leaderboardPageSize;
}

export function sliceLeaderboardPage<T>(entries: readonly T[]) {
  return {
    entries: entries.slice(0, leaderboardPageSize),
    hasNextPage: entries.length > leaderboardPageSize,
  } as const;
}
