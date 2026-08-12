const CACHE_NAME = 'msc-public-shell-w00-v1';
const PUBLIC_SHELL = ['/', '/offline.html', '/manifest.webmanifest'];

self.addEventListener('install', (event) => {
  event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(PUBLIC_SHELL)));
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key))),
    ),
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  const url = new URL(request.url);

  if (request.method !== 'GET' || url.origin !== self.location.origin || request.mode !== 'navigate') {
    return;
  }

  event.respondWith(
    fetch(request).catch(async () => {
      if (url.pathname === '/') {
        return (await caches.match('/')) || Response.error();
      }

      return (await caches.match('/offline.html')) || Response.error();
    }),
  );
});
