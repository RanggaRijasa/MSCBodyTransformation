import "server-only";

import { randomUUID } from "node:crypto";

import { sanitizeServerImageUpload } from "@/application/media/server-image-validation";
import { AppError } from "@/domain/errors/app-error";
import type { ParticipantAnswerInput } from "@/domain/participant/participant-answer-input";
import { canonicalIndonesianWeight } from "@/domain/services/participant-program";
import { failure, success } from "@/domain/result";
import { getVerifiedSupabaseContext } from "@/infrastructure/supabase/auth/get-verified-actor";
import { createSupabaseServiceClient } from "@/infrastructure/supabase/client/service";
import { consumeAuthenticatedRateLimit } from "@/application/security/authenticated-rate-limit";

const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const idempotencyPattern = /^[A-Za-z0-9][A-Za-z0-9._:-]{15,127}$/;

function mutationError(error: unknown): AppError {
  const message =
    error && typeof error === "object" && "message" in error && typeof error.message === "string"
      ? error.message
      : "";
  if (/permission|forbidden|unavailable|not_found/i.test(message)) {
    return new AppError("forbidden", "Langkah ini tidak tersedia untuk akunmu.", { cause: error });
  }
  if (/already|duplicate|idempotency|unique/i.test(message)) {
    return new AppError(
      "conflict",
      "Aktivitas ini sudah diproses. Muat ulang untuk melihat status terbaru.",
      { cause: error },
    );
  }
  if (/answer|photo|weight|invalid|required|mismatch/i.test(message)) {
    return new AppError("validation_failed", "Data aktivitas belum lengkap atau tidak valid.", {
      cause: error,
    });
  }
  return new AppError("unknown", "Aktivitas belum dapat disimpan.", { cause: error });
}

function validIdentifiers(...identifiers: readonly string[]) {
  return identifiers.every((identifier) => uuidPattern.test(identifier));
}

export async function prepareParticipantSubmissionOperation(
  input: Readonly<{
    enrollmentId: string;
    idempotencyKey: string;
    stepId: string;
  }>,
) {
  if (
    !validIdentifiers(input.enrollmentId, input.stepId) ||
    !idempotencyPattern.test(input.idempotencyKey)
  ) {
    return failure(new AppError("validation_failed", "Permintaan aktivitas tidak valid."));
  }
  const context = await getVerifiedSupabaseContext();
  if (!context.isSuccess) return context;
  const rateLimit = await consumeAuthenticatedRateLimit(
    context.value,
    "submission",
    input.enrollmentId,
  );
  if (!rateLimit.isSuccess) return rateLimit;
  const { data, error } = await context.value.supabase.rpc("prepare_step_submission", {
    request_idempotency_key: input.idempotencyKey,
    target_enrollment_id: input.enrollmentId,
    target_step_id: input.stepId,
  });
  if (error) return failure(mutationError(error));
  const submission = data as { id?: unknown; status?: unknown } | null;
  return submission && typeof submission.id === "string" && submission.status === "draft"
    ? success({ submissionId: submission.id })
    : failure(new AppError("validation_failed", "Draft aktivitas server tidak valid."));
}

export async function uploadParticipantQuestionPhotoOperation(
  input: Readonly<{
    bytes: Uint8Array;
    declaredMimeType: string;
    questionId: string;
    submissionId: string;
  }>,
) {
  if (!validIdentifiers(input.questionId, input.submissionId)) {
    return failure(new AppError("validation_failed", "Tujuan foto tidak valid."));
  }
  const sanitized = sanitizeServerImageUpload(input.bytes, input.declaredMimeType);
  if (!sanitized.isSuccess) return sanitized;
  const context = await getVerifiedSupabaseContext();
  if (!context.isSuccess) return context;
  const rateLimit = await consumeAuthenticatedRateLimit(
    context.value,
    "upload",
    input.submissionId,
  );
  if (!rateLimit.isSuccess) return rateLimit;
  const [submissionResult, questionResult] = await Promise.all([
    context.value.supabase
      .from("step_submissions")
      .select("id,enrollment_id,step_id,status")
      .eq("id", input.submissionId)
      .maybeSingle(),
    context.value.supabase
      .from("program_questions")
      .select("id,step_id,kind")
      .eq("id", input.questionId)
      .maybeSingle(),
  ]);
  if (
    submissionResult.error ||
    questionResult.error ||
    !submissionResult.data ||
    submissionResult.data.status !== "draft" ||
    !questionResult.data ||
    questionResult.data.kind !== "photo_upload" ||
    questionResult.data.step_id !== submissionResult.data.step_id
  ) {
    return failure(new AppError("forbidden", "Foto tidak dapat dipakai untuk aktivitas ini."));
  }
  const objectPath = [
    context.value.actor.userId,
    submissionResult.data.enrollment_id,
    input.submissionId,
    input.questionId,
    `${randomUUID()}.jpg`,
  ].join("/");
  let service;
  try {
    service = createSupabaseServiceClient();
  } catch (error) {
    return failure(error instanceof AppError ? error : mutationError(error));
  }
  const { error } = await service.storage
    .from("question-photos")
    .upload(objectPath, sanitized.value.bytes, {
      cacheControl: "0",
      contentType: "image/jpeg",
      upsert: false,
    });
  return error ? failure(mutationError(error)) : success({ privatePhotoPath: objectPath });
}

export async function submitParticipantAnswersOperation(
  input: Readonly<{
    answers: readonly ParticipantAnswerInput[];
    idempotencyKey: string;
    submissionId: string;
  }>,
) {
  if (!validIdentifiers(input.submissionId) || !idempotencyPattern.test(input.idempotencyKey)) {
    return failure(new AppError("validation_failed", "Permintaan aktivitas tidak valid."));
  }
  const context = await getVerifiedSupabaseContext();
  if (!context.isSuccess) return context;
  const rateLimit = await consumeAuthenticatedRateLimit(
    context.value,
    "submission",
    input.submissionId,
  );
  if (!rateLimit.isSuccess) return rateLimit;
  const answers = input.answers.map((answer) => ({
    number_value: answer.numberValue ?? null,
    private_photo_path: answer.privatePhotoPath ?? null,
    question_id: answer.questionId,
    selected_option_ids: answer.selectedOptionIds ?? [],
    text_value: answer.textValue ?? null,
  }));
  const { data, error } = await context.value.supabase.rpc("submit_step_answers", {
    request_idempotency_key: input.idempotencyKey,
    submitted_answers: answers,
    target_submission_id: input.submissionId,
  });
  if (error) return failure(mutationError(error));
  const submission = data as { id?: unknown; status?: unknown } | null;
  if (
    !submission ||
    typeof submission.id !== "string" ||
    !["pending", "approved", "rejected"].includes(String(submission.status))
  ) {
    return failure(new AppError("validation_failed", "Status aktivitas server tidak valid."));
  }
  const { data: quiz } = await context.value.supabase
    .from("quiz_attempt_results")
    .select("correct_count,total_count,percentage,passed,awarded_points")
    .eq("submission_id", submission.id)
    .maybeSingle();
  return success({
    quizResult:
      quiz && typeof quiz.percentage === "number"
        ? {
            awardedPoints: quiz.awarded_points,
            correctCount: quiz.correct_count,
            passed: quiz.passed,
            percentage: quiz.percentage,
            totalCount: quiz.total_count,
          }
        : null,
    status: submission.status as "approved" | "pending" | "rejected",
  });
}

export async function submitParticipantWeighInOperation(
  input: Readonly<{
    enrollmentId: string;
    idempotencyKey: string;
    kind: "daily" | "final" | "initial";
    stepId: string;
    weight: string;
  }>,
) {
  if (
    !validIdentifiers(input.enrollmentId, input.stepId) ||
    !idempotencyPattern.test(input.idempotencyKey)
  ) {
    return failure(new AppError("validation_failed", "Permintaan pencatatan tidak valid."));
  }
  const weight = canonicalIndonesianWeight(input.weight);
  if (!weight.isSuccess) return weight;
  const context = await getVerifiedSupabaseContext();
  if (!context.isSuccess) return context;
  const rateLimit = await consumeAuthenticatedRateLimit(
    context.value,
    "submission",
    input.enrollmentId,
  );
  if (!rateLimit.isSuccess) return rateLimit;
  const { data, error } = await context.value.supabase.rpc("submit_weigh_in", {
    request_idempotency_key: input.idempotencyKey,
    target_enrollment_id: input.enrollmentId,
    target_step_id: input.stepId,
    weigh_in_kind: input.kind,
    weight_kg: weight.value,
  });
  if (error) return failure(mutationError(error));
  return data && typeof data.id === "string"
    ? success({ status: "approved" as const })
    : failure(new AppError("validation_failed", "Status pencatatan server tidak valid."));
}
