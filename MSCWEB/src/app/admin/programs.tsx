import { AdminProgramsExperience } from '@/features/admin/AdminProgramComponents';
import { useAuth } from '@/shared/auth/AuthProvider';
import { AppShell } from '@/shared/navigation/AppShell';

export default function AdminProgramsRoute() {
  const { state } = useAuth();
  const authorized = state.status === 'authenticated' && state.account.role === 'admin';
  return <AppShell role="admin" activeRoute="programs" title="Program"><AdminProgramsExperience authorized={authorized} /></AppShell>;
}
