import { Redirect } from 'expo-router';

import { useAuth } from '@/shared/auth/AuthProvider';

export default function AppIndexRoute() {
  const { state } = useAuth();
  if (state.status === 'authenticated' && state.account.role === 'coach') return <Redirect href="/coach" />;
  if (state.status === 'authenticated' && state.account.role === 'admin') return <Redirect href="/admin" />;
  return <Redirect href="/app/home" />;
}
