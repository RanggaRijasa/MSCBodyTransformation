import type {
  ProgramCompletionPolicy,
  ProgramContentKind,
  ProgramDayPolicy,
  ProgramPricingMode,
  ProgramQuestionKind,
  ProgramVerificationMode,
  PublicProgram,
} from "@/domain/programs/program";

export type AdminProgramStatus = "active" | "archived" | "completed" | "draft" | "scheduled";

export type AdminAnswerKey = Readonly<{
  acceptedTextValues: readonly string[];
  matchingMode: "case_insensitive_text" | "exact";
  numberValue: string | null;
  selectedOptionIds: readonly string[];
}>;

export type AdminQuestionOption = Readonly<{
  id: string;
  mediaAlternativeText: string | null;
  mediaPath: string | null;
  order: number;
  title: string;
}>;

export type AdminProgramQuestion = Readonly<{
  answerKey: AdminAnswerKey | null;
  id: string;
  kind: ProgramQuestionKind;
  options: readonly AdminQuestionOption[];
  order: number;
  prompt: string;
}>;

export type AdminProgramStep = Readonly<{
  completionPolicy: ProgramCompletionPolicy;
  contentKind: ProgramContentKind;
  id: string;
  instructions: string;
  mediaAlternativeText: string | null;
  mediaPath: string | null;
  order: number;
  questions: readonly AdminProgramQuestion[];
  title: string;
  verificationMode: ProgramVerificationMode;
  videoAutoplay: boolean;
  videoRequired: boolean;
  videoThreshold: number | null;
}>;

export type AdminProgramDay = Readonly<{
  dayNumber: number;
  id: string;
  scheduledOn: string;
  steps: readonly AdminProgramStep[];
  summary: string | null;
  title: string;
}>;

export type AdminProgramDraft = Readonly<{
  category: string | null;
  coverAlternativeText: string | null;
  coverPath: string | null;
  days: readonly AdminProgramDay[];
  desiredPrice: string | null;
  endsOn: string;
  futureStepPolicy: ProgramDayPolicy;
  id: string;
  participantLimit: number | null;
  pastStepPolicy: ProgramDayPolicy;
  pointsPerActivity: number;
  pointsPerWeightKilogram: string;
  pricingMode: ProgramPricingMode;
  quizPassingPercentage: number;
  registrationClosesAt: string | null;
  startsOn: string;
  status: AdminProgramStatus;
  summary: string;
  timezone: string;
  title: string;
  wellnessDisclaimer: string;
}>;

export type AdminProgramListItem = Readonly<{
  desiredPrice: string | null;
  endsOn: string;
  enrollmentCount: number;
  id: string;
  participantLimit: number | null;
  pricingMode: ProgramPricingMode;
  startsOn: string;
  status: AdminProgramStatus;
  title: string;
}>;

export type ProgramValidationIssue = Readonly<{
  field: string;
  message: string;
}>;

const answerKinds = new Set<ProgramQuestionKind>([
  "image_choice",
  "long_answer",
  "multiple_choice",
  "number",
  "photo_upload",
  "short_answer",
  "single_choice",
]);

export function validateProgramDraft(draft: AdminProgramDraft): readonly ProgramValidationIssue[] {
  const issues: ProgramValidationIssue[] = [];
  if (!draft.title.trim()) issues.push({ field: "title", message: "Judul program wajib diisi." });
  if (!draft.timezone.trim())
    issues.push({ field: "timezone", message: "Zona waktu wajib diisi." });
  if (!draft.startsOn || !draft.endsOn || draft.endsOn < draft.startsOn) {
    issues.push({ field: "schedule", message: "Rentang tanggal program tidak valid." });
  }
  if (draft.participantLimit !== null && draft.participantLimit < 1) {
    issues.push({ field: "participantLimit", message: "Kapasitas minimal satu peserta." });
  }
  if (draft.pricingMode === "paid" && Number(draft.desiredPrice) <= 0) {
    issues.push({ field: "desiredPrice", message: "Harga program berbayar wajib lebih dari nol." });
  }
  if (draft.quizPassingPercentage < 0 || draft.quizPassingPercentage > 100) {
    issues.push({ field: "quizPassingPercentage", message: "Ambang kuis harus 0–100%." });
  }
  if (draft.days.length === 0)
    issues.push({ field: "days", message: "Tambahkan minimal satu hari." });

  const dayNumbers = new Set<number>();
  for (const day of draft.days) {
    if (dayNumbers.has(day.dayNumber)) {
      issues.push({ field: `day.${day.id}`, message: "Nomor hari harus unik." });
    }
    dayNumbers.add(day.dayNumber);
    if (!day.title.trim())
      issues.push({ field: `day.${day.id}`, message: "Judul hari wajib diisi." });
    if (day.steps.length === 0) {
      issues.push({
        field: `day.${day.id}.steps`,
        message: "Setiap hari memerlukan minimal satu langkah.",
      });
    }
    for (const step of day.steps) {
      if (!step.title.trim()) {
        issues.push({ field: `step.${step.id}`, message: "Judul langkah wajib diisi." });
      }
      if (step.contentKind === "quiz" && !step.questions.some((question) => question.answerKey)) {
        issues.push({ field: `step.${step.id}.quiz`, message: "Kuis memerlukan kunci jawaban." });
      }
      for (const question of step.questions) {
        if (answerKinds.has(question.kind) && !question.prompt.trim()) {
          issues.push({ field: `question.${question.id}`, message: "Pertanyaan wajib diisi." });
        }
      }
    }
  }

  if (Number(draft.pointsPerWeightKilogram) > 0) {
    const kinds = draft.days.flatMap((day) => day.steps.map((step) => step.contentKind));
    if (
      kinds.filter((kind) => kind === "initial_weigh_in").length !== 1 ||
      kinds.filter((kind) => kind === "final_weigh_in").length !== 1
    ) {
      issues.push({
        field: "weightScoring",
        message: "Poin berat memerlukan tepat satu timbang awal dan satu timbang akhir.",
      });
    }
  }
  return issues;
}

export function copyDayContent(
  source: AdminProgramDay,
  targets: readonly AdminProgramDay[],
  makeId: () => string,
): readonly AdminProgramDay[] {
  return targets.map((target) => ({
    ...target,
    steps: source.steps.map((step, stepIndex) => ({
      ...step,
      id: makeId(),
      order: stepIndex + 1,
      questions: step.questions.map((question, questionIndex) => {
        const options = question.options.map((option, optionIndex) => ({
          ...option,
          id: makeId(),
          order: optionIndex + 1,
        }));
        const selectedIndexes = question.answerKey?.selectedOptionIds.map((selectedId) =>
          question.options.findIndex((option) => option.id === selectedId),
        );
        return {
          ...question,
          id: makeId(),
          order: questionIndex + 1,
          options,
          answerKey: question.answerKey
            ? {
                ...question.answerKey,
                selectedOptionIds: (selectedIndexes ?? [])
                  .filter((index) => index >= 0)
                  .map((index) => options[index]!.id),
              }
            : null,
        };
      }),
    })),
  }));
}

export function projectDraftForPreview(draft: AdminProgramDraft): PublicProgram {
  return {
    category: draft.category ?? "Program",
    coverAlternativeText: draft.coverAlternativeText,
    coverImageUrl: null,
    days: draft.days.map((day) => ({
      ...day,
      steps: day.steps.map((step) => ({
        ...step,
        mediaUrl: null,
        questions: step.questions.map((question) => ({
          id: question.id,
          kind: question.kind,
          options: question.options.map((option) => ({ ...option, mediaUrl: null })),
          order: question.order,
          prompt: question.prompt,
        })),
      })),
    })),
    desiredPrice: draft.desiredPrice,
    endsOn: draft.endsOn,
    futureStepPolicy: draft.futureStepPolicy,
    id: draft.id,
    participantLimit: draft.participantLimit,
    pastStepPolicy: draft.pastStepPolicy,
    pointsPerActivity: draft.pointsPerActivity,
    pointsPerWeightKilogram: draft.pointsPerWeightKilogram,
    pricingMode: draft.pricingMode,
    quizPassingPercentage: draft.quizPassingPercentage,
    registrationClosesAt: draft.registrationClosesAt,
    startsOn: draft.startsOn,
    status: draft.status === "draft" ? "scheduled" : draft.status,
    summary: draft.summary,
    timezone: draft.timezone,
    title: draft.title,
    wellnessDisclaimer: draft.wellnessDisclaimer,
  };
}

export function createBlankProgramDraft(makeId: () => string, today: string): AdminProgramDraft {
  const firstDayId = makeId();
  return {
    category: null,
    coverAlternativeText: null,
    coverPath: null,
    days: [
      {
        dayNumber: 1,
        id: firstDayId,
        scheduledOn: today,
        steps: [],
        summary: null,
        title: "Hari 1",
      },
    ],
    desiredPrice: null,
    endsOn: today,
    futureStepPolicy: "locked",
    id: makeId(),
    participantLimit: null,
    pastStepPolicy: "available",
    pointsPerActivity: 0,
    pointsPerWeightKilogram: "0",
    pricingMode: "free",
    quizPassingPercentage: 70,
    registrationClosesAt: null,
    startsOn: today,
    status: "draft",
    summary: "",
    timezone: "Asia/Makassar",
    title: "Program baru",
    wellnessDisclaimer:
      "Program ini mendukung kebiasaan hidup sehat dan bukan pengganti diagnosis atau perawatan medis.",
  };
}

export function serializeProgramDraft(draft: AdminProgramDraft) {
  return {
    category: draft.category,
    cover_alt_text: draft.coverAlternativeText,
    cover_path: draft.coverPath,
    days: draft.days.map((day) => ({
      day_number: day.dayNumber,
      id: day.id,
      scheduled_on: day.scheduledOn,
      steps: day.steps.map((step) => ({
        completion_policy: step.completionPolicy,
        content_kind: step.contentKind,
        id: step.id,
        instructions: step.instructions,
        media_alt_text: step.mediaAlternativeText,
        media_path: step.mediaPath,
        questions: step.questions.map((question) => ({
          answer_key: question.answerKey
            ? {
                accepted_text_values: question.answerKey.acceptedTextValues,
                matching_mode: question.answerKey.matchingMode,
                number_value: question.answerKey.numberValue,
                selected_option_ids: question.answerKey.selectedOptionIds,
              }
            : undefined,
          id: question.id,
          kind: question.kind,
          options: question.options.map((option) => ({
            id: option.id,
            media_alt_text: option.mediaAlternativeText,
            media_path: option.mediaPath,
            option_order: option.order,
            title: option.title,
          })),
          prompt: question.prompt,
          question_order: question.order,
        })),
        step_order: step.order,
        title: step.title,
        verification_mode: step.verificationMode,
        video_autoplay: step.videoAutoplay,
        video_required: step.videoRequired,
        video_threshold: step.videoThreshold,
      })),
      summary: day.summary,
      title: day.title,
    })),
    desired_price: draft.desiredPrice,
    ends_on: draft.endsOn,
    future_step_policy: draft.futureStepPolicy,
    id: draft.id,
    participant_limit: draft.participantLimit,
    past_step_policy: draft.pastStepPolicy,
    points_per_activity: draft.pointsPerActivity,
    points_per_weight_kg: draft.pointsPerWeightKilogram,
    pricing_mode: draft.pricingMode,
    quiz_passing_percentage: draft.quizPassingPercentage,
    registration_closes_at: draft.registrationClosesAt,
    starts_on: draft.startsOn,
    summary: draft.summary,
    timezone: draft.timezone,
    title: draft.title,
    wellness_disclaimer: draft.wellnessDisclaimer,
  };
}
