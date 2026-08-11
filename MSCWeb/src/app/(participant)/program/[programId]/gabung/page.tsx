import type { Metadata } from "next";
import { notFound, redirect } from "next/navigation";

import { revalidatePendingProgramIntent } from "@/application/auth/pending-program-intent";
import { loadEnrollmentAvailabilityOperation } from "@/application/programs/program-enrollment-operations";
import { loadProgramDetailOperation } from "@/application/programs/load-program-catalog";
import { requireRole } from "@/features/auth/server/session-routing";
import { ProgramEnrollmentFlow } from "@/features/programs";
import { StateMessage } from "@/shared/ui";

export const dynamic = "force-dynamic";
export const metadata: Metadata = { title: "Daftar program" };

export default async function JoinProgramPage({
  params,
}: Readonly<{ params: Promise<{ programId: string }> }>) {
  const { programId } = await params;
  await requireRole("participant", `/program/${programId}/gabung`);
  await revalidatePendingProgramIntent(programId);
  const detail = await loadProgramDetailOperation(programId);
  if (!detail.isSuccess) {
    if (detail.error.code === "validation_failed") notFound();
    return (
      <StateMessage
        description="Periksa koneksi lalu coba lagi."
        title="Program belum dapat dimuat"
        tone="error"
      />
    );
  }
  if (detail.value.mode === "activity") redirect(`/program/${programId}`);
  const availability = await loadEnrollmentAvailabilityOperation(programId);
  if (!availability.isSuccess) {
    return (
      <StateMessage
        description={availability.error.message}
        title="Pendaftaran belum dapat diperiksa"
        tone="error"
      />
    );
  }
  return (
    <ProgramEnrollmentFlow
      availability={availability.value}
      pricingMode={detail.value.program.pricingMode}
      programId={programId}
      programTitle={detail.value.program.title}
    />
  );
}
