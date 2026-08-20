import { useLocalSearchParams } from 'expo-router';

import { AdminContentExperience } from '@/features/admin/AdminContentComponents';
import { useAuth } from '@/shared/auth/AuthProvider';
import { AppShell } from '@/shared/navigation/AppShell';

export default function AdminContentRoute() {
  const { state } = useAuth();
  const params = useLocalSearchParams<{ scope?: string; create?: string }>();
  const authorized = state.status === 'authenticated' && state.account.role === 'admin';
  return <AppShell role="admin" activeRoute="content" title="Konten"><AdminContentExperience authorized={authorized} initialScope={typeof params.scope === 'string' ? params.scope : 'posters'} createPoster={params.create === 'poster'} /></AppShell>;
}
