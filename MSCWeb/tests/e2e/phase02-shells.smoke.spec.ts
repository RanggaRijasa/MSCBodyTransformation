import AxeBuilder from "@axe-core/playwright";
import { expect, test, type Page } from "@playwright/test";

const consoleErrors = new WeakMap<Page, string[]>();

test.beforeEach(async ({ page }) => {
  const messages: string[] = [];
  consoleErrors.set(page, messages);
  page.on("console", (message) => {
    if (message.type() === "error") {
      messages.push(message.text());
    }
  });
});

test.afterEach(async ({ page }) => {
  expect(consoleErrors.get(page) ?? []).toEqual([]);
});

test("smoke navigasi Peserta menjaga URL, focus, back, dan forward", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/hari-ini");

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
  await expect(page.getByRole("heading", { level: 1, name: "Hari ini" })).toBeFocused();

  await page.goForward();
  await expect(page).toHaveURL(/\/program$/);
});

test("smoke tiga shell responsif pada mobile, tablet, dan desktop", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/coach-area");
  await expect(page.getByRole("navigation", { name: "Navigasi Coach" })).toBeVisible();
  await expect(page.getByRole("heading", { name: "Dashboard Coach" })).toBeVisible();

  await page.setViewportSize({ width: 820, height: 1000 });
  await page.goto("/admin");
  await expect(page.getByRole("navigation", { name: "Navigasi Admin" })).toBeVisible();

  await page.setViewportSize({ width: 1440, height: 1000 });
  const sidebarBox = await page.locator(".app-shell__sidebar").boundingBox();
  const mainBox = await page.locator("#app-main-content").boundingBox();
  expect(sidebarBox?.width).toBeGreaterThanOrEqual(260);
  expect(mainBox?.x).toBeGreaterThanOrEqual(260);
});

test("smoke posisi scroll tiap tab dipulihkan saat kembali", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 700 });
  await page.goto("/hari-ini");
  await expect(page.getByRole("heading", { name: "Hari ini" })).toBeVisible();
  await page.evaluate(() => {
    document.documentElement.style.scrollBehavior = "auto";
    window.scrollTo(0, 650);
  });
  await expect.poll(() => page.evaluate(() => window.scrollY)).toBeGreaterThan(500);

  const programNavigation = page
    .getByRole("navigation", { name: "Navigasi Peserta" })
    .getByRole("link", { name: "Program" });
  // WebKit Playwright memindahkan scroll sebelum pointer click pada navigasi fixed.
  // DOM click menjaga posisi awal dan tetap melewati event serta router Link yang sama.
  await programNavigation.evaluate((link: HTMLAnchorElement) => link.click());
  await expect(page).toHaveURL(/\/program$/);
  const savedPosition = await page.evaluate(() =>
    Number.parseInt(sessionStorage.getItem("msc-shell-scroll:/hari-ini") ?? "0", 10),
  );
  expect(savedPosition).toBeGreaterThan(500);

  await page.goBack();
  await expect(page).toHaveURL(/\/hari-ini$/);
  await expect.poll(() => page.evaluate(() => window.scrollY)).toBeGreaterThan(500);
});

test("smoke manifest PWA memuat kontrak presentation", async ({ request }) => {
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

test("smoke axe shell Peserta, Coach, dan Admin tanpa serious/critical", async ({ page }) => {
  for (const route of ["/hari-ini", "/coach-area", "/admin"]) {
    await page.goto(route);
    const results = await new AxeBuilder({ page }).analyze();
    const blocking = results.violations.filter(
      (violation) => violation.impact === "serious" || violation.impact === "critical",
    );
    expect(blocking, `${route}: ${JSON.stringify(blocking)}`).toEqual([]);
  }
});

test("smoke zoom 200 persen, reduced motion, dan high contrast tetap tanpa overflow horizontal", async ({
  page,
}) => {
  await page.emulateMedia({ colorScheme: "dark", contrast: "more", reducedMotion: "reduce" });
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/hari-ini");
  await page.evaluate(() => {
    document.documentElement.style.fontSize = "200%";
  });

  await expect(page.getByRole("heading", { name: "Hari ini" })).toBeVisible();
  const dimensions = await page.evaluate(() => ({
    pageWidth: document.documentElement.scrollWidth,
    viewportWidth: window.innerWidth,
  }));
  expect(dimensions.pageWidth).toBeLessThanOrEqual(dimensions.viewportWidth);
});
