import "server-only";

import { AppError } from "@/domain/errors/app-error";
import type {
  ParticipantDayAccess,
  ParticipantProgram,
  ParticipantQuizResult,
  ParticipantScore,
  ParticipantSubmission,
  PublicCoach,
  PublicLeaderboardEntry,
  PublicWinner,
  PublicWinnerPoster,
} from "@/domain/participant/participant-program";
import type { ParticipantExperienceRepository } from "@/domain/repositories/program-repository";
import { failure, success } from "@/domain/result";
import { getVerifiedSupabaseContext } from "@/infrastructure/supabase/auth/get-verified-actor";
import { createSupabaseServerClient } from "@/infrastructure/supabase/client/server";
import { supabasePublicProgramRepository } from "@/infrastructure/supabase/programs/supabase-program-repositories";

type Row = Record<string, unknown>;

function row(value: unknown): Row | null {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? (value as Row)
    : null;
}

function string(value: unknown): string | null {
  return typeof value === "string" && value.length > 0 ? value : null;
}

function integer(value: unknown): number | null {
  return typeof value === "number" && Number.isInteger(value) ? value : null;
}

function programError(message: string, cause?: unknown) {
  return new AppError("unknown", message, { cause });
}

function parseAccess(value: unknown): ParticipantDayAccess | null {
  const input = row(value);
  const accessState = string(input?.access_state);
  const dayNumber = integer(input?.day_number);
  const enrollmentId = string(input?.enrollment_id);
  const programDayId = string(input?.program_day_id);
  const programId = string(input?.program_id);
  if (
    !input ||
    !enrollmentId ||
    !programDayId ||
    !programId ||
    dayNumber === null ||
    !["available", "hidden", "locked", "read_only"].includes(accessState ?? "") ||
    typeof input.is_current_day !== "boolean"
  ) {
    return null;
  }
  return {
    accessState: accessState as ParticipantDayAccess["accessState"],
    dayNumber,
    enrollmentId,
    isCurrentDay: input.is_current_day,
    programDayId,
    programId,
  };
}

function parseSubmission(value: unknown): ParticipantSubmission | null {
  const input = row(value);
  const id = string(input?.id);
  const stepId = string(input?.step_id);
  const status = string(input?.status);
  const sequence = integer(input?.attempt_sequence);
  const submittedAt = string(input?.submitted_at);
  const reviewNote = input?.review_note;
  if (
    !input ||
    !id ||
    !stepId ||
    !submittedAt ||
    sequence === null ||
    !["draft", "pending", "approved", "rejected"].includes(status ?? "") ||
    (reviewNote !== null && typeof reviewNote !== "string")
  ) {
    return null;
  }
  return {
    attemptSequence: sequence,
    id,
    reviewNote: reviewNote as string | null,
    status: status as ParticipantSubmission["status"],
    stepId,
    submittedAt,
  };
}

function parseScore(value: unknown): ParticipantScore | null {
  const input = row(value);
  const activity = integer(input?.activity_points);
  const adjustment = integer(input?.adjustment_points);
  const progress = integer(input?.progress_percentage);
  const quiz = integer(input?.quiz_points);
  const rank = input?.rank === null ? null : integer(input?.rank);
  const weight = integer(input?.weight_points);
  if (
    !input ||
    activity === null ||
    adjustment === null ||
    progress === null ||
    quiz === null ||
    (rank === null && input.rank !== null) ||
    weight === null
  ) {
    return null;
  }
  return {
    activityPoints: activity,
    adjustmentPoints: adjustment,
    progressPercentage: progress,
    quizPoints: quiz,
    rank,
    totalPoints: activity + adjustment + quiz + weight,
    weightPoints: weight,
  };
}

function parseQuizResult(value: unknown): ParticipantQuizResult | null {
  const input = row(value);
  const submissionId = string(input?.submission_id);
  const correct = integer(input?.correct_count);
  const total = integer(input?.total_count);
  const percentage = integer(input?.percentage);
  const points = integer(input?.awarded_points);
  if (
    !input ||
    !submissionId ||
    correct === null ||
    total === null ||
    percentage === null ||
    points === null ||
    typeof input.passed !== "boolean"
  ) {
    return null;
  }
  return {
    awardedPoints: points,
    correctCount: correct,
    passed: input.passed,
    percentage,
    submissionId,
    totalCount: total,
  };
}

async function publicClient() {
  return createSupabaseServerClient();
}

async function loadPublicProfileId(client: Awaited<ReturnType<typeof publicClient>>) {
  const claims = await client.auth.getClaims();
  const subject = string(claims.data?.claims?.sub);
  if (!subject) return null;
  const { data } = await client
    .from("profiles")
    .select("public_profile_id")
    .eq("user_id", subject)
    .maybeSingle();
  return string(data?.public_profile_id);
}

export const supabaseParticipantExperienceRepository: ParticipantExperienceRepository = {
  async listMyPrograms() {
    const context = await getVerifiedSupabaseContext();
    if (!context.isSuccess) return context;
    const [programs, accessResult, enrollmentResult] = await Promise.all([
      supabasePublicProgramRepository.list(),
      context.value.supabase.rpc("list_my_program_day_access"),
      context.value.supabase
        .from("program_enrollments")
        .select("id,program_id,status")
        .eq("participant_id", context.value.actor.userId)
        .in("status", ["active", "completed"]),
    ]);
    if (!programs.isSuccess) return programs;
    if (accessResult.error || enrollmentResult.error) {
      return failure(
        programError(
          "Aktivitas program belum dapat dimuat.",
          accessResult.error ?? enrollmentResult.error,
        ),
      );
    }
    const enrollmentRows = enrollmentResult.data ?? [];
    const enrollmentIds = enrollmentRows.map(({ id }) => id);
    const [submissionResult, scoreResult, weighResult] = enrollmentIds.length
      ? await Promise.all([
          context.value.supabase
            .from("step_submissions")
            .select("id,enrollment_id,step_id,attempt_sequence,status,submitted_at,review_note")
            .in("enrollment_id", enrollmentIds),
          context.value.supabase
            .from("program_scores")
            .select(
              "enrollment_id,activity_points,quiz_points,weight_points,adjustment_points,progress_percentage,rank",
            )
            .in("enrollment_id", enrollmentIds),
          context.value.supabase
            .from("weigh_ins")
            .select("enrollment_id,step_id")
            .in("enrollment_id", enrollmentIds),
        ])
      : [
          { data: [], error: null },
          { data: [], error: null },
          { data: [], error: null },
        ];
    if (submissionResult.error || scoreResult.error || weighResult.error) {
      return failure(
        programError(
          "Progres program belum dapat dimuat.",
          submissionResult.error ?? scoreResult.error ?? weighResult.error,
        ),
      );
    }
    const submissions: Array<ParticipantSubmission | null> = (submissionResult.data ?? []).map(
      parseSubmission,
    );
    const access: Array<ParticipantDayAccess | null> = (accessResult.data ?? []).map(parseAccess);
    if (submissions.includes(null) || access.includes(null)) {
      return failure(new AppError("validation_failed", "Data aktivitas program tidak valid."));
    }
    const submissionIds = submissions.flatMap((submission) => (submission ? [submission.id] : []));
    const quizResult = submissionIds.length
      ? await context.value.supabase
          .from("quiz_attempt_results")
          .select("submission_id,correct_count,total_count,percentage,passed,awarded_points")
          .in("submission_id", submissionIds)
      : { data: [], error: null };
    if (quizResult.error) {
      return failure(programError("Hasil kuis belum dapat dimuat.", quizResult.error));
    }
    const quizResults = (quizResult.data ?? []).map(parseQuizResult);
    if (quizResults.includes(null)) {
      return failure(new AppError("validation_failed", "Data hasil kuis tidak valid."));
    }
    const result: ParticipantProgram[] = [];
    for (const enrollment of enrollmentRows) {
      const program = programs.value.find(({ id }) => id === enrollment.program_id);
      const score = parseScore(
        (scoreResult.data ?? []).find((candidate) => candidate.enrollment_id === enrollment.id),
      );
      if (
        !program ||
        typeof enrollment.id !== "string" ||
        (enrollment.status !== "active" && enrollment.status !== "completed") ||
        !score
      ) {
        return failure(new AppError("validation_failed", "Data program Peserta tidak valid."));
      }
      const enrollmentSubmissionIds = new Set(
        (submissionResult.data ?? [])
          .filter((raw) => raw.enrollment_id === enrollment.id)
          .map((raw) => raw.id),
      );
      result.push({
        access: access.filter(
          (item) => item?.enrollmentId === enrollment.id,
        ) as ParticipantDayAccess[],
        enrollmentId: enrollment.id,
        enrollmentStatus: enrollment.status,
        program,
        quizResults: quizResults.filter(
          (quiz) => quiz && enrollmentSubmissionIds.has(quiz.submissionId),
        ) as ParticipantQuizResult[],
        score,
        submissions: submissions.filter(
          (_submission, index) => submissionResult.data?.[index]?.enrollment_id === enrollment.id,
        ) as ParticipantSubmission[],
        weighedStepIds: (weighResult.data ?? [])
          .filter((weigh) => weigh.enrollment_id === enrollment.id)
          .flatMap((weigh) => (typeof weigh.step_id === "string" ? [weigh.step_id] : [])),
      });
    }
    return success(result);
  },

  async listCoaches() {
    try {
      const client = await publicClient();
      const [{ data, error }, assigned] = await Promise.all([
        client.rpc("list_public_coaches", { result_limit: 100, result_offset: 0 }),
        client.rpc("get_my_assigned_coach"),
      ]);
      if (error) return failure(programError("Daftar Coach belum dapat dimuat.", error));
      const assignedId = string(
        Array.isArray(assigned.data) ? assigned.data[0]?.public_profile_id : null,
      );
      const coaches: PublicCoach[] = [];
      for (const value of data ?? []) {
        const input = row(value);
        const id = string(input?.id);
        const displayName = string(input?.display_name);
        if (!id || !displayName) {
          return failure(new AppError("validation_failed", "Data Coach publik tidak valid."));
        }
        coaches.push({
          biography: typeof input?.biography === "string" ? input.biography : "",
          city: typeof input?.city === "string" ? input.city : null,
          displayName,
          id,
          isAssigned: id === assignedId,
          photoUrl: typeof input?.photo_reference === "string" ? input.photo_reference : null,
        });
      }
      return success(coaches);
    } catch (error) {
      return failure(programError("Daftar Coach belum dapat dimuat.", error));
    }
  },

  async listLeaderboard(programId, limit = 100, offset = 0) {
    try {
      const client = await publicClient();
      const [{ data, error }, publicProfileId] = await Promise.all([
        client.rpc("list_public_leaderboard", {
          result_limit: limit,
          result_offset: offset,
          target_program_id: programId,
        }),
        loadPublicProfileId(client),
      ]);
      if (error) return failure(programError("Papan peringkat belum dapat dimuat.", error));
      const entries: PublicLeaderboardEntry[] = [];
      for (const value of data ?? []) {
        const input = row(value);
        const id = string(input?.id);
        const participantId = string(input?.participant_id);
        const participantDisplayName = string(input?.participant_display_name);
        const rank = integer(input?.rank);
        const progress = integer(input?.progress_percentage);
        const points = integer(input?.total_points);
        if (
          !id ||
          !participantId ||
          !participantDisplayName ||
          rank === null ||
          progress === null ||
          points === null
        ) {
          return failure(new AppError("validation_failed", "Data papan peringkat tidak valid."));
        }
        entries.push({
          id,
          isCurrentParticipant: participantId === publicProfileId,
          participantDisplayName,
          participantId,
          programId,
          progressPercentage: progress,
          rank,
          totalPoints: points,
        });
      }
      return success(entries);
    } catch (error) {
      return failure(programError("Papan peringkat belum dapat dimuat.", error));
    }
  },

  async listWinners(programId) {
    try {
      const client = await publicClient();
      const { data, error } = await client.rpc("list_public_winners", {
        result_limit: 5,
        result_offset: 0,
        target_program_id: programId,
      });
      if (error) return failure(programError("Daftar pemenang belum dapat dimuat.", error));
      const winners: PublicWinner[] = [];
      for (const value of data ?? []) {
        const input = row(value);
        const id = string(input?.id);
        const participantId = string(input?.participant_id);
        const name = string(input?.participant_display_name);
        const lockedAt = string(input?.locked_at);
        const rank = integer(input?.rank);
        const points = integer(input?.total_points);
        if (!id || !participantId || !name || !lockedAt || rank === null || points === null) {
          return failure(new AppError("validation_failed", "Data pemenang tidak valid."));
        }
        winners.push({
          id,
          lockedAt,
          participantDisplayName: name,
          participantId,
          programId,
          rank,
          totalPoints: points,
        });
      }
      return success(winners);
    } catch (error) {
      return failure(programError("Daftar pemenang belum dapat dimuat.", error));
    }
  },

  async listWinnerPosters() {
    try {
      const client = await publicClient();
      const { data, error } = await client.rpc("list_public_winner_posters", {
        result_limit: 20,
        result_offset: 0,
      });
      if (error) return failure(programError("Poster pemenang belum dapat dimuat.", error));
      const posters: PublicWinnerPoster[] = [];
      for (const value of data ?? []) {
        const input = row(value);
        const id = string(input?.id);
        const programId = string(input?.program_id);
        const title = string(input?.title);
        const alternativeText = string(input?.body);
        const path = string(input?.media_reference);
        if (
          !id ||
          !programId ||
          !title ||
          !alternativeText ||
          !path ||
          path.includes("..") ||
          path.includes("://")
        ) {
          return failure(new AppError("validation_failed", "Data poster pemenang tidak valid."));
        }
        posters.push({
          alternativeText,
          id,
          imageUrl: client.storage.from("public-media").getPublicUrl(path).data.publicUrl,
          programId,
          title,
        });
      }
      return success(posters);
    } catch (error) {
      return failure(programError("Poster pemenang belum dapat dimuat.", error));
    }
  },
};
