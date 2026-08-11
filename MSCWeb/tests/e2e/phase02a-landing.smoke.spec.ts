import AxeBuilder from "@axe-core/playwright";
import { expect, test, type Page } from "@playwright/test";

async function dispatchInstallPrompt(page: Page, outcome: "accepted" | "dismissed") {
  await page.evaluate((choice) => {
    const installEvent = new Event("beforeinstallprompt", { cancelable: true });
    Object.assign(installEvent, {
      prompt: async () => {
        const state = window as typeof window & { __installPromptCalls?: number };
        state.__installPromptCalls = (state.__installPromptCalls ?? 0) + 1;
      },
      userChoice: Promise.resolve({ outcome: choice, platform: "web" }),
    });
    window.dispatchEvent(installEvent);
  }, outcome);
}

test("landing anonymous public-safe, SEO-ready, dan tidak shared-cache personalized HTML", async ({
  page,
  request,
}) => {
  const response = await page.goto("/");
  expect(response?.ok()).toBe(true);
  await expect(
    page.getByRole("heading", { name: "Transformasi lebih terarah, bersama Coach." }),
  ).toBeVisible();

  const html = await response?.text();
  expect(html).not.toContain("privateEnrollmentCount");
  expect(html).not.toContain("privateEmail");
  expect(html).not.toContain("service_role");
  expect(response?.headers()["cache-control"] ?? "").not.toContain("public");
  const canonical = await page.locator('link[rel="canonical"]').getAttribute("href");
  expect(canonical).toBeTruthy();
  expect(new URL(canonical ?? "http://invalid.test").search).toBe("");
  await expect(page.locator('meta[property="og:locale"]')).toHaveAttribute("content", "id_ID");
  const structuredData = await page
    .locator('script[type="application/ld\+json"]')
    .evaluate((script) => script.textContent);
  expect(structuredData).toContain("WebSite");
  const socialImageUrl = await page.locator('meta[property="og:image"]').getAttribute("content");
  expect(socialImageUrl).toBeTruthy();
  const socialImage = await request.get(new URL(socialImageUrl ?? "http://invalid.test").pathname);
  expect(socialImage.headers()["content-type"]).toContain("image/png");
  expect((await socialImage.body()).byteLength).toBeLessThanOrEqual(300_000);

  const robots = await request.get("/robots.txt");
  expect(await robots.text()).toContain("Disallow: /admin/");
  const sitemap = await request.get("/sitemap.xml");
  const sitemapBody = await sitemap.text();
  expect(sitemapBody).toContain("/program");
  expect(sitemapBody).not.toContain("/admin");

  for (const route of ["/privasi", "/ketentuan", "/bantuan"]) {
    expect((await request.get(route)).ok()).toBe(true);
  }
});

test("standalone signal mengganti CTA menjadi Buka aplikasi", async ({ page }) => {
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
  await page.goto("/");
  await expect(
    page.locator("#hero-install-anchor").getByRole("link", { name: "Buka aplikasi" }),
  ).toHaveAttribute("href", "/program");
});

test("hero, FAQ, section navigation, dan sticky CTA tetap keyboard-friendly", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/");
  const programLink = page.getByRole("link", { name: "Lihat program" });
  await expect(programLink).toHaveAttribute("href", "/program");
  await programLink.focus();
  await page.keyboard.press("Enter");
  await expect(page).toHaveURL(/\/program$/);
  await page.goto("/");
  await expect(page.locator("html")).toHaveAttribute("data-pwa-install-controller", "ready");
  await expect(page.locator("html")).toHaveAttribute("data-pwa-service-worker", "ready");

  const menu = page.locator(".marketing-menu > summary");
  await menu.focus();
  await expect(menu).toBeFocused();
  await menu.click();
  await expect(page.locator(".marketing-menu")).toHaveJSProperty("open", true);
  await expect(page.getByRole("navigation", { name: "Navigasi utama mobile" })).toBeVisible();
  await expect(
    page.getByRole("navigation", { name: "Navigasi utama mobile" }).getByRole("link", {
      name: "Program",
    }),
  ).toHaveAttribute("href", "/program");

  const faq = page.getByText("Apa itu MSC Body Transformation?");
  await faq.click();
  await expect(
    page
      .locator("details")
      .filter({ hasText: "Apa itu MSC Body Transformation?" })
      .getByText(/bukan pengganti diagnosis/i),
  ).toBeVisible();

  await page.locator("#cara-kerja").scrollIntoViewIfNeeded();
  const stickyBar = page.locator('.sticky-install[data-visible="true"]');
  await expect(stickyBar).toBeVisible();
  const stickyAction = stickyBar.locator("a, button");
  await expect(stickyAction).toBeVisible();
  await expect(stickyAction).toHaveText(
    /Unduh MSC|Cara memasang(?: di iPhone)?|Gunakan di browser|Buka aplikasi/,
  );
});

for (const outcome of ["accepted", "dismissed"] as const) {
  test(`Chromium custom prompt ${outcome} dikonsumsi satu kali`, async ({ browserName, page }) => {
    test.skip(browserName !== "chromium", "Custom beforeinstallprompt diuji pada Chromium.");
    await page.goto("/");
    await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
    await dispatchInstallPrompt(page, outcome);
    const heroAction = page
      .locator("#hero-install-anchor")
      .getByRole("button", { name: "Unduh MSC" });
    await expect(heroAction).toBeVisible();
    await heroAction.click();
    await expect
      .poll(() =>
        page.evaluate(
          () => (window as typeof window & { __installPromptCalls?: number }).__installPromptCalls,
        ),
      )
      .toBe(1);
    await expect(
      page.locator("#hero-install-anchor").getByRole("link", { name: "Gunakan di browser" }),
    ).toBeVisible();
  });
}

test("WebKit iPhone membuka guidance, Escape menutup, dan fokus kembali", async ({
  browserName,
  page,
}) => {
  test.skip(browserName !== "webkit", "Fallback iPhone diuji dengan engine WebKit.");
  await page.addInitScript(() => {
    Object.defineProperty(navigator, "platform", { configurable: true, get: () => "iPhone" });
    Object.defineProperty(navigator, "userAgent", {
      configurable: true,
      get: () => "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X)",
    });
    Object.defineProperty(navigator, "maxTouchPoints", { configurable: true, get: () => 5 });
  });
  await page.goto("/");
  const heroAction = page
    .locator("#hero-install-anchor")
    .getByRole("button", { name: "Cara memasang di iPhone" });
  await heroAction.click();
  await expect(page.getByRole("dialog", { name: "Cara memasang MSC" })).toBeVisible();
  await page.keyboard.press("Escape");
  await expect(page.getByRole("dialog", { name: "Cara memasang MSC" })).not.toBeVisible();
  await expect(heroAction).toBeFocused();
});

test("landing responsif pada mobile, tablet, dan desktop tanpa overflow", async ({ page }) => {
  for (const viewport of [
    { width: 390, height: 844 },
    { width: 768, height: 1024 },
    { width: 1024, height: 900 },
    { width: 1440, height: 1000 },
  ]) {
    await page.setViewportSize(viewport);
    await page.goto("/");
    await expect(
      page.getByRole("figure", { name: /Pratinjau placeholder antarmuka PWA/i }),
    ).toBeVisible();
    const dimensions = await page.evaluate(() => ({
      page: document.documentElement.scrollWidth,
      viewport: window.innerWidth,
    }));
    expect(dimensions.page, `${viewport.width}px`).toBeLessThanOrEqual(dimensions.viewport);
  }
});

test("landing lulus axe dan 320px dengan zoom 400 persen tidak overflow horizontal", async ({
  page,
}) => {
  await page.emulateMedia({ colorScheme: "dark", contrast: "more", reducedMotion: "reduce" });
  await page.setViewportSize({ width: 320, height: 900 });
  await page.goto("/");
  await expect(page.locator("html")).toHaveAttribute("data-pwa-install-controller", "ready");
  await page.evaluate(() => {
    document.documentElement.style.fontSize = "400%";
  });
  await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
  const widths = await page.evaluate(() => {
    const overflow = [...document.querySelectorAll<HTMLElement>("body *")]
      .map((element) => ({ element, bounds: element.getBoundingClientRect() }))
      .filter(({ bounds }) => bounds.right > window.innerWidth + 1 || bounds.left < -1)
      .sort((left, right) => right.bounds.right - left.bounds.right)
      .slice(0, 8)
      .map(({ bounds, element }) => ({
        className: element.className,
        left: Math.round(bounds.left),
        right: Math.round(bounds.right),
        tag: element.tagName,
        text: element.textContent?.trim().slice(0, 40),
        width: Math.round(bounds.width),
      }));
    return {
      overflow,
      page: document.documentElement.scrollWidth,
      viewport: window.innerWidth,
    };
  });
  expect(widths.page, JSON.stringify(widths.overflow)).toBeLessThanOrEqual(widths.viewport);

  await page.evaluate(() => {
    document.documentElement.style.fontSize = "100%";
  });
  const results = await new AxeBuilder({ page }).analyze();
  const blocking = results.violations.filter(
    (violation) => violation.impact === "serious" || violation.impact === "critical",
  );
  expect(blocking).toEqual([]);
});
