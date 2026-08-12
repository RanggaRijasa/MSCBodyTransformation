import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "@playwright/test";

test("Guest melihat auth Bahasa Indonesia, Google-first, tanpa Apple", async ({ page }) => {
  await page.setViewportSize({ height: 844, width: 390 });
  await page.goto("/masuk?returnTo=https%3A%2F%2Fevil.example");
  const heading = page.getByRole("heading", { name: "Selamat datang kembali" });
  await expect(heading).toBeVisible();
  await expect(heading).toBeFocused();
  await expect(heading).toHaveCSS("outline-style", "none");
  const google = page.getByRole("link", { name: "Lanjutkan dengan Google" });
  await expect(google).toHaveAttribute("href", /returnTo=%2Fhari-ini/);
  await expect(page.getByRole("link", { name: /Google/ })).toHaveCount(1);
  await expect(page.getByRole("textbox")).toHaveCount(0);
  await expect(page.getByText(/Apple|provider utama|atau/i)).toHaveCount(0);
  await expect(page.getByRole("link", { name: "Tutup" })).toHaveAttribute("href", "/hari-ini");
  const closeControl = page.getByRole("link", { name: "Tutup" });
  await expect(closeControl).toHaveCSS("white-space", "nowrap");
  expect((await closeControl.boundingBox())?.height).toBeLessThanOrEqual(48);
  expect(
    (await new AxeBuilder({ page }).analyze()).violations.filter(
      (item) => item.impact === "serious" || item.impact === "critical",
    ),
  ).toEqual([]);
});

test("aksi Google memiliki state offline dan halaman daftar mempertahankan return-to", async ({
  page,
}) => {
  await page.addInitScript(() => {
    Object.defineProperty(Navigator.prototype, "onLine", {
      configurable: true,
      get: () => false,
    });
  });
  await page.goto("/masuk?returnTo=%2Fprofil");
  await page.getByRole("link", { name: "Lanjutkan dengan Google" }).click();
  await expect(
    page.getByText("Tidak ada koneksi. Sambungkan perangkat, lalu coba lagi."),
  ).toBeVisible();

  await page.goto("/daftar?returnTo=%2Fprogram%2Fdemo");
  await expect(page.getByRole("heading", { name: "Buat akun Peserta" })).toBeVisible();
  await expect(page.getByRole("link", { name: "Daftar dengan Google" })).toHaveAttribute(
    "href",
    /mode=register&returnTo=%2Fprogram%2Fdemo/,
  );
  await expect(page.getByRole("link", { name: "Masuk" })).toHaveAttribute(
    "href",
    "/masuk?returnTo=%2Fprogram%2Fdemo",
  );
});

test("Beranda Guest mendahulukan auth lalu hanya membuka data publik", async ({ page }) => {
  test.skip(!process.env.NEXT_PUBLIC_SUPABASE_URL, "Memerlukan data publik Supabase lokal.");
  await page.goto("/hari-ini");
  await expect(page.getByRole("heading", { level: 1, name: "Beranda" })).toBeVisible();
  await expect(page.getByRole("heading", { name: "Siap memulai perjalananmu?" })).toBeVisible();
  await expect(page.getByRole("link", { name: "Masuk" })).toHaveAttribute(
    "href",
    "/masuk?returnTo=%2Fhari-ini",
  );
  await expect(page.getByRole("heading", { name: "Fokus pribadi terkunci" })).toBeVisible();
  await expect(page.getByText("Coach-mu")).toHaveCount(0);
  await expect(page.getByText("Buka langkah berikutnya")).toHaveCount(0);
});

test("auth gate mempertahankan return-to internal pada profil", async ({ page }) => {
  await page.goto("/profil");
  await expect(page).toHaveURL(/\/masuk\?returnTo=%2Fprofil$/);
  await expect(page.getByRole("heading", { name: "Selamat datang kembali" })).toBeVisible();
});

test("callback tanpa transaksi cocok gagal tertutup", async ({ page }) => {
  await page.goto("/auth/callback?code=kode-palsu&state=state-palsu");
  await expect(page).toHaveURL(/\/masuk\?error=callback|\/masuk\?error=state/);
  await expect(page.getByText(/tidak valid|tidak cocok/i)).toBeVisible();
});

test("route role sensitif menolak Guest", async ({ page }) => {
  test.skip(!process.env.NEXT_PUBLIC_SUPABASE_URL, "Memerlukan session routing Supabase lokal.");
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
  await expect(page.getByRole("textbox")).toHaveCount(0);
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
