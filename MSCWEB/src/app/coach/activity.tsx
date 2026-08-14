import { CoachActivityScreen } from '@/features/coach/CoachActivityComponents';
import { useAuth } from '@/shared/auth/AuthProvider';
import { AppShell } from '@/shared/navigation/AppShell';

export default function CoachActivityRoute() {
  const { state } = useAuth();
  return <AppShell role="coach" activeRoute="dashboard" title="Aktivitas terbaru"><CoachActivityScreen authorized={state.status === 'authenticated' && state.account.role === 'coach'} /></AppShell>;
}
