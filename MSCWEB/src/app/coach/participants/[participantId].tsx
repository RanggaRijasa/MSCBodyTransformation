import { useLocalSearchParams } from 'expo-router';

import { CoachParticipantDetailScreen } from '@/features/coach/CoachParticipantComponents';
import { useAuth } from '@/shared/auth/AuthProvider';
import { AppShell } from '@/shared/navigation/AppShell';

export default function CoachParticipantDetailRoute() {
  const params = useLocalSearchParams<{ participantId: string; enrollment?: string }>();
  const { state } = useAuth();
  return (
    <AppShell role="coach" activeRoute="dashboard" title="Detail peserta">
      <CoachParticipantDetailScreen
        participantId={params.participantId ?? ''}
        enrollmentId={params.enrollment}
        authorized={state.status === 'authenticated' && state.account.role === 'coach'}
      />
    </AppShell>
  );
}
