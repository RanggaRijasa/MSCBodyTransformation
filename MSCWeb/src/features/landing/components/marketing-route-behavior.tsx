"use client";

import { useEffect } from "react";

function focusHashTarget(hash: string) {
  let identifier = "";
  try {
    identifier = decodeURIComponent(hash.replace(/^#/, ""));
  } catch {
    return;
  }
  if (!identifier) return;
  requestAnimationFrame(() => {
    const target = document.getElementById(identifier);
    if (!target) return;
    target.focus({ preventScroll: true });
    target.scrollIntoView({ block: "start" });
  });
}

export function MarketingRouteBehavior() {
  useEffect(() => {
    const handleClick = (event: MouseEvent) => {
      const link = (event.target as Element | null)?.closest<HTMLAnchorElement>('a[href^="#"]');
      if (!link?.hash) return;
      link.closest<HTMLDetailsElement>("details")?.removeAttribute("open");
      focusHashTarget(link.hash);
    };
    const handleHashChange = () => focusHashTarget(window.location.hash);
    document.addEventListener("click", handleClick);
    window.addEventListener("hashchange", handleHashChange);
    focusHashTarget(window.location.hash);
    return () => {
      document.removeEventListener("click", handleClick);
      window.removeEventListener("hashchange", handleHashChange);
    };
  }, []);

  return null;
}
