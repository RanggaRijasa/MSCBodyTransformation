import type { Metadata } from "next";

import { loadCoachDashboardOperation } from "@/application/coach/load-coach-experience";
import { CoachDashboard } from "@/features/coach";
import { copy } from "@/shared/i18n/id";
import { StateMessage } from "@/shared/ui";

export const dynamic = "force-dynamic";
export const metadata: Metadata = { title: copy.shell.coach.dashboardTitle };

export default async function CoachDashboardPage() {
  const result = await loadCoachDashboardOperation();
  return result.isSuccess ? (
    <CoachDashboard {...result.value} />
  ) : (
    <StateMessage
      description={result.error.message}
      title="Dashboard Coach belum dapat dimuat"
      tone="error"
    />
  );
}
