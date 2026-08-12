import { expect, test } from '@playwright/test';

test.describe('W02 public application and auth gate', () => {
  test('Guest explores a public program and reaches Google login with safe intent', async ({ page }) => {
    await page.goto('/app/programs');
    await expect(page.getByRole('heading', { name: 'Program yang tersedia' })).toBeVisible();
    const programLink = page.getByRole('link').filter({ has: page.getByRole('heading') }).last();
    await expect(programLink).toBeVisible();
    const programTitle = await programLink.getByRole('heading').innerText();
    await programLink.click();
    await expect(page.getByRole('heading', { name: programTitle }).first()).toBeVisible();
    const detailUrl = page.url();

    await page.getByRole('button', { name: 'Gabung program' }).click();
    await expect(page).toHaveURL(/\/login\?returnTo=%2Fapp%2Fprograms%2F/);
    await expect(page.getByRole('heading', { name: 'Masuk ke MSC' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Lanjutkan dengan Google' })).toBeVisible();

    await page.getByRole('button', { name: 'Kembali' }).click();
    await expect(page).toHaveURL(detailUrl);
  });

  test('unsafe return intent is reduced to the internal app root', async ({ page }) => {
    await page.goto('/login?returnTo=https%3A%2F%2Fevil.example%2Fadmin');
    await expect(page.getByRole('heading', { name: 'Masuk ke MSC' })).toBeVisible();
    await expect(page.locator('body')).not.toContainText('evil.example');
  });

  test('invalid OAuth callback is mapped to Indonesian recovery copy', async ({ page }) => {
    await page.goto('/auth/callback');
    await expect(page.getByText('Tautan masuk tidak valid. Mulai proses masuk lagi.')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Kembali ke halaman masuk' })).toBeVisible();
  });

  test('public leaderboard and Coach directory exclude private fields', async ({ page }) => {
    for (const path of ['/app/leaderboard', '/app/coaches']) {
      await page.goto(path);
      await expect(page.getByRole('navigation', { name: 'Navigasi utama' })).toBeVisible();
      const content = await page.locator('body').innerText();
      expect(content).not.toContain('coach_qr_identifier');
      expect(content).not.toContain('phone_number');
      expect(content).not.toContain('Berat awal');
      expect(content).not.toContain('Berat akhir');
    }
  });

  test('Guest profile renders a gate without hydrating personal account data', async ({ page }) => {
    await page.goto('/app/profile');
    await expect(page.getByRole('heading', { name: 'Jelajahi sebagai Tamu' })).toBeVisible();
    await expect(page.getByText('Data tersebut tidak dimuat dalam mode Tamu.')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Masuk dengan Google' })).toBeVisible();
  });
});
