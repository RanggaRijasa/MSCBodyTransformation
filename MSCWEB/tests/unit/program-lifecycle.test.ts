import { describe, expect, it } from 'vitest';

import { effectiveProgramLifecycle, programStatusPresentation } from '../../src/shared/program/program-lifecycle';

describe('effective program lifecycle', () => {
  const scheduledProgram = {
    status: 'scheduled' as const,
    starts_on: '2026-08-22',
    ends_on: '2026-08-24',
    timezone: 'Asia/Makassar',
  };

  it('treats a stale scheduled status as running during the local program dates', () => {
    expect(effectiveProgramLifecycle(scheduledProgram, new Date('2026-08-23T04:00:00Z'))).toBe('running');
  });

  it('keeps a future scheduled program upcoming', () => {
    expect(effectiveProgramLifecycle(
      { ...scheduledProgram, starts_on: '2026-08-24', ends_on: '2026-08-26' },
      new Date('2026-08-23T04:00:00Z'),
    )).toBe('upcoming');
  });

  it('renders the effective running and upcoming labels used by program cards', () => {
    expect(programStatusPresentation('running')).toEqual({ label: 'Aktif', tone: 'success' });
    expect(programStatusPresentation('upcoming')).toEqual({ label: 'Segera hadir', tone: 'info' });
  });

  it('distinguishes awaiting completion, completed, and archived states', () => {
    expect(effectiveProgramLifecycle(scheduledProgram, new Date('2026-08-24T16:00:00Z'))).toBe('awaiting_completion');
    expect(effectiveProgramLifecycle({ ...scheduledProgram, status: 'completed' })).toBe('completed');
    expect(effectiveProgramLifecycle({ ...scheduledProgram, status: 'archived' })).toBe('archived');
  });
});
