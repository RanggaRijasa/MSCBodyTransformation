import { effectiveProgramLifecycle } from '@/shared/program/program-lifecycle';

export type LeaderboardPendingInput = Readonly<{
  programsPending: boolean;
  routedProgramRequested: boolean;
  routedProgramPending: boolean;
  prerequisitePending?: boolean;
  selectedProgramId?: string;
  leaderboardPending: boolean;
}>;

export type LeaderboardProgramState = 'upcoming' | 'running' | 'awaiting_completion' | 'completed';

export const leaderboardProgramStorageKey = 'msc:leaderboard-program:v1';

type LeaderboardProgram = LeaderboardProgramTiming & Readonly<{ id: string }>;

type KeyValueStorage = Pick<Storage, 'getItem' | 'setItem'>;

export function readLeaderboardProgramId(storage: KeyValueStorage | undefined = browserStorage()): string | undefined {
  try {
    return storage?.getItem(leaderboardProgramStorageKey) || undefined;
  } catch {
    return undefined;
  }
}

export function saveLeaderboardProgramId(programId: string, storage: KeyValueStorage | undefined = browserStorage()): void {
  try {
    storage?.setItem(leaderboardProgramStorageKey, programId);
  } catch {
    // A blocked browser storage policy must not prevent leaderboard navigation.
  }
}

export function selectLeaderboardProgram<T extends LeaderboardProgram>(
  programs: readonly T[] | undefined,
  requestedId?: string,
  preferredIds: readonly string[] = [],
): T | undefined {
  if (!programs?.length) return undefined;
  return programs.find((program) => program.id === requestedId)
    ?? programs.find((program) => preferredIds.includes(program.id) && program.status === 'active')
    ?? programs.find((program) => preferredIds.includes(program.id))
    ?? programs.find((program) => program.status === 'active')
    ?? programs.find((program) => program.status === 'scheduled')
    ?? programs.find((program) => program.status === 'completed')
    ?? programs[0];
}

type LeaderboardProgramTiming = Readonly<{
  status: 'scheduled' | 'active' | 'completed' | 'archived';
  starts_on: string;
  ends_on?: string | null;
  timezone: string;
}>;

export function isLeaderboardPending({
  programsPending,
  routedProgramRequested,
  routedProgramPending,
  prerequisitePending = false,
  selectedProgramId,
  leaderboardPending,
}: LeaderboardPendingInput): boolean {
  return programsPending
    || (routedProgramRequested && routedProgramPending)
    || prerequisitePending
    || (selectedProgramId !== undefined && leaderboardPending);
}

export function leaderboardProgramState(
  program: LeaderboardProgramTiming,
  now = new Date(),
): LeaderboardProgramState {
  const lifecycle = effectiveProgramLifecycle(program, now);
  return lifecycle === 'archived' ? 'completed' : lifecycle;
}

function browserStorage(): Storage | undefined {
  return typeof globalThis.localStorage === 'undefined' ? undefined : globalThis.localStorage;
}
