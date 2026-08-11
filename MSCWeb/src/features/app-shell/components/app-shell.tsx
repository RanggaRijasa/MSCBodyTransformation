import type { ReactNode } from "react";

import { navigationByKind, type ShellKind } from "@/features/app-shell/model/navigation-items";
import { RouteBehavior } from "@/features/app-shell/components/route-behavior";
import { mainContentId } from "@/features/app-shell/model/shell-constants";
import { ShellNavigation } from "@/features/app-shell/components/shell-navigation";
import { copy } from "@/shared/i18n/id";

type AppShellProperties = Readonly<{
  children: ReactNode;
  kind: ShellKind;
  label: string;
}>;

const navigationLabels: Readonly<Record<ShellKind, string>> = {
  participant: copy.shell.participantLabel,
  coach: copy.shell.coachLabel,
  admin: copy.shell.adminLabel,
};

export function AppShell({ children, kind, label }: AppShellProperties) {
  return (
    <div className={`app-shell app-shell--${kind}`}>
      <a className="skip-link" href={`#${mainContentId}`}>
        {copy.navigation.skipToContent}
      </a>
      <aside className="app-shell__sidebar">
        <div className="app-shell__brand" aria-label="MSC Body Transformation">
          <span aria-hidden="true">MSC</span>
          <div>
            <strong>Body Transformation</strong>
            <small>{label}</small>
          </div>
        </div>
        <ShellNavigation
          items={navigationByKind[kind]}
          kind={kind}
          label={navigationLabels[kind]}
        />
      </aside>
      <main id={mainContentId}>{children}</main>
      {kind === "admin" ? null : (
        <ShellNavigation
          items={navigationByKind[kind]}
          kind={kind}
          label={navigationLabels[kind]}
        />
      )}
      <RouteBehavior />
    </div>
  );
}
