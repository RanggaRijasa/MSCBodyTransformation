import "server-only";

import { AppError } from "@/domain/errors/app-error";
import { failure, success } from "@/domain/result";
import { getVerifiedSupabaseContext } from "@/infrastructure/supabase/auth/get-verified-actor";

const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const idempotencyPattern = /^[A-Za-z0-9][A-Za-z0-9._:-]{15,127}$/;
const scoreColumns = "activity_points,quiz_points,weight_points,adjustment_points";

function totalPoints(
  score: Readonly<{
    activity_points: number;
    adjustment_points: number;
    quiz_points: number;
    weight_points: number;
  }> | null,
) {
  return score
    ? score.activity_points + score.quiz_points + score.weight_points + score.adjustment_points
    : null;
}

function operationError(error: unknown) {
  const message =
    error && typeof error === "object" && "message" in error ? String(error.message) : "";
  if (/entitlement_inactive|permission|forbidden/i.test(message))
    return new AppError("forbidden", "Akses Coach tidak tersedia.", { cause: error });
  if (/already_reviewed|idempotency|duplicate/i.test(message))
    return new AppError("conflict", "Pemeriksaan ini sudah diproses. Muat ulang antrean.", {
      cause: error,
    });
  if (/reason_required|not_reviewable|invalid/i.test(message))
    return new AppError(
      "validation_failed",
      "Keputusan pemeriksaan belum lengkap atau sudah basi.",
      { cause: error },
    );
  return new AppError("unknown", "Tindakan Coach belum dapat disimpan.", { cause: error });
}

export async function reviewCoachSubmissionOperation(
  input: Readonly<{
    decision: "approved" | "rejected";
    idempotencyKey: string;
    reason?: string;
    submissionId: string;
  }>,
) {
  if (
    !uuidPattern.test(input.submissionId) ||
    !idempotencyPattern.test(input.idempotencyKey) ||
    (input.decision === "rejected" && !input.reason?.trim())
  )
    return failure(new AppError("validation_failed", "Keputusan pemeriksaan belum lengkap."));
  const context = await getVerifiedSupabaseContext();
  if (!context.isSuccess) return context;
  const before = await context.value.supabase
    .from("step_submissions")
    .select("enrollment_id")
    .eq("id", input.submissionId)
    .single();
  if (before.error) return failure(operationError(before.error));
  const scoreBefore = await context.value.supabase
    .from("program_scores")
    .select(scoreColumns)
    .eq("enrollment_id", before.data.enrollment_id)
    .single();
  const { data, error } = await context.value.supabase.rpc("review_step_submission", {
    request_idempotency_key: input.idempotencyKey,
    review_decision: input.decision,
    review_reason: input.reason?.trim() || null,
    target_submission_id: input.submissionId,
  });
  if (error) return failure(operationError(error));
  const scoreAfter = await context.value.supabase
    .from("program_scores")
    .select(scoreColumns)
    .eq("enrollment_id", before.data.enrollment_id)
    .single();
  return data && typeof data.id === "string"
    ? success({
        pointsAfter: totalPoints(scoreAfter.data),
        pointsBefore: totalPoints(scoreBefore.data),
        status: data.status,
      })
    : failure(new AppError("validation_failed", "Hasil pemeriksaan server tidak valid."));
}

export async function updateCoachProfileOperation(
  input: Readonly<{
    biography: string;
    city: string;
    displayName: string;
    isPublic: boolean;
  }>,
) {
  const displayName = input.displayName.trim();
  const biography = input.biography.trim();
  const city = input.city.trim();
  if (
    displayName.length < 2 ||
    displayName.length > 80 ||
    biography.length > 500 ||
    city.length > 80
  )
    return failure(new AppError("validation_failed", "Periksa kembali nama, bio, dan kota."));
  const context = await getVerifiedSupabaseContext();
  if (!context.isSuccess) return context;
  const { data, error } = await context.value.supabase.rpc("update_coach_profile", {
    new_biography: biography,
    new_city: city,
    new_display_name: displayName,
    new_is_public: input.isPublic,
    reason: null,
    target_coach_user_id: context.value.actor.userId,
  });
  return error
    ? failure(operationError(error))
    : data && typeof data.user_id === "string"
      ? success({ displayName: data.display_name })
      : failure(new AppError("validation_failed", "Hasil profil server tidak valid."));
}

export async function downloadCoachQuestionPhotoOperation(
  submissionId: string,
  questionId: string,
) {
  if (!uuidPattern.test(submissionId) || !uuidPattern.test(questionId))
    return failure(new AppError("validation_failed", "Foto jawaban tidak valid."));
  const context = await getVerifiedSupabaseContext();
  if (!context.isSuccess) return context;
  const answer = await context.value.supabase
    .from("step_submission_answers")
    .select("private_photo_path")
    .eq("submission_id", submissionId)
    .eq("question_id", questionId)
    .single();
  if (answer.error || !answer.data.private_photo_path)
    return failure(new AppError("forbidden", "Foto jawaban tidak tersedia untuk Coach ini."));
  const downloaded = await context.value.supabase.storage
    .from("question-photos")
    .download(answer.data.private_photo_path);
  return downloaded.error
    ? failure(operationError(downloaded.error))
    : success(new Uint8Array(await downloaded.data.arrayBuffer()));
}
