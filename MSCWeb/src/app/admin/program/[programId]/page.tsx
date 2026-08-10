import type { Metadata } from "next";

import {
  loadAdminProgramClosureOperation,
  loadAdminProgramOperation,
} from "@/application/admin/load-admin-experience";
import { requireRole } from "@/features/auth/server/session-routing";
import { AdminProgramDetail } from "@/features/admin";
import { StateMessage } from "@/shared/ui";

export const metadata: Metadata = { title: "Detail program" };

export default async function AdminProgramDetailPage({
  params,
}: Readonly<{ params: Promise<{ programId: string }> }>) {
  const { programId } = await params;
  await requireRole("admin", `/admin/program/${programId}`);
  const [program, closure] = await Promise.all([
    loadAdminProgramOperation(programId),
    loadAdminProgramClosureOperation(programId),
  ]);
  return program.isSuccess && closure.isSuccess ? (
    <AdminProgramDetail closure={closure.value} draft={program.value} />
  ) : (
    <StateMessage
      description="Program tidak ditemukan atau tidak dapat diakses."
      title="Program tidak tersedia"
      tone="error"
    />
  );
}
