import { describe, expect, it } from 'vitest';

import {
  isLeaderboardPending,
  leaderboardProgramState,
  readLeaderboardProgramId,
  saveLeaderboardProgramId,
  selectLeaderboardProgram,
} from '../../src/features/leaderboard/leaderboard-state';

describe('leaderboard loading state', () => {
  it('stops loading when no public program exists and the leaderboard query is disabled', () => {
    expect(isLeaderboardPending({
      programsPending: false,
      routedProgramRequested: false,
      routedProgramPending: true,
      selectedProgramId: undefined,
      leaderboardPending: true,
    })).toBe(false);
  });

  it('keeps loading while the selected program leaderboard is being fetched', () => {
    expect(isLeaderboardPending({
      programsPending: false,
      routedProgramRequested: false,
      routedProgramPending: true,
      selectedProgramId: 'program-id',
      leaderboardPending: true,
    })).toBe(true);
  });

  it('keeps loading for an explicitly routed program or Coach prerequisite', () => {
    expect(isLeaderboardPending({
      programsPending: false,
      routedProgramRequested: true,
      routedProgramPending: true,
      selectedProgramId: undefined,
      leaderboardPending: true,
    })).toBe(true);

    expect(isLeaderboardPending({
      programsPending: false,
      routedProgramRequested: false,
      routedProgramPending: true,
      prerequisitePending: true,
      selectedProgramId: undefined,
      leaderboardPending: true,
    })).toBe(true);
  });
});

describe('leaderboard program selection', () => {
  const programs = [
    { id: 'scheduled', status: 'scheduled' as const, starts_on: '2026-09-01', ends_on: '2026-09-03', timezone: 'Asia/Makassar' },
    { id: 'active', status: 'active' as const, starts_on: '2026-08-22', ends_on: '2026-08-24', timezone: 'Asia/Makassar' },
  ];

  it('uses the explicitly selected program before the active fallback', () => {
    expect(selectLeaderboardProgram(programs, 'scheduled')?.id).toBe('scheduled');
    expect(selectLeaderboardProgram(programs)?.id).toBe('active');
  });

  it('persists only the public program identifier', () => {
    const values = new Map<string, string>();
    const storage = {
      getItem: (key: string) => values.get(key) ?? null,
      setItem: (key: string, value: string) => { values.set(key, value); },
    };
    saveLeaderboardProgramId('scheduled', storage);
    expect(readLeaderboardProgramId(storage)).toBe('scheduled');
    expect([...values.values()]).toEqual(['scheduled']);
  });
});

describe('leaderboard program state', () => {
  const program = {
    status: 'scheduled' as const,
    starts_on: '2026-08-22',
    ends_on: '2026-08-24',
    timezone: 'Asia/Makassar',
  };

  it('treats a scheduled program as running once its local start date arrives', () => {
    expect(leaderboardProgramState(program, new Date('2026-08-21T16:30:00Z'))).toBe('running');
    expect(leaderboardProgramState(program, new Date('2026-08-24T15:59:59Z'))).toBe('running');
  });

  it('distinguishes upcoming, awaiting completion, and completed programs', () => {
    expect(leaderboardProgramState(program, new Date('2026-08-21T15:59:59Z'))).toBe('upcoming');
    expect(leaderboardProgramState(program, new Date('2026-08-24T16:00:00Z'))).toBe('awaiting_completion');
    expect(leaderboardProgramState({ ...program, status: 'completed' }, new Date('2026-08-22T00:00:00Z'))).toBe('completed');
  });
});
