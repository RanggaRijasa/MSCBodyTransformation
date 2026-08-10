"use server";

import { randomUUID } from "node:crypto";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import {
  archiveAdminProgram,
  completeAdminProgram,
  duplicateAdminProgram,
  lockAdminWinners,
  publishAdminProgram,
  reopenAdminProgram,
  saveAdminProgram,
} from "@/infrastructure/supabase/admin/admin-program-repository";
import type { AdminProgramDraft } from "@/domain/admin/admin-program";
import { getVerifiedSupabaseContext } from "@/infrastructure/supabase/auth/get-verified-actor";

function required(form: FormData, name: string) {
  const value = form.get(name);
  return typeof value === "string" ? value.trim() : "";
}

function operationKey(prefix: string) {
  return `${prefix}-${randomUUID()}`;
}

async function runProgramLifecycle(
  form: FormData,
  operation: "archive" | "complete" | "lock" | "publish",
) {
  const id = required(form, "programId");
  const reason = required(form, "reason");
  if (!id) return;
  if (operation === "publish") await publishAdminProgram(id, operationKey("publish"));
  if (operation === "complete") await completeAdminProgram(id, reason, operationKey("complete"));
  if (operation === "lock") await lockAdminWinners(id, operationKey("winners"));
  if (operation === "archive") await archiveAdminProgram(id, reason, operationKey("archive"));
  revalidatePath("/admin");
  revalidatePath("/admin/program");
  revalidatePath(`/admin/program/${id}`);
}

export async function publishProgramAction(form: FormData) {
  await runProgramLifecycle(form, "publish");
}
export async function completeProgramAction(form: FormData) {
  await runProgramLifecycle(form, "complete");
}
export async function lockWinnersAction(form: FormData) {
  await runProgramLifecycle(form, "lock");
}
export async function archiveProgramAction(form: FormData) {
  await runProgramLifecycle(form, "archive");
}

export async function reopenProgramAction(form: FormData) {
  const id = required(form, "programId");
  const reason = required(form, "reason");
  if (!id || reason.length < 5) return;
  await reopenAdminProgram(id, reason, operationKey("reopen-program"));
  revalidatePath("/admin");
  revalidatePath("/admin/program");
  revalidatePath(`/admin/program/${id}`);
}

export async function reopenQuizAttemptAction(form: FormData) {
  const enrollmentId = required(form, "enrollmentId");
  const stepId = required(form, "stepId");
  const programId = required(form, "programId");
  const reason = required(form, "reason");
  if (!enrollmentId || !stepId || !programId || reason.length < 5) return;
  const context = await getVerifiedSupabaseContext();
  if (!context.isSuccess) return;
  await context.value.supabase.rpc("reopen_quiz_attempt", {
    reason,
    request_idempotency_key: operationKey("reopen-quiz"),
    target_enrollment_id: enrollmentId,
    target_step_id: stepId,
  });
  revalidatePath(`/admin/program/${programId}`);
}

export async function duplicateProgramAction(form: FormData) {
  const sourceId = required(form, "programId");
  const title = required(form, "title");
  const startsOn = required(form, "startsOn");
  if (!sourceId || !title || !startsOn) return;
  const targetId = randomUUID();
  const result = await duplicateAdminProgram(
    sourceId,
    targetId,
    title,
    startsOn,
    operationKey("duplicate"),
  );
  if (result.isSuccess) redirect(`/admin/program/${targetId}`);
}

export async function saveProgramDraftAction(form: FormData) {
  const serialized = required(form, "draft");
  if (!serialized || serialized.length > 1_000_000) return;
  let draft: AdminProgramDraft;
  try {
    draft = JSON.parse(serialized) as AdminProgramDraft;
  } catch {
    return;
  }
  if (
    !draft ||
    typeof draft.id !== "string" ||
    draft.status !== "draft" ||
    !Array.isArray(draft.days)
  )
    return;
  const result = await saveAdminProgram(draft, operationKey("draft"));
  if (result.isSuccess) {
    revalidatePath("/admin/program");
    redirect(`/admin/program/${draft.id}`);
  }
}

export async function decideCoachApplicationAction(form: FormData) {
  const applicationId = required(form, "applicationId");
  const decision = required(form, "decision");
  const reason = required(form, "reason");
  if (!applicationId || !["approved", "rejected"].includes(decision)) return;
  const context = await getVerifiedSupabaseContext();
  if (!context.isSuccess) return;
  await context.value.supabase.rpc("decide_coach_application", {
    decision,
    decision_reason: reason,
    request_idempotency_key: operationKey("coach-application"),
    target_application_id: applicationId,
  });
  revalidatePath("/admin/orang");
  revalidatePath("/admin");
}

export async function adjustScoreAction(form: FormData) {
  const enrollmentId = required(form, "enrollmentId");
  const reason = required(form, "reason");
  const points = Number(required(form, "points"));
  if (!enrollmentId || !reason || !Number.isInteger(points) || points === 0) return;
  const context = await getVerifiedSupabaseContext();
  if (!context.isSuccess) return;
  await context.value.supabase.rpc("admin_adjust_score", {
    points,
    reason,
    request_idempotency_key: operationKey("score"),
    target_enrollment_id: enrollmentId,
  });
  revalidatePath("/admin/orang");
}

export async function enrollParticipantAction(form: FormData) {
  const participantId = required(form, "participantId");
  const programId = required(form, "programId");
  const reason = required(form, "reason");
  if (!participantId || !programId || !reason) return;
  const context = await getVerifiedSupabaseContext();
  if (!context.isSuccess) return;
  await context.value.supabase.rpc("admin_enroll_participant", {
    reason,
    target_participant_id: participantId,
    target_program_id: programId,
  });
  revalidatePath("/admin/orang");
}

export async function transferCoachAction(form: FormData) {
  const participantId = required(form, "participantId");
  const coachId = required(form, "coachId");
  const reason = required(form, "reason");
  if (!participantId || !coachId || !reason) return;
  const context = await getVerifiedSupabaseContext();
  if (!context.isSuccess) return;
  await context.value.supabase.rpc("admin_transfer_coach", {
    reason,
    target_coach_id: coachId,
    target_participant_id: participantId,
  });
  revalidatePath("/admin/orang");
}

export async function correctWeighInAction(form: FormData) {
  const weighInId = required(form, "weighInId");
  const reason = required(form, "reason");
  const weight = Number(required(form, "weight"));
  if (!weighInId || !reason || weight < 20 || weight > 400) return;
  const context = await getVerifiedSupabaseContext();
  if (!context.isSuccess) return;
  await context.value.supabase.rpc("admin_correct_weigh_in", {
    corrected_weight_kg: weight,
    reason,
    request_idempotency_key: operationKey("weigh-in"),
    target_weigh_in_id: weighInId,
  });
  revalidatePath("/admin/orang");
}

export async function managePosterAction(form: FormData) {
  const operation = required(form, "operation");
  const posterId = required(form, "posterId") || randomUUID();
  const context = await getVerifiedSupabaseContext();
  if (!context.isSuccess || !["add", "replace", "publish", "delete"].includes(operation)) return;
  await context.value.supabase.rpc("manage_winner_poster", {
    operation,
    reason: required(form, "reason"),
    request_idempotency_key: operationKey("poster"),
    target_alt_text: required(form, "alternativeText"),
    target_media_path: required(form, "mediaPath"),
    target_poster_id: posterId,
    target_program_id: required(form, "programId") || null,
    target_snapshot_id: required(form, "snapshotId") || null,
  });
  revalidatePath("/admin/konten");
}

export async function createPaymentDestinationAction(form: FormData) {
  const context = await getVerifiedSupabaseContext();
  if (!context.isSuccess) return;
  const effectiveAt = required(form, "effectiveAt");
  await context.value.supabase.rpc("create_payment_destination", {
    destination_account_name: required(form, "accountName"),
    destination_account_reference: required(form, "accountReference"),
    destination_bank_code: required(form, "bankCode"),
    destination_bank_name: required(form, "bankName"),
    destination_qris_object_path: null,
    effective_at: effectiveAt ? new Date(effectiveAt).toISOString() : new Date().toISOString(),
  });
  revalidatePath("/admin/pembayaran");
}

export async function cancelPaymentOrderAction(form: FormData) {
  const orderId = required(form, "orderId");
  if (!orderId) return;
  const context = await getVerifiedSupabaseContext();
  if (!context.isSuccess) return;
  await context.value.supabase.rpc("cancel_payment_order", { target_order_id: orderId });
  revalidatePath(`/admin/pembayaran/${orderId}`);
  revalidatePath("/admin/pembayaran");
}

export async function recordExceptionalReversalAction(form: FormData) {
  const orderId = required(form, "orderId");
  const reference = required(form, "reference");
  const reason = required(form, "reason");
  if (!orderId || reference.length < 4 || reason.length < 5) return;
  const context = await getVerifiedSupabaseContext();
  if (!context.isSuccess) return;
  await context.value.supabase.rpc("record_exceptional_reversal", {
    mark_completed: form.get("completed") === "on",
    reconciliation_reference: reference,
    resolution_note: reason,
    target_order_id: orderId,
  });
  revalidatePath(`/admin/pembayaran/${orderId}`);
  revalidatePath("/admin/pembayaran");
}
