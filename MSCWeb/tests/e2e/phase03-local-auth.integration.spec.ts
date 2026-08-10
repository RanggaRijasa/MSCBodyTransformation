import { createServerClient } from "@supabase/ssr";
import { createClient, type SupabaseClient, type User } from "@supabase/supabase-js";
import { expect, test, type BrowserContext, type Page } from "@playwright/test";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const publishableKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
const serviceRoleKey = process.env.SUPABASE_TEST_SERVICE_ROLE_KEY;
const baseUrl = "http://127.0.0.1:3000";
const testPassword = "Phase03-local-only-2026!";

type LocalIdentity = Readonly<{
  admin: SupabaseClient;
  user: User;
}>;

async function removeExistingIdentity(admin: SupabaseClient, email: string) {
  const { data } = await admin.auth.admin.listUsers({ page: 1, perPage: 1_000 });
  const existing = data.users.find((user) => user.email === email);
  if (existing) await admin.auth.admin.deleteUser(existing.id);
}

async function createLocalIdentity(context: BrowserContext, email: string): Promise<LocalIdentity> {
  if (!supabaseUrl || !publishableKey || !serviceRoleKey) {
    throw new Error("Konfigurasi integration test Supabase lokal tidak tersedia.");
  }
  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  await removeExistingIdentity(admin, email);
  const { data, error } = await admin.auth.admin.createUser({
    email,
    email_confirm: true,
    password: testPassword,
    user_metadata: { display_name: "Peserta lokal" },
  });
  if (error || !data.user) throw error ?? new Error("Identitas lokal tidak dibuat.");

  const cookieJar = new Map<string, string>();
  const authClient = createServerClient(supabaseUrl, publishableKey, {
    cookies: {
      getAll: () => [...cookieJar].map(([name, value]) => ({ name, value })),
      setAll: (values) => {
        for (const { name, value } of values) cookieJar.set(name, value);
      },
    },
  });
  const { error: signInError } = await authClient.auth.signInWithPassword({
    email,
    password: testPassword,
  });
  if (signInError) throw signInError;
  const { data: claimsData, error: claimsError } = await authClient.auth.getClaims();
  if (claimsError || claimsData?.claims.sub !== data.user.id) {
    throw claimsError ?? new Error("Claims lokal tidak cocok.");
  }
  const { error: profileError } = await authClient
    .from("profiles")
    .select("role,onboarding_status")
    .eq("user_id", data.user.id)
    .single();
  if (profileError) throw profileError;
  const restoredClient = createServerClient(supabaseUrl, publishableKey, {
    cookies: {
      getAll: () => [...cookieJar].map(([name, value]) => ({ name, value })),
      setAll: (values) => {
        for (const { name, value } of values) cookieJar.set(name, value);
      },
    },
  });
  const { data: restoredClaims, error: restoredClaimsError } =
    await restoredClient.auth.getClaims();
  if (restoredClaimsError || restoredClaims?.claims.sub !== data.user.id) {
    throw restoredClaimsError ?? new Error("Cookie SSR lokal tidak memulihkan claims.");
  }
  const { error: restoredProfileError } = await restoredClient
    .from("profiles")
    .select("role,onboarding_status")
    .eq("user_id", data.user.id)
    .single();
  if (restoredProfileError) throw restoredProfileError;
  await context.addCookies([...cookieJar].map(([name, value]) => ({ name, value, url: baseUrl })));
  const browserCookies = await context.cookies(baseUrl);
  for (const [name, value] of cookieJar) {
    if (browserCookies.find((cookie) => cookie.name === name)?.value !== value) {
      throw new Error(`Cookie lokal ${name} tidak tersimpan utuh di browser.`);
    }
  }
  const sessionResponse = await context.request.get("/api/session");
  const session = (await sessionResponse.json()) as { state?: string };
  if (session.state !== "onboarding") {
    throw new Error(
      `Session bootstrap lokal gagal tertutup sebagai ${session.state ?? "unknown"}.`,
    );
  }
  return { admin, user: data.user };
}

async function completeCoachApplicantOnboarding(page: Page) {
  await page.goto("/onboarding");
  await page.getByLabel("Nama lengkap").fill("Peserta lokal");
  await page.getByLabel("Nomor HP").fill("+628123456789");
  await page.getByLabel("Level member").selectOption("sc");
  await page.getByRole("radio", { name: /Ajukan Coach/ }).check();
  await page.getByLabel("Saya telah menyelesaikan HOM STS").check();
  await page.getByLabel("Saya telah menyelesaikan ICT").check();
  await page.getByRole("button", { name: "Simpan dan lanjutkan" }).click();
  await expect(page).toHaveURL(/\/hari-ini$/);
}

test.describe("Supabase Auth lokal", () => {
  test.skip(
    !supabaseUrl || !publishableKey || !serviceRoleKey,
    "Memerlukan credential runtime Supabase lokal.",
  );

  test("onboarding Coach tetap Participant lalu logout membatalkan sesi di tab lain", async ({
    context,
    page,
  }) => {
    const email = "phase03-onboarding@local.invalid";
    const identity = await createLocalIdentity(context, email);
    try {
      await completeCoachApplicantOnboarding(page);
      const { data: profile } = await identity.admin
        .from("profiles")
        .select("role,onboarding_status,account_purpose")
        .eq("user_id", identity.user.id)
        .single();
      expect(profile).toMatchObject({
        account_purpose: "coach_applicant",
        onboarding_status: "coach_handoff_pending",
        role: "participant",
      });

      const secondTab = await context.newPage();
      await secondTab.goto("/profil");
      await expect(
        secondTab.locator(".profile-readonly dd").filter({ hasText: "Peserta" }),
      ).toBeVisible();
      await secondTab.getByRole("button", { name: "Keluar" }).click();
      await expect(secondTab).toHaveURL(/\/masuk\?status=keluar$/);
      await page.bringToFront();
      await page.goto("/profil");
      await expect(page).toHaveURL(/\/masuk\?returnTo=%2Fprofil$/);
    } finally {
      await identity.admin.auth.admin.deleteUser(identity.user.id);
    }
  });

  test("penghapusan akun sukses setelah reautentikasi baru", async ({ context, page }) => {
    const email = "phase03-delete-success@local.invalid";
    const identity = await createLocalIdentity(context, email);
    try {
      await page.goto("/profil");
      page.once("dialog", (dialog) => dialog.accept());
      await page.getByRole("button", { name: "Hapus akun" }).click();
      await expect(page).toHaveURL(/\/masuk\?status=akun-dihapus$/);
      const { data } = await identity.admin.auth.admin.getUserById(identity.user.id);
      expect(data.user).toBeNull();
    } finally {
      await identity.admin.auth.admin.deleteUser(identity.user.id).catch(() => undefined);
    }
  });

  test("penghapusan akun Admin ditolak tanpa membocorkan error teknis", async ({
    context,
    page,
  }) => {
    const email = "phase03-delete-denied@local.invalid";
    const identity = await createLocalIdentity(context, email);
    try {
      const { error } = await identity.admin
        .from("profiles")
        .update({ role: "admin" })
        .eq("user_id", identity.user.id);
      expect(error).toBeNull();
      await page.goto("/profil");
      page.once("dialog", (dialog) => dialog.accept());
      await page.getByRole("button", { name: "Hapus akun" }).click();
      await expect(
        page.getByText("Akun Admin tidak dapat dihapus melalui aplikasi."),
      ).toBeVisible();
      const { data } = await identity.admin.auth.admin.getUserById(identity.user.id);
      expect(data.user?.id).toBe(identity.user.id);
    } finally {
      await identity.admin.auth.admin.deleteUser(identity.user.id);
    }
  });

  test("sesi yang dicabut gagal tertutup saat private route dimuat ulang", async ({
    context,
    page,
  }) => {
    const email = "phase03-revoked@local.invalid";
    const identity = await createLocalIdentity(context, email);
    await page.goto("/profil");
    await identity.admin.auth.admin.deleteUser(identity.user.id);
    await page.reload();
    await expect(page).toHaveURL(/\/masuk\?returnTo=%2Fprofil$/);
  });
});
