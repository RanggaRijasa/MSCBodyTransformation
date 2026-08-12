import type { PublicProgram } from "@/domain/programs/program";
import { ProgramCatalog } from "@/features/programs/components/program-catalog";
import { ProgramDetail } from "@/features/programs/components/program-detail";

export function galleryProgram(overrides: Partial<PublicProgram>): PublicProgram {
  return {
    category: "Transformasi kebiasaan",
    coverAlternativeText: null,
    coverImageUrl: null,
    days: [],
    desiredPrice: null,
    endsOn: "2026-09-30",
    futureStepPolicy: "locked",
    id: "00000000-0000-4000-8000-000000000001",
    participantLimit: 50,
    pastStepPolicy: "available",
    pointsPerActivity: 10,
    pointsPerWeightKilogram: "100.00",
    pricingMode: "free",
    quizPassingPercentage: 80,
    registrationClosesAt: "2026-08-20T00:00:00Z",
    startsOn: "2026-09-01",
    status: "scheduled",
    summary: "Bangun rutinitas kebugaran secara bertahap bersama Coach.",
    timezone: "Asia/Makassar",
    title: "MSC September",
    wellnessDisclaimer: "Program kebugaran non-diagnostik.",
    ...overrides,
  };
}

export function ProgramGallery() {
  const detailProgram = galleryProgram({
    desiredPrice: "250000.00",
    id: "00000000-0000-4000-8000-000000000005",
    pricingMode: "paid",
    title: "MSC Detail Mobile",
  });
  return (
    <div>
      <div data-testid="program-gallery">
        <ProgramCatalog
          isAuthenticatedParticipant
          now={new Date("2026-08-10T00:00:00Z")}
          sections={{
            available: [
              galleryProgram({}),
              galleryProgram({
                desiredPrice: "250000.00",
                id: "00000000-0000-4000-8000-000000000002",
                pricingMode: "paid",
                registrationClosesAt: "2026-08-09T00:00:00Z",
                title: "MSC Intensif",
              }),
            ],
            followed: [
              {
                enrollmentId: "00000000-0000-4000-8000-000000000101",
                program: galleryProgram({
                  id: "00000000-0000-4000-8000-000000000003",
                  status: "active",
                  title: "MSC Agustus",
                }),
              },
            ],
            history: [
              galleryProgram({
                id: "00000000-0000-4000-8000-000000000004",
                status: "completed",
                title: "MSC Juli",
              }),
            ],
          }}
        />
      </div>
      <div data-testid="program-detail-gallery">
        <ProgramDetail
          actor="participant"
          mode="offer"
          now={new Date("2026-08-10T00:00:00Z")}
          program={detailProgram}
        />
      </div>
    </div>
  );
}
