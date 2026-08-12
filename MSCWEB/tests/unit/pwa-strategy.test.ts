import { readFileSync } from 'node:fs';

import { describe, expect, it } from 'vitest';

describe('service worker public-shell boundary', () => {
  const serviceWorker = readFileSync('public/sw.js', 'utf8');

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
});
