import { router, useLocalSearchParams } from 'expo-router';
import { useMemo, useState } from 'react';
import { Modal, Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';

import { useCoachLeaderboard, useCoachWorkspace } from '@/features/coach/coach-experience-queries';
import type { CoachLeaderboardEntry } from '@/features/coach/coach-experience-models';
import { useParticipantProfile } from '@/features/participant/participant-queries';
import type { PublicLeaderboardRow, PublicProgram } from '@/features/public/public-models';
import { useLeaderboard, usePrograms, useWinners } from '@/features/public/public-queries';
import { primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { useResponsiveLayout } from '@/shared/design/useResponsiveLayout';
import { MSCIcon } from '@/shared/icons/MSCIcon';
import { Button, StateView, UserAvatar } from '@/shared/ui/primitives';
import {
  isLeaderboardPending,
  leaderboardProgramState,
  readLeaderboardProgramId,
  saveLeaderboardProgramId,
  selectLeaderboardProgram,
  type LeaderboardProgramState,
} from './leaderboard-state';

type LeaderboardRole = 'participant' | 'coach';

type LeaderboardEntry = Readonly<{
  id: string;
  participantId: string;
  name: string;
  avatarUrl: string | null;
  rank: number;
  progress: number;
  totalPoints: number;
  assignedToCoach: boolean;
  stepPoints: number | null;
  weightPoints: number | null;
  adjustmentPoints: number | null;
}>;

export function ParticipantLeaderboardExperience({ enabled }: { enabled: boolean }) {
  const programs = usePrograms();
  const route = useLocalSearchParams<{ programId?: string }>();
  const [requestedProgramId, setRequestedProgramId] = useState<string | undefined>(() => route.programId ?? readLeaderboardProgramId());
  const selectedProgram = selectLeaderboardProgram(programs.data, requestedProgramId);
  const leaderboard = useLeaderboard(selectedProgram?.id);
  const winners = useWinners(selectedProgram?.id);
  const profile = useParticipantProfile(enabled);
  const entries = useMemo(
    () => (leaderboard.data ?? []).map(normalizePublicEntry),
    [leaderboard.data],
  );

  return (
    <LeaderboardSurface
      role="participant"
      programs={programs.data ?? []}
      selectedProgram={selectedProgram}
      entries={entries}
      currentParticipantId={profile.data?.public_profile_id}
      isPending={isLeaderboardPending({
        programsPending: programs.isPending,
        routedProgramRequested: false,
        routedProgramPending: false,
        selectedProgramId: selectedProgram?.id,
        leaderboardPending: leaderboard.isPending,
      })}
      isError={programs.isError || leaderboard.isError}
      isLocked={(winners.data?.length ?? 0) > 0}
      onSelectProgram={(programId) => {
        saveLeaderboardProgramId(programId);
        setRequestedProgramId(programId);
      }}
      onRetry={() => {
        void programs.refetch();
        void leaderboard.refetch();
      }}
    />
  );
}

export function CoachLeaderboardExperience({ authorized }: { authorized: boolean }) {
  const programs = usePrograms();
  const workspace = useCoachWorkspace(authorized);
  const route = useLocalSearchParams<{ programId?: string }>();
  const [requestedProgramId, setRequestedProgramId] = useState<string | undefined>(() => route.programId ?? readLeaderboardProgramId());
  const selectedProgram = selectLeaderboardProgram(
    programs.data,
    requestedProgramId,
    workspace.data?.programs.map((program) => program.program_id),
  );
  const leaderboard = useCoachLeaderboard(selectedProgram?.id, authorized);
  const winners = useWinners(selectedProgram?.id);

  if (!authorized) return <StateView kind="forbidden" />;

  return (
    <LeaderboardSurface
      role="coach"
      programs={programs.data ?? []}
      selectedProgram={selectedProgram}
      entries={leaderboard.data?.map(normalizeCoachEntry) ?? []}
      isPending={isLeaderboardPending({
        programsPending: programs.isPending,
        routedProgramRequested: false,
        routedProgramPending: false,
        prerequisitePending: workspace.isPending,
        selectedProgramId: selectedProgram?.id,
        leaderboardPending: leaderboard.isPending,
      })}
      isError={programs.isError || workspace.isError || leaderboard.isError}
      isLocked={(winners.data?.length ?? 0) > 0}
      onSelectProgram={(programId) => {
        saveLeaderboardProgramId(programId);
        setRequestedProgramId(programId);
      }}
      onRetry={() => {
        void programs.refetch();
        void workspace.refetch();
        void leaderboard.refetch();
      }}
    />
  );
}

function LeaderboardSurface({
  role,
  programs,
  selectedProgram,
  entries,
  currentParticipantId,
  isPending,
  isError,
  isLocked,
  onSelectProgram,
  onRetry,
}: {
  role: LeaderboardRole;
  programs: PublicProgram[];
  selectedProgram?: PublicProgram;
  entries: LeaderboardEntry[];
  currentParticipantId?: string;
  isPending: boolean;
  isError: boolean;
  isLocked: boolean;
  onSelectProgram: (programId: string) => void;
  onRetry: () => void;
}) {
  const { colors } = useAppTheme();
  const [programPicker, setProgramPicker] = useState<'all' | 'history'>();
  const [detailEntry, setDetailEntry] = useState<LeaderboardEntry>();
  const sortedEntries = useMemo(
    () => [...entries].sort((left, right) => left.rank - right.rank || right.totalPoints - left.totalPoints || left.name.localeCompare(right.name, 'id-ID')),
    [entries],
  );
  const podium = [2, 1, 3]
    .map((rank) => sortedEntries.find((entry) => entry.rank === rank))
    .filter((entry): entry is LeaderboardEntry => entry !== undefined);
  const remaining = sortedEntries.filter((entry) => entry.rank > 3);
  const currentOutsidePodium = remaining.find((entry) => entry.participantId === currentParticipantId);
  const remainingWithoutCurrent = currentOutsidePodium
    ? remaining.filter((entry) => entry.id !== currentOutsidePodium.id)
    : remaining;
  const completedPrograms = programs.filter((program) => program.status === 'completed' || program.status === 'archived');
  const tiedTotals = new Set(
    sortedEntries
      .filter((entry, index) => sortedEntries.some((candidate, candidateIndex) => candidateIndex !== index && candidate.totalPoints === entry.totalPoints))
      .map((entry) => entry.totalPoints),
  );

  if (isPending) return <StateView kind="loading" />;
  if (isError) return <StateView kind="error" action={<Button label="Coba lagi" onPress={onRetry} />} />;
  if (!selectedProgram) return <StateView kind="empty" />;

  const programState = leaderboardProgramState(selectedProgram);
  const statusPresentation = leaderboardStatusPresentation(programState, colors);

  const openDetails = role === 'coach'
    ? (entry: LeaderboardEntry) => {
        if (entry.assignedToCoach) setDetailEntry(entry);
      }
    : undefined;

  return (
    <>
      <ScrollView contentContainerStyle={styles.content} testID={`${role}.leaderboard`}>
        {role === 'coach' ? (
          <Button label="Kembali ke dashboard" tone="secondary" icon="back" onPress={() => router.replace('/coach')} />
        ) : null}

        <ProgramSummary program={selectedProgram} onPress={() => setProgramPicker('all')} />

        <View style={styles.statusRow}>
          <View style={[styles.statusPill, { backgroundColor: colors.secondaryBackground }]}>
            <MSCIcon name={statusPresentation.icon} color={statusPresentation.color} size="small" />
            <Text style={[styles.statusPillText, { color: statusPresentation.color }]}>
              {statusPresentation.label}
            </Text>
          </View>
          {completedPrograms.length > 0 ? (
            <Pressable
              accessibilityRole="button"
              accessibilityLabel="Riwayat peringkat"
              onPress={() => setProgramPicker('history')}
              style={({ pressed }) => [styles.historyButton, { backgroundColor: pressed ? colors.primaryTintSurface : colors.secondaryBackground }]}
            >
              <MSCIcon name="history" color={colors.primaryAction} size="small" />
              <Text style={[styles.historyText, { color: colors.primaryAction }]}>Riwayat</Text>
            </Pressable>
          ) : null}
        </View>

        <View style={styles.statusCopy}>
          <Text accessibilityRole="header" style={[styles.sectionTitle, { color: colors.primaryText }]}>
            {isLocked ? 'Hasil akhir' : statusPresentation.heading}
          </Text>
          <Text style={[styles.body, { color: colors.secondaryText }]}>
            {isLocked
              ? 'Peringkat program sudah dikunci.'
              : statusPresentation.description}
          </Text>
        </View>

        {sortedEntries.length === 0 ? <StateView kind="empty" /> : (
          <>
            <View accessibilityLabel="Podium juara" style={styles.podium} testID="leaderboard.podium">
              {podium.map((entry) => (
                <PodiumEntry
                  key={entry.id}
                  entry={entry}
                  marker={markerFor(entry, role, currentParticipantId)}
                  onPress={entry.assignedToCoach ? openDetails : undefined}
                  isTied={tiedTotals.has(entry.totalPoints)}
                />
              ))}
            </View>

            {currentOutsidePodium ? (
              <View style={styles.sectionStack}>
                <Text accessibilityRole="header" style={[styles.sectionTitle, { color: colors.primaryText }]}>Peringkatmu</Text>
                <LeaderboardRow entry={currentOutsidePodium} marker="Kamu" isHighlighted isTied={tiedTotals.has(currentOutsidePodium.totalPoints)} />
              </View>
            ) : null}

            {remainingWithoutCurrent.length > 0 ? (
              <View style={styles.sectionStack}>
                <Text accessibilityRole="header" style={[styles.sectionTitle, { color: colors.primaryText }]}>Peringkat lainnya</Text>
                <View style={styles.rows}>
                  {remainingWithoutCurrent.map((entry) => (
                    <LeaderboardRow
                      key={entry.id}
                      entry={entry}
                      marker={markerFor(entry, role, currentParticipantId)}
                      isHighlighted={entry.assignedToCoach}
                      isTied={tiedTotals.has(entry.totalPoints)}
                      onPress={entry.assignedToCoach ? openDetails : undefined}
                    />
                  ))}
                </View>
              </View>
            ) : null}

          </>
        )}
      </ScrollView>

      <ProgramPickerSheet
        visible={programPicker !== undefined}
        title={programPicker === 'history' ? 'Riwayat peringkat' : 'Pilih program'}
        programs={programPicker === 'history' ? completedPrograms : programs}
        selectedProgramId={selectedProgram.id}
        onClose={() => setProgramPicker(undefined)}
        onSelect={(programId) => {
          onSelectProgram(programId);
          setProgramPicker(undefined);
        }}
      />
      <ScoreDetailSheet entry={detailEntry} onClose={() => setDetailEntry(undefined)} />
    </>
  );
}

function ProgramSummary({ program, onPress }: { program: PublicProgram; onPress: () => void }) {
  const { colors } = useAppTheme();
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel="Ganti program leaderboard"
      onPress={onPress}
      style={({ pressed }) => [styles.programCard, { backgroundColor: pressed ? colors.secondaryBackground : colors.surface, borderColor: colors.border }]}
    >
      <View style={[styles.trophyBox, { backgroundColor: colors.podiumGoldSurface }]}>
        <MSCIcon name="trophy" color={colors.podiumGold} size="large" weight="fill" />
      </View>
      <View style={styles.flexCopy}>
        <Text style={[styles.caption, { color: colors.secondaryText }]}>Program</Text>
        <Text accessibilityRole="header" style={[styles.cardTitle, { color: colors.primaryText }]}>{program.title}</Text>
        <Text style={[styles.caption, { color: colors.secondaryText }]}>{formatProgramDate(program)}</Text>
      </View>
      <View style={styles.changeProgram}>
        <Text style={[styles.changeProgramText, { color: colors.primaryAction }]}>Ganti</Text>
        <MSCIcon name="chevron" color={colors.primaryAction} size="small" />
      </View>
    </Pressable>
  );
}

function PodiumEntry({ entry, marker, onPress, isTied }: { entry: LeaderboardEntry; marker?: string; onPress?: (entry: LeaderboardEntry) => void; isTied: boolean }) {
  const { colors } = useAppTheme();
  const isWinner = entry.rank === 1;
  const palette = podiumPalette(entry.rank, colors);
  const content = (
    <View style={[styles.podiumColumn, isWinner && styles.podiumColumnWinner]}>
      {isWinner ? <MSCIcon name="crown" color={palette.accent} size="medium" weight="fill" /> : <View style={styles.crownSpacer} />}
      <View style={[styles.podiumAvatarRing, { borderColor: palette.accent }]}>
        <UserAvatar uri={entry.avatarUrl ?? undefined} label={entry.name} size={isWinner ? 76 : 62} />
        <View style={[styles.rankMedallion, { backgroundColor: palette.accent }]}>
          <Text style={[styles.rankMedallionText, { color: entry.rank === 1 ? primitiveTokens.color.nearBlack : primitiveTokens.color.white }]}>{entry.rank}</Text>
        </View>
      </View>
      <View style={[styles.podiumBase, isWinner && styles.podiumBaseWinner, { backgroundColor: palette.surface, borderColor: palette.accent }]}>
        <Text numberOfLines={2} style={[styles.podiumName, { color: colors.primaryText }]}>{entry.name}</Text>
        <Text style={[styles.podiumPoints, { color: colors.primaryText }]}>{formatNumber(entry.totalPoints)}</Text>
        <Text style={[styles.caption, { color: colors.secondaryText }]}>poin</Text>
        {marker ? <Marker label={marker} /> : isTied ? <TieMarker /> : null}
      </View>
    </View>
  );
  if (!onPress) return content;
  return <Pressable accessibilityRole="button" accessibilityLabel={`Rincian poin ${entry.name}`} onPress={() => onPress(entry)} style={({ pressed }) => ({ opacity: pressed ? 0.72 : 1, transform: [{ scale: pressed ? 0.98 : 1 }] })}>{content}</Pressable>;
}

function LeaderboardRow({ entry, marker, isHighlighted = false, isTied, onPress }: { entry: LeaderboardEntry; marker?: string; isHighlighted?: boolean; isTied: boolean; onPress?: (entry: LeaderboardEntry) => void }) {
  const { colors } = useAppTheme();
  const content = (
    <View style={[styles.rankRow, { backgroundColor: isHighlighted ? colors.primaryTintSurface : colors.surface, borderColor: isHighlighted ? colors.primaryAction : colors.border }]}>
      <View style={[styles.rankCircle, { backgroundColor: colors.background }]}><Text style={[styles.rankNumber, { color: colors.primaryText }]}>{entry.rank}</Text></View>
      <UserAvatar uri={entry.avatarUrl ?? undefined} label={entry.name} size={48} />
      <View style={styles.flexCopy}>
        <Text numberOfLines={1} style={[styles.rowName, { color: colors.primaryText }]}>{entry.name}</Text>
        <Text style={[styles.rowProgress, { color: colors.secondaryText }]}>{Math.round(entry.progress)}%</Text>
        {marker ? <Marker label={marker} /> : isTied ? <TieMarker /> : null}
      </View>
      <View style={[styles.pointsCapsule, { backgroundColor: colors.background }]}>
        <Text style={[styles.rowPoints, { color: colors.primaryText }]}>{formatNumber(entry.totalPoints)}</Text>
        <Text style={[styles.caption, { color: colors.secondaryText }]}>poin</Text>
      </View>
    </View>
  );
  if (!onPress) return content;
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={`Rincian poin ${entry.name}`}
      onPress={() => onPress(entry)}
      style={({ pressed }) => ({ opacity: pressed ? 0.72 : 1, transform: [{ scale: pressed ? 0.985 : 1 }] })}
    >
      {content}
    </Pressable>
  );
}

function Marker({ label }: { label: string }) {
  const { colors } = useAppTheme();
  return <View style={styles.marker}><MSCIcon name="assigned" color={colors.primaryAction} size="small" /><Text style={[styles.markerText, { color: colors.primaryAction }]}>{label}</Text></View>;
}

function TieMarker() {
  const { colors } = useAppTheme();
  return <View style={styles.marker}><MSCIcon name="tie" color={colors.warning} size="small" /><Text style={[styles.markerText, { color: colors.warning }]}>Poin sama</Text></View>;
}

function ProgramPickerSheet({ visible, title, programs, selectedProgramId, onClose, onSelect }: { visible: boolean; title: string; programs: PublicProgram[]; selectedProgramId: string; onClose: () => void; onSelect: (programId: string) => void }) {
  const { colors } = useAppTheme();
  const layout = useResponsiveLayout();
  return (
    <Modal transparent visible={visible} animationType="slide" onRequestClose={onClose}>
      <View style={[styles.modalOverlay, { backgroundColor: colors.overlay }]}>
        <View accessibilityViewIsModal style={[styles.sheet, layout !== 'compact' && styles.sheetWide, { backgroundColor: colors.background, borderColor: colors.border }]}>
          <View style={styles.sheetHeader}>
            <Button label="Tutup" tone="secondary" onPress={onClose} />
            <Text accessibilityRole="header" style={[styles.sheetTitle, { color: colors.primaryText }]}>{title}</Text>
          </View>
          <ScrollView contentContainerStyle={styles.sheetList}>
            {programs.length === 0 ? <StateView kind="empty" /> : programs.map((program) => (
              <Pressable
                key={program.id}
                accessibilityRole="radio"
                accessibilityState={{ checked: program.id === selectedProgramId }}
                onPress={() => onSelect(program.id)}
                style={({ pressed }) => [styles.historyRow, { backgroundColor: pressed ? colors.secondaryBackground : colors.surface, borderColor: colors.border }]}
              >
                <View style={[styles.historyIcon, { backgroundColor: colors.podiumGoldSurface }]}><MSCIcon name="trophy" color={colors.podiumGold} /></View>
                <View style={styles.flexCopy}><Text style={[styles.rowName, { color: colors.primaryText }]}>{program.title}</Text><Text style={[styles.caption, { color: colors.secondaryText }]}>{formatProgramDate(program)}</Text></View>
                {program.id === selectedProgramId ? <MSCIcon name="approved" color={colors.primaryAction} /> : null}
              </Pressable>
            ))}
          </ScrollView>
        </View>
      </View>
    </Modal>
  );
}

function ScoreDetailSheet({ entry, onClose }: { entry?: LeaderboardEntry; onClose: () => void }) {
  const { colors } = useAppTheme();
  const layout = useResponsiveLayout();
  return (
    <Modal transparent visible={entry !== undefined} animationType="slide" onRequestClose={onClose}>
      <View style={[styles.modalOverlay, { backgroundColor: colors.overlay }]}>
        <View accessibilityViewIsModal style={[styles.sheet, layout !== 'compact' && styles.sheetWide, { backgroundColor: colors.background, borderColor: colors.border }]}>
          <View style={styles.sheetHeader}><Button label="Tutup" tone="secondary" onPress={onClose} /><Text accessibilityRole="header" style={[styles.sheetTitle, { color: colors.primaryText }]}>Rincian poin</Text></View>
          {entry ? (
            <ScrollView contentContainerStyle={styles.detailContent}>
              <View style={[styles.detailIdentity, { backgroundColor: colors.surface, borderColor: colors.border }]}>
                <UserAvatar uri={entry.avatarUrl ?? undefined} label={entry.name} size={76} />
                <Text style={[styles.detailName, { color: colors.primaryText }]}>{entry.name}</Text>
                <DetailLine label="Peringkat" value={String(entry.rank)} />
                <DetailLine label="Total poin" value={formatNumber(entry.totalPoints)} />
              </View>
              <Text accessibilityRole="header" style={[styles.sectionTitle, { color: colors.secondaryText }]}>Rincian poin</Text>
              <View style={[styles.detailCard, { backgroundColor: colors.surface, borderColor: colors.border }]}>
                <DetailLine label="Poin langkah" value={formatNumber(entry.stepPoints ?? 0)} />
                <DetailLine label="Poin penurunan berat badan" value={formatNumber(entry.weightPoints ?? 0)} />
                <DetailLine label="Penyesuaian" value={formatNumber(entry.adjustmentPoints ?? 0)} />
                <DetailLine label="Progres" value={`${Math.round(entry.progress)}%`} last />
              </View>
            </ScrollView>
          ) : null}
        </View>
      </View>
    </Modal>
  );
}

function DetailLine({ label, value, last = false }: { label: string; value: string; last?: boolean }) {
  const { colors } = useAppTheme();
  return <View style={[styles.detailLine, !last && { borderBottomColor: colors.border, borderBottomWidth: StyleSheet.hairlineWidth }]}><Text style={[styles.body, { color: colors.primaryText }]}>{label}</Text><Text style={[styles.detailValue, { color: colors.primaryText }]}>{value}</Text></View>;
}

function normalizePublicEntry(row: PublicLeaderboardRow): LeaderboardEntry {
  return { id: row.id, participantId: row.participant_id, name: row.participant_display_name, avatarUrl: row.avatar_url, rank: row.rank, progress: row.progress_percentage, totalPoints: row.total_points, assignedToCoach: false, stepPoints: null, weightPoints: null, adjustmentPoints: null };
}

function normalizeCoachEntry(row: CoachLeaderboardEntry): LeaderboardEntry {
  return { id: row.id, participantId: row.participant_id, name: row.participant_display_name, avatarUrl: row.avatar_url, rank: row.rank, progress: row.progress_percentage, totalPoints: row.total_points, assignedToCoach: row.is_assigned_to_coach, stepPoints: row.step_points, weightPoints: row.weight_points, adjustmentPoints: row.adjustment_points };
}

function markerFor(entry: LeaderboardEntry, role: LeaderboardRole, currentParticipantId?: string) {
  if (role === 'coach' && entry.assignedToCoach) return 'Pesertamu';
  if (entry.participantId === currentParticipantId) return 'Kamu';
  return undefined;
}

function leaderboardStatusPresentation(
  state: LeaderboardProgramState,
  colors: ReturnType<typeof useAppTheme>['colors'],
) {
  if (state === 'running') {
    return { label: 'Berlangsung', heading: 'Peringkat sementara', description: 'Urutan dapat berubah sampai program selesai.', icon: 'activity' as const, color: colors.info };
  }
  if (state === 'upcoming') {
    return { label: 'Akan datang', heading: 'Program belum dimulai', description: 'Peringkat akan diperbarui saat program berlangsung.', icon: 'program' as const, color: colors.info };
  }
  if (state === 'awaiting_completion') {
    return { label: 'Menunggu hasil', heading: 'Program berakhir', description: 'Peringkat menunggu penguncian hasil akhir.', icon: 'pending' as const, color: colors.warning };
  }
  return { label: 'Selesai', heading: 'Program selesai', description: 'Peringkat menunggu penguncian hasil akhir.', icon: 'approved' as const, color: colors.success };
}

function podiumPalette(rank: number, colors: ReturnType<typeof useAppTheme>['colors']) {
  if (rank === 1) return { accent: colors.podiumGold, surface: colors.podiumGoldSurface };
  if (rank === 2) return { accent: colors.podiumSilver, surface: colors.podiumSilverSurface };
  return { accent: colors.podiumBronze, surface: colors.podiumBronzeSurface };
}

function formatNumber(value: number) { return new Intl.NumberFormat('id-ID').format(value); }
function formatProgramDate(program: PublicProgram) {
  const formatter = new Intl.DateTimeFormat('id-ID', { day: 'numeric', month: 'short', year: 'numeric', timeZone: program.timezone });
  const start = formatter.format(new Date(`${program.starts_on}T12:00:00Z`));
  const end = program.ends_on ? formatter.format(new Date(`${program.ends_on}T12:00:00Z`)) : null;
  return end ? `${start} – ${end}` : start;
}

const styles = StyleSheet.create({
  content: { width: '100%', maxWidth: 720, alignSelf: 'center', padding: primitiveTokens.space.large, paddingBottom: 140, gap: primitiveTokens.space.large },
  programCard: { borderWidth: 1, borderRadius: primitiveTokens.radius.large, padding: primitiveTokens.space.medium, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.medium },
  trophyBox: { width: 58, height: 58, borderRadius: primitiveTokens.radius.medium, alignItems: 'center', justifyContent: 'center' },
  changeProgram: { minHeight: 44, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.xxSmall },
  changeProgramText: typographyTokens.label,
  flexCopy: { flex: 1, minWidth: 0, gap: primitiveTokens.space.xxSmall },
  caption: typographyTokens.caption,
  body: typographyTokens.body,
  cardTitle: typographyTokens.headline,
  sectionTitle: typographyTokens.headline,
  statusRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: primitiveTokens.space.small },
  statusPill: { minHeight: 38, borderRadius: primitiveTokens.radius.capsule, paddingHorizontal: primitiveTokens.space.small, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.xSmall },
  statusPillText: typographyTokens.label,
  historyButton: { minHeight: 44, borderRadius: primitiveTokens.radius.capsule, paddingHorizontal: primitiveTokens.space.medium, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.xSmall },
  historyText: typographyTokens.bodyStrong,
  statusCopy: { gap: primitiveTokens.space.xxSmall },
  podium: { minHeight: 300, flexDirection: 'row', alignItems: 'flex-end', justifyContent: 'center', gap: primitiveTokens.space.xSmall, paddingTop: primitiveTokens.space.small },
  podiumColumn: { flex: 1, maxWidth: 190, alignItems: 'center', justifyContent: 'flex-end' },
  podiumColumnWinner: { alignSelf: 'stretch', justifyContent: 'flex-start' },
  crownSpacer: { height: 30 },
  podiumAvatarRing: { borderWidth: 4, borderRadius: primitiveTokens.radius.capsule, padding: primitiveTokens.space.xxSmall, position: 'relative' },
  rankMedallion: { position: 'absolute', bottom: -16, alignSelf: 'center', minWidth: 36, height: 36, borderRadius: 18, alignItems: 'center', justifyContent: 'center', paddingHorizontal: 8 },
  rankMedallionText: { fontSize: 18, lineHeight: 22, fontWeight: '900', fontVariant: ['tabular-nums'] },
  podiumBase: { width: '100%', minHeight: 128, marginTop: 16, borderWidth: 1, borderRadius: primitiveTokens.radius.medium, paddingHorizontal: primitiveTokens.space.xSmall, paddingVertical: primitiveTokens.space.medium, alignItems: 'center', justifyContent: 'center', gap: 2 },
  podiumBaseWinner: { minHeight: 166 },
  podiumName: { ...typographyTokens.label, textAlign: 'center' },
  podiumPoints: { fontSize: 24, lineHeight: 29, fontWeight: '900', fontVariant: ['tabular-nums'] },
  sectionStack: { gap: primitiveTokens.space.small },
  rows: { gap: primitiveTokens.space.xSmall },
  rankRow: { minHeight: 82, borderWidth: 1, borderRadius: primitiveTokens.radius.large, padding: primitiveTokens.space.small, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.small },
  rankCircle: { width: 42, height: 42, borderRadius: 21, alignItems: 'center', justifyContent: 'center' },
  rankNumber: { fontSize: 18, lineHeight: 22, fontWeight: '800', fontVariant: ['tabular-nums'] },
  rowName: typographyTokens.bodyStrong,
  rowProgress: { ...typographyTokens.callout, fontVariant: ['tabular-nums'] },
  pointsCapsule: { minWidth: 76, minHeight: 58, borderRadius: primitiveTokens.radius.capsule, paddingHorizontal: primitiveTokens.space.small, alignItems: 'center', justifyContent: 'center' },
  rowPoints: { fontSize: 19, lineHeight: 23, fontWeight: '900', fontVariant: ['tabular-nums'] },
  marker: { flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.xxSmall },
  markerText: typographyTokens.caption,
  modalOverlay: { flex: 1, justifyContent: 'flex-end' },
  sheet: { width: '100%', maxHeight: '88%', minHeight: '58%', borderTopWidth: 1, borderTopLeftRadius: primitiveTokens.radius.prominent, borderTopRightRadius: primitiveTokens.radius.prominent, padding: primitiveTokens.space.large, gap: primitiveTokens.space.large },
  sheetWide: { width: 640, maxHeight: '82%', alignSelf: 'center', borderWidth: 1, borderBottomWidth: 0 },
  sheetHeader: { minHeight: 50, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.medium },
  sheetTitle: { ...typographyTokens.headline, flex: 1, textAlign: 'center', paddingRight: 86 },
  sheetList: { gap: primitiveTokens.space.xSmall, paddingBottom: primitiveTokens.space.large },
  historyRow: { minHeight: 78, borderWidth: 1, borderRadius: primitiveTokens.radius.large, padding: primitiveTokens.space.small, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.small },
  historyIcon: { width: 48, height: 48, borderRadius: primitiveTokens.radius.medium, alignItems: 'center', justifyContent: 'center' },
  detailContent: { gap: primitiveTokens.space.large, paddingBottom: primitiveTokens.space.xLarge },
  detailIdentity: { borderWidth: 1, borderRadius: primitiveTokens.radius.large, padding: primitiveTokens.space.large, alignItems: 'center', gap: primitiveTokens.space.small },
  detailName: typographyTokens.title,
  detailCard: { borderWidth: 1, borderRadius: primitiveTokens.radius.large, paddingHorizontal: primitiveTokens.space.large },
  detailLine: { width: '100%', minHeight: 58, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: primitiveTokens.space.medium },
  detailValue: { ...typographyTokens.bodyStrong, fontVariant: ['tabular-nums'] },
});
