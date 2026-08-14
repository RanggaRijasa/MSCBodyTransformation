import { createReadStream, existsSync, statSync } from 'node:fs';
import { createServer } from 'node:http';
import { extname, join, normalize, resolve } from 'node:path';

const host = process.env.HOST || '127.0.0.1';
const port = Number(process.env.PORT || 4173);
const root = resolve(process.cwd(), 'dist');

if (!existsSync(join(root, 'index.html')) || !existsSync(join(root, 'app.html'))) {
  throw new Error('Build production belum ada. Jalankan npm run build terlebih dahulu.');
}

const contentTypes = new Map([
  ['.css', 'text/css; charset=utf-8'],
  ['.html', 'text/html; charset=utf-8'],
  ['.ico', 'image/x-icon'],
  ['.js', 'text/javascript; charset=utf-8'],
  ['.jpg', 'image/jpeg'],
  ['.json', 'application/json; charset=utf-8'],
  ['.png', 'image/png'],
  ['.svg', 'image/svg+xml'],
  ['.webmanifest', 'application/manifest+json; charset=utf-8'],
]);

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

function isKnownAppRoute(pathname) {
  if (knownAppRoutes.has(pathname)) return true;
  if (/^\/c\/[a-z0-9]+(?:-[a-z0-9]+)*$/.test(pathname)) return true;
  if (/^\/coach\/reviews\/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(pathname)) return true;
  if (/^\/coach\/participants\/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(pathname)) return true;
  if (/^\/admin\/payments\/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(pathname)) return true;
  if (/^\/app\/payments\/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(pathname)) return true;
  return /^\/app\/(programs|coaches)\/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(pathname);
}

function resolveStaticPath(pathname) {
  const decoded = decodeURIComponent(pathname);
  const normalizedPath = normalize(decoded).replace(/^(\.\.(\/|\\|$))+/, '');
  const candidate = resolve(root, `.${normalizedPath}`);

  if (!candidate.startsWith(`${root}/`) && candidate !== root) {
    return null;
  }

  if (existsSync(candidate) && statSync(candidate).isFile()) {
    return candidate;
  }

  if (existsSync(`${candidate}.html`) && statSync(`${candidate}.html`).isFile()) {
    return `${candidate}.html`;
  }

  return null;
}

function sendFile(request, response, filePath, statusCode = 200) {
  response.writeHead(statusCode, {
    'Cache-Control': filePath.endsWith('.html') ? 'no-cache' : 'public, max-age=3600',
    'Content-Type': contentTypes.get(extname(filePath)) || 'application/octet-stream',
    'X-Content-Type-Options': 'nosniff',
  });

  if (request.method === 'HEAD') {
    response.end();
    return;
  }

  createReadStream(filePath).pipe(response);
}

const server = createServer((request, response) => {
  if (request.method !== 'GET' && request.method !== 'HEAD') {
    response.writeHead(405, { Allow: 'GET, HEAD' });
    response.end();
    return;
  }

  const requestURL = new URL(request.url || '/', `http://${host}:${port}`);

  if (requestURL.pathname === '/') {
    sendFile(request, response, join(root, 'index.html'));
    return;
  }

  const staticPath = resolveStaticPath(requestURL.pathname);

  if (staticPath) {
    sendFile(request, response, staticPath);
    return;
  }

  if (extname(requestURL.pathname)) {
    response.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
    response.end('Berkas tidak ditemukan.');
    return;
  }

  const knownRoute = isKnownAppRoute(requestURL.pathname);
  sendFile(
    request,
    response,
    join(root, knownRoute ? 'app.html' : '404.html'),
    knownRoute ? 200 : 404,
  );
});

server.listen(port, host, () => {
  process.stdout.write(`MSCWEB production server: http://${host}:${port}\n`);
});
