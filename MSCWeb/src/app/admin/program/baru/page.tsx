import { randomUUID } from "node:crypto";

import type { Metadata } from "next";

import { createBlankProgramDraft } from "@/domain/admin/admin-program";
import { requireRole } from "@/features/auth/server/session-routing";
import { AdminProgramEditor } from "@/features/admin";

export const metadata: Metadata = { title: "Buat program" };

export default async function NewAdminProgramPage() {
  await requireRole("admin", "/admin/program/baru");
  const today = new Date().toISOString().slice(0, 10);
  return <AdminProgramEditor initialDraft={createBlankProgramDraft(randomUUID, today)} />;
}
