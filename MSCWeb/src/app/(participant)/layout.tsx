import type { ReactNode } from "react";

import { AppShell } from "@/features/app-shell";

export default function ParticipantLayout({ children }: Readonly<{ children: ReactNode }>) {
  return (
    <AppShell kind="participant" label="Peserta">
      {children}
    </AppShell>
  );
}
