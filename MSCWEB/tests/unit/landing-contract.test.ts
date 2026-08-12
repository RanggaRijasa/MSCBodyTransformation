import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

const landing = readFileSync('public/landing.html', 'utf8');

describe('W01 static landing contract', () => {
  it('contains every required semantic section as static readable HTML', () => {
    for (const copy of [
      'Transformasi tubuh, langkah demi langkah.',
      'Cara kerja',
      'Program yang membantumu tetap terarah',
      'Dukungan Coach di setiap langkah',
      'Pembayaran diperiksa manual',
      'Data pribadi tetap pribadi',
      'Pasang MSC di layar utama',
    ]) {
      expect(landing).toContain(copy);
    }
    expect(landing).toContain('src="/install-pwa.js?v=20260812"');
  });

  it('links canonical product, manifest, icons, metadata, legal, support, and install surfaces', () => {
    for (const marker of [
      'rel="canonical"',
      'rel="manifest"',
      'rel="apple-touch-icon"',
      'property="og:title"',
      'href="/app"',
      'href="/app/programs"',
      'href="/kebijakan-privasi"',
      'href="/ketentuan"',
      'href="/bantuan-pembayaran"',
      'href="/cara-memasang"',
    ]) {
      expect(landing).toContain(marker);
    }
  });

  it('uses the hero action for PWA installation instead of starting a program', () => {
    expect(landing).toContain('<a class="button" href="/cara-memasang" data-install-app>Unduh aplikasi</a>');
    expect(landing).not.toContain('Mulai program');
  });

  it('uses marketing copy instead of a mock program catalog', () => {
    for (const copy of ['Tujuan yang jelas', 'Langkah yang terstruktur', 'Dukungan yang terhubung']) {
      expect(landing).toContain(copy);
    }
    expect(landing).not.toContain('Lihat semua program');
    expect(landing).not.toContain('Pratinjau katalog program');
  });

  it('does not ship invented claims or generated concept data', () => {
    for (const forbidden of ['Fat Loss Fundamental', '1.2K peserta', 'Coach Arif', 'hasil terjamin']) {
      expect(landing).not.toContain(forbidden);
    }
  });
});
