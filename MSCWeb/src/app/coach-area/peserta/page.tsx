import type { Metadata } from "next";

import { loadCoachRosterOperation } from "@/application/coach/load-coach-experience";
import { CoachRoster } from "@/features/coach";
import { copy } from "@/shared/i18n/id";
import { StateMessage } from "@/shared/ui";

export const dynamic = "force-dynamic";
export const metadata: Metadata = { title: copy.shell.coach.participantsTitle };

export default async function CoachParticipantsPage({
  searchParams,
}: Readonly<{
  searchParams: Promise<{ perhatian?: string; program?: string; q?: string; urut?: string }>;
}>) {
  const query = await searchParams;
  const filters = {
    attention: query.perhatian,
    programId: query.program,
    query: query.q,
    sort: query.urut,
  };
  const result = await loadCoachRosterOperation(filters);
  return result.isSuccess ? (
    <CoachRoster {...result.value} filters={filters} />
  ) : (
    <StateMessage
      description={result.error.message}
      title="Peserta saya belum dapat dimuat"
      tone="error"
    />
  );
}
