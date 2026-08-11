import type { CoachContext, CoachRosterEntry } from "@/domain/coach/coach-experience";
import type { ParticipantProgram } from "@/domain/participant/participant-program";
import type { PublicProgram } from "@/domain/programs/program";
import { CoachDashboard } from "@/features/coach";
import { ParticipantRanking } from "@/features/participant";

const program: PublicProgram = {
  category: "Transformasi kebiasaan",
  coverAlternativeText: null,
  coverImageUrl: null,
  days: [],
  desiredPrice: null,
  endsOn: "2026-08-31",
  futureStepPolicy: "locked",
  id: "marketing-program-v1",
  participantLimit: 50,
  pastStepPolicy: "read_only",
  pointsPerActivity: 10,
  pointsPerWeightKilogram: "100.00",
  pricingMode: "free",
  quizPassingPercentage: 70,
  registrationClosesAt: null,
  startsOn: "2026-08-01",
  status: "active",
  summary: "Bangun kebiasaan sehat bersama komunitas dan Coach.",
  timezone: "Asia/Makassar",
  title: "Program MSC Demo",
  wellnessDisclaimer: "Program kebugaran non-diagnostik.",
};

const participantProgram: ParticipantProgram = {
  access: [],
  enrollmentId: "marketing-enrollment-v1",
  enrollmentStatus: "active",
  program,
  quizResults: [],
  score: {
    activityPoints: 120,
    adjustmentPoints: 0,
    progressPercentage: 72,
    quizPoints: 40,
    rank: 3,
    totalPoints: 310,
    weightPoints: 150,
  },
  submissions: [],
  weighedStepIds: [],
};

const leaderboard = [
  {
    id: "marketing-score-1",
    isCurrentParticipant: false,
    participantDisplayName: "Peserta Satu",
    participantId: "marketing-public-1",
    programId: program.id,
    progressPercentage: 94,
    rank: 1,
    totalPoints: 460,
  },
  {
    id: "marketing-score-2",
    isCurrentParticipant: false,
    participantDisplayName: "Peserta Dua",
    participantId: "marketing-public-2",
    programId: program.id,
    progressPercentage: 85,
    rank: 2,
    totalPoints: 390,
  },
  {
    id: "marketing-score-3",
    isCurrentParticipant: true,
    participantDisplayName: "Peserta Demo",
    participantId: "marketing-public-current",
    programId: program.id,
    progressPercentage: 72,
    rank: 3,
    totalPoints: 310,
  },
] as const;

const coachContext: CoachContext = {
  accessEndsAt: "2026-11-10T00:00:00Z",
  accessStartsAt: "2026-08-10T00:00:00Z",
  accessState: "active",
  applicationId: "marketing-application-v1",
  applicationStatus: "active",
  avatarUrl: null,
  biography: "Mendampingi kebiasaan sehat secara konsisten.",
  city: "Indonesia",
  displayName: "Coach Demo",
  email: "",
  isPublic: true,
  paymentOrderId: null,
  paymentStatus: null,
  phoneNumber: null,
};

const roster: CoachRosterEntry[] = [
  {
    activeEnrollmentCount: 1,
    attentionState: "on_track",
    avatarUrl: null,
    city: null,
    displayName: "Peserta Satu",
    lastActivityAt: "2026-08-10T02:00:00Z",
    memberLevel: "member",
    participantId: "marketing-participant-1",
    pendingReviewCount: 0,
    points: 460,
    programId: program.id,
    programTitle: program.title,
    progressPercentage: 94,
    publicProfileId: "marketing-public-1",
  },
  {
    activeEnrollmentCount: 1,
    attentionState: "falling_behind",
    avatarUrl: null,
    city: null,
    displayName: "Peserta Dua",
    lastActivityAt: "2026-08-09T02:00:00Z",
    memberLevel: "member",
    participantId: "marketing-participant-2",
    pendingReviewCount: 1,
    points: 390,
    programId: program.id,
    programTitle: program.title,
    progressPercentage: 58,
    publicProfileId: "marketing-public-2",
  },
];

export function MarketingCaptureGallery() {
  return (
    <div className="marketing-capture-gallery" data-fixture-version="phase10-marketing-v1">
      <div data-testid="marketing-participant-capture">
        <ParticipantRanking
          currentEntry={leaderboard[2]}
          entries={leaderboard}
          hasNextPage={false}
          page={1}
          programs={[participantProgram]}
          selected={participantProgram}
          winners={[]}
        />
      </div>
      <div data-testid="marketing-coach-capture">
        <CoachDashboard
          activity={[]}
          context={coachContext}
          leaderboard={leaderboard}
          programs={[program]}
          reviews={[]}
          roster={roster}
        />
      </div>
    </div>
  );
}
