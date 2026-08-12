const managedCachePrefixes = ["msc-pwa-static-", "msc-pwa-runtime-"] as const;

type DevelopmentServiceWorkerContainer = Pick<
  ServiceWorkerContainer,
  "controller" | "getRegistrations"
>;

type DevelopmentCacheStorage = Pick<CacheStorage, "delete" | "keys">;

export async function clearDevelopmentPwaState(
  serviceWorker: DevelopmentServiceWorkerContainer,
  cacheStorage?: DevelopmentCacheStorage,
) {
  const registrations = await serviceWorker.getRegistrations();
  const cacheNames = cacheStorage ? await cacheStorage.keys() : [];

  await Promise.all([
    ...registrations.map((registration) => registration.unregister()),
    ...(cacheStorage
      ? cacheNames
          .filter((name) => managedCachePrefixes.some((prefix) => name.startsWith(prefix)))
          .map((name) => cacheStorage.delete(name))
      : []),
  ]);

  return serviceWorker.controller !== null;
}
