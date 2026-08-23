import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

import { publicProgramSchema } from '@/features/public/public-models';
import type { ParticipantDayAccess, ParticipantEnrollment, ParticipantSubmission } from '@/features/participant/participant-models';
import { formatProgramDateRange } from '@/shared/design/formatters';
import {
  isRepeatableLocalTestProgram,
  isFoodInsightEnabledForStep,
  latestSubmissionForStep,
  programsForSegment,
  relevantDayAccess,
  stepKindLabel,
  submissionPresentation,
  weighInCompletionSubmission,
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
  it('formats joined-program dates compactly without a timezone suffix', () => {
    expect(formatProgramDateRange('2026-08-22', '2026-08-24')).toBe('22–24 Agustus 2026');
    expect(formatProgramDateRange('2026-08-31', '2026-09-02')).toBe('31 Agustus–2 September 2026');
    expect(formatProgramDateRange('2026-12-31', '2027-01-02')).toBe('31 Desember 2026–2 Januari 2027');
  });

  it('separates joined, available, and history using server enrollment state', () => {
    const available = { ...program, id: '66666666-6666-4666-8666-666666666666', title: 'Program tersedia' };
    const completed = { ...program, id: '77777777-7777-4777-8777-777777777777', title: 'Program selesai', status: 'completed' as const };
    const awaitingPayment = { ...program, id: '99999999-9999-4999-8999-999999999999', title: 'Program menunggu pembayaran', pricing_mode: 'paid' };
    const completedEnrollment = { ...enrollment, id: '88888888-8888-4888-8888-888888888888', program_id: completed.id, status: 'completed' as const };
    const paymentEnrollment = { ...enrollment, id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', program_id: awaitingPayment.id, status: 'waiting_for_payment' as const };
    const programs = [program, available, completed, awaitingPayment];
    const enrollments = [enrollment, completedEnrollment, paymentEnrollment];
    expect(programsForSegment(programs, enrollments, 'joined').map(({ id }) => id)).toEqual([program.id, awaitingPayment.id]);
    expect(programsForSegment(programs, enrollments, 'available').map(({ id }) => id)).toEqual([available.id]);
    expect(programsForSegment(programs, enrollments, 'history').map(({ id }) => id)).toEqual([completed.id]);
  });

  it('keeps the two explicit local fixtures repeatable without showing consumed rows in joined or history', () => {
    const repeatablePaid = {
      ...program,
      id: '12121212-1212-4212-8212-121212121212',
      title: 'Program uji lokal berbayar',
      category: 'Pengujian lokal berulang',
      pricing_mode: 'paid',
    };
    const archivedRotation = {
      ...repeatablePaid,
      id: '13131313-1313-4313-8313-131313131313',
      status: 'archived' as const,
    };
    const fixtureEnrollment = {
      ...enrollment,
      id: '14141414-1414-4414-8414-141414141414',
      program_id: repeatablePaid.id,
      status: 'waiting_for_payment' as const,
    };

    expect(isRepeatableLocalTestProgram(repeatablePaid)).toBe(true);
    expect(programsForSegment([repeatablePaid, archivedRotation], [fixtureEnrollment], 'available')).toEqual([repeatablePaid]);
    expect(programsForSegment([repeatablePaid, archivedRotation], [fixtureEnrollment], 'joined')).toEqual([]);
    expect(programsForSegment([repeatablePaid, archivedRotation], [fixtureEnrollment], 'history')).toEqual([]);
  });

  it('hides archived fixtures from the previous local W05 sequence', () => {
    const archivedFixture = {
      ...program,
      id: '15151515-1515-4515-8515-151515151515',
      title: 'Program Uji Pembayaran Lokal #3',
      category: 'Pengujian lokal berulang',
      status: 'archived' as const,
    };
    const fixtureEnrollment = {
      ...enrollment,
      id: '16161616-1616-4616-8616-161616161616',
      program_id: archivedFixture.id,
      status: 'waiting_for_payment' as const,
    };

    expect(programsForSegment([archivedFixture], [fixtureEnrollment], 'available')).toEqual([]);
    expect(programsForSegment([archivedFixture], [fixtureEnrollment], 'joined')).toEqual([]);
    expect(programsForSegment([archivedFixture], [fixtureEnrollment], 'history')).toEqual([]);
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

  it('presents an existing private weigh-in as a completed step without exposing its value', () => {
    const completion = weighInCompletionSubmission({
      id: '17000000-0000-4000-8000-000000000000',
      enrollment_id: enrollmentId,
      step_id: stepId,
      recorded_at: '2026-08-22T01:54:00Z',
    });
    expect(completion).toEqual(expect.objectContaining({
      step_id: stepId,
      status: 'approved',
      submitted_at: '2026-08-22T01:54:00Z',
    }));
    expect(completion).not.toHaveProperty('weight_kg');
    expect(submissionPresentation(completion.status)).toEqual({ label: 'Selesai', tone: 'success' });
  });

  it('maps every published step kind to Indonesian product copy', () => {
    expect(['article', 'video', 'form', 'quiz', 'initial_weigh_in', 'daily_weigh_in', 'final_weigh_in'].map(stepKindLabel)).toEqual([
      'Artikel', 'Video', 'Formulir', 'Kuis', 'Timbang awal', 'Timbang harian', 'Timbang akhir',
    ]);
  });

  it('enables food insight only for an opted-in photo question', () => {
    const baseStep = {
      id: stepId,
      step_order: 1,
      title: 'Bukti',
      instructions: null,
      content_kind: 'form',
      completion_policy: 'answer_all_questions',
      verification_mode: 'automatic',
      media_path: null,
      media_alt_text: null,
      video_required: false,
      video_threshold: 100,
      video_autoplay: false,
      program_questions: [],
    };
    const question = {
      id: '18181818-1818-4818-8818-181818181818',
      question_order: 1,
      kind: 'photo_upload',
      prompt: 'Unggah foto makanan',
      analysis_mode: 'none' as const,
      analysis_rubric: null,
      analysis_rubric_version: null,
      media_kind: null,
      media_path: null,
      media_alt_text: null,
      program_question_options: [],
    };

    expect(isFoodInsightEnabledForStep({ ...baseStep, program_questions: [question] })).toBe(false);
    expect(isFoodInsightEnabledForStep({ ...baseStep, program_questions: [{ ...question, kind: 'video_upload', analysis_mode: 'food' }] })).toBe(false);
    expect(isFoodInsightEnabledForStep({ ...baseStep, program_questions: [{ ...question, analysis_mode: 'food' }] })).toBe(true);
  });

  it('keeps all shared renderers and explicit states in one activity boundary', () => {
    const source = readFileSync('src/features/participant/ParticipantProgramComponents.tsx', 'utf8');
    const submissionSource = readFileSync('src/features/participant/ParticipantSubmissionForm.tsx', 'utf8');
    const policySource = readFileSync('src/features/participant/participant-program-policy.ts', 'utf8');
    for (const renderer of ['ArticleRenderer', 'VideoRenderer']) {
      expect(source).toContain(`function ${renderer}`);
    }
    for (const copy of ['Aktivitas belum tersedia', 'Menunggu tinjauan', 'Perlu diperbaiki', 'Satu kesempatan']) {
      expect(source + submissionSource + policySource).toContain(copy);
    }
    expect(source).toContain('access.access_state');
    expect(source).toContain('scrollIntoView');
    expect(source).toContain('ParticipantSubmissionForm');
    expect(submissionSource).toContain('type="file"');
    expect(submissionSource).toContain('Pilih sumber foto');
    expect(submissionSource).toContain('Pilih sumber video');
    expect(submissionSource).not.toContain('capture="environment"');
    expect(submissionSource).toContain('Berat badan sudah dicatat');
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
