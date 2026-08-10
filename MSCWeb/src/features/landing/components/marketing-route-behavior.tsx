"use client";

import { useEffect } from "react";

function focusHashTarget(hash: string) {
  const identifier = decodeURIComponent(hash.replace(/^#/, ""));
  if (!identifier) return;
  requestAnimationFrame(() => document.getElementById(identifier)?.focus({ preventScroll: true }));
}

export function MarketingRouteBehavior() {
  useEffect(() => {
    const handleClick = (event: MouseEvent) => {
      const link = (event.target as Element | null)?.closest<HTMLAnchorElement>('a[href^="#"]');
      if (link?.hash) focusHashTarget(link.hash);
    };
    const handleHashChange = () => focusHashTarget(window.location.hash);
    document.addEventListener("click", handleClick);
    window.addEventListener("hashchange", handleHashChange);
    return () => {
      document.removeEventListener("click", handleClick);
      window.removeEventListener("hashchange", handleHashChange);
    };
  }, []);

  return null;
}
