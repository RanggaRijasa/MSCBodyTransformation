import { expect, test } from "@playwright/test";

test.describe("simulator role development", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
    await page.evaluate(() => window.localStorage.clear());
    await page.reload();
  });

  test("memilih Peserta lalu menavigasi shell asli", async ({ page }) => {
    await page.setViewportSize({ height: 844, width: 390 });
    await page.getByRole("button", { name: /^Peserta / }).click();
    await expect(page).toHaveURL(/\/hari-ini$/);
    await expect(page.getByRole("heading", { level: 1, name: "Beranda" })).toBeVisible();
    await page.getByRole("link", { name: "Program" }).last().click();
    await expect(page).toHaveURL(/\/program$/);
    await expect(
      page.getByRole("heading", { name: "Temukan program transformasimu" }),
    ).toBeVisible();
    await page.getByRole("link", { name: "Profil" }).last().click();
    await expect(page.getByRole("heading", { name: "Profil" })).toBeVisible();
  });

  test("menjalankan mode Guest tanpa data privat", async ({ page }) => {
    await page.getByRole("button", { name: /Guest/ }).click();
    await expect(page.getByRole("heading", { level: 1, name: "Beranda" })).toBeVisible();
    await expect(page.getByText("Siap memulai perjalananmu?")).toBeVisible();
    await expect(page.getByText(/berat badan/i)).toHaveCount(0);
  });

  test("menavigasi perjalanan Coach", async ({ page }) => {
    await page.getByRole("button", { name: /Coach/ }).click();
    await expect(page).toHaveURL(/\/coach-area$/);
    await expect(page.getByRole("heading", { level: 1, name: "Dashboard" })).toBeVisible();
    await page.getByRole("link", { name: "Peserta saya" }).first().click();
    await expect(page).toHaveURL(/\/coach-area\/peserta$/);
    await expect(page.getByRole("heading", { level: 1, name: "Peserta saya" })).toBeVisible();
  });

  test("menavigasi perjalanan Admin", async ({ page }) => {
    await page.setViewportSize({ height: 844, width: 390 });
    await page.getByRole("button", { name: /Admin/ }).click();
    await expect(page.getByRole("heading", { level: 1, name: "Dashboard" })).toBeVisible();
    await page.getByRole("link", { name: "Orang" }).last().click();
    await expect(page.getByRole("heading", { level: 1, name: "Orang" })).toBeVisible();
    await page.getByRole("button", { name: "Ganti role" }).click();
    await expect(page.getByRole("heading", { name: "Pilih perjalanan aplikasi" })).toBeVisible();
  });

  test("menahan submit server di simulator", async ({ page }) => {
    await page.getByRole("button", { name: /Guest/ }).click();
    await page.getByRole("link", { name: "Program" }).last().click();
    await page.getByRole("link", { name: "Lihat detail" }).first().click();
    await page.getByRole("button", { name: "Masuk untuk mendaftar" }).click();
    await expect(page.getByRole("status")).toContainText("Aksi server ditahan");
  });
});
