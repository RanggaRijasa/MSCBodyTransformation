import { useLocalSearchParams } from 'expo-router';

import { AdminPeopleExperience } from '@/features/admin/AdminPeopleComponents';
import { useAuth } from '@/shared/auth/AuthProvider';
import { AppShell } from '@/shared/navigation/AppShell';

export default function AdminPeopleRoute() {
  const { state } = useAuth();
  const params = useLocalSearchParams<{ scope?: string; pending?: string }>();
  const authorized = state.status === 'authenticated' && state.account.role === 'admin';
  const initialScope = typeof params.scope === 'string' ? params.scope : 'participant';
  const pendingOnly = params.pending === '1';
  return <AppShell role="admin" activeRoute="people" title="Orang"><AdminPeopleExperience key={`${initialScope}-${pendingOnly ? 'pending' : 'all'}`} authorized={authorized} initialScope={initialScope} pendingOnly={pendingOnly} /></AppShell>;
}
