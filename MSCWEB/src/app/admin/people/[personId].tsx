import { useLocalSearchParams } from 'expo-router';

import { AdminPersonDetailExperience } from '@/features/admin/AdminPeopleComponents';
import { useAuth } from '@/shared/auth/AuthProvider';
import { AppShell } from '@/shared/navigation/AppShell';

export default function AdminPersonDetailRoute() {
  const { state } = useAuth();
  const params = useLocalSearchParams<{ personId?: string }>();
  const authorized = state.status === 'authenticated' && state.account.role === 'admin';
  return <AppShell role="admin" activeRoute="people" title="Detail orang"><AdminPersonDetailExperience authorized={authorized} personId={typeof params.personId === 'string' ? params.personId : ''} /></AppShell>;
}
