import type { Metadata } from "next";

import { loadParticipantHomeOperation } from "@/application/participant/load-participant-experience";
import { ParticipantHome } from "@/features/participant";
import { copy } from "@/shared/i18n/id";
import { StateMessage } from "@/shared/ui";

export const metadata: Metadata = { title: copy.shell.participant.todayTitle };
export const dynamic = "force-dynamic";

export default async function TodayPage({
  searchParams,
}: Readonly<{ searchParams: Promise<{ program?: string }> }>) {
  const { program } = await searchParams;
  const result = await loadParticipantHomeOperation(program);
  if (!result.isSuccess) {
    return (
      <StateMessage
        description="Periksa koneksi lalu muat ulang. Tidak ada progres yang diubah."
        title="Beranda belum dapat dimuat"
        tone="error"
      />
    );
  }
  return <ParticipantHome {...result.value} />;
}
