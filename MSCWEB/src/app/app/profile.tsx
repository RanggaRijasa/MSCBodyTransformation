import { router } from 'expo-router';
import { ScrollView, StyleSheet, Text, View } from 'react-native';

import { CompactStat, publicScreenStyles, Section } from '@/features/public/PublicComponents';
import { useParticipantProfile, useParticipantScores } from '@/features/participant/participant-queries';
import { useAuth } from '@/shared/auth/AuthProvider';
import { dateFormatter } from '@/shared/design/formatters';
import { primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { AppShell } from '@/shared/navigation/AppShell';
import { Button, Card, InlineMessage, StateView, StatusBadge, UserAvatar } from '@/shared/ui/primitives';

export default function PublicProfileRoute() {
  const { state, signOut } = useAuth();
  const { colors } = useAppTheme();
  const role = state.status === 'authenticated' ? state.account.role : 'guest';
  return (
    <AppShell role={role} activeRoute="profile" title="Profil" subtitle={state.status === 'authenticated' ? 'Ringkasan akun terlindungi' : 'Masuk untuk melihat akunmu'}>
      <ScrollView contentContainerStyle={publicScreenStyles.content}>
        {state.status === 'loading' ? <StateView kind="loading" /> : state.status === 'error' ? <StateView kind="error" action={<Button label="Masuk kembali" onPress={() => router.push('/login?returnTo=/app/profile')} />} /> : state.status === 'guest' ? (
          <Card>
            <UserAvatar label="Tamu" size={80} />
            <Text accessibilityRole="header" style={[styles.title, { color: colors.primaryText }]}>Jelajahi sebagai Tamu</Text>
            <Text style={[styles.body, { color: colors.secondaryText }]}>Masuk untuk melihat profil, program yang diikuti, bukti, dan progres pribadi. Data tersebut tidak dimuat dalam mode Tamu.</Text>
            <Button label="Masuk dengan Google" onPress={() => router.push('/login?returnTo=/app/profile')} />
            <InlineMessage title="Pendaftaran aman" message="Akun baru selalu dibuat sebagai Peserta. Coach dan Admin tidak dapat dipilih saat mendaftar." />
          </Card>
        ) : (
          <>
            {state.account.role === 'participant'
              ? <ParticipantIdentity />
              : <Card><View style={styles.identityRow}><UserAvatar label={state.account.email ?? 'Akun MSC'} size={80} /><View style={styles.copy}><StatusBadge label={state.account.role === 'coach' ? 'Coach' : 'Admin'} tone="success" /><Text accessibilityRole="header" style={[styles.title, { color: colors.primaryText }]}>{state.account.email ?? 'Akun MSC'}</Text></View></View></Card>}
            <Section title="Ringkasan akun">
              <View style={styles.stats}>
                <CompactStat label="Program aktif" value={state.account.activeEnrollmentCount} />
                <CompactStat label="Program selesai" value={state.account.completedEnrollmentCount} />
                {state.account.role === 'coach' ? <CompactStat label="Peserta ditangani" value={state.account.assignedParticipantCount} /> : null}
              </View>
            </Section>
            {state.account.role === 'participant' ? <ParticipantProgress /> : null}
            <Button label="Keluar" tone="destructive" onPress={() => void signOut()} />
          </>
        )}
      </ScrollView>
    </AppShell>
  );
}

function ParticipantIdentity() {
  const { colors } = useAppTheme();
  const profile = useParticipantProfile(true);
  if (profile.isPending) return <StateView kind="loading" />;
  if (profile.isError) return <StateView kind="error" action={<Button label="Coba lagi" onPress={() => void profile.refetch()} />} />;
  return (
    <Card>
      <View style={styles.identityRow}>
        <UserAvatar uri={profile.data?.provider_avatar_url ?? undefined} label={profile.data?.display_name ?? 'Peserta MSC'} size={80} />
        <View style={styles.copy}>
          <StatusBadge label="Peserta" tone="success" />
          <Text accessibilityRole="header" style={[styles.title, { color: colors.primaryText }]}>{profile.data?.display_name ?? 'Peserta MSC'}</Text>
          {profile.data?.city ? <Text style={[styles.body, { color: colors.secondaryText }]}>{profile.data.city}</Text> : null}
        </View>
      </View>
    </Card>
  );
}

function ParticipantProgress() {
  const { colors } = useAppTheme();
  const scores = useParticipantScores(true);
  if (scores.isPending) return <StateView kind="loading" />;
  if (scores.isError) return <StateView kind="error" action={<Button label="Coba lagi" onPress={() => void scores.refetch()} />} />;
  if (!scores.data?.length) return <Section title="Progres program"><StateView kind="empty" /></Section>;
  const ranks = scores.data.flatMap((score) => score.rank === null ? [] : [score.rank]);
  const recalculatedAt = scores.data[0]?.recalculated_at;
  return (
    <Section title="Progres program" intro="Nilai berikut berasal dari perhitungan server.">
      <View style={styles.stats}>
        <CompactStat label="Total poin" value={scores.data.reduce((total, score) => total + score.activity_points + score.quiz_points + score.weight_points + score.adjustment_points, 0)} />
        {ranks.length ? <CompactStat label="Peringkat terbaik" value={Math.min(...ranks)} /> : null}
      </View>
      {recalculatedAt ? <Text style={[styles.body, { color: colors.secondaryText }]}>Dihitung ulang {dateFormatter.format(new Date(recalculatedAt))}.</Text> : null}
    </Section>
  );
}

const styles = StyleSheet.create({ identityRow: { flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.medium }, copy: { flex: 1, gap: primitiveTokens.space.xSmall }, title: typographyTokens.title, body: typographyTokens.body, stats: { flexDirection: 'row', flexWrap: 'wrap', gap: primitiveTokens.space.medium } });
