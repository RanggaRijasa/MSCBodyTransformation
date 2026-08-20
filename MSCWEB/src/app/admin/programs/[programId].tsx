import { useLocalSearchParams } from 'expo-router';

import { AdminProgramDetailExperience } from '@/features/admin/AdminProgramComponents';
import { useAuth } from '@/shared/auth/AuthProvider';
import { AppShell } from '@/shared/navigation/AppShell';

export default function AdminProgramDetailRoute() {
  const { state } = useAuth();
  const params = useLocalSearchParams<{ programId?: string; section?: string; dayId?: string; stepId?: string; questionId?: string }>();
  const programId = typeof params.programId === 'string' ? params.programId : '';
  const authorized = state.status === 'authenticated' && state.account.role === 'admin';
  return <AppShell role="admin" activeRoute="programs" title="Program" hideHeader><AdminProgramDetailExperience authorized={authorized} programId={programId} params={{
    section: typeof params.section === 'string' ? params.section : undefined,
    dayId: typeof params.dayId === 'string' ? params.dayId : undefined,
    stepId: typeof params.stepId === 'string' ? params.stepId : undefined,
    questionId: typeof params.questionId === 'string' ? params.questionId : undefined,
  }} /></AppShell>;
}
