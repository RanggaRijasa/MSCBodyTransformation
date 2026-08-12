import AxeBuilder from "@axe-core/playwright";
import { expect, test, type Page } from "@playwright/test";

import {
  addPhase11AShellSession,
  cleanupPhase11AShellFixture,
  createPhase11AShellFixture,
  hasPhase11AShellAuthEnvironment,
  phase11AShellAuthSkipReason,
  type Phase11AShellFixture,
} from "./support/phase11a-shell-fixture";

const consoleErrors = new WeakMap<Page, string[]>();

test.beforeEach(async ({ page }) => {
  const messages: string[] = [];
  consoleErrors.set(page, messages);
  page.on("console", (message) => {
    if (message.type() === "error") messages.push(message.text());
  });
});

test.afterEach(async ({ page }) => {
  expect(consoleErrors.get(page) ?? []).toEqual([]);
});

async function expectNoBlockingAxeFindings(page: Page, route: string) {
  const results = await new AxeBuilder({ page }).analyze();
  const blocking = results.violations.filter(
    (violation) => violation.impact === "serious" || violation.impact === "critical",
  );
  expect(blocking, `${route}: ${JSON.stringify(blocking)}`).toEqual([]);
}

test.describe("public Guest/Peserta shell", () => {
  test("navigasi menjaga URL, focus, back, dan forward", async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    // Hangatkan chunk route pada Next dev agar WebKit tidak menguji jeda cold compilation.
    // Journey di bawah tetap memakai Link, history back/forward, dan focus route yang nyata.
    await page.goto("/program");
    await expect(page.getByRole("heading", { level: 1, name: "Program" })).toBeVisible();
    await page.goto("/hari-ini");

    await expect(page.getByRole("heading", { level: 1, name: "Beranda" })).toBeVisible();
    await expect(page.getByRole("link", { name: "Lewati ke konten utama" })).toHaveAttribute(
      "href",
      "#app-main-content",
    );
    const navigation = page.getByRole("navigation", { name: "Navigasi Peserta" });
    await expect(navigation).toBeVisible();
    await navigation.getByRole("link", { name: "Program" }).click();

    await expect(page).toHaveURL(/\/program$/);
    await expect(page.getByRole("heading", { level: 1, name: "Program" })).toBeFocused();

    await page.goBack();
    await expect(page).toHaveURL(/\/hari-ini$/);
    await expect(page.getByRole("heading", { level: 1, name: "Beranda" })).toBeFocused();

    await page.goForward();
    await expect(page).toHaveURL(/\/program$/);
    await expect(page.getByRole("heading", { level: 1, name: "Program" })).toBeFocused();
  });

  test("posisi scroll tiap tab dipulihkan saat kembali", async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 700 });
    await page.goto("/hari-ini");
    await expect(page.getByRole("heading", { level: 1, name: "Beranda" })).toBeVisible();
    const scrollAnchor = page.getByRole("heading", { level: 2, name: "Coach" });
    await expect(scrollAnchor).toBeAttached();
    await scrollAnchor.scrollIntoViewIfNeeded();
    await page.evaluate(() => {
      document.documentElement.style.scrollBehavior = "auto";
    });
    await expect.poll(() => page.evaluate(() => window.scrollY)).toBeGreaterThan(500);

    const programNavigation = page
      .getByRole("navigation", { name: "Navigasi Peserta" })
      .getByRole("link", { name: "Program" });
    // DOM click mempertahankan handler Link yang menyimpan posisi tanpa membuat WebKit
    // memindahkan viewport ke navigasi fixed sebelum nilai scroll dibaca.
    await programNavigation.evaluate((link: HTMLAnchorElement) => {
      link.click();
    });
    await expect(page).toHaveURL(/\/program$/);
    await expect(page.getByRole("heading", { level: 1, name: "Program" })).toBeFocused();
    const savedPosition = await page.evaluate(() =>
      Number.parseInt(sessionStorage.getItem("msc-shell-scroll:/hari-ini") ?? "0", 10),
    );
    expect(savedPosition).toBeGreaterThan(500);

    await page.goBack();
    await expect(page).toHaveURL(/\/hari-ini$/);
    await expect(page.getByRole("heading", { level: 1, name: "Beranda" })).toBeFocused();
    await expect
      .poll(() => page.evaluate((expected) => Math.abs(window.scrollY - expected), savedPosition))
      .toBeLessThanOrEqual(2);
  });

  test("manifest PWA memuat kontrak presentation", async ({ request }) => {
    const response = await request.get("/manifest.webmanifest");
    expect(response.ok()).toBe(true);

    const manifest = (await response.json()) as Record<string, unknown>;
    expect(manifest).toMatchObject({
      name: "MSC Body Transformation",
      short_name: "MSC Body",
      start_url: "/hari-ini",
      display: "standalone",
      lang: "id-ID",
    });
    expect(manifest.icons).toHaveLength(3);
  });

  test("axe shell Guest/Peserta tanpa serious atau critical", async ({ page }) => {
    await page.goto("/hari-ini");
    await expect(page).toHaveURL(/\/hari-ini$/);
    await expect(page.getByRole("heading", { level: 1, name: "Beranda" })).toBeVisible();
    await expectNoBlockingAxeFindings(page, "/hari-ini");
  });

  test("zoom 200 persen, reduced motion, dan high contrast tidak overflow", async ({ page }) => {
    await page.emulateMedia({ colorScheme: "dark", contrast: "more", reducedMotion: "reduce" });
    await page.setViewportSize({ width: 390, height: 844 });
    await page.goto("/hari-ini");
    await page.evaluate(() => {
      document.documentElement.style.fontSize = "200%";
    });

    await expect(page.getByRole("heading", { level: 1, name: "Beranda" })).toBeVisible();
    const dimensions = await page.evaluate(() => ({
      pageWidth: document.documentElement.scrollWidth,
      viewportWidth: window.innerWidth,
    }));
    expect(dimensions.pageWidth).toBeLessThanOrEqual(dimensions.viewportWidth);
  });
});

test.describe("authenticated Coach/Admin shell", () => {
  test.describe.configure({ mode: "serial" });
  test.skip(!hasPhase11AShellAuthEnvironment, phase11AShellAuthSkipReason);

  let fixture: Phase11AShellFixture | undefined;

  test.beforeAll(async () => {
    fixture = await createPhase11AShellFixture();
  });

  test.afterAll(async () => {
    if (fixture) await cleanupPhase11AShellFixture(fixture);
  });

  test("Coach mobile memakai tiga tab dan session peran yang benar", async ({ context, page }) => {
    if (!fixture) throw new Error("Fixture shell belum dibuat.");
    await addPhase11AShellSession(context, fixture, "coach");
    await page.setViewportSize({ width: 390, height: 844 });
    await page.goto("/coach-area");

    await expect(page).toHaveURL(/\/coach-area$/);
    await expect(page.getByRole("heading", { level: 1, name: "Dashboard" })).toBeVisible();
    const navigation = page.getByRole("navigation", { name: "Navigasi Coach" });
    await expect(navigation).toBeVisible();
    await expect(navigation.getByRole("link")).toHaveCount(3);
    expect(await navigation.getByRole("link").allTextContents()).toEqual([
      "Dashboard",
      "Program",
      "Profil",
    ]);
  });

  test("Admin mobile lima tab dan desktop enam destination", async ({ context, page }) => {
    if (!fixture) throw new Error("Fixture shell belum dibuat.");
    await addPhase11AShellSession(context, fixture, "admin");
    await page.setViewportSize({ width: 390, height: 844 });
    await page.goto("/admin");

    await expect(page).toHaveURL(/\/admin$/);
    await expect(page.getByRole("heading", { level: 1, name: "Dashboard" })).toBeVisible();
    const mobileNavigation = page.getByRole("navigation", { name: "Navigasi Admin" });
    await expect(mobileNavigation).toBeVisible();
    await expect(mobileNavigation.getByRole("link")).toHaveCount(5);
    expect(await mobileNavigation.getByRole("link").allTextContents()).toEqual([
      "Dashboard",
      "Program",
      "Orang",
      "Konten",
      "Pengaturan",
    ]);
    await expect(mobileNavigation.getByRole("link", { name: "Pembayaran" })).toHaveCount(0);
    await expect(page.getByRole("link", { name: "Buka antrean" })).toHaveAttribute(
      "href",
      "/admin/pembayaran",
    );
    for (const link of await mobileNavigation.getByRole("link").all()) {
      const box = await link.boundingBox();
      expect(box?.width).toBeGreaterThanOrEqual(44);
      expect(box?.height).toBeGreaterThanOrEqual(44);
    }

    await page.setViewportSize({ width: 1440, height: 1000 });
    const desktopNavigation = page
      .locator(".app-shell--admin .app-shell__sidebar")
      .getByRole("navigation", { name: "Navigasi Admin" });
    await expect(desktopNavigation).toBeVisible();
    await expect(desktopNavigation.getByRole("link")).toHaveCount(6);
    await expect(desktopNavigation.getByRole("link", { name: "Pembayaran" })).toHaveAttribute(
      "href",
      "/admin/pembayaran",
    );
    const sidebarBox = await page.locator(".app-shell__sidebar").boundingBox();
    const mainBox = await page.locator("#app-main-content").boundingBox();
    expect(sidebarBox?.width).toBeGreaterThanOrEqual(260);
    expect(mainBox?.x).toBeGreaterThanOrEqual(260);
  });

  test("axe Coach memakai context Coach tanpa redirect", async ({ context, page }) => {
    if (!fixture) throw new Error("Fixture shell belum dibuat.");
    await addPhase11AShellSession(context, fixture, "coach");
    await page.goto("/coach-area");
    await expect(page).toHaveURL(/\/coach-area$/);
    await expect(page.getByRole("heading", { level: 1, name: "Dashboard" })).toBeVisible();
    await expectNoBlockingAxeFindings(page, "/coach-area");
  });

  test("axe Admin memakai context Admin tanpa redirect", async ({ context, page }) => {
    if (!fixture) throw new Error("Fixture shell belum dibuat.");
    await addPhase11AShellSession(context, fixture, "admin");
    await page.goto("/admin");
    await expect(page).toHaveURL(/\/admin$/);
    await expect(page.getByRole("heading", { level: 1, name: "Dashboard" })).toBeVisible();
    await expectNoBlockingAxeFindings(page, "/admin");
  });
});
