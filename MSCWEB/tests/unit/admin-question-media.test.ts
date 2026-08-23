import { describe, expect, it } from 'vitest';

import {
  defaultQuestionPromptMediaAltText,
  normalizeQuestionPromptMedia,
} from '../../src/features/admin/admin-question-media';
import type { AdminQuestion } from '../../src/features/admin/admin-models';

describe('Admin question prompt media', () => {
  it('creates an accessible default from the question prompt', () => {
    expect(defaultQuestionPromptMediaAltText('image', '  Unggah foto awal  ', 1))
      .toBe('Gambar panduan untuk pertanyaan: Unggah foto awal');
    expect(defaultQuestionPromptMediaAltText('video', '', 2))
      .toBe('Video panduan untuk pertanyaan 2.');
  });

  it('fills a missing description before the graph is saved', () => {
    const question = makeQuestion({
      media_kind: 'video',
      media_path: 'questions/example.mp4',
      media_alt_text: '',
    });

    expect(normalizeQuestionPromptMedia(question).media_alt_text)
      .toBe('Video panduan untuk pertanyaan: Tunjukkan posisi timbang awal');
  });

  it('preserves a description written by the Admin', () => {
    const question = makeQuestion({
      media_kind: 'image',
      media_path: 'questions/example.jpg',
      media_alt_text: 'Peserta berdiri menghadap kamera.',
    });

    expect(normalizeQuestionPromptMedia(question).media_alt_text)
      .toBe('Peserta berdiri menghadap kamera.');
  });

  it('preserves food insight only when the photo question is opted in', () => {
    expect(normalizeQuestionPromptMedia(makeQuestion({
      analysis_mode: 'food',
      analysis_rubric: 'Rubrik makanan',
      analysis_rubric_version: 'rubric_food_v1',
    }))).toMatchObject({
      analysis_mode: 'food',
      analysis_rubric: 'Rubrik makanan',
      analysis_rubric_version: 'rubric_food_v1',
    });
  });

  it('clears stale AI configuration when the toggle is off or the question is not a photo', () => {
    for (const candidate of [
      makeQuestion({ analysis_mode: 'none', analysis_rubric: 'Rubrik lama', analysis_rubric_version: 'v1' }),
      makeQuestion({ kind: 'video_upload', analysis_mode: 'food', analysis_rubric: 'Rubrik lama', analysis_rubric_version: 'v1' }),
    ]) {
      expect(normalizeQuestionPromptMedia(candidate)).toMatchObject({
        analysis_mode: 'none',
        analysis_rubric: null,
        analysis_rubric_version: null,
      });
    }
  });
});

function makeQuestion(values: Partial<AdminQuestion>): AdminQuestion {
  return {
    id: crypto.randomUUID(),
    question_order: 1,
    kind: 'photo_upload',
    prompt: 'Tunjukkan posisi timbang awal',
    analysis_mode: 'none',
    analysis_rubric: null,
    analysis_rubric_version: null,
    media_kind: null,
    media_path: null,
    media_alt_text: null,
    options: [],
    answer_key: null,
    ...values,
  };
}
