type AssetsBinding = {
  fetch(request: Request): Promise<Response>;
};

type WorkerEnvironment = {
  ASSETS: AssetsBinding;
};

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
  '/login',
  '/auth/callback',
]);

function isKnownAppRoute(pathname: string): boolean {
  if (knownAppRoutes.has(pathname)) return true;
  if (/^\/c\/[a-z0-9]+(?:-[a-z0-9]+)*$/.test(pathname)) return true;
  if (/^\/coach\/reviews\/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(pathname)) return true;
  if (/^\/coach\/participants\/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(pathname)) return true;
  if (/^\/admin\/payments\/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(pathname)) return true;
  if (/^\/app\/payments\/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(pathname)) return true;
  return /^\/app\/(programs|coaches)\/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(pathname);
}

const assetRequest = (request: Request, pathname: string) => {
  const url = new URL(request.url);
  url.pathname = pathname;
  return new Request(url, request);
};

export const worker = {
  async fetch(request: Request, env: WorkerEnvironment) {
    if (request.method !== 'GET' && request.method !== 'HEAD') {
      return new Response(null, { status: 405, headers: { Allow: 'GET, HEAD' } });
    }

    const url = new URL(request.url);
    if (url.pathname === '/') {
      return env.ASSETS.fetch(assetRequest(request, '/index.html'));
    }

    const assetResponse = await env.ASSETS.fetch(request);
    if (assetResponse.status !== 404) return assetResponse;

    if (url.pathname.includes('.')) {
      return new Response('Berkas tidak ditemukan.', { status: 404 });
    }

    if (isKnownAppRoute(url.pathname)) {
      return env.ASSETS.fetch(assetRequest(request, '/app.html'));
    }

    const notFound = await env.ASSETS.fetch(assetRequest(request, '/404.html'));
    return new Response(notFound.body, { status: 404, headers: notFound.headers });
  },
};

export default worker;
