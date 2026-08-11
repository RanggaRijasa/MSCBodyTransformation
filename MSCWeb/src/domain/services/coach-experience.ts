import type { CoachAttentionState, CoachRosterEntry } from "@/domain/coach/coach-experience";

export function coachAttentionState(
  activeEnrollmentCount: number,
  progressPercentage: number,
): CoachAttentionState {
  if (activeEnrollmentCount === 0) return "not_enrolled";
  if (progressPercentage === 0) return "not_started";
  if (progressPercentage >= 100) return "complete";
  return progressPercentage < 50 ? "falling_behind" : "on_track";
}

export function filterAndSortCoachRoster(
  entries: readonly CoachRosterEntry[],
  input: Readonly<{
    attention?: string | undefined;
    programId?: string | undefined;
    query?: string | undefined;
    sort?: string | undefined;
  }>,
) {
  const query = input.query?.trim().toLocaleLowerCase("id-ID") ?? "";
  return entries
    .filter(
      (entry) =>
        !query ||
        entry.displayName.toLocaleLowerCase("id-ID").includes(query) ||
        entry.city?.toLocaleLowerCase("id-ID").includes(query),
    )
    .filter((entry) => !input.programId || entry.programId === input.programId)
    .filter((entry) => !input.attention || entry.attentionState === input.attention)
    .toSorted((left, right) => {
      if (input.sort === "points") return right.points - left.points || nameOrder(left, right);
      if (input.sort === "activity")
        return (
          (right.lastActivityAt ?? "").localeCompare(left.lastActivityAt ?? "") ||
          nameOrder(left, right)
        );
      return right.progressPercentage - left.progressPercentage || nameOrder(left, right);
    });
}

function nameOrder(left: CoachRosterEntry, right: CoachRosterEntry) {
  return left.displayName.localeCompare(right.displayName, "id-ID");
}

export function coachActivityStart(reference: Date, range: "1" | "7" | "30", timeZone = "UTC") {
  const parts = dateParts(reference, timeZone);
  const targetCalendar = new Date(
    Date.UTC(parts.year, parts.month - 1, parts.day - (Number(range) - 1)),
  );
  const targetLocal = Date.UTC(
    targetCalendar.getUTCFullYear(),
    targetCalendar.getUTCMonth(),
    targetCalendar.getUTCDate(),
  );
  let instant = targetLocal;
  for (let iteration = 0; iteration < 2; iteration += 1) {
    const observed = dateTimeParts(new Date(instant), timeZone);
    const observedAsUtc = Date.UTC(
      observed.year,
      observed.month - 1,
      observed.day,
      observed.hour,
      observed.minute,
      observed.second,
    );
    instant = targetLocal - (observedAsUtc - instant);
  }
  return new Date(instant);
}

function dateParts(date: Date, timeZone: string) {
  const parts = new Intl.DateTimeFormat("en-CA", {
    day: "2-digit",
    month: "2-digit",
    timeZone,
    year: "numeric",
  }).formatToParts(date);
  return Object.fromEntries(parts.map(({ type, value }) => [type, Number(value)])) as Record<
    "day" | "month" | "year",
    number
  >;
}

function dateTimeParts(date: Date, timeZone: string) {
  const parts = new Intl.DateTimeFormat("en-CA", {
    day: "2-digit",
    hour: "2-digit",
    hourCycle: "h23",
    minute: "2-digit",
    month: "2-digit",
    second: "2-digit",
    timeZone,
    year: "numeric",
  }).formatToParts(date);
  return Object.fromEntries(parts.map(({ type, value }) => [type, Number(value)])) as Record<
    "day" | "hour" | "minute" | "month" | "second" | "year",
    number
  >;
}
