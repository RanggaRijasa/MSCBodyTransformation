import { describe, expect, it } from 'vitest';

import type { AdminProgram } from '../../src/features/admin/admin-models';
import { completedAdminStages, validateAdminProgram } from '../../src/features/admin/admin-policy';

describe('W07 Admin program validation', () => {
  it('accepts every published content type and all supported question types', () => {
    const program = validProgram();
    expect(validateAdminProgram(program)).toEqual([]);
    expect(completedAdminStages(program)).toBe(3);
    expect(program.days.flatMap((day) => day.steps).map((step) => step.content_kind)).toEqual([
      'article', 'video', 'form', 'initial_weigh_in', 'daily_weigh_in', 'final_weigh_in', 'quiz',
    ]);
  });

  it('blocks missing cover, empty day, invalid pricing, choice options, and answer key', () => {
    const program = validProgram();
    program.cover_path = null;
    program.desired_price = 0;
    program.days[0]!.steps = [];
    program.days[1]!.steps[0]!.questions[0]!.options = [];
    program.days[1]!.steps[0]!.questions[0]!.answer_key = null;
    const issues = validateAdminProgram(program).map((issue) => issue.message).join(' | ');
    expect(issues).toContain('Cover');
    expect(issues).toContain('Harga');
    expect(issues).toContain('belum memiliki langkah');
    expect(issues).toContain('minimal dua pilihan');
    expect(issues).toContain('kunci jawaban');
  });

  it('requires exactly one initial and final weigh-in when weight points are enabled', () => {
    const program = validProgram();
    program.days[0]!.steps = program.days[0]!.steps.filter((step) => step.content_kind !== 'final_weigh_in');
    expect(validateAdminProgram(program).some((issue) => issue.message.includes('tepat satu timbang awal'))).toBe(true);
  });

  it('requires media accessibility copy and keeps uploads out of quizzes', () => {
    const program = validProgram();
    const quiz = program.days[1]!.steps[0]!;
    quiz.questions[0] = { ...quiz.questions[0]!, kind: 'video_upload', media_kind: 'video', media_path: 'questions/example.mp4', media_alt_text: '' };
    const issues = validateAdminProgram(program).map((issue) => issue.message).join(' | ');
    expect(issues).toContain('deskripsi aksesibilitas');
    expect(issues).toContain('Gunakan Form untuk unggah foto atau video');
  });
});

function validProgram(): AdminProgram {
  const optionA = crypto.randomUUID(); const optionB = crypto.randomUUID();
  return {
    id: crypto.randomUUID(), source_program_id: null, title: 'Program Admin W07', summary: 'Program lengkap untuk pengujian Admin.', category: 'Transformasi',
    cover_path: 'programs/w07.jpg', cover_alt_text: 'Cover Program Admin W07', status: 'draft', pace: 'scheduled', duration_mode: 'specific_dates', default_verification_mode: 'coach_review',
    starts_on: '2026-08-17', ends_on: '2026-08-18', timezone: 'Asia/Makassar', participant_limit: 30, registration_closes_at: null,
    past_step_policy: 'available', future_step_policy: 'locked', wellness_disclaimer: 'Program wellness non-diagnostik.', points_per_activity: 10,
    points_per_weight_kg: 100, quiz_passing_percentage: 70, pricing_mode: 'paid', desired_price: 125_000, published_at: null,
    created_at: new Date().toISOString(), updated_at: new Date().toISOString(),
    days: [
      { id: crypto.randomUUID(), day_number: 1, title: 'Hari ke-1', summary: '', scheduled_on: '2026-08-17', steps: [
        step('article', 1), step('video', 2), step('form', 3), step('initial_weigh_in', 4), step('daily_weigh_in', 5), step('final_weigh_in', 6),
      ] },
      { id: crypto.randomUUID(), day_number: 2, title: 'Hari ke-2', summary: '', scheduled_on: '2026-08-18', steps: [{
        ...step('quiz', 1), questions: [{ id: crypto.randomUUID(), question_order: 1, kind: 'single_choice', prompt: 'Pilihan yang sesuai?', analysis_mode: 'none', analysis_rubric: null, analysis_rubric_version: null,
          options: [{ id: optionA, option_order: 1, title: 'A', media_path: null, media_alt_text: null }, { id: optionB, option_order: 2, title: 'B', media_path: null, media_alt_text: null }],
          answer_key: { question_id: crypto.randomUUID(), accepted_text_values: [], number_value: null, selected_option_ids: [optionA], matching_mode: 'exact' } }],
      }] },
    ],
  };
}

function step(kind: AdminProgram['days'][number]['steps'][number]['content_kind'], order: number) {
  return { id: crypto.randomUUID(), step_order: order, title: `Langkah ${order}`, instructions: 'Ikuti petunjuk.', content_kind: kind,
    completion_policy: kind === 'video' ? 'watch_threshold' : kind.includes('weigh_in') ? 'record_weight' : 'mark_complete',
    verification_mode: 'automatic', media_path: null, media_alt_text: null, video_required: kind === 'video', video_threshold: 80, video_autoplay: false,
    questions: kind === 'form' ? [{ id: crypto.randomUUID(), question_order: 1, kind: 'short_answer', prompt: 'Jawaban singkat', analysis_mode: 'none' as const, analysis_rubric: null, analysis_rubric_version: null, options: [], answer_key: null }] : [] };
}
