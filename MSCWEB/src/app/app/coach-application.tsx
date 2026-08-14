import { CoachApplicationFlow } from '@/features/coach/CoachApplicationComponents';
import { useAuth } from '@/shared/auth/AuthProvider';
import { AppShell } from '@/shared/navigation/AppShell';

export default function CoachApplicationRoute() {
  const { state } = useAuth();
  const authorized = state.status === 'authenticated' && state.account.role === 'participant';
  return (
    <AppShell role={authorized ? 'participant' : 'guest'} activeRoute="profile" title="Aplikasi Coach" subtitle="Akses tiga bulan · pembayaran manual">
      <CoachApplicationFlow authorized={authorized} />
    </AppShell>
  );
}
