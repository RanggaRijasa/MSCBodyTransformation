import "server-only";

import type {
  CoachActivityItem,
  CoachPrivateAnswer,
  CoachReviewItem,
} from "@/domain/coach/coach-experience";
import { AppError } from "@/domain/errors/app-error";
import { failure, success } from "@/domain/result";
import { getVerifiedSupabaseContext } from "@/infrastructure/supabase/auth/get-verified-actor";
import {
  listCoachRosterRepository,
  loadCoachContextRepository,
} from "@/infrastructure/supabase/coach/supabase-coach-repository";
import { supabasePublicProgramRepository } from "@/infrastructure/supabase/programs/supabase-program-repositories";

type Row = Record<string, unknown>;
const row = (value: unknown): Row | null =>
  value !== null && typeof value === "object" && !Array.isArray(value) ? (value as Row) : null;
const string = (value: unknown) => (typeof value === "string" && value ? value : null);
const rows = (value: unknown) => (Array.isArray(value) ? value : []);

function error(message: string, cause?: unknown) {
  return new AppError("unknown", message, { cause });
}

async function activeContext() {
  const context = await loadCoachContextRepository();
  if (!context.isSuccess) return context;
  return context.value.accessState === "active"
    ? getVerifiedSupabaseContext()
    : failure(new AppError("forbidden", "Akses Coach belum aktif atau sudah berakhir."));
}

function mapAnswer(
  value: unknown,
  questions: readonly { id: string }[],
  answerKeys: readonly Row[],
): CoachPrivateAnswer | null {
  const answer = row(value);
  const questionId = string(answer?.question_id);
  if (!questionId) return null;
  const key = answerKeys.find((candidate) => candidate.question_id === questionId);
  return {
    answerKey: key
      ? {
          acceptedTextValues: Array.isArray(key.accepted_text_values)
            ? key.accepted_text_values.filter(
                (accepted): accepted is string => typeof accepted === "string",
              )
            : [],
          matchingMode: string(key.matching_mode) ?? "exact",
          numberValue:
            typeof key.number_value === "number" || typeof key.number_value === "string"
              ? String(key.number_value)
              : null,
          selectedOptionIds: Array.isArray(key.selected_option_ids)
            ? key.selected_option_ids.filter((id): id is string => typeof id === "string")
            : [],
        }
      : null,
    hasPhoto: Boolean(string(answer?.private_photo_path)),
    numberValue:
      typeof answer?.number_value === "number" || typeof answer?.number_value === "string"
        ? String(answer.number_value)
        : null,
    question:
      (questions.find(({ id }) => id === questionId) as CoachPrivateAnswer["question"]) ?? null,
    questionId,
    selectedOptionIds: Array.isArray(answer?.selected_option_ids)
      ? answer.selected_option_ids.filter((id): id is string => typeof id === "string")
      : [],
    textValue: string(answer?.text_value),
  };
}

export async function listCoachReviewsRepository() {
  const verified = await activeContext();
  if (!verified.isSuccess) return verified;
  const { data, error: providerError } =
    await verified.value.supabase.rpc("list_my_pending_reviews");
  if (providerError)
    return failure(error("Antrean pemeriksaan belum dapat dimuat.", providerError));
  const programs = await supabasePublicProgramRepository.list();
  if (!programs.isSuccess) return programs;
  const values = rows(data);
  const questionIds = [
    ...new Set(
      values.flatMap((value) =>
        rows(row(value)?.answers).flatMap((answer) => {
          const id = string(row(answer)?.question_id);
          return id ? [id] : [];
        }),
      ),
    ),
  ];
  const keyResult = questionIds.length
    ? await verified.value.supabase
        .from("program_answer_keys")
        .select("question_id,accepted_text_values,number_value,selected_option_ids,matching_mode")
        .in("question_id", questionIds)
    : { data: [], error: null };
  if (keyResult.error)
    return failure(error("Kunci jawaban pemeriksaan belum dapat dimuat.", keyResult.error));
  const answerKeys = (keyResult.data ?? []).map((key) => key as Row);
  const result: CoachReviewItem[] = [];
  for (const value of values) {
    const item = row(value);
    const submission = row(item?.submission);
    const participant = row(item?.participant);
    const programRow = row(item?.program);
    const stepRow = row(item?.step);
    const submissionId = string(submission?.id);
    const participantId = string(participant?.user_id);
    const participantName = string(participant?.display_name);
    const programId = string(programRow?.id);
    const programTitle = string(programRow?.title);
    const stepId = string(stepRow?.id);
    const stepTitle = string(stepRow?.title);
    const submittedAt = string(submission?.submitted_at);
    if (
      !submissionId ||
      !participantId ||
      !participantName ||
      !programId ||
      !programTitle ||
      !stepId ||
      !stepTitle ||
      !submittedAt
    )
      return failure(new AppError("validation_failed", "Data pemeriksaan Coach tidak valid."));
    const questions =
      programs.value
        .find(({ id }) => id === programId)
        ?.days.flatMap(({ steps }) => steps)
        .find(({ id }) => id === stepId)?.questions ?? [];
    result.push({
      answers: rows(item?.answers)
        .map((answer) => mapAnswer(answer, questions, answerKeys))
        .filter((answer): answer is CoachPrivateAnswer => Boolean(answer)),
      contentKind: string(stepRow?.content_kind) ?? "form",
      participantId,
      participantName,
      programId,
      programTitle,
      stepId,
      stepTitle,
      submissionId,
      submittedAt,
    });
  }
  return success(result);
}

export async function listCoachActivityRepository(programId?: string) {
  const [roster, verified] = await Promise.all([listCoachRosterRepository(), activeContext()]);
  if (!roster.isSuccess) return roster;
  if (!verified.isSuccess) return verified;
  const { actor, supabase } = verified.value;
  const enrollments = await supabase
    .from("program_enrollments")
    .select("id,participant_id,program_id,enrolled_at,completed_at")
    .eq("coach_id", actor.userId);
  if (enrollments.error)
    return failure(error("Aktivitas Coach belum dapat dimuat.", enrollments.error));
  const enrollmentRows = (enrollments.data ?? []).filter(
    (entry) => !programId || entry.program_id === programId,
  );
  const [programs, submissions] = await Promise.all([
    supabasePublicProgramRepository.list(),
    enrollmentRows.length
      ? supabase
          .from("step_submissions")
          .select("id,enrollment_id,step_id,status,submitted_at")
          .in(
            "enrollment_id",
            enrollmentRows.map(({ id }) => id),
          )
          .not("submitted_at", "is", null)
      : Promise.resolve({ data: [], error: null }),
  ]);
  if (!programs.isSuccess || submissions.error)
    return failure(
      error(
        "Aktivitas Coach belum dapat dimuat.",
        !programs.isSuccess ? programs.error : submissions.error,
      ),
    );
  const items: CoachActivityItem[] = [];
  for (const enrollment of enrollmentRows) {
    const participant = roster.value.find(
      ({ participantId }) => participantId === enrollment.participant_id,
    );
    const program = programs.value.find(({ id }) => id === enrollment.program_id);
    if (!participant || !program) continue;
    items.push({
      id: `${enrollment.id}-joined`,
      kind: "participant_joined",
      occurredAt: enrollment.enrolled_at,
      participantId: participant.participantId,
      participantName: participant.displayName,
      points: null,
      programId: program.id,
      programTitle: program.title,
      stepTitle: null,
    });
    if (enrollment.completed_at)
      items.push({
        id: `${enrollment.id}-completed`,
        kind: "program_completed",
        occurredAt: enrollment.completed_at,
        participantId: participant.participantId,
        participantName: participant.displayName,
        points: null,
        programId: program.id,
        programTitle: program.title,
        stepTitle: null,
      });
    const steps = program.days.flatMap(({ steps }) => steps);
    for (const submission of (submissions.data ?? []).filter(
      ({ enrollment_id }) => enrollment_id === enrollment.id,
    )) {
      const step = steps.find(({ id }) => id === submission.step_id);
      items.push({
        id: submission.id,
        kind:
          submission.status === "pending"
            ? "submission_pending"
            : submission.status === "rejected"
              ? "submission_rejected"
              : "step_completed",
        occurredAt: submission.submitted_at!,
        participantId: participant.participantId,
        participantName: participant.displayName,
        points:
          submission.status === "approved" && step && step.contentKind !== "quiz"
            ? program.pointsPerActivity
            : null,
        programId: program.id,
        programTitle: program.title,
        stepTitle: step?.title ?? null,
      });
    }
  }
  return success(items.toSorted((left, right) => right.occurredAt.localeCompare(left.occurredAt)));
}
