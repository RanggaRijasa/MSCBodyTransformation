import { createClient, type SupabaseClient, type User } from "@supabase/supabase-js";
import { expect, test, type BrowserContext, type Page } from "@playwright/test";
import { renderSVG } from "uqr";

import { addSupabaseSession, createIdentity, must } from "./support/phase06-browser-fixture";
import { createCoachAccessFixture } from "./support/phase08-coach-fixture";
import {
  buildPhase10ProgramPayload,
  phase10CoachQr as coachQr,
  phase10Ids as ids,
} from "./support/phase10-program-payload";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const publishableKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
const serviceKey = process.env.SUPABASE_TEST_SERVICE_ROLE_KEY;
const baseUrl = "http://127.0.0.1:3000";
const password = "Phase10-browser-local-2026!";
const users: User[] = [];
let service: SupabaseClient;
let administrator: User;
let coach: User;
let participant: User;
let enrollmentId = "";
let orderId = "";

test.skip(!supabaseUrl || !publishableKey || !serviceKey, "Memerlukan Supabase lokal.");
test.describe.configure({ mode: "serial" });
test.setTimeout(120_000);

async function identity(label: string) {
  return createIdentity(service, users, password, `phase10-${label}`);
}

async function session(context: BrowserContext, user: User) {
  if (!supabaseUrl || !publishableKey || !user.email) throw new Error("Fixture Auth tidak ada.");
  await addSupabaseSession(context, {
    baseUrl,
    email: user.email,
    password,
    publishableKey,
    supabaseUrl,
  });
}

async function submitWeight(page: Page, stepId: string, weight: string) {
  await page.goto(`/program/${ids.program}/langkah/${stepId}`);
  await page.getByRole("textbox", { name: "Berat badan (kg)" }).fill(weight);
  await page.getByRole("button", { name: "Simpan berat" }).click();
  await expect(page.getByRole("heading", { name: "Tidak ada tindakan" })).toBeVisible();
  await page.waitForTimeout(500);
  await page.waitForLoadState("networkidle");
}

test.beforeAll(async () => {
  if (!supabaseUrl || !serviceKey || !publishableKey) return;
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
      .update({ ...active, display_name: "Admin Journey Phase 10", role: "admin" })
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
        display_name: "Coach Journey Phase 10",
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
        display_name: "Peserta Journey Phase 10",
        role: "participant",
      })
      .eq("user_id", participant.id),
    "profil Peserta",
  );
  await createCoachAccessFixture(service, administrator, {
    applicationId: ids.application,
    coach,
    displayName: "Coach Journey Phase 10",
    endsAt: new Date(Date.now() + 90 * 86_400_000).toISOString(),
    entitlementId: ids.coachEntitlement,
    paymentId: ids.coachPayment,
    status: "active",
  });
  await must(
    service.from("payment_destinations").insert({
      account_name: "MSC Lokal Phase 10",
      account_reference: "1010101010",
      bank_code: "BCA",
      bank_name: "Bank Central Asia",
      created_by: administrator.id,
      effective_from: new Date().toISOString(),
      id: ids.destination,
      status: "active",
      version: Math.floor(Date.now() / 1000),
    }),
    "tujuan pembayaran",
  );

  const today = new Intl.DateTimeFormat("en-CA", {
    day: "2-digit",
    month: "2-digit",
    timeZone: "Asia/Makassar",
    year: "numeric",
  }).format(new Date());
  const tomorrow = new Intl.DateTimeFormat("en-CA", {
    day: "2-digit",
    month: "2-digit",
    timeZone: "Asia/Makassar",
    year: "numeric",
  }).format(new Date(Date.now() + 86_400_000));
  const adminClient = createClient(supabaseUrl, publishableKey, {
    auth: { persistSession: false },
  });
  await must(
    adminClient.auth.signInWithPassword({ email: administrator.email ?? "", password }),
    "login Admin RPC",
  );
  await must(
    adminClient.rpc("save_program_draft", {
      program_payload: buildPhase10ProgramPayload(today, tomorrow),
      request_idempotency_key: `phase10-draft-${crypto.randomUUID()}`,
    }),
    "draft program",
  );
});

test.afterAll(async () => {
  if (!service) return;
  if (orderId) {
    const evidence = await service
      .from("payment_evidence_attempts")
      .select("object_path")
      .eq("order_id", orderId);
    const evidencePaths = (evidence.data ?? []).map(({ object_path }) => object_path);
    if (evidencePaths.length) await service.storage.from("payment-evidence").remove(evidencePaths);
  }
  const posters = await service
    .from("winner_posters")
    .select("media_path")
    .eq("program_id", ids.program);
  const paths = (posters.data ?? []).map(({ media_path }) => media_path);
  if (paths.length) await service.storage.from("public-media").remove(paths);
  if (enrollmentId) {
    const questionPhotos = await service
      .from("step_submission_answers")
      .select("private_photo_path")
      .like("private_photo_path", `${participant.id}/${enrollmentId}/%`);
    const questionPhotoPaths = (questionPhotos.data ?? [])
      .map(({ private_photo_path }) => private_photo_path)
      .filter((path): path is string => typeof path === "string");
    if (questionPhotoPaths.length) {
      await service.storage.from("question-photos").remove(questionPhotoPaths);
    }
  }
  await service.from("winner_posters").delete().eq("program_id", ids.program);
  await service.from("winner_snapshots").delete().eq("program_id", ids.program);
  await service.from("program_enrollments").delete().eq("program_id", ids.program);
  await service.from("programs").delete().eq("id", ids.program);
  await service.from("payment_destinations").delete().eq("id", ids.destination);
  await service.from("coach_access_entitlements").delete().eq("id", ids.coachEntitlement);
  await service.from("coach_payment_records").delete().eq("id", ids.coachPayment);
  await service.from("coach_applications").delete().eq("id", ids.application);
  for (const user of [...users].reverse()) await service.auth.admin.deleteUser(user.id);
});

test("journey Admin → Peserta → Coach → scoring → closure → winner → poster", async ({
  browser,
  context,
  page,
}) => {
  await session(context, administrator);
  await page.goto(`/admin/program/${ids.program}`);
  await expect(page.getByRole("heading", { name: "Program Cross-role Phase 10" })).toBeVisible();
  expect(await page.locator(".admin-validation-list li").allTextContents()).toEqual([]);
  await page.getByRole("button", { name: "Terbitkan program" }).click();
  await expect
    .poll(
      async () =>
        (await service.from("programs").select("status").eq("id", ids.program).single()).data
          ?.status,
    )
    .toBe("active");

  const participantContext = await browser.newContext({ baseURL: baseUrl });
  await session(participantContext, participant);
  const participantPage = await participantContext.newPage();
  const svg = renderSVG(`${baseUrl}/gabung/coach/${coachQr}`, { border: 4, ecc: "M" });
  await participantPage.setContent(`<div style="width:320px;height:320px">${svg}</div>`);
  const qrImage = await participantPage.locator("svg").screenshot({ type: "png" });
  await participantPage.goto(`/program/${ids.program}/gabung`);
  await participantPage.getByRole("button", { name: "Pindai QR Coach" }).click();
  await participantPage
    .locator('dialog[open] .qr-scanner__file-action input[type="file"]')
    .setInputFiles({
      buffer: qrImage,
      mimeType: "image/png",
      name: "coach-phase10.png",
    });
  await expect(
    participantPage.getByRole("heading", { name: "Coach Journey Phase 10" }),
  ).toBeVisible();
  await participantPage.getByRole("button", { name: "Lanjut ke pembayaran" }).click();
  await expect(participantPage).toHaveURL(/\/pembayaran\/[0-9a-f-]{36}$/);
  orderId = new URL(participantPage.url()).pathname.split("/").at(-1) ?? "";
  await participantPage.locator('.image-acquisition input[type="file"]').first().setInputFiles({
    buffer: qrImage,
    mimeType: "image/png",
    name: "bukti-transfer-phase10.png",
  });
  await participantPage.getByRole("button", { name: "Kirim untuk diperiksa" }).click();
  await expect(
    participantPage.getByRole("heading", { name: "Menunggu pemeriksaan Admin" }),
  ).toBeVisible();

  await page.goto(`/admin/pembayaran/${orderId}`);
  await page.waitForLoadState("networkidle");
  const paymentDecision = page.locator(".payment-decision:visible");
  const reconciliationReference = paymentDecision.getByRole("textbox", {
    name: "Referensi mutasi bank",
  });
  const destinationConfirmation = paymentDecision.getByRole("checkbox", {
    name: "Rekening tujuan pada mutasi cocok dengan snapshot pesanan",
  });
  const approvePayment = paymentDecision.getByRole("button", { name: "Setujui pembayaran" });
  await reconciliationReference.fill("MUTASI-PHASE10");
  await expect(reconciliationReference).toHaveValue("MUTASI-PHASE10");
  await destinationConfirmation.check();
  await expect(destinationConfirmation).toBeChecked();
  await expect(approvePayment).toBeEnabled();
  await approvePayment.click();
  await paymentDecision.getByRole("button", { name: "Konfirmasi dan aktifkan" }).click();
  await expect(page.getByText("Terverifikasi", { exact: true })).toBeVisible();
  await participantPage.reload();
  await expect(
    participantPage.getByRole("heading", { name: "Pembayaran terverifikasi" }),
  ).toBeVisible();
  const enrollment = await must(
    service
      .from("program_enrollments")
      .select("id")
      .eq("program_id", ids.program)
      .eq("participant_id", participant.id)
      .single(),
    "enrollment",
  );
  enrollmentId = enrollment.data?.id ?? "";
  expect(enrollmentId).not.toBe("");

  await submitWeight(participantPage, ids.initialStep, "75,00");
  await participantPage.goto(`/program/${ids.program}/langkah/${ids.articleStep}`);
  await participantPage.getByRole("button", { name: "Kirim aktivitas" }).click();
  await expect
    .poll(
      async () =>
        (
          await service
            .from("step_submissions")
            .select("status")
            .eq("enrollment_id", enrollmentId)
            .eq("step_id", ids.articleStep)
            .single()
        ).data?.status,
    )
    .toBe("approved");
  await participantPage.waitForTimeout(500);
  await participantPage.waitForLoadState("networkidle");
  await participantPage.goto(`/program/${ids.program}/langkah/${ids.formStep}`);
  await participantPage
    .getByRole("textbox", { name: "Apa fokusmu hari ini?" })
    .fill("Konsisten bergerak.");
  await participantPage.locator('.image-acquisition input[type="file"]').first().setInputFiles({
    buffer: qrImage,
    mimeType: "image/png",
    name: "bukti-aktivitas-phase10.png",
  });
  await participantPage.getByRole("button", { name: "Kirim aktivitas" }).click();
  await expect(
    participantPage.getByText("Menunggu pemeriksaan Coach", { exact: true }).first(),
  ).toBeVisible();
  await expect
    .poll(async () => {
      const submission = await service
        .from("step_submissions")
        .select("id,status,step_submission_answers(private_photo_path)")
        .eq("enrollment_id", enrollmentId)
        .eq("step_id", ids.formStep)
        .single();
      const answers = submission.data?.step_submission_answers ?? [];
      return {
        hasPrivatePhoto: answers.some(({ private_photo_path }) => Boolean(private_photo_path)),
        status: submission.data?.status,
      };
    })
    .toEqual({ hasPrivatePhoto: true, status: "pending" });
  await participantPage.waitForTimeout(500);
  await participantPage.waitForLoadState("networkidle");
  await participantPage.goto(`/program/${ids.program}/langkah/${ids.quizStep}`);
  await participantPage.getByRole("radio", { name: "Semua sekaligus" }).check();
  await participantPage.getByRole("button", { name: "Kirim kuis" }).click();
  await expect(participantPage.getByText("Belum lulus", { exact: true })).toBeVisible();
  await participantPage.waitForTimeout(500);
  await participantPage.waitForLoadState("networkidle");
  await submitWeight(participantPage, ids.dailyStep, "60,00");
  await submitWeight(participantPage, ids.finalStep, "73,50");

  const coachContext = await browser.newContext({ baseURL: baseUrl });
  await session(coachContext, coach);
  const coachPage = await coachContext.newPage();
  await coachPage.goto("/coach-area/pemeriksaan");
  await expect(coachPage.getByRole("heading", { name: "Peserta Journey Phase 10" })).toBeVisible();
  await coachPage.getByRole("button", { name: "Setujui" }).click();
  await expect(coachPage.getByText(/Skor direkonsiliasi/)).toBeVisible();

  await page.goto(`/admin/program/${ids.program}`);
  const closure = page.getByRole("region", { name: "Prasyarat penutupan" });
  await expect(closure.getByText("Kuis belum lulus")).toBeVisible();
  await expect(page.getByRole("button", { name: "Selesaikan program" })).toBeDisabled();
  await closure.getByLabel("Alasan membuka kuis").fill("Berikan kesempatan remediasi terkontrol.");
  await closure.getByRole("button", { name: "Buka percobaan baru" }).click();
  await expect
    .poll(
      async () =>
        (
          await service
            .from("step_submissions")
            .select("status")
            .eq("enrollment_id", enrollmentId)
            .eq("step_id", ids.quizStep)
            .order("attempt_sequence", { ascending: false })
            .limit(1)
            .single()
        ).data?.status,
    )
    .toBe("rejected");

  await participantPage.goto(`/program/${ids.program}/langkah/${ids.quizStep}`);
  await participantPage.getByRole("radio", { name: "Konsisten dan bertahap" }).check();
  await participantPage.getByRole("button", { name: "Kirim kuis" }).click();
  await expect(participantPage.getByText("Lulus", { exact: true })).toBeVisible();
  await participantPage.waitForTimeout(500);
  await participantPage.waitForLoadState("networkidle");

  await page.goto("/admin/orang");
  await page.getByText("Operasi koreksi terkontrol").click();
  await page.getByLabel("Enrollment").selectOption(enrollmentId);
  await page.getByPlaceholder("Poin +/-").fill("5");
  await page.getByPlaceholder("Alasan penyesuaian").fill("Koreksi hasil rekonsiliasi final.");
  await page.getByRole("button", { name: "Sesuaikan poin" }).click();
  await expect
    .poll(
      async () =>
        (
          await service
            .from("program_scores")
            .select("activity_points,quiz_points,weight_points,adjustment_points")
            .eq("enrollment_id", enrollmentId)
            .single()
        ).data,
    )
    .toEqual({ activity_points: 20, adjustment_points: 5, quiz_points: 10, weight_points: 150 });

  await page.goto(`/admin/program/${ids.program}`);
  await expect(
    page.getByRole("region", { name: "Prasyarat penutupan" }).getByText("Siap ditutup"),
  ).toBeVisible();
  await page
    .getByLabel("Alasan penyelesaian")
    .first()
    .fill("Seluruh prasyarat journey sudah selesai.");
  await page.getByRole("button", { name: "Selesaikan program" }).click();
  await expect
    .poll(
      async () =>
        (await service.from("programs").select("status").eq("id", ids.program).single()).data
          ?.status,
    )
    .toBe("completed");
  await page.reload();
  await page.getByRole("button", { name: "Kunci pemenang" }).click();
  const snapshotId = await expect
    .poll(async () => {
      const result = await service
        .from("winner_snapshots")
        .select("id")
        .eq("program_id", ids.program)
        .maybeSingle();
      return result.data?.id ?? "";
    })
    .not.toBe("");
  void snapshotId;
  const snapshot = await service
    .from("winner_snapshots")
    .select("id")
    .eq("program_id", ids.program)
    .single();

  await page.setContent(
    '<div style="width:450px;height:800px;background:#111;color:#fff;display:grid;place-items:center;font:700 36px sans-serif">Pemenang MSC</div>',
  );
  const poster = await page.locator("body > div").screenshot({ type: "png" });
  await page.goto("/admin/konten#tambah-poster");
  await page.getByLabel("Snapshot pemenang").selectOption(snapshot.data?.id ?? "");
  await page.locator('#tambah-poster input[type="file"]').setInputFiles({
    buffer: poster,
    mimeType: "image/png",
    name: "poster-phase10.png",
  });
  await page.getByLabel("Teks alternatif").fill("Poster pemenang Program Cross-role Phase 10");
  await page.getByLabel("Alasan").fill("Journey final telah diperiksa.");
  await page.getByRole("button", { name: "Simpan sebagai draft" }).click();
  await expect
    .poll(
      async () =>
        (await service.from("winner_posters").select("id").eq("program_id", ids.program)).data
          ?.length,
    )
    .toBe(1);
  await page.reload();
  await page.getByRole("button", { name: "Terbitkan poster" }).click();

  await participantPage.goto(`/peringkat?program=${ids.program}`);
  await expect(participantPage.getByText("185 poin").first()).toBeVisible();
  await expect(participantPage.getByRole("heading", { name: "Hasil yang dikunci" })).toBeVisible();
  await expect(participantPage.getByText(/\bkg\b/i)).toHaveCount(0);
  await coachPage.goto(`/coach-area/program?program=${ids.program}`);
  await expect(coachPage.getByText("185 poin").first()).toBeVisible();
  await expect(coachPage.getByText(/\bkg\b/i)).toHaveCount(0);
  await expect(coachPage.getByRole("img", { name: /bukti/i })).toHaveCount(0);

  const guestContext = await browser.newContext({ baseURL: baseUrl });
  const guestPage = await guestContext.newPage();
  await guestPage.goto(`/program/${ids.program}`);
  await expect(
    guestPage.getByRole("heading", { name: "Program Cross-role Phase 10" }),
  ).toBeVisible();
  await expect(guestPage.getByText(/Peserta Journey|73[,.]5|Konsisten bergerak/i)).toHaveCount(0);
  await guestContext.close();
  await coachContext.close();
  await participantContext.close();
});
