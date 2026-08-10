import type { Metadata } from "next";
import { notFound } from "next/navigation";

import { loadProgramDetailOperation } from "@/application/programs/load-program-catalog";
import { loadParticipantActivityOperation } from "@/application/participant/load-participant-experience";
import { ProgramDetail } from "@/features/programs";
import { ProgramActivity } from "@/features/participant";
import { StateMessage } from "@/shared/ui";

export const dynamic = "force-dynamic";
export const metadata: Metadata = { title: "Detail program" };

export default async function ProgramDetailPage({
  params,
}: Readonly<{ params: Promise<{ programId: string }> }>) {
  const { programId } = await params;
  const result = await loadProgramDetailOperation(programId);
  if (!result.isSuccess) {
    if (result.error.code === "validation_failed") notFound();
    return (
      <StateMessage
        description="Periksa koneksi lalu muat ulang halaman ini."
        title="Detail program belum dapat dimuat"
        tone="error"
      />
    );
  }
  if (result.value.mode === "activity") {
    const activity = await loadParticipantActivityOperation(programId);
    return activity.isSuccess ? (
      <ProgramActivity participantProgram={activity.value} />
    ) : (
      <StateMessage
        description="Periksa koneksi lalu muat ulang halaman ini."
        title="Aktivitas program belum dapat dimuat"
        tone="error"
      />
    );
  }
  return (
    <ProgramDetail
      actor={result.value.actor}
      mode={result.value.mode}
      now={new Date()}
      program={result.value.program}
    />
  );
}
