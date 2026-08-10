import "server-only";

import type { AdminProgramClosure } from "@/domain/admin/admin-operations";
import { AppError } from "@/domain/errors/app-error";
import { failure, success, type Result } from "@/domain/result";
import { getVerifiedSupabaseContext } from "@/infrastructure/supabase/auth/get-verified-actor";

type UnknownRow = Record<string, unknown>;

function record(value: unknown): UnknownRow | null {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? (value as UnknownRow)
    : null;
}

function text(value: unknown) {
  return typeof value === "string" ? value : null;
}

function integer(value: unknown) {
  return typeof value === "number" && Number.isInteger(value) ? value : null;
}

export async function loadAdminProgramClosure(
  programId: string,
): Promise<Result<AdminProgramClosure, AppError>> {
  const verified = await getVerifiedSupabaseContext();
  if (!verified.isSuccess) return verified;
  const { data, error } = await verified.value.supabase.rpc("get_program_closure_preflight", {
    target_program_id: programId,
  });
  if (error) {
    return failure(
      new AppError("unknown", "Status penutupan belum dapat dimuat.", { cause: error }),
    );
  }
  const input = record(data);
  const parsedProgramId = text(input?.program_id);
  const status = text(input?.status);
  const pendingReviews = integer(input?.pending_reviews);
  const missingFinalWeights = integer(input?.missing_final_weights);
  const failedQuizAttempts = integer(input?.failed_quiz_attempts);
  const incompleteEnrollments = integer(input?.incomplete_enrollments);
  if (
    !parsedProgramId ||
    !status ||
    !["active", "archived", "completed", "draft", "scheduled"].includes(status) ||
    pendingReviews === null ||
    missingFinalWeights === null ||
    failedQuizAttempts === null ||
    incompleteEnrollments === null ||
    typeof input?.can_complete !== "boolean" ||
    typeof input.can_lock !== "boolean" ||
    typeof input.can_reopen !== "boolean"
  ) {
    return failure(new AppError("validation_failed", "Status penutupan tidak valid."));
  }
  const failedQuizzes: Array<AdminProgramClosure["failedQuizzes"][number]> = [];
  for (const candidate of Array.isArray(input.failed_quizzes) ? input.failed_quizzes : []) {
    const quiz = record(candidate);
    const enrollmentId = text(quiz?.enrollment_id);
    const stepId = text(quiz?.step_id);
    const participantDisplayName = text(quiz?.participant_display_name);
    const stepTitle = text(quiz?.step_title);
    const attemptSequence = integer(quiz?.attempt_sequence);
    const percentage = integer(quiz?.percentage);
    if (
      enrollmentId &&
      stepId &&
      participantDisplayName &&
      stepTitle &&
      attemptSequence !== null &&
      percentage !== null
    ) {
      failedQuizzes.push({
        attemptSequence,
        enrollmentId,
        participantDisplayName,
        percentage,
        stepId,
        stepTitle,
      });
    }
  }
  return success({
    canComplete: input.can_complete,
    canLock: input.can_lock,
    canReopen: input.can_reopen,
    failedQuizAttempts,
    failedQuizzes,
    incompleteEnrollments,
    missingFinalWeights,
    pendingReviews,
    programId: parsedProgramId,
    status: status as AdminProgramClosure["status"],
    winnerSnapshotId: text(input.winner_snapshot_id),
  });
}
