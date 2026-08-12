import type { PublicCoach, PublicLeaderboardEntry } from "@/domain/participant/participant-program";
import type { PublicProgram } from "@/domain/programs/program";
import { ParticipantHome } from "@/features/participant/components/participant-home";

export const guestSimulatorProgram: PublicProgram = {
  category: "Transformasi kebiasaan",
  coverAlternativeText: null,
  coverImageUrl: null,
  days: [],
  desiredPrice: null,
  endsOn: "2026-09-30",
  futureStepPolicy: "locked",
  id: "guest-gallery-program",
  participantLimit: 60,
  pastStepPolicy: "read_only",
  pointsPerActivity: 10,
  pointsPerWeightKilogram: "100.00",
  pricingMode: "free",
  quizPassingPercentage: 70,
  registrationClosesAt: null,
  startsOn: "2026-09-01",
  status: "scheduled",
  summary: "Program kebugaran terarah yang dapat dilihat sebelum masuk.",
  timezone: "Asia/Makassar",
  title: "MSC September",
  wellnessDisclaimer: "Program kebugaran non-diagnostik.",
};

export const guestSimulatorCoaches: readonly PublicCoach[] = [
  {
    biography: "Mendampingi kebiasaan sehat secara konsisten.",
    city: "Denpasar",
    displayName: "Coach Ayu",
    id: "guest-gallery-coach",
    isAssigned: false,
    photoUrl: null,
  },
];

export const guestSimulatorRanking: readonly PublicLeaderboardEntry[] = [
  {
    id: "guest-gallery-score-1",
    isCurrentParticipant: false,
    participantDisplayName: "Peserta Satu",
    participantId: "guest-gallery-public-1",
    programId: guestSimulatorProgram.id,
    progressPercentage: 90,
    rank: 1,
    totalPoints: 450,
  },
  {
    id: "guest-gallery-score-2",
    isCurrentParticipant: false,
    participantDisplayName: "Peserta Dua",
    participantId: "guest-gallery-public-2",
    programId: guestSimulatorProgram.id,
    progressPercentage: 76,
    rank: 2,
    totalPoints: 390,
  },
];

export function GuestGallery() {
  return (
    <div data-testid="guest-home-gallery">
      <ParticipantHome
        actor="guest"
        coaches={guestSimulatorCoaches}
        displayName=""
        programs={[]}
        publicPrograms={[guestSimulatorProgram]}
        selectedProgram={null}
        topFive={guestSimulatorRanking}
        winnerPosters={[]}
        winners={[]}
      />
    </div>
  );
}
