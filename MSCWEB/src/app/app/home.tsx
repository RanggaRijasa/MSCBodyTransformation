import { router } from 'expo-router';
import { ScrollView, StyleSheet, Text, View } from 'react-native';

import { CoachCard, ProgramCard, publicScreenStyles, RankingRow, Section } from '@/features/public/PublicComponents';
import { useCoaches, useLeaderboard, usePrograms, useWinnerPosters, useWinners } from '@/features/public/public-queries';
import { useAuth } from '@/shared/auth/AuthProvider';
import { primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { AppShell } from '@/shared/navigation/AppShell';
import { Button, Card, InlineMessage, StateView } from '@/shared/ui/primitives';

export default function PublicHomeRoute() {
  const { colors } = useAppTheme();
  const { state } = useAuth();
  const programs = usePrograms();
  const coaches = useCoaches();
  const posters = useWinnerPosters();
  const featuredProgram = programs.data?.find((program) => program.status === 'active') ?? programs.data?.[0];
  const leaderboard = useLeaderboard(featuredProgram?.id);
  const winners = useWinners(featuredProgram?.id);

  return (
    <AppShell role={state.status === 'authenticated' ? state.account.role : 'guest'} activeRoute="home" title="Beranda" subtitle="Program transformasi yang terarah">
      <ScrollView contentContainerStyle={publicScreenStyles.content}>
        {state.status === 'guest' && state.notice === 'sessionExpired' ? (
          <InlineMessage title="Sesi berakhir" message="Masuk kembali untuk melanjutkan dengan aman." tone="warning" />
        ) : null}
        <Card>
          <Text accessibilityRole="header" style={[styles.heroTitle, { color: colors.primaryText }]}>Perubahan nyata dimulai dari langkah yang konsisten.</Text>
          <Text style={[styles.heroBody, { color: colors.secondaryText }]}>Ikuti program harian, catat progres, dan tumbuh bersama dukungan Coach MSC.</Text>
          <View style={styles.actionRow}>
            <Button label="Jelajahi program" onPress={() => router.push('/app/programs')} />
            {state.status !== 'authenticated' ? <Button label="Masuk" tone="secondary" onPress={() => router.push('/login?returnTo=/app/home')} /> : null}
          </View>
        </Card>

        <Section title="Program pilihan" intro="Hanya program yang sudah dipublikasikan yang tampil di area publik.">
          {programs.isPending ? <StateView kind="loading" /> : programs.isError ? <StateView kind="error" action={<Button label="Coba lagi" onPress={() => void programs.refetch()} />} /> : programs.data?.length ? (
            <View style={publicScreenStyles.grid}>{programs.data.slice(0, 3).map((program) => <View key={program.id} style={publicScreenStyles.gridItem}><ProgramCard program={program} /></View>)}</View>
          ) : <StateView kind="empty" />}
        </Section>

        <Section title="Fokusmu hari ini" intro="Masuk untuk melihat langkah pribadi, program yang diikuti, dan progresmu.">
          <Card>
            <Text style={[styles.cardTitle, { color: colors.primaryText }]}>{state.status === 'authenticated' ? 'Ringkasan akunmu siap' : 'Data pribadi tetap terlindungi'}</Text>
            <Text style={[styles.heroBody, { color: colors.secondaryText }]}>{state.status === 'authenticated' ? 'Buka Profil untuk melihat ringkasan akun yang berasal dari data terlindungi.' : 'Berat badan, bukti foto, pembayaran, dan hubungan Coach tidak dimuat selama kamu menjelajah sebagai Tamu.'}</Text>
            <Button label={state.status === 'authenticated' ? 'Buka Profil' : 'Masuk untuk melanjutkan'} onPress={() => router.push(state.status === 'authenticated' ? '/app/profile' : '/login?returnTo=/app/home')} />
          </Card>
        </Section>

        <Section title="Peringkat teratas" intro={featuredProgram ? featuredProgram.title : 'Peringkat publik program'}>
          {leaderboard.isPending && featuredProgram ? <StateView kind="loading" /> : leaderboard.isError ? <StateView kind="error" /> : leaderboard.data?.length ? (
            <View style={publicScreenStyles.stack}>{leaderboard.data.slice(0, 5).map((row) => <RankingRow key={row.id} row={row} winner={winners.data?.find((winner) => winner.participant_id === row.participant_id)} />)}</View>
          ) : <StateView kind="empty" />}
          <Button label="Lihat papan peringkat" tone="secondary" onPress={() => router.push('/app/leaderboard')} />
        </Section>

        {posters.data?.length ? <Section title="Cerita pemenang"><View style={publicScreenStyles.grid}>{posters.data.slice(0, 3).map((poster) => <View key={poster.id} style={publicScreenStyles.gridItem}><Card><Text style={[styles.cardTitle, { color: colors.primaryText }]}>{poster.title}</Text><Text style={[styles.heroBody, { color: colors.secondaryText }]}>{poster.body}</Text></Card></View>)}</View></Section> : null}

        <Section title="Coach publik" intro="Temukan Coach yang profilnya telah disetujui dan dipublikasikan.">
          {coaches.isPending ? <StateView kind="loading" /> : coaches.isError ? <StateView kind="error" /> : coaches.data?.length ? <View style={publicScreenStyles.grid}>{coaches.data.slice(0, 3).map((coach) => <View key={coach.id} style={publicScreenStyles.gridItem}><CoachCard coach={coach} /></View>)}</View> : <StateView kind="empty" />}
        </Section>
      </ScrollView>
    </AppShell>
  );
}

const styles = StyleSheet.create({
  heroTitle: typographyTokens.titleLarge,
  heroBody: typographyTokens.body,
  cardTitle: typographyTokens.headline,
  actionRow: { flexDirection: 'row', flexWrap: 'wrap', gap: primitiveTokens.space.small },
});
