import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "@playwright/test";
import { renderSVG } from "uqr";

test("gallery development-only membuka dialog dengan history dan lulus axe", async ({ page }) => {
  const consoleErrors: string[] = [];
  page.on("console", (message) => {
    if (message.type() === "error") consoleErrors.push(message.text());
  });

  await page.goto("/");
  await expect(page.getByRole("heading", { name: "Galeri kondisi internal" })).toBeVisible();
  for (const label of [
    "Navigasi Peserta pratinjau",
    "Navigasi Coach pratinjau",
    "Navigasi Admin pratinjau",
  ]) {
    await expect(page.getByRole("navigation", { name: label })).toBeVisible();
  }
  await page.getByRole("button", { name: "Buka dialog" }).click();
  await expect(page.getByRole("dialog", { name: "Atur filter" })).toBeVisible();

  await page.goBack();
  await expect(page.getByRole("dialog", { name: "Atur filter" })).not.toBeVisible();

  const results = await new AxeBuilder({ page }).analyze();
  const blocking = results.violations.filter(
    (violation) => violation.impact === "serious" || violation.impact === "critical",
  );
  expect(blocking).toEqual([]);
  expect(consoleErrors).toEqual([]);
});

test("gallery mendekode QR synthetic tanpa input kode manual", async ({ page }) => {
  const svg = renderSVG("http://127.0.0.1:4173/gabung/coach/coach-gallery-1234", {
    border: 4,
    ecc: "M",
  });
  await page.setContent(`<div style="width:320px;height:320px">${svg}</div>`);
  const png = await page.locator("svg").screenshot({ type: "png" });

  await page.goto("/");
  await page.getByRole("button", { name: "Uji pemindai QR" }).click();
  await expect(page.getByRole("dialog", { name: "Pindai QR Coach" })).toBeVisible();
  await expect(page.getByRole("dialog", { name: "Pindai QR Coach" })).toHaveScreenshot(
    "qr-scanner-mobile.png",
    { animations: "disabled" },
  );
  await expect(page.getByRole("textbox", { name: /kode coach/i })).toHaveCount(0);
  await page.locator('.qr-scanner__file-action input[type="file"]').setInputFiles({
    buffer: png,
    mimeType: "image/png",
    name: "qr-synthetic.png",
  });
  await expect(
    page.getByText("QR Coach canonical diterima tanpa menampilkan identifier."),
  ).toBeVisible();
});

test("gallery memproses foto synthetic di worker tanpa shortcut produksi", async ({ page }) => {
  await page.setContent(`
    <div style="width:640px;height:480px;background:#fff;display:grid;place-items:center">
      <div style="width:240px;height:240px;background:#d92d20;border-radius:32px"></div>
    </div>
  `);
  const png = await page.locator("body > div").screenshot({ type: "png" });

  await page.goto("/");
  await page
    .getByRole("region", { name: "Unggah foto" })
    .locator('input[type="file"]')
    .setInputFiles({
      buffer: png,
      mimeType: "image/png",
      name: "foto-synthetic.png",
    });
  await expect(page.getByText(/Foto aman siap: \d+ × \d+ piksel/)).toBeVisible({ timeout: 2_000 });
  await expect(page.getByRole("img", { name: "Pratinjau foto yang dipilih" })).toBeVisible();
  await expect(page.getByRole("button", { name: /Gunakan foto demo/i })).toHaveCount(0);
});

test("gallery katalog program mobile lulus aksesibilitas dan visual", async ({
  page,
}, testInfo) => {
  await page.setViewportSize({ height: 844, width: 390 });
  await page.goto("/");
  const gallery = page.getByTestId("program-gallery");
  await expect(gallery.getByRole("heading", { name: "Diikuti" })).toBeVisible();
  await expect(gallery.getByText("Pendaftaran ditutup")).toBeVisible();
  const results = await new AxeBuilder({ page })
    .include('[data-testid="program-gallery"]')
    .analyze();
  expect(
    results.violations.filter(
      (violation) => violation.impact === "serious" || violation.impact === "critical",
    ),
  ).toEqual([]);
  if (testInfo.project.name === "chromium") {
    await expect(gallery).toHaveScreenshot("program-catalog-mobile.png", {
      animations: "disabled",
    });
  }
});

test("gallery detail program mobile lulus aksesibilitas dan visual", async ({ page }, testInfo) => {
  await page.setViewportSize({ height: 844, width: 390 });
  await page.goto("/");
  const detail = page.getByTestId("program-detail-gallery");
  await expect(detail.getByRole("heading", { name: "MSC Detail Mobile" })).toBeVisible();
  const results = await new AxeBuilder({ page })
    .include('[data-testid="program-detail-gallery"]')
    .analyze();
  expect(
    results.violations.filter(
      (violation) => violation.impact === "serious" || violation.impact === "critical",
    ),
  ).toEqual([]);
  if (testInfo.project.name === "chromium") {
    await expect(detail).toHaveScreenshot("program-detail-mobile.png", {
      animations: "disabled",
    });
  }
});

test("gallery pembayaran Peserta mobile lulus aksesibilitas dan visual", async ({
  page,
}, testInfo) => {
  await page.setViewportSize({ height: 844, width: 390 });
  await page.goto("/");
  const payment = page.getByTestId("payment-owner-gallery");
  await expect(payment.getByRole("heading", { name: "Instruksi pembayaran" })).toBeVisible();
  const results = await new AxeBuilder({ page })
    .include('[data-testid="payment-owner-gallery"]')
    .analyze();
  expect(
    results.violations.filter(
      (violation) => violation.impact === "serious" || violation.impact === "critical",
    ),
  ).toEqual([]);
  if (testInfo.project.name === "chromium")
    await expect(payment).toHaveScreenshot("payment-owner-mobile.png", {
      animations: "disabled",
    });
});

test("gallery antrean Admin responsif lulus aksesibilitas dan visual", async ({
  page,
}, testInfo) => {
  await page.setViewportSize({ height: 900, width: 1280 });
  await page.goto("/");
  const payment = page.getByTestId("payment-admin-gallery");
  await expect(payment.getByRole("heading", { name: "Pembayaran", exact: true })).toBeVisible();
  const results = await new AxeBuilder({ page })
    .include('[data-testid="payment-admin-gallery"]')
    .analyze();
  expect(
    results.violations.filter(
      (violation) => violation.impact === "serious" || violation.impact === "critical",
    ),
  ).toEqual([]);
  if (testInfo.project.name === "chromium")
    await expect(payment).toHaveScreenshot("payment-admin-desktop.png", {
      animations: "disabled",
    });
});

test("gallery Home Peserta mobile lulus axe, zoom, mode gelap, dan visual", async ({
  page,
}, testInfo) => {
  await page.setViewportSize({ height: 844, width: 390 });
  await page.emulateMedia({ colorScheme: "dark", reducedMotion: "reduce" });
  await page.goto("/");
  await page.locator("html").evaluate((element) => {
    element.dataset.colorScheme = "dark";
    element.style.fontSize = "125%";
  });
  const home = page.getByTestId("participant-home-gallery");
  await expect(home.getByRole("heading", { name: "Halo, Rani" })).toBeVisible();
  await expect(home.getByText("Coach-mu")).toBeVisible();
  const results = await new AxeBuilder({ page })
    .include('[data-testid="participant-home-gallery"]')
    .analyze();
  expect(
    results.violations.filter(
      (violation) => violation.impact === "serious" || violation.impact === "critical",
    ),
  ).toEqual([]);
  await expect(home).toHaveScreenshot(`participant-home-mobile-${testInfo.project.name}.png`, {
    animations: "disabled",
  });
});

test("gallery dashboard Coach desktop lulus axe, keyboard, dan visual", async ({
  page,
}, testInfo) => {
  await page.setViewportSize({ height: 900, width: 1280 });
  await page.goto("/");
  const dashboard = page.getByTestId("coach-dashboard-gallery");
  await expect(dashboard.getByRole("heading", { name: "Halo, Coach Ayu" })).toBeVisible();
  await dashboard.getByRole("link", { name: /Peserta saya/ }).focus();
  await expect(dashboard.getByRole("link", { name: /Peserta saya/ })).toBeFocused();
  const results = await new AxeBuilder({ page })
    .include('[data-testid="coach-dashboard-gallery"]')
    .analyze();
  expect(
    results.violations.filter(
      (violation) => violation.impact === "serious" || violation.impact === "critical",
    ),
  ).toEqual([]);
  await expect(dashboard).toHaveScreenshot(`coach-dashboard-desktop-${testInfo.project.name}.png`, {
    animations: "disabled",
  });
});

test("gallery roster dan expiry Coach mobile tidak membocorkan data privat", async ({
  page,
}, testInfo) => {
  await page.setViewportSize({ height: 844, width: 390 });
  await page.goto("/");
  const roster = page.getByTestId("coach-roster-gallery");
  await expect(
    roster
      .locator(".coach-roster-card")
      .filter({ hasText: "Dewi Lestari" })
      .getByText("Belum terdaftar", { exact: true }),
  ).toBeVisible();
  await expect(roster.getByText(/\bkg\b/i)).toHaveCount(0);
  await expect(roster.getByRole("img", { name: /bukti/i })).toHaveCount(0);
  const expired = page.getByTestId("coach-expired-gallery");
  await expect(expired.getByRole("heading", { name: "Akses Coach berakhir" })).toBeVisible();
  await expect(expired.getByRole("link", { name: "Lanjut sebagai Peserta" })).toBeVisible();
  const results = await new AxeBuilder({ page })
    .include('[data-testid="coach-roster-gallery"]')
    .include('[data-testid="coach-expired-gallery"]')
    .analyze();
  expect(
    results.violations.filter(
      (violation) => violation.impact === "serious" || violation.impact === "critical",
    ),
  ).toEqual([]);
  await expect(roster).toHaveScreenshot(`coach-roster-mobile-${testInfo.project.name}.png`, {
    animations: "disabled",
  });
});

test("gallery dashboard Admin wide lulus axe, keyboard, dan visual", async ({ page }, testInfo) => {
  await page.setViewportSize({ height: 1000, width: 1440 });
  await page.goto("/");
  const dashboard = page.getByTestId("admin-dashboard-gallery");
  await expect(dashboard.getByRole("heading", { name: "Dashboard Admin" })).toBeVisible();
  await dashboard.getByRole("link", { name: "Buka antrean" }).focus();
  await expect(dashboard.getByRole("link", { name: "Buka antrean" })).toBeFocused();
  const results = await new AxeBuilder({ page })
    .include('[data-testid="admin-dashboard-gallery"]')
    .analyze();
  expect(
    results.violations.filter(
      (violation) => violation.impact === "serious" || violation.impact === "critical",
    ),
  ).toEqual([]);
  if (testInfo.project.name === "chromium")
    await expect(dashboard).toHaveScreenshot("admin-dashboard-wide.png", {
      animations: "disabled",
    });
});

test("gallery program Admin tablet responsif dan visual", async ({ page }, testInfo) => {
  await page.setViewportSize({ height: 1024, width: 820 });
  await page.goto("/");
  const programs = page.getByTestId("admin-program-gallery");
  await expect(programs.getByRole("heading", { name: "Program", exact: true })).toBeVisible();
  if (testInfo.project.name === "chromium")
    await expect(programs).toHaveScreenshot("admin-program-tablet.png", { animations: "disabled" });
});

test("gallery program Admin mobile tetap operabel", async ({ page }, testInfo) => {
  await page.setViewportSize({ height: 844, width: 390 });
  await page.goto("/");
  const programs = page.getByTestId("admin-program-gallery");
  await expect(programs.getByRole("link", { name: "Buat program baru" })).toBeVisible();
  await expect(programs.getByRole("button", { name: "Terapkan" })).toBeVisible();
  if (testInfo.project.name === "chromium")
    await expect(programs).toHaveScreenshot("admin-program-mobile.png", { animations: "disabled" });
});

test("capture marketing Peserta aman, reproducible, dan siap visual", async ({
  page,
}, testInfo) => {
  await page.setViewportSize({ height: 844, width: 390 });
  await page.goto("/");
  const capture = page.getByTestId("marketing-participant-capture");
  await expect(capture.getByRole("heading", { name: "Papan peringkat" })).toBeVisible();
  await expect(capture).toHaveAttribute("data-testid", "marketing-participant-capture");
  const text = await capture.textContent();
  expect(text).not.toMatch(/@|\+62|\bkg\b|bukti transfer|token|signed/i);
  const results = await new AxeBuilder({ page })
    .include('[data-testid="marketing-participant-capture"]')
    .analyze();
  expect(
    results.violations.filter(
      (violation) => violation.impact === "serious" || violation.impact === "critical",
    ),
  ).toEqual([]);
  await expect(capture).toHaveScreenshot(`marketing-participant-${testInfo.project.name}.png`, {
    animations: "disabled",
  });
});

test("capture marketing Coach tidak memuat field privat", async ({ page }, testInfo) => {
  await page.setViewportSize({ height: 900, width: 1280 });
  await page.goto("/");
  const capture = page.getByTestId("marketing-coach-capture");
  await expect(capture.getByRole("heading", { name: "Halo, Coach Demo" })).toBeVisible();
  const text = await capture.textContent();
  expect(text).not.toMatch(/@|\+62|\bkg\b|bukti transfer|token|signed/i);
  const results = await new AxeBuilder({ page })
    .include('[data-testid="marketing-coach-capture"]')
    .analyze();
  expect(
    results.violations.filter(
      (violation) => violation.impact === "serious" || violation.impact === "critical",
    ),
  ).toEqual([]);
  await expect(capture).toHaveScreenshot(`marketing-coach-${testInfo.project.name}.png`, {
    animations: "disabled",
  });
});
