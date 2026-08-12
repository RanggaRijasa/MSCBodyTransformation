import type { Metadata } from "next";

import { loadAdminProgramOperation } from "@/application/admin/load-admin-experience";
import { requireRole } from "@/features/auth/server/session-routing";
import { AdminProgramEditor } from "@/features/admin/components/admin-program-editor";
import { StateMessage } from "@/shared/ui";

export const metadata: Metadata = { title: "Edit draft program" };

export default async function AdminProgramEditPage({
  params,
}: Readonly<{ params: Promise<{ programId: string }> }>) {
  const { programId } = await params;
  await requireRole("admin", `/admin/program/${programId}/edit`);
  const program = await loadAdminProgramOperation(programId);
  if (!program.isSuccess || program.value.status !== "draft")
    return (
      <StateMessage
        description="Hanya draft yang dapat diedit."
        title="Editor tidak tersedia"
        tone="error"
      />
    );
  return <AdminProgramEditor initialDraft={program.value} />;
}
