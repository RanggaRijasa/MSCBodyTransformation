import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "@playwright/test";

test("Guest melihat auth Bahasa Indonesia, Google-first, tanpa Apple", async ({ page }) => {
  await page.goto("/masuk?returnTo=https%3A%2F%2Fevil.example");
  await expect(page.getByRole("heading", { name: "Masuk" })).toBeVisible();
  const google = page.getByRole("link", { name: "Lanjutkan dengan Google" });
  await expect(google).toHaveAttribute("href", /returnTo=%2Fhari-ini/);
  await expect(page.getByText(/email dan pemulihan password belum diaktifkan/i)).toBeVisible();
  await expect(page.getByText(/Apple/i)).toHaveCount(0);
  expect(
    (await new AxeBuilder({ page }).analyze()).violations.filter(
      (item) => item.impact === "serious" || item.impact === "critical",
    ),
  ).toEqual([]);
});

test("auth gate mempertahankan return-to internal pada profil", async ({ page }) => {
  await page.goto("/profil");
  await expect(page).toHaveURL(/\/masuk\?returnTo=%2Fprofil$/);
  await expect(page.getByRole("heading", { name: "Masuk" })).toBeVisible();
});

test("callback tanpa transaksi cocok gagal tertutup", async ({ page }) => {
  await page.goto("/auth/callback?code=kode-palsu&state=state-palsu");
  await expect(page).toHaveURL(/\/masuk\?error=callback|\/masuk\?error=state/);
  await expect(page.getByText(/tidak valid|tidak cocok/i)).toBeVisible();
});

test("route role sensitif menolak Guest", async ({ page }) => {
  await page.goto("/coach-area/qr");
  await expect(page).toHaveURL(/\/masuk\?returnTo=%2Fcoach-area%2Fqr$/);
  await page.goto("/admin/pembayaran");
  await expect(page).toHaveURL(/\/masuk\?returnTo=%2Fadmin%2Fpembayaran$/);
});

test("onboarding dan pemulihan tidak membocorkan akun", async ({ page }) => {
  await page.goto("/onboarding");
  await expect(page).toHaveURL(/\/masuk\?returnTo=%2Fonboarding$/);
  await page.goto("/lupa-password");
  await expect(page.getByText(/respons akan tetap sama untuk setiap alamat email/i)).toBeVisible();
});

test("inisiasi Google lokal membuat transaksi HttpOnly sebelum meninggalkan aplikasi", async ({
  request,
}) => {
  test.skip(!process.env.NEXT_PUBLIC_SUPABASE_URL, "Memerlukan Supabase lokal Phase 03.");
  const response = await request.get("/auth/google/start?mode=login&returnTo=%2Fprofil", {
    maxRedirects: 0,
  });
  expect(response.status()).toBe(307);
  expect(response.headers()["set-cookie"]).toMatch(/msc_auth_flow=.*HttpOnly.*SameSite=Lax/i);
  const location = response.headers().location ?? "";
  expect(location).toContain("/auth/v1/authorize");
  expect(location).toContain("provider=google");
});

test("pending program intent lokal hanya menyimpan program publik dan kedaluwarsa", async ({
  request,
}) => {
  test.skip(!process.env.NEXT_PUBLIC_SUPABASE_URL, "Memerlukan konfigurasi Auth lokal Phase 03.");
  const response = await request.post("/auth/intent/program", {
    form: { programId: "8acb9e0e-42ee-4c98-a7a5-10786e286657" },
    maxRedirects: 0,
  });
  expect(response.status()).toBe(303);
  const setCookie = response.headers()["set-cookie"] ?? "";
  expect(setCookie).toMatch(/msc_pending_program=/i);
  expect(setCookie).toMatch(/HttpOnly/i);
  expect(setCookie).toMatch(/Max-Age=1800/i);
  expect(setCookie).toMatch(/SameSite=Lax/i);
  expect(setCookie).not.toMatch(/coach|qr/i);
  expect(response.headers().location).toContain("returnTo=%2Fprogram%2F8acb9e0e");
});

test("session bootstrap Guest tidak mengeluarkan private state dan tidak boleh di-cache publik", async ({
  request,
}) => {
  const response = await request.get("/api/session");
  expect(response.ok()).toBe(true);
  expect(await response.json()).toEqual({ state: "guest" });
  expect(response.headers()["cache-control"]).toContain("private");
  expect(response.headers()["cache-control"]).toContain("no-store");
});
