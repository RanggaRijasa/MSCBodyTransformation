"use client";

import { useRouter } from "next/navigation";
import { useCallback, useEffect, useRef, useState, type ReactNode } from "react";

import { clearDevelopmentPwaState } from "@/features/pwa-runtime/lib/clear-development-pwa-state";
import { AppButton } from "@/shared/ui/controls/actions";

const runtimeChannelName = "msc-pwa-runtime";
const developmentResetMarker = "msc.dev-pwa-reset-v1";

export function PwaRuntimeProvider({ children }: Readonly<{ children: ReactNode }>) {
  const router = useRouter();
  const registrationReference = useRef<ServiceWorkerRegistration | null>(null);
  const shouldReloadReference = useRef(false);
  const [isOnline, setOnline] = useState(true);
  const [isRetrying, setRetrying] = useState(false);
  const [isUpdateAvailable, setUpdateAvailable] = useState(false);

  useEffect(() => {
    if (!("serviceWorker" in navigator) || !window.isSecureContext) return;
    let disposed = false;

    if (process.env.NODE_ENV !== "production") {
      void clearDevelopmentPwaState(
        navigator.serviceWorker,
        "caches" in window ? window.caches : undefined,
      ).then((wasControlled) => {
        if (disposed) return;
        delete document.documentElement.dataset.pwaServiceWorker;
        if (wasControlled && sessionStorage.getItem(developmentResetMarker) !== "complete") {
          sessionStorage.setItem(developmentResetMarker, "complete");
          window.location.reload();
          return;
        }
        sessionStorage.removeItem(developmentResetMarker);
      });

      return () => {
        disposed = true;
      };
    }

    let channel: BroadcastChannel | null = null;
    try {
      channel = "BroadcastChannel" in window ? new BroadcastChannel(runtimeChannelName) : null;
    } catch {
      channel = null;
    }

    const announceReady = () => {
      document.documentElement.dataset.pwaServiceWorker = "ready";
      window.dispatchEvent(new Event("msc:pwa-ready"));
    };
    const markUpdateAvailable = () => {
      setUpdateAvailable(true);
      channel?.postMessage({ type: "update-ready" });
    };
    const watchRegistration = (registration: ServiceWorkerRegistration) => {
      registrationReference.current = registration;
      if (registration.waiting && navigator.serviceWorker.controller) markUpdateAvailable();
      registration.addEventListener("updatefound", () => {
        const installing = registration.installing;
        installing?.addEventListener("statechange", () => {
          if (installing.state === "installed" && navigator.serviceWorker.controller)
            markUpdateAvailable();
        });
      });
      announceReady();
    };

    void navigator.serviceWorker
      .register("/sw.js", { scope: "/", updateViaCache: "none" })
      .then((registration) => {
        if (!disposed) watchRegistration(registration);
      })
      .catch(() => {
        if (!disposed) delete document.documentElement.dataset.pwaServiceWorker;
      });

    const handleControllerChange = () => {
      announceReady();
      if (shouldReloadReference.current) window.location.reload();
    };
    const handleWorkerMessage = (event: MessageEvent) => {
      if (event.data?.type === "MSC_PWA_ACTIVATED") {
        setUpdateAvailable(false);
        announceReady();
      }
    };
    const handleChannelMessage = (event: MessageEvent) => {
      if (event.data?.type === "update-ready") setUpdateAvailable(true);
      if (event.data?.type === "update-applying") shouldReloadReference.current = true;
    };
    const updateConnectivity = () => setOnline(navigator.onLine);
    const updateWhenVisible = () => {
      if (document.visibilityState === "visible") void registrationReference.current?.update();
    };
    channel?.addEventListener("message", handleChannelMessage);
    navigator.serviceWorker.addEventListener("controllerchange", handleControllerChange);
    navigator.serviceWorker.addEventListener("message", handleWorkerMessage);
    window.addEventListener("online", updateConnectivity);
    window.addEventListener("offline", updateConnectivity);
    document.addEventListener("visibilitychange", updateWhenVisible);
    updateConnectivity();

    return () => {
      disposed = true;
      channel?.removeEventListener("message", handleChannelMessage);
      channel?.close();
      navigator.serviceWorker.removeEventListener("controllerchange", handleControllerChange);
      navigator.serviceWorker.removeEventListener("message", handleWorkerMessage);
      window.removeEventListener("online", updateConnectivity);
      window.removeEventListener("offline", updateConnectivity);
      document.removeEventListener("visibilitychange", updateWhenVisible);
      delete document.documentElement.dataset.pwaServiceWorker;
    };
  }, []);

  const retry = useCallback(async () => {
    setRetrying(true);
    try {
      const response = await fetch("/manifest.webmanifest", { cache: "no-store" });
      if (!response.ok) throw new Error("connection_check_failed");
      setOnline(true);
      router.refresh();
    } catch {
      setOnline(false);
    } finally {
      setRetrying(false);
    }
  }, [router]);

  const applyUpdate = useCallback(() => {
    const waiting = registrationReference.current?.waiting;
    if (!waiting) {
      void registrationReference.current?.update();
      return;
    }
    shouldReloadReference.current = true;
    try {
      const channel = new BroadcastChannel(runtimeChannelName);
      channel.postMessage({ type: "update-applying" });
      channel.close();
    } catch {
      // The active tab still updates when BroadcastChannel is unavailable.
    }
    waiting.postMessage({ type: "MSC_ACTIVATE_UPDATE" });
  }, []);

  return (
    <>
      {children}
      {!isOnline ? (
        <aside className="pwa-runtime-banner pwa-runtime-banner--offline" role="status">
          <div>
            <strong>Kamu sedang offline</strong>
            <span>Perubahan pribadi belum akan dianggap berhasil sampai tersimpan di server.</span>
          </div>
          <AppButton isLoading={isRetrying} onClick={() => void retry()} variant="secondary">
            Coba lagi
          </AppButton>
        </aside>
      ) : null}
      {isUpdateAvailable ? (
        <aside className="pwa-runtime-banner pwa-runtime-banner--update" role="status">
          <div>
            <strong>Pembaruan MSC tersedia</strong>
            <span>Muat versi baru setelah pekerjaanmu saat ini selesai.</span>
          </div>
          <AppButton onClick={applyUpdate}>Muat versi baru</AppButton>
        </aside>
      ) : null}
    </>
  );
}
