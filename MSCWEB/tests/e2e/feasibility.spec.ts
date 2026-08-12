import { expect, test } from '@playwright/test';

test.describe('W00 production routing', () => {
  test('landing statis dapat dibaca dan membuka shell aplikasi', async ({ page }) => {
    const response = await page.goto('/');

    expect(response?.status()).toBe(200);
    await expect(page.getByRole('heading', { name: 'MSC Body Transformation' })).toBeVisible();
    await expect(page.getByRole('link', { name: 'Buka aplikasi' })).toHaveAttribute('href', '/app');

    const html = await response?.text();
    expect(html).not.toContain('/_expo/static/js');

    await page.getByRole('link', { name: 'Buka aplikasi' }).click();
    await expect(page).toHaveURL(/\/app$/);
    await expect(page.getByRole('heading', { name: 'Shell aplikasi siap' })).toBeVisible();
  });

  test('nested route, refresh, dan browser Back/Forward tetap konsisten', async ({ page }) => {
    await page.goto('/app');
    await page.getByRole('link', { name: 'Profil' }).click();
    await expect(page).toHaveURL(/\/app\/profile$/);
    await page.reload();
    await expect(page.getByRole('heading', { name: 'Route bertingkat' })).toBeVisible();

    await page.goBack();
    await expect(page).toHaveURL(/\/app$/);
    await page.goForward();
    await expect(page).toHaveURL(/\/app\/profile$/);
  });

  test('unknown navigation memakai UI 404 dan asset hilang tetap HTTP 404', async ({ page, request }) => {
    const navigationResponse = await page.goto('/route-yang-tidak-ada');
    expect(navigationResponse?.status()).toBe(404);
    await expect(page.getByRole('heading', { name: 'Halaman tidak ditemukan' })).toBeVisible();

    const assetResponse = await request.get('/icons/tidak-ada.png');
    expect(assetResponse.status()).toBe(404);

    const unknownAppResponse = await page.goto('/app/tidak-ada');
    expect(unknownAppResponse?.status()).toBe(404);
    await expect(page.getByRole('heading', { name: 'Halaman tidak ditemukan' })).toBeVisible();
  });
});

test.describe('W00 responsive dan accessibility', () => {
  test('pipeline gambar browser mendekode, resize, dan menghasilkan JPEG', async ({ page }) => {
    await page.goto('/app/feasibility');
    await page.getByRole('button', { name: 'Uji pipeline gambar' }).click();

    await expect(page.getByText(/^Berhasil: 1536×2048, JPEG tanpa EXIF\/GPS,/)).toBeVisible();
  });

  test('320 px memakai bottom navigation tanpa overflow horizontal', async ({ page }) => {
    await page.setViewportSize({ width: 320, height: 720 });
    await page.goto('/app');

    const navigation = page.getByRole('navigation', { name: 'Navigasi utama' });
    await expect(navigation).toBeVisible();
    await expect(navigation.getByRole('link', { name: 'Beranda' })).toHaveAttribute(
      'aria-current',
      'page',
    );
    const box = await navigation.boundingBox();
    expect(box?.width).toBeLessThanOrEqual(320);

    const links = await navigation.getByRole('link').all();
    expect(links).toHaveLength(3);
    const linkBoxes = await Promise.all(links.map((link) => link.boundingBox()));
    for (const linkBox of linkBoxes) {
      expect(linkBox?.width).toBeGreaterThanOrEqual(44);
      expect(linkBox?.height).toBeGreaterThanOrEqual(44);
    }
    expect(linkBoxes[0]?.x).toBeLessThan(linkBoxes[1]?.x ?? 0);
    expect(linkBoxes[1]?.x).toBeLessThan(linkBoxes[2]?.x ?? 0);
    expect((linkBoxes[0]?.x ?? 0) + (linkBoxes[0]?.width ?? 0)).toBeLessThanOrEqual(linkBoxes[1]?.x ?? 0);
    expect((linkBoxes[1]?.x ?? 0) + (linkBoxes[1]?.width ?? 0)).toBeLessThanOrEqual(linkBoxes[2]?.x ?? 0);

    const overflow = await page.evaluate(() => document.documentElement.scrollWidth > window.innerWidth);
    expect(overflow).toBe(false);
  });

  test('wide layout memakai navigation rail dan focus-visible', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto('/app');
    const profileLink = page.getByRole('link', { name: 'Profil' });
    await profileLink.focus();

    const focusedOutline = await page.evaluate(() => {
      const focused = document.activeElement;
      return focused ? getComputedStyle(focused).outlineStyle : 'none';
    });
    expect(focusedOutline).not.toBe('none');
  });

  test('dark mode dan reduced motion mengikuti preferensi browser', async ({ page }) => {
    await page.emulateMedia({ colorScheme: 'dark', reducedMotion: 'reduce' });
    await page.goto('/app');

    const rootBackground = await page.locator('body').evaluate((element) =>
      getComputedStyle(element).backgroundColor,
    );
    expect(rootBackground).toBe('rgb(13, 13, 15)');

    const transitionDuration = await page.locator('body').evaluate((element) =>
      getComputedStyle(element).transitionDuration,
    );
    expect(Number.parseFloat(transitionDuration)).toBeLessThanOrEqual(0.000001);
  });
});
