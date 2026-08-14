import { CoachWorkspaceContent } from '@/features/coach/CoachWorkspaceComponents';
import { useAuth } from '@/shared/auth/AuthProvider';
import { AppShell } from '@/shared/navigation/AppShell';

export default function CoachQrRoute() {
  const { state } = useAuth();
  return <AppShell role="coach" activeRoute="dashboard" title="QR pendaftaran"><CoachWorkspaceContent authorized={state.status === 'authenticated' && state.account.role === 'coach'} screen="qr" /></AppShell>;
}
