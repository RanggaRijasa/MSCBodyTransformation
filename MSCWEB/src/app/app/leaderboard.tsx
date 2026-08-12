import { ScrollView, View } from 'react-native';

import { ProgramCard, publicScreenStyles, RankingRow, Section } from '@/features/public/PublicComponents';
import { useParticipantProfile } from '@/features/participant/participant-queries';
import { useLeaderboard, usePrograms, useWinners } from '@/features/public/public-queries';
import { useAuth } from '@/shared/auth/AuthProvider';
import { AppShell } from '@/shared/navigation/AppShell';
import { Button, InlineMessage, StateView } from '@/shared/ui/primitives';

export default function PublicLeaderboardRoute() {
  const programs = usePrograms();
  const selected = programs.data?.find((program) => program.status === 'active') ?? programs.data?.[0];
  const leaderboard = useLeaderboard(selected?.id);
  const winners = useWinners(selected?.id);
  const { state } = useAuth();
  const role = state.status === 'authenticated' ? state.account.role : 'guest';
  const profile = useParticipantProfile(role === 'participant');

  return (
    <AppShell role={role} activeRoute="leaderboard" title="Peringkat" subtitle={selected?.title ?? 'Hasil program publik'}>
      <ScrollView contentContainerStyle={publicScreenStyles.content}>
        <InlineMessage title="Privasi peserta terjaga" message="Peringkat publik hanya menampilkan nama publik, progres, dan poin. Berat badan tidak pernah ditampilkan." />
        {programs.isPending ? <StateView kind="loading" /> : programs.isError ? <StateView kind="error" /> : !selected ? <StateView kind="empty" /> : (
          <>
            <Section title="Program terpilih"><ProgramCard program={selected} /></Section>
            <Section title="Papan peringkat" intro="Urutan menggunakan hasil publik yang diterbitkan program.">
              {leaderboard.isPending ? <StateView kind="loading" /> : leaderboard.isError ? <StateView kind="error" action={<Button label="Coba lagi" onPress={() => void leaderboard.refetch()} />} /> : leaderboard.data?.length ? <View style={publicScreenStyles.stack}>{leaderboard.data.map((row) => <RankingRow key={row.id} row={row} isCurrent={row.participant_id === profile.data?.public_profile_id} winner={winners.data?.find((winner) => winner.participant_id === row.participant_id)} />)}</View> : <StateView kind="empty" />}
            </Section>
          </>
        )}
      </ScrollView>
    </AppShell>
  );
}
