import type { Metadata } from "next";

import { loadAdminDashboardOperation } from "@/application/admin/load-admin-experience";
import { requireRole } from "@/features/auth/server/session-routing";
import { AdminDashboard } from "@/features/admin/components/admin-dashboard";
import { copy } from "@/shared/i18n/id";
import { StateMessage } from "@/shared/ui";

export const metadata: Metadata = { title: copy.shell.admin.dashboardTitle };

export default async function AdminDashboardPage() {
  await requireRole("admin", "/admin");
  const snapshot = await loadAdminDashboardOperation();
  return snapshot.isSuccess ? (
    <AdminDashboard snapshot={snapshot.value} />
  ) : (
    <StateMessage
      description="Dashboard belum dapat dimuat. Coba lagi."
      title="Dashboard tidak tersedia"
      tone="error"
    />
  );
}
