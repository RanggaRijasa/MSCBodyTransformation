const knownAppRoutes = new Set([
  '/app',
  '/app/home',
  '/app/programs',
  '/app/leaderboard',
  '/app/coaches',
  '/app/feasibility',
  '/app/profile',
  '/app/coach-application',
  '/coach',
  '/coach/activity',
  '/coach/leaderboard',
  '/coach/participants',
  '/coach/programs',
  '/coach/profile',
  '/coach/qr',
  '/coach/reviews',
  '/admin',
  '/admin/programs',
  '/admin/people',
  '/admin/content',
  '/admin/settings',
  '/admin/payments',
  '/admin/operations',
  '/admin/audit',
  '/login',
  '/auth/callback',
  '/onboarding/profile',
  '/onboarding/participant/coach',
  '/onboarding/coach/eligibility',
  '/onboarding/coach/payment',
  '/onboarding/coach/status',
  '/onboarding/cleanup',
]);

const staticPageAssets = new Map([
  ['/bantuan-pembayaran', '/bantuan-pembayaran.html'],
  ['/cara-memasang', '/cara-memasang.html'],
  ['/kebijakan-privasi', '/kebijakan-privasi.html'],
  ['/ketentuan', '/ketentuan.html'],
]);

type WorkerEnvironment = Pick<Env, 'DEPLOYMENT_ENVIRONMENT' | 'SUPABASE_ORIGIN'> & {
  ASSETS: Pick<Fetcher, 'fetch'>;
  SUPABASE_PUBLISHABLE_KEY?: string;
};

type PublicCoachMetadata = {
  biography?: string;
  displayName: string;
  handle: string;
  photoReference?: string;
  professionalHeadline?: string;
  serviceArea?: string;
};

const publicCoachPathPattern = /^\/c\/([a-z0-9]+(?:-[a-z0-9]+)*)$/;
const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function isKnownAppRoute(pathname: string): boolean {
  if (knownAppRoutes.has(pathname)) return true;
  if (/^\/c\/[a-z0-9]+(?:-[a-z0-9]+)*$/.test(pathname)) return true;
  if (/^\/coach\/reviews\/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(pathname)) return true;
  if (/^\/coach\/participants\/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(pathname)) return true;
  if (/^\/admin\/payments\/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(pathname)) return true;
  if (/^\/admin\/(programs|people)\/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(pathname)) return true;
  if (/^\/app\/payments\/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(pathname)) return true;
  return /^\/app\/(programs|coaches)\/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(pathname);
}

const assetRequest = (request: Request, pathname: string) => {
  const url = new URL(request.url);
  url.pathname = pathname;
  return new Request(url, request);
};

const htmlPaths = new Set([
  '/',
  '/index.html',
  '/app.html',
  '/404.html',
  '/offline.html',
  '/landing.html',
  '/cara-memasang.html',
  '/bantuan-pembayaran.html',
  '/kebijakan-privasi.html',
  '/ketentuan.html',
]);

const updateSensitivePaths = new Set(['/manifest.webmanifest', '/sw.js', '/robots.txt']);
const hashedAssetPattern = /(?:^|\/)[^/]*[.-][a-f0-9]{8,}\.(?:css|js|mjs|png|jpe?g|webp|svg|wasm|woff2?)$/iu;

type RouteGroup = 'landing' | 'static-page' | 'public-coach' | 'app-shell' | 'asset' | 'not-found';

function routeGroup(pathname: string, status: number, isAppShell: boolean): RouteGroup {
  if (status >= 400) return 'not-found';
  if (pathname === '/') return 'landing';
  if (staticPageAssets.has(pathname)) return 'static-page';
  if (publicCoachPathPattern.test(pathname)) return 'public-coach';
  if (isAppShell || isKnownAppRoute(pathname)) return 'app-shell';
  return 'asset';
}

function contentSecurityPolicy(env: WorkerEnvironment): string {
  const supabaseOrigin = validatedSupabaseOrigin(env.SUPABASE_ORIGIN);
  const supabaseRealtimeOrigin = supabaseOrigin.startsWith('https://')
    ? supabaseOrigin.replace('https://', 'wss://')
    : "'self'";
  const productionConnectSources = [...new Set(["'self'", supabaseOrigin, supabaseRealtimeOrigin])];
  const connectSources = ['production', 'candidate'].includes(env.DEPLOYMENT_ENVIRONMENT)
    ? productionConnectSources
    : [...productionConnectSources, 'http://127.0.0.1:54321', 'ws://127.0.0.1:54321'];
  return [
    "default-src 'self'",
    "base-uri 'self'",
    `connect-src ${connectSources.join(' ')}`,
    "font-src 'self' data:",
    "form-action 'self'",
    "frame-ancestors 'none'",
    "img-src 'self' data: blob: https:",
    "manifest-src 'self'",
    `media-src 'self' blob: ${supabaseOrigin}`,
    "object-src 'none'",
    "script-src 'self' 'wasm-unsafe-eval'",
    "style-src 'self' 'unsafe-inline'",
    "worker-src 'self' blob:",
  ].join('; ');
}

function validatedSupabaseOrigin(value: string): string {
  try {
    const url = new URL(value);
    if (url.protocol !== 'https:' || url.pathname !== '/' || url.search || url.hash
      || !url.hostname.endsWith('.supabase.co')) return "'self'";
    return url.origin;
  } catch {
    return "'self'";
  }
}

function safeText(value: unknown, maximumLength: number): string | undefined {
  if (typeof value !== 'string') return undefined;
  const normalized = value.trim().replace(/\s+/gu, ' ');
  if (!normalized) return undefined;
  return normalized.slice(0, maximumLength);
}

function parsePublicCoachMetadata(value: unknown, expectedHandle: string): PublicCoachMetadata | null {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) return null;
  const record = value as Record<string, unknown>;
  const handle = safeText(record.handle, 80);
  const displayName = safeText(record.display_name, 120);
  if (handle !== expectedHandle || !displayName || record.is_verified !== true) return null;

  const photoReference = safeText(record.photo_reference, 36);
  return {
    biography: safeText(record.biography, 280),
    displayName,
    handle,
    photoReference: photoReference && uuidPattern.test(photoReference) ? photoReference : undefined,
    professionalHeadline: safeText(record.professional_headline, 160),
    serviceArea: safeText(record.service_area, 120),
  };
}

function escapeHtml(value: string): string {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

function coachMetadataDescription(profile: PublicCoachMetadata): string {
  const description = profile.professionalHeadline
    ?? profile.biography
    ?? `Profil Coach terverifikasi di MSC Body Transformation${profile.serviceArea ? ` untuk area ${profile.serviceArea}` : ''}.`;
  return description.slice(0, 200);
}

function injectCoachMetadata(
  html: string,
  profile: PublicCoachMetadata,
  env: WorkerEnvironment,
): string {
  const title = `${profile.displayName} — Coach MSC Body Transformation`;
  const description = coachMetadataDescription(profile);
  const canonicalUrl = `https://msc-body-transformation.com/c/${encodeURIComponent(profile.handle)}`;
  const imageUrl = profile.photoReference
    ? `${new URL(env.SUPABASE_ORIGIN).origin}/functions/v1/public-coach-media/${profile.photoReference}`
    : undefined;
  const socialTags = [
    `<link rel="canonical" href="${escapeHtml(canonicalUrl)}" />`,
    '<meta property="og:type" content="profile" />',
    `<meta property="og:title" content="${escapeHtml(title)}" />`,
    `<meta property="og:description" content="${escapeHtml(description)}" />`,
    `<meta property="og:url" content="${escapeHtml(canonicalUrl)}" />`,
    '<meta property="og:site_name" content="MSC Body Transformation" />',
    '<meta name="twitter:card" content="summary_large_image" />',
    `<meta name="twitter:title" content="${escapeHtml(title)}" />`,
    `<meta name="twitter:description" content="${escapeHtml(description)}" />`,
    ...(imageUrl ? [
      `<meta property="og:image" content="${escapeHtml(imageUrl)}" />`,
      `<meta name="twitter:image" content="${escapeHtml(imageUrl)}" />`,
    ] : []),
  ].join('\n    ');

  return html
    .replace(/<title>[^<]*<\/title>/iu, `<title>${escapeHtml(title)}</title>`)
    .replace(
      /<meta\s+name="description"\s+content="[^"]*"\s*\/>/iu,
      `<meta name="description" content="${escapeHtml(description)}" />`,
    )
    .replace('</head>', `    ${socialTags}\n  </head>`);
}

async function fetchPublicCoachMetadata(
  env: WorkerEnvironment,
  handle: string,
): Promise<PublicCoachMetadata | null | undefined> {
  if (!env.SUPABASE_PUBLISHABLE_KEY) return undefined;
  try {
    const response = await fetch(`${new URL(env.SUPABASE_ORIGIN).origin}/rest/v1/rpc/get_public_coach_profile`, {
      method: 'POST',
      headers: {
        apikey: env.SUPABASE_PUBLISHABLE_KEY,
        Authorization: `Bearer ${env.SUPABASE_PUBLISHABLE_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ target_handle: handle }),
    });
    if (!response.ok) return undefined;
    const value: unknown = await response.json();
    if (value === null) return null;
    return parsePublicCoachMetadata(value, handle);
  } catch {
    return undefined;
  }
}

function cacheControlFor(pathname: string, status: number, isAppShell: boolean): string {
  if (
    status >= 400
    || isAppShell
    || htmlPaths.has(pathname)
    || staticPageAssets.has(pathname)
    || updateSensitivePaths.has(pathname)
  ) {
    return 'no-store, no-transform';
  }
  if (hashedAssetPattern.test(pathname)) {
    return 'public, max-age=31536000, immutable';
  }
  return 'public, max-age=3600, must-revalidate';
}

function applyResponsePolicy(
  request: Request,
  response: Response,
  env: WorkerEnvironment,
  isAppShell = false,
): Response {
  const headers = new Headers(response.headers);
  const pathname = new URL(request.url).pathname;
  const requestId = crypto.randomUUID();

  headers.set('Cache-Control', cacheControlFor(pathname, response.status, isAppShell));
  const policy = contentSecurityPolicy(env);
  if (['production', 'candidate'].includes(env.DEPLOYMENT_ENVIRONMENT)) {
    headers.set('Content-Security-Policy', policy);
    headers.delete('Content-Security-Policy-Report-Only');
  } else {
    headers.set('Content-Security-Policy-Report-Only', policy);
    headers.delete('Content-Security-Policy');
  }
  headers.set('Permissions-Policy', 'camera=(self), geolocation=(), microphone=(), payment=(), usb=()');
  headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');
  headers.set('X-Content-Type-Options', 'nosniff');
  headers.set('X-Frame-Options', 'DENY');
  headers.set('X-Request-ID', requestId);

  if (env.DEPLOYMENT_ENVIRONMENT === 'production') {
    headers.set('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
  } else {
    headers.delete('Strict-Transport-Security');
  }

  if (['preview', 'candidate'].includes(env.DEPLOYMENT_ENVIRONMENT)) {
    headers.set('X-Robots-Tag', 'noindex, nofollow, noarchive');
  }

  if (env.DEPLOYMENT_ENVIRONMENT !== 'local') {
    console.log({
      environment: env.DEPLOYMENT_ENVIRONMENT,
      event: 'http_response',
      method: request.method,
      request_id: requestId,
      route_group: routeGroup(pathname, response.status, isAppShell),
      status: response.status,
    });
  }

  return new Response(request.method === 'HEAD' ? null : response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

async function serveAsset(
  request: Request,
  env: WorkerEnvironment,
  pathname?: string,
  isAppShell = false,
): Promise<Response> {
  const response = await env.ASSETS.fetch(pathname ? assetRequest(request, pathname) : request);
  return applyResponsePolicy(request, response, env, isAppShell);
}

async function servePublicCoachProfile(
  request: Request,
  env: WorkerEnvironment,
  handle: string,
): Promise<Response> {
  const profile = await fetchPublicCoachMetadata(env, handle);
  if (profile === null) {
    const notFound = await env.ASSETS.fetch(assetRequest(request, '/404.html'));
    return applyResponsePolicy(
      request,
      new Response(notFound.body, { status: 404, headers: notFound.headers }),
      env,
    );
  }
  if (!profile) return serveAsset(request, env, '/app.html', true);

  const appShell = await env.ASSETS.fetch(assetRequest(request, '/app.html'));
  if (!appShell.ok) return applyResponsePolicy(request, appShell, env, true);
  const headers = new Headers(appShell.headers);
  headers.set('Content-Type', 'text/html; charset=utf-8');
  const html = injectCoachMetadata(await appShell.text(), profile, env);
  return applyResponsePolicy(request, new Response(html, { headers }), env, true);
}

export const worker = {
  async fetch(request: Request, env: WorkerEnvironment): Promise<Response> {
    if (request.method !== 'GET' && request.method !== 'HEAD') {
      return applyResponsePolicy(
        request,
        new Response(null, { status: 405, headers: { Allow: 'GET, HEAD' } }),
        env,
      );
    }

    const url = new URL(request.url);
    if (env.DEPLOYMENT_ENVIRONMENT === 'production'
      && url.hostname === 'www.msc-body-transformation.com') {
      url.hostname = 'msc-body-transformation.com';
      return applyResponsePolicy(
        request,
        new Response(null, { status: 308, headers: { Location: url.toString() } }),
        env,
      );
    }
    if (url.pathname === '/robots.txt'
      && ['preview', 'candidate'].includes(env.DEPLOYMENT_ENVIRONMENT)) {
      return applyResponsePolicy(
        request,
        new Response('User-agent: *\nDisallow: /\n', {
          headers: { 'Content-Type': 'text/plain; charset=utf-8' },
        }),
        env,
      );
    }

    if (url.pathname === '/') {
      return serveAsset(request, env, '/index.html');
    }

    const staticPageAsset = staticPageAssets.get(url.pathname);
    if (staticPageAsset) {
      return serveAsset(request, env, staticPageAsset);
    }

    const publicCoachMatch = url.pathname.match(publicCoachPathPattern);
    if (publicCoachMatch?.[1]) {
      return servePublicCoachProfile(request, env, publicCoachMatch[1]);
    }

    const assetResponse = await env.ASSETS.fetch(request);
    if (assetResponse.status !== 404) return applyResponsePolicy(request, assetResponse, env);

    if (url.pathname.includes('.')) {
      return applyResponsePolicy(
        request,
        new Response('Berkas tidak ditemukan.', { status: 404 }),
        env,
      );
    }

    if (isKnownAppRoute(url.pathname)) {
      return serveAsset(request, env, '/app.html', true);
    }

    const notFound = await env.ASSETS.fetch(assetRequest(request, '/404.html'));
    return applyResponsePolicy(
      request,
      new Response(notFound.body, { status: 404, headers: notFound.headers }),
      env,
    );
  },
} satisfies ExportedHandler<Env>;

export default worker;
