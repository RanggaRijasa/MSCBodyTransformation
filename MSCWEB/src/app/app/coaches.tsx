import { ScrollView, View } from 'react-native';

import { CoachCard, publicScreenStyles, Section } from '@/features/public/PublicComponents';
import { useCoaches } from '@/features/public/public-queries';
import { useAuth } from '@/shared/auth/AuthProvider';
import { AppShell } from '@/shared/navigation/AppShell';
import { Button, StateView } from '@/shared/ui/primitives';

export default function PublicCoachesRoute() {
  const coaches = useCoaches();
  const { state } = useAuth();
  const role = state.status === 'authenticated' ? state.account.role : 'guest';
  return (
    <AppShell role={role} activeRoute="coaches" title="Coach" subtitle="Direktori profil publik">
      <ScrollView contentContainerStyle={publicScreenStyles.content}>
        <Section title="Temukan Coach">
          {coaches.isPending ? <StateView kind="loading" /> : coaches.isError ? <StateView kind="error" action={<Button label="Coba lagi" onPress={() => void coaches.refetch()} />} /> : coaches.data?.length ? <View style={publicScreenStyles.grid}>{coaches.data.map((coach) => <View key={coach.id} style={publicScreenStyles.gridItem}><CoachCard coach={coach} /></View>)}</View> : <StateView kind="empty" />}
        </Section>
      </ScrollView>
    </AppShell>
  );
}
