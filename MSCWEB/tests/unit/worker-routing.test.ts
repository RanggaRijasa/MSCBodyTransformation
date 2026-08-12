import { describe, expect, it, vi } from 'vitest';

import { worker } from '../../worker/index';

function makeEnvironment() {
  const assets = new Map([
    ['/index.html', new Response('landing')],
    ['/app.html', new Response('app-shell')],
    ['/404.html', new Response('tidak ditemukan')],
    ['/icons/icon-192.png', new Response('icon')],
  ]);
  const fetch = vi.fn(async (request: Request) => {
    const response = assets.get(new URL(request.url).pathname);
    return response === undefined ? new Response('missing', { status: 404 }) : response.clone();
  });
  return { env: { ASSETS: { fetch } }, fetch };
}

describe('Cloudflare Worker routing contract', () => {
  it('serves the static landing and SPA shell from separate artifacts', async () => {
    const { env, fetch } = makeEnvironment();

    await expect(worker.fetch(new Request('https://msc.invalid/'), env).then((r) => r.text())).resolves.toBe('landing');
    await expect(worker.fetch(new Request('https://msc.invalid/app/profile'), env).then((r) => r.text())).resolves.toBe('app-shell');
    await expect(worker.fetch(new Request('https://msc.invalid/login?returnTo=%2Fapp'), env).then((r) => r.text())).resolves.toBe('app-shell');
    await expect(worker.fetch(new Request('https://msc.invalid/app/programs/11111111-1111-4111-8111-111111111111'), env).then((r) => r.text())).resolves.toBe('app-shell');
    await expect(worker.fetch(new Request('https://msc.invalid/coach/reviews'), env).then((r) => r.text())).resolves.toBe('app-shell');
    await expect(worker.fetch(new Request('https://msc.invalid/coach/reviews/11111111-1111-4111-8111-111111111111'), env).then((r) => r.text())).resolves.toBe('app-shell');
    expect(fetch).toHaveBeenCalledWith(expect.objectContaining({ url: 'https://msc.invalid/app.html' }));
  });

  it('preserves real asset 404 and unknown-navigation status', async () => {
    const { env } = makeEnvironment();
    const missingAsset = await worker.fetch(new Request('https://msc.invalid/icons/missing.png'), env);
    expect(missingAsset.status).toBe(404);

    const unknownNavigation = await worker.fetch(new Request('https://msc.invalid/unknown'), env);
    expect(unknownNavigation.status).toBe(404);
    await expect(unknownNavigation.text()).resolves.toBe('tidak ditemukan');

    const unknownAppNavigation = await worker.fetch(new Request('https://msc.invalid/app/unknown'), env);
    expect(unknownAppNavigation.status).toBe(404);
    const malformedEntityNavigation = await worker.fetch(new Request('https://msc.invalid/app/programs/not-a-uuid'), env);
    expect(malformedEntityNavigation.status).toBe(404);
  });

  it('rejects mutation methods at the static edge', async () => {
    const { env } = makeEnvironment();
    const response = await worker.fetch(new Request('https://msc.invalid/app', { method: 'POST' }), env);

    expect(response.status).toBe(405);
    expect(response.headers.get('Allow')).toBe('GET, HEAD');
  });
});
