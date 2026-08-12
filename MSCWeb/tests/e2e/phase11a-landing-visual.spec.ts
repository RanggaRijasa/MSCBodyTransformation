import AxeBuilder from "@axe-core/playwright";
import { expect, test, type Page, type TestInfo } from "@playwright/test";

async function dispatchInstallPrompt(page: Page, outcome: "accepted" | "dismissed") {
  await page.evaluate((choice) => {
    const installEvent = new Event("beforeinstallprompt", { cancelable: true });
    Object.assign(installEvent, {
      prompt: async () => undefined,
      userChoice: Promise.resolve({ outcome: choice, platform: "web" }),
    });
    window.dispatchEvent(installEvent);
  }, outcome);
}

async function captureInstallState(page: Page, testInfo: TestInfo, name: string) {
  await page.addStyleTag({ content: "nextjs-portal { display: none !important; }" });
  await page.evaluate(() => scrollTo(0, 0));
  await page.screenshot({
    animations: "disabled",
    fullPage: false,
    path: testInfo.outputPath(`${name}.png`),
  });
}

async function waitForLanding(page: Page) {
  await page.goto("/");
  await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
  await expect(page.locator("html")).toHaveAttribute("data-pwa-install-controller", "ready");
  await page.addStyleTag({ content: "nextjs-portal { display: none !important; }" });
}

async function captureLanding(
  page: Page,
  testInfo: TestInfo,
  name: string,
  colorScheme: "dark" | "light",
  viewport: Readonly<{ height: number; width: number }>,
) {
  await page.emulateMedia({ colorScheme, reducedMotion: "reduce" });
  await page.setViewportSize(viewport);
  await waitForLanding(page);
  const previewImages = page.locator(".landing-preview-card__image");
  await expect(previewImages).toHaveCount(3);
  await previewImages.first().scrollIntoViewIfNeeded();
  await expect
    .poll(() =>
      previewImages.evaluateAll((images) =>
        images.every(
          (image) => image instanceof HTMLImageElement && image.complete && image.naturalWidth > 0,
        ),
      ),
    )
    .toBe(true);
  await page.evaluate(() => scrollTo(0, 0));
  await page.screenshot({
    animations: "disabled",
    fullPage: true,
    path: testInfo.outputPath(`${name}-${colorScheme}.png`),
  });
}

for (const colorScheme of ["light", "dark"] as const) {
  test(`landing 390 ${colorScheme} menjaga hierarchy, CTA, dan media frame`, async ({
    page,
  }, testInfo) => {
    await page.emulateMedia({ colorScheme, reducedMotion: "reduce" });
    await page.setViewportSize({ height: 844, width: 390 });
    await waitForLanding(page);

    await expect(
      page.getByRole("heading", { level: 1, name: "Transformasi lebih terarah, bersama Coach." }),
    ).toBeVisible();
    await expect(
      page.getByRole("figure", { exact: true, name: "Pratinjau aplikasi" }),
    ).toBeVisible();
    await expect(page.locator(".sticky-install")).toHaveAttribute("data-visible", "false");
    await expect(page.locator("#hero-install-anchor > .app-action")).toBeVisible();

    const mediaFrames = page.locator(".landing-preview-card__media");
    await expect(mediaFrames).toHaveCount(3);
    await expect(page.locator(".landing-preview-card__image")).toHaveCount(3);
    for (const frame of await mediaFrames.all()) {
      const ratio = await frame.evaluate((element) => {
        const bounds = element.getBoundingClientRect();
        return bounds.width / bounds.height;
      });
      expect(ratio).toBeGreaterThan(1.3);
      expect(ratio).toBeLessThan(1.37);
    }

    const results = await new AxeBuilder({ page }).analyze();
    expect(
      results.violations.filter(({ impact }) => impact === "critical" || impact === "serious"),
    ).toEqual([]);
    await page.screenshot({
      animations: "disabled",
      fullPage: false,
      path: testInfo.outputPath(`landing-390-${colorScheme}.png`),
    });
  });
}

test("landing responsive matrix tidak overflow dan menghasilkan evidence aktual", async ({
  page,
}, testInfo) => {
  for (const candidate of [
    { colorScheme: "light", height: 900, name: "landing-320", width: 320 },
    { colorScheme: "dark", height: 932, name: "landing-430", width: 430 },
    { colorScheme: "dark", height: 1024, name: "landing-768", width: 768 },
    { colorScheme: "light", height: 1000, name: "landing-1440", width: 1440 },
  ] as const) {
    await captureLanding(page, testInfo, candidate.name, candidate.colorScheme, candidate);
    const dimensions = await page.evaluate(() => ({
      clientWidth: document.documentElement.clientWidth,
      scrollWidth: document.documentElement.scrollWidth,
    }));
    expect(dimensions.scrollWidth, candidate.name).toBeLessThanOrEqual(dimensions.clientWidth);
  }
});

test("landing 320 pada zoom 400 persen tetap reflow dan hash target tidak tertutup", async ({
  page,
}) => {
  await page.emulateMedia({ colorScheme: "dark", contrast: "more", reducedMotion: "reduce" });
  await page.setViewportSize({ height: 900, width: 320 });
  await waitForLanding(page);
  await page.evaluate(() => {
    document.documentElement.style.fontSize = "400%";
  });
  const dimensions = await page.evaluate(() => ({
    clientWidth: document.documentElement.clientWidth,
    scrollWidth: document.documentElement.scrollWidth,
  }));
  expect(dimensions.scrollWidth).toBeLessThanOrEqual(dimensions.clientWidth);

  await page.evaluate(() => {
    document.documentElement.style.fontSize = "100%";
  });
  await page.goto("/#untuk-coach");
  const target = page.locator("#untuk-coach");
  await expect(target).toBeFocused();
  await expect
    .poll(() =>
      target.evaluate((element) => {
        const header = document.querySelector<HTMLElement>(".marketing-header");
        return (
          element.getBoundingClientRect().top >= (header?.getBoundingClientRect().bottom ?? 0) - 1
        );
      }),
    )
    .toBe(true);
});

test("landing forced colors mempertahankan fokus dan hierarki tindakan", async ({ page }) => {
  await page.emulateMedia({ forcedColors: "active", reducedMotion: "reduce" });
  await page.setViewportSize({ height: 844, width: 390 });
  await waitForLanding(page);
  test.skip(
    !(await page.evaluate(() => matchMedia("(forced-colors: active)").matches)),
    "Engine tidak mengemulasi forced colors.",
  );

  const programLink = page.getByRole("link", { name: "Lihat program" });
  await programLink.focus();
  await expect(programLink).not.toHaveCSS("outline-style", "none");
  expect(
    Number.parseFloat(
      await programLink.evaluate((element) => getComputedStyle(element).outlineWidth),
    ),
  ).toBeGreaterThanOrEqual(2);
  await expect(page.locator("#hero-install-anchor > .app-action")).toBeVisible();
  await expect(page.locator(".sticky-install")).toHaveAttribute("data-visible", "false");
});

test("Chromium prompt-ready dan dismissed memiliki evidence aktual", async ({
  browserName,
  page,
}, testInfo) => {
  test.skip(browserName !== "chromium", "beforeinstallprompt hanya tersedia pada Chromium.");
  await page.setViewportSize({ height: 844, width: 390 });
  await waitForLanding(page);
  await dispatchInstallPrompt(page, "dismissed");
  await expect(page.locator("html")).toHaveAttribute("data-pwa-install-state", "prompt-ready");
  const installAction = page
    .locator("#hero-install-anchor")
    .getByRole("button", { name: "Unduh MSC" });
  await expect(installAction).toBeVisible();
  await captureInstallState(page, testInfo, "landing-install-prompt-ready-390-light");

  await installAction.click();
  await expect(page.locator("html")).toHaveAttribute("data-pwa-install-state", "dismissed");
  await expect(
    page.locator("#hero-install-anchor").getByRole("link", { name: "Gunakan di browser" }),
  ).toBeVisible();
  const installAnnouncement = page.getByText(
    "Permintaan pemasangan sudah ditampilkan. Kamu tetap dapat menggunakan MSC di browser.",
  );
  await expect(installAnnouncement).toBeVisible();
  await expect(installAnnouncement).not.toBeVisible({ timeout: 7_000 });
  await captureInstallState(page, testInfo, "landing-install-dismissed-390-light");
});

test("WebKit iPhone menampilkan guidance aktual", async ({ browserName, page }, testInfo) => {
  test.skip(browserName !== "webkit", "Guidance iPhone dibuktikan dengan engine WebKit.");
  await page.addInitScript(() => {
    Object.defineProperty(navigator, "platform", { configurable: true, get: () => "iPhone" });
    Object.defineProperty(navigator, "userAgent", {
      configurable: true,
      get: () => "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X)",
    });
    Object.defineProperty(navigator, "maxTouchPoints", { configurable: true, get: () => 5 });
  });
  await page.setViewportSize({ height: 844, width: 390 });
  await waitForLanding(page);
  await expect(page.locator("html")).toHaveAttribute("data-pwa-install-state", "ios-guidance");
  await page
    .locator("#hero-install-anchor")
    .getByRole("button", { name: "Cara memasang di iPhone" })
    .click();
  await expect(page.getByRole("dialog", { name: "Cara memasang MSC" })).toBeVisible();
  await expect(
    page.getByText(
      "Di Safari, buka menu Bagikan, lalu pilih Tambahkan ke Layar Utama. Nama menu dapat berbeda menurut versi iOS.",
      { exact: true },
    ),
  ).toHaveCount(1);
  await captureInstallState(page, testInfo, "landing-install-ios-guidance-390-light");
});

test("standalone menampilkan Buka aplikasi pada kedua engine", async ({ page }, testInfo) => {
  await page.addInitScript(() => {
    const nativeMatchMedia = window.matchMedia.bind(window);
    window.matchMedia = (query: string) => {
      const result = nativeMatchMedia(query);
      if (query !== "(display-mode: standalone)") return result;
      return new Proxy(result, {
        get(target, property) {
          if (property === "matches") return true;
          const value: unknown = Reflect.get(target, property, target);
          return typeof value === "function" ? value.bind(target) : value;
        },
      });
    };
  });
  await page.setViewportSize({ height: 844, width: 390 });
  await waitForLanding(page);
  await expect(page.locator("html")).toHaveAttribute("data-pwa-install-state", "standalone");
  await expect(
    page.locator("#hero-install-anchor").getByRole("link", { name: "Buka aplikasi" }),
  ).toBeVisible();
  await captureInstallState(page, testInfo, "landing-install-standalone-390-light");
});

test("not-ready dan unsupported tetap menyediakan browser fallback", async ({ page }, testInfo) => {
  await page.addInitScript(() => {
    Reflect.deleteProperty(Navigator.prototype, "serviceWorker");
  });
  await page.setViewportSize({ height: 844, width: 390 });
  await page.goto("/");
  await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
  await expect(page.locator("html")).toHaveAttribute("data-pwa-install-state", "not-ready");
  await expect(
    page.locator("#hero-install-anchor").getByRole("link", { name: "Gunakan di browser" }),
  ).toBeVisible();
  await captureInstallState(page, testInfo, "landing-install-not-ready-390-light");

  await page.evaluate(() => {
    document.documentElement.dataset.pwaServiceWorker = "ready";
    window.dispatchEvent(new Event("msc:pwa-ready"));
  });
  await expect(page.locator("html")).toHaveAttribute("data-pwa-install-state", "unsupported");
  await captureInstallState(page, testInfo, "landing-install-unsupported-390-light");
});
