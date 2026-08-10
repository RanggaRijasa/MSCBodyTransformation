import "server-only";

import { AppError } from "@/domain/errors/app-error";
import type {
  AdminProgramDay,
  AdminProgramDraft,
  AdminProgramListItem,
  AdminProgramQuestion,
  AdminProgramStatus,
  AdminProgramStep,
} from "@/domain/admin/admin-program";
import { serializeProgramDraft, validateProgramDraft } from "@/domain/admin/admin-program";
import { failure, success, type Result } from "@/domain/result";
import { getVerifiedSupabaseContext } from "@/infrastructure/supabase/auth/get-verified-actor";

type Row = Record<string, unknown>;
const programStatuses = new Set(["active", "archived", "completed", "draft", "scheduled"]);

function record(value: unknown): Row {
  return value && typeof value === "object" && !Array.isArray(value) ? (value as Row) : {};
}
function text(value: unknown, fallback = "") {
  return typeof value === "string" ? value : fallback;
}
function nullableText(value: unknown) {
  return typeof value === "string" && value.length > 0 ? value : null;
}
function numberValue(value: unknown, fallback = 0) {
  return typeof value === "number" && Number.isFinite(value) ? value : fallback;
}
function adminError(cause: unknown, message: string) {
  return new AppError("unknown", message, { cause });
}

function parseQuestions(raw: unknown): AdminProgramQuestion[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .map(record)
    .map((question) => {
      const key = record(
        Array.isArray(question.program_answer_keys)
          ? question.program_answer_keys[0]
          : question.program_answer_keys,
      );
      return {
        answerKey: Object.keys(key).length
          ? {
              acceptedTextValues: Array.isArray(key.accepted_text_values)
                ? key.accepted_text_values.filter(
                    (value): value is string => typeof value === "string",
                  )
                : [],
              matchingMode: (key.matching_mode === "case_insensitive_text"
                ? "case_insensitive_text"
                : "exact") as "case_insensitive_text" | "exact",
              numberValue:
                key.number_value === null || key.number_value === undefined
                  ? null
                  : String(key.number_value),
              selectedOptionIds: Array.isArray(key.selected_option_ids)
                ? key.selected_option_ids.filter(
                    (value): value is string => typeof value === "string",
                  )
                : [],
            }
          : null,
        id: text(question.id),
        kind: text(question.kind, "text") as AdminProgramQuestion["kind"],
        options: (Array.isArray(question.program_question_options)
          ? question.program_question_options
          : []
        )
          .map(record)
          .map((option) => ({
            id: text(option.id),
            mediaAlternativeText: nullableText(option.media_alt_text),
            mediaPath: nullableText(option.media_path),
            order: numberValue(option.option_order),
            title: text(option.title),
          }))
          .sort((a, b) => a.order - b.order),
        order: numberValue(question.question_order),
        prompt: text(question.prompt),
      };
    })
    .sort((a, b) => a.order - b.order);
}

function parseSteps(raw: unknown): AdminProgramStep[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .map(record)
    .map((step) => ({
      completionPolicy: text(
        step.completion_policy,
        "mark_complete",
      ) as AdminProgramStep["completionPolicy"],
      contentKind: text(step.content_kind, "article") as AdminProgramStep["contentKind"],
      id: text(step.id),
      instructions: text(step.instructions),
      mediaAlternativeText: nullableText(step.media_alt_text),
      mediaPath: nullableText(step.media_path),
      order: numberValue(step.step_order),
      questions: parseQuestions(step.program_questions),
      title: text(step.title),
      verificationMode: text(
        step.verification_mode,
        "automatic",
      ) as AdminProgramStep["verificationMode"],
      videoAutoplay: step.video_autoplay === true,
      videoRequired: step.video_required === true,
      videoThreshold: typeof step.video_threshold === "number" ? step.video_threshold : null,
    }))
    .sort((a, b) => a.order - b.order);
}

function parseDays(raw: unknown): AdminProgramDay[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .map(record)
    .map((day) => ({
      dayNumber: numberValue(day.day_number),
      id: text(day.id),
      scheduledOn: text(day.scheduled_on),
      steps: parseSteps(day.program_steps),
      summary: nullableText(day.summary),
      title: text(day.title),
    }))
    .sort((a, b) => a.dayNumber - b.dayNumber);
}

function parseDraft(raw: unknown): AdminProgramDraft | null {
  const row = record(raw);
  const id = text(row.id);
  const status = text(row.status);
  if (!id || !programStatuses.has(status)) return null;
  return {
    category: nullableText(row.category),
    coverAlternativeText: nullableText(row.cover_alt_text),
    coverPath: nullableText(row.cover_path),
    days: parseDays(row.program_days),
    desiredPrice: row.desired_price == null ? null : String(row.desired_price),
    endsOn: text(row.ends_on),
    futureStepPolicy: text(
      row.future_step_policy,
      "locked",
    ) as AdminProgramDraft["futureStepPolicy"],
    id,
    participantLimit: typeof row.participant_limit === "number" ? row.participant_limit : null,
    pastStepPolicy: text(row.past_step_policy, "available") as AdminProgramDraft["pastStepPolicy"],
    pointsPerActivity: numberValue(row.points_per_activity),
    pointsPerWeightKilogram: String(row.points_per_weight_kg ?? "0"),
    pricingMode: row.pricing_mode === "paid" ? "paid" : "free",
    quizPassingPercentage: numberValue(row.quiz_passing_percentage, 70),
    registrationClosesAt: nullableText(row.registration_closes_at),
    startsOn: text(row.starts_on),
    status: status as AdminProgramStatus,
    summary: text(row.summary),
    timezone: text(row.timezone, "Asia/Makassar"),
    title: text(row.title),
    wellnessDisclaimer: text(row.wellness_disclaimer),
  };
}

export async function listAdminPrograms(): Promise<
  Result<readonly AdminProgramListItem[], AppError>
> {
  const verified = await getVerifiedSupabaseContext();
  if (!verified.isSuccess) return verified;
  const { data, error } = await verified.value.supabase
    .from("programs")
    .select(
      "id,title,status,starts_on,ends_on,participant_limit,pricing_mode,desired_price,program_enrollments(count)",
    )
    .order("starts_on", { ascending: false })
    .limit(100);
  if (error) return failure(adminError(error, "Daftar program belum dapat dimuat."));
  const items: AdminProgramListItem[] = [];
  for (const raw of data ?? []) {
    const row = record(raw);
    const status = text(row.status);
    const id = text(row.id);
    if (!id || !programStatuses.has(status)) continue;
    const enrollment = record(
      Array.isArray(row.program_enrollments) ? row.program_enrollments[0] : null,
    );
    items.push({
      desiredPrice: row.desired_price == null ? null : String(row.desired_price),
      endsOn: text(row.ends_on),
      enrollmentCount: numberValue(enrollment.count),
      id,
      participantLimit: typeof row.participant_limit === "number" ? row.participant_limit : null,
      pricingMode: row.pricing_mode === "paid" ? "paid" : "free",
      startsOn: text(row.starts_on),
      status: status as AdminProgramStatus,
      title: text(row.title),
    });
  }
  return success(items);
}

export async function loadAdminProgram(id: string): Promise<Result<AdminProgramDraft, AppError>> {
  const verified = await getVerifiedSupabaseContext();
  if (!verified.isSuccess) return verified;
  const select =
    "*,program_days(*,program_steps(*,program_questions(*,program_question_options(*),program_answer_keys(*))))";
  const { data, error } = await verified.value.supabase
    .from("programs")
    .select(select)
    .eq("id", id)
    .maybeSingle();
  if (error) return failure(adminError(error, "Program belum dapat dimuat."));
  const draft = parseDraft(data);
  return draft ? success(draft) : failure(new AppError("forbidden", "Program tidak ditemukan."));
}

export async function saveAdminProgram(draft: AdminProgramDraft, idempotencyKey: string) {
  const issues = validateProgramDraft(draft);
  if (issues.length) return failure(new AppError("validation_failed", issues[0]!.message));
  const verified = await getVerifiedSupabaseContext();
  if (!verified.isSuccess) return verified;
  const { error } = await verified.value.supabase.rpc("save_program_draft", {
    program_payload: serializeProgramDraft(draft),
    request_idempotency_key: idempotencyKey,
  });
  return error
    ? failure(adminError(error, "Draft belum dapat disimpan."))
    : loadAdminProgram(draft.id);
}

async function programRpc(name: string, parameters: Row, message: string) {
  const verified = await getVerifiedSupabaseContext();
  if (!verified.isSuccess) return verified;
  const { data, error } = await verified.value.supabase.rpc(name, parameters);
  return error ? failure(adminError(error, message)) : success(data);
}

export const publishAdminProgram = (id: string, key: string) =>
  programRpc(
    "publish_program",
    { target_program_id: id, request_idempotency_key: key },
    "Program belum dapat diterbitkan.",
  );
export const completeAdminProgram = (id: string, reason: string, key: string) =>
  programRpc(
    "complete_program",
    { target_program_id: id, reason, request_idempotency_key: key },
    "Program belum dapat diselesaikan.",
  );
export const archiveAdminProgram = (id: string, reason: string, key: string) =>
  programRpc(
    "archive_program",
    { target_program_id: id, reason, request_idempotency_key: key },
    "Program belum dapat diarsipkan.",
  );
export const reopenAdminProgram = (id: string, reason: string, key: string) =>
  programRpc(
    "reopen_program",
    { target_program_id: id, reason, request_idempotency_key: key },
    "Program belum dapat dibuka kembali.",
  );
export const lockAdminWinners = (id: string, key: string) =>
  programRpc(
    "lock_program_winners",
    { target_program_id: id, request_idempotency_key: key },
    "Pemenang belum dapat dikunci.",
  );
export const duplicateAdminProgram = (
  sourceId: string,
  targetId: string,
  title: string,
  startsOn: string,
  key: string,
) =>
  programRpc(
    "duplicate_program_as_draft",
    {
      source_target_id: sourceId,
      target_program_id: targetId,
      target_title: title,
      target_starts_on: startsOn,
      request_idempotency_key: key,
    },
    "Program belum dapat diduplikasi.",
  );
