import type { ReactNode } from "react";

import { AppShell } from "@/features/app-shell";

export default function CoachLayout({ children }: Readonly<{ children: ReactNode }>) {
  return (
    <AppShell kind="coach" label="Coach">
      {children}
    </AppShell>
  );
}
