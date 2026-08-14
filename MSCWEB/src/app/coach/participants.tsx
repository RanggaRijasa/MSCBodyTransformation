import { CoachParticipantDirectoryScreen } from '@/features/coach/CoachParticipantComponents';
import { useAuth } from '@/shared/auth/AuthProvider';
import { AppShell } from '@/shared/navigation/AppShell';

export default function CoachParticipantsRoute() {
  const { state } = useAuth();
  return <AppShell role="coach" activeRoute="dashboard" title="Peserta saya"><CoachParticipantDirectoryScreen authorized={state.status === 'authenticated' && state.account.role === 'coach'} /></AppShell>;
}
