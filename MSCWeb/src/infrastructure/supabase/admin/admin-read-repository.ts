import "server-only";

import { AppError } from "@/domain/errors/app-error";
import type {
  AdminAuditItem,
  AdminCoachApplication,
  AdminCorrectionTargets,
  AdminDashboardSnapshot,
  AdminPerson,
  AdminWinnerPoster,
  AdminWinnerSnapshot,
} from "@/domain/admin/admin-operations";
import { safeAuditKind } from "@/domain/admin/admin-operations";
import { failure, success, type Result } from "@/domain/result";
import { getVerifiedSupabaseContext } from "@/infrastructure/supabase/auth/get-verified-actor";

type UnknownRow = Record<string, unknown>;

function adminError(cause: unknown, message: string) {
  return new AppError("unknown", message, { cause });
}

function record(value: unknown): UnknownRow | null {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? (value as UnknownRow)
    : null;
}

function text(value: unknown) {
  return typeof value === "string" ? value : null;
}

async function context() {
  return getVerifiedSupabaseContext();
}

export async function loadAdminDashboard(): Promise<Result<AdminDashboardSnapshot, AppError>> {
  const verified = await context();
  if (!verified.isSuccess) return verified;
  const client = verified.value.supabase;
  const [payments, applications, reviews, programs, audit] = await Promise.all([
    client
      .from("payment_orders")
      .select("id", { count: "exact", head: true })
      .eq("status", "under_review"),
    client
      .from("coach_applications")
      .select("id", { count: "exact", head: true })
      .eq("status", "submitted"),
    client
      .from("step_submissions")
      .select("id", { count: "exact", head: true })
      .eq("status", "pending"),
    client.from("programs").select("id,status").in("status", ["active", "completed"]),
    client
      .from("audit_events")
      .select("id,kind,subject_id,summary,created_at")
      .order("created_at", { ascending: false })
      .limit(5),
  ]);
  const error =
    payments.error ?? applications.error ?? reviews.error ?? programs.error ?? audit.error;
  if (error) return failure(adminError(error, "Dashboard Admin belum dapat dimuat."));
  const programRows = Array.isArray(programs.data) ? programs.data : [];
  const completedIds = programRows
    .filter((row) => row.status === "completed")
    .map((row) => row.id)
    .filter((id): id is string => typeof id === "string");
  let closureBlockers = 0;
  if (completedIds.length > 0) {
    const snapshots = await client
      .from("winner_snapshots")
      .select("program_id")
      .in("program_id", completedIds);
    if (snapshots.error)
      return failure(adminError(snapshots.error, "Status penutupan belum dapat dimuat."));
    const locked = new Set((snapshots.data ?? []).map((row) => row.program_id));
    closureBlockers = completedIds.filter((id) => !locked.has(id)).length;
  }
  const recentAudit: AdminAuditItem[] = [];
  for (const raw of audit.data ?? []) {
    const row = record(raw);
    const id = text(row?.id);
    const occurredAt = text(row?.created_at);
    const kind = text(row?.kind);
    if (!id || !occurredAt || !kind) continue;
    recentAudit.push({
      actorLabel: "Admin",
      id,
      kind: safeAuditKind(kind),
      occurredAt,
      reason: text(row?.summary) ?? "Perubahan tercatat.",
      subjectId: text(row?.subject_id),
    });
  }
  return success({
    activePrograms: programRows.filter((row) => row.status === "active").length,
    coachApplications: applications.count ?? 0,
    closureBlockers,
    paymentReviews: payments.count ?? 0,
    recentAudit,
    systemAttention: (reviews.count ?? 0) + closureBlockers,
  });
}

export async function listAdminPeople(
  role?: AdminPerson["role"],
  search?: string,
): Promise<Result<readonly AdminPerson[], AppError>> {
  const verified = await context();
  if (!verified.isSuccess) return verified;
  let query = verified.value.supabase
    .from("profiles")
    .select("user_id,display_name,role,member_level")
    .order("display_name")
    .limit(100);
  if (role) query = query.eq("role", role);
  if (search?.trim()) query = query.ilike("display_name", `%${search.trim().slice(0, 80)}%`);
  const { data, error } = await query;
  if (error) return failure(adminError(error, "Direktori orang belum dapat dimuat."));
  const people: AdminPerson[] = [];
  for (const raw of data ?? []) {
    const row = record(raw);
    const id = text(row?.user_id);
    const displayName = text(row?.display_name);
    const parsedRole = text(row?.role);
    if (!id || !displayName || !["admin", "coach", "participant"].includes(parsedRole ?? ""))
      continue;
    people.push({
      coachAccessEndsAt: null,
      coachApplicationStatus: null,
      displayName,
      email: "Email tidak ditampilkan",
      id,
      memberLevel: text(row?.member_level),
      role: parsedRole as AdminPerson["role"],
    });
  }
  return success(people);
}

export async function listAdminAudit(): Promise<Result<readonly AdminAuditItem[], AppError>> {
  const dashboard = await loadAdminDashboard();
  return dashboard.isSuccess ? success(dashboard.value.recentAudit) : dashboard;
}

export async function listAdminCorrectionTargets(): Promise<
  Result<AdminCorrectionTargets, AppError>
> {
  const verified = await context();
  if (!verified.isSuccess) return verified;
  const [enrollmentsResult, profilesResult, programsResult] = await Promise.all([
    verified.value.supabase
      .from("program_enrollments")
      .select("id,participant_id,program_id")
      .in("status", ["active", "completed"])
      .order("enrolled_at", { ascending: false })
      .limit(100),
    verified.value.supabase
      .from("profiles")
      .select("user_id,display_name")
      .order("display_name")
      .limit(200),
    verified.value.supabase
      .from("programs")
      .select("id,title")
      .order("starts_on", { ascending: false })
      .limit(100),
  ]);
  const error = enrollmentsResult.error ?? profilesResult.error ?? programsResult.error;
  if (error) return failure(adminError(error, "Target koreksi belum dapat dimuat."));
  const names = new Map((profilesResult.data ?? []).map((row) => [row.user_id, row.display_name]));
  const titles = new Map((programsResult.data ?? []).map((row) => [row.id, row.title]));
  const enrollments = (enrollmentsResult.data ?? []).flatMap((row) =>
    typeof row.id === "string" &&
    typeof row.participant_id === "string" &&
    typeof row.program_id === "string"
      ? [
          {
            id: row.id,
            label: `${names.get(row.participant_id) ?? "Peserta"} • ${titles.get(row.program_id) ?? "Program"}`,
          },
        ]
      : [],
  );
  const enrollmentLabels = new Map(enrollments.map((item) => [item.id, item.label]));
  const ids = enrollments.map((item) => item.id);
  if (!ids.length) return success({ enrollments, weighIns: [] });
  const weighInsResult = await verified.value.supabase
    .from("weigh_ins")
    .select("id,enrollment_id,kind")
    .in("enrollment_id", ids)
    .order("recorded_at", { ascending: false })
    .limit(100);
  if (weighInsResult.error)
    return failure(adminError(weighInsResult.error, "Data timbang belum dapat dimuat."));
  const weighIns = (weighInsResult.data ?? []).flatMap((row) =>
    typeof row.id === "string" && typeof row.enrollment_id === "string"
      ? [
          {
            id: row.id,
            label: `${enrollmentLabels.get(row.enrollment_id) ?? "Enrollment"} • ${text(row.kind) ?? "timbang"}`,
          },
        ]
      : [],
  );
  return success({ enrollments, weighIns });
}

export async function listCoachApplications(): Promise<
  Result<readonly AdminCoachApplication[], AppError>
> {
  const verified = await context();
  if (!verified.isSuccess) return verified;
  const { data, error } = await verified.value.supabase
    .from("coach_applications")
    .select(
      "id,applicant_user_id,display_name_snapshot,member_level_snapshot,has_completed_hom_sts,has_completed_ict,status,submitted_at,payment_orders(status)",
    )
    .order("submitted_at", { ascending: true, nullsFirst: false })
    .limit(100);
  if (error) return failure(adminError(error, "Pengajuan Coach belum dapat dimuat."));
  const applications: AdminCoachApplication[] = [];
  for (const raw of data ?? []) {
    const row = record(raw);
    const id = text(row?.id);
    const applicantId = text(row?.applicant_user_id);
    if (!id || !applicantId) continue;
    const orders = Array.isArray(row?.payment_orders) ? row.payment_orders : [];
    applications.push({
      applicantId,
      displayName: text(row?.display_name_snapshot) ?? "Peserta",
      hasCompletedHomSts: row?.has_completed_hom_sts === true,
      hasCompletedIct: row?.has_completed_ict === true,
      id,
      memberLevel: text(row?.member_level_snapshot) ?? "member",
      paymentStatus: text(record(orders[0])?.status),
      status: text(row?.status) ?? "draft",
      submittedAt: text(row?.submitted_at),
    });
  }
  return success(applications);
}

export async function listWinnerPosters(): Promise<Result<readonly AdminWinnerPoster[], AppError>> {
  const verified = await context();
  if (!verified.isSuccess) return verified;
  const { data, error } = await verified.value.supabase
    .from("winner_posters")
    .select("id,program_id,winner_snapshot_id,media_path,alt_text,is_published,published_at")
    .is("deleted_at", null)
    .order("published_at", { ascending: false, nullsFirst: false })
    .limit(100);
  if (error) return failure(adminError(error, "Galeri poster belum dapat dimuat."));
  const programIds = [
    ...new Set(
      (data ?? []).map((row) => text(row.program_id)).filter((id): id is string => Boolean(id)),
    ),
  ];
  const programTitles = new Map<string, string>();
  if (programIds.length) {
    const programs = await verified.value.supabase
      .from("programs")
      .select("id,title")
      .in("id", programIds);
    if (programs.error) {
      return failure(adminError(programs.error, "Judul program belum dapat dimuat."));
    }
    for (const program of programs.data ?? []) {
      if (typeof program.id === "string" && typeof program.title === "string") {
        programTitles.set(program.id, program.title);
      }
    }
  }
  const posters: AdminWinnerPoster[] = [];
  for (const raw of data ?? []) {
    const row = record(raw);
    const id = text(row?.id);
    const programId = text(row?.program_id);
    const snapshotId = text(row?.winner_snapshot_id);
    const mediaPath = text(row?.media_path);
    if (!id || !programId || !snapshotId || !mediaPath) continue;
    posters.push({
      alternativeText: text(row?.alt_text) ?? "Poster pemenang program",
      id,
      isPublished: row?.is_published === true,
      mediaPath,
      programId,
      programTitle: programTitles.get(programId) ?? "Program",
      publishedAt: text(row?.published_at),
      snapshotId,
    });
  }
  return success(posters);
}

export async function listWinnerSnapshots(): Promise<
  Result<readonly AdminWinnerSnapshot[], AppError>
> {
  const verified = await context();
  if (!verified.isSuccess) return verified;
  const { data, error } = await verified.value.supabase
    .from("winner_snapshots")
    .select("id,program_id")
    .order("locked_at", { ascending: false })
    .limit(100);
  if (error) return failure(adminError(error, "Snapshot pemenang belum dapat dimuat."));
  const programIds = [
    ...new Set(
      (data ?? [])
        .map((row) => row.program_id)
        .filter((id): id is string => typeof id === "string"),
    ),
  ];
  const programs = programIds.length
    ? await verified.value.supabase.from("programs").select("id,title").in("id", programIds)
    : { data: [], error: null };
  if (programs.error)
    return failure(adminError(programs.error, "Program pemenang belum dapat dimuat."));
  const titles = new Map((programs.data ?? []).map((row) => [row.id, row.title]));
  const snapshots: AdminWinnerSnapshot[] = (data ?? []).flatMap((row) =>
    typeof row.id === "string" && typeof row.program_id === "string"
      ? [
          {
            id: row.id,
            programId: row.program_id,
            programTitle: titles.get(row.program_id) ?? "Program",
          },
        ]
      : [],
  );
  return success(snapshots);
}
