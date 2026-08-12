"use client";

import type { MouseEvent } from "react";

import { requestShellRouteFocus } from "@/shared/route-transition";
import { AppIcon } from "@/shared/ui/icons/app-icon";

export function shouldUseAuthHistoryBack(
  referrer: string,
  currentOrigin: string,
  historyLength: number,
): boolean {
  if (!referrer || historyLength <= 1) return false;
  try {
    return new URL(referrer).origin === currentOrigin;
  } catch {
    return false;
  }
}

export function AuthCloseControl() {
  function close(event: MouseEvent<HTMLAnchorElement>) {
    if (
      shouldUseAuthHistoryBack(document.referrer, window.location.origin, window.history.length)
    ) {
      event.preventDefault();
      const returnLocation = new URL(document.referrer);
      requestShellRouteFocus(
        `${returnLocation.pathname}?${new URLSearchParams(returnLocation.search).toString()}`,
      );
      window.history.back();
      return;
    }
    requestShellRouteFocus("/hari-ini?");
  }

  return (
    <a className="auth-close-control" href="/hari-ini" onClick={close}>
      <AppIcon name="close" />
      <span>Tutup</span>
    </a>
  );
}
