import type { Metadata } from "next";

import { loadCoachProgramHubOperation } from "@/application/coach/load-coach-experience";
import { CoachProgramHubView } from "@/features/coach";
import { copy } from "@/shared/i18n/id";
import { StateMessage } from "@/shared/ui";

export const dynamic = "force-dynamic";
export const metadata: Metadata = { title: copy.shell.coach.programTitle };

export default async function CoachProgramPage({
  searchParams,
}: Readonly<{ searchParams: Promise<{ program?: string; rentang?: string }> }>) {
  const query = await searchParams;
  const result = await loadCoachProgramHubOperation({
    programId: query.program,
    range: query.rentang,
  });
  return result.isSuccess ? (
    <CoachProgramHubView
      context={result.value.context}
      hub={result.value}
      range={result.value.range}
    />
  ) : (
    <StateMessage
      description={result.error.message}
      title="Program Coach belum dapat dimuat"
      tone="error"
    />
  );
}
