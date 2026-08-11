import { AppError } from "@/domain/errors/app-error";
import type {
  ProgramContentKind,
  ProgramCompletionPolicy,
  ProgramDayPolicy,
  ProgramQuestionKind,
  ProgramVerificationMode,
  PublicProgram,
  PublicProgramDay,
  PublicProgramQuestion,
  PublicProgramQuestionOption,
  PublicProgramStatus,
  PublicProgramStep,
} from "@/domain/programs/program";
import { failure, success, type Result } from "@/domain/result";

const statuses = new Set<PublicProgramStatus>(["scheduled", "active", "completed", "archived"]);
const contentKinds = new Set<ProgramContentKind>([
  "article",
  "video",
  "form",
  "quiz",
  "initial_weigh_in",
  "daily_weigh_in",
  "final_weigh_in",
]);
const completionPolicies = new Set<ProgramCompletionPolicy>([
  "mark_complete",
  "answer_all_questions",
  "watch_video",
  "automatic_quiz",
  "submit_weigh_in",
]);
const verificationModes = new Set<ProgramVerificationMode>(["automatic", "coach_review"]);
const questionKinds = new Set<ProgramQuestionKind>([
  "short_answer",
  "long_answer",
  "number",
  "single_choice",
  "multiple_choice",
  "image_choice",
  "photo_upload",
  "heading",
  "text",
]);
const dayPolicies = new Set<ProgramDayPolicy>(["available", "hidden", "locked", "read_only"]);

function record(value: unknown): Record<string, unknown> | null {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : null;
}

function requiredString(value: unknown): string | null {
  return typeof value === "string" && value.trim().length > 0 ? value : null;
}

function optionalString(value: unknown): string | null | undefined {
  return value === null ? null : typeof value === "string" ? value : undefined;
}

function decimalString(value: unknown): string | null {
  if (typeof value === "string" && /^\d+(?:\.\d{1,2})?$/.test(value)) return value;
  if (typeof value === "number" && Number.isFinite(value) && value >= 0) return String(value);
  return null;
}

function optionalPath(value: unknown): string | null | undefined {
  const path = optionalString(value);
  if (path === null) return null;
  if (
    path === undefined ||
    path.length === 0 ||
    path.length > 512 ||
    path.includes("..") ||
    path.includes("://") ||
    path.startsWith("/")
  ) {
    return undefined;
  }
  return path;
}

function parseOption(value: unknown): PublicProgramQuestionOption | null {
  const input = record(value);
  if (!input) return null;
  const id = requiredString(input.id);
  const title = typeof input.title === "string" ? input.title : null;
  const mediaPath = optionalPath(input.media_path);
  const mediaAlternativeText = optionalString(input.media_alt_text);
  const order = input.option_order;
  if (
    !id ||
    title === null ||
    mediaPath === undefined ||
    mediaAlternativeText === undefined ||
    !Number.isInteger(order) ||
    (order as number) <= 0
  ) {
    return null;
  }
  return {
    id,
    mediaAlternativeText,
    mediaPath,
    mediaUrl: null,
    order: order as number,
    title,
  };
}

function parseQuestion(value: unknown): PublicProgramQuestion | null {
  const input = record(value);
  if (!input || !Array.isArray(input.program_question_options)) return null;
  const id = requiredString(input.id);
  const prompt = typeof input.prompt === "string" ? input.prompt : null;
  const kind = input.kind;
  const order = input.question_order;
  const options = input.program_question_options.map(parseOption);
  if (
    !id ||
    prompt === null ||
    typeof kind !== "string" ||
    !questionKinds.has(kind as ProgramQuestionKind) ||
    !Number.isInteger(order) ||
    (order as number) <= 0 ||
    options.some((option) => option === null)
  ) {
    return null;
  }
  return {
    id,
    kind: kind as ProgramQuestionKind,
    options: options as PublicProgramQuestionOption[],
    order: order as number,
    prompt,
  };
}

function parseStep(value: unknown): PublicProgramStep | null {
  const input = record(value);
  if (!input || !Array.isArray(input.program_questions)) return null;
  const id = requiredString(input.id);
  const title = requiredString(input.title);
  const instructions = typeof input.instructions === "string" ? input.instructions : null;
  const kind = input.content_kind;
  const completionPolicy = input.completion_policy;
  const verificationMode = input.verification_mode;
  const mediaPath = optionalPath(input.media_path);
  const mediaAlternativeText = optionalString(input.media_alt_text);
  const videoRequired = input.video_required;
  const videoAutoplay = input.video_autoplay;
  const videoThreshold = input.video_threshold;
  const order = input.step_order;
  const questions = input.program_questions.map(parseQuestion);
  if (
    !id ||
    !title ||
    instructions === null ||
    typeof kind !== "string" ||
    !contentKinds.has(kind as ProgramContentKind) ||
    typeof completionPolicy !== "string" ||
    !completionPolicies.has(completionPolicy as ProgramCompletionPolicy) ||
    typeof verificationMode !== "string" ||
    !verificationModes.has(verificationMode as ProgramVerificationMode) ||
    mediaPath === undefined ||
    mediaAlternativeText === undefined ||
    typeof videoRequired !== "boolean" ||
    typeof videoAutoplay !== "boolean" ||
    (videoThreshold !== null &&
      (!Number.isInteger(videoThreshold) ||
        (videoThreshold as number) < 0 ||
        (videoThreshold as number) > 100)) ||
    !Number.isInteger(order) ||
    (order as number) <= 0 ||
    questions.some((question) => question === null)
  ) {
    return null;
  }
  return {
    completionPolicy: completionPolicy as ProgramCompletionPolicy,
    contentKind: kind as ProgramContentKind,
    id,
    instructions,
    mediaAlternativeText,
    mediaPath,
    mediaUrl: null,
    order: order as number,
    questions: questions as PublicProgramQuestion[],
    title,
    verificationMode: verificationMode as ProgramVerificationMode,
    videoAutoplay,
    videoRequired,
    videoThreshold: videoThreshold as number | null,
  };
}

function parseDay(value: unknown): PublicProgramDay | null {
  const input = record(value);
  if (!input || !Array.isArray(input.program_steps)) return null;
  const id = requiredString(input.id);
  const title = requiredString(input.title);
  const scheduledOn = requiredString(input.scheduled_on);
  const summary = optionalString(input.summary);
  const dayNumber = input.day_number;
  const steps = input.program_steps.map(parseStep);
  if (
    !id ||
    !title ||
    !scheduledOn ||
    summary === undefined ||
    !Number.isInteger(dayNumber) ||
    (dayNumber as number) <= 0 ||
    steps.some((step) => step === null)
  ) {
    return null;
  }
  return {
    dayNumber: dayNumber as number,
    id,
    scheduledOn,
    steps: steps as PublicProgramStep[],
    summary,
    title,
  };
}

export function parsePublicProgram(value: unknown): Result<PublicProgram, AppError> {
  const input = record(value);
  if (!input || !Array.isArray(input.program_days)) {
    return failure(new AppError("validation_failed", "Data program publik tidak valid."));
  }
  const status = input.status;
  const pricingMode = input.pricing_mode;
  const desiredPrice = optionalString(input.desired_price);
  const price = desiredPrice === null ? null : decimalString(input.desired_price);
  const pointsPerWeight = decimalString(input.points_per_weight_kg);
  const days = input.program_days.map(parseDay);
  const program: PublicProgram = {
    category: requiredString(input.category) ?? "Program transformasi",
    coverAlternativeText: optionalString(input.cover_alt_text) ?? null,
    coverImageUrl: null,
    days: days as PublicProgramDay[],
    desiredPrice: price,
    endsOn: requiredString(input.ends_on) ?? "",
    futureStepPolicy: (requiredString(input.future_step_policy) ?? "locked") as ProgramDayPolicy,
    id: requiredString(input.id) ?? "",
    participantLimit: input.participant_limit === null ? null : (input.participant_limit as number),
    pastStepPolicy: (requiredString(input.past_step_policy) ?? "available") as ProgramDayPolicy,
    pointsPerActivity: input.points_per_activity as number,
    pointsPerWeightKilogram: pointsPerWeight ?? "",
    pricingMode: pricingMode as PublicProgram["pricingMode"],
    quizPassingPercentage: input.quiz_passing_percentage as number,
    registrationClosesAt: optionalString(input.registration_closes_at) ?? null,
    startsOn: requiredString(input.starts_on) ?? "",
    status: status as PublicProgramStatus,
    summary: typeof input.summary === "string" ? input.summary : "",
    timezone: requiredString(input.timezone) ?? "",
    title: requiredString(input.title) ?? "",
    wellnessDisclaimer:
      typeof input.wellness_disclaimer === "string" ? input.wellness_disclaimer : "",
  };
  const participantLimitValid =
    program.participantLimit === null ||
    (Number.isInteger(program.participantLimit) && program.participantLimit > 0);
  if (
    !program.id ||
    !program.title ||
    !program.startsOn ||
    !program.endsOn ||
    !program.timezone ||
    !dayPolicies.has(program.futureStepPolicy) ||
    !dayPolicies.has(program.pastStepPolicy) ||
    typeof status !== "string" ||
    !statuses.has(status as PublicProgramStatus) ||
    (pricingMode !== "free" && pricingMode !== "paid") ||
    (pricingMode === "free" && program.desiredPrice !== null) ||
    (pricingMode === "paid" && program.desiredPrice === null) ||
    !participantLimitValid ||
    !Number.isInteger(program.pointsPerActivity) ||
    program.pointsPerActivity < 0 ||
    !pointsPerWeight ||
    !Number.isInteger(program.quizPassingPercentage) ||
    program.quizPassingPercentage < 0 ||
    program.quizPassingPercentage > 100 ||
    days.some((day) => day === null)
  ) {
    return failure(new AppError("validation_failed", "Data program publik tidak valid."));
  }
  return success(program);
}
