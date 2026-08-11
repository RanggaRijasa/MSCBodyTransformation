import type { ParticipantProgram } from "@/domain/participant/participant-program";
import type { PublicProgram } from "@/domain/programs/program";
import { ParticipantHome, ProgramActivity } from "@/features/participant";
import { ProgramContentPreview } from "@/shared/ui";

const program: PublicProgram = {
  category: "Transformasi kebiasaan",
  coverAlternativeText: null,
  coverImageUrl: null,
  days: [
    {
      dayNumber: 1,
      id: "gallery-day",
      scheduledOn: "2026-08-10",
      steps: [
        {
          completionPolicy: "answer_all_questions",
          contentKind: "form",
          id: "gallery-step",
          instructions: "Catat fokus kebiasaanmu hari ini.",
          mediaAlternativeText: null,
          mediaPath: null,
          mediaUrl: null,
          order: 1,
          questions: [],
          title: "Refleksi kebiasaan",
          verificationMode: "coach_review",
          videoAutoplay: false,
          videoRequired: false,
          videoThreshold: null,
        },
      ],
      summary: "Mulai dengan satu kebiasaan yang realistis.",
      title: "Bangun konsistensi",
    },
  ],
  desiredPrice: null,
  endsOn: "2026-08-31",
  futureStepPolicy: "locked",
  id: "gallery-program",
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

const participantProgram: ParticipantProgram = {
  access: [
    {
      accessState: "available",
      dayNumber: 1,
      enrollmentId: "gallery-enrollment",
      isCurrentDay: true,
      programDayId: "gallery-day",
      programId: program.id,
    },
  ],
  enrollmentId: "gallery-enrollment",
  enrollmentStatus: "active",
  program,
  quizResults: [],
  score: {
    activityPoints: 30,
    adjustmentPoints: 0,
    progressPercentage: 60,
    quizPoints: 10,
    rank: 4,
    totalPoints: 240,
    weightPoints: 200,
  },
  submissions: [],
  weighedStepIds: [],
};

export function ParticipantGallery() {
  return (
    <div className="state-gallery__stack">
      <div data-testid="participant-home-gallery">
        <ParticipantHome
          actor="participant"
          coaches={[
            {
              biography: "",
              city: "Denpasar",
              displayName: "Coach Ayu",
              id: "coach-gallery",
              isAssigned: true,
              photoUrl: null,
            },
          ]}
          displayName="Rani"
          programs={[participantProgram]}
          publicPrograms={[]}
          selectedProgram={participantProgram}
          topFive={[
            {
              id: "score-1",
              isCurrentParticipant: false,
              participantDisplayName: "Dewi",
              participantId: "participant-1",
              programId: program.id,
              progressPercentage: 90,
              rank: 1,
              totalPoints: 450,
            },
            {
              id: "score-2",
              isCurrentParticipant: true,
              participantDisplayName: "Rani",
              participantId: "participant-2",
              programId: program.id,
              progressPercentage: 60,
              rank: 4,
              totalPoints: 240,
            },
          ]}
          winnerPosters={[]}
          winners={[]}
        />
      </div>
      <div data-testid="participant-activity-gallery">
        <ProgramActivity participantProgram={participantProgram} />
      </div>
      <div data-testid="coach-content-preview-gallery">
        <ProgramContentPreview audience="coach" step={program.days[0]!.steps[0]!} />
      </div>
    </div>
  );
}
