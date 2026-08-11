import type { InstallStateKind } from "@/features/pwa-install/model/install-state";
import { copy } from "@/shared/i18n/id";

export type InstallActionKind = "prompt" | "guidance" | "navigate";

export type InstallPresentation = Readonly<{
  action: InstallActionKind;
  label: string;
}>;

export function getInstallPresentation(kind: InstallStateKind): InstallPresentation {
  switch (kind) {
    case "prompt-ready":
      return { action: "prompt", label: copy.landing.install.install };
    case "ios-guidance":
      return { action: "guidance", label: copy.landing.install.iosGuidance };
    case "manual-guidance":
      return { action: "guidance", label: copy.landing.install.manualGuidance };
    case "standalone":
      return { action: "navigate", label: copy.landing.install.openApp };
    case "dismissed":
    case "unsupported":
    case "not-ready":
      return { action: "navigate", label: copy.landing.install.useBrowser };
  }
}
