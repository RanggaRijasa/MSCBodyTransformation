import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

import { publicProgramSchema } from '@/features/public/public-models';
import type { ParticipantDayAccess, ParticipantEnrollment, ParticipantSubmission } from '@/features/participant/participant-models';
import {
  latestSubmissionForStep,
  programsForSegment,
  relevantDayAccess,
  stepKindLabel,
  submissionPresentation,
} from '@/features/participant/participant-program-policy';

const programId = '11111111-1111-4111-8111-111111111111';
const enrollmentId = '22222222-2222-4222-8222-222222222222';
const stepId = '44444444-4444-4444-8444-444444444444';

const program = publicProgramSchema.parse({
  id: programId,
  title: 'Program aktif',
  summary: 'Langkah harian terarah.',
  category: 'Wellness',
  status: 'active',
  starts_on: '2026-08-12',
  ends_on: '2026-08-18',
  timezone: 'Asia/Makassar',
  pricing_mode: 'free',
  program_days: [],
});

const enrollment: ParticipantEnrollment = {
  id: enrollmentId,
  program_id: programId,
  coach_id: '55555555-5555-4555-8555-555555555555',
  status: 'active',
  enrolled_at: '2026-08-12T00:00:00Z',
  completed_at: null,
};

const access: ParticipantDayAccess = {
  enrollment_id: enrollmentId,
  program_id: programId,
  program_day_id: '33333333-3333-4333-8333-333333333333',
  day_number: 1,
  access_state: 'available',
  is_current_day: true,
};

describe('W03 Participant program policy', () => {
  it('separates joined, available, and history using server enrollment state', () => {
    const available = { ...program, id: '66666666-6666-4666-8666-666666666666', title: 'Program tersedia' };
    const completed = { ...program, id: '77777777-7777-4777-8777-777777777777', title: 'Program selesai', status: 'completed' as const };
    const completedEnrollment = { ...enrollment, id: '88888888-8888-4888-8888-888888888888', program_id: completed.id, status: 'completed' as const };
    expect(programsForSegment([program, available, completed], [enrollment, completedEnrollment], 'joined').map(({ id }) => id)).toEqual([program.id]);
    expect(programsForSegment([program, available, completed], [enrollment, completedEnrollment], 'available').map(({ id }) => id)).toEqual([available.id]);
    expect(programsForSegment([program, available, completed], [enrollment, completedEnrollment], 'history').map(({ id }) => id)).toEqual([completed.id]);
  });

  it('uses server day access without deriving unlock from device dates', () => {
    const locked = { ...access, program_day_id: '99999999-9999-4999-8999-999999999999', day_number: 2, access_state: 'locked' as const, is_current_day: false };
    expect(relevantDayAccess([locked, access])).toEqual(access);
  });

  it('selects the latest attempt and preserves pending/rejected labels', () => {
    const submissions: ParticipantSubmission[] = [submission(1, 'rejected'), submission(2, 'pending')];
    expect(latestSubmissionForStep(submissions, stepId)?.status).toBe('pending');
    expect(submissionPresentation('pending')).toEqual({ label: 'Menunggu tinjauan', tone: 'warning' });
    expect(submissionPresentation('rejected')).toEqual({ label: 'Perlu diperbaiki', tone: 'destructive' });
  });

  it('maps every published step kind to Indonesian product copy', () => {
    expect(['article', 'video', 'form', 'quiz', 'initial_weigh_in', 'daily_weigh_in', 'final_weigh_in'].map(stepKindLabel)).toEqual([
      'Artikel', 'Video', 'Formulir', 'Kuis', 'Timbang awal', 'Timbang harian', 'Timbang akhir',
    ]);
  });

  it('keeps all shared renderers and explicit states in one activity boundary', () => {
    const source = readFileSync('src/features/participant/ParticipantProgramComponents.tsx', 'utf8');
    for (const renderer of ['ArticleRenderer', 'VideoRenderer', 'QuestionRenderer', 'WeightRenderer']) {
      expect(source).toContain(`function ${renderer}`);
    }
    for (const copy of ['Aktivitas belum tersedia', 'Menunggu tinjauan', 'Perlu diperbaiki', 'Satu kesempatan']) {
      expect(source).toContain(copy);
    }
    expect(source).toContain('access.access_state');
    expect(source).toContain('scrollIntoView');
    expect(source).toContain('useSafeAreaInsets');
    expect(source).toContain('componentTokens.compactTabBarHeight');
    expect(source).not.toContain('new Date().getDate');
  });
});

function submission(attempt: number, status: ParticipantSubmission['status']): ParticipantSubmission {
  return {
    id: `${attempt}0000000-0000-4000-8000-000000000000`,
    enrollment_id: enrollmentId,
    step_id: stepId,
    attempt_sequence: attempt,
    status,
    review_note: status === 'rejected' ? 'Foto kurang jelas.' : null,
    submitted_at: `2026-08-12T00:00:0${attempt}Z`,
  };
}
