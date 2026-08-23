export type ProgramLifecycleInput = Readonly<{
  status: 'scheduled' | 'active' | 'completed' | 'archived';
  starts_on: string;
  ends_on?: string | null;
  timezone: string;
}>;

export type EffectiveProgramLifecycle = 'upcoming' | 'running' | 'awaiting_completion' | 'completed' | 'archived';

export type ProgramStatusPresentation = Readonly<{
  label: string;
  tone: 'success' | 'warning' | 'info';
}>;

export function effectiveProgramLifecycle(
  program: ProgramLifecycleInput,
  now = new Date(),
): EffectiveProgramLifecycle {
  if (program.status === 'archived') return 'archived';
  if (program.status === 'completed') return 'completed';

  const currentProgramDate = dateKeyInTimezone(now, program.timezone);
  if (currentProgramDate < program.starts_on) return 'upcoming';
  if (program.ends_on !== null && program.ends_on !== undefined && currentProgramDate > program.ends_on) {
    return 'awaiting_completion';
  }
  return 'running';
}

export function dateKeyInTimezone(date: Date, timezone: string): string {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone: timezone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(date);
  const year = parts.find((part) => part.type === 'year')?.value;
  const month = parts.find((part) => part.type === 'month')?.value;
  const day = parts.find((part) => part.type === 'day')?.value;
  if (year === undefined || month === undefined || day === undefined) {
    return date.toISOString().slice(0, 10);
  }
  return `${year}-${month}-${day}`;
}

export function programStatusPresentation(status: EffectiveProgramLifecycle): ProgramStatusPresentation {
  const presentations: Record<EffectiveProgramLifecycle, ProgramStatusPresentation> = {
    upcoming: { label: 'Segera hadir', tone: 'info' },
    running: { label: 'Aktif', tone: 'success' },
    awaiting_completion: { label: 'Menunggu hasil', tone: 'warning' },
    completed: { label: 'Selesai', tone: 'success' },
    archived: { label: 'Arsip', tone: 'info' },
  };
  return presentations[status];
}
