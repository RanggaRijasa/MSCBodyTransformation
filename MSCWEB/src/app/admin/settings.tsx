import { AdminSettingsExperience } from '@/features/admin/AdminSettingsComponents';
import { useAuth } from '@/shared/auth/AuthProvider';
import { AppShell } from '@/shared/navigation/AppShell';

export default function AdminSettingsRoute() {
  const { state } = useAuth();
  const authorized = state.status === 'authenticated' && state.account.role === 'admin';
  return <AppShell role="admin" activeRoute="settings" title="Pengaturan"><AdminSettingsExperience authorized={authorized} /></AppShell>;
}
