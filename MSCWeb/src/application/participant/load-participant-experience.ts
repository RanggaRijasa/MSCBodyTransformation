import "server-only";

import { AppError } from "@/domain/errors/app-error";
import {
  leaderboardOffset,
  leaderboardPageSize,
  normalizeLeaderboardPage,
  sliceLeaderboardPage,
} from "@/domain/scoring/leaderboard";
import { selectParticipantProgram } from "@/domain/services/participant-program";
import { presentParticipantStep } from "@/domain/services/participant-program";
import { failure, success } from "@/domain/result";
import { loadVerifiedProfile } from "@/features/auth/server/profile-repository";
import { supabaseParticipantExperienceRepository as repository } from "@/infrastructure/supabase/programs/supabase-participant-repository";
import { supabasePublicProgramRepository } from "@/infrastructure/supabase/programs/supabase-program-repositories";

export async function loadParticipantHomeOperation(requestedProgramId?: string) {
  const profile = await loadVerifiedProfile();
  if (!profile.isSuccess) {
    if (profile.error.code !== "unauthorized") return profile;
    const [programsResult, coachesResult, postersResult] = await Promise.all([
      supabasePublicProgramRepository.list(),
      repository.listCoaches(),
      repository.listWinnerPosters(),
    ]);
    if (!programsResult.isSuccess) return programsResult;
    if (!coachesResult.isSuccess) return coachesResult;
    if (!postersResult.isSuccess) return postersResult;
    const publicProgram = programsResult.value.find(({ status }) => status === "active") ?? null;
    const topFive = publicProgram
      ? await repository.listLeaderboard(publicProgram.id, 5)
      : success([]);
    const winners = publicProgram ? await repository.listWinners(publicProgram.id) : success([]);
    if (!topFive.isSuccess) return topFive;
    if (!winners.isSuccess) return winners;
    return success({
      actor: "guest" as const,
      coaches: coachesResult.value,
      displayName: "",
      programs: [],
      publicPrograms: programsResult.value,
      selectedProgram: null,
      topFive: topFive.value,
      winnerPosters: postersResult.value,
      winners: winners.value,
    });
  }

  if (profile.value.role !== "participant" && profile.value.role !== "coach") {
    return failure(new AppError("forbidden", "Halaman ini hanya tersedia untuk Peserta."));
  }
  const [programsResult, coachesResult, postersResult] = await Promise.all([
    repository.listMyPrograms(),
    repository.listCoaches(),
    repository.listWinnerPosters(),
  ]);
  if (!programsResult.isSuccess) return programsResult;
  if (!coachesResult.isSuccess) return coachesResult;
  if (!postersResult.isSuccess) return postersResult;
  const selectedProgram = selectParticipantProgram(programsResult.value, requestedProgramId);
  const topFive = selectedProgram
    ? await repository.listLeaderboard(selectedProgram.program.id, 5)
    : success([]);
  const winners = selectedProgram
    ? await repository.listWinners(selectedProgram.program.id)
    : success([]);
  if (!topFive.isSuccess) return topFive;
  if (!winners.isSuccess) return winners;
  return success({
    actor: "participant" as const,
    coaches: coachesResult.value,
    displayName: profile.value.displayName,
    programs: programsResult.value,
    publicPrograms: [],
    selectedProgram,
    topFive: topFive.value,
    winnerPosters: postersResult.value,
    winners: winners.value,
  });
}

export async function loadParticipantActivityOperation(programId: string) {
  const profile = await loadVerifiedProfile();
  if (!profile.isSuccess) return profile;
  if (profile.value.role !== "participant" && profile.value.role !== "coach") {
    return failure(new AppError("forbidden", "Aktivitas ini hanya tersedia untuk Peserta."));
  }
  const programs = await repository.listMyPrograms();
  if (!programs.isSuccess) return programs;
  const participantProgram = programs.value.find(({ program }) => program.id === programId);
  return participantProgram
    ? success(participantProgram)
    : failure(new AppError("forbidden", "Program ini belum aktif untuk akunmu."));
}

export async function loadParticipantStepOperation(programId: string, stepId: string) {
  const activity = await loadParticipantActivityOperation(programId);
  if (!activity.isSuccess) return activity;
  for (const day of activity.value.program.days) {
    const step = day.steps.find(({ id }) => id === stepId);
    if (!step) continue;
    const access = activity.value.access.find(({ programDayId }) => programDayId === day.id);
    if (!access || access.accessState === "hidden" || access.accessState === "locked") {
      return failure(new AppError("forbidden", "Langkah ini belum tersedia."));
    }
    const presentation = presentParticipantStep(step, access.accessState, activity.value);
    return success({ access, day, participantProgram: activity.value, presentation, step });
  }
  return failure(new AppError("validation_failed", "Langkah program tidak ditemukan."));
}

export async function loadParticipantRankingOperation(
  requestedProgramId?: string,
  requestedPage = 1,
) {
  const programs = await repository.listMyPrograms();
  if (!programs.isSuccess) return programs;
  const selected = selectParticipantProgram(programs.value, requestedProgramId);
  const page = normalizeLeaderboardPage(requestedPage);
  if (!selected)
    return success({
      currentEntry: null,
      entries: [],
      hasNextPage: false,
      page,
      programs: [],
      selected: null,
      winners: [],
    });
  const [pageEntries, winners] = await Promise.all([
    repository.listLeaderboard(
      selected.program.id,
      leaderboardPageSize + 1,
      leaderboardOffset(page),
    ),
    repository.listWinners(selected.program.id),
  ]);
  if (!pageEntries.isSuccess) return pageEntries;
  if (!winners.isSuccess) return winners;
  const pageWindow = sliceLeaderboardPage(pageEntries.value);
  const entries = pageWindow.entries;
  let currentEntry = entries.find(({ isCurrentParticipant }) => isCurrentParticipant) ?? null;
  if (!currentEntry && selected.score.rank && selected.score.rank > 0) {
    const ownEntry = await repository.listLeaderboard(
      selected.program.id,
      1,
      selected.score.rank - 1,
    );
    if (!ownEntry.isSuccess) return ownEntry;
    currentEntry = ownEntry.value.find(({ isCurrentParticipant }) => isCurrentParticipant) ?? null;
  }
  return success({
    currentEntry,
    entries,
    hasNextPage: pageWindow.hasNextPage,
    page,
    programs: programs.value,
    selected,
    winners: winners.value,
  });
}

export async function loadCoachDirectoryOperation() {
  const profile = await loadVerifiedProfile();
  if (!profile.isSuccess) return profile;
  if (profile.value.role !== "participant" && profile.value.role !== "coach") {
    return failure(new AppError("forbidden", "Daftar ini hanya tersedia untuk Peserta."));
  }
  return repository.listCoaches();
}
