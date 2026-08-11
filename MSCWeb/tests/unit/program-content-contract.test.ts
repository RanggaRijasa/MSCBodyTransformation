import { describe, expect, it } from "vitest";

import { parsePublicProgram } from "@/domain/programs/program-contract";

describe("kontrak konten program publik", () => {
  it("memetakan renderer typed lengkap tanpa menerima answer key", () => {
    const raw = {
      category: "Transformasi",
      cover_alt_text: null,
      desired_price: null,
      ends_on: "2026-08-10",
      future_step_policy: "locked",
      id: "program-1",
      participant_limit: null,
      past_step_policy: "read_only",
      points_per_activity: 10,
      points_per_weight_kg: 100,
      pricing_mode: "free",
      program_days: [
        {
          day_number: 1,
          id: "day-1",
          program_steps: [
            {
              completion_policy: "automatic_quiz",
              content_kind: "quiz",
              id: "step-1",
              instructions: "Pilih jawaban.",
              media_alt_text: null,
              media_path: null,
              program_questions: [
                {
                  answer_key: { selected_option_ids: ["option-1"] },
                  id: "question-1",
                  kind: "single_choice",
                  program_question_options: [
                    {
                      id: "option-1",
                      media_alt_text: null,
                      media_path: null,
                      option_order: 1,
                      title: "Pilihan",
                    },
                  ],
                  prompt: "Pertanyaan",
                  question_order: 1,
                },
              ],
              step_order: 1,
              title: "Kuis",
              verification_mode: "automatic",
              video_autoplay: false,
              video_required: false,
              video_threshold: null,
            },
          ],
          scheduled_on: "2026-08-10",
          summary: null,
          title: "Hari pertama",
        },
      ],
      quiz_passing_percentage: 70,
      registration_closes_at: null,
      starts_on: "2026-08-10",
      status: "active",
      summary: "Ringkasan",
      timezone: "Asia/Makassar",
      title: "Program",
      wellness_disclaimer: "Non-diagnostik.",
    };
    const result = parsePublicProgram(raw);
    expect(result.isSuccess).toBe(true);
    if (!result.isSuccess) return;
    const question = result.value.days[0]?.steps[0]?.questions[0];
    expect(question?.kind).toBe("single_choice");
    expect(question).not.toHaveProperty("answerKey");
    expect(question).not.toHaveProperty("answer_key");
  });

  it("menolak path media eksternal atau traversal", () => {
    const baseStep = {
      completion_policy: "mark_complete",
      content_kind: "article",
      id: "step-1",
      instructions: "Baca.",
      media_alt_text: null,
      media_path: "../secret.jpg",
      program_questions: [],
      step_order: 1,
      title: "Artikel",
      verification_mode: "automatic",
      video_autoplay: false,
      video_required: false,
      video_threshold: null,
    };
    const raw = {
      desired_price: null,
      ends_on: "2026-08-10",
      id: "program-1",
      participant_limit: null,
      points_per_activity: 10,
      points_per_weight_kg: 100,
      pricing_mode: "free",
      program_days: [
        {
          day_number: 1,
          id: "day-1",
          program_steps: [baseStep],
          scheduled_on: "2026-08-10",
          summary: null,
          title: "Hari",
        },
      ],
      quiz_passing_percentage: 70,
      registration_closes_at: null,
      starts_on: "2026-08-10",
      status: "active",
      summary: "",
      timezone: "Asia/Makassar",
      title: "Program",
      wellness_disclaimer: "Aman.",
    };
    expect(parsePublicProgram(raw).isSuccess).toBe(false);
  });
});
