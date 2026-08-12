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
  '/coach',
  '/coach/programs',
  '/coach/profile',
  '/admin',
  '/admin/programs',
  '/admin/people',
  '/admin/content',
  '/admin/settings',
  '/auth/callback',
]);

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

    if (knownAppRoutes.has(url.pathname)) {
      return env.ASSETS.fetch(assetRequest(request, '/app.html'));
    }

    const notFound = await env.ASSETS.fetch(assetRequest(request, '/404.html'));
    return new Response(notFound.body, { status: 404, headers: notFound.headers });
  },
};

export default worker;
