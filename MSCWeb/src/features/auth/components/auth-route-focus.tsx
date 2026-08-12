"use client";

import { useEffect } from "react";

import {
  currentBrowserRouteKey,
  requestShellRouteFocus,
  writeShellRouteMarker,
} from "@/shared/route-transition";

type AuthRouteFocusProperties = Readonly<{
  focusKey: string;
  headingId: string;
}>;

export function AuthRouteFocus({ focusKey, headingId }: AuthRouteFocusProperties) {
  useEffect(() => {
    writeShellRouteMarker(currentBrowserRouteKey());
    const requestFocusAfterHistoryNavigation = () => {
      requestShellRouteFocus(currentBrowserRouteKey());
    };
    window.addEventListener("popstate", requestFocusAfterHistoryNavigation);
    const frame = requestAnimationFrame(() => {
      const activeElement = document.activeElement;
      if (activeElement && activeElement !== document.body && activeElement.isConnected) return;
      document.getElementById(headingId)?.focus({ preventScroll: true });
    });
    return () => {
      cancelAnimationFrame(frame);
      window.removeEventListener("popstate", requestFocusAfterHistoryNavigation);
    };
  }, [focusKey, headingId]);

  return null;
}
