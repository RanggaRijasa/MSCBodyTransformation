import { CoachProfileEditor } from '@/features/coach/CoachProfileComponents';
import { useAuth } from '@/shared/auth/AuthProvider';
import { AppShell } from '@/shared/navigation/AppShell';

export default function CoachProfileRoute() {
  const { state } = useAuth();
  const authorized = state.status === 'authenticated' && state.account.role === 'coach';
  return <AppShell role="coach" activeRoute="profile" title="Profil" subtitle="Identitas, profil publik, dan privasi"><CoachProfileEditor authorized={authorized} /></AppShell>;
}
