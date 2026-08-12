import AxeBuilder from "@axe-core/playwright";
import { expect, test, type Locator, type Page } from "@playwright/test";

import {
  addParticipantVisualSession,
  cleanupParticipantVisualFixture,
  createParticipantVisualFixture,
  hasParticipantVisualEnvironment,
  participantVisualSkipReason,
  type ParticipantVisualFixture,
} from "./support/phase11a-participant-fixture";

let fixture: ParticipantVisualFixture;

test.skip(!hasParticipantVisualEnvironment, participantVisualSkipReason);
test.describe.configure({ mode: "serial" });

test.beforeAll(async () => {
  fixture = await createParticipantVisualFixture();
});

test.afterAll(async () => {
  if (fixture) await cleanupParticipantVisualFixture(fixture);
});

async function expectOpaque(locator: Locator) {
  const presentation = await locator.evaluate((element) => {
    const style = getComputedStyle(element);
    return {
      background: style.backgroundColor,
      backgroundImage: style.backgroundImage,
      opacity: style.opacity,
    };
  });
  expect(
    presentation.background !== "rgba(0, 0, 0, 0)" || presentation.backgroundImage !== "none",
  ).toBe(true);
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

for (const colorScheme of ["light", "dark"] as const) {
  test(`Beranda Peserta 390 ${colorScheme} menjaga hierarki, privasi, dan target`, async ({
    context,
    page,
  }, testInfo) => {
    await addParticipantVisualSession(context, fixture);
    await page.emulateMedia({ colorScheme });
    await page.setViewportSize({ height: 844, width: 390 });
    await page.goto(`/hari-ini?program=${fixture.ids.program}`);
    await hideDevelopmentChrome(page);
    const main = page.locator("#app-main-content");

    await expect(main.getByRole("heading", { level: 1, name: "Beranda" })).toBeVisible();
    await expect(
      main.getByRole("heading", { level: 2, name: "Peserta Visual Phase 11A" }),
    ).toBeVisible();
    await expect(main.getByRole("heading", { name: "Fokus hari ini" })).toBeVisible();
    await expect(main.getByRole("heading", { name: "Top 5" })).toBeVisible();
    await expect(main.getByRole("heading", { name: "Pemenang" })).toBeVisible();
    await expect(main.getByRole("heading", { exact: true, name: "Coach" })).toBeVisible();
    await expect(main.getByText("Denpasar")).toHaveCount(1);
    await expect(main.getByText(/\bkg\b|\+628|bukti transfer/i)).toHaveCount(0);
    await expectOpaque(main.locator(".participant-identity-card"));
    await expectOpaque(main.locator(".participant-program-chip").first());
    await expectOpaque(main.locator(".participant-focus-card"));
    await expect(
      main.getByRole("img", {
        name: /Aktivitas hari ini \d+ dari \d+ langkah selesai\. Progres program 0 persen\./,
      }),
    ).toHaveCSS("border-radius", /.+/);
    const programPresentation = await main
      .locator(".participant-program-chip")
      .first()
      .evaluate((element) => {
        const accentProbe = document.createElement("span");
        accentProbe.style.color = "var(--color-brand-accent)";
        document.body.append(accentProbe);
        const accent = getComputedStyle(accentProbe).color;
        accentProbe.remove();
        const style = getComputedStyle(element);
        return {
          accent,
          backgroundImage: style.backgroundImage,
          borderColor: style.borderColor,
          boxShadow: style.boxShadow,
        };
      });
    expect(programPresentation.backgroundImage).not.toBe("none");
    expect(programPresentation.borderColor).not.toBe(programPresentation.accent);
    expect(programPresentation.boxShadow).not.toContain(programPresentation.accent);

    const nextStep = main.getByRole("link", { name: "Lanjutkan" });
    const navigation = page.getByRole("navigation", { name: "Navigasi Peserta" });
    const [nextStepBox, navigationBox, progressBox] = await Promise.all([
      nextStep.boundingBox(),
      navigation.boundingBox(),
      main.locator(".participant-focus-card__progress").boundingBox(),
    ]);
    expect(nextStepBox?.height).toBeGreaterThanOrEqual(44);
    expect((nextStepBox?.y ?? Infinity) + (nextStepBox?.height ?? 0)).toBeLessThanOrEqual(
      navigationBox?.y ?? 0,
    );
    expect(Math.abs((progressBox?.width ?? 0) - (progressBox?.height ?? 0))).toBeLessThanOrEqual(1);
    await expect(nextStep).toHaveAttribute(
      "href",
      `/program/${fixture.ids.program}/langkah/${fixture.ids.step}`,
    );
    await expect(navigation.getByRole("link")).toHaveCount(5);
    expect(await navigation.getByRole("link").allTextContents()).toEqual([
      "Beranda",
      "Program",
      "Peringkat",
      "Coach",
      "Profil",
    ]);
    await expectNoCriticalAxe(page);
    await hideDevelopmentChrome(page);
    await page.screenshot({
      animations: "disabled",
      fullPage: false,
      path: testInfo.outputPath(`participant-home-390-${colorScheme}.png`),
    });
  });
}

test("Peserta 320 dan zoom 400% tetap reflow, fokus, serta kembali aman", async ({
  browserName,
  context,
  page,
}) => {
  await addParticipantVisualSession(context, fixture);
  await page.setViewportSize({ height: 844, width: 320 });
  await page.goto(`/hari-ini?program=${fixture.ids.program}`);
  await hideDevelopmentChrome(page);
  const main = page.locator("#app-main-content");
  const nextStep = main.getByRole("link", { name: "Lanjutkan" });

  const tabKey = browserName === "webkit" ? "Alt+Tab" : "Tab";
  for (
    let index = 0;
    index < 20 && !(await nextStep.evaluate((node) => node === document.activeElement));
    index += 1
  ) {
    await page.keyboard.press(tabKey);
  }
  await expect(nextStep).toBeFocused();
  expect(
    await nextStep.evaluate((element) => {
      const style = getComputedStyle(element);
      return style.boxShadow !== "none" || style.outlineStyle !== "none";
    }),
  ).toBe(true);

  await nextStep.click();
  await expect(page).toHaveURL(
    new RegExp(`/program/${fixture.ids.program}/langkah/${fixture.ids.step}$`),
  );
  await page.goBack();
  await expect(page).toHaveURL(new RegExp(`/hari-ini[?]program=${fixture.ids.program}$`));

  await page.evaluate(() => {
    document.documentElement.style.fontSize = "400%";
  });
  const dimensions = await page.evaluate(() => ({
    clientWidth: document.documentElement.clientWidth,
    scrollWidth: document.documentElement.scrollWidth,
  }));
  expect(dimensions.scrollWidth).toBeLessThanOrEqual(dimensions.clientWidth);
  await expect(main.getByRole("heading", { level: 1, name: "Beranda" })).toBeVisible();
});
