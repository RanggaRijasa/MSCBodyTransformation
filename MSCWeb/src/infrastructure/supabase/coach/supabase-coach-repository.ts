import "server-only";

import type {
  CoachContext,
  CoachParticipantDetail,
  CoachPrivateAnswer,
  CoachRosterEntry,
} from "@/domain/coach/coach-experience";
import { AppError } from "@/domain/errors/app-error";
import { coachAttentionState } from "@/domain/services/coach-experience";
import { failure, success } from "@/domain/result";
import { getVerifiedSupabaseContext } from "@/infrastructure/supabase/auth/get-verified-actor";
import { supabasePublicProgramRepository } from "@/infrastructure/supabase/programs/supabase-program-repositories";

type Row = Record<string, unknown>;
const asRow = (value: unknown): Row | null =>
  value !== null && typeof value === "object" && !Array.isArray(value) ? (value as Row) : null;
const asString = (value: unknown) => (typeof value === "string" && value ? value : null);
const asInteger = (value: unknown) =>
  typeof value === "number" && Number.isInteger(value) ? value : null;
const asRows = (value: unknown) => (Array.isArray(value) ? value : []);

function repositoryError(message: string, cause?: unknown) {
  const providerMessage =
    cause && typeof cause === "object" && "message" in cause ? String(cause.message) : "";
  if (/entitlement_inactive|permission|forbidden/i.test(providerMessage))
    return new AppError("forbidden", "Akses Coach belum aktif atau sudah berakhir.", { cause });
  return new AppError("unknown", message, { cause });
}

async function verifiedContext() {
  return getVerifiedSupabaseContext();
}

export async function loadCoachContextRepository() {
  const verified = await verifiedContext();
  if (!verified.isSuccess) return verified;
  const { actor, supabase } = verified.value;
  const [profileResult, applicationResult, entitlementResult] = await Promise.all([
    supabase
      .from("profiles")
      .select(
        "role,display_name,phone_number,provider_avatar_url,profile_avatar_path,coach_biography,city,coach_is_public",
      )
      .eq("user_id", actor.userId)
      .single(),
    supabase
      .from("coach_applications")
      .select("id,status,created_at")
      .eq("applicant_user_id", actor.userId)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle(),
    supabase
      .from("coach_access_entitlements")
      .select("status,starts_at,ends_at")
      .eq("coach_user_id", actor.userId)
      .order("ends_at", { ascending: false })
      .limit(1)
      .maybeSingle(),
  ]);
  if (profileResult.error || applicationResult.error || entitlementResult.error) {
    return failure(
      repositoryError(
        "Status Coach belum dapat dimuat.",
        profileResult.error ?? applicationResult.error ?? entitlementResult.error,
      ),
    );
  }
  const profile = profileResult.data;
  if (!profile || typeof profile.display_name !== "string")
    return failure(new AppError("validation_failed", "Data profil Coach tidak valid."));
  const application = applicationResult.data;
  const entitlement = entitlementResult.data;
  const now = Date.now();
  const isActive =
    profile.role === "coach" &&
    entitlement?.status === "active" &&
    Date.parse(entitlement.starts_at) <= now &&
    Date.parse(entitlement.ends_at) > now;
  const applicationStatus = application?.status ?? null;
  const accessState: CoachContext["accessState"] = isActive
    ? "active"
    : applicationStatus === "rejected"
      ? "rejected"
      : entitlement && Date.parse(entitlement.ends_at) <= now
        ? "expired"
        : applicationStatus && ["submitted", "accepted_pending_payment"].includes(applicationStatus)
          ? "pending"
          : "inactive";
  const orderResult = application?.id
    ? await supabase
        .from("payment_orders")
        .select("id,status,created_at")
        .eq("coach_application_id", application.id)
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle()
    : { data: null, error: null };
  if (orderResult.error)
    return failure(
      repositoryError("Status pembayaran Coach belum dapat dimuat.", orderResult.error),
    );
  const avatarPath = asString(profile.profile_avatar_path);
  const avatarUrl = avatarPath
    ? supabase.storage.from("public-media").getPublicUrl(avatarPath).data.publicUrl
    : asString(profile.provider_avatar_url);
  return success<CoachContext>({
    accessEndsAt: entitlement?.ends_at ?? null,
    accessStartsAt: entitlement?.starts_at ?? null,
    accessState,
    applicationId: application?.id ?? null,
    applicationStatus,
    avatarUrl,
    biography: profile.coach_biography ?? "",
    city: profile.city ?? "",
    displayName: profile.display_name,
    email: actor.email,
    isPublic: Boolean(profile.coach_is_public),
    paymentOrderId: orderResult.data?.id ?? null,
    paymentStatus: orderResult.data?.status ?? null,
    phoneNumber: profile.phone_number,
  });
}

async function activeCoach() {
  const context = await loadCoachContextRepository();
  if (!context.isSuccess) return context;
  return context.value.accessState === "active"
    ? context
    : failure(new AppError("forbidden", "Akses Coach belum aktif atau sudah berakhir."));
}

export async function listCoachRosterRepository() {
  const active = await activeCoach();
  if (!active.isSuccess) return active;
  const verified = await verifiedContext();
  if (!verified.isSuccess) return verified;
  const { actor, supabase } = verified.value;
  const { data, error } = await supabase.rpc("list_my_assigned_participants");
  if (error) return failure(repositoryError("Daftar Peserta belum dapat dimuat.", error));
  const raw = asRows(data);
  const participantIds = raw.flatMap((value) => {
    const id = asString(asRow(asRow(value)?.profile)?.user_id);
    return id ? [id] : [];
  });
  if (!participantIds.length) return success<readonly CoachRosterEntry[]>([]);
  const [profiles, enrollments, programs] = await Promise.all([
    supabase
      .from("profiles")
      .select("user_id,public_profile_id,profile_avatar_path,provider_avatar_url")
      .in("user_id", participantIds),
    supabase
      .from("program_enrollments")
      .select("id,participant_id,program_id,status,enrolled_at")
      .eq("coach_id", actor.userId)
      .in("participant_id", participantIds),
    supabasePublicProgramRepository.list(),
  ]);
  if (profiles.error || enrollments.error || !programs.isSuccess)
    return failure(
      repositoryError(
        "Ringkasan Peserta belum dapat dimuat.",
        profiles.error ?? enrollments.error ?? (!programs.isSuccess ? programs.error : undefined),
      ),
    );
  const enrollmentRows = enrollments.data ?? [];
  const scoreResult = enrollmentRows.length
    ? await supabase
        .from("program_scores")
        .select(
          "enrollment_id,activity_points,quiz_points,weight_points,adjustment_points,progress_percentage",
        )
        .in(
          "enrollment_id",
          enrollmentRows.map(({ id }) => id),
        )
    : { data: [], error: null };
  if (scoreResult.error)
    return failure(repositoryError("Skor Peserta belum dapat dimuat.", scoreResult.error));
  const entries: CoachRosterEntry[] = [];
  for (const value of raw) {
    const item = asRow(value);
    const profile = asRow(item?.profile);
    const participantId = asString(profile?.user_id);
    const displayName = asString(profile?.display_name);
    const activeCount = asInteger(item?.active_enrollment_count);
    const pending = asInteger(item?.pending_review_count);
    if (!participantId || !displayName || activeCount === null || pending === null)
      return failure(new AppError("validation_failed", "Data roster Coach tidak valid."));
    const participantEnrollments = enrollmentRows
      .filter(({ participant_id }) => participant_id === participantId)
      .toSorted((left, right) => right.enrolled_at.localeCompare(left.enrolled_at));
    const enrollment =
      participantEnrollments.find(({ status }) => status === "active") ?? participantEnrollments[0];
    const score = (scoreResult.data ?? []).find(
      ({ enrollment_id }) => enrollment_id === enrollment?.id,
    );
    const progress =
      score?.progress_percentage ?? asInteger(item?.average_progress_percentage) ?? 0;
    const points = score
      ? score.activity_points + score.quiz_points + score.weight_points + score.adjustment_points
      : 0;
    const program = programs.value.find(({ id }) => id === enrollment?.program_id);
    const privateProfile = (profiles.data ?? []).find(({ user_id }) => user_id === participantId);
    const avatarPath = asString(privateProfile?.profile_avatar_path);
    entries.push({
      activeEnrollmentCount: activeCount,
      attentionState: coachAttentionState(activeCount, progress),
      avatarUrl: avatarPath
        ? supabase.storage.from("public-media").getPublicUrl(avatarPath).data.publicUrl
        : asString(privateProfile?.provider_avatar_url),
      city: asString(profile?.city),
      displayName,
      lastActivityAt: null,
      memberLevel: asString(profile?.member_level),
      participantId,
      pendingReviewCount: pending,
      points,
      programId: program?.id ?? null,
      programTitle: program?.title ?? null,
      progressPercentage: progress,
      publicProfileId: privateProfile?.public_profile_id ?? participantId,
    });
  }
  const submissionResult = enrollmentRows.length
    ? await supabase
        .from("step_submissions")
        .select("enrollment_id,submitted_at")
        .in(
          "enrollment_id",
          enrollmentRows.map(({ id }) => id),
        )
        .not("submitted_at", "is", null)
    : { data: [], error: null };
  if (submissionResult.error)
    return failure(
      repositoryError("Aktivitas Peserta belum dapat dimuat.", submissionResult.error),
    );
  return success(
    entries.map((entry) => {
      const ids = new Set(
        enrollmentRows
          .filter(({ participant_id }) => participant_id === entry.participantId)
          .map(({ id }) => id),
      );
      const last = (submissionResult.data ?? [])
        .filter(({ enrollment_id }) => ids.has(enrollment_id))
        .flatMap(({ submitted_at }) => (submitted_at ? [submitted_at] : []))
        .toSorted()
        .at(-1);
      return { ...entry, lastActivityAt: last ?? null };
    }),
  );
}

function mapAnswer(
  value: unknown,
  questions: readonly { id: string }[],
): CoachPrivateAnswer | null {
  const answer = asRow(value);
  const questionId = asString(answer?.question_id);
  if (!questionId) return null;
  return {
    answerKey: null,
    hasPhoto: Boolean(asString(answer?.private_photo_path)),
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
    textValue: asString(answer?.text_value),
  };
}

export async function loadCoachParticipantDetailRepository(
  participantId: string,
  programId?: string,
) {
  const active = await activeCoach();
  if (!active.isSuccess) return active;
  const verified = await verifiedContext();
  if (!verified.isSuccess) return verified;
  const { actor, supabase } = verified.value;
  const [profileResult, enrollmentResult, programs] = await Promise.all([
    supabase
      .from("profiles")
      .select(
        "user_id,display_name,city,phone_number,member_level,profile_avatar_path,provider_avatar_url",
      )
      .eq("user_id", participantId)
      .single(),
    supabase
      .from("program_enrollments")
      .select("id,program_id,status,enrolled_at")
      .eq("participant_id", participantId)
      .eq("coach_id", actor.userId),
    supabasePublicProgramRepository.list(),
  ]);
  if (profileResult.error || enrollmentResult.error || !programs.isSuccess)
    return failure(
      repositoryError(
        "Detail Peserta tidak tersedia untuk Coach ini.",
        profileResult.error ??
          enrollmentResult.error ??
          (!programs.isSuccess ? programs.error : undefined),
      ),
    );
  const enrollmentRows = enrollmentResult.data ?? [];
  const chosen =
    enrollmentRows.find(({ program_id }) => program_id === programId) ??
    enrollmentRows.find(({ status }) => status === "active") ??
    enrollmentRows.toSorted((a, b) => b.enrolled_at.localeCompare(a.enrolled_at))[0];
  const program = programs.value.find(({ id }) => id === chosen?.program_id);
  if (!chosen || !program)
    return failure(new AppError("validation_failed", "Enrollment Peserta tidak ditemukan."));
  const [scoreResult, submissionResult, weighResult] = await Promise.all([
    supabase.from("program_scores").select("*").eq("enrollment_id", chosen.id).single(),
    supabase
      .from("step_submissions")
      .select("id,step_id,attempt_sequence,status,submitted_at,review_note")
      .eq("enrollment_id", chosen.id)
      .order("submitted_at", { ascending: false }),
    supabase
      .from("weigh_ins")
      .select("kind,weight_kg,recorded_at")
      .eq("enrollment_id", chosen.id)
      .order("recorded_at", { ascending: true }),
  ]);
  if (scoreResult.error || submissionResult.error || weighResult.error)
    return failure(
      repositoryError(
        "Riwayat Peserta belum dapat dimuat.",
        scoreResult.error ?? submissionResult.error ?? weighResult.error,
      ),
    );
  const submissionIds = (submissionResult.data ?? []).map(({ id }) => id);
  const answerResult = submissionIds.length
    ? await supabase.from("step_submission_answers").select("*").in("submission_id", submissionIds)
    : { data: [], error: null };
  if (answerResult.error)
    return failure(repositoryError("Jawaban Peserta belum dapat dimuat.", answerResult.error));
  const steps = program.days.flatMap(({ steps }) => steps);
  const questions = steps.flatMap(({ questions }) => questions);
  const profile = profileResult.data;
  const avatarPath = asString(profile.profile_avatar_path);
  const score = scoreResult.data;
  return success<CoachParticipantDetail>({
    avatarUrl: avatarPath
      ? supabase.storage.from("public-media").getPublicUrl(avatarPath).data.publicUrl
      : asString(profile.provider_avatar_url),
    city: profile.city,
    displayName: profile.display_name,
    enrollmentId: chosen.id,
    enrollments: enrollmentRows.flatMap((enrollment) => {
      const candidate = programs.value.find(({ id }) => id === enrollment.program_id);
      return candidate
        ? [{ id: enrollment.id, programId: candidate.id, programTitle: candidate.title }]
        : [];
    }),
    memberLevel: profile.member_level,
    participantId,
    phoneNumber: profile.phone_number,
    program,
    score: {
      activityPoints: score.activity_points,
      adjustmentPoints: score.adjustment_points,
      progressPercentage: score.progress_percentage,
      quizPoints: score.quiz_points,
      totalPoints:
        score.activity_points + score.quiz_points + score.weight_points + score.adjustment_points,
      weightPoints: score.weight_points,
    },
    submissions: (submissionResult.data ?? []).map((submission) => {
      const step = steps.find(({ id }) => id === submission.step_id);
      return {
        answers: (answerResult.data ?? [])
          .filter(({ submission_id }) => submission_id === submission.id)
          .map((answer) => mapAnswer(answer, questions))
          .filter((answer): answer is CoachPrivateAnswer => Boolean(answer)),
        attemptSequence: submission.attempt_sequence,
        id: submission.id,
        reviewNote: submission.review_note,
        status: submission.status,
        stepId: submission.step_id,
        stepTitle: step?.title ?? "Langkah program",
        submittedAt: submission.submitted_at,
      };
    }),
    weighIns: (weighResult.data ?? []).map((weigh) => ({
      recordedAt: weigh.recorded_at,
      type: weigh.kind,
      weightKilograms: String(weigh.weight_kg),
    })),
  });
}
