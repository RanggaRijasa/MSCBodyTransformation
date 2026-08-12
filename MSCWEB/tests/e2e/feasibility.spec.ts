import { expect, test } from '@playwright/test';

test.describe('W00 production routing and risk probes', () => {
  test('static landing opens the public application shell', async ({ page }) => {
    const response = await page.goto('/');
    expect(response?.status()).toBe(200);
    await expect(page.getByRole('heading', { name: 'Transformasi tubuh, langkah demi langkah.' })).toBeVisible();
    const html = await response?.text();
    expect(html).not.toContain('/_expo/static/js');

    await page.getByRole('link', { name: 'Lihat program' }).click();
    await expect(page).toHaveURL(/\/app\/programs$/);
    await expect(page.getByRole('heading', { name: 'Program' }).first()).toBeVisible();
  });

  test('nested route, refresh, Back, and Forward remain consistent', async ({ page }) => {
    await page.goto('/app/home');
    await page.getByRole('link', { name: 'Profil' }).click();
    await expect(page).toHaveURL(/\/app\/profile$/);
    await page.reload();
    await expect(page.getByRole('heading', { name: 'Jelajahi sebagai Tamu' })).toBeVisible();
    await page.goBack();
    await expect(page).toHaveURL(/\/app\/home$/);
    await page.goForward();
    await expect(page).toHaveURL(/\/app\/profile$/);
  });

  test('unknown navigation uses UI 404 and missing assets stay HTTP 404', async ({ page, request }) => {
    const navigationResponse = await page.goto('/route-yang-tidak-ada');
    expect(navigationResponse?.status()).toBe(404);
    await expect(page.getByRole('heading', { name: 'Halaman tidak ditemukan' })).toBeVisible();
    expect((await request.get('/icons/tidak-ada.png')).status()).toBe(404);
    const unknownAppResponse = await page.goto('/app/tidak-ada');
    expect(unknownAppResponse?.status()).toBe(404);
  });

  test('browser image pipeline decodes, resizes, and produces metadata-free JPEG', async ({ page }) => {
    await page.goto('/app/feasibility');
    await page.getByRole('button', { name: 'Uji pipeline gambar' }).click();
    await expect(page.getByText(/^Berhasil: 1536×2048, JPEG tanpa EXIF\/GPS,/)).toBeVisible();
  });
});

test.describe('W01 landing and metadata', () => {
  test('all approved sections and product-safe copy are readable', async ({ page }) => {
    await page.goto('/');
    for (const heading of ['Cara kerja', 'Program yang membantumu tetap terarah', 'Dukungan Coach di setiap langkah', 'Pembayaran diperiksa manual', 'Data pribadi tetap pribadi', 'Pasang MSC di layar utama']) {
      await expect(page.getByRole('heading', { name: heading })).toBeVisible();
    }
    await expect(page.getByText('aktivasi tidak berlangsung seketika')).toBeVisible();
    await expect(page.locator('link[rel="manifest"]')).toHaveAttribute('href', '/manifest.webmanifest');
    await expect(page.locator('link[rel="canonical"]')).toHaveAttribute('href', '/');
    await expect(page.locator('meta[property="og:title"]')).toHaveAttribute('content', 'MSC Body Transformation');
  });

  test('primary hero CTA opens PWA installation guidance', async ({ page }) => {
    await page.goto('/');
    const installAction = page.getByRole('link', { name: 'Unduh aplikasi' });
    await expect(installAction).toHaveAttribute('href', '/cara-memasang');
    await installAction.click();
    await expect(page).toHaveURL(/\/cara-memasang$/);
    await expect(page.getByRole('heading', { name: 'Cara memasang aplikasi' })).toBeVisible();
  });

  test('supported Chromium install event opens the native prompt from the CTA', async ({ page }) => {
    await page.goto('/');
    await page.evaluate(() => {
      const target = window as Window & { __installPromptCalls?: number };
      target.__installPromptCalls = 0;
      const event = new Event('beforeinstallprompt');
      Object.defineProperties(event, {
        prompt: {
          value: () => {
            target.__installPromptCalls = (target.__installPromptCalls ?? 0) + 1;
            return Promise.resolve();
          },
        },
        userChoice: { value: Promise.resolve({ outcome: 'accepted', platform: 'web' }) },
      });
      window.dispatchEvent(event);
    });

    await page.getByRole('link', { name: 'Unduh aplikasi' }).click();
    await expect.poll(() => page.evaluate(() => (window as Window & { __installPromptCalls?: number }).__installPromptCalls)).toBe(1);
    await expect(page).toHaveURL(/\/$/);
    await expect(page.getByText('Permintaan pemasangan dikirim ke browser.')).toBeVisible();
  });

  test('landing uses bold brand color blocks instead of muted accents', async ({ page }) => {
    await page.goto('/');
    await expect(page.getByRole('link', { name: 'Unduh aplikasi' })).toHaveCSS('background-color', 'rgb(215, 25, 32)');
    await expect(page.locator('.payment')).toHaveCSS('background-color', 'rgb(215, 25, 32)');
    await expect(page.locator('.install-panel')).toHaveCSS('background-color', 'rgb(255, 212, 0)');
  });

  test('legal, payment-help, and install shells resolve with manifest metadata', async ({ request }) => {
    for (const path of ['/kebijakan-privasi', '/ketentuan', '/bantuan-pembayaran', '/cara-memasang']) {
      const response = await request.get(path);
      expect(response.status()).toBe(200);
      expect(await response.text()).toContain('rel="manifest"');
    }
  });

  test('keyboard reaches skip link and primary action', async ({ page }) => {
    await page.goto('/');
    await page.keyboard.press('Tab');
    await expect(page.getByRole('link', { name: 'Lewati ke konten' })).toBeFocused();
    await page.keyboard.press('Enter');
    await expect(page.locator('#konten')).toBeFocused();
  });

  test('landing has no horizontal overflow across required viewport matrix', async ({ page }) => {
    for (const width of [320, 375, 390, 430, 768, 1024, 1440]) {
      await page.setViewportSize({ width, height: width < 768 ? 844 : 900 });
      await page.goto('/');
      const overflow = await page.evaluate(() => document.documentElement.scrollWidth > window.innerWidth);
      expect(overflow, `overflow at ${width}px`).toBe(false);
      await expect(page.getByRole('link', { name: 'Unduh aplikasi' })).toBeVisible();
    }
  });

  test('landing remains functional at a 200% content zoom simulation', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto('/');
    await page.evaluate(() => { document.documentElement.style.fontSize = '200%'; });
    await expect(page.getByRole('link', { name: 'Unduh aplikasi' })).toBeVisible();
    await expect(page.getByRole('heading', { name: 'Cara kerja' })).toBeVisible();
  });
});

test.describe('W01 role shells and accessibility', () => {
  const cases = [
    { path: '/app/home', links: ['Beranda', 'Program', 'Peringkat', 'Coach', 'Profil'], active: 'Beranda' },
    { path: '/coach', links: ['Dashboard', 'Program', 'Profil'], active: 'Dashboard' },
    { path: '/admin', links: ['Dashboard', 'Program', 'Orang', 'Konten', 'Pengaturan'], active: 'Dashboard' },
  ] as const;

  for (const shell of cases) {
    test(`${shell.path} exposes the exact semantic destination set`, async ({ page }) => {
      await page.goto(shell.path);
      const navigation = page.getByRole('navigation', { name: 'Navigasi utama' });
      await expect(navigation).toBeVisible();
      await expect(navigation.getByRole('link')).toHaveCount(shell.links.length);
      for (const label of shell.links) await expect(navigation.getByRole('link', { name: label })).toBeVisible();
      const activeLink = navigation.getByRole('link', { name: shell.active });
      await expect(activeLink).toHaveAttribute('aria-current', 'page');
      const compact = (page.viewportSize()?.width ?? 0) < 768;
      await expect(activeLink).toHaveCSS(
        'background-color',
        compact ? 'rgb(242, 242, 242)' : 'rgb(215, 25, 32)',
      );
      if (compact) {
        await expect(activeLink.getByText(shell.active, { exact: true })).toHaveCSS(
          'color',
          'rgb(215, 25, 32)',
        );
      }
    });
  }

  test('320px compact shell has readable five-item bottom navigation without content overlap', async ({ page }) => {
    await page.setViewportSize({ width: 320, height: 720 });
    await page.goto('/app/home');
    const navigation = page.getByRole('navigation', { name: 'Navigasi utama' });
    const box = await navigation.boundingBox();
    expect(box).not.toBeNull();
    expect(box!.x).toBeGreaterThanOrEqual(11);
    expect(320 - box!.x - box!.width).toBeGreaterThanOrEqual(11);
    expect(box!.height).toBe(64);
    expect(Number.parseFloat(await navigation.evaluate((element) => getComputedStyle(element).borderRadius))).toBeGreaterThanOrEqual(30);
    expect(await page.evaluate(() => document.documentElement.scrollWidth > window.innerWidth)).toBe(false);
    const linkBoxes = await navigation.getByRole('link').evaluateAll((links) =>
      links.map((link) => link.getBoundingClientRect().width),
    );
    expect(Math.max(...linkBoxes) - Math.min(...linkBoxes)).toBeLessThanOrEqual(1);
    const homeLink = navigation.getByRole('link', { name: 'Beranda' });
    const iconBox = await homeLink.locator('svg').boundingBox();
    const labelBox = await homeLink.getByText('Beranda', { exact: true }).boundingBox();
    expect(iconBox).not.toBeNull();
    expect(labelBox).not.toBeNull();
    expect(labelBox!.y).toBeGreaterThanOrEqual(iconBox!.y + iconBox!.height - 1);
    expect(Math.abs(
      (iconBox!.x + iconBox!.width / 2) - (labelBox!.x + labelBox!.width / 2),
    )).toBeLessThanOrEqual(1);
    await expect(page.getByRole('button', { name: 'Jelajahi program' })).toBeVisible();

    await navigation.getByRole('link', { name: 'Program' }).click();
    await expect(page).toHaveURL(/\/app\/programs$/);
    await expect(navigation.getByRole('link', { name: 'Program' })).toHaveAttribute(
      'aria-current',
      'page',
    );
    const selectedBox = await navigation.boundingBox();
    expect(selectedBox).not.toBeNull();
    expect(selectedBox!.x).toBe(box!.x);
    expect(selectedBox!.width).toBe(box!.width);
    expect(selectedBox!.height).toBe(box!.height);
  });

  test('compact dark navigation keeps a lighter selected pill with bold red emphasis', async ({ page }) => {
    await page.setViewportSize({ width: 368, height: 800 });
    await page.emulateMedia({ colorScheme: 'dark' });
    await page.goto('/app/home');
    const navigation = page.getByRole('navigation', { name: 'Navigasi utama' });
    const activeLink = navigation.getByRole('link', { name: 'Beranda' });
    await expect(navigation).toHaveCSS('background-color', 'rgb(26, 26, 26)');
    await expect(activeLink).toHaveCSS('background-color', 'rgb(58, 58, 60)');
    await expect(activeLink.getByText('Beranda', { exact: true })).toHaveCSS(
      'color',
      'rgb(215, 25, 32)',
    );
  });

  test('wide shell uses rail, focus-visible, dark mode, and reduced motion', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.emulateMedia({ colorScheme: 'dark', reducedMotion: 'reduce' });
    await page.goto('/admin');
    const settings = page.getByRole('link', { name: 'Pengaturan' });
    await settings.focus();
    expect(await settings.evaluate((element) => getComputedStyle(element).outlineStyle)).not.toBe('none');
    expect(await page.locator('body').evaluate((element) => getComputedStyle(element).backgroundColor)).toBe('rgb(0, 0, 0)');
    expect(Number.parseFloat(await page.locator('body').evaluate((element) => getComputedStyle(element).transitionDuration))).toBeLessThanOrEqual(0.000001);
  });

  test('captures W01 visual baselines', async ({ page }, testInfo) => {
    const compact = testInfo.project.name.includes('compact');
    await page.setViewportSize(compact ? { width: 390, height: 844 } : { width: 1440, height: 900 });
    await page.goto('/');
    await expect(page).toHaveScreenshot(compact ? 'landing-390.png' : 'landing-1440.png', { fullPage: true, animations: 'disabled' });
  });
});
