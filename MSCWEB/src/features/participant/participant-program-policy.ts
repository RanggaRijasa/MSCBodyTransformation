import type { PublicProgram, PublicProgramStep } from '@/features/public/public-models';
import type {
  ParticipantDayAccess,
  ParticipantEnrollment,
  ParticipantSubmission,
} from './participant-models';

export type ProgramSegment = 'joined' | 'available' | 'history';

export const repeatableLocalFixtureCategory = 'Pengujian lokal berulang';

export function isRepeatableLocalTestProgram(program: PublicProgram): boolean {
  return program.category === repeatableLocalFixtureCategory
    && (program.title === 'Program uji lokal gratis' || program.title === 'Program uji lokal berbayar');
}

export function programsForSegment(
  programs: PublicProgram[],
  enrollments: ParticipantEnrollment[],
  segment: ProgramSegment,
): PublicProgram[] {
  const enrollmentByProgram = new Map(enrollments.map((enrollment) => [enrollment.program_id, enrollment]));
  return programs.filter((program) => {
    if (program.category === repeatableLocalFixtureCategory) {
      return isRepeatableLocalTestProgram(program)
        && segment === 'available'
        && (program.status === 'active' || program.status === 'scheduled');
    }
    const enrollment = enrollmentByProgram.get(program.id);
    if (segment === 'joined') {
      return enrollment?.status === 'active'
        || enrollment?.status === 'pending'
        || enrollment?.status === 'waiting_for_payment';
    }
    if (segment === 'history') {
      return enrollment !== undefined && (
        enrollment.status === 'completed'
        || program.status === 'completed'
        || program.status === 'archived'
      );
    }
    return enrollment === undefined
      && (program.status === 'active' || program.status === 'scheduled');
  });
}

export function latestSubmissionForStep(
  submissions: ParticipantSubmission[],
  stepId: string,
): ParticipantSubmission | undefined {
  return submissions
    .filter((submission) => submission.step_id === stepId)
    .sort((left, right) => right.attempt_sequence - left.attempt_sequence)[0];
}

export function relevantDayAccess(accesses: ParticipantDayAccess[]): ParticipantDayAccess | undefined {
  return accesses.find((access) => access.is_current_day)
    ?? accesses.find((access) => access.access_state === 'available')
    ?? [...accesses].reverse().find((access) => access.access_state === 'read_only')
    ?? accesses.find((access) => access.access_state !== 'hidden');
}

export function stepKindLabel(kind: PublicProgramStep['content_kind']): string {
  return ({
    article: 'Artikel',
    video: 'Video',
    form: 'Formulir',
    quiz: 'Kuis',
    initial_weigh_in: 'Timbang awal',
    daily_weigh_in: 'Timbang harian',
    final_weigh_in: 'Timbang akhir',
  } as Record<string, string>)[kind] ?? 'Aktivitas';
}

export function submissionPresentation(status?: ParticipantSubmission['status']): {
  label: string;
  tone: 'success' | 'warning' | 'destructive' | 'info';
} {
  if (status === 'approved') return { label: 'Selesai', tone: 'success' };
  if (status === 'pending') return { label: 'Menunggu tinjauan', tone: 'warning' };
  if (status === 'rejected') return { label: 'Perlu diperbaiki', tone: 'destructive' };
  if (status === 'draft') return { label: 'Draf', tone: 'info' };
  return { label: 'Belum dimulai', tone: 'info' };
}
