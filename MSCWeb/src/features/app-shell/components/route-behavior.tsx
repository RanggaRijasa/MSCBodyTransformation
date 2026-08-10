"use client";

import { usePathname } from "next/navigation";
import { useEffect, useRef } from "react";

import { mainContentId } from "@/features/app-shell/model/shell-constants";

const scrollStoragePrefix = "msc-shell-scroll:";

export function saveShellScrollPosition(pathname: string) {
  try {
    sessionStorage.setItem(`${scrollStoragePrefix}${pathname}`, String(window.scrollY));
  } catch {
    // Browser privacy modes may deny storage; native history remains the safe fallback.
  }
}

function readShellScrollPosition(pathname: string): number {
  try {
    return Number.parseInt(sessionStorage.getItem(`${scrollStoragePrefix}${pathname}`) ?? "0", 10);
  } catch {
    return 0;
  }
}

export function RouteBehavior() {
  const pathname = usePathname();
  const previousPath = useRef(pathname);

  useEffect(() => {
    const previousBehavior = history.scrollRestoration;
    history.scrollRestoration = "manual";

    return () => {
      history.scrollRestoration = previousBehavior;
    };
  }, []);

  useEffect(() => {
    const restoredPosition = readShellScrollPosition(pathname);
    let restoreFrame = 0;
    let settleTimer = 0;
    const frame =
      restoredPosition > 0
        ? requestAnimationFrame(() => {
            restoreFrame = requestAnimationFrame(() => {
              window.scrollTo({ top: restoredPosition });
              settleTimer = window.setTimeout(
                () => window.scrollTo({ top: restoredPosition }),
                100,
              );
            });
          })
        : 0;

    if (previousPath.current !== pathname) {
      const heading = document.querySelector<HTMLElement>(`#${mainContentId} h1`);
      heading?.setAttribute("tabindex", "-1");
      heading?.focus({ preventScroll: true });
      previousPath.current = pathname;
    }

    return () => {
      cancelAnimationFrame(frame);
      cancelAnimationFrame(restoreFrame);
      window.clearTimeout(settleTimer);
    };
  }, [pathname]);

  return null;
}
