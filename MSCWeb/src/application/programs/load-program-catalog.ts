import "server-only";

import { AppError } from "@/domain/errors/app-error";
import { buildCatalogSections, programRouteMode } from "@/domain/programs/program-catalog";
import type { EnrollmentProjection } from "@/domain/programs/program";
import { failure, success, type Result } from "@/domain/result";
import { loadVerifiedProfile } from "@/features/auth/server/profile-repository";
import {
  supabaseEnrollmentProjectionRepository,
  supabasePublicProgramRepository,
} from "@/infrastructure/supabase/programs/supabase-program-repositories";

async function loadParticipantContext(): Promise<
  Result<
    Readonly<{
      actor: "guest" | "participant" | "other";
      enrollments: readonly EnrollmentProjection[];
      isAuthenticatedParticipant: boolean;
    }>,
    AppError
  >
> {
  const profile = await loadVerifiedProfile();
  if (!profile.isSuccess) {
    return profile.error.code === "unauthorized"
      ? success({ actor: "guest", enrollments: [], isAuthenticatedParticipant: false })
      : profile;
  }
  if (profile.value.role !== "participant" && profile.value.role !== "coach") {
    return success({ actor: "other", enrollments: [], isAuthenticatedParticipant: false });
  }
  const enrollments = await supabaseEnrollmentProjectionRepository.listMine();
  if (!enrollments.isSuccess) return enrollments;
  return success({
    actor: "participant",
    enrollments: enrollments.value,
    isAuthenticatedParticipant: true,
  });
}

export async function loadProgramCatalogOperation(now = new Date()) {
  const programs = await supabasePublicProgramRepository.list();
  if (!programs.isSuccess) return programs;
  const participant = await loadParticipantContext();
  if (!participant.isSuccess) return participant;
  return success({
    actor: participant.value.actor,
    isAuthenticatedParticipant: participant.value.isAuthenticatedParticipant,
    sections: buildCatalogSections(programs.value, participant.value.enrollments, now),
  });
}

export async function loadProgramDetailOperation(programId: string) {
  const program = await supabasePublicProgramRepository.get(programId);
  if (!program.isSuccess) return program;
  if (!program.value) {
    return failure(new AppError("validation_failed", "Program tidak ditemukan."));
  }
  const participant = await loadParticipantContext();
  if (!participant.isSuccess) return participant;
  const route = programRouteMode(programId, participant.value.enrollments);
  return success({
    actor: participant.value.actor,
    enrollmentId: route.mode === "activity" ? route.enrollmentId : null,
    mode: route.mode,
    program: program.value,
  });
}
