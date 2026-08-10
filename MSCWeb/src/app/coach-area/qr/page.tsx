import type { Metadata } from "next";

import { loadCoachContextOperation } from "@/application/coach/load-coach-experience";
import { CoachQrPanel } from "@/features/device-media";
import { CoachAccessState } from "@/features/coach";
import { copy } from "@/shared/i18n/id";
import { StateMessage } from "@/shared/ui";

export const metadata: Metadata = { title: copy.shell.coach.qrTitle };

export default async function CoachQrPage() {
  const context = await loadCoachContextOperation();
  if (!context.isSuccess)
    return (
      <StateMessage
        description={context.error.message}
        title="QR Coach belum dapat dimuat"
        tone="error"
      />
    );
  return context.value.accessState === "active" ? (
    <CoachQrPanel coachName={context.value.displayName} />
  ) : (
    <CoachAccessState context={context.value} />
  );
}
