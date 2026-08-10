import type { Metadata } from "next";

import { listAdminAuditOperation } from "@/application/admin/load-admin-experience";
import { requireRole } from "@/features/auth/server/session-routing";
import { AdminSettings } from "@/features/admin";
import { copy } from "@/shared/i18n/id";
import { StateMessage } from "@/shared/ui";

export const metadata: Metadata = { title: copy.shell.admin.settingsTitle };

export default async function AdminSettingsPage() {
  await requireRole("admin", "/admin/pengaturan");
  const audit = await listAdminAuditOperation();
  return audit.isSuccess ? (
    <AdminSettings
      audit={audit.value}
      environment={process.env.APP_ENVIRONMENT ?? "local"}
      siteUrl={process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000"}
    />
  ) : (
    <StateMessage
      description="Konfigurasi aman belum dapat dimuat."
      title="Pengaturan tidak tersedia"
      tone="error"
    />
  );
}
