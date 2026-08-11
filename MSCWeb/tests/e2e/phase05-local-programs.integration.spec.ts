import { createServerClient } from "@supabase/ssr";
import { createClient, type SupabaseClient, type User } from "@supabase/supabase-js";
import { expect, test, type BrowserContext } from "@playwright/test";
import { execFileSync } from "node:child_process";
import { renderSVG } from "uqr";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const publishableKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
const serviceRoleKey = process.env.SUPABASE_TEST_SERVICE_ROLE_KEY;
const databaseUrl = process.env.DB_URL;
const baseUrl = "http://127.0.0.1:3000";
const password = "Phase05-browser-local-2026!";

test.skip(
  !supabaseUrl || !publishableKey || !serviceRoleKey || !databaseUrl,
  "Memerlukan credential runtime Supabase lokal.",
);
test.describe.configure({ mode: "serial" });

const ids = {
  coachApplications: [crypto.randomUUID(), crypto.randomUUID()] as const,
  coachEntitlements: [crypto.randomUUID(), crypto.randomUUID()] as const,
  coachPayments: [crypto.randomUUID(), crypto.randomUUID()] as const,
  programs: [
    crypto.randomUUID(),
    crypto.randomUUID(),
    crypto.randomUUID(),
    crypto.randomUUID(),
  ] as const,
};
const coachQr = ["phase05_browser_coach_one", "phase05_browser_coach_two"] as const;
const paymentDestinationId = crypto.randomUUID();
let admin: SupabaseClient;
let users: User[] = [];

function programRow(
  id: string,
  creator: string,
  title: string,
  extras: Record<string, unknown> = {},
) {
  return {
    created_by: creator,
    duration_mode: "fixed_duration",
    ends_on: "2026-08-31",
    future_step_policy: "locked",
    id,
    pace: "scheduled",
    past_step_policy: "available",
    points_per_activity: 10,
    points_per_weight_kg: 100,
    pricing_mode: "free",
    published_at: new Date().toISOString(),
    quiz_passing_percentage: 70,
    starts_on: "2026-08-01",
    status: "active",
    summary: "Program deterministic untuk browser lokal.",
    timezone: "Asia/Makassar",
    title,
    wellness_disclaimer: "Program kebugaran non-diagnostik.",
    ...extras,
  };
}

async function createIdentity(label: string) {
  const email = `phase05-browser-${label}-${crypto.randomUUID()}@local.invalid`;
  const { data, error } = await admin.auth.admin.createUser({
    email,
    email_confirm: true,
    password,
  });
  if (error || !data.user) throw error ?? new Error(`Identity ${label} tidak dibuat.`);
  users.push(data.user);
  return data.user;
}

async function addSession(context: BrowserContext, email: string) {
  if (!supabaseUrl || !publishableKey) throw new Error("Supabase lokal tidak tersedia.");
  const cookieJar = new Map<string, string>();
  const auth = createServerClient(supabaseUrl, publishableKey, {
    cookies: {
      getAll: () => [...cookieJar].map(([name, value]) => ({ name, value })),
      setAll: (values) => {
        for (const { name, value } of values) cookieJar.set(name, value);
      },
    },
  });
  const { error } = await auth.auth.signInWithPassword({ email, password });
  if (error) throw error;
  await context.addCookies([...cookieJar].map(([name, value]) => ({ name, value, url: baseUrl })));
}

test.beforeAll(async () => {
  if (!supabaseUrl || !serviceRoleKey) return;
  expect(new URL(supabaseUrl).hostname).toMatch(/^(127\.0\.0\.1|localhost)$/);
  admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const administrator = await createIdentity("admin");
  const coaches = [await createIdentity("coach-one"), await createIdentity("coach-two")];
  const participant = await createIdentity("participant");
  const activeShape = {
    finalized_at: new Date().toISOString(),
    onboarding_status: "active",
    provisional_expires_at: null,
  };
  await admin
    .from("profiles")
    .update({ ...activeShape, role: "admin" })
    .eq("user_id", administrator.id);
  for (const [index, coach] of coaches.entries()) {
    await admin
      .from("profiles")
      .update({
        ...activeShape,
        coach_is_approved: true,
        coach_qr_identifier: coachQr[index],
        display_name: `Coach Browser ${index + 1}`,
        role: "coach",
      })
      .eq("user_id", coach.id);
    await admin.from("coach_applications").insert({
      applicant_user_id: coach.id,
      decided_at: new Date().toISOString(),
      decided_by: administrator.id,
      display_name_snapshot: `Coach Browser ${index + 1}`,
      draft_idempotency_key: `phase05-browser-${index}-${crypto.randomUUID()}`,
      has_completed_hom_sts: true,
      has_completed_ict: true,
      id: ids.coachApplications[index],
      member_level_snapshot: "sc",
      participant_profile_id: coach.id,
      phone_number_snapshot: `+62810000001${index}`,
      status: "active",
      submitted_at: new Date().toISOString(),
      terms_version: "phase05-local",
    });
    await admin.from("coach_payment_records").insert({
      amount_minor_units: 100_000,
      application_id: ids.coachApplications[index],
      id: ids.coachPayments[index],
      price_band: "entry",
      provider_reference: `phase05-browser-${index}-${crypto.randomUUID()}`,
      state: "verified",
      verified_at: new Date().toISOString(),
    });
    await admin.from("coach_access_entitlements").insert({
      application_id: ids.coachApplications[index],
      coach_user_id: coach.id,
      ends_at: new Date(Date.now() + 30 * 86_400_000).toISOString(),
      id: ids.coachEntitlements[index],
      payment_record_id: ids.coachPayments[index],
      starts_at: new Date(Date.now() - 86_400_000).toISOString(),
      status: "active",
    });
  }
  await admin
    .from("profiles")
    .update({ ...activeShape, display_name: "Peserta Browser", role: "participant" })
    .eq("user_id", participant.id);
  await admin.from("programs").insert([
    programRow(ids.programs[0], administrator.id, "Program Browser Gratis"),
    programRow(ids.programs[1], administrator.id, "Program Coach Berbeda"),
    programRow(ids.programs[2], administrator.id, "Program Sudah Ditutup", {
      registration_closes_at: new Date(Date.now() - 60_000).toISOString(),
    }),
    programRow(ids.programs[3], administrator.id, "Program Browser Berbayar", {
      desired_price: 250_000,
      pricing_mode: "paid",
    }),
  ]);
  await admin.from("payment_destinations").insert({
    account_name: "MSC Browser Lokal",
    account_reference: "1234567890",
    bank_code: "BCA",
    bank_name: "Bank Central Asia",
    created_by: administrator.id,
    effective_from: new Date().toISOString(),
    id: paymentDestinationId,
    status: "active",
    version: Math.floor(Date.now() / 1000),
  });
});

test.afterAll(async () => {
  if (!admin) return;
  if (databaseUrl) {
    expect(new URL(databaseUrl).hostname).toMatch(/^(127\.0\.0\.1|localhost)$/);
    const programIds = ids.programs.map((id) => `'${id}'`).join(",");
    execFileSync("/opt/homebrew/opt/postgresql@16/bin/psql", [
      "-X",
      "-w",
      "-v",
      "ON_ERROR_STOP=1",
      "-d",
      databaseUrl,
      "-c",
      `begin;
       alter table public.payment_events disable trigger payment_events_no_update_or_delete;
       delete from public.payment_events where order_id in (select id from public.payment_orders where program_id in (${programIds}));
       delete from public.payment_evidence_attempts where order_id in (select id from public.payment_orders where program_id in (${programIds}));
       delete from public.payment_orders where program_id in (${programIds});
       alter table public.payment_events enable trigger payment_events_no_update_or_delete;
       commit;`,
    ]);
  }
  const { data: enrollments } = await admin
    .from("program_enrollments")
    .select("id")
    .in("program_id", ids.programs);
  const enrollmentIds = (enrollments ?? []).map(({ id }) => id);
  if (enrollmentIds.length > 0) {
    await admin.from("program_scores").delete().in("enrollment_id", enrollmentIds);
  }
  await admin.from("program_enrollments").delete().in("program_id", ids.programs);
  await admin.from("programs").delete().in("id", ids.programs);
  await admin.from("payment_destinations").delete().eq("id", paymentDestinationId);
  await admin.from("coach_access_entitlements").delete().in("id", ids.coachEntitlements);
  await admin.from("coach_payment_records").delete().in("id", ids.coachPayments);
  await admin.from("coach_applications").delete().in("id", ids.coachApplications);
  await admin
    .from("audit_events")
    .delete()
    .in(
      "actor_id",
      users.map(({ id }) => id),
    );
  for (const user of [...users].reverse()) await admin.auth.admin.deleteUser(user.id);
  users = [];
});

test("Guest melihat katalog publik, closed detail, dan intent login HttpOnly", async ({ page }) => {
  await page.goto("/program");
  await expect(page.getByRole("heading", { name: "Temukan program transformasimu" })).toBeVisible();
  await expect(page.getByText("Program Browser Gratis")).toBeVisible();
  await page.goto(`/program/${ids.programs[2]}`);
  await expect(page.getByText("Pendaftaran program ini sudah ditutup.")).toBeVisible();
  await expect(page.getByRole("button", { name: /daftar/i })).toHaveCount(0);

  await page.goto(`/program/${ids.programs[0]}`);
  await page.getByRole("button", { name: "Masuk untuk mendaftar" }).click();
  await expect(page).toHaveURL(new RegExp(`/masuk\\?returnTo=%2Fprogram%2F${ids.programs[0]}`));
  const pendingCookie = (await page.context().cookies()).find(
    ({ name }) => name === "msc_pending_program",
  );
  expect(pendingCookie?.httpOnly).toBe(true);
});

test("Peserta memindai QR visual, enroll gratis idempoten, dan mode berubah ke aktivitas", async ({
  context,
  page,
}) => {
  const participant = users.at(-1);
  if (!participant?.email) throw new Error("Fixture Participant tidak tersedia.");
  await addSession(context, participant.email);
  const svg = renderSVG(`${baseUrl}/gabung/coach/${coachQr[0]}`, { border: 4, ecc: "M" });
  await page.setContent(`<div style="width:320px;height:320px">${svg}</div>`);
  const png = await page.locator("svg").screenshot({ type: "png" });

  await page.goto(`/program/${ids.programs[0]}/gabung`);
  await page.getByRole("button", { name: "Pindai QR Coach" }).click();
  await page.locator('.qr-scanner__file-action input[type="file"]').setInputFiles({
    buffer: png,
    mimeType: "image/png",
    name: "coach-phase05.png",
  });
  await expect(page.getByRole("heading", { name: "Coach Browser 1" })).toBeVisible();
  await page.getByRole("button", { name: "Konfirmasi pendaftaran" }).click();
  await expect(page).toHaveURL(new RegExp(`/program/${ids.programs[0]}$`));
  await expect(page.getByRole("link", { name: "Buka aktivitas program" })).toBeVisible();

  const duplicate = await context.request.post(`/api/programs/${ids.programs[0]}/enroll/free`, {
    data: { coachQrPayload: coachQr[0] },
    headers: { Origin: baseUrl },
  });
  expect(duplicate.status()).toBe(200);
});

test("same-Coach guard menolak QR Coach berbeda dengan copy aman", async ({ context, page }) => {
  const participant = users.at(-1);
  if (!participant?.email) throw new Error("Fixture Participant tidak tersedia.");
  await addSession(context, participant.email);
  const svg = renderSVG(`${baseUrl}/gabung/coach/${coachQr[1]}`, { border: 4, ecc: "M" });
  await page.setContent(`<div style="width:320px;height:320px">${svg}</div>`);
  const png = await page.locator("svg").screenshot({ type: "png" });

  await page.goto(`/program/${ids.programs[1]}/gabung`);
  await page.getByRole("button", { name: "Pindai QR Coach" }).click();
  await page.locator('.qr-scanner__file-action input[type="file"]').setInputFiles({
    buffer: png,
    mimeType: "image/png",
    name: "coach-mismatch.png",
  });
  const enrollmentError = page.locator(".form-error-summary");
  await expect(enrollmentError).toContainText("Coach yang berbeda");
  await expect(enrollmentError).not.toContainText(coachQr[1]);
});

test("program berbayar membuat reservasi dan snapshot instruksi", async ({ context, page }) => {
  const participant = users.at(-1);
  if (!participant?.email) throw new Error("Fixture Participant tidak tersedia.");
  await addSession(context, participant.email);
  const svg = renderSVG(`${baseUrl}/gabung/coach/${coachQr[0]}`, { border: 4, ecc: "M" });
  await page.setContent(`<div style="width:320px;height:320px">${svg}</div>`);
  const png = await page.locator("svg").screenshot({ type: "png" });

  await page.goto(`/program/${ids.programs[3]}/gabung`);
  await page.getByRole("button", { name: "Pindai QR Coach" }).click();
  await page.locator('.qr-scanner__file-action input[type="file"]').setInputFiles({
    buffer: png,
    mimeType: "image/png",
    name: "coach-paid.png",
  });
  await page.getByRole("button", { name: "Lanjut ke pembayaran" }).click();
  await expect(page).toHaveURL(/\/pembayaran\/[0-9a-f-]{36}$/);
  await expect(page.getByRole("heading", { name: "Instruksi pembayaran" })).toBeVisible();
  await expect(page.getByText("Bank Central Asia")).toBeVisible();
  await expect(page.getByText(/Rp\s*250\.000/)).toBeVisible();
  await expect(page.getByText("Menunggu bukti")).toBeVisible();
});
