import { expect, test } from "@playwright/test";

async function hideDevelopmentToolbar(page: import("@playwright/test").Page) {
  await page.addStyleTag({ content: "nextjs-portal { display: none !important; }" });
}

test("visual Peserta mobile light", async ({ browserName, page }) => {
  test.skip(browserName !== "chromium", "Visual baseline tunggal memakai Chromium.");
  await page.emulateMedia({ colorScheme: "light", reducedMotion: "reduce" });
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/hari-ini");
  await hideDevelopmentToolbar(page);

  await expect(page).toHaveScreenshot("participant-mobile-light.png", {
    animations: "disabled",
  });
});

test("visual Peserta mobile dark", async ({ browserName, page }) => {
  test.skip(browserName !== "chromium", "Visual baseline tunggal memakai Chromium.");
  await page.emulateMedia({ colorScheme: "dark", reducedMotion: "reduce" });
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/hari-ini");
  await hideDevelopmentToolbar(page);

  await expect(page).toHaveScreenshot("participant-mobile-dark.png", {
    animations: "disabled",
  });
});

test("visual Admin desktop", async ({ browserName, page }) => {
  test.skip(browserName !== "chromium", "Visual baseline tunggal memakai Chromium.");
  await page.emulateMedia({ colorScheme: "light", reducedMotion: "reduce" });
  await page.setViewportSize({ width: 1440, height: 1000 });
  await page.goto("/admin");
  await hideDevelopmentToolbar(page);

  await expect(page).toHaveScreenshot("admin-desktop-light.png", {
    animations: "disabled",
    fullPage: true,
  });
});
