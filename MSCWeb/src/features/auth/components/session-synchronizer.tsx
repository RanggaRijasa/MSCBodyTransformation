"use client";

import { useRouter } from "next/navigation";
import { useEffect } from "react";

import { subscribeToAuthClientEvents } from "@/application/auth/client-auth-events";

const channelName = "msc-auth-session";

function clearAccountScopedBrowserState() {
  for (const storage of [window.localStorage, window.sessionStorage]) {
    const keys = Array.from({ length: storage.length }, (_, index) => storage.key(index)).filter(
      (key): key is string => Boolean(key?.startsWith("msc.")),
    );
    for (const key of keys) storage.removeItem(key);
  }
  navigator.serviceWorker?.controller?.postMessage({ type: "MSC_CLEAR_CLIENT_STATE" });
}

export function SessionSynchronizer() {
  const router = useRouter();

  useEffect(() => {
    let channel: BroadcastChannel | null = null;
    try {
      channel = "BroadcastChannel" in window ? new BroadcastChannel(channelName) : null;
      channel?.addEventListener("message", (message) => {
        if (["SIGNED_IN", "SIGNED_OUT"].includes(message.data?.event))
          clearAccountScopedBrowserState();
        router.refresh();
      });
    } catch {
      channel = null;
    }

    let unsubscribe: (() => void) | undefined;
    try {
      unsubscribe = subscribeToAuthClientEvents((event) => {
        if (event === "SIGNED_IN" || event === "SIGNED_OUT") clearAccountScopedBrowserState();
        channel?.postMessage({ event });
        router.refresh();
      });
    } catch {
      // Public pages remain usable when local service configuration is absent.
    }

    const refreshVisibleSession = () => {
      if (document.visibilityState === "visible") router.refresh();
    };
    document.addEventListener("visibilitychange", refreshVisibleSession);
    return () => {
      document.removeEventListener("visibilitychange", refreshVisibleSession);
      unsubscribe?.();
      channel?.close();
    };
  }, [router]);

  return null;
}
