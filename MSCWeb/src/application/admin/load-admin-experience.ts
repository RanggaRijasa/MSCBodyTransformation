import "server-only";

export {
  listAdminAudit as listAdminAuditOperation,
  listAdminCorrectionTargets as listAdminCorrectionTargetsOperation,
  listAdminPeople as listAdminPeopleOperation,
  listCoachApplications as listCoachApplicationsOperation,
  listWinnerPosters as listWinnerPostersOperation,
  listWinnerSnapshots as listWinnerSnapshotsOperation,
  loadAdminDashboard as loadAdminDashboardOperation,
} from "@/infrastructure/supabase/admin/admin-read-repository";
export { loadAdminProgramClosure as loadAdminProgramClosureOperation } from "@/infrastructure/supabase/admin/admin-closure-repository";
export {
  listAdminPrograms as listAdminProgramsOperation,
  loadAdminProgram as loadAdminProgramOperation,
} from "@/infrastructure/supabase/admin/admin-program-repository";
