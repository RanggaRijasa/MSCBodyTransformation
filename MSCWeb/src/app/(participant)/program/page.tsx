import type { Metadata } from "next";

import { loadProgramCatalogOperation } from "@/application/programs/load-program-catalog";
import { ProgramCatalog } from "@/features/programs";
import { copy } from "@/shared/i18n/id";
import { StateMessage } from "@/shared/ui";

export const dynamic = "force-dynamic";
export const metadata: Metadata = { title: copy.shell.participant.programTitle };

export default async function ProgramPage() {
  const now = new Date();
  const result = await loadProgramCatalogOperation(now);
  if (!result.isSuccess) {
    return (
      <div className="program-page">
        <header className="program-page__header">
          <p className="program-eyebrow">Program MSC</p>
          <h1>Program</h1>
        </header>
        <StateMessage
          description="Periksa koneksi lalu muat ulang halaman ini."
          title="Katalog belum dapat dimuat"
          tone="error"
        />
      </div>
    );
  }
  return (
    <ProgramCatalog
      isAuthenticatedParticipant={result.value.isAuthenticatedParticipant}
      now={now}
      sections={result.value.sections}
    />
  );
}
