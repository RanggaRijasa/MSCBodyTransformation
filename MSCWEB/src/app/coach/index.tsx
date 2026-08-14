import { CoachWorkspaceContent } from '@/features/coach/CoachWorkspaceComponents';
import { useAuth } from '@/shared/auth/AuthProvider';
import { AppShell } from '@/shared/navigation/AppShell';

export default function CoachDashboardRoute() {
  const { state } = useAuth();
  const authorized = state.status === 'authenticated' && state.account.role === 'coach';
  return <AppShell role="coach" activeRoute="dashboard" title="Dashboard"><CoachWorkspaceContent authorized={authorized} screen="dashboard" /></AppShell>;
}
