import type { Metadata } from "next";

import { loadCoachReviewsOperation } from "@/application/coach/load-coach-experience";
import { CoachReviewQueue } from "@/features/coach";
import { copy } from "@/shared/i18n/id";
import { StateMessage } from "@/shared/ui";

export const dynamic = "force-dynamic";
export const metadata: Metadata = { title: copy.shell.coach.reviewTitle };

export default async function CoachReviewPage({
  searchParams,
}: Readonly<{ searchParams: Promise<{ jenis?: string; program?: string; sejak?: string }> }>) {
  const query = await searchParams;
  const filters = {
    contentKind: query.jenis,
    programId: query.program,
    submittedSince: query.sejak ? new Date(query.sejak).toISOString() : undefined,
  };
  const result = await loadCoachReviewsOperation(filters);
  return result.isSuccess ? (
    <CoachReviewQueue {...result.value} filters={filters} />
  ) : (
    <StateMessage
      description={result.error.message}
      title="Antrean belum dapat dimuat"
      tone="error"
    />
  );
}
