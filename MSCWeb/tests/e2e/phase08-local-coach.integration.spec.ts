import { createClient, type SupabaseClient, type User } from "@supabase/supabase-js";
import { expect, test, type BrowserContext } from "@playwright/test";

import { addSupabaseSession, createIdentity, must } from "./support/phase06-browser-fixture";
import { createCoachAccessFixture } from "./support/phase08-coach-fixture";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const publishableKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
const serviceKey = process.env.SUPABASE_TEST_SERVICE_ROLE_KEY;
const baseUrl = "http://127.0.0.1:3000";
const password = "Phase08-browser-local-2026!";
const ids = {
  applicationA: crypto.randomUUID(),
  applicationB: crypto.randomUUID(),
  applicationExpired: crypto.randomUUID(),
  day: crypto.randomUUID(),
  enrollment: crypto.randomUUID(),
  entitlementA: crypto.randomUUID(),
  entitlementB: crypto.randomUUID(),
  entitlementExpired: crypto.randomUUID(),
  initialStep: crypto.randomUUID(),
  paymentA: crypto.randomUUID(),
  paymentB: crypto.randomUUID(),
  paymentExpired: crypto.randomUUID(),
  program: crypto.randomUUID(),
  question: crypto.randomUUID(),
  rejectedSubmission: crypto.randomUUID(),
  step: crypto.randomUUID(),
  submission: crypto.randomUUID(),
  weighIn: crypto.randomUUID(),
};
const coachAQr = `phase08_coach_a_${crypto.randomUUID().replaceAll("-", "_")}`;
const coachBQr = `phase08_coach_b_${crypto.randomUUID().replaceAll("-", "_")}`;
let service: SupabaseClient;
let administrator: User;
let coachA: User;
let coachB: User;
let expiredCoach: User;
let participant: User;
const users: User[] = [];

test.skip(!supabaseUrl || !publishableKey || !serviceKey, "Memerlukan Supabase lokal.");
test.describe.configure({ mode: "serial" });

async function identity(label: string) {
  return createIdentity(service, users, password, `phase08-${label}`);
}

async function session(context: BrowserContext, user: User) {
  if (!supabaseUrl || !publishableKey || !user.email)
    throw new Error("Fixture Auth tidak tersedia.");
  await addSupabaseSession(context, {
    baseUrl,
    email: user.email,
    password,
    publishableKey,
    supabaseUrl,
  });
}

test.beforeAll(async () => {
  if (!supabaseUrl || !serviceKey || !publishableKey) return;
  expect(new URL(supabaseUrl).hostname).toMatch(/^(127\.0\.0\.1|localhost)$/);
  service = createClient(supabaseUrl, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  administrator = await identity("admin");
  coachA = await identity("coach-a");
  coachB = await identity("coach-b");
  expiredCoach = await identity("expired");
  participant = await identity("participant");
  const active = {
    finalized_at: new Date().toISOString(),
    onboarding_status: "active",
    provisional_expires_at: null,
  };
  await must(
    service
      .from("profiles")
      .update({ ...active, role: "admin" })
      .eq("user_id", administrator.id),
    "profil Admin",
  );
  await must(
    service
      .from("profiles")
      .update({
        ...active,
        coach_biography: "Mendampingi kebiasaan sehat.",
        coach_is_approved: true,
        coach_is_public: true,
        coach_qr_identifier: coachAQr,
        city: "Denpasar",
        current_coach_id: coachB.id,
        display_name: "Coach Browser A",
        role: "coach",
      })
      .eq("user_id", coachA.id),
    "profil Coach A",
  );
  await must(
    service
      .from("profiles")
      .update({
        ...active,
        coach_is_approved: true,
        coach_is_public: true,
        coach_qr_identifier: coachBQr,
        display_name: "Coach Browser B",
        role: "coach",
      })
      .eq("user_id", coachB.id),
    "profil Coach B",
  );
  await must(
    service
      .from("profiles")
      .update({
        ...active,
        account_purpose: "coach_applicant",
        coach_is_approved: false,
        display_name: "Coach Expired Browser",
        role: "participant",
      })
      .eq("user_id", expiredCoach.id),
    "profil Coach expired",
  );
  await must(
    service
      .from("profiles")
      .update({
        ...active,
        current_coach_id: coachA.id,
        display_name: "Peserta Coach Browser",
        phone_number: "+628123456780",
        role: "participant",
      })
      .eq("user_id", participant.id),
    "profil Peserta",
  );
  const future = new Date(Date.now() + 30 * 86400000).toISOString();
  await createCoachAccessFixture(service, administrator, {
    applicationId: ids.applicationA,
    coach: coachA,
    displayName: "Coach Browser A",
    endsAt: future,
    entitlementId: ids.entitlementA,
    paymentId: ids.paymentA,
    status: "active",
  });
  await createCoachAccessFixture(service, administrator, {
    applicationId: ids.applicationB,
    coach: coachB,
    displayName: "Coach Browser B",
    endsAt: future,
    entitlementId: ids.entitlementB,
    paymentId: ids.paymentB,
    status: "active",
  });
  await createCoachAccessFixture(service, administrator, {
    applicationId: ids.applicationExpired,
    coach: expiredCoach,
    displayName: "Coach Expired Browser",
    endsAt: new Date(Date.now() - 86400000).toISOString(),
    entitlementId: ids.entitlementExpired,
    paymentId: ids.paymentExpired,
    status: "expired",
  });
  const today = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Jakarta",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(new Date());
  await must(
    service.from("programs").insert({
      created_by: administrator.id,
      duration_mode: "fixed_duration",
      ends_on: today,
      future_step_policy: "locked",
      id: ids.program,
      pace: "scheduled",
      past_step_policy: "available",
      points_per_activity: 10,
      points_per_weight_kg: 100,
      pricing_mode: "free",
      published_at: new Date().toISOString(),
      quiz_passing_percentage: 70,
      starts_on: today,
      status: "active",
      summary: "Program E2E Coach.",
      timezone: "Asia/Jakarta",
      title: "Program Coach Browser",
      wellness_disclaimer: "Program kebugaran non-diagnostik.",
    }),
    "program",
  );
  await must(
    service.from("program_days").insert({
      day_number: 1,
      id: ids.day,
      program_id: ids.program,
      scheduled_on: today,
      title: "Hari Coach",
    }),
    "hari",
  );
  await must(
    service.from("program_steps").insert([
      {
        completion_policy: "submit_weigh_in",
        content_kind: "initial_weigh_in",
        id: ids.initialStep,
        program_day_id: ids.day,
        step_order: 1,
        title: "Timbang awal",
        verification_mode: "automatic",
      },
      {
        completion_policy: "answer_all_questions",
        content_kind: "form",
        id: ids.step,
        program_day_id: ids.day,
        step_order: 2,
        title: "Refleksi Coach",
        verification_mode: "coach_review",
      },
    ]),
    "langkah",
  );
  await must(
    service.from("program_questions").insert({
      id: ids.question,
      kind: "short_answer",
      prompt: "Apa fokus hari ini?",
      question_order: 1,
      step_id: ids.step,
    }),
    "pertanyaan",
  );
  await must(
    service.from("program_answer_keys").insert({
      accepted_text_values: ["Menjaga konsistensi."],
      matching_mode: "case_insensitive_text",
      question_id: ids.question,
      selected_option_ids: [],
    }),
    "kunci jawaban",
  );
  await must(
    service.from("program_enrollments").insert({
      coach_id: coachA.id,
      id: ids.enrollment,
      participant_id: participant.id,
      program_id: ids.program,
      status: "active",
    }),
    "enrollment Peserta",
  );
  await must(
    service.from("program_scores").insert({ enrollment_id: ids.enrollment }),
    "skor Peserta",
  );
  await must(
    service.from("weigh_ins").insert({
      enrollment_id: ids.enrollment,
      id: ids.weighIn,
      idempotency_key: "phase08-weight-once",
      kind: "initial",
      step_id: ids.initialStep,
      weight_kg: 75,
    }),
    "berat privat",
  );
  await must(
    service.from("step_submissions").insert({
      attempt_sequence: 1,
      enrollment_id: ids.enrollment,
      finalized_at: new Date().toISOString(),
      id: ids.submission,
      idempotency_key: "phase08-browser-submission",
      status: "pending",
      step_id: ids.step,
      submitted_at: new Date().toISOString(),
    }),
    "submission",
  );
  await must(
    service.from("step_submission_answers").insert({
      question_id: ids.question,
      submission_id: ids.submission,
      text_value: "Menjaga konsistensi.",
    }),
    "jawaban",
  );
  const coachClient = createClient(supabaseUrl, publishableKey, {
    auth: { persistSession: false },
  });
  await must(
    coachClient.auth.signInWithPassword({ email: coachA.email ?? "", password }),
    "login Coach sebagai Peserta",
  );
  await must(
    coachClient.rpc("enroll_free_program", {
      scanned_coach_qr: coachBQr,
      target_program_id: ids.program,
    }),
    "Coach mengikuti program",
  );
});

test.afterAll(async () => {
  if (!service) return;
  await service.from("program_enrollments").delete().eq("program_id", ids.program);
  await service.from("programs").delete().eq("id", ids.program);
  await service
    .from("coach_access_entitlements")
    .delete()
    .in("id", [ids.entitlementA, ids.entitlementB, ids.entitlementExpired]);
  await service
    .from("coach_payment_records")
    .delete()
    .in("id", [ids.paymentA, ids.paymentB, ids.paymentExpired]);
  await service
    .from("coach_applications")
    .delete()
    .in("id", [ids.applicationA, ids.applicationB, ids.applicationExpired]);
  for (const user of [...users].reverse()) await service.auth.admin.deleteUser(user.id);
});

test("dashboard → roster → detail → approve → score → activity → QR → mode Peserta", async ({
  context,
  page,
}) => {
  const reactWarnings: string[] = [];
  page.on("console", (message) => {
    if (message.text().includes("two children with the same key"))
      reactWarnings.push(`${message.text()} ${JSON.stringify(message.location())}`);
  });
  await session(context, coachA);
  await page.goto("/coach-area");
  await expect(page.getByRole("heading", { name: "Halo, Coach Browser A" })).toBeVisible();
  await expect(page.getByRole("link", { name: /Peserta saya/ })).toBeVisible();
  await page.goto("/coach-area/peserta?perhatian=not_started&urut=progress");
  await expect(page.getByRole("heading", { name: "Peserta Coach Browser" })).toBeVisible();
  await page.getByRole("link", { name: "Buka detail privat" }).click();
  await expect(page.getByRole("heading", { name: "Riwayat berat privat" })).toBeVisible();
  await expect(page.getByText(/75(?:,0)?\s*kg/i)).toBeVisible();
  await expect(page.getByText("Menjaga konsistensi.")).toBeVisible();
  await page.goto("/coach-area/pemeriksaan");
  await expect(page.getByRole("heading", { name: "Peserta Coach Browser" })).toBeVisible();
  await expect(page.getByText("Kunci jawaban")).toBeVisible();
  await expect(page.getByText("Menjaga konsistensi.", { exact: true })).toHaveCount(2);
  await page.getByRole("button", { name: "Setujui" }).click();
  await expect(page.getByText(/Skor direkonsiliasi/)).toBeVisible();
  const submission = await service
    .from("step_submissions")
    .select("status")
    .eq("id", ids.submission)
    .single();
  expect(submission.data?.status).toBe("approved");
  const score = await service
    .from("program_scores")
    .select("activity_points")
    .eq("enrollment_id", ids.enrollment)
    .single();
  expect(score.data?.activity_points).toBe(10);
  await page.goto(`/coach-area/program?program=${ids.program}&rentang=7`);
  await expect(page.getByRole("heading", { name: "Aktivitas" })).toBeVisible();
  await expect(page.getByText(/75(?:,0)?\s*kg/i)).toHaveCount(0);
  await expect(page.getByRole("img", { name: /bukti/i })).toHaveCount(0);
  await page.goto("/coach-area/qr");
  await expect(
    page.getByRole("img", { name: "QR pendaftaran milik Coach Browser A" }),
  ).toBeVisible();
  await expect(page.getByRole("button", { name: "Bagikan QR" })).toBeVisible();
  await expect(page.getByRole("textbox", { name: /identifier|kode/i })).toHaveCount(0);
  await page.goto("/coach-area/profil");
  await page.getByLabel("Bio publik").fill("Bio Coach diperbarui melalui journey lokal.");
  await page.getByRole("button", { name: "Simpan profil publik" }).click();
  await expect(page.getByRole("status")).toHaveText(/berhasil diperbarui/);
  const coachProfile = await service
    .from("profiles")
    .select("coach_biography")
    .eq("user_id", coachA.id)
    .single();
  expect(coachProfile.data?.coach_biography).toBe("Bio Coach diperbarui melalui journey lokal.");
  await page.goto(`/hari-ini?program=${ids.program}`);
  await expect(page.getByRole("heading", { name: "Halo, Coach Browser A" })).toBeVisible();
  await expect(page.getByRole("heading", { name: "Program" })).toBeVisible();
  expect(
    reactWarnings,
    JSON.stringify({ coachA: coachA.id, coachB: coachB.id, ids, participant: participant.id }),
  ).toEqual([]);
});

test("Coach lain ditolak dari detail privat", async ({ context, page }) => {
  await session(context, coachB);
  await page.goto(`/coach-area/peserta/${participant.id}?program=${ids.program}`);
  await expect(page.getByRole("heading", { name: "Detail Peserta tidak tersedia" })).toBeVisible();
  await expect(page.getByText(/75(?:,0)?\s*kg/i)).toHaveCount(0);
});

test("Coach menolak submission dengan alasan wajib dan audit server", async ({ context, page }) => {
  await must(
    service.from("step_submissions").insert({
      attempt_sequence: 2,
      enrollment_id: ids.enrollment,
      finalized_at: new Date().toISOString(),
      id: ids.rejectedSubmission,
      idempotency_key: "phase08-browser-rejection",
      status: "pending",
      step_id: ids.step,
      submitted_at: new Date().toISOString(),
    }),
    "submission untuk penolakan",
  );
  await must(
    service.from("step_submission_answers").insert({
      question_id: ids.question,
      submission_id: ids.rejectedSubmission,
      text_value: "Jawaban perlu diperbaiki.",
    }),
    "jawaban untuk penolakan",
  );
  await session(context, coachA);
  await page.goto("/coach-area/pemeriksaan");
  await page.getByRole("button", { name: "Tolak" }).click();
  await expect(page.getByRole("status")).toHaveText(/Tulis alasan penolakan/);
  await page.getByLabel(/Alasan penolakan/).fill("Bukti belum sesuai panduan.");
  await page.getByRole("button", { name: "Tolak" }).click();
  await expect(page.getByRole("status")).toHaveText(/Keputusan tersimpan/);
  const rejected = await service
    .from("step_submissions")
    .select("status,review_note")
    .eq("id", ids.rejectedSubmission)
    .single();
  expect(rejected.data).toMatchObject({
    review_note: "Bukti belum sesuai panduan.",
    status: "rejected",
  });
  const audit = await service
    .from("audit_events")
    .select("id", { count: "exact", head: true })
    .eq("kind", "submission_rejected")
    .eq("subject_id", ids.rejectedSubmission);
  expect(audit.count).toBe(1);
});

test("expiry mempertahankan mode Peserta lalu renewal lokal memulihkan dashboard", async ({
  context,
  page,
}) => {
  await session(context, expiredCoach);
  await page.goto("/coach-area");
  await expect(page.getByRole("heading", { name: "Akses Coach berakhir" })).toBeVisible();
  await expect(page.getByRole("link", { name: "Lanjut sebagai Peserta" })).toBeVisible();
  await must(
    service
      .from("coach_access_entitlements")
      .update({ ends_at: new Date(Date.now() + 90 * 86400000).toISOString(), status: "active" })
      .eq("id", ids.entitlementExpired),
    "renewal entitlement",
  );
  await must(
    service
      .from("profiles")
      .update({ coach_is_approved: true, role: "coach" })
      .eq("user_id", expiredCoach.id),
    "renewal projection",
  );
  await page.reload();
  await expect(page.getByRole("heading", { name: "Halo, Coach Expired Browser" })).toBeVisible();
});
