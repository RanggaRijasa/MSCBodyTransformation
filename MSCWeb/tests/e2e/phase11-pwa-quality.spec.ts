import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "@playwright/test";

test("manifest, release screenshots, dan header hardening konsisten", async ({ page, request }) => {
  const response = await page.goto("/");
  expect(response?.headers()["content-security-policy"]).toContain("frame-ancestors 'none'");
  expect(response?.headers()["strict-transport-security"]).toContain("max-age=63072000");
  expect(response?.headers()["x-content-type-options"]).toBe("nosniff");
  expect(response?.headers()["x-correlation-id"]).toMatch(/^[0-9a-f-]{36}$/i);
  expect(response?.headers()["cache-control"]).toContain("no-store");
  await expect(page.getByAltText(/papan peringkat Peserta/i)).toBeVisible();
  await expect(page.getByAltText(/Dashboard Coach MSC/i)).toBeVisible();
  expect(await page.getByText(/placeholder|tampilan contoh/i).count()).toBe(0);

  const manifestResponse = await request.get("/manifest.webmanifest");
  const manifest = (await manifestResponse.json()) as {
    display?: string;
    icons?: unknown[];
    screenshots?: Array<{ form_factor?: string; src?: string }>;
    scope?: string;
    start_url?: string;
  };
  expect(manifest).toMatchObject({ display: "standalone", scope: "/", start_url: "/hari-ini" });
  expect(manifest.icons).toHaveLength(3);
  expect(manifest.screenshots).toEqual(
    expect.arrayContaining([
      expect.objectContaining({ form_factor: "narrow", src: "/images/pwa-participant-rc-v1.jpg" }),
      expect.objectContaining({ form_factor: "wide", src: "/images/pwa-coach-rc-v1.jpg" }),
    ]),
  );
});

test("service worker hanya menyimpan aset publik dan fallback navigasi generik", async ({
  browserName,
  context,
  page,
}) => {
  test.skip(browserName !== "chromium", "Cache Storage dan mode offline diuji pada Chromium.");
  await page.goto("/");
  await page.evaluate(() => navigator.serviceWorker.ready);
  await page.reload();
  await expect
    .poll(() => page.evaluate(() => Boolean(navigator.serviceWorker.controller)))
    .toBe(true);

  const cachedUrls = await page.evaluate(async () => {
    const names = await caches.keys();
    const requests = await Promise.all(
      names.map(async (name) => (await (await caches.open(name)).keys()).map((entry) => entry.url)),
    );
    return requests.flat();
  });
  expect(cachedUrls.length).toBeGreaterThan(0);
  expect(cachedUrls.join("\n")).not.toMatch(
    /\/api\/|\/auth\/|supabase|signed|payment|pembayaran|weight|berat|question|jawaban|qr/i,
  );

  await page.evaluate(async () => {
    localStorage.setItem("msc.private-test", "rahasia");
    localStorage.setItem("unrelated", "tetap");
    sessionStorage.setItem("msc.session-test", "rahasia");
    await caches.open("msc-pwa-runtime-test");
    const channel = new BroadcastChannel("msc-auth-session");
    channel.postMessage({ event: "SIGNED_OUT" });
    channel.close();
  });
  await expect.poll(() => page.evaluate(() => localStorage.getItem("msc.private-test"))).toBeNull();
  expect(await page.evaluate(() => localStorage.getItem("unrelated"))).toBe("tetap");
  await expect
    .poll(() => page.evaluate(async () => (await caches.keys()).includes("msc-pwa-runtime-test")))
    .toBe(false);

  await context.setOffline(true);
  await expect(page.getByText("Kamu sedang offline")).toBeVisible();
  const mutationResult = await page.evaluate(async () => {
    try {
      await fetch("/api/onboarding", { method: "POST", body: "{}" });
      return "unexpected-success";
    } catch {
      return "offline-failure";
    }
  });
  expect(mutationResult).toBe("offline-failure");
  await page.goto("/bantuan?offline-test=1");
  await expect(page.getByRole("heading", { name: "Kamu sedang offline" })).toBeVisible();
  await context.setOffline(false);
});

test("journey inti tetap accessible pada light, dark, dan 400 persen", async ({ page }) => {
  for (const route of ["/", "/masuk", "/hari-ini", "/coach-area"]) {
    await page.goto(route);
    const results = await new AxeBuilder({ page }).analyze();
    expect(
      results.violations.filter(
        (violation) => violation.impact === "serious" || violation.impact === "critical",
      ),
      route,
    ).toEqual([]);
  }

  await page.emulateMedia({ colorScheme: "dark", contrast: "more", reducedMotion: "reduce" });
  await page.setViewportSize({ width: 320, height: 900 });
  await page.goto("/");
  await page.evaluate(() => {
    document.documentElement.style.fontSize = "400%";
  });
  const dimensions = await page.evaluate(() => ({
    page: document.documentElement.scrollWidth,
    viewport: window.innerWidth,
  }));
  expect(dimensions.page).toBeLessThanOrEqual(dimensions.viewport);
});

test("landing lulus Web Vitals pada simulasi mobile menengah dan jaringan lambat", async ({
  browserName,
  page,
}) => {
  test.skip(browserName !== "chromium", "Throttling CDP hanya tersedia pada Chromium.");
  const session = await page.context().newCDPSession(page);
  await session.send("Network.enable");
  await session.send("Network.emulateNetworkConditions", {
    connectionType: "cellular3g",
    downloadThroughput: 200_000,
    latency: 150,
    offline: false,
    uploadThroughput: 80_000,
  });
  await session.send("Emulation.setCPUThrottlingRate", { rate: 4 });
  await page.setViewportSize({ width: 390, height: 844 });
  await page.addInitScript(() => {
    const metrics = { cls: 0, inp: 0, lcp: 0 };
    Object.assign(window, { __phase11Vitals: metrics });
    new PerformanceObserver((list) => {
      for (const entry of list.getEntries()) metrics.lcp = entry.startTime;
    }).observe({ buffered: true, type: "largest-contentful-paint" });
    new PerformanceObserver((list) => {
      for (const entry of list.getEntries() as Array<
        PerformanceEntry & { hadRecentInput?: boolean; value?: number }
      >) {
        if (!entry.hadRecentInput) metrics.cls += entry.value ?? 0;
      }
    }).observe({ buffered: true, type: "layout-shift" });
    new PerformanceObserver((list) => {
      for (const entry of list.getEntries()) metrics.inp = Math.max(metrics.inp, entry.duration);
    }).observe({ buffered: true, type: "event" });
  });
  const apiRequests: string[] = [];
  page.on("request", (request) => {
    if (/\/api\/|\/rest\/v1\//.test(request.url())) apiRequests.push(request.url());
  });
  await page.goto("/", { waitUntil: "networkidle" });
  await page.getByText("Apa itu MSC Body Transformation?").click();
  await page.waitForTimeout(500);
  const metrics = await page.evaluate(
    () =>
      (window as typeof window & { __phase11Vitals: { cls: number; inp: number; lcp: number } })
        .__phase11Vitals,
  );
  expect(metrics.lcp).toBeLessThanOrEqual(4_500);
  expect(metrics.cls).toBeLessThanOrEqual(0.1);
  expect(metrics.inp).toBeLessThanOrEqual(300);
  expect(apiRequests).toHaveLength(0);
});
