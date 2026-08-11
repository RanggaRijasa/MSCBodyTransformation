import { describe, expect, it } from "vitest";

import type { AdminProgramDraft } from "@/domain/admin/admin-program";
import {
  copyDayContent,
  createBlankProgramDraft,
  projectDraftForPreview,
  serializeProgramDraft,
  validateProgramDraft,
} from "@/domain/admin/admin-program";

function identifiers(start = 0) {
  let value = start;
  return () => `00000000-0000-4000-8000-${String(++value).padStart(12, "0")}`;
}

function completeDraft(): AdminProgramDraft {
  const nextId = identifiers();
  const draft = createBlankProgramDraft(nextId, "2026-08-10");
  return {
    ...draft,
    pointsPerActivity: 10,
    days: [
      {
        ...draft.days[0]!,
        steps: [
          {
            completionPolicy: "automatic_quiz",
            contentKind: "quiz",
            id: nextId(),
            instructions: "Pilih jawaban yang paling sesuai.",
            mediaAlternativeText: null,
            mediaPath: null,
            order: 1,
            questions: [
              {
                answerKey: {
                  acceptedTextValues: ["konsisten"],
                  matchingMode: "case_insensitive_text",
                  numberValue: null,
                  selectedOptionIds: [],
                },
                id: nextId(),
                kind: "short_answer",
                options: [],
                order: 1,
                prompt: "Apa fokus utama?",
              },
            ],
            title: "Kuis kebiasaan",
            verificationMode: "automatic",
            videoAutoplay: false,
            videoRequired: false,
            videoThreshold: null,
          },
        ],
      },
    ],
    summary: "Program kebiasaan sehat.",
  };
}

describe("kontrak Admin program", () => {
  it("mempertahankan semua nilai penting pada serialisasi draft", () => {
    const draft = completeDraft();
    const payload = serializeProgramDraft(draft);
    expect(payload.id).toBe(draft.id);
    expect(payload.days[0]?.steps[0]?.questions[0]?.answer_key).toEqual({
      accepted_text_values: ["konsisten"],
      matching_mode: "case_insensitive_text",
      number_value: null,
      selected_option_ids: [],
    });
    expect(validateProgramDraft(draft)).toEqual([]);
  });

  it("copy-day mengganti seluruh nested ID dan memetakan ulang kunci opsi", () => {
    const nextId = identifiers(100);
    const draft = completeDraft();
    const optionId = nextId();
    const source = {
      ...draft.days[0]!,
      steps: draft.days[0]!.steps.map((step) => ({
        ...step,
        questions: step.questions.map((question) => ({
          ...question,
          answerKey: { ...question.answerKey!, selectedOptionIds: [optionId] },
          options: [
            {
              id: optionId,
              mediaAlternativeText: null,
              mediaPath: null,
              order: 1,
              title: "Pilihan",
            },
          ],
        })),
      })),
    };
    const target = { ...source, dayNumber: 2, id: nextId(), scheduledOn: "2026-08-11", steps: [] };
    const copied = copyDayContent(source, [target], nextId)[0]!;
    expect(copied.id).toBe(target.id);
    expect(copied.steps[0]?.id).not.toBe(source.steps[0]?.id);
    expect(copied.steps[0]?.questions[0]?.id).not.toBe(source.steps[0]?.questions[0]?.id);
    expect(copied.steps[0]?.questions[0]?.options[0]?.id).not.toBe(optionId);
    expect(copied.steps[0]?.questions[0]?.answerKey?.selectedOptionIds).toEqual([
      copied.steps[0]?.questions[0]?.options[0]?.id,
    ]);
  });

  it("menolak draft yang tidak publishable dan memakai shared runtime projection", () => {
    const draft = { ...completeDraft(), title: "", days: [] };
    expect(validateProgramDraft(draft).map((issue) => issue.field)).toEqual(
      expect.arrayContaining(["title", "days"]),
    );
    const preview = projectDraftForPreview(completeDraft());
    expect(preview.days[0]?.steps[0]?.contentKind).toBe("quiz");
    expect(preview.days[0]?.steps[0]?.questions[0]?.prompt).toBe("Apa fokus utama?");
  });

  it("mewajibkan pasangan timbang ketika poin berat diaktifkan", () => {
    const draft = { ...completeDraft(), pointsPerWeightKilogram: "100" };
    expect(validateProgramDraft(draft)).toContainEqual(
      expect.objectContaining({ field: "weightScoring" }),
    );
  });
});
