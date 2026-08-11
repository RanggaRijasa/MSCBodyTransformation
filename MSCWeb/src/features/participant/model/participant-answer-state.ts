import type { ProcessedBrowserImage } from "@/infrastructure/browser-media/browser-image-processor";
import type { PublicProgramQuestion } from "@/domain/programs/program";

export type ParticipantAnswerDraft = Readonly<{
  photo?: ProcessedBrowserImage;
  selectedOptionIds: readonly string[];
  value: string;
}>;

export type ParticipantAnswerDrafts = Readonly<Record<string, ParticipantAnswerDraft>>;

export function emptyAnswerDraft(): ParticipantAnswerDraft {
  return { selectedOptionIds: [], value: "" };
}

export function validateParticipantAnswers(
  questions: readonly PublicProgramQuestion[],
  drafts: ParticipantAnswerDrafts,
): Readonly<Record<string, string>> {
  const errors: Record<string, string> = {};
  for (const question of questions) {
    if (question.kind === "heading" || question.kind === "text") continue;
    const draft = drafts[question.id] ?? emptyAnswerDraft();
    if (
      (question.kind === "short_answer" || question.kind === "long_answer") &&
      draft.value.trim().length === 0
    ) {
      errors[question.id] = "Jawaban ini wajib diisi.";
    } else if (question.kind === "number") {
      const normalized = draft.value.trim().replace(",", ".");
      if (!/^-?\d+(?:\.\d{1,2})?$/.test(normalized)) {
        errors[question.id] = "Masukkan angka dengan maksimal dua desimal.";
      }
    } else if (
      ["single_choice", "multiple_choice", "image_choice"].includes(question.kind) &&
      draft.selectedOptionIds.length === 0
    ) {
      errors[question.id] = "Pilih setidaknya satu jawaban.";
    } else if (question.kind === "photo_upload" && !draft.photo) {
      errors[question.id] = "Foto wajib dipilih dan selesai diproses.";
    }
  }
  return errors;
}
