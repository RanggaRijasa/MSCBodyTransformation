import type { ReactNode } from "react";

import { AppShell } from "@/features/app-shell";

export default function AdminLayout({ children }: Readonly<{ children: ReactNode }>) {
  return (
    <AppShell kind="admin" label="Admin">
      {children}
    </AppShell>
  );
}
