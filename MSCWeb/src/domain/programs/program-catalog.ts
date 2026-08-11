import type { EnrollmentProjection, PublicProgram } from "@/domain/programs/program";

export type ProgramOfferState =
  "available" | "registration_closed" | "program_completed" | "program_unavailable";

export type CatalogSections = Readonly<{
  available: readonly PublicProgram[];
  followed: readonly Readonly<{ enrollmentId: string; program: PublicProgram }>[];
  history: readonly PublicProgram[];
}>;

export function evaluateProgramOffer(program: PublicProgram, now: Date): ProgramOfferState {
  if (program.status === "completed" || program.status === "archived") return "program_completed";
  if (program.status !== "scheduled" && program.status !== "active") return "program_unavailable";
  if (
    program.registrationClosesAt &&
    Number.isFinite(Date.parse(program.registrationClosesAt)) &&
    now.getTime() >= Date.parse(program.registrationClosesAt)
  ) {
    return "registration_closed";
  }
  return "available";
}

export function buildCatalogSections(
  programs: readonly PublicProgram[],
  enrollments: readonly EnrollmentProjection[],
  now: Date,
): CatalogSections {
  const enrollmentByProgram = new Map(enrollments.map((item) => [item.programId, item]));
  const followed: Array<Readonly<{ enrollmentId: string; program: PublicProgram }>> = [];
  const available: PublicProgram[] = [];
  const history: PublicProgram[] = [];
  for (const program of programs) {
    const enrollment = enrollmentByProgram.get(program.id);
    if (enrollment?.status === "active") {
      followed.push({ enrollmentId: enrollment.enrollmentId, program });
    } else if (
      enrollment?.status === "completed" ||
      evaluateProgramOffer(program, now) === "program_completed"
    ) {
      history.push(program);
    } else {
      available.push(program);
    }
  }
  return { available, followed, history };
}

export function programRouteMode(
  programId: string,
  enrollments: readonly EnrollmentProjection[],
): Readonly<{ enrollmentId: string; mode: "activity" }> | Readonly<{ mode: "offer" }> {
  const enrollment = enrollments.find((item) => item.programId === programId);
  return enrollment
    ? { enrollmentId: enrollment.enrollmentId, mode: "activity" }
    : { mode: "offer" };
}
