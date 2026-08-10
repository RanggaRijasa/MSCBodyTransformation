import type { Metadata } from "next";

import { loadParticipantRankingOperation } from "@/application/participant/load-participant-experience";
import { ParticipantRanking } from "@/features/participant";
import { copy } from "@/shared/i18n/id";
import { StateMessage } from "@/shared/ui";

export const metadata: Metadata = { title: copy.shell.participant.rankingTitle };
export const dynamic = "force-dynamic";

export default async function RankingPage({
  searchParams,
}: Readonly<{ searchParams: Promise<{ page?: string; program?: string }> }>) {
  const { page, program } = await searchParams;
  const parsedPage = Number(page ?? "1");
  const result = await loadParticipantRankingOperation(program, parsedPage);
  return result.isSuccess ? (
    <ParticipantRanking {...result.value} />
  ) : (
    <StateMessage
      description="Periksa koneksi lalu muat ulang halaman ini."
      title="Papan peringkat belum dapat dimuat"
      tone="error"
    />
  );
}
