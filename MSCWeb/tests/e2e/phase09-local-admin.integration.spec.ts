import { createClient, type SupabaseClient, type User } from "@supabase/supabase-js";
import { expect, test, type BrowserContext } from "@playwright/test";

import { addSupabaseSession, createIdentity, must } from "./support/phase06-browser-fixture";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const publishableKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
const serviceKey = process.env.SUPABASE_TEST_SERVICE_ROLE_KEY;
const baseUrl = "http://127.0.0.1:3000";
const password = "Phase09-browser-local-2026!";
const title = `Program Admin Browser ${crypto.randomUUID().slice(0, 8)}`;
const ids = {
  application: crypto.randomUUID(),
  destination: crypto.randomUUID(),
  enrollment: crypto.randomUUID(),
};
let service: SupabaseClient;
let administrator: User;
let applicant: User;
let participant: User;
let programId = "";
const users: User[] = [];

test.skip(!supabaseUrl || !publishableKey || !serviceKey, "Memerlukan Supabase lokal.");
test.describe.configure({ mode: "serial" });
test.setTimeout(90_000);

async function identity(label: string) {
  return createIdentity(service, users, password, `phase09-${label}`);
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

async function waitForProgramStatus(status: string) {
  await expect
    .poll(async () => {
      if (!programId) {
        const result = await service
          .from("programs")
          .select("id,status")
          .eq("title", title)
          .maybeSingle();
        programId = result.data?.id ?? "";
        return result.data?.status;
      }
      const result = await service.from("programs").select("status").eq("id", programId).single();
      return result.data?.status;
    })
    .toBe(status);
}

test.beforeAll(async () => {
  if (!supabaseUrl || !serviceKey) return;
  expect(new URL(supabaseUrl).hostname).toMatch(/^(127\.0\.0\.1|localhost)$/);
  service = createClient(supabaseUrl, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  administrator = await identity("admin");
  applicant = await identity("applicant");
  participant = await identity("participant");
  const active = {
    finalized_at: new Date().toISOString(),
    onboarding_status: "active",
    provisional_expires_at: null,
  };
  await must(
    service
      .from("profiles")
      .update({ ...active, display_name: "Admin Browser Phase 09", role: "admin" })
      .eq("user_id", administrator.id),
    "profil Admin",
  );
  await must(
    service
      .from("profiles")
      .update({
        ...active,
        display_name: "Calon Coach Browser Phase 09",
        member_level: "sc",
        role: "participant",
      })
      .eq("user_id", applicant.id),
    "profil calon Coach",
  );
  await must(
    service
      .from("profiles")
      .update({ ...active, display_name: "Peserta Browser Phase 09", role: "participant" })
      .eq("user_id", participant.id),
    "profil Peserta",
  );
  await must(
    service.from("coach_applications").insert({
      applicant_user_id: applicant.id,
      display_name_snapshot: "Calon Coach Browser Phase 09",
      draft_idempotency_key: `phase09-${crypto.randomUUID()}`,
      has_completed_hom_sts: true,
      has_completed_ict: true,
      id: ids.application,
      member_level_snapshot: "sc",
      participant_profile_id: applicant.id,
      phone_number_snapshot: "+628900000009",
      status: "submitted",
      submitted_at: new Date().toISOString(),
      terms_version: "phase09-local",
    }),
    "pengajuan Coach",
  );
  await must(
    service.from("payment_destinations").insert({
      account_name: "MSC Lokal Phase 09",
      account_reference: "9000000009",
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
});

test.afterAll(async () => {
  if (!service) return;
  if (programId) {
    const posterMedia = await service
      .from("winner_posters")
      .select("media_path")
      .eq("program_id", programId);
    const posterPaths = (posterMedia.data ?? []).map((item) => item.media_path);
    if (posterPaths.length) await service.storage.from("public-media").remove(posterPaths);
    await service.from("winner_posters").delete().eq("program_id", programId);
    await service.from("winner_snapshots").delete().eq("program_id", programId);
    await service.from("program_enrollments").delete().eq("program_id", programId);
    await service.from("programs").delete().eq("id", programId);
  }
  await service.from("payment_destinations").delete().eq("id", ids.destination);
  await service.from("coach_applications").delete().eq("id", ids.application);
  for (const user of [...users].reverse()) await service.auth.admin.deleteUser(user.id);
});

test("Admin membuat draft, menyusun konten, menerbitkan, menutup, dan mengelola poster", async ({
  context,
  page,
}) => {
  await session(context, administrator);
  await page.goto("/admin");
  await expect(page.getByRole("heading", { name: "Dashboard Admin" })).toBeVisible();
  await page.getByRole("link", { name: "Buat program" }).click();
  await page.getByLabel("Judul").fill(title);
  await page.getByRole("tab", { name: "Hari dan konten" }).click();
  await page.getByRole("button", { name: "Tambah langkah" }).click();
  await page.getByLabel("Judul langkah").fill("Aktivitas pembuka");
  await page.getByLabel("Petunjuk").fill("Baca panduan lalu tandai selesai.");
  await page.getByRole("button", { name: "Simpan draft" }).click();
  await expect(page.getByRole("heading", { name: title })).toBeVisible();
  await waitForProgramStatus("draft");
  await page.getByRole("button", { name: "Terbitkan program" }).click();
  await waitForProgramStatus("active");

  await must(
    service.from("program_enrollments").insert({
      coach_id: administrator.id,
      id: ids.enrollment,
      participant_id: participant.id,
      program_id: programId,
      status: "active",
    }),
    "enrollment koreksi",
  );
  await must(
    service.from("program_scores").insert({ enrollment_id: ids.enrollment }),
    "skor koreksi",
  );
  const programDay = await must(
    service.from("program_days").select("id").eq("program_id", programId).single(),
    "hari program",
  );
  const programStep = await must(
    service
      .from("program_steps")
      .select("id")
      .eq("program_day_id", programDay.data?.id ?? "")
      .single(),
    "langkah program",
  );
  await must(
    service.from("step_submissions").insert({
      attempt_sequence: 1,
      enrollment_id: ids.enrollment,
      finalized_at: new Date().toISOString(),
      idempotency_key: `phase09-submission-${crypto.randomUUID()}`,
      status: "approved",
      step_id: programStep.data?.id,
      submitted_at: new Date().toISOString(),
    }),
    "aktivitas selesai",
  );

  await page.goto("/admin/orang");
  await page.getByText("Operasi koreksi terkontrol").click();
  await page.getByLabel("Enrollment").selectOption(ids.enrollment);
  await page.getByPlaceholder("Poin +/-").fill("7");
  await page.getByPlaceholder("Alasan penyesuaian").fill("Koreksi hasil verifikasi operasional.");
  await page.getByRole("button", { name: "Sesuaikan poin" }).click();
  await expect
    .poll(
      async () =>
        (
          await service
            .from("program_scores")
            .select("adjustment_points")
            .eq("enrollment_id", ids.enrollment)
            .single()
        ).data?.adjustment_points,
    )
    .toBe(7);

  await page.goto(`/admin/program/${programId}`);
  await page.getByLabel("Alasan penyelesaian").fill("Seluruh kegiatan program telah berakhir.");
  await page.getByRole("button", { name: "Selesaikan program" }).click();
  await waitForProgramStatus("completed");
  await page.reload();
  await page.getByRole("button", { name: "Kunci pemenang" }).click();
  const snapshot = await expect
    .poll(async () => {
      const result = await service
        .from("winner_snapshots")
        .select("id")
        .eq("program_id", programId)
        .maybeSingle();
      return result.data?.id ?? "";
    })
    .not.toBe("");
  void snapshot;
  const snapshotResult = await service
    .from("winner_snapshots")
    .select("id")
    .eq("program_id", programId)
    .single();
  const snapshotId = snapshotResult.data?.id as string;

  await page.setContent(
    '<div style="width:450px;height:800px;background:#111;display:grid;place-items:center;color:#fff;font:700 36px sans-serif">Pemenang MSC</div>',
  );
  const posterImage = await page.locator("body > div").screenshot({ type: "png" });
  await page.goto("/admin/konten#tambah-poster");
  await page.getByLabel("Snapshot pemenang").selectOption(snapshotId);
  await page.locator('#tambah-poster input[type="file"]').setInputFiles({
    buffer: posterImage,
    mimeType: "image/png",
    name: "poster-9x16.png",
  });
  await expect(
    page.locator("#tambah-poster").getByRole("img", { name: "Pratinjau foto yang dipilih" }),
  ).toBeVisible();
  await page.getByLabel("Teks alternatif").fill("Poster pemenang program browser Phase 09");
  await page.getByLabel("Alasan").fill("Poster sudah melalui pemeriksaan Admin.");
  await page.getByRole("button", { name: "Simpan sebagai draft" }).click();
  await expect
    .poll(
      async () =>
        (await service.from("winner_posters").select("id").eq("program_id", programId)).data
          ?.length,
    )
    .toBe(1);
  await page.reload();
  await page.getByRole("button", { name: "Terbitkan poster" }).click();
  await expect
    .poll(
      async () =>
        (
          await service
            .from("winner_posters")
            .select("is_published")
            .eq("program_id", programId)
            .single()
        ).data?.is_published,
    )
    .toBe(true);
});

test("Admin memutus pengajuan dan melihat pembayaran versi aman", async ({ context, page }) => {
  await session(context, administrator);
  await page.goto("/admin/orang?bagian=pengajuan");
  const applications = page.locator("#pengajuan");
  await expect(
    applications.getByRole("heading", { name: "Calon Coach Browser Phase 09" }),
  ).toBeVisible();
  await applications.getByRole("button", { name: "Terima kelayakan" }).click();
  await expect
    .poll(
      async () =>
        (
          await service
            .from("coach_applications")
            .select("status")
            .eq("id", ids.application)
            .single()
        ).data?.status,
    )
    .toBe("accepted_pending_payment");
  await page.goto("/admin/pembayaran");
  await expect(page.getByRole("heading", { name: "Pembayaran" })).toBeVisible();
  await page.locator("details.payment-destinations > summary").first().click();
  await expect(page.getByText("MSC Lokal Phase 09")).toBeVisible();
});

test("non-Admin gagal tertutup tanpa melihat resource Admin", async ({ context, page }) => {
  await session(context, participant);
  await page.goto("/admin");
  await expect(page).toHaveURL(/\/hari-ini$/);
  await expect(page.getByRole("heading", { name: "Dashboard Admin" })).toHaveCount(0);
  const upload = await page.request.post("/api/admin/content/posters", {
    multipart: { operation: "add" },
  });
  expect(upload.status()).toBe(403);
});
