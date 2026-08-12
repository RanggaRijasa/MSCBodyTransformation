import type { ReactNode } from "react";

import "@/shared/ui/styles/shells.css";
import "@/features/auth/styles/auth.css";
import "@/features/device-media/styles/device-media.css";
import "@/features/coach/styles/coach.css";
import "@/features/coach/styles/coach-dashboard-and-program.css";
import "@/features/push/styles/push.css";
import { AppShell } from "@/features/app-shell";

export default function CoachLayout({ children }: Readonly<{ children: ReactNode }>) {
  return (
    <AppShell kind="coach" label="Coach">
      {children}
    </AppShell>
  );
}
