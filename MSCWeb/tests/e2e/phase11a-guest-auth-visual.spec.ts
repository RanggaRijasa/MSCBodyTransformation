import AxeBuilder from "@axe-core/playwright";
import { expect, test, type Locator, type Page, type TestInfo } from "@playwright/test";

const hasLocalEnvironment = Boolean(
  process.env.NEXT_PUBLIC_SUPABASE_URL && process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
);
const colorSchemes = ["light", "dark"] as const;

test.skip(!hasLocalEnvironment, "Memerlukan Supabase lokal untuk data publik Guest.");
test.describe.configure({ mode: "serial" });
test.setTimeout(90_000);

async function openRoute(page: Page, path: string, heading: string) {
  await page.goto(path);
  await expect
    .poll(() => new URL(page.url()).pathname)
    .toBe(new URL(path, "http://local").pathname);
  await expect(page.getByRole("heading", { level: 1, name: heading })).toBeVisible();
  await page.waitForLoadState("networkidle");
  await page.addStyleTag({ content: "nextjs-portal { display: none !important; }" });
}

async function expectNoSeriousAxeFindings(page: Page) {
  const result = await new AxeBuilder({ page }).analyze();
  expect(
    result.violations.filter(({ impact }) => impact === "critical" || impact === "serious"),
  ).toEqual([]);
}

async function expectMinimumTarget(locator: Locator) {
  const box = await locator.boundingBox();
  expect(box, "Target interaksi harus terlihat.").not.toBeNull();
  expect(box!.height).toBeGreaterThanOrEqual(44);
  expect(box!.width).toBeGreaterThanOrEqual(44);
}

async function expectNoHorizontalOverflow(page: Page) {
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= document.documentElement.clientWidth,
    ),
  ).toBe(true);
}

async function capture(page: Page, testInfo: TestInfo, name: string) {
  await page.screenshot({
    animations: "disabled",
    fullPage: false,
    path: testInfo.outputPath(`${name}-${testInfo.project.name}.png`),
  });
}

async function expectGuestPublicContract(page: Page) {
  const headings = [
    "Beranda",
    "Siap memulai perjalananmu?",
    "Program",
    "Fokus",
    "Top 5",
    "Pemenang",
    "Coach",
  ];
  const positions: number[] = [];
  for (const name of headings) {
    const heading = page.getByRole("heading", { name, exact: true });
    await expect(heading).toBeVisible();
    positions.push(
      await heading.evaluate((element) => element.getBoundingClientRect().top + window.scrollY),
    );
  }
  expect(positions).toEqual([...positions].sort((left, right) => left - right));

  const login = page.getByRole("link", { name: "Masuk", exact: true });
  await expect(login).toHaveAttribute("href", "/masuk?returnTo=%2Fhari-ini");
  await expectMinimumTarget(login);
  await expect(page.getByRole("heading", { name: "Fokus pribadi terkunci" })).toBeVisible();

  const navigation = page.getByRole("navigation", { name: "Navigasi Peserta" });
  const links = navigation.getByRole("link");
  await expect(links).toHaveCount(5);
  for (const name of ["Beranda", "Program", "Peringkat", "Coach", "Profil"]) {
    const link = navigation.getByRole("link", { name, exact: true });
    await expect(link).toBeVisible();
    await expectMinimumTarget(link);
  }

  const pageText = await page.locator("body").innerText();
  for (const privateTerm of [
    "Coach-mu",
    "Buka langkah berikutnya",
    "Berat awal",
    "Berat akhir",
    "Bukti pembayaran",
    "Jawaban foto",
  ]) {
    expect(pageText).not.toContain(privateTerm);
  }
  await expectNoHorizontalOverflow(page);
}

async function expectGoogleOnlyAuth(page: Page, label: string) {
  await expect(page.getByRole("link", { name: label })).toHaveCount(1);
  await expect(page.locator("input, textarea, select")).toHaveCount(0);
  await expect(page.getByText(/Apple/i)).toHaveCount(0);
  await expectMinimumTarget(page.getByRole("link", { name: label }));
  const close = page.getByRole("link", { name: "Tutup" });
  await expect(close).toHaveAttribute("href", "/hari-ini");
  await expectMinimumTarget(close);
}

for (const colorScheme of colorSchemes) {
  test(`Guest 390 ${colorScheme} hanya merender hierarki publik dan lima tab`, async ({
    page,
  }, testInfo) => {
    await page.emulateMedia({ colorScheme });
    await page.setViewportSize({ height: 844, width: 390 });
    await openRoute(page, "/hari-ini", "Beranda");
    await expectGuestPublicContract(page);
    await expectNoSeriousAxeFindings(page);
    await capture(page, testInfo, `guest-home-390-${colorScheme}`);
  });
}

test("Guest tetap reflow pada viewport 320 dan root zoom 400 persen", async ({
  page,
}, testInfo) => {
  await page.setViewportSize({ height: 900, width: 320 });
  await openRoute(page, "/hari-ini", "Beranda");
  await page.addStyleTag({ content: ":root { font-size: 400% !important; }" });
  await expect(page.getByRole("heading", { level: 1, name: "Beranda" })).toBeVisible();
  await expect(
    page.getByRole("navigation", { name: "Navigasi Peserta" }).getByRole("link"),
  ).toHaveCount(5);
  const navigation = page.getByRole("navigation", { name: "Navigasi Peserta" });
  const navigationLinks = navigation.getByRole("link");
  const navigationOverflow = await navigation.evaluate((element) => ({
    clientWidth: element.clientWidth,
    scrollWidth: element.scrollWidth,
  }));
  expect(navigationOverflow.scrollWidth).toBeGreaterThan(navigationOverflow.clientWidth);
  for (const link of await navigationLinks.all()) {
    await link.scrollIntoViewIfNeeded();
    const geometry = await link.evaluate((element) => {
      const navigationElement = element.closest("nav");
      const linkBounds = element.getBoundingClientRect();
      const navigationBounds = navigationElement?.getBoundingClientRect();
      return {
        linkBottom: linkBounds.bottom,
        linkLeft: linkBounds.left,
        linkRight: linkBounds.right,
        linkTop: linkBounds.top,
        navigationBottom: navigationBounds?.bottom ?? 0,
        navigationLeft: navigationBounds?.left ?? 0,
        navigationRight: navigationBounds?.right ?? 0,
        navigationTop: navigationBounds?.top ?? 0,
      };
    });
    expect(geometry.linkLeft).toBeGreaterThanOrEqual(geometry.navigationLeft - 1);
    expect(geometry.linkRight).toBeLessThanOrEqual(geometry.navigationRight + 1);
    expect(geometry.linkTop).toBeGreaterThanOrEqual(geometry.navigationTop - 1);
    expect(geometry.linkBottom).toBeLessThanOrEqual(geometry.navigationBottom + 1);
  }
  await navigation.evaluate((element) => element.scrollTo({ left: 0 }));
  await expectNoHorizontalOverflow(page);
  await capture(page, testInfo, "guest-home-320-zoom400");
});

for (const colorScheme of colorSchemes) {
  test(`/masuk ready 390 ${colorScheme} Google-only dan fokus`, async ({ page }, testInfo) => {
    await page.emulateMedia({ colorScheme });
    await page.setViewportSize({ height: 844, width: 390 });
    if (colorScheme === "light") {
      await openRoute(page, "/hari-ini", "Beranda");
      await page.getByRole("link", { name: "Masuk", exact: true }).click();
      await expect(page).toHaveURL(/\/masuk\?returnTo=%2Fhari-ini$/);
    } else {
      await page.goto("/masuk?returnTo=%2Fhari-ini");
    }
    const heading = page.getByRole("heading", { level: 1, name: "Selamat datang kembali" });
    await expect(heading).toBeVisible();
    await expect(heading).toBeFocused();
    await page.waitForLoadState("networkidle");
    await page.addStyleTag({ content: "nextjs-portal { display: none !important; }" });
    await expectGoogleOnlyAuth(page, "Lanjutkan dengan Google");
    await expect(page.getByRole("link", { name: "Lanjutkan dengan Google" })).toHaveAttribute(
      "href",
      /mode=login&returnTo=%2Fhari-ini/,
    );
    await expect(page.locator(".auth-notice[role='alert']")).toHaveCount(0);
    await expectNoHorizontalOverflow(page);
    await expectNoSeriousAxeFindings(page);
    await capture(page, testInfo, `auth-login-ready-390-${colorScheme}`);

    if (colorScheme === "light") {
      await page.getByRole("link", { name: "Tutup" }).click();
      await expect(page).toHaveURL(/\/hari-ini$/);
      await expect(page.getByRole("heading", { level: 1, name: "Beranda" })).toBeFocused();
    }
  });

  test(`/masuk error 390 ${colorScheme} tetap aman dan Google-only`, async ({ page }, testInfo) => {
    await page.emulateMedia({ colorScheme });
    await page.setViewportSize({ height: 844, width: 390 });
    await openRoute(page, "/masuk?error=provider&returnTo=%2Fhari-ini", "Selamat datang kembali");
    await expect(page.getByRole("heading", { name: "Selamat datang kembali" })).toBeFocused();
    await expect(page.locator(".auth-notice[role='alert']")).toHaveText(
      "Google belum dapat dihubungi. Periksa koneksi lalu coba lagi.",
    );
    await expectGoogleOnlyAuth(page, "Lanjutkan dengan Google");
    await expectNoHorizontalOverflow(page);
    await expectNoSeriousAxeFindings(page);
    await capture(page, testInfo, `auth-login-error-390-${colorScheme}`);
  });
}

test("/daftar mempertahankan akun Peserta dan Google-only", async ({ page }, testInfo) => {
  await page.setViewportSize({ height: 844, width: 390 });
  await openRoute(page, "/daftar?returnTo=%2Fhari-ini", "Buat akun Peserta");
  await expect(page.getByRole("heading", { name: "Buat akun Peserta" })).toBeFocused();
  await expectGoogleOnlyAuth(page, "Daftar dengan Google");
  await expect(page.getByRole("link", { name: "Daftar dengan Google" })).toHaveAttribute(
    "href",
    /mode=register&returnTo=%2Fhari-ini/,
  );
  await expectNoSeriousAxeFindings(page);
  await capture(page, testInfo, "auth-register-390-light");
});

test("/lupa-password menjaga respons privat tanpa formulir palsu", async ({ page }, testInfo) => {
  await page.setViewportSize({ height: 844, width: 390 });
  await openRoute(page, "/lupa-password", "Lupa password");
  await expect(page.getByRole("heading", { name: "Lupa password" })).toBeFocused();
  await expect(page.getByText(/respons akan tetap sama untuk setiap alamat email/i)).toBeVisible();
  await expect(page.locator("input, textarea, select")).toHaveCount(0);
  await expect(page.getByRole("link", { name: "Kembali ke masuk" })).toHaveAttribute(
    "href",
    "/masuk",
  );
  await expectMinimumTarget(page.getByRole("link", { name: "Tutup" }));
  await expectNoSeriousAxeFindings(page);
  await capture(page, testInfo, "auth-forgot-password-390-light");
});
