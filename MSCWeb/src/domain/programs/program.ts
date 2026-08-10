export type PublicProgramStatus = "active" | "archived" | "completed" | "scheduled";
export type ProgramPricingMode = "free" | "paid";
export type ProgramDayAccessState = "available" | "hidden" | "locked" | "read_only";
export type ProgramDayPolicy = "available" | "hidden" | "locked" | "read_only";
export type ProgramContentKind =
  "article" | "daily_weigh_in" | "final_weigh_in" | "form" | "initial_weigh_in" | "quiz" | "video";
export type ProgramCompletionPolicy =
  "answer_all_questions" | "automatic_quiz" | "mark_complete" | "submit_weigh_in" | "watch_video";
export type ProgramVerificationMode = "automatic" | "coach_review";
export type ProgramQuestionKind =
  | "heading"
  | "image_choice"
  | "long_answer"
  | "multiple_choice"
  | "number"
  | "photo_upload"
  | "short_answer"
  | "single_choice"
  | "text";

export type PublicProgramQuestionOption = Readonly<{
  id: string;
  mediaAlternativeText: string | null;
  mediaPath: string | null;
  mediaUrl: string | null;
  order: number;
  title: string;
}>;

export type PublicProgramQuestion = Readonly<{
  id: string;
  kind: ProgramQuestionKind;
  options: readonly PublicProgramQuestionOption[];
  order: number;
  prompt: string;
}>;

export type PublicProgramStep = Readonly<{
  completionPolicy: ProgramCompletionPolicy;
  contentKind: ProgramContentKind;
  id: string;
  instructions: string;
  mediaAlternativeText: string | null;
  mediaPath: string | null;
  mediaUrl: string | null;
  order: number;
  questions: readonly PublicProgramQuestion[];
  title: string;
  verificationMode: ProgramVerificationMode;
  videoAutoplay: boolean;
  videoRequired: boolean;
  videoThreshold: number | null;
}>;

export type PublicProgramDay = Readonly<{
  dayNumber: number;
  id: string;
  scheduledOn: string;
  steps: readonly PublicProgramStep[];
  summary: string | null;
  title: string;
}>;

export type PublicProgram = Readonly<{
  category: string;
  coverAlternativeText: string | null;
  coverImageUrl: string | null;
  days: readonly PublicProgramDay[];
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
  status: PublicProgramStatus;
  summary: string;
  timezone: string;
  title: string;
  wellnessDisclaimer: string;
}>;

export type EnrollmentProjection = Readonly<{
  enrollmentId: string;
  programId: string;
  status: "active" | "completed";
}>;
