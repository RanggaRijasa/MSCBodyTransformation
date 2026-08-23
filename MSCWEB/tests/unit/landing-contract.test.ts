import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

const landing = readFileSync('public/landing.html', 'utf8');
const landingCss = readFileSync('public/landing.css', 'utf8');
const privacy = readFileSync('public/kebijakan-privasi.html', 'utf8');
const terms = readFileSync('public/ketentuan.html', 'utf8');

describe('W01 static landing contract', () => {
  it('contains every required semantic section as static readable HTML', () => {
    for (const copy of [
      'Transformasi',
      'Lima langkah untuk tetap bergerak.',
      'Terarah dari hari pertama sampai selesai.',
      'Ada orang yang peduli dengan progresmu.',
      'Pembayaran diperiksa sebelum akses aktif.',
      'Progresmu itu pribadi. Kami menjaganya.',
      'Langkah pertamamu dimulai dari sini.',
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
    expect(landing).toContain('rel="canonical" href="https://msc-body-transformation.com/"');
    expect(landing).not.toContain('rel="canonical" href="/"');
  });

  it('keeps payment and footer copy at an explicit high-contrast color', () => {
    expect(landingCss).toContain('.payment-section .eyebrow,');
    expect(landingCss).toContain('.payment-section .section-heading > p:last-child { color: #fff; }');
    expect(landingCss).toContain('.payment-grid > ol p { margin-top: 0.25rem; color: #fff;');
    expect(landingCss).toContain('color: rgb(247 242 232 / 66%); font-size: 0.75rem;');
  });

  it('uses the hero action for PWA installation instead of starting a program', () => {
    expect(landing).toContain('href="/cara-memasang" data-install-app');
    expect(landing).toContain('Pasang aplikasi');
    expect(landing).not.toContain('Mulai program');
  });

  it('uses marketing copy instead of a mock program catalog', () => {
    for (const copy of ['Tujuan yang jelas', 'Langkah yang terstruktur', 'Dukungan yang terhubung']) {
      expect(landing).toContain(copy);
    }
    expect(landing).not.toContain('Pratinjau katalog program');
  });

  it('does not ship invented claims or generated concept data', () => {
    for (const forbidden of ['Fat Loss Fundamental', '1.2K peserta', 'Coach Arif', 'hasil terjamin']) {
      expect(landing).not.toContain(forbidden);
    }
    for (const image of ['modest-gym.jpg', 'woman-gym-generated.jpg', 'man-gym-coach.jpg', 'man-gym-pullup.jpg']) {
      expect(landing).toContain(image);
    }
    expect(landing.match(/modest-gym\.jpg/g)).toHaveLength(3);
    expect(landing).not.toContain('alt="Perempuan berhijab berlari');
    expect(landingCss).not.toContain('content: "✦"');
  });

  it('keeps the mobile hero inside narrow viewports', () => {
    expect(landingCss).toContain('.hero-copy { min-width: 0; }');
    expect(landingCss).toContain('.hero h1 { font-size: clamp(2.8rem, 13.5vw, 4.2rem); }');
    expect(landingCss).not.toContain('18.3vw');
  });

  it('publishes approved web legal copy without development placeholders', () => {
    for (const page of [privacy, terms]) {
      expect(page).toContain('21 Agustus 2026');
      expect(page).toContain('ranggarijasa2005@gmail.com');
      expect(page).toContain('085241997304');
      expect(page).not.toMatch(/dokumen ini adalah shell|belum merupakan teks hukum|jangan gunakan shell|\[ISI/iu);
    }
    expect(privacy).toContain('Zero Data Retention tidak dipaksakan');
    expect(terms).toContain('hukum Republik Indonesia');
  });
});
