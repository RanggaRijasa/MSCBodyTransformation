"use client";

import { getInstallPresentation } from "@/features/pwa-install/model/install-presentation";
import type { InstallStateKind } from "@/features/pwa-install/model/install-state";
import { usePwaInstall } from "@/features/pwa-install/components/pwa-install-provider";
import { AppButton, AppLink, type ActionVariant } from "@/shared/ui";

type InstallCtaPresentationProperties = Readonly<{
  actorDestination: string;
  className?: string;
  kind: InstallStateKind;
  onGuidance: (trigger?: HTMLElement) => void;
  onPrompt: () => void;
  variant?: ActionVariant;
}>;

export function InstallCtaPresentation({
  actorDestination,
  className = "",
  kind,
  onGuidance,
  onPrompt,
  variant = "primary",
}: InstallCtaPresentationProperties) {
  const presentation = getInstallPresentation(kind);
  if (presentation.action === "navigate") {
    return (
      <AppLink className={className} href={actorDestination} variant={variant}>
        {presentation.label}
      </AppLink>
    );
  }

  return (
    <AppButton
      className={className}
      onClick={
        presentation.action === "prompt" ? onPrompt : (event) => onGuidance(event.currentTarget)
      }
      variant={variant}
    >
      {presentation.label}
    </AppButton>
  );
}

export function InstallCta({
  className = "",
  variant = "primary",
}: Readonly<{ className?: string; variant?: ActionVariant }>) {
  const { actorDestination, openInstruction, requestInstall, state } = usePwaInstall();
  return (
    <InstallCtaPresentation
      actorDestination={actorDestination}
      className={className}
      kind={state.kind}
      onGuidance={openInstruction}
      onPrompt={() => void requestInstall()}
      variant={variant}
    />
  );
}
