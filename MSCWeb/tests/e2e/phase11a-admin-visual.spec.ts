import AxeBuilder from "@axe-core/playwright";
import { expect, test, type Page, type TestInfo } from "@playwright/test";

import {
  addAdminVisualSession,
  cleanupAdminVisualFixture,
  createAdminVisualFixture,
} from "./support/phase11a-admin-fixture";

const hasLocalEnvironment = Boolean(
  process.env.NEXT_PUBLIC_SUPABASE_URL &&
  process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY &&
  process.env.SUPABASE_TEST_SERVICE_ROLE_KEY,
);
type AdminFixture = Awaited<ReturnType<typeof createAdminVisualFixture>>;
let fixture: AdminFixture;

test.skip(!hasLocalEnvironment, "Memerlukan Supabase lokal.");
test.describe.configure({ mode: "serial" });
test.setTimeout(90_000);

async function openAsAdmin(page: Page, path: string) {
  if (page.url() !== "about:blank") {
    await page.evaluate(() => (document.activeElement as HTMLElement | null)?.blur());
  }
  await page.goto(path);
  await expect(page).toHaveURL(new RegExp(`${path.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}`));
  await page.waitForLoadState("networkidle");
  await page.addStyleTag({ content: "nextjs-portal { display: none !important; }" });
}

async function expectNoSeriousAxeFindings(page: Page) {
  const result = await new AxeBuilder({ page }).analyze();
  expect(
    result.violations.filter(({ impact }) => impact === "critical" || impact === "serious"),
  ).toEqual([]);
}

async function capture(page: Page, testInfo: TestInfo, name: string) {
  await page.screenshot({
    animations: "disabled",
    fullPage: false,
    path: testInfo.outputPath(`${name}-${testInfo.project.name}.png`),
  });
}

async function expectOpaqueContrastAtLeast(page: Page, selector: string, minimum: number) {
  const ratio = await page
    .locator(selector)
    .first()
    .evaluate((element) => {
      const channels = (value: string) =>
        value
          .match(/[\d.]+/g)!
          .slice(0, 3)
          .map(Number);
      const luminance = (value: string) => {
        const [red, green, blue] = channels(value).map((channel) => {
          const normalized = channel! / 255;
          return normalized <= 0.04045 ? normalized / 12.92 : ((normalized + 0.055) / 1.055) ** 2.4;
        });
        return red! * 0.2126 + green! * 0.7152 + blue! * 0.0722;
      };
      const style = getComputedStyle(element);
      const foreground = luminance(style.color);
      const background = luminance(style.backgroundColor);
      return (Math.max(foreground, background) + 0.05) / (Math.min(foreground, background) + 0.05);
    });
  expect(ratio).toBeGreaterThanOrEqual(minimum);
}

test.beforeAll(async () => {
  if (!hasLocalEnvironment) return;
  fixture = await createAdminVisualFixture();
});

test.afterAll(async () => {
  await cleanupAdminVisualFixture(fixture);
});

test.beforeEach(async ({ context }) => {
  await addAdminVisualSession(context, fixture);
});

test("dashboard 390 mempertahankan tiga metrik dan lima tab mobile", async ({ page }, testInfo) => {
  await page.setViewportSize({ height: 844, width: 390 });
  await openAsAdmin(page, "/admin");
  await expect(page.getByRole("heading", { level: 1, name: "Dashboard" })).toBeVisible();
  await expect(page.getByText("Ringkasan operasional", { exact: true })).toHaveCount(0);
  const actionRows = page.locator(".admin-action-row");
  await expect(actionRows).toHaveCount(3);
  expect(await actionRows.evaluateAll((rows) => rows.every((row) => row.clientHeight <= 136))).toBe(
    true,
  );
  const actionLinks = [
    ["Buka program", "/admin/program?status=completed"],
    ["Tinjau pengajuan", "/admin/orang?bagian=pengajuan"],
    ["Buka antrean", "/admin/pembayaran"],
  ] as const;
  for (const [name, href] of actionLinks) {
    const link = page.getByRole("link", { name });
    await expect(link).toBeVisible();
    await expect(link).toHaveAttribute("href", href);
    await expect(link.locator("svg")).toHaveCount(1);
    const box = await link.boundingBox();
    expect(box?.height).toBeGreaterThanOrEqual(44);
    expect(box?.width).toBeGreaterThanOrEqual(44);
  }
  const overview = page.locator(".admin-overview");
  const metrics = overview.locator(".metric");
  await expect(metrics).toHaveCount(3);
  const boxes = await metrics.evaluateAll((items) =>
    items.map((item) => {
      const box = item.getBoundingClientRect();
      return { right: box.right, width: box.width, x: box.x, y: box.y };
    }),
  );
  expect(new Set(boxes.map(({ y }) => Math.round(y))).size).toBe(1);
  expect(boxes[0]!.x).toBeLessThan(boxes[1]!.x);
  expect(boxes[1]!.x).toBeLessThan(boxes[2]!.x);
  expect(boxes.every(({ width }) => width >= 100)).toBe(true);
  const mobileNavigation = page.locator("nav.shell-navigation--admin:visible");
  await expect(mobileNavigation.getByRole("link")).toHaveCount(5);
  await expect(mobileNavigation.getByRole("link", { name: "Pembayaran" })).toHaveCount(0);
  expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBeLessThanOrEqual(390);
  await expectNoSeriousAxeFindings(page);
  await capture(page, testInfo, "admin-dashboard-390");
});

test("dashboard 390 dark mempertahankan hierarki dan lima tab mobile", async ({
  page,
}, testInfo) => {
  await page.emulateMedia({ colorScheme: "dark" });
  await page.setViewportSize({ height: 844, width: 390 });
  await openAsAdmin(page, "/admin");
  await expect(page.getByRole("heading", { level: 1, name: "Dashboard" })).toBeVisible();
  await expect(page.locator(".admin-overview:visible > .metric")).toHaveCount(3);
  const mobileNavigation = page.locator("nav.shell-navigation--admin:visible");
  await expect(mobileNavigation.getByRole("link")).toHaveCount(5);
  await expect(mobileNavigation.getByRole("link", { name: "Pembayaran" })).toHaveCount(0);
  const dashboardLink = mobileNavigation.getByRole("link", { name: "Dashboard" });
  expect(
    await dashboardLink.evaluate((element) => {
      const probe = document.createElement("span");
      probe.style.color = "var(--color-text-primary)";
      document.body.append(probe);
      const expected = getComputedStyle(probe).color;
      probe.remove();
      return getComputedStyle(element).color === expected;
    }),
  ).toBe(true);
  await expectOpaqueContrastAtLeast(page, ".admin-dashboard .app-action--secondary", 4.5);
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= document.documentElement.clientWidth,
    ),
  ).toBe(true);
  await expectNoSeriousAxeFindings(page);
  await capture(page, testInfo, "admin-dashboard-390-dark");
});

test("dashboard 1440 light mempertahankan hierarki dan enam link desktop", async ({
  page,
}, testInfo) => {
  await page.emulateMedia({ colorScheme: "light" });
  await page.setViewportSize({ height: 900, width: 1440 });
  await openAsAdmin(page, "/admin");
  await expect(page.getByRole("heading", { level: 1, name: "Dashboard" })).toBeVisible();
  await expect(page.locator(".admin-overview:visible > .metric")).toHaveCount(3);
  const desktopNavigation = page.locator("nav.shell-navigation--admin:visible");
  await expect(desktopNavigation.getByRole("link")).toHaveCount(6);
  await expect(desktopNavigation.getByRole("link", { name: "Pembayaran" })).toBeVisible();
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= document.documentElement.clientWidth,
    ),
  ).toBe(true);
  await expectNoSeriousAxeFindings(page);
  await capture(page, testInfo, "admin-dashboard-1440-light");
});

test("dashboard tetap zoom-safe pada 320 dan root 400 persen", async ({ page }) => {
  await page.setViewportSize({ height: 900, width: 320 });
  await openAsAdmin(page, "/admin");
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= document.documentElement.clientWidth,
    ),
  ).toBe(true);
  await page.addStyleTag({ content: ":root { font-size: 400% !important; }" });
  await expect(page.getByRole("heading", { level: 1, name: "Dashboard" })).toBeVisible();
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= document.documentElement.clientWidth,
    ),
  ).toBe(true);
  await expect(page.locator(".admin-overview:visible > .metric")).toHaveCount(3);
});

test("tab editor memiliki cue forced-colors dan ArrowRight", async ({ page }, testInfo) => {
  await page.emulateMedia({ forcedColors: "active" });
  await openAsAdmin(page, `/admin/program/${fixture.programId}/edit`);
  const settings = page.getByRole("tab", { name: "Pengaturan" });
  const content = page.getByRole("tab", { name: "Hari dan konten" });
  await settings.focus();
  await settings.press("ArrowRight");
  await expect(content).toBeFocused();
  await expect(content).toHaveAttribute("aria-selected", "true");
  const cue = await content.evaluate((element) => {
    const style = getComputedStyle(element);
    return { outlineStyle: style.outlineStyle, outlineWidth: style.outlineWidth };
  });
  expect(cue.outlineStyle).not.toBe("none");
  expect(cue.outlineWidth).toBe("2px");
  await capture(page, testInfo, "admin-editor-forced-colors");
});

test("segmen peran memakai URL kanonik, selected cue, keyboard, dan back focus", async ({
  page,
}) => {
  await page.emulateMedia({ forcedColors: "active" });
  // Warm the real destination so the assertion exercises navigation, not compilation latency.
  await openAsAdmin(page, "/admin/program");
  await expect(page.getByRole("heading", { level: 1, name: "Program" })).toBeVisible();
  await openAsAdmin(page, "/admin/orang?q=Visual&peran=coach");
  const coach = page.getByRole("link", { name: "Coach", exact: true });
  const participant = page.getByRole("link", { name: "Peserta", exact: true });
  await expect(coach).toHaveAttribute("aria-current", "page");
  await expect(coach).toHaveAttribute("href", "/admin/orang?q=Visual&peran=coach");
  await expect(participant).toHaveAttribute("href", "/admin/orang?q=Visual&peran=participant");
  await coach.focus();
  await expect(coach).toBeFocused();
  expect(await coach.evaluate((item) => getComputedStyle(item).outlineWidth)).toBe("2px");
  await participant.click();
  await expect(page).toHaveURL(/\/admin\/orang\?q=Visual&peran=participant$/);
  await expect(page.getByRole("link", { name: "Peserta", exact: true })).toHaveAttribute(
    "aria-current",
    "page",
  );
  await page
    .locator("nav.shell-navigation--admin:visible")
    .getByRole("link", { name: "Program" })
    .click();
  await expect(page.getByRole("heading", { level: 1, name: "Program" })).toBeFocused();
  await page.goBack();
  await expect(page).toHaveURL(/\/admin\/orang\?q=Visual&peran=participant$/);
  await expect(page.getByRole("heading", { level: 1, name: "Orang" })).toBeFocused();
  await expect(page.getByRole("link", { name: "Peserta", exact: true })).toHaveAttribute(
    "aria-current",
    "page",
  );
});

test("poster memakai URL publik dan alt tersimpan tanpa mengekspos raw path", async ({ page }) => {
  await openAsAdmin(page, "/admin/konten");
  const poster = page.getByRole("img", { name: fixture.posterAlternativeText });
  await expect(poster).toBeVisible();
  await expect(poster).toHaveAttribute("src", /\/storage\/v1\/object\/public\/public-media\//);
  await expect(page.getByText(fixture.posterMediaPath, { exact: true })).toHaveCount(0);
  await expectNoSeriousAxeFindings(page);
});

test("matriks route Admin nyata menjaga heading, desktop enam link, dan tanpa overflow", async ({
  page,
}) => {
  await page.setViewportSize({ height: 900, width: 1440 });
  const routes = [
    ["/admin", "Dashboard"],
    ["/admin/program", "Program"],
    [`/admin/program/${fixture.programId}`, fixture.programTitle],
    [`/admin/program/${fixture.programId}/edit`, fixture.programTitle],
    ["/admin/program/baru", "Program baru"],
    ["/admin/orang", "Orang"],
    ["/admin/konten", "Poster pemenang"],
    ["/admin/pengaturan#audit", "Pengaturan"],
  ] as const;
  for (const [path, heading] of routes) {
    await openAsAdmin(page, path);
    await expect(page.getByRole("heading", { level: 1, name: heading })).toBeVisible();
    expect(
      await page.evaluate(
        () => document.documentElement.scrollWidth <= document.documentElement.clientWidth,
      ),
    ).toBe(true);
  }
  const desktopNavigation = page.locator("nav.shell-navigation--admin:visible");
  await expect(desktopNavigation.getByRole("link")).toHaveCount(6);
  await expect(desktopNavigation.getByRole("link", { name: "Pembayaran" })).toBeVisible();
  await expectNoSeriousAxeFindings(page);
});
