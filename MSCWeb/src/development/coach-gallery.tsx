import type {
  CoachActivityItem,
  CoachContext,
  CoachReviewItem,
  CoachRosterEntry,
} from "@/domain/coach/coach-experience";
import type { PublicProgram } from "@/domain/programs/program";
import { CoachAccessState, CoachDashboard, CoachRoster } from "@/features/coach";

export const coachSimulatorContext: CoachContext = {
  accessEndsAt: "2026-11-10T00:00:00Z",
  accessStartsAt: "2026-08-10T00:00:00Z",
  accessState: "active",
  applicationId: "coach-gallery-application",
  applicationStatus: "active",
  avatarUrl: null,
  biography: "Mendampingi kebiasaan sehat secara konsisten.",
  city: "Denpasar",
  displayName: "Coach Ayu",
  email: "coach-gallery@example.invalid",
  isPublic: true,
  paymentOrderId: null,
  paymentStatus: "verified",
  phoneNumber: null,
};

export const coachSimulatorProgram: PublicProgram = {
  category: "Transformasi kebiasaan",
  coverAlternativeText: null,
  coverImageUrl: null,
  days: [],
  desiredPrice: null,
  endsOn: "2026-08-31",
  futureStepPolicy: "locked",
  id: "coach-gallery-program",
  participantLimit: 50,
  pastStepPolicy: "read_only",
  pointsPerActivity: 10,
  pointsPerWeightKilogram: "100.00",
  pricingMode: "free",
  quizPassingPercentage: 70,
  registrationClosesAt: null,
  startsOn: "2026-08-01",
  status: "active",
  summary: "Program kebugaran terarah bersama Coach.",
  timezone: "Asia/Makassar",
  title: "MSC Agustus",
  wellnessDisclaimer: "Program kebugaran non-diagnostik.",
};

export const coachSimulatorRoster: CoachRosterEntry[] = [
  {
    activeEnrollmentCount: 1,
    attentionState: "falling_behind",
    avatarUrl: null,
    city: "Denpasar",
    displayName: "Rani Putri",
    lastActivityAt: "2026-08-08T02:00:00Z",
    memberLevel: "member",
    participantId: "coach-gallery-participant-1",
    pendingReviewCount: 1,
    points: 240,
    programId: coachSimulatorProgram.id,
    programTitle: coachSimulatorProgram.title,
    progressPercentage: 40,
    publicProfileId: "coach-gallery-public-1",
  },
  {
    activeEnrollmentCount: 0,
    attentionState: "not_enrolled",
    avatarUrl: null,
    city: "Gianyar",
    displayName: "Dewi Lestari",
    lastActivityAt: null,
    memberLevel: "member",
    participantId: "coach-gallery-participant-2",
    pendingReviewCount: 0,
    points: 0,
    programId: null,
    programTitle: null,
    progressPercentage: 0,
    publicProfileId: "coach-gallery-public-2",
  },
];

export const coachSimulatorReviews: CoachReviewItem[] = [
  {
    answers: [],
    contentKind: "form",
    participantId: coachSimulatorRoster[0]!.participantId,
    participantName: coachSimulatorRoster[0]!.displayName,
    programId: coachSimulatorProgram.id,
    programTitle: coachSimulatorProgram.title,
    stepId: "coach-gallery-step",
    stepTitle: "Refleksi kebiasaan",
    submissionId: "coach-gallery-submission",
    submittedAt: "2026-08-10T02:00:00Z",
  },
];

export const coachSimulatorActivity: CoachActivityItem[] = [
  {
    id: "coach-gallery-activity",
    kind: "submission_pending",
    occurredAt: "2026-08-10T02:00:00Z",
    participantId: coachSimulatorRoster[0]!.participantId,
    participantName: coachSimulatorRoster[0]!.displayName,
    points: null,
    programId: coachSimulatorProgram.id,
    programTitle: coachSimulatorProgram.title,
    stepTitle: "Refleksi kebiasaan",
  },
];

export function CoachGallery() {
  return (
    <div className="state-gallery__stack">
      <div data-testid="coach-dashboard-gallery">
        <CoachDashboard
          activity={coachSimulatorActivity}
          context={coachSimulatorContext}
          leaderboard={[
            {
              id: "coach-gallery-score",
              isCurrentParticipant: false,
              participantDisplayName: "Rani Putri",
              participantId: coachSimulatorRoster[0]!.publicProfileId,
              programId: coachSimulatorProgram.id,
              progressPercentage: 40,
              rank: 1,
              totalPoints: 240,
            },
          ]}
          programs={[coachSimulatorProgram]}
          reviews={coachSimulatorReviews}
          roster={coachSimulatorRoster}
        />
      </div>
      <div data-testid="coach-roster-gallery">
        <CoachRoster
          context={coachSimulatorContext}
          entries={coachSimulatorRoster}
          filters={{}}
          programs={[coachSimulatorProgram]}
        />
      </div>
      <div data-testid="coach-expired-gallery">
        <CoachAccessState context={{ ...coachSimulatorContext, accessState: "expired" }} />
      </div>
    </div>
  );
}
