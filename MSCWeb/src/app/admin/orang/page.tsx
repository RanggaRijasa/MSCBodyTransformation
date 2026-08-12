import type { Metadata } from "next";

import {
  listAdminCorrectionTargetsOperation,
  listAdminPeopleOperation,
  listAdminProgramsOperation,
  listCoachApplicationsOperation,
} from "@/application/admin/load-admin-experience";
import type { AdminPerson } from "@/domain/admin/admin-operations";
import { requireRole } from "@/features/auth/server/session-routing";
import { AdminPeople } from "@/features/admin/components/admin-people";
import { copy } from "@/shared/i18n/id";
import { StateMessage } from "@/shared/ui";

export const metadata: Metadata = { title: copy.shell.admin.peopleTitle };

function first(value: string | string[] | undefined) {
  return Array.isArray(value) ? (value[0] ?? "") : (value ?? "");
}

export default async function AdminPeoplePage({
  searchParams,
}: Readonly<{ searchParams: Promise<Record<string, string | string[] | undefined>> }>) {
  await requireRole("admin", "/admin/orang");
  const searchValues = await searchParams;
  const roleValue = first(searchValues.peran);
  const role = ["admin", "coach", "participant"].includes(roleValue)
    ? (roleValue as AdminPerson["role"])
    : undefined;
  const search = first(searchValues.q).slice(0, 80);
  const [people, operationPeople, applications, programs, correctionTargets] = await Promise.all([
    listAdminPeopleOperation(role, search),
    listAdminPeopleOperation(),
    listCoachApplicationsOperation(),
    listAdminProgramsOperation(),
    listAdminCorrectionTargetsOperation(),
  ]);
  return people.isSuccess &&
    operationPeople.isSuccess &&
    applications.isSuccess &&
    programs.isSuccess &&
    correctionTargets.isSuccess ? (
    <AdminPeople
      applications={applications.value}
      correctionTargets={correctionTargets.value}
      operationPeople={operationPeople.value}
      people={people.value}
      programs={programs.value}
      role={role ?? ""}
      search={search}
    />
  ) : (
    <StateMessage
      description="Direktori belum dapat dimuat. Coba lagi."
      title="Data orang tidak tersedia"
      tone="error"
    />
  );
}
