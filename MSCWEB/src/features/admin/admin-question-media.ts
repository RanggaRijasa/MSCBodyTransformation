import type { AdminQuestion } from './admin-models';

export function defaultQuestionPromptMediaAltText(
  mediaKind: 'image' | 'video',
  prompt: string,
  questionOrder: number,
): string {
  const label = mediaKind === 'video' ? 'Video' : 'Gambar';
  const normalizedPrompt = prompt.trim();
  return normalizedPrompt
    ? `${label} panduan untuk pertanyaan: ${normalizedPrompt}`
    : `${label} panduan untuk pertanyaan ${questionOrder}.`;
}

export function normalizeQuestionPromptMedia(question: AdminQuestion): AdminQuestion {
  const foodInsightEnabled = question.kind === 'photo_upload' && question.analysis_mode === 'food';
  const normalizedQuestion: AdminQuestion = {
    ...question,
    analysis_mode: foodInsightEnabled ? 'food' : 'none',
    analysis_rubric: foodInsightEnabled ? question.analysis_rubric : null,
    analysis_rubric_version: foodInsightEnabled ? question.analysis_rubric_version : null,
  };
  if (!normalizedQuestion.media_kind || !normalizedQuestion.media_path) return normalizedQuestion;
  const mediaAltText = normalizedQuestion.media_alt_text?.trim()
    || defaultQuestionPromptMediaAltText(normalizedQuestion.media_kind, normalizedQuestion.prompt, normalizedQuestion.question_order);
  return { ...normalizedQuestion, media_alt_text: mediaAltText };
}
