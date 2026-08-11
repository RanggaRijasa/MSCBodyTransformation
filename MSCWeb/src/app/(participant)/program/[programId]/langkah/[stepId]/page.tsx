import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";

import { loadParticipantStepOperation } from "@/application/participant/load-participant-experience";
import { ParticipantStepContent } from "@/features/participant/components/participant-step-content";
import { StatusBadge, Surface } from "@/shared/ui";

export const dynamic = "force-dynamic";
export const metadata: Metadata = { title: "Langkah program" };

export default async function ParticipantStepPage({
  params,
}: Readonly<{ params: Promise<{ programId: string; stepId: string }> }>) {
  const { programId, stepId } = await params;
  const result = await loadParticipantStepOperation(programId, stepId);
  if (!result.isSuccess) {
    if (result.error.code === "validation_failed") notFound();
    return (
      <Surface>
        <h1>Langkah belum tersedia</h1>
        <p>{result.error.message}</p>
        <Link href={`/program/${programId}`}>Kembali ke program</Link>
      </Surface>
    );
  }
  const { access, day, participantProgram, presentation, step } = result.value;
  const canEdit =
    access.accessState === "available" && !["approved", "pending"].includes(presentation.status);
  return (
    <article className="participant-step-page">
      <Link className="participant-step-page__back" href={`/program/${programId}`}>
        ← Kembali ke program
      </Link>
      <header>
        <p className="participant-eyebrow">
          {access.isCurrentDay ? "Hari ini" : `Hari ${day.dayNumber}`}
        </p>
        <h1>{step.title}</h1>
        <p>{day.title}</p>
        <StatusBadge
          tone={
            presentation.status === "approved"
              ? "success"
              : presentation.status === "pending"
                ? "warning"
                : presentation.status === "rejected"
                  ? "error"
                  : "info"
          }
        >
          {presentation.detail}
        </StatusBadge>
      </header>
      {canEdit ? (
        <ParticipantStepContent participantProgram={participantProgram} step={step} />
      ) : (
        <Surface>
          <h2>
            {access.accessState === "read_only"
              ? "Riwayat hanya dapat dilihat"
              : "Tidak ada tindakan"}
          </h2>
          <p>{presentation.detail}</p>
        </Surface>
      )}
    </article>
  );
}
