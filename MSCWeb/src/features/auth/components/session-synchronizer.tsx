"use client";

import { useRouter } from "next/navigation";
import { useEffect } from "react";

import { subscribeToAuthClientEvents } from "@/application/auth/client-auth-events";

const channelName = "msc-auth-session";

export function SessionSynchronizer() {
  const router = useRouter();

  useEffect(() => {
    let channel: BroadcastChannel | null = null;
    try {
      channel = "BroadcastChannel" in window ? new BroadcastChannel(channelName) : null;
      channel?.addEventListener("message", () => router.refresh());
    } catch {
      channel = null;
    }

    let unsubscribe: (() => void) | undefined;
    try {
      unsubscribe = subscribeToAuthClientEvents((event) => {
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
