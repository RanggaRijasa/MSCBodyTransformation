"use client";

import { useEffect, useState } from "react";

import { InstallCta } from "@/features/pwa-install/components/install-cta";
import { usePwaInstall } from "@/features/pwa-install/components/pwa-install-provider";

export function StickyInstallBar() {
  const [visibleRegions, setVisibleRegions] = useState({ callout: false, hero: true });
  const { isInstructionOpen } = usePwaInstall();

  useEffect(() => {
    const heroAction = document.querySelector("#hero-install-anchor");
    const calloutAction = document.querySelector("#install-callout-anchor");
    if (!heroAction || !calloutAction || typeof IntersectionObserver === "undefined") return;
    const observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          const region = entry.target === heroAction ? "hero" : "callout";
          setVisibleRegions((current) => ({ ...current, [region]: entry.isIntersecting }));
        }
      },
      { threshold: 0.2 },
    );
    observer.observe(heroAction);
    observer.observe(calloutAction);
    return () => observer.disconnect();
  }, []);

  const isInlineActionVisible = visibleRegions.hero || visibleRegions.callout;

  return (
    <div
      aria-hidden={isInlineActionVisible || isInstructionOpen}
      className="sticky-install"
      data-visible={!isInlineActionVisible && !isInstructionOpen}
    >
      <InstallCta className="sticky-install__action" />
    </div>
  );
}
