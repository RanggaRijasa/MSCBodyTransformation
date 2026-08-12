import { router } from 'expo-router';
import type { ReactNode } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import type { PublicCoach, PublicLeaderboardRow, PublicProgram, PublicWinner } from './public-models';
import { dateFormatter, numberFormatter, percentFormatter } from '@/shared/design/formatters';
import { primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { MSCIcon } from '@/shared/icons/MSCIcon';
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
  const end = program.ends_on ? dateFormatter.format(new Date(`${program.ends_on}T12:00:00Z`)) : 'Tanggal selesai menyesuaikan program';
  return (
    <Pressable accessibilityRole="link" onPress={() => router.push(`/app/programs/${program.id}` as never)}>
      <Card>
        <View style={styles.rowBetween}>
          <StatusBadge label={programStatus(program.status)} tone={program.status === 'active' ? 'success' : 'info'} />
          <MSCIcon name="program" color={colors.primaryAction} />
        </View>
        <Text accessibilityRole="header" style={[styles.cardTitle, { color: colors.primaryText }]}>{program.title}</Text>
        <Text style={[styles.body, { color: colors.secondaryText }]}>{program.summary || 'Program transformasi dengan langkah harian yang terarah.'}</Text>
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
            <Text accessibilityRole="header" style={[styles.cardTitle, { color: colors.primaryText }]}>{coach.display_name}</Text>
            <Text style={[styles.body, { color: colors.secondaryText }]}>{coach.city || 'Lokasi belum dicantumkan'}</Text>
          </View>
        </View>
        {coach.biography ? <Text style={[styles.body, { color: colors.secondaryText }]}>{coach.biography}</Text> : null}
      </Card>
    </Pressable>
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

function programStatus(status: PublicProgram['status']): string {
  return ({ active: 'Aktif', scheduled: 'Segera hadir', completed: 'Selesai', archived: 'Arsip' })[status];
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
  stat: { flex: 1, minWidth: 140, padding: primitiveTokens.space.medium, borderRadius: primitiveTokens.radius.medium, gap: primitiveTokens.space.xxSmall },
  numeric: { ...typographyTokens.numericDisplay, fontVariant: ['tabular-nums'] },
});
