export type WatchInterval = Readonly<{ end: number; start: number }>;
export type VideoWatchState = Readonly<{
  intervals: readonly WatchInterval[];
  lastSampleSeconds: number | null;
}>;

export const initialVideoWatchState: VideoWatchState = { intervals: [], lastSampleSeconds: null };

function mergeIntervals(intervals: readonly WatchInterval[]): readonly WatchInterval[] {
  const sorted = [...intervals].sort((left, right) => left.start - right.start);
  const merged: WatchInterval[] = [];
  for (const interval of sorted) {
    const previous = merged.at(-1);
    if (!previous || interval.start > previous.end + 0.25) merged.push(interval);
    else
      merged[merged.length - 1] = {
        start: previous.start,
        end: Math.max(previous.end, interval.end),
      };
  }
  return merged;
}

export function recordVideoSample(
  state: VideoWatchState,
  currentSeconds: number,
  durationSeconds: number,
  maximumTrustedAdvanceSeconds = 5,
): VideoWatchState {
  if (!Number.isFinite(currentSeconds) || !Number.isFinite(durationSeconds) || durationSeconds <= 0)
    return state;
  const current = Math.min(durationSeconds, Math.max(0, currentSeconds));
  const previous = state.lastSampleSeconds;
  if (previous === null) return { ...state, lastSampleSeconds: current };
  const advance = current - previous;
  if (advance <= 0 || advance > maximumTrustedAdvanceSeconds) {
    return { ...state, lastSampleSeconds: current };
  }
  return {
    intervals: mergeIntervals([...state.intervals, { start: previous, end: current }]),
    lastSampleSeconds: current,
  };
}

export function watchedPercentage(state: VideoWatchState, durationSeconds: number): number {
  if (!Number.isFinite(durationSeconds) || durationSeconds <= 0) return 0;
  const watched = state.intervals.reduce(
    (total, interval) => total + interval.end - interval.start,
    0,
  );
  return Math.min(100, Math.max(0, Math.floor((watched / durationSeconds) * 100)));
}

export function hasMetWatchThreshold(
  state: VideoWatchState,
  durationSeconds: number,
  requiredPercentage: number,
): boolean {
  return (
    watchedPercentage(state, durationSeconds) >= Math.min(100, Math.max(0, requiredPercentage))
  );
}
