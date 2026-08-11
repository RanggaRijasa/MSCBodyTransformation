/* MSC PWA service worker: only public, non-personal assets may enter Cache Storage. */

const BUILD_VERSION = "phase11-20260811-1";
const STATIC_CACHE = `msc-pwa-static-${BUILD_VERSION}`;
const CACHE_PREFIXES = ["msc-pwa-static-", "msc-pwa-runtime-"];
const OFFLINE_URL = "/offline.html";
const PUBLIC_ASSETS = new Set([
  OFFLINE_URL,
  "/icons/app-icon-192.png",
  "/icons/app-icon-512.png",
  "/icons/app-icon-maskable-512.png",
  "/icons/apple-touch-icon.png",
  "/icons/favicon-32.png",
  "/images/pwa-coach-rc-v1.jpg",
  "/images/pwa-participant-rc-v1.jpg",
]);

function isCurrentCache(name) {
  return name === STATIC_CACHE;
}

function isManagedCache(name) {
  return CACHE_PREFIXES.some((prefix) => name.startsWith(prefix));
}

async function notifyClients(message) {
  const clients = await self.clients.matchAll({ includeUncontrolled: true, type: "window" });
  for (const client of clients) client.postMessage(message);
}

self.addEventListener("install", (event) => {
  event.waitUntil(caches.open(STATIC_CACHE).then((cache) => cache.addAll([...PUBLIC_ASSETS])));
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    (async () => {
      const names = await caches.keys();
      await Promise.all(
        names
          .filter((name) => isManagedCache(name) && !isCurrentCache(name))
          .map((name) => caches.delete(name)),
      );
      await self.clients.claim();
      await notifyClients({ type: "MSC_PWA_ACTIVATED", version: BUILD_VERSION });
    })(),
  );
});

async function publicAssetResponse(request) {
  const cache = await caches.open(STATIC_CACHE);
  const cached = await cache.match(request, { ignoreSearch: false });
  if (cached) return cached;
  const response = await fetch(request, { cache: "no-store" });
  if (response.ok && response.type === "basic") await cache.put(request, response.clone());
  return response;
}

async function navigationResponse(request) {
  try {
    return await fetch(request, { cache: "no-store" });
  } catch {
    return (await caches.match(OFFLINE_URL)) ?? Response.error();
  }
}

self.addEventListener("fetch", (event) => {
  const request = event.request;
  if (request.method !== "GET") return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;

  if (request.mode === "navigate") {
    event.respondWith(navigationResponse(request));
    return;
  }

  const isFingerprintedNextAsset =
    url.search === "" &&
    url.pathname.startsWith("/_next/static/") &&
    ["font", "script", "style", "worker"].includes(request.destination);
  const isAllowlistedPublicAsset = url.search === "" && PUBLIC_ASSETS.has(url.pathname);
  if (isFingerprintedNextAsset || isAllowlistedPublicAsset) {
    event.respondWith(publicAssetResponse(request));
  }
});

self.addEventListener("message", (event) => {
  const type = event.data?.type;
  if (type === "MSC_ACTIVATE_UPDATE") {
    self.skipWaiting();
    return;
  }
  if (type === "MSC_CLEAR_CLIENT_STATE") {
    event.waitUntil(
      (async () => {
        const names = await caches.keys();
        await Promise.all(
          names
            .filter(
              (name) => name.startsWith("msc-private-") || name.startsWith("msc-pwa-runtime-"),
            )
            .map((name) => caches.delete(name)),
        );
        await notifyClients({ type: "MSC_CLIENT_STATE_CLEARED" });
      })(),
    );
  }
});

function safeNotificationPayload(rawPayload) {
  const fallback = {
    body: "Ada pembaruan pada akun MSC-mu.",
    tag: "msc-update",
    title: "Pembaruan MSC",
    url: "/hari-ini",
  };
  try {
    const value = JSON.parse(rawPayload);
    const url = typeof value.url === "string" ? value.url : fallback.url;
    if (!url.startsWith("/") || url.startsWith("//") || /[\r\n]/.test(url)) return fallback;
    return {
      body: typeof value.body === "string" ? value.body.slice(0, 180) : fallback.body,
      tag: typeof value.tag === "string" ? value.tag.slice(0, 64) : fallback.tag,
      title: typeof value.title === "string" ? value.title.slice(0, 80) : fallback.title,
      url,
    };
  } catch {
    return fallback;
  }
}

self.addEventListener("push", (event) => {
  const payload = safeNotificationPayload(event.data?.text() ?? "");
  event.waitUntil(
    self.registration.showNotification(payload.title, {
      badge: "/icons/app-icon-192.png",
      body: payload.body,
      data: { url: payload.url },
      icon: "/icons/app-icon-192.png",
      renotify: false,
      tag: payload.tag,
    }),
  );
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  const path = safeNotificationPayload(JSON.stringify({ url: event.notification.data?.url })).url;
  event.waitUntil(
    (async () => {
      const windows = await self.clients.matchAll({ includeUncontrolled: true, type: "window" });
      const existing = windows.find(
        (client) => new URL(client.url).origin === self.location.origin,
      );
      if (existing) {
        await existing.navigate(path);
        return existing.focus();
      }
      return self.clients.openWindow(path);
    })(),
  );
});

self.addEventListener("pushsubscriptionchange", (event) => {
  event.waitUntil(notifyClients({ type: "MSC_PUSH_SUBSCRIPTION_CHANGED" }));
});
