import { AdminDashboardExperience } from '@/features/admin/AdminDashboardComponents';
import { useAuth } from '@/shared/auth/AuthProvider';
import { AppShell } from '@/shared/navigation/AppShell';

export default function AdminDashboardRoute() {
  const { state } = useAuth();
  const authorized = state.status === 'authenticated' && state.account.role === 'admin';
  return <AppShell role="admin" activeRoute="dashboard" title="Dashboard"><AdminDashboardExperience authorized={authorized} /></AppShell>;
}
