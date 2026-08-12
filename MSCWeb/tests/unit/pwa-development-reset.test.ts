import { describe, expect, it, vi } from "vitest";

import { clearDevelopmentPwaState } from "@/features/pwa-runtime/lib/clear-development-pwa-state";

describe("development PWA reset", () => {
  it("menghapus registrasi dan cache MSC tanpa menyentuh cache lain", async () => {
    const unregisterFirst = vi.fn().mockResolvedValue(true);
    const unregisterSecond = vi.fn().mockResolvedValue(true);
    const deleteCache = vi.fn().mockResolvedValue(true);
    const serviceWorker = {
      controller: {} as ServiceWorker,
      getRegistrations: vi
        .fn()
        .mockResolvedValue([{ unregister: unregisterFirst }, { unregister: unregisterSecond }]),
    };
    const cacheStorage = {
      delete: deleteCache,
      keys: vi
        .fn()
        .mockResolvedValue(["msc-pwa-static-lama", "msc-pwa-runtime-test", "cache-lain"]),
    };

    await expect(clearDevelopmentPwaState(serviceWorker, cacheStorage)).resolves.toBe(true);
    expect(unregisterFirst).toHaveBeenCalledOnce();
    expect(unregisterSecond).toHaveBeenCalledOnce();
    expect(deleteCache).toHaveBeenCalledTimes(2);
    expect(deleteCache).toHaveBeenCalledWith("msc-pwa-static-lama");
    expect(deleteCache).toHaveBeenCalledWith("msc-pwa-runtime-test");
    expect(deleteCache).not.toHaveBeenCalledWith("cache-lain");
  });

  it("tidak meminta reload ketika halaman tidak lagi dikontrol worker", async () => {
    const serviceWorker = {
      controller: null,
      getRegistrations: vi.fn().mockResolvedValue([]),
    };

    await expect(clearDevelopmentPwaState(serviceWorker)).resolves.toBe(false);
  });
});
