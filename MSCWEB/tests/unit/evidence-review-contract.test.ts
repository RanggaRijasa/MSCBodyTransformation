import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

import { coachReviewItemSchema } from '../../src/features/coach/coach-review-models';

describe('W04 evidence, review, and scoring boundary', () => {
  it('keeps private upload paths unique, owner-scoped, and non-overwriting', () => {
    const repository = readFileSync('src/features/participant/participant-repository.ts', 'utf8');
    expect(repository).toContain('user.data.user.id');
    expect(repository).toContain('command.enrollmentId');
    expect(repository).toContain('submissionId');
    expect(repository).toContain('question.id');
    expect(repository).toContain('crypto.randomUUID()');
    expect(repository).toContain('normalizeBrowserImageOffMainThread');
    expect(repository).toContain('Promise.allSettled');
    expect(repository).not.toContain('console.');
  });

  it('uses an actual accessible picker and revokes preview object URLs', () => {
    const component = readFileSync('src/features/participant/ParticipantSubmissionForm.tsx', 'utf8');
    expect(component).toContain('type="file"');
    expect(component).toContain('aria-label="Pilih sumber foto"');
    expect(component).toContain('aria-label="Pilih sumber video"');
    expect(component).not.toContain('capture="environment"');
    expect(component).toContain("event.currentTarget.value = ''");
    expect(component).toContain('URL.revokeObjectURL');
    expect(component).not.toContain('foto demo');
  });

  it('requires a rejection reason and maps concurrent review conflicts', () => {
    const repository = readFileSync('src/features/coach/coach-review-repository.ts', 'utf8');
    expect(repository).toContain("command.decision === 'rejected'");
    expect(repository).toContain('already_reviewed');
    expect(repository).toContain('review_step_submission');
    expect(repository).not.toContain('weight_kg');
  });

  it('strips sensitive fields from the Coach review view model', () => {
    const parsed = coachReviewItemSchema.parse({
      id: '10000000-0000-4000-8000-000000000001',
      enrollment_id: '10000000-0000-4000-8000-000000000002',
      status: 'pending',
      submitted_at: '2026-08-12T00:00:00Z',
      reviewed_at: null,
      review_note: null,
      participant: { id: '10000000-0000-4000-8000-000000000003', display_name: 'Peserta', avatar_url: null, weight_kg: 70 },
      program: { id: '10000000-0000-4000-8000-000000000004', title: 'Program', ends_on: '2026-08-20', timezone: 'Asia/Makassar', points_per_activity: 10 },
      day: { day_number: 1, title: 'Mulai' },
      step: { id: '10000000-0000-4000-8000-000000000005', title: 'Bukti', instructions: 'Kirim bukti aktivitas.', content_kind: 'form', verification_mode: 'coach_review' },
      answers: [],
      quiz_result: null,
      initial_weight_kg: 75,
    });
    expect(parsed).not.toHaveProperty('initial_weight_kg');
    expect(parsed.participant).not.toHaveProperty('weight_kg');
  });
});
