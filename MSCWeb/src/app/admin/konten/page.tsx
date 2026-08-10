import type { Metadata } from "next";

import {
  listWinnerPostersOperation,
  listWinnerSnapshotsOperation,
} from "@/application/admin/load-admin-experience";
import { requireRole } from "@/features/auth/server/session-routing";
import { AdminContent } from "@/features/admin";
import { copy } from "@/shared/i18n/id";
import { StateMessage } from "@/shared/ui";

export const metadata: Metadata = { title: copy.shell.admin.contentTitle };

export default async function AdminContentPage() {
  await requireRole("admin", "/admin/konten");
  const [posters, snapshots] = await Promise.all([
    listWinnerPostersOperation(),
    listWinnerSnapshotsOperation(),
  ]);
  return posters.isSuccess && snapshots.isSuccess ? (
    <AdminContent posters={posters.value} snapshots={snapshots.value} />
  ) : (
    <StateMessage
      description="Galeri poster belum dapat dimuat. Coba lagi."
      title="Konten tidak tersedia"
      tone="error"
    />
  );
}
