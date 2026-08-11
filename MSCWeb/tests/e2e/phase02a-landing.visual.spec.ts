import { expect, test } from "@playwright/test";

async function hideDevelopmentToolbar(page: import("@playwright/test").Page) {
  await page.addStyleTag({ content: "nextjs-portal { display: none !important; }" });
}

async function waitForLandingReady(page: import("@playwright/test").Page) {
  await expect(page.locator("html")).toHaveAttribute("data-pwa-install-controller", "ready");
  await expect(
    page.locator("#hero-install-anchor").getByRole("link", { name: "Gunakan di browser" }),
  ).toBeVisible();
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
  await expect(page).toHaveScreenshot("landing-mobile-light.png", { animations: "disabled" });
});

test("visual landing mobile dark", async ({ page }) => {
  await page.emulateMedia({ colorScheme: "dark", reducedMotion: "reduce" });
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/");
  await waitForLandingReady(page);
  await hideDevelopmentToolbar(page);
  await expect(page).toHaveScreenshot("landing-mobile-dark.png", { animations: "disabled" });
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
  });
});
