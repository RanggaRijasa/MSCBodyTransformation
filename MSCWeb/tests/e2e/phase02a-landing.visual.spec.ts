import { expect, test } from "@playwright/test";

async function hideDevelopmentToolbar(page: import("@playwright/test").Page) {
  await page.addStyleTag({
    content: "nextjs-portal, .sticky-install { display: none !important; }",
  });
}

async function waitForLandingReady(page: import("@playwright/test").Page) {
  await expect(page.locator("html")).toHaveAttribute("data-pwa-install-controller", "ready");
  await expect(page.locator("html")).toHaveAttribute("data-pwa-service-worker", "ready");
  await page.evaluate(() => {
    const installEvent = new Event("beforeinstallprompt", { cancelable: true });
    Object.assign(installEvent, {
      prompt: async () => undefined,
      userChoice: Promise.resolve({ outcome: "accepted", platform: "web" }),
    });
    window.dispatchEvent(installEvent);
  });
  await expect(
    page.locator("#hero-install-anchor").getByRole("button", { name: "Unduh MSC" }),
  ).toBeVisible();
  await expect
    .poll(() =>
      page.locator("img").evaluateAll((images) =>
        images.every((image) => {
          const loadedImage = image as HTMLImageElement;
          return loadedImage.complete && loadedImage.naturalWidth > 0;
        }),
      ),
    )
    .toBe(true);
}

test.beforeEach(({ browserName }) => {
  test.skip(browserName !== "chromium", "Visual baseline tunggal memakai Chromium.");
});

test("visual landing desktop light", async ({ page }) => {
  await page.emulateMedia({ colorScheme: "light", reducedMotion: "reduce" });
  await page.setViewportSize({ width: 1440, height: 1000 });
  await page.goto("/");
  await waitForLandingReady(page);
  await hideDevelopmentToolbar(page);
  await expect(page).toHaveScreenshot("landing-desktop-light.png", {
    animations: "disabled",
    fullPage: true,
  });
});

test("visual landing mobile light", async ({ page }) => {
  await page.emulateMedia({ colorScheme: "light", reducedMotion: "reduce" });
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/");
  await waitForLandingReady(page);
  await hideDevelopmentToolbar(page);
  await expect(page).toHaveScreenshot("landing-mobile-light.png", {
    animations: "disabled",
    fullPage: true,
  });
});

test("visual landing mobile dark", async ({ page }) => {
  await page.emulateMedia({ colorScheme: "dark", reducedMotion: "reduce" });
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/");
  await waitForLandingReady(page);
  await hideDevelopmentToolbar(page);
  await expect(page).toHaveScreenshot("landing-mobile-dark.png", {
    animations: "disabled",
    fullPage: true,
  });
});

test("visual landing tablet", async ({ page }) => {
  await page.emulateMedia({ colorScheme: "dark", reducedMotion: "reduce" });
  await page.setViewportSize({ width: 768, height: 1024 });
  await page.goto("/");
  await waitForLandingReady(page);
  await hideDevelopmentToolbar(page);
  await expect(page).toHaveScreenshot("landing-tablet-dark.png", {
    animations: "disabled",
    fullPage: true,
  });
});

test("visual landing 320px large text", async ({ page }) => {
  await page.emulateMedia({ colorScheme: "light", reducedMotion: "reduce" });
  await page.setViewportSize({ width: 320, height: 900 });
  await page.goto("/");
  await waitForLandingReady(page);
  await page.evaluate(() => {
    document.documentElement.style.fontSize = "200%";
  });
  await hideDevelopmentToolbar(page);
  await expect(page).toHaveScreenshot("landing-mobile-large-text.png", {
    animations: "disabled",
    fullPage: true,
  });
});
