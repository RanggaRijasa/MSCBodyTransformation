import type {
  PublicLeaderboardEntry,
  PublicWinner,
} from "@/domain/participant/participant-program";
import type { PublicProgram, PublicProgramQuestion } from "@/domain/programs/program";

export type CoachAccessState = "active" | "expired" | "pending" | "rejected" | "inactive";
export type CoachAttentionState =
  "complete" | "falling_behind" | "not_enrolled" | "not_started" | "on_track";

export type CoachContext = Readonly<{
  accessEndsAt: string | null;
  accessStartsAt: string | null;
  accessState: CoachAccessState;
  applicationId: string | null;
  applicationStatus: string | null;
  avatarUrl: string | null;
  biography: string;
  city: string;
  displayName: string;
  email: string;
  isPublic: boolean;
  paymentOrderId: string | null;
  paymentStatus: string | null;
  phoneNumber: string | null;
}>;

export type CoachRosterEntry = Readonly<{
  activeEnrollmentCount: number;
  attentionState: CoachAttentionState;
  avatarUrl: string | null;
  city: string | null;
  displayName: string;
  lastActivityAt: string | null;
  memberLevel: string | null;
  participantId: string;
  pendingReviewCount: number;
  points: number;
  programId: string | null;
  programTitle: string | null;
  progressPercentage: number;
  publicProfileId: string;
}>;

export type CoachPrivateAnswer = Readonly<{
  answerKey: Readonly<{
    acceptedTextValues: readonly string[];
    matchingMode: string;
    numberValue: string | null;
    selectedOptionIds: readonly string[];
  }> | null;
  hasPhoto: boolean;
  numberValue: string | null;
  question: PublicProgramQuestion | null;
  questionId: string;
  selectedOptionIds: readonly string[];
  textValue: string | null;
}>;

export type CoachSubmissionDetail = Readonly<{
  answers: readonly CoachPrivateAnswer[];
  attemptSequence: number;
  id: string;
  reviewNote: string | null;
  status: "approved" | "draft" | "pending" | "rejected";
  stepId: string;
  stepTitle: string;
  submittedAt: string | null;
}>;

export type CoachWeighIn = Readonly<{
  recordedAt: string;
  type: "daily" | "final" | "initial";
  weightKilograms: string;
}>;

export type CoachParticipantDetail = Readonly<{
  avatarUrl: string | null;
  city: string | null;
  displayName: string;
  enrollmentId: string;
  enrollments: readonly Readonly<{ id: string; programId: string; programTitle: string }>[];
  memberLevel: string | null;
  participantId: string;
  phoneNumber: string | null;
  program: PublicProgram;
  score: Readonly<{
    activityPoints: number;
    adjustmentPoints: number;
    progressPercentage: number;
    quizPoints: number;
    totalPoints: number;
    weightPoints: number;
  }>;
  submissions: readonly CoachSubmissionDetail[];
  weighIns: readonly CoachWeighIn[];
}>;

export type CoachReviewItem = Readonly<{
  answers: readonly CoachPrivateAnswer[];
  contentKind: string;
  participantId: string;
  participantName: string;
  programId: string;
  programTitle: string;
  stepId: string;
  stepTitle: string;
  submissionId: string;
  submittedAt: string;
}>;

export type CoachActivityItem = Readonly<{
  id: string;
  kind:
    | "participant_joined"
    | "program_completed"
    | "step_completed"
    | "submission_pending"
    | "submission_rejected";
  occurredAt: string;
  participantId: string;
  participantName: string;
  points: number | null;
  programId: string;
  programTitle: string;
  stepTitle: string | null;
}>;

export type CoachProgramHub = Readonly<{
  activity: readonly CoachActivityItem[];
  assignedPublicProfileIds: ReadonlySet<string>;
  leaderboard: readonly PublicLeaderboardEntry[];
  programs: readonly PublicProgram[];
  selectedProgram: PublicProgram | null;
  winners: readonly PublicWinner[];
}>;
