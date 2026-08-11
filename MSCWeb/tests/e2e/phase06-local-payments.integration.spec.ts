import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";

import { createClient, type SupabaseClient, type User } from "@supabase/supabase-js";
import { expect, test, type BrowserContext } from "@playwright/test";

import {
  addSupabaseSession,
  assertCoachQueueFilters,
  createBrowserFixtureIds,
  createIdentity,
  must,
  paymentCleanupSql,
} from "./support/phase06-browser-fixture";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const publishableKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
const serviceKey = process.env.SUPABASE_TEST_SERVICE_ROLE_KEY;
const databaseUrl = process.env.DB_URL;
const baseUrl = "http://127.0.0.1:3000";
const password = "Phase06-browser-local-2026!";
const testImagePath = fileURLToPath(
  new URL("../../public/icons/app-icon-512.png", import.meta.url),
);
const ids = createBrowserFixtureIds();
const coachQr = `phase06_browser_${crypto.randomUUID().replaceAll("-", "_")}`;
let adminClient: SupabaseClient;
let administrator: User;
let applicant: User;
let participant: User;
let orderId = "";
const createdOrderIds: string[] = [];
let createdUsers: User[] = [];

test.skip(
  !supabaseUrl || !publishableKey || !serviceKey || !databaseUrl,
  "Memerlukan Supabase lokal dan database URL.",
);
test.describe.configure({ mode: "serial" });

async function identity(label: string) {
  return createIdentity(adminClient, createdUsers, password, label);
}

async function addSession(context: BrowserContext, email: string) {
  if (!supabaseUrl || !publishableKey) throw new Error("Supabase lokal tidak tersedia.");
  return addSupabaseSession(context, {
    baseUrl,
    email,
    password,
    publishableKey,
    supabaseUrl,
  });
}

test.beforeAll(async () => {
  if (!supabaseUrl || !serviceKey || !publishableKey) return;
  expect(new URL(supabaseUrl).hostname).toMatch(/^(127\.0\.0\.1|localhost)$/);
  adminClient = createClient(supabaseUrl, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  administrator = await identity("admin");
  const coach = await identity("coach");
  applicant = await identity("coach-applicant");
  participant = await identity("participant");
  const active = {
    finalized_at: new Date().toISOString(),
    onboarding_status: "active",
    provisional_expires_at: null,
  };
  await must(
    adminClient
      .from("profiles")
      .update({ ...active, role: "admin" })
      .eq("user_id", administrator.id)
      .select("user_id")
      .single(),
    "aktifkan profil Admin",
  );
  await must(
    adminClient
      .from("profiles")
      .update({
        ...active,
        coach_is_approved: true,
        coach_qr_identifier: coachQr,
        display_name: "Coach Payment Browser",
        role: "coach",
      })
      .eq("user_id", coach.id)
      .select("user_id")
      .single(),
    "aktifkan profil Coach",
  );
  await must(
    adminClient
      .from("profiles")
      .update({ ...active, display_name: "Peserta Payment Browser", role: "participant" })
      .eq("user_id", participant.id)
      .select("user_id")
      .single(),
    "aktifkan profil Peserta",
  );
  await must(
    adminClient
      .from("profiles")
      .update({ ...active, display_name: "Calon Coach Payment Browser", role: "participant" })
      .eq("user_id", applicant.id)
      .select("user_id")
      .single(),
    "aktifkan profil calon Coach",
  );
  await must(
    adminClient.from("coach_applications").insert({
      applicant_user_id: coach.id,
      decided_at: new Date().toISOString(),
      decided_by: administrator.id,
      display_name_snapshot: "Coach Payment Browser",
      draft_idempotency_key: `phase06-browser-${crypto.randomUUID()}`,
      has_completed_hom_sts: true,
      has_completed_ict: true,
      id: ids.application,
      member_level_snapshot: "sc",
      participant_profile_id: coach.id,
      phone_number_snapshot: "+628600000077",
      status: "active",
      submitted_at: new Date().toISOString(),
      terms_version: "phase06-local",
    }),
    "buat aplikasi Coach",
  );
  await must(
    adminClient.from("coach_payment_records").insert({
      amount_minor_units: 100000,
      application_id: ids.application,
      id: ids.payment,
      price_band: "entry",
      provider_reference: `phase06-${crypto.randomUUID()}`,
      state: "verified",
      verified_at: new Date().toISOString(),
    }),
    "buat catatan pembayaran Coach",
  );
  await must(
    adminClient.from("coach_access_entitlements").insert({
      application_id: ids.application,
      coach_user_id: coach.id,
      ends_at: new Date(Date.now() + 30 * 86400000).toISOString(),
      id: ids.entitlement,
      payment_record_id: ids.payment,
      starts_at: new Date(Date.now() - 86400000).toISOString(),
      status: "active",
    }),
    "buat hak akses Coach",
  );
  await must(
    adminClient.from("coach_applications").insert({
      applicant_user_id: applicant.id,
      decided_at: new Date().toISOString(),
      decided_by: administrator.id,
      display_name_snapshot: "Calon Coach Payment Browser",
      draft_idempotency_key: `phase06-browser-applicant-${crypto.randomUUID()}`,
      has_completed_hom_sts: true,
      has_completed_ict: true,
      id: ids.applicantApplication,
      member_level_snapshot: "supervisor",
      participant_profile_id: applicant.id,
      phone_number_snapshot: "+628600000088",
      status: "accepted_pending_payment",
      submitted_at: new Date().toISOString(),
      terms_version: "phase06-local",
    }),
    "buat pengajuan Coach yang diterima",
  );
  await must(
    adminClient.from("payment_destinations").insert({
      account_name: "MSC Browser Lokal",
      account_reference: "1234567890",
      bank_code: "BCA",
      bank_name: "Bank Central Asia",
      created_by: administrator.id,
      effective_from: new Date().toISOString(),
      id: ids.destination,
      status: "active",
      version: Math.floor(Date.now() / 1000),
    }),
    "buat rekening tujuan",
  );
  await must(
    adminClient.from("programs").insert({
      created_by: administrator.id,
      desired_price: 250000,
      duration_mode: "fixed_duration",
      ends_on: "2026-08-31",
      future_step_policy: "locked",
      id: ids.program,
      pace: "scheduled",
      past_step_policy: "available",
      points_per_activity: 10,
      points_per_weight_kg: 100,
      pricing_mode: "paid",
      published_at: new Date().toISOString(),
      quiz_passing_percentage: 70,
      starts_on: "2026-08-01",
      status: "active",
      summary: "Program browser Phase 06.",
      timezone: "Asia/Makassar",
      title: "Program Payment Browser",
      wellness_disclaimer: "Program kebugaran non-diagnostik.",
    }),
    "buat program berbayar",
  );
  const participantClient = createClient(supabaseUrl, publishableKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const signIn = await participantClient.auth.signInWithPassword({
    email: participant.email ?? "",
    password,
  });
  if (signIn.error) throw signIn.error;
  const order = await participantClient.rpc("create_program_payment_order", {
    coach_qr_payload: coachQr,
    request_idempotency_key: `phase06-browser-order-${crypto.randomUUID()}`,
    target_program_id: ids.program,
  });
  if (order.error) throw order.error;
  orderId = order.data.order_id;
  createdOrderIds.push(orderId);
});

test.afterAll(async () => {
  if (!adminClient || !databaseUrl) return;
  const evidence = await adminClient
    .from("payment_evidence_attempts")
    .select("object_path")
    .in(
      "order_id",
      createdOrderIds.length ? createdOrderIds : ["00000000-0000-0000-0000-000000000000"],
    );
  const paths = (evidence.data ?? []).map(({ object_path }) => object_path);
  if (paths.length) await adminClient.storage.from("payment-evidence").remove(paths);
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
  await adminClient
    .from("coach_access_entitlements")
    .delete()
    .in("application_id", [ids.application, ids.applicantApplication]);
  await adminClient
    .from("coach_payment_records")
    .delete()
    .in("application_id", [ids.application, ids.applicantApplication]);
  await adminClient
    .from("coach_applications")
    .delete()
    .in("id", [ids.application, ids.applicantApplication]);
  for (const user of [...createdUsers].reverse()) await adminClient.auth.admin.deleteUser(user.id);
  createdUsers = [];
});

test("upload offline retry lalu Admin approve mengaktifkan program", async ({ browser }) => {
  const participantContext = await browser.newContext();
  await addSession(participantContext, participant.email ?? "");
  const participantPage = await participantContext.newPage();
  await participantPage.goto(`/pembayaran/${orderId}`);
  await participantPage.getByRole("button", { name: "Gunakan kamera" }).click();
  await expect(participantPage.getByRole("dialog", { name: "Ambil foto" })).toBeVisible();
  await participantPage.getByRole("button", { name: "Batal" }).click();
  await participantPage
    .locator('.image-acquisition input[type="file"]')
    .setInputFiles(testImagePath);
  await expect(
    participantPage.getByRole("img", { name: "Pratinjau foto yang dipilih" }),
  ).toBeVisible();
  await participantContext.setOffline(true);
  await participantPage.getByRole("button", { name: "Kirim untuk diperiksa" }).click();
  await expect(participantPage.locator(".form-error-summary")).toContainText("offline");
  await participantContext.setOffline(false);
  await participantPage.getByRole("button", { name: "Kirim untuk diperiksa" }).click();
  await expect(
    participantPage.getByRole("heading", { name: "Menunggu pemeriksaan Admin" }),
  ).toBeVisible();

  const adminContext = await browser.newContext();
  await addSession(adminContext, administrator.email ?? "");
  const adminPage = await adminContext.newPage();
  await adminPage.goto(`/admin/pembayaran/${orderId}`);
  await expect(adminPage.getByRole("img", { name: "Bukti transfer privat" })).toBeVisible();
  const adminDecision = adminPage.locator(".payment-decision:visible");
  await adminDecision
    .getByRole("textbox", { name: "Referensi mutasi bank" })
    .fill("MUTASI-BROWSER-001");
  await adminDecision
    .getByRole("checkbox", {
      name: "Rekening tujuan pada mutasi cocok dengan snapshot pesanan",
    })
    .check();
  await adminDecision.getByRole("button", { name: "Setujui pembayaran" }).click();
  await adminDecision.getByRole("button", { name: "Konfirmasi dan aktifkan" }).click();
  await expect(adminPage.getByText("Terverifikasi", { exact: true })).toBeVisible();

  await participantPage.reload();
  await expect(
    participantPage.getByRole("heading", { name: "Pembayaran terverifikasi" }),
  ).toBeVisible();
  const enrollment = await adminClient
    .from("program_enrollments")
    .select("status")
    .eq("program_id", ids.program)
    .single();
  expect(enrollment.data?.status).toBe("active");
  await participantContext.close();
  await adminContext.close();
});

test("upload tanpa sesi ditolak sebelum membaca body", async ({ request }) => {
  const response = await request.post(`/api/payments/${orderId}/evidence`, {
    headers: { Origin: baseUrl },
    multipart: { idempotencyKey: "phase06-no-session" },
  });
  expect(response.status()).toBe(401);
  expect(response.headers()["cache-control"]).toContain("no-store");
});

test("Coach session expiry, rejection retry, lalu aktivasi", async ({ browser }) => {
  const applicantContext = await browser.newContext();
  await addSession(applicantContext, applicant.email ?? "");
  const applicantPage = await applicantContext.newPage();
  await applicantPage.goto(`/akses-coach/${ids.applicantApplication}`);
  await applicantPage.getByRole("button", { name: "Buat instruksi pembayaran" }).click();
  await expect(applicantPage).toHaveURL(/\/pembayaran\/[0-9a-f-]{36}$/);
  const coachOrderId = new URL(applicantPage.url()).pathname.split("/").at(-1) ?? "";
  createdOrderIds.push(coachOrderId);

  await applicantPage.getByRole("button", { name: "Gunakan kamera" }).click();
  await applicantPage.getByRole("button", { name: "Batal" }).click();
  await applicantPage.locator('.image-acquisition input[type="file"]').setInputFiles(testImagePath);
  await applicantContext.clearCookies();
  await applicantPage.getByRole("button", { name: "Kirim untuk diperiksa" }).click();
  await expect(applicantPage.locator(".form-error-summary")).toContainText(/masuk kembali/i);
  await addSession(applicantContext, applicant.email ?? "");
  await applicantPage.getByRole("button", { name: "Kirim untuk diperiksa" }).click();
  await expect(
    applicantPage.getByRole("heading", { name: "Menunggu pemeriksaan Admin" }),
  ).toBeVisible();

  const adminContext = await browser.newContext();
  await addSession(adminContext, administrator.email ?? "");
  const adminPage = await adminContext.newPage();
  await assertCoachQueueFilters(adminPage);
  await adminPage.goto(`/admin/pembayaran/${coachOrderId}`);
  let decision = adminPage.locator(".payment-decision:visible");
  await decision
    .getByRole("textbox", { name: "Alasan dan instruksi koreksi" })
    .fill("Referensi mutasi belum terlihat jelas. Unggah ulang.");
  await decision.getByRole("button", { name: "Tolak dan minta perbaikan" }).click();
  await expect(adminPage.getByText("Perlu perbaikan", { exact: true })).toBeVisible();

  await applicantPage.reload();
  await expect(
    applicantPage.locator(".payment-correction:visible").getByText(/Referensi mutasi belum/),
  ).toBeVisible();
  await applicantPage.getByRole("button", { name: "Gunakan kamera" }).click();
  await applicantPage.getByRole("button", { name: "Batal" }).click();
  await applicantPage.locator('.image-acquisition input[type="file"]').setInputFiles(testImagePath);
  await applicantPage.getByRole("button", { name: "Kirim untuk diperiksa" }).click();
  await expect(
    applicantPage.getByRole("heading", { name: "Menunggu pemeriksaan Admin" }),
  ).toBeVisible();

  await adminPage.reload();
  decision = adminPage.locator(".payment-decision:visible");
  await decision
    .getByRole("textbox", { name: "Referensi mutasi bank" })
    .fill("MUTASI-COACH-BROWSER-001");
  await decision.getByRole("checkbox").check();
  await decision.getByRole("button", { name: "Setujui pembayaran" }).click();
  await decision.getByRole("button", { name: "Konfirmasi dan aktifkan" }).click();
  await expect(adminPage.getByText("Terverifikasi", { exact: true })).toBeVisible();
  const profile = await adminClient
    .from("profiles")
    .select("role,coach_is_approved,coach_qr_identifier")
    .eq("user_id", applicant.id)
    .single();
  expect(profile.data?.role).toBe("coach");
  expect(profile.data?.coach_is_approved).toBe(true);
  expect(profile.data?.coach_qr_identifier).toBeTruthy();
  await applicantContext.close();
  await adminContext.close();
});
