import { readFileSync } from 'node:fs';

import { describe, expect, it } from 'vitest';

describe('service worker public-shell boundary', () => {
  const serviceWorker = readFileSync('public/sw.js', 'utf8');
  const registration = readFileSync('public/register-sw.js', 'utf8');

  it('tidak melakukan precache route atau data privat', () => {
    expect(serviceWorker).toContain("const PUBLIC_SHELL = ['/', '/offline.html', '/manifest.webmanifest']");
    expect(serviceWorker).not.toContain("'/app'");
    expect(serviceWorker).not.toContain('supabase');
    expect(serviceWorker).not.toContain('signed');
  });

  it('tidak mengantrikan mutation di background', () => {
    expect(serviceWorker).not.toMatch(/addEventListener\(['"]sync['"]/u);
    expect(serviceWorker).not.toContain('POST');
    expect(serviceWorker).toContain("request.method !== 'GET'");
  });

  it('menunggu safe activation dan hanya membersihkan cache publik milik MSC', () => {
    expect(serviceWorker).toContain("event.data?.type === 'MSC_ACTIVATE_UPDATE'");
    expect(serviceWorker).toContain('key.startsWith(CACHE_PREFIX)');
    expect(serviceWorker).not.toContain('keys.filter((key) => key !== CACHE_NAME)');
    expect(registration).toContain("new CustomEvent('msc:pwa-update-ready')");
  });
});
