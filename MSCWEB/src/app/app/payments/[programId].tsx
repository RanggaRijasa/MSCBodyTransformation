import { useLocalSearchParams } from 'expo-router';

import { ParticipantPaymentFlow } from '@/features/payment/ParticipantPaymentFlow';
import { useProgram } from '@/features/public/public-queries';
import { useAuth } from '@/shared/auth/AuthProvider';
import { AppShell } from '@/shared/navigation/AppShell';
import { Button, StateView } from '@/shared/ui/primitives';

export default function ParticipantPaymentRoute() {
  const params = useLocalSearchParams<{ programId?: string }>();
  const programId = typeof params.programId === 'string' ? params.programId : '';
  const { state } = useAuth();
  const program = useProgram(programId);
  const authorized = state.status === 'authenticated' && state.account.role === 'participant';

  return (
    <AppShell role={authorized ? 'participant' : 'guest'} activeRoute="programs" title="Pendaftaran program">
      {!authorized ? <StateView kind="forbidden" /> : program.isPending ? <StateView kind="loading" /> : program.isError ? <StateView kind="error" action={<Button label="Coba lagi" onPress={() => void program.refetch()} />} /> : program.data ? <ParticipantPaymentFlow program={program.data} /> : <StateView kind="empty" />}
    </AppShell>
  );
}
