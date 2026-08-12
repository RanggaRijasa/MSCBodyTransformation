import type { ReactNode } from "react";

import "@/shared/ui/styles/shells.css";
import "@/features/auth/styles/auth.css";
import "@/features/device-media/styles/device-media.css";
import "@/features/programs/styles/programs.css";
import "@/features/payments/styles/payments.css";
import "@/features/participant/styles/participant.css";
import "@/features/participant/styles/participant-home.css";
import "@/features/push/styles/push.css";
import { AppShell } from "@/features/app-shell";

export default function ParticipantLayout({ children }: Readonly<{ children: ReactNode }>) {
  return (
    <AppShell kind="participant" label="Peserta">
      {children}
    </AppShell>
  );
}
