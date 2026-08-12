import { router } from 'expo-router';
import { useRef, useState } from 'react';
import { ScrollView, StyleSheet, Text, View } from 'react-native';

import { CoachCard, ProgramCard, publicScreenStyles, RankingRow, Section } from '@/features/public/PublicComponents';
import { useCoaches, useLeaderboard, usePrograms, useWinnerPosters, useWinners } from '@/features/public/public-queries';
import {
  useParticipantAssignedCoach,
  useParticipantDayAccess,
  useParticipantEnrollments,
  useParticipantProfile,
  useParticipantScores,
  useParticipantSubmissions,
} from '@/features/participant/participant-queries';
import { ParticipantRepositoryError } from '@/features/participant/participant-repository';
import { relevantDayAccess } from '@/features/participant/participant-program-policy';
import { useAuth } from '@/shared/auth/AuthProvider';
import { numberFormatter } from '@/shared/design/formatters';
import { primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { AppShell } from '@/shared/navigation/AppShell';
import { Button, Card, InlineMessage, ProgressBar, StateView, UserAvatar } from '@/shared/ui/primitives';

export default function PublicHomeRoute() {
  const { state } = useAuth();
  const role = state.status === 'authenticated' ? state.account.role : 'guest';
  return (
    <AppShell role={role} activeRoute="home" title="Beranda" subtitle={role === 'participant' ? undefined : 'Program transformasi yang terarah'}>
      {state.status === 'authenticated' && state.account.role === 'participant'
        ? <ParticipantHome />
        : <GuestHome />}
    </AppShell>
  );
}

function ParticipantHome() {
  const { colors } = useAppTheme();
  const programs = usePrograms();
  const enrollments = useParticipantEnrollments(true);
  const accesses = useParticipantDayAccess(true);
  const submissions = useParticipantSubmissions(true);
  const scores = useParticipantScores(true);
  const assignedCoach = useParticipantAssignedCoach(true);
  const profile = useParticipantProfile(true);
  const posters = useWinnerPosters();
  const joined = programs.data?.filter((program) => enrollments.data?.some((enrollment) => enrollment.program_id === program.id && ['active', 'pending', 'completed'].includes(enrollment.status))) ?? [];
  const activeProgram = joined.find((program) => enrollments.data?.some((enrollment) => enrollment.program_id === program.id && enrollment.status === 'active'));
  const activeEnrollment = enrollments.data?.find((enrollment) => enrollment.program_id === activeProgram?.id);
  const activeAccesses = accesses.data?.filter((access) => access.program_id === activeProgram?.id) ?? [];
  const focusAccess = relevantDayAccess(activeAccesses);
  const focusDay = activeProgram?.program_days.find((day) => day.id === focusAccess?.program_day_id);
  const activeScore = scores.data?.find((score) => score.enrollment_id === activeEnrollment?.id);
  const leaderboard = useLeaderboard(activeProgram?.id);
  const winners = useWinners(activeProgram?.id);
  const carousel = useRef<ScrollView>(null);
  const [carouselIndex, setCarouselIndex] = useState(0);
  const privateQueries = [profile, enrollments, accesses, submissions, scores, assignedCoach];
  const privateError = privateQueries.find((query) => query.error)?.error;

  if (privateQueries.some((query) => query.isPending) || programs.isPending) {
    return <ScrollView contentContainerStyle={publicScreenStyles.content}><StateView kind="loading" /></ScrollView>;
  }
  if (privateError || programs.isError) {
    const kind = privateError instanceof ParticipantRepositoryError ? privateError.failure : 'unknown';
    return (
      <ScrollView contentContainerStyle={publicScreenStyles.content}>
        <StateView
          kind={kind === 'offline' ? 'offline' : kind === 'forbidden' ? 'forbidden' : kind === 'sessionExpired' ? 'sessionExpired' : 'error'}
          action={<Button label="Coba lagi" onPress={() => void Promise.all(privateQueries.map((query) => query.refetch()))} />}
        />
      </ScrollView>
    );
  }

  return (
    <ScrollView contentContainerStyle={publicScreenStyles.content} testID="participant.home">
      <Card>
        <View style={styles.coachRow}>
          <UserAvatar uri={profile.data?.provider_avatar_url ?? undefined} label={profile.data?.display_name ?? 'Peserta MSC'} />
          <View style={styles.flexCopy}>
            <Text accessibilityRole="header" style={[styles.cardTitle, { color: colors.primaryText }]}>{profile.data?.display_name ?? 'Peserta MSC'}</Text>
            <Text style={[styles.body, { color: colors.secondaryText }]}>Peserta{profile.data?.city ? ` · ${profile.data.city}` : ''}</Text>
          </View>
        </View>
      </Card>
      <Section title="Program" intro={joined.length ? 'Program yang sedang kamu jalani.' : 'Pilih program untuk memulai perjalananmu.'}>
        {joined.length ? (
          <View style={styles.carouselGroup}>
            <ScrollView
              ref={carousel}
              horizontal
              accessibilityLabel="Program yang diikuti"
              showsHorizontalScrollIndicator={false}
              snapToInterval={304}
              decelerationRate="fast"
              contentContainerStyle={styles.carousel}
            >
              {joined.map((program) => <View key={program.id} style={styles.carouselCard}><ProgramCard program={program} /></View>)}
            </ScrollView>
            {joined.length > 1 ? (
              <View style={styles.carouselActions}>
                <Button label="Program sebelumnya" tone="secondary" disabled={carouselIndex === 0} onPress={() => {
                  const next = Math.max(0, carouselIndex - 1);
                  setCarouselIndex(next);
                  carousel.current?.scrollTo({ x: next * 304, animated: true });
                }} />
                <Text style={[styles.numericLabel, { color: colors.secondaryText }]}>{numberFormatter.format(carouselIndex + 1)} dari {numberFormatter.format(joined.length)}</Text>
                <Button label="Program berikutnya" tone="secondary" disabled={carouselIndex === joined.length - 1} onPress={() => {
                  const next = Math.min(joined.length - 1, carouselIndex + 1);
                  setCarouselIndex(next);
                  carousel.current?.scrollTo({ x: next * 304, animated: true });
                }} />
              </View>
            ) : null}
          </View>
        ) : <Card><Text style={[styles.cardTitle, { color: colors.primaryText }]}>Belum mengikuti program</Text><Text style={[styles.body, { color: colors.secondaryText }]}>Jelajahi program yang tersedia dan pilih yang sesuai dengan tujuanmu.</Text><Button label="Jelajahi program" onPress={() => router.push('/app/programs?segment=available')} /></Card>}
      </Section>

      <Section title="Fokus hari ini" intro={activeProgram?.title}>
        {activeProgram && activeEnrollment && focusDay && focusAccess ? (
          <Card>
            {activeScore ? <ProgressBar label="Progres program" value={activeScore.progress_percentage / 100} /> : null}
            <Text style={[styles.cardTitle, { color: colors.primaryText }]}>{focusAccess.is_current_day ? 'Hari ini · ' : ''}Hari ke-{numberFormatter.format(focusDay.day_number)}</Text>
            <Text style={[styles.body, { color: colors.secondaryText }]}>{focusDay.title}</Text>
            {focusAccess.access_state === 'locked'
              ? <InlineMessage title="Aktivitas belum tersedia" message="Kembali saat jadwal program membuka hari ini." tone="warning" />
              : <Button label="Lanjutkan" onPress={() => router.push(`/app/programs/${activeProgram.id}` as never)} />}
          </Card>
        ) : <StateView kind="empty" />}
      </Section>

      <Section title="Leaderboard Top 5" intro={activeProgram?.title ?? 'Program aktif'}>
        {leaderboard.isPending && activeProgram ? <StateView kind="loading" /> : leaderboard.data?.length ? (
          <View style={publicScreenStyles.stack}>{leaderboard.data.slice(0, 5).map((row) => <RankingRow key={row.id} row={row} isCurrent={row.participant_id === profile.data?.public_profile_id} winner={winners.data?.find((winner) => winner.participant_id === row.participant_id)} />)}</View>
        ) : <StateView kind="empty" />}
        <Button label="Lihat semua" tone="secondary" onPress={() => router.push('/app/leaderboard')} />
      </Section>

      <Section title="Pemenang terbaru">
        {posters.data?.length ? <View style={publicScreenStyles.grid}>{posters.data.slice(0, 2).map((poster) => <View key={poster.id} style={publicScreenStyles.gridItem}><Card><Text style={[styles.cardTitle, { color: colors.primaryText }]}>{poster.title}</Text><Text style={[styles.body, { color: colors.secondaryText }]}>{poster.body}</Text></Card></View>)}</View> : <StateView kind="empty" />}
      </Section>

      <Section title="Coach">
        {assignedCoach.data ? (
          <Card>
            <View style={styles.coachRow}>
              <UserAvatar uri={assignedCoach.data.provider_avatar_url ?? undefined} label={assignedCoach.data.display_name} />
              <View style={styles.flexCopy}>
                <Text style={[styles.cardTitle, { color: colors.primaryText }]}>{assignedCoach.data.display_name}</Text>
                <Text style={[styles.body, { color: colors.secondaryText }]}>{assignedCoach.data.city || 'Lokasi belum dicantumkan'} · Coach-mu</Text>
              </View>
            </View>
          </Card>
        ) : <InlineMessage title="Coach belum terhubung" message="Coach akan tampil setelah enrollment program aktif." />}
      </Section>
    </ScrollView>
  );
}

function GuestHome() {
  const { colors } = useAppTheme();
  const { state } = useAuth();
  const programs = usePrograms();
  const coaches = useCoaches();
  const featuredProgram = programs.data?.find((program) => program.status === 'active') ?? programs.data?.[0];
  const leaderboard = useLeaderboard(featuredProgram?.id);

  return (
    <ScrollView contentContainerStyle={publicScreenStyles.content}>
      {state.status === 'guest' && state.notice === 'sessionExpired' ? <InlineMessage title="Sesi berakhir" message="Masuk kembali untuk melanjutkan dengan aman." tone="warning" /> : null}
      <Card><Text accessibilityRole="header" style={[styles.heroTitle, { color: colors.primaryText }]}>Perubahan nyata dimulai dari langkah yang konsisten.</Text><Text style={[styles.body, { color: colors.secondaryText }]}>Ikuti program harian dan tumbuh bersama dukungan Coach MSC.</Text><Button label="Jelajahi program" onPress={() => router.push('/app/programs')} /></Card>
      <Section title="Program pilihan">{programs.data?.length ? <View style={publicScreenStyles.grid}>{programs.data.slice(0, 3).map((program) => <View key={program.id} style={publicScreenStyles.gridItem}><ProgramCard program={program} /></View>)}</View> : <StateView kind={programs.isPending ? 'loading' : 'empty'} />}</Section>
      <Section title="Fokusmu hari ini"><Card><Text style={[styles.cardTitle, { color: colors.primaryText }]}>Data pribadi tetap terlindungi</Text><Text style={[styles.body, { color: colors.secondaryText }]}>Masuk untuk melihat aktivitas dan progres pribadimu.</Text><Button label="Masuk untuk melanjutkan" onPress={() => router.push('/login?returnTo=/app/home')} /></Card></Section>
      <Section title="Peringkat teratas">{leaderboard.data?.length ? <View style={publicScreenStyles.stack}>{leaderboard.data.slice(0, 5).map((row) => <RankingRow key={row.id} row={row} />)}</View> : <StateView kind="empty" />}</Section>
      <Section title="Coach publik">{coaches.data?.length ? <View style={publicScreenStyles.grid}>{coaches.data.slice(0, 3).map((coach) => <View key={coach.id} style={publicScreenStyles.gridItem}><CoachCard coach={coach} /></View>)}</View> : <StateView kind="empty" />}</Section>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  heroTitle: typographyTokens.titleLarge,
  body: typographyTokens.body,
  cardTitle: typographyTokens.headline,
  numericLabel: { ...typographyTokens.label, fontVariant: ['tabular-nums'] },
  carouselGroup: { gap: primitiveTokens.space.small },
  carousel: { gap: primitiveTokens.space.medium, paddingRight: primitiveTokens.space.large },
  carouselCard: { width: 288 },
  carouselActions: { flexDirection: 'row', flexWrap: 'wrap', alignItems: 'center', justifyContent: 'space-between', gap: primitiveTokens.space.small },
  coachRow: { flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.medium },
  flexCopy: { flex: 1, minWidth: 0, gap: primitiveTokens.space.xxSmall },
});
