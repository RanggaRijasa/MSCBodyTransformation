import AxeBuilder from "@axe-core/playwright";
import { expect, test, type Locator, type Page } from "@playwright/test";

import {
  addCoachVisualSession,
  cleanupCoachVisualFixture,
  createCoachVisualFixture,
  hasCoachVisualEnvironment,
  coachVisualSkipReason,
  type CoachVisualFixture,
} from "./support/phase11a-coach-fixture";

let fixture: CoachVisualFixture;

test.skip(!hasCoachVisualEnvironment, coachVisualSkipReason);
test.describe.configure({ mode: "serial" });

test.beforeAll(async () => {
  fixture = await createCoachVisualFixture();
});

test.afterAll(async () => {
  if (fixture) await cleanupCoachVisualFixture(fixture);
});

async function expectOpaque(locator: Locator) {
  const presentation = await locator.evaluate((element) => {
    const style = getComputedStyle(element);
    return { background: style.backgroundColor, opacity: style.opacity };
  });
  expect(presentation.background).not.toBe("rgba(0, 0, 0, 0)");
  expect(presentation.opacity).toBe("1");
}

async function expectNoCriticalAxe(page: Page) {
  const results = await new AxeBuilder({ page }).analyze();
  expect(
    results.violations.filter(({ impact }) => impact === "critical" || impact === "serious"),
  ).toEqual([]);
}

async function hideDevelopmentChrome(page: Page) {
  await page.addStyleTag({ content: "nextjs-portal { display: none !important; }" });
  await page.locator("nextjs-portal").evaluateAll((portals) => {
    portals.forEach((portal) => portal.remove());
  });
}

async function expectNoHorizontalOverflow(page: Page) {
  const dimensions = await page.evaluate(() => ({
    clientWidth: document.documentElement.clientWidth,
    offenders: Array.from(document.querySelectorAll<HTMLElement>("body *"))
      .filter((element) => {
        const bounds = element.getBoundingClientRect();
        return bounds.right > document.documentElement.clientWidth + 1 || bounds.left < -1;
      })
      .slice(0, 12)
      .map((element) => ({
        className: element.className,
        right: Math.round(element.getBoundingClientRect().right),
        tagName: element.tagName,
      })),
    scrollWidth: document.documentElement.scrollWidth,
  }));
  expect(dimensions.scrollWidth, JSON.stringify(dimensions.offenders)).toBeLessThanOrEqual(
    dimensions.clientWidth,
  );
}

for (const colorScheme of ["light", "dark"] as const) {
  test(`Dashboard Coach 390 ${colorScheme} menjaga hierarki, privasi, dan tiga tab`, async ({
    context,
    page,
  }, testInfo) => {
    await addCoachVisualSession(context, fixture);
    await page.emulateMedia({ colorScheme });
    await page.setViewportSize({ height: 844, width: 390 });
    await page.goto("/coach-area");
    await hideDevelopmentChrome(page);
    const main = page.locator("#app-main-content");

    const screenTitle = main.getByRole("heading", { level: 1, name: "Dashboard" });
    await expect(screenTitle).toBeVisible();
    expect(
      await screenTitle.evaluate((element) =>
        Number.parseFloat(getComputedStyle(element).fontSize),
      ),
    ).toBeGreaterThanOrEqual(32);
    await expect(
      main.getByRole("heading", { level: 2, name: "Coach Visual Phase 11A" }),
    ).toBeVisible();
    const actions = main.getByRole("navigation", { name: "Tindakan cepat Coach" });
    await expect(actions.getByRole("link")).toHaveCount(6);
    expect(await actions.locator("strong").allTextContents()).toEqual([
      "Periksa bukti",
      "Peserta saya",
      "Aktivitas terbaru",
      "Peringkat",
      "Program saya",
      "QR pendaftaran",
    ]);
    await expect(actions.getByRole("link", { name: "Aktivitas terbaru" })).toHaveAttribute(
      "href",
      "/coach-area/program#aktivitas",
    );
    await expect(actions.getByRole("link", { name: /Peringkat/ })).toHaveAttribute(
      "href",
      "/coach-area/program#peringkat",
    );
    for (const action of await actions.getByRole("link").all()) {
      const box = await action.boundingBox();
      expect(box?.height).toBeGreaterThanOrEqual(44);
      expect(box?.width).toBeGreaterThanOrEqual(44);
    }
    const navigation = page.getByRole("navigation", { name: "Navigasi Coach" });
    await expect(navigation.getByRole("link")).toHaveCount(3);
    expect(await navigation.getByRole("link").allTextContents()).toEqual([
      "Dashboard",
      "Program",
      "Profil",
    ]);
    await expect(main.getByText(/\bkg\b|\+628|bukti transfer/i)).toHaveCount(0);
    const identity = main.locator(".coach-identity-card");
    await expectOpaque(identity);
    const [avatarBox, copyBox] = await Promise.all([
      identity.getByRole("img").boundingBox(),
      identity.getByRole("heading", { name: "Coach Visual Phase 11A" }).boundingBox(),
    ]);
    expect(avatarBox?.x).toBeLessThan(copyBox?.x ?? 0);
    expect(Math.abs((avatarBox?.y ?? 0) - (copyBox?.y ?? 0))).toBeLessThan(80);
    const summary = main.getByRole("region", { name: "Ringkasan pendampingan" });
    await expect(summary.locator(".coach-metrics > div")).toHaveCount(3);
    await expectOpaque(main.locator(".coach-quick-actions a").first());
    await expectNoHorizontalOverflow(page);
    await expectNoCriticalAxe(page);
    await hideDevelopmentChrome(page);
    await page.screenshot({
      animations: "disabled",
      fullPage: false,
      path: testInfo.outputPath(`coach-dashboard-390-${colorScheme}.png`),
    });
  });
}

test("Program Coach memakai anchor kanonis dan reflow pada 320/zoom 400%", async ({
  browserName,
  context,
  page,
}) => {
  await addCoachVisualSession(context, fixture);
  await page.setViewportSize({ height: 844, width: 320 });
  await page.goto(`/coach-area/program?program=${fixture.ids.program}&rentang=7`);
  await hideDevelopmentChrome(page);
  const main = page.locator("#app-main-content");
  const activity = main.getByRole("heading", { name: "Aktivitas" });
  const ranking = main.getByRole("heading", { name: "Papan peringkat" });

  await expect(activity).toHaveAttribute("id", "aktivitas");
  await expect(ranking).toHaveAttribute("id", "peringkat");
  await expect(main.getByText(/\bkg\b|\+628|bukti transfer/i)).toHaveCount(0);
  await expect(main.getByRole("img", { name: /bukti/i })).toHaveCount(0);
  await expectOpaque(main.locator(".coach-activity-feed .app-surface").first());

  const programLink = main.getByRole("link", { name: "Program Coach Phase 11A" });
  const tabKey = browserName === "webkit" ? "Alt+Tab" : "Tab";
  for (
    let index = 0;
    index < 20 && !(await programLink.evaluate((node) => node === document.activeElement));
    index += 1
  ) {
    await page.keyboard.press(tabKey);
  }
  await expect(programLink).toBeFocused();
  expect((await programLink.boundingBox())?.height).toBeGreaterThanOrEqual(44);

  await page.evaluate(() => {
    document.documentElement.style.fontSize = "400%";
  });
  await expectNoHorizontalOverflow(page);
  await expect(activity).toBeVisible();
});

test("Pemeriksaan Coach mempertahankan detail inline, fokus, dan data privat terkontrol", async ({
  browserName,
  context,
  page,
}, testInfo) => {
  await addCoachVisualSession(context, fixture);
  await page.setViewportSize({ height: 844, width: 390 });
  await page.goto("/coach-area/pemeriksaan");
  await hideDevelopmentChrome(page);
  const main = page.locator("#app-main-content");
  const review = main.locator(".coach-review-card").first();

  await expect(main.getByRole("heading", { level: 1, name: "Antrean pemeriksaan" })).toBeVisible();
  await expect(review.getByRole("heading", { name: "Peserta Dampingan Visual" })).toBeVisible();
  await expect(review.getByText("Kunci jawaban")).toBeVisible();
  await expect(review.getByText("Menjaga konsistensi.", { exact: true })).toHaveCount(2);
  await expect(main.getByText(/\bkg\b|\+628|bukti transfer/i)).toHaveCount(0);
  await expectOpaque(review);

  const reject = review.getByRole("button", { name: "Tolak" });
  const tabKey = browserName === "webkit" ? "Alt+Tab" : "Tab";
  for (
    let index = 0;
    index < 30 && !(await reject.evaluate((node) => node === document.activeElement));
    index += 1
  ) {
    await page.keyboard.press(tabKey);
  }
  await expect(reject).toBeFocused();
  expect((await reject.boundingBox())?.height).toBeGreaterThanOrEqual(44);
  await expectNoHorizontalOverflow(page);
  await expectNoCriticalAxe(page);
  await hideDevelopmentChrome(page);
  await page.screenshot({
    animations: "disabled",
    fullPage: false,
    path: testInfo.outputPath("coach-review-inline-390.png"),
  });
});
