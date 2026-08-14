import { AdminCoachApplications } from '@/features/coach/AdminCoachApplicationComponents';
import { useAuth } from '@/shared/auth/AuthProvider';
import { AppShell } from '@/shared/navigation/AppShell';

export default function AdminPeopleRoute() {
  const { state } = useAuth();
  const authorized = state.status === 'authenticated' && state.account.role === 'admin';
  return <AppShell role="admin" activeRoute="people" title="Orang" subtitle="Aplikasi dan aktivasi Coach"><AdminCoachApplications authorized={authorized} /></AppShell>;
}
