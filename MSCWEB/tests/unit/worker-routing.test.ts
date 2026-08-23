import { describe, expect, it, vi } from 'vitest';
import { readFileSync } from 'node:fs';

import { worker } from '../../worker/index';

function makeEnvironment(appShell = 'app-shell') {
  const assets = new Map([
    ['/index.html', new Response('landing')],
    ['/app.html', new Response(appShell)],
    ['/404.html', new Response('tidak ditemukan')],
    ['/cara-memasang.html', new Response('cara memasang')],
    ['/icons/icon-192.png', new Response('icon')],
    ['/wasm/zxing-reader-3.1.1-6a858c01.wasm', new Response('wasm')],
    ['/_expo/static/js/web/app-a1b2c3d4.js', new Response('bundle')],
    ['/robots.txt', new Response('User-agent: *\nAllow: /\n')],
  ]);
  const fetch = vi.fn(async (request: Request) => {
    const response = assets.get(new URL(request.url).pathname);
    return response === undefined ? new Response('missing', { status: 404 }) : response.clone();
  });
  return { env: { ASSETS: { fetch }, DEPLOYMENT_ENVIRONMENT: 'local' as const, SUPABASE_ORIGIN: 'https://project.supabase.co' }, fetch };
}

describe('Cloudflare Worker routing contract', () => {
  it('keeps preview isolated from production custom domains', () => {
    const configuration = readFileSync('wrangler.jsonc', 'utf8');
    expect(configuration).toContain('"routes": []');
    expect(configuration.match(/"run_worker_first": true/gu)).toHaveLength(3);
    expect(configuration).toContain('"invocation_logs": false');
  });
  it('serves the static landing and SPA shell from separate artifacts', async () => {
    const { env, fetch } = makeEnvironment();

    await expect(worker.fetch(new Request('https://msc.invalid/'), env).then((r) => r.text())).resolves.toBe('landing');
    const installGuide = await worker.fetch(new Request('https://msc.invalid/cara-memasang'), env);
    await expect(installGuide.text()).resolves.toBe('cara memasang');
    expect(installGuide.headers.get('Cache-Control')).toBe('no-store, no-transform');
    await expect(worker.fetch(new Request('https://msc.invalid/app/profile'), env).then((r) => r.text())).resolves.toBe('app-shell');
    await expect(worker.fetch(new Request('https://msc.invalid/login?returnTo=%2Fapp'), env).then((r) => r.text())).resolves.toBe('app-shell');
    await expect(worker.fetch(new Request('https://msc.invalid/onboarding/profile'), env).then((r) => r.text())).resolves.toBe('app-shell');
    await expect(worker.fetch(new Request('https://msc.invalid/onboarding/participant/coach'), env).then((r) => r.text())).resolves.toBe('app-shell');
    await expect(worker.fetch(new Request('https://msc.invalid/onboarding/coach/eligibility'), env).then((r) => r.text())).resolves.toBe('app-shell');
    await expect(worker.fetch(new Request('https://msc.invalid/onboarding/coach/payment'), env).then((r) => r.text())).resolves.toBe('app-shell');
    await expect(worker.fetch(new Request('https://msc.invalid/onboarding/coach/status'), env).then((r) => r.text())).resolves.toBe('app-shell');
    await expect(worker.fetch(new Request('https://msc.invalid/app/programs/11111111-1111-4111-8111-111111111111'), env).then((r) => r.text())).resolves.toBe('app-shell');
    await expect(worker.fetch(new Request('https://msc.invalid/coach/reviews'), env).then((r) => r.text())).resolves.toBe('app-shell');
    await expect(worker.fetch(new Request('https://msc.invalid/coach/participants'), env).then((r) => r.text())).resolves.toBe('app-shell');
    await expect(worker.fetch(new Request('https://msc.invalid/coach/activity'), env).then((r) => r.text())).resolves.toBe('app-shell');
    await expect(worker.fetch(new Request('https://msc.invalid/coach/leaderboard'), env).then((r) => r.text())).resolves.toBe('app-shell');
    await expect(worker.fetch(new Request('https://msc.invalid/coach/qr'), env).then((r) => r.text())).resolves.toBe('app-shell');
    await expect(worker.fetch(new Request('https://msc.invalid/app/coach-application'), env).then((r) => r.text())).resolves.toBe('app-shell');
    await expect(worker.fetch(new Request('https://msc.invalid/c/coach-lestari'), env).then((r) => r.text())).resolves.toContain('app-shell');
    await expect(worker.fetch(new Request('https://msc.invalid/coach/reviews/11111111-1111-4111-8111-111111111111'), env).then((r) => r.text())).resolves.toBe('app-shell');
    await expect(worker.fetch(new Request('https://msc.invalid/coach/participants/11111111-1111-4111-8111-111111111111'), env).then((r) => r.text())).resolves.toBe('app-shell');
    await expect(worker.fetch(new Request('https://msc.invalid/app/payments/11111111-1111-4111-8111-111111111111'), env).then((r) => r.text())).resolves.toBe('app-shell');
    await expect(worker.fetch(new Request('https://msc.invalid/admin/payments/11111111-1111-4111-8111-111111111111'), env).then((r) => r.text())).resolves.toBe('app-shell');
    await expect(worker.fetch(new Request('https://msc.invalid/admin/programs/11111111-1111-4111-8111-111111111111'), env).then((r) => r.text())).resolves.toBe('app-shell');
    await expect(worker.fetch(new Request('https://msc.invalid/admin/people/11111111-1111-4111-8111-111111111111'), env).then((r) => r.text())).resolves.toBe('app-shell');
    await expect(worker.fetch(new Request('https://msc.invalid/admin/operations'), env).then((r) => r.text())).resolves.toBe('app-shell');
    await expect(worker.fetch(new Request('https://msc.invalid/admin/audit'), env).then((r) => r.text())).resolves.toBe('app-shell');
    expect(fetch).toHaveBeenCalledWith(expect.objectContaining({ url: 'https://msc.invalid/app.html' }));
  });

  it('preserves real asset 404 and unknown-navigation status', async () => {
    const { env } = makeEnvironment();
    const missingAsset = await worker.fetch(new Request('https://msc.invalid/icons/missing.png'), env);
    expect(missingAsset.status).toBe(404);

    const unknownNavigation = await worker.fetch(new Request('https://msc.invalid/unknown'), env);
    expect(unknownNavigation.status).toBe(404);
    expect(unknownNavigation.headers.get('Cache-Control')).toBe('no-store, no-transform');
    await expect(unknownNavigation.text()).resolves.toBe('tidak ditemukan');

    const unknownAppNavigation = await worker.fetch(new Request('https://msc.invalid/app/unknown'), env);
    expect(unknownAppNavigation.status).toBe(404);
    const malformedEntityNavigation = await worker.fetch(new Request('https://msc.invalid/app/programs/not-a-uuid'), env);
    expect(malformedEntityNavigation.status).toBe(404);
    const malformedCoachHandle = await worker.fetch(new Request('https://msc.invalid/c/Coach_Lestari'), env);
    expect(malformedCoachHandle.status).toBe(404);
  });

  it('rejects mutation methods at the static edge', async () => {
    const { env } = makeEnvironment();
    const response = await worker.fetch(new Request('https://msc.invalid/app', { method: 'POST' }), env);

    expect(response.status).toBe(405);
    expect(response.headers.get('Allow')).toBe('GET, HEAD');
  });

  it('membuat metadata sosial Coach dari whitelist data publik', async () => {
    const { env } = makeEnvironment('<html><head><meta name="description" content="Deskripsi umum" /><title>MSC Body Transformation</title></head><body>app-shell</body></html>');
    const apiFetch = vi.fn(async () => new Response(JSON.stringify({
      biography: 'Pendamping transformasi yang ramah.',
      display_name: 'Coach <Lestari>',
      handle: 'coach-lestari',
      is_verified: true,
      phone_number: 'tidak-boleh-muncul',
      photo_reference: '11111111-1111-4111-8111-111111111111',
      professional_headline: 'Temani langkah sehat & konsisten',
      whatsapp_number: 'tidak-boleh-muncul',
    }), { headers: { 'Content-Type': 'application/json' } }));
    vi.stubGlobal('fetch', apiFetch);

    const response = await worker.fetch(
      new Request('https://candidate.invalid/c/coach-lestari?utm_source=synthetic'),
      { ...env, DEPLOYMENT_ENVIRONMENT: 'candidate' as const, SUPABASE_PUBLISHABLE_KEY: 'sb_publishable_test' },
    );
    const html = await response.text();

    expect(response.status).toBe(200);
    expect(response.headers.get('Cache-Control')).toBe('no-store, no-transform');
    expect(html).toContain('<title>Coach &lt;Lestari&gt; — Coach MSC Body Transformation</title>');
    expect(html).toContain('Temani langkah sehat &amp; konsisten');
    expect(html).toContain('https://msc-body-transformation.com/c/coach-lestari');
    expect(html).not.toContain('utm_source');
    expect(html).toContain('/functions/v1/public-coach-media/11111111-1111-4111-8111-111111111111');
    expect(html).not.toContain('tidak-boleh-muncul');
    expect(apiFetch).toHaveBeenCalledWith(
      'https://project.supabase.co/rest/v1/rpc/get_public_coach_profile',
      expect.objectContaining({
        body: JSON.stringify({ target_handle: 'coach-lestari' }),
        method: 'POST',
      }),
    );
    vi.unstubAllGlobals();
  });

  it('mengembalikan 404 untuk handle Coach publik yang tidak ditemukan', async () => {
    const { env } = makeEnvironment();
    vi.stubGlobal('fetch', vi.fn(async () => new Response('null', {
      headers: { 'Content-Type': 'application/json' },
    })));

    const response = await worker.fetch(
      new Request('https://candidate.invalid/c/tidak-ada'),
      { ...env, DEPLOYMENT_ENVIRONMENT: 'candidate' as const, SUPABASE_PUBLISHABLE_KEY: 'sb_publishable_test' },
    );

    expect(response.status).toBe(404);
    await expect(response.text()).resolves.toBe('tidak ditemukan');
    vi.unstubAllGlobals();
  });

  it('memberi noindex dan robots tertutup hanya untuk preview', async () => {
    const { env } = makeEnvironment();
    const previewEnv = { ...env, DEPLOYMENT_ENVIRONMENT: 'preview' as const };

    const response = await worker.fetch(new Request('https://preview.invalid/app'), previewEnv);
    expect(response.headers.get('X-Robots-Tag')).toBe('noindex, nofollow, noarchive');
    expect(response.headers.get('Cache-Control')).toBe('no-store, no-transform');

    const robots = await worker.fetch(new Request('https://preview.invalid/robots.txt'), previewEnv);
    await expect(robots.text()).resolves.toBe('User-agent: *\nDisallow: /\n');
    expect(robots.headers.get('X-Robots-Tag')).toContain('noindex');

    const local = await worker.fetch(new Request('https://local.invalid/robots.txt'), env);
    expect(local.headers.has('X-Robots-Tag')).toBe(false);
    await expect(local.text()).resolves.toContain('Allow: /');

    const candidateEnv = { ...env, DEPLOYMENT_ENVIRONMENT: 'candidate' as const };
    const candidate = await worker.fetch(new Request('https://candidate.invalid/app'), candidateEnv);
    expect(candidate.headers.get('X-Robots-Tag')).toContain('noindex');
    expect(candidate.headers.get('Content-Security-Policy')).toContain('https://project.supabase.co');
    expect(candidate.headers.has('Content-Security-Policy-Report-Only')).toBe(false);
  });

  it('menerapkan header keamanan dan cache berdasarkan jenis respons', async () => {
    const { env } = makeEnvironment();
    const html = await worker.fetch(new Request('https://msc.invalid/'), env);
    const asset = await worker.fetch(
      new Request('https://msc.invalid/_expo/static/js/web/app-a1b2c3d4.js'),
      env,
    );
    const wasm = await worker.fetch(
      new Request('https://msc.invalid/wasm/zxing-reader-3.1.1-6a858c01.wasm'),
      env,
    );

    expect(html.headers.get('Content-Security-Policy-Report-Only')).toContain("frame-ancestors 'none'");
    expect(html.headers.get('X-Content-Type-Options')).toBe('nosniff');
    expect(html.headers.get('Referrer-Policy')).toBe('strict-origin-when-cross-origin');
    expect(html.headers.get('Permissions-Policy')).toContain('camera=(self)');
    expect(html.headers.get('X-Request-ID')).toMatch(/^[0-9a-f-]{36}$/u);
    expect(html.headers.has('Strict-Transport-Security')).toBe(false);
    expect(asset.headers.get('Cache-Control')).toBe('public, max-age=31536000, immutable');
    expect(wasm.headers.get('Cache-Control')).toBe('public, max-age=31536000, immutable');
    expect(html.headers.get('Content-Security-Policy-Report-Only')).toContain(
      "script-src 'self' 'wasm-unsafe-eval'",
    );
    expect(html.headers.get('Content-Security-Policy-Report-Only')).not.toContain(" 'unsafe-eval'");
  });

  it('enforces production CSP dan mengarahkan www ke apex', async () => {
    const { env } = makeEnvironment();
    const productionEnv = { ...env, DEPLOYMENT_ENVIRONMENT: 'production' as const };
    const html = await worker.fetch(new Request('https://msc-body-transformation.com/'), productionEnv);
    expect(html.headers.get('Content-Security-Policy')).toContain('https://project.supabase.co');
    expect(html.headers.get('Content-Security-Policy')).toContain('wss://project.supabase.co');
    expect(html.headers.get('Content-Security-Policy')).toContain(
      "media-src 'self' blob: https://project.supabase.co",
    );
    expect(html.headers.has('Content-Security-Policy-Report-Only')).toBe(false);
    expect(html.headers.get('Content-Security-Policy')).not.toContain('127.0.0.1');
    expect(html.headers.get('Strict-Transport-Security')).toBe('max-age=31536000; includeSubDomains');

    const redirect = await worker.fetch(
      new Request('https://www.msc-body-transformation.com/app/profile?from=www'),
      productionEnv,
    );
    expect(redirect.status).toBe(308);
    expect(redirect.headers.get('Location')).toBe(
      'https://msc-body-transformation.com/app/profile?from=www',
    );
  });

  it('mencatat event edge tersensor dengan correlation ID tanpa path atau query', async () => {
    const { env } = makeEnvironment();
    const log = vi.spyOn(console, 'log').mockImplementation(() => undefined);
    const response = await worker.fetch(
      new Request('https://candidate.invalid/app/payments/11111111-1111-4111-8111-111111111111?token=rahasia'),
      { ...env, DEPLOYMENT_ENVIRONMENT: 'candidate' as const },
    );

    expect(log).toHaveBeenCalledOnce();
    expect(log).toHaveBeenCalledWith({
      environment: 'candidate',
      event: 'http_response',
      method: 'GET',
      request_id: response.headers.get('X-Request-ID'),
      route_group: 'app-shell',
      status: 200,
    });
    expect(JSON.stringify(log.mock.calls)).not.toContain('11111111');
    expect(JSON.stringify(log.mock.calls)).not.toContain('rahasia');
    log.mockRestore();
  });
});
