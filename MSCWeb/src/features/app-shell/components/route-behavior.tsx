"use client";

import { usePathname, useSearchParams } from "next/navigation";
import { useEffect, useRef } from "react";

import { mainContentId } from "@/features/app-shell/model/shell-constants";
import {
  clearShellRouteFocusRequest,
  currentBrowserRouteKey,
  readShellRouteFocusRequest,
  readShellRouteMarker,
  writeShellRouteMarker,
} from "@/shared/route-transition";

const scrollStoragePrefix = "msc-shell-scroll:";
const focusObserverDeadlineMilliseconds = 3_000;

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
  const searchParameters = useSearchParams();
  const routeKey = `${pathname}?${searchParameters.toString()}`;
  const previousRoute = useRef(routeKey);
  const routeHeading = useRef<HTMLElement | null>(null);

  useEffect(() => {
    const previousBehavior = history.scrollRestoration;
    history.scrollRestoration = "manual";
    const clearTemporaryHeadingTabIndex = (event: PointerEvent) => {
      if (!(event.target instanceof Element) || !event.target.closest("a[href]")) return;
      routeHeading.current?.removeAttribute("tabindex");
    };
    document.addEventListener("pointerdown", clearTemporaryHeadingTabIndex, true);

    return () => {
      writeShellRouteMarker(currentBrowserRouteKey());
      history.scrollRestoration = previousBehavior;
      document.removeEventListener("pointerdown", clearTemporaryHeadingTabIndex, true);
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

    const main = document.getElementById(mainContentId);
    let focusFrame = 0;
    let settleFocusFrame = 0;
    let verifyFocusFrame = 0;
    let settleVerifyFocusFrame = 0;
    let focusObserverDeadline = 0;
    let observer: MutationObserver | null = null;
    const storedRoute = readShellRouteMarker();
    const routeFocusRequested = readShellRouteFocusRequest(routeKey);
    const inMemoryRouteChanged = previousRoute.current !== routeKey;
    const routeChanged =
      routeFocusRequested ||
      inMemoryRouteChanged ||
      (storedRoute !== null && storedRoute !== routeKey);
    if (routeChanged && main) {
      const previousHeading = inMemoryRouteChanged
        ? (routeHeading.current ?? main.querySelector<HTMLElement>("h1"))
        : null;
      const previousHeadingText = previousHeading?.textContent;
      previousHeading?.removeAttribute("tabindex");
      const navigationTrigger = document.activeElement;
      let allowRequestedRouteFocus = routeFocusRequested;
      let lastFocusedHeading: HTMLElement | null = null;
      const findReadyHeading = () => {
        const currentMain = document.getElementById(mainContentId);
        const heading = currentMain?.querySelector<HTMLElement>("h1");
        if (!heading || heading.closest('[aria-busy="true"]')) return null;
        if (heading === previousHeading && heading.textContent === previousHeadingText) return null;
        return heading;
      };
      const finishFocusTransition = () => {
        cancelAnimationFrame(verifyFocusFrame);
        cancelAnimationFrame(settleVerifyFocusFrame);
        window.clearTimeout(focusObserverDeadline);
        observer?.disconnect();
        clearShellRouteFocusRequest(routeKey);
        writeShellRouteMarker(routeKey);
      };
      const focusHeading = (heading: HTMLElement) => {
        const active = document.activeElement;
        if (
          !allowRequestedRouteFocus &&
          ((!lastFocusedHeading && active !== document.body && active !== navigationTrigger) ||
            (lastFocusedHeading &&
              active !== document.body &&
              active !== lastFocusedHeading &&
              active !== navigationTrigger))
        ) {
          finishFocusTransition();
          return false;
        }
        heading.setAttribute("tabindex", "-1");
        heading.addEventListener("blur", () => heading.removeAttribute("tabindex"), {
          once: true,
        });
        heading.focus({ preventScroll: true });
        allowRequestedRouteFocus = false;
        lastFocusedHeading = heading;
        routeHeading.current = heading;
        return true;
      };
      const verifySettledFocus = (heading: HTMLElement) => {
        cancelAnimationFrame(verifyFocusFrame);
        cancelAnimationFrame(settleVerifyFocusFrame);
        verifyFocusFrame = requestAnimationFrame(() => {
          settleVerifyFocusFrame = requestAnimationFrame(() => {
            if (findReadyHeading() !== heading || !heading.isConnected) return;
            if (
              document.activeElement === document.body ||
              document.activeElement === navigationTrigger
            )
              focusHeading(heading);
            writeShellRouteMarker(routeKey);
          });
        });
      };
      observer = new MutationObserver(() => {
        const heading = findReadyHeading();
        if (!heading) return;
        if (heading !== lastFocusedHeading) {
          if (focusHeading(heading)) verifySettledFocus(heading);
        } else if (lastFocusedHeading) {
          verifySettledFocus(lastFocusedHeading);
        }
      });
      observer.observe(document.body, { childList: true, subtree: true });
      focusObserverDeadline = window.setTimeout(() => {
        const heading = findReadyHeading();
        if (heading) focusHeading(heading);
        finishFocusTransition();
      }, focusObserverDeadlineMilliseconds);
      focusFrame = requestAnimationFrame(() => {
        settleFocusFrame = requestAnimationFrame(() => {
          const heading = findReadyHeading();
          if (!heading || !focusHeading(heading)) return;
          verifySettledFocus(heading);
        });
      });
      previousRoute.current = routeKey;
    } else {
      writeShellRouteMarker(routeKey);
      if (!routeHeading.current?.isConnected) {
        routeHeading.current = main?.querySelector<HTMLElement>("h1") ?? null;
      }
    }

    return () => {
      cancelAnimationFrame(frame);
      cancelAnimationFrame(restoreFrame);
      cancelAnimationFrame(focusFrame);
      cancelAnimationFrame(settleFocusFrame);
      cancelAnimationFrame(verifyFocusFrame);
      cancelAnimationFrame(settleVerifyFocusFrame);
      window.clearTimeout(settleTimer);
      window.clearTimeout(focusObserverDeadline);
      observer?.disconnect();
    };
  }, [pathname, routeKey]);

  return null;
}
