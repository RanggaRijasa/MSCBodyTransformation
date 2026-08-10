import type { Metadata } from "next";

import { loadCoachParticipantDetailOperation } from "@/application/coach/load-coach-experience";
import { CoachParticipantDetailView } from "@/features/coach";
import { StateMessage } from "@/shared/ui";

export const dynamic = "force-dynamic";
export const metadata: Metadata = { title: "Detail Peserta" };

export default async function CoachParticipantPage({
  params,
  searchParams,
}: Readonly<{
  params: Promise<{ participantId: string }>;
  searchParams: Promise<{ program?: string }>;
}>) {
  const [{ participantId }, query] = await Promise.all([params, searchParams]);
  const result = await loadCoachParticipantDetailOperation(participantId, query.program);
  return result.isSuccess ? (
    <CoachParticipantDetailView detail={result.value} />
  ) : (
    <StateMessage
      description={result.error.message}
      title="Detail Peserta tidak tersedia"
      tone="error"
    />
  );
}
