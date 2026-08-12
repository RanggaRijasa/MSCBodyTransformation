import type { AdminPaymentQueueItem } from "@/domain/payments/payment";
import type { CoachParticipantDetail, CoachProgramHub } from "@/domain/coach/coach-experience";
import type { PublicLeaderboardEntry } from "@/domain/participant/participant-program";
import { adminSimulatorDashboard, adminSimulatorPrograms } from "@/development/admin-gallery";
import {
  coachSimulatorActivity,
  coachSimulatorProgram,
  coachSimulatorRoster,
} from "@/development/coach-gallery";
import { guestSimulatorProgram } from "@/development/guest-gallery";
import {
  participantSimulatorEnrollment,
  participantSimulatorProgram,
} from "@/development/participant-gallery";
import { simulatorPaymentOrder } from "@/development/payment-gallery";

export const participantSimulatorRanking: readonly PublicLeaderboardEntry[] = [
  {
    id: "simulator-ranking-1",
    isCurrentParticipant: false,
    participantDisplayName: "Dewi Lestari",
    participantId: "simulator-public-1",
    programId: participantSimulatorProgram.id,
    progressPercentage: 90,
    rank: 1,
    totalPoints: 450,
  },
  {
    id: "simulator-ranking-2",
    isCurrentParticipant: true,
    participantDisplayName: "Rani Putri",
    participantId: "simulator-public-2",
    programId: participantSimulatorProgram.id,
    progressPercentage: 60,
    rank: 4,
    totalPoints: 240,
  },
];

export const simulatorProgramSections = {
  available: [guestSimulatorProgram],
  followed: [
    {
      enrollmentId: participantSimulatorEnrollment.enrollmentId,
      program: participantSimulatorProgram,
    },
  ],
  history: [
    {
      ...guestSimulatorProgram,
      endsOn: "2026-07-31",
      id: "simulator-program-history",
      startsOn: "2026-07-01",
      status: "completed" as const,
      title: "MSC Juli",
    },
  ],
};

export const coachSimulatorHub: CoachProgramHub = {
  activity: coachSimulatorActivity,
  assignedPublicProfileIds: new Set([coachSimulatorRoster[0]!.publicProfileId]),
  leaderboard: participantSimulatorRanking,
  programs: [coachSimulatorProgram],
  selectedProgram: coachSimulatorProgram,
  winners: [],
};

export const coachSimulatorParticipantDetail: CoachParticipantDetail = {
  avatarUrl: null,
  city: "Denpasar",
  displayName: coachSimulatorRoster[0]!.displayName,
  enrollmentId: "simulator-coach-enrollment",
  enrollments: [
    {
      id: "simulator-coach-enrollment",
      programId: coachSimulatorProgram.id,
      programTitle: coachSimulatorProgram.title,
    },
  ],
  memberLevel: "member",
  participantId: coachSimulatorRoster[0]!.participantId,
  phoneNumber: "+6281234567890",
  program: coachSimulatorProgram,
  score: {
    activityPoints: 40,
    adjustmentPoints: 0,
    progressPercentage: 40,
    quizPoints: 0,
    totalPoints: 240,
    weightPoints: 200,
  },
  submissions: [
    {
      answers: [
        {
          answerKey: null,
          hasPhoto: false,
          numberValue: null,
          question: null,
          questionId: "simulator-answer-1",
          selectedOptionIds: [],
          textValue: "Saya menyiapkan jadwal aktivitas yang realistis untuk besok.",
        },
      ],
      attemptSequence: 1,
      id: "simulator-submission-1",
      reviewNote: null,
      status: "pending",
      stepId: "simulator-step-1",
      stepTitle: "Refleksi kebiasaan",
      submittedAt: "2026-08-10T02:00:00Z",
    },
  ],
  weighIns: [
    {
      recordedAt: "2026-08-01T00:00:00Z",
      type: "initial",
      weightKilograms: "70.00",
    },
    {
      recordedAt: "2026-08-10T00:00:00Z",
      type: "daily",
      weightKilograms: "68.00",
    },
  ],
};

export const adminSimulatorPeople = [
  { detail: "Peserta · Member", title: "Rani Putri" },
  { detail: "Coach · SC", title: "Coach Ayu" },
  { detail: "Admin · Operasional", title: "Admin MSC" },
] as const;

export const adminSimulatorPaymentQueue: readonly AdminPaymentQueueItem[] = [
  {
    ...simulatorPaymentOrder,
    ownerDisplayName: "Rani Putri",
    ownerEmailHint: "Identitas privat",
    relatedLabel: "MSC Agustus",
    status: "under_review",
    version: 2,
  },
];

export { adminSimulatorDashboard, adminSimulatorPrograms };
