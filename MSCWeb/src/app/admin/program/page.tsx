import type { Metadata } from "next";

import { listAdminProgramsOperation } from "@/application/admin/load-admin-experience";
import { requireRole } from "@/features/auth/server/session-routing";
import { AdminProgramList } from "@/features/admin";
import { copy } from "@/shared/i18n/id";
import { StateMessage } from "@/shared/ui";

export const metadata: Metadata = { title: copy.shell.admin.programTitle };

function first(value: string | string[] | undefined) {
  return Array.isArray(value) ? (value[0] ?? "") : (value ?? "");
}

export default async function AdminProgramsPage({
  searchParams,
}: Readonly<{ searchParams: Promise<Record<string, string | string[] | undefined>> }>) {
  await requireRole("admin", "/admin/program");
  const search = await searchParams;
  const pageValue = Number(first(search.halaman));
  const page = Number.isSafeInteger(pageValue) && pageValue > 0 ? pageValue : 1;
  const programs = await listAdminProgramsOperation();
  return programs.isSuccess ? (
    <AdminProgramList
      items={programs.value}
      page={page}
      query={first(search.q).slice(0, 80)}
      status={first(search.status)}
    />
  ) : (
    <StateMessage
      description="Daftar program belum dapat dimuat. Coba lagi."
      title="Program tidak tersedia"
      tone="error"
    />
  );
}
