import type { ProgramDayAccessState, PublicProgram } from "@/domain/programs/program";

export type SubmissionStatus = "approved" | "draft" | "pending" | "rejected";

export type ParticipantDayAccess = Readonly<{
  accessState: ProgramDayAccessState;
  dayNumber: number;
  enrollmentId: string;
  isCurrentDay: boolean;
  programDayId: string;
  programId: string;
}>;

export type ParticipantSubmission = Readonly<{
  attemptSequence: number;
  id: string;
  reviewNote: string | null;
  status: SubmissionStatus;
  stepId: string;
  submittedAt: string;
}>;

export type ParticipantQuizResult = Readonly<{
  awardedPoints: number;
  correctCount: number;
  passed: boolean;
  percentage: number;
  submissionId: string;
  totalCount: number;
}>;

export type ParticipantScore = Readonly<{
  activityPoints: number;
  adjustmentPoints: number;
  progressPercentage: number;
  quizPoints: number;
  rank: number | null;
  totalPoints: number;
  weightPoints: number;
}>;

export type ParticipantProgram = Readonly<{
  access: readonly ParticipantDayAccess[];
  enrollmentId: string;
  enrollmentStatus: "active" | "completed";
  program: PublicProgram;
  quizResults: readonly ParticipantQuizResult[];
  score: ParticipantScore;
  submissions: readonly ParticipantSubmission[];
  weighedStepIds: readonly string[];
}>;

export type PublicCoach = Readonly<{
  biography: string;
  city: string | null;
  displayName: string;
  id: string;
  isAssigned: boolean;
  photoUrl: string | null;
}>;

export type PublicLeaderboardEntry = Readonly<{
  id: string;
  isCurrentParticipant: boolean;
  participantDisplayName: string;
  participantId: string;
  programId: string;
  progressPercentage: number;
  rank: number;
  totalPoints: number;
}>;

export type PublicWinner = Readonly<{
  id: string;
  lockedAt: string;
  participantDisplayName: string;
  participantId: string;
  programId: string;
  rank: number;
  totalPoints: number;
}>;

export type PublicWinnerPoster = Readonly<{
  alternativeText: string;
  id: string;
  imageUrl: string | null;
  programId: string;
  title: string;
}>;

export type ParticipantHome = Readonly<{
  coaches: readonly PublicCoach[];
  displayName: string;
  programs: readonly ParticipantProgram[];
  topFive: readonly PublicLeaderboardEntry[];
  winnerPosters: readonly PublicWinnerPoster[];
  winners: readonly PublicWinner[];
}>;
