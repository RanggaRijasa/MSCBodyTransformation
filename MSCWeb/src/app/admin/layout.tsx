import type { ReactNode } from "react";

import "@/shared/ui/styles/shells.css";
import "@/features/device-media/styles/device-media.css";
import "@/features/programs/styles/programs.css";
import "@/features/payments/styles/payments.css";
import "@/features/admin/styles/admin.css";
import "@/features/admin/styles/admin-dashboard.css";
import "@/features/admin/styles/admin-data.css";
import "@/features/admin/styles/admin-workflows.css";
import "@/features/push/styles/push.css";
import { AppShell } from "@/features/app-shell";

export default function AdminLayout({ children }: Readonly<{ children: ReactNode }>) {
  return (
    <AppShell kind="admin" label="Admin">
      {children}
    </AppShell>
  );
}
