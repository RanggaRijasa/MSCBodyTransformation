import type { Metadata } from "next";

import { loadCoachDirectoryOperation } from "@/application/participant/load-participant-experience";
import { CoachDirectory } from "@/features/participant";
import { copy } from "@/shared/i18n/id";
import { StateMessage } from "@/shared/ui";

export const metadata: Metadata = { title: copy.shell.participant.coachTitle };
export const dynamic = "force-dynamic";

export default async function CoachDirectoryPage() {
  const result = await loadCoachDirectoryOperation();
  return result.isSuccess ? (
    <CoachDirectory coaches={result.value} />
  ) : (
    <StateMessage
      description="Periksa koneksi lalu muat ulang halaman ini."
      title="Daftar Coach belum dapat dimuat"
      tone="error"
    />
  );
}
