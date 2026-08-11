import "server-only";

import { coachActivityStart, filterAndSortCoachRoster } from "@/domain/services/coach-experience";
import { success } from "@/domain/result";
import {
  listCoachRosterRepository,
  loadCoachContextRepository,
  loadCoachParticipantDetailRepository,
} from "@/infrastructure/supabase/coach/supabase-coach-repository";
import {
  listCoachActivityRepository,
  listCoachReviewsRepository,
} from "@/infrastructure/supabase/coach/supabase-coach-feed-repository";
import { supabaseParticipantExperienceRepository } from "@/infrastructure/supabase/programs/supabase-participant-repository";
import { supabasePublicProgramRepository } from "@/infrastructure/supabase/programs/supabase-program-repositories";

export const loadCoachContextOperation = loadCoachContextRepository;

export async function loadCoachDashboardOperation() {
  const context = await loadCoachContextRepository();
  if (!context.isSuccess || context.value.accessState !== "active")
    return context.isSuccess
      ? success({
          activity: [],
          context: context.value,
          leaderboard: [],
          programs: [],
          reviews: [],
          roster: [],
        })
      : context;
  const [roster, reviews, activity, programs] = await Promise.all([
    listCoachRosterRepository(),
    listCoachReviewsRepository(),
    listCoachActivityRepository(),
    supabasePublicProgramRepository.list(),
  ]);
  if (!roster.isSuccess) return roster;
  if (!reviews.isSuccess) return reviews;
  if (!activity.isSuccess) return activity;
  if (!programs.isSuccess) return programs;
  const associatedProgramIds = new Set(
    roster.value.flatMap(({ programId }) => (programId ? [programId] : [])),
  );
  const associatedPrograms = programs.value.filter(({ id }) => associatedProgramIds.has(id));
  const leaderboard = associatedPrograms[0]
    ? await supabaseParticipantExperienceRepository.listLeaderboard(associatedPrograms[0].id, 5)
    : success([]);
  if (!leaderboard.isSuccess) return leaderboard;
  return success({
    activity: activity.value.slice(0, 6),
    context: context.value,
    leaderboard: leaderboard.value,
    programs: associatedPrograms,
    reviews: reviews.value,
    roster: roster.value,
  });
}

export async function loadCoachRosterOperation(
  input: Readonly<{
    attention?: string | undefined;
    programId?: string | undefined;
    query?: string | undefined;
    sort?: string | undefined;
  }>,
) {
  const context = await loadCoachContextRepository();
  if (!context.isSuccess) return context;
  if (context.value.accessState !== "active")
    return success({ context: context.value, entries: [], programs: [] });
  const [roster, programs] = await Promise.all([
    listCoachRosterRepository(),
    supabasePublicProgramRepository.list(),
  ]);
  if (!roster.isSuccess) return roster;
  if (!programs.isSuccess) return programs;
  return success({
    context: context.value,
    entries: filterAndSortCoachRoster(roster.value, input),
    programs: programs.value.filter(({ id }) =>
      roster.value.some(({ programId }) => programId === id),
    ),
  });
}

export async function loadCoachParticipantDetailOperation(
  participantId: string,
  programId?: string,
) {
  return loadCoachParticipantDetailRepository(participantId, programId);
}

export async function loadCoachReviewsOperation(
  input: Readonly<{
    contentKind?: string | undefined;
    programId?: string | undefined;
    submittedSince?: string | undefined;
  }>,
) {
  const context = await loadCoachContextRepository();
  if (!context.isSuccess) return context;
  if (context.value.accessState !== "active")
    return success({ context: context.value, items: [], programs: [] });
  const [reviews, programs] = await Promise.all([
    listCoachReviewsRepository(),
    supabasePublicProgramRepository.list(),
  ]);
  if (!reviews.isSuccess) return reviews;
  if (!programs.isSuccess) return programs;
  return success({
    context: context.value,
    items: reviews.value.filter(
      (item) =>
        (!input.programId || item.programId === input.programId) &&
        (!input.contentKind || item.contentKind === input.contentKind) &&
        (!input.submittedSince || item.submittedAt >= input.submittedSince),
    ),
    programs: programs.value.filter(({ id }) =>
      reviews.value.some(({ programId }) => programId === id),
    ),
  });
}

export async function loadCoachProgramHubOperation(
  input: Readonly<{
    programId?: string | undefined;
    range?: string | undefined;
  }>,
) {
  const context = await loadCoachContextRepository();
  if (!context.isSuccess) return context;
  if (context.value.accessState !== "active")
    return success({
      activity: [],
      assignedPublicProfileIds: new Set<string>(),
      context: context.value,
      leaderboard: [],
      programs: [],
      range: "1" as const,
      selectedProgram: null,
      winners: [],
    });
  const [roster, programs] = await Promise.all([
    listCoachRosterRepository(),
    supabasePublicProgramRepository.list(),
  ]);
  if (!roster.isSuccess) return roster;
  if (!programs.isSuccess) return programs;
  const associatedIds = new Set(
    roster.value.flatMap(({ programId }) => (programId ? [programId] : [])),
  );
  const associatedPrograms = programs.value.filter(({ id }) => associatedIds.has(id));
  const selectedProgram =
    associatedPrograms.find(({ id }) => id === input.programId) ?? associatedPrograms[0] ?? null;
  const range = input.range === "7" || input.range === "30" ? input.range : "1";
  const activity = await listCoachActivityRepository(selectedProgram?.id);
  if (!activity.isSuccess) return activity;
  const start = coachActivityStart(new Date(), range, selectedProgram?.timezone ?? "Asia/Jakarta");
  const filteredActivity = activity.value.filter(({ occurredAt }) => new Date(occurredAt) >= start);
  const [leaderboard, winners] = selectedProgram
    ? await Promise.all([
        supabaseParticipantExperienceRepository.listLeaderboard(selectedProgram.id),
        supabaseParticipantExperienceRepository.listWinners(selectedProgram.id),
      ])
    : [success([]), success([])];
  if (!leaderboard.isSuccess) return leaderboard;
  if (!winners.isSuccess) return winners;
  return success({
    activity: filteredActivity,
    assignedPublicProfileIds: new Set(roster.value.map(({ publicProfileId }) => publicProfileId)),
    context: context.value,
    leaderboard: leaderboard.value,
    programs: associatedPrograms,
    range,
    selectedProgram,
    winners: winners.value,
  });
}
