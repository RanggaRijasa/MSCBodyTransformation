"use client";

import { useEffect, useState } from "react";

import { InstallCta } from "@/features/pwa-install/components/install-cta";
import { usePwaInstall } from "@/features/pwa-install/components/pwa-install-provider";

export function StickyInstallBar() {
  const [isHeroActionVisible, setHeroActionVisible] = useState(true);
  const { isInstructionOpen } = usePwaInstall();

  useEffect(() => {
    const heroAction = document.querySelector("#hero-install-anchor");
    if (!heroAction || typeof IntersectionObserver === "undefined") return;
    const observer = new IntersectionObserver(
      ([entry]) => setHeroActionVisible(entry?.isIntersecting ?? true),
      { threshold: 0.2 },
    );
    observer.observe(heroAction);
    return () => observer.disconnect();
  }, []);

  return (
    <div
      aria-hidden={isHeroActionVisible || isInstructionOpen}
      className="sticky-install"
      data-visible={!isHeroActionVisible && !isInstructionOpen}
    >
      <InstallCta className="sticky-install__action" />
    </div>
  );
}
