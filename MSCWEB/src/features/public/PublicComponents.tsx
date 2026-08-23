import { router } from 'expo-router';
import type { ReactNode } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';

import type { PublicCoach, PublicLeaderboardRow, PublicProgram, PublicWinner } from './public-models';
import { dateFormatter, numberFormatter, percentFormatter } from '@/shared/design/formatters';
import { primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { MSCIcon } from '@/shared/icons/MSCIcon';
import { effectiveProgramLifecycle, programStatusPresentation } from '@/shared/program/program-lifecycle';
import { Card, ProgressBar, StatusBadge, UserAvatar } from '@/shared/ui/primitives';

export function Section({ title, intro, children }: { title: string; intro?: string; children: ReactNode }) {
  const { colors } = useAppTheme();
  return (
    <View style={styles.section}>
      <View style={styles.sectionHeading}>
        <Text accessibilityRole="header" style={[styles.sectionTitle, { color: colors.primaryText }]}>{title}</Text>
        {intro ? <Text style={[styles.body, { color: colors.secondaryText }]}>{intro}</Text> : null}
      </View>
      {children}
    </View>
  );
}

export function ProgramCard({ program }: { program: PublicProgram }) {
  const { colors } = useAppTheme();
  const lifecycle = effectiveProgramLifecycle(program);
  const status = programStatusPresentation(lifecycle);
  const end = program.ends_on ? dateFormatter.format(new Date(`${program.ends_on}T12:00:00Z`)) : 'Tanggal selesai menyesuaikan program';
  return (
    <Pressable accessibilityRole="link" onPress={() => router.push(`/app/programs/${program.id}` as never)}>
      <Card>
        <View style={styles.rowBetween}>
          <StatusBadge label={status.label} tone={status.tone} />
          <MSCIcon name="program" color={colors.primaryAction} />
        </View>
        <Text accessibilityRole="header" style={[styles.cardTitle, { color: colors.primaryText }]}>{program.title}</Text>
        <Text style={[styles.label, { color: colors.primaryText }]}>{program.program_days.length} hari · Selesai {end}</Text>
      </Card>
    </Pressable>
  );
}

export function CoachCard({ coach }: { coach: PublicCoach }) {
  const { colors } = useAppTheme();
  return (
    <Pressable accessibilityRole="link" onPress={() => router.push(`/app/coaches/${coach.id}` as never)}>
      <Card>
        <View style={styles.identityRow}>
          <UserAvatar uri={coach.photo_reference ?? undefined} label={coach.display_name} />
          <View style={styles.flexCopy}>
            {coach.is_verified ? <StatusBadge label="Coach terverifikasi" tone="success" /> : null}
            <Text accessibilityRole="header" style={[styles.cardTitle, { color: colors.primaryText }]}>{coach.display_name}</Text>
            <Text style={[styles.body, { color: colors.secondaryText }]}>
              {[coach.professional_headline, coach.city].filter(Boolean).join(' · ') || 'Lokasi belum dicantumkan'}
            </Text>
          </View>
        </View>
      </Card>
    </Pressable>
  );
}

export function LeaderboardTopFive({ rows, currentParticipantId }: { rows: PublicLeaderboardRow[]; currentParticipantId?: string }) {
  const { colors } = useAppTheme();
  const topFive = [...rows].sort((left, right) => left.rank - right.rank).slice(0, 5);
  return (
    <ScrollView
      horizontal
      accessibilityLabel="Lima peringkat teratas"
      showsHorizontalScrollIndicator={false}
      contentContainerStyle={styles.topFive}
    >
      {topFive.map((row) => {
        const rankColor = row.rank === 1
          ? colors.podiumGold
          : row.rank === 2
            ? colors.podiumSilver
            : row.rank === 3
              ? colors.podiumBronze
              : colors.border;
        const isCurrent = row.participant_id === currentParticipantId;
        return (
          <View key={row.id} style={styles.topFiveEntry} accessibilityLabel={`${row.participant_display_name}, peringkat ${row.rank}`}>
            {row.rank === 1 ? <MSCIcon name="crown" color={rankColor} size="small" weight="fill" /> : <View style={styles.topFiveCrownSpacer} />}
            <View style={[styles.topFiveAvatarRing, { borderColor: rankColor }]}>
              <UserAvatar uri={row.avatar_url ?? undefined} label={row.participant_display_name} size={56} />
            </View>
            <View style={[styles.topFiveRank, { backgroundColor: rankColor }]}>
              <Text style={[styles.topFiveRankText, { color: row.rank === 1 ? primitiveTokens.color.nearBlack : primitiveTokens.color.white }]}>{row.rank}</Text>
            </View>
            <Text numberOfLines={1} style={[styles.topFiveName, { color: colors.primaryText }]}>{row.participant_display_name}{isCurrent ? ' · Kamu' : ''}</Text>
            <Text style={[styles.caption, { color: colors.secondaryText }]}>{numberFormatter.format(row.total_points)} poin</Text>
          </View>
        );
      })}
    </ScrollView>
  );
}

export function RankingRow({ row, winner, isCurrent = false }: { row: PublicLeaderboardRow; winner?: PublicWinner; isCurrent?: boolean }) {
  const { colors } = useAppTheme();
  return (
    <View accessibilityLabel={isCurrent ? `${row.participant_display_name}, kamu` : undefined} style={isCurrent ? [styles.currentRanking, { borderColor: colors.primaryAction }] : undefined}>
      <Card>
        <View style={styles.rankingRow}>
          <View style={[styles.rank, { backgroundColor: row.rank <= 3 ? colors.accent : colors.secondaryBackground }]}>
            <Text style={[styles.rankText, { color: primitiveTokens.color.black }]}>{numberFormatter.format(row.rank)}</Text>
          </View>
          <View style={styles.flexCopy}>
            <Text style={[styles.cardTitle, { color: colors.primaryText }]}>{row.participant_display_name}{isCurrent ? ' · Kamu' : ''}</Text>
            <Text style={[styles.body, { color: colors.secondaryText }]}>{numberFormatter.format(row.total_points)} poin{winner ? ' · Pemenang resmi' : ''}</Text>
          </View>
        </View>
        <ProgressBar label={`Progres ${row.participant_display_name}`} value={row.progress_percentage / 100} />
      </Card>
    </View>
  );
}

export function CompactStat({ label, value }: { label: string; value: number }) {
  const { colors } = useAppTheme();
  return (
    <View style={[styles.stat, { backgroundColor: colors.secondaryBackground }]}>
      <Text style={[styles.numeric, { color: colors.primaryText }]}>{numberFormatter.format(value)}</Text>
      <Text style={[styles.label, { color: colors.secondaryText }]}>{label}</Text>
    </View>
  );
}

export function formatProgress(value: number): string {
  return percentFormatter.format(value / 100);
}

export const publicScreenStyles = StyleSheet.create({
  content: { width: '100%', maxWidth: 960, alignSelf: 'center', padding: primitiveTokens.space.large, gap: primitiveTokens.space.xLarge },
  grid: { flexDirection: 'row', flexWrap: 'wrap', gap: primitiveTokens.space.medium },
  gridItem: { flexGrow: 1, flexBasis: 280, minWidth: 0 },
  stack: { gap: primitiveTokens.space.medium },
  body: typographyTokens.body,
  cardTitle: typographyTokens.headline,
});

const styles = StyleSheet.create({
  section: { gap: primitiveTokens.space.medium },
  sectionHeading: { gap: primitiveTokens.space.xxSmall },
  sectionTitle: typographyTokens.title,
  cardTitle: typographyTokens.headline,
  body: typographyTokens.body,
  label: typographyTokens.label,
  rowBetween: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: primitiveTokens.space.small },
  identityRow: { flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.medium },
  rankingRow: { flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.medium },
  currentRanking: { borderWidth: 2, borderRadius: primitiveTokens.radius.large },
  flexCopy: { flex: 1, minWidth: 0, gap: primitiveTokens.space.xxSmall },
  rank: { width: 48, height: 48, borderRadius: primitiveTokens.radius.capsule, alignItems: 'center', justifyContent: 'center' },
  rankText: { ...typographyTokens.headline, fontVariant: ['tabular-nums'] },
  topFive: { gap: primitiveTokens.space.medium, paddingVertical: primitiveTokens.space.xSmall, paddingRight: primitiveTokens.space.large },
  topFiveEntry: { width: 92, alignItems: 'center', gap: primitiveTokens.space.xxSmall },
  topFiveCrownSpacer: { height: 18 },
  topFiveAvatarRing: { borderWidth: 3, borderRadius: primitiveTokens.radius.capsule, padding: 2 },
  topFiveRank: { minWidth: 28, height: 28, marginTop: -14, borderRadius: 14, alignItems: 'center', justifyContent: 'center', paddingHorizontal: primitiveTokens.space.xxSmall },
  topFiveRankText: { ...typographyTokens.label, fontVariant: ['tabular-nums'] },
  topFiveName: { ...typographyTokens.label, width: '100%', textAlign: 'center' },
  caption: typographyTokens.caption,
  stat: { flex: 1, minWidth: 140, padding: primitiveTokens.space.medium, borderRadius: primitiveTokens.radius.medium, gap: primitiveTokens.space.xxSmall },
  numeric: { ...typographyTokens.numericDisplay, fontVariant: ['tabular-nums'] },
});
