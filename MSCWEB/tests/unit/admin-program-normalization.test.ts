import { describe, expect, it } from 'vitest';

import { normalizeProgramGraph } from '@/features/admin/admin-repository';

describe('normalisasi graph program Admin', () => {
  it.each([
    ['objek tunggal', answerKey],
    ['array relasi', [answerKey]],
  ])('mempertahankan kunci jawaban dari bentuk %s', (_label, relation) => {
    const normalized = normalizeProgramGraph({
      program_days: [{
        day_number: 1,
        program_steps: [{
          step_order: 1,
          program_questions: [{
            question_order: 1,
            program_question_options: [],
            program_answer_keys: relation,
          }],
        }],
      }],
    }) as {
      days: Array<{ steps: Array<{ questions: Array<{ answer_key: typeof answerKey }> }> }>;
    };

    expect(normalized.days[0]?.steps[0]?.questions[0]?.answer_key).toStrictEqual(answerKey);
  });
});

const answerKey = {
  question_id: '11111111-1111-4111-8111-111111111111',
  accepted_text_values: [],
  number_value: null,
  selected_option_ids: ['22222222-2222-4222-8222-222222222222'],
  matching_mode: 'exact',
};
