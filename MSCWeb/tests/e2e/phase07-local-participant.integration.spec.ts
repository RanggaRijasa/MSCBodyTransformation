import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";

import { createClient, type SupabaseClient, type User } from "@supabase/supabase-js";
import { expect, test, type BrowserContext } from "@playwright/test";
import { renderSVG } from "uqr";

import {
  addSupabaseSession,
  createIdentity,
  must,
  paymentCleanupSql,
} from "./support/phase06-browser-fixture";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const publishableKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
const serviceKey = process.env.SUPABASE_TEST_SERVICE_ROLE_KEY;
const databaseUrl = process.env.DB_URL;
const baseUrl = "http://127.0.0.1:3000";
const password = "Phase07-browser-local-2026!";
const testImagePath = fileURLToPath(
  new URL("../../public/icons/app-icon-512.png", import.meta.url),
);
const ids = {
  application: crypto.randomUUID(),
  applicantApplication: crypto.randomUUID(),
  day: crypto.randomUUID(),
  destination: crypto.randomUUID(),
  entitlement: crypto.randomUUID(),
  formQuestion: crypto.randomUUID(),
  formStep: crypto.randomUUID(),
  initialStep: crypto.randomUUID(),
  finalStep: crypto.randomUUID(),
  payment: crypto.randomUUID(),
  program: crypto.randomUUID(),
};
const coachQr = `phase07_browser_${crypto.randomUUID().replaceAll("-", "_")}`;
let service: SupabaseClient;
let administrator: User;
let coach: User;
let participant: User;
let enrollmentId = "";
let orderId = "";
const users: User[] = [];

test.skip(
  !supabaseUrl || !publishableKey || !serviceKey || !databaseUrl,
  "Memerlukan Supabase lokal dan database URL.",
);
test.describe.configure({ mode: "serial" });

async function identity(label: string) {
  return createIdentity(service, users, password, `phase07-${label}`);
}

async function participantSession(context: BrowserContext) {
  if (!participant.email) throw new Error("Fixture auth tidak tersedia.");
  await participantSessionFor(context, participant.email);
}

async function participantSessionFor(context: BrowserContext, email: string) {
  if (!supabaseUrl || !publishableKey) throw new Error("Fixture auth tidak tersedia.");
  await addSupabaseSession(context, {
    baseUrl,
    email,
    password,
    publishableKey,
    supabaseUrl,
  });
}

test.beforeAll(async () => {
  if (!supabaseUrl || !serviceKey) return;
  expect(new URL(supabaseUrl).hostname).toMatch(/^(127\.0\.0\.1|localhost)$/);
  service = createClient(supabaseUrl, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  administrator = await identity("admin");
  coach = await identity("coach");
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
        coach_is_approved: true,
        coach_is_public: true,
        coach_qr_identifier: coachQr,
        display_name: "Coach Phase 07",
        role: "coach",
      })
      .eq("user_id", coach.id),
    "profil Coach",
  );
  await must(
    service
      .from("profiles")
      .update({
        ...active,
        current_coach_id: null,
        display_name: "Peserta Phase 07",
        member_level: "member",
        phone_number: "+628123456789",
        role: "participant",
      })
      .eq("user_id", participant.id),
    "profil Peserta",
  );
  await must(
    service.from("coach_applications").insert({
      applicant_user_id: coach.id,
      decided_at: new Date().toISOString(),
      decided_by: administrator.id,
      display_name_snapshot: "Coach Phase 07",
      draft_idempotency_key: `phase07-${crypto.randomUUID()}`,
      has_completed_hom_sts: true,
      has_completed_ict: true,
      id: ids.application,
      member_level_snapshot: "sc",
      participant_profile_id: coach.id,
      phone_number_snapshot: "+628700000007",
      status: "active",
      submitted_at: new Date().toISOString(),
      terms_version: "phase07-local",
    }),
    "aplikasi Coach",
  );
  await must(
    service.from("coach_payment_records").insert({
      amount_minor_units: 100000,
      application_id: ids.application,
      id: ids.payment,
      price_band: "entry",
      provider_reference: `phase07-${crypto.randomUUID()}`,
      state: "verified",
      verified_at: new Date().toISOString(),
    }),
    "pembayaran Coach",
  );
  await must(
    service.from("coach_access_entitlements").insert({
      application_id: ids.application,
      coach_user_id: coach.id,
      ends_at: new Date(Date.now() + 30 * 86400000).toISOString(),
      id: ids.entitlement,
      payment_record_id: ids.payment,
      starts_at: new Date(Date.now() - 86400000).toISOString(),
      status: "active",
    }),
    "akses Coach",
  );
  await must(
    service.from("payment_destinations").insert({
      account_name: "MSC Phase 07 Lokal",
      account_reference: "1234567890",
      bank_code: "BCA",
      bank_name: "Bank Central Asia",
      created_by: administrator.id,
      effective_from: new Date().toISOString(),
      id: ids.destination,
      status: "active",
      version: Math.floor(Date.now() / 1000),
    }),
    "rekening tujuan",
  );
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
      past_step_policy: "read_only",
      points_per_activity: 10,
      points_per_weight_kg: 100,
      desired_price: 250000,
      pricing_mode: "paid",
      published_at: new Date().toISOString(),
      quiz_passing_percentage: 70,
      starts_on: today,
      status: "active",
      summary: "Perjalanan Peserta terverifikasi lokal.",
      timezone: "Asia/Jakarta",
      title: "Program Participant Phase 07",
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
      summary: "Selesaikan tiga langkah hari ini.",
      title: "Hari verifikasi",
    }),
    "hari program",
  );
  await must(
    service.from("program_steps").insert([
      {
        completion_policy: "submit_weigh_in",
        content_kind: "initial_weigh_in",
        id: ids.initialStep,
        instructions: "",
        program_day_id: ids.day,
        step_order: 1,
        title: "Berat awal",
        verification_mode: "automatic",
      },
      {
        completion_policy: "answer_all_questions",
        content_kind: "form",
        id: ids.formStep,
        instructions: "Jawab refleksi singkat.",
        program_day_id: ids.day,
        step_order: 2,
        title: "Refleksi harian",
        verification_mode: "coach_review",
      },
      {
        completion_policy: "submit_weigh_in",
        content_kind: "final_weigh_in",
        id: ids.finalStep,
        instructions: "",
        program_day_id: ids.day,
        step_order: 3,
        title: "Berat akhir",
        verification_mode: "automatic",
      },
    ]),
    "langkah program",
  );
  await must(
    service.from("program_questions").insert({
      id: ids.formQuestion,
      kind: "short_answer",
      prompt: "Apa fokusmu hari ini?",
      question_order: 1,
      step_id: ids.formStep,
    }),
    "pertanyaan",
  );
});

test.afterAll(async () => {
  if (!service || !databaseUrl) return;
  if (orderId) {
    const evidence = await service
      .from("payment_evidence_attempts")
      .select("object_path")
      .eq("order_id", orderId);
    const paths = (evidence.data ?? []).map(({ object_path }) => object_path);
    if (paths.length) await service.storage.from("payment-evidence").remove(paths);
  }
  expect(new URL(databaseUrl).hostname).toMatch(/^(127\.0\.0\.1|localhost)$/);
  execFileSync("/opt/homebrew/opt/postgresql@16/bin/psql", [
    "-X",
    "-w",
    "-v",
    "ON_ERROR_STOP=1",
    "-d",
    databaseUrl,
    "-c",
    paymentCleanupSql(ids),
  ]);
  await service.from("coach_access_entitlements").delete().eq("id", ids.entitlement);
  await service.from("coach_payment_records").delete().eq("id", ids.payment);
  await service.from("coach_applications").delete().eq("id", ids.application);
  for (const user of [...users].reverse()) await service.auth.admin.deleteUser(user.id);
});

test("gabung → bayar → Admin verifikasi → aktivitas → Coach review → leaderboard", async ({
  browser,
  context,
  page,
}) => {
  await participantSession(context);
  const main = page.locator("#app-main-content");
  const svg = renderSVG(`${baseUrl}/gabung/coach/${coachQr}`, { border: 4, ecc: "M" });
  await page.setContent(`<div style="width:320px;height:320px">${svg}</div>`);
  const qrImage = await page.locator("svg").screenshot({ type: "png" });

  await page.goto(`/program/${ids.program}/gabung`);
  await page.getByRole("button", { name: "Pindai QR Coach" }).click();
  await page.locator('.qr-scanner__file-action input[type="file"]').setInputFiles({
    buffer: qrImage,
    mimeType: "image/png",
    name: "coach-phase07.png",
  });
  await expect(page.getByRole("heading", { name: "Coach Phase 07" })).toBeVisible();
  await page.getByRole("button", { name: "Lanjut ke pembayaran" }).click();
  await expect(page).toHaveURL(/\/pembayaran\/[0-9a-f-]{36}$/);
  orderId = new URL(page.url()).pathname.split("/").at(-1) ?? "";
  await page.locator('.image-acquisition input[type="file"]').setInputFiles(testImagePath);
  await page.getByRole("button", { name: "Kirim untuk diperiksa" }).click();
  await expect(page.getByRole("heading", { name: "Menunggu pemeriksaan Admin" })).toBeVisible();

  const adminContext = await browser.newContext();
  if (!administrator.email) throw new Error("Fixture Admin tidak tersedia.");
  await participantSessionFor(adminContext, administrator.email);
  const adminPage = await adminContext.newPage();
  await adminPage.goto(`/admin/pembayaran/${orderId}`);
  const decision = adminPage.locator(".payment-decision:visible");
  await decision.getByRole("textbox", { name: "Referensi mutasi bank" }).fill("MUTASI-PHASE07");
  await decision
    .getByRole("checkbox", {
      name: "Rekening tujuan pada mutasi cocok dengan snapshot pesanan",
    })
    .check();
  await decision.getByRole("button", { name: "Setujui pembayaran" }).click();
  await decision.getByRole("button", { name: "Konfirmasi dan aktifkan" }).click();
  await expect(adminPage.getByText("Terverifikasi", { exact: true })).toBeVisible();
  await adminContext.close();

  await page.reload();
  await expect(page.getByRole("heading", { name: "Pembayaran terverifikasi" })).toBeVisible();
  const enrollment = await must(
    service
      .from("program_enrollments")
      .select("id")
      .eq("program_id", ids.program)
      .eq("participant_id", participant.id)
      .single(),
    "enrollment aktif",
  );
  if (!enrollment.data) throw new Error("Enrollment belum diaktifkan.");
  enrollmentId = enrollment.data.id;

  await page.goto(`/hari-ini?program=${ids.program}`);
  await expect(main.getByRole("heading", { name: "Halo, Peserta Phase 07" })).toBeVisible();
  await expect(main.getByRole("heading", { name: "Fokus" })).toBeVisible();

  await page.goto(`/program/${ids.program}`);
  await expect(main.getByText("Hari ini · Hari verifikasi")).toBeVisible();
  await main.getByRole("link", { name: /Berat awal/ }).click();
  await main.getByRole("textbox", { name: "Berat badan (kg)" }).fill("75,00");
  await main.getByRole("button", { name: "Simpan berat" }).click();
  await expect(main.getByRole("heading", { name: "Tidak ada tindakan" })).toBeVisible();

  await page.goto(`/program/${ids.program}/langkah/${ids.formStep}`);
  await main.getByRole("textbox", { name: "Apa fokusmu hari ini?" }).fill("Menjaga konsistensi.");
  await main.getByRole("button", { name: "Kirim aktivitas" }).click();
  await expect(main.getByText("Menunggu pemeriksaan Coach", { exact: true }).first()).toBeVisible();

  if (!supabaseUrl || !publishableKey || !coach.email)
    throw new Error("Fixture Coach tidak tersedia.");
  const coachClient = createClient(supabaseUrl, publishableKey, {
    auth: { persistSession: false },
  });
  await must(coachClient.auth.signInWithPassword({ email: coach.email, password }), "login Coach");
  const submission = await must(
    service
      .from("step_submissions")
      .select("id")
      .eq("enrollment_id", enrollmentId)
      .eq("step_id", ids.formStep)
      .single(),
    "submission",
  );
  if (!submission.data) throw new Error("Submission belum tersedia.");
  await must(
    coachClient.rpc("review_step_submission", {
      request_idempotency_key: `phase07-review-${crypto.randomUUID()}`,
      review_decision: "approved",
      review_reason: null,
      target_submission_id: submission.data.id,
    }),
    "review Coach",
  );

  await page.goto(`/program/${ids.program}/langkah/${ids.finalStep}`);
  await main.getByRole("textbox", { name: "Berat badan (kg)" }).fill("72,50");
  await main.getByRole("button", { name: "Simpan berat" }).click();
  await expect(main.getByRole("heading", { name: "Tidak ada tindakan" })).toBeVisible();

  await page.goto(`/peringkat?program=${ids.program}`);
  const ranking = main.getByRole("region", { name: "Peringkat peserta" });
  await expect(ranking.getByText("Peserta Phase 07", { exact: true })).toBeVisible();
  await expect(ranking.getByText("260 poin")).toBeVisible();
  await expect(main.getByText(/72[,.]5/)).toHaveCount(0);
});
