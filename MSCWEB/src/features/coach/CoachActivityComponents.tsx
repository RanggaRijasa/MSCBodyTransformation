import { router } from 'expo-router';
import { useMemo, useState } from 'react';
import { Modal, Pressable, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';

import { useCoachActivityFeed } from './coach-experience-queries';
import type { CoachActivityFeed } from './coach-experience-models';
import { componentTokens, primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { useResponsiveLayout } from '@/shared/design/useResponsiveLayout';
import { MSCIcon, type MSCIconName } from '@/shared/icons/MSCIcon';
import { Button, Card, StateView, StatusBadge, UserAvatar } from '@/shared/ui/primitives';

type ActivityItem = CoachActivityFeed['items'][number];
type ActivityKind = 'all' | ActivityItem['kind'];
type TimeRange = 'today' | 'sevenDays' | 'thirtyDays';
type ActivityFilters = { programId: string | null; kind: ActivityKind; timeRange: TimeRange };

const displayTimeZone = 'Asia/Makassar';
const defaultFilters: ActivityFilters = { programId: null, kind: 'all', timeRange: 'today' };
const kindOptions: readonly { value: ActivityKind; label: string }[] = [
  { value: 'all', label: 'Semua aktivitas' },
  { value: 'evidence_submitted', label: 'Bukti dikirim' },
  { value: 'step_completed', label: 'Langkah selesai' },
  { value: 'participant_joined', label: 'Peserta bergabung' },
  { value: 'program_completed', label: 'Program selesai' },
];
const timeOptions: readonly { value: TimeRange; label: string }[] = [
  { value: 'today', label: 'Hari ini' },
  { value: 'sevenDays', label: '7 hari terakhir' },
  { value: 'thirtyDays', label: '30 hari terakhir' },
];

export function CoachActivityScreen({ authorized }: { authorized: boolean }) {
  const query = useCoachActivityFeed(authorized);
  if (!authorized) return <StateView kind="forbidden" />;
  if (query.isPending) return <StateView kind="loading" />;
  if (query.isError) return <StateView kind="error" action={<Button label="Coba lagi" onPress={() => void query.refetch()} />} />;
  if (!query.data) return <StateView kind="empty" />;
  return <ActivityFeed data={query.data} />;
}

function ActivityFeed({ data }: { data: CoachActivityFeed }) {
  const { colors } = useAppTheme();
  const [filters, setFilters] = useState(defaultFilters);
  const [filtersVisible, setFiltersVisible] = useState(false);
  const items = useMemo(() => data.items
    .filter((item) => filters.programId === null || item.program_id === filters.programId)
    .filter((item) => filters.kind === 'all' || item.kind === filters.kind)
    .filter((item) => matchesTimeRange(item.occurred_at, filters.timeRange))
    .sort((left, right) => new Date(right.occurred_at).getTime() - new Date(left.occurred_at).getTime()), [data.items, filters]);
  const groups = useMemo(() => groupByDay(items), [items]);
  const hasEarlierActivity = filters.timeRange === 'today' && data.items.some((item) =>
    (filters.programId === null || item.program_id === filters.programId)
      && (filters.kind === 'all' || item.kind === filters.kind)
      && localDateKey(item.occurred_at) < todayKey());

  return (
    <View style={styles.screen} testID="coach.activity">
      <View style={[styles.controls, { backgroundColor: colors.background }]}>
        <Button label="Kembali ke dashboard" tone="secondary" icon="back" onPress={() => router.replace('/coach')} />
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={`Filter aktivitas, ${filterSummary(filters, data)}`}
          onPress={() => setFiltersVisible(true)}
          style={({ hovered, pressed }) => [
            styles.filterSummary,
            {
              backgroundColor: pressed ? colors.secondaryBackground : colors.surface,
              borderColor: hovered ? colors.primaryAction : colors.border,
              transform: [{ scale: pressed ? 0.99 : 1 }],
            },
          ]}
        >
          <MSCIcon name="filter" color={colors.primaryText} />
          <View style={styles.flexCopy}>
            <Text style={[styles.cardTitle, { color: colors.primaryText }]}>Filter aktivitas</Text>
            <Text style={[styles.body, { color: colors.secondaryText }]}>{filterSummary(filters, data)}</Text>
          </View>
          <Text accessibilityElementsHidden style={[styles.chevron, { color: colors.secondaryText }]}>›</Text>
        </Pressable>
      </View>

      <ScrollView contentContainerStyle={styles.list}>
        {groups.length === 0 ? (
          <View style={styles.emptyWrap}>
            <StateView kind="empty" />
            <Text style={[styles.body, styles.centerText, { color: colors.secondaryText }]}>
              {filters.timeRange === 'today' ? 'Belum ada aktivitas hari ini.' : 'Tidak ada aktivitas yang cocok dengan filter.'}
            </Text>
            {hasEarlierActivity ? <Button label="Aktivitas sebelumnya" tone="secondary" onPress={() => setFilters((value) => ({ ...value, timeRange: 'thirtyDays' }))} /> : null}
          </View>
        ) : groups.map((group) => (
          <View key={group.key} style={styles.group}>
            <Text accessibilityRole="header" style={[styles.sectionTitle, { color: colors.primaryText }]}>{dateHeading(group.key)}</Text>
            <Card>
              {group.items.map((item, index) => <ActivityRow key={item.id} item={item} divider={index > 0} />)}
            </Card>
          </View>
        ))}
      </ScrollView>

      {filtersVisible ? (
        <ActivityFilterSheet
          data={data}
          selection={filters}
          onClose={() => setFiltersVisible(false)}
          onApply={(selection) => { setFilters(selection); setFiltersVisible(false); }}
        />
      ) : null}
    </View>
  );
}

function ActivityRow({ item, divider }: { item: ActivityItem; divider: boolean }) {
  const { colors } = useAppTheme();
  const presentation = activityPresentation(item);
  const open = () => item.requires_review
    ? router.push('/coach/reviews')
    : router.push(`/coach/participants/${item.participant_id}?enrollment=${item.enrollment_id}` as never);
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={`${item.participant_name}, ${presentation.copy}, ${presentation.badge ?? ''}`}
      onPress={open}
      style={({ pressed }) => [styles.activityRow, divider && { borderTopColor: colors.border, borderTopWidth: StyleSheet.hairlineWidth }, pressed && { backgroundColor: colors.secondaryBackground }]}
    >
      <UserAvatar uri={item.avatar_url ?? undefined} label={item.participant_name} size={56} />
      <View style={styles.flexCopy}>
        <Text style={[styles.cardTitle, { color: colors.primaryText }]}>{item.participant_name}</Text>
        <Text style={[styles.body, { color: colors.primaryText }]}>{presentation.copy}</Text>
        <Text style={[styles.body, { color: colors.secondaryText }]}>{relativeTime(item.occurred_at)}</Text>
        <View style={styles.activityMeta}>
          <MSCIcon name={presentation.icon} color={colors[presentation.color]} size="small" />
          {presentation.badge ? <StatusBadge label={presentation.badge} tone={presentation.tone} /> : null}
        </View>
      </View>
      <Text accessibilityElementsHidden style={[styles.chevron, { color: colors.secondaryText }]}>›</Text>
    </Pressable>
  );
}

function ActivityFilterSheet({ data, selection, onClose, onApply }: {
  data: CoachActivityFeed;
  selection: ActivityFilters;
  onClose: () => void;
  onApply: (selection: ActivityFilters) => void;
}) {
  const { colors } = useAppTheme();
  const layout = useResponsiveLayout();
  const [draft, setDraft] = useState(selection);
  const [historyVisible, setHistoryVisible] = useState(false);
  const [search, setSearch] = useState('');
  const currentPrograms = data.programs.filter((program) => !isPastProgram(program));
  const historicalPrograms = data.programs.filter(isPastProgram)
    .filter((program) => program.title.toLocaleLowerCase('id-ID').includes(search.trim().toLocaleLowerCase('id-ID')));

  return (
    <Modal transparent visible animationType="slide" onRequestClose={onClose}>
      <View style={[styles.sheetOverlay, { backgroundColor: colors.overlay }]}> 
        <View style={[styles.filterSheet, layout !== 'compact' && styles.filterSheetWide, { backgroundColor: colors.background, borderColor: colors.border }]} accessibilityViewIsModal>
          <View style={styles.sheetHeader}>
            <Pressable accessibilityRole="button" onPress={() => historyVisible ? setHistoryVisible(false) : onClose()} style={styles.sheetHeaderAction}>
              <Text style={[styles.body, { color: colors.primaryAction }]}>{historyVisible ? 'Kembali' : 'Tutup'}</Text>
            </Pressable>
            <Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>{historyVisible ? 'Riwayat program' : 'Filter aktivitas'}</Text>
            <View style={styles.sheetHeaderSpacer} />
          </View>
          {historyVisible ? (
            <View style={styles.sheetBody}>
              <View style={[styles.searchField, { backgroundColor: colors.surface, borderColor: colors.border }]}>
                <MSCIcon name="search" color={colors.secondaryText} size="small" />
                <TextInput accessibilityLabel="Cari program selesai" placeholder="Cari program selesai" placeholderTextColor={colors.secondaryText} value={search} onChangeText={setSearch} style={[styles.searchInput, { color: colors.primaryText }]} />
              </View>
              <ScrollView contentContainerStyle={styles.optionList}>
                {historicalPrograms.map((program) => <FilterOption key={program.program_id} label={program.title} detail={formatProgramDate(program.ends_on, program.timezone)} selected={draft.programId === program.program_id} onPress={() => { setDraft((value) => ({ ...value, programId: program.program_id })); setHistoryVisible(false); }} />)}
                {historicalPrograms.length === 0 ? <StateView kind="empty" /> : null}
              </ScrollView>
            </View>
          ) : (
            <>
              <ScrollView contentContainerStyle={styles.sheetBody}>
                <FilterSection title="Program">
                  <FilterOption label="Semua program" selected={draft.programId === null} onPress={() => setDraft((value) => ({ ...value, programId: null }))} />
                  {currentPrograms.map((program) => <FilterOption key={program.program_id} label={program.title} selected={draft.programId === program.program_id} onPress={() => setDraft((value) => ({ ...value, programId: program.program_id }))} />)}
                  {historicalPrograms.length > 0 ? <FilterOption label="Riwayat program" detail={`${historicalPrograms.length} program selesai`} leadingIcon="pending" trailing="chevron" onPress={() => setHistoryVisible(true)} /> : null}
                </FilterSection>
                <FilterSection title="Jenis aktivitas">
                  {kindOptions.map((option) => <FilterOption key={option.value} label={option.label} selected={draft.kind === option.value} onPress={() => setDraft((value) => ({ ...value, kind: option.value }))} />)}
                </FilterSection>
                <FilterSection title="Waktu">
                  {timeOptions.map((option) => <FilterOption key={option.value} label={option.label} selected={draft.timeRange === option.value} onPress={() => setDraft((value) => ({ ...value, timeRange: option.value }))} />)}
                </FilterSection>
              </ScrollView>
              <View style={[styles.sheetActions, { backgroundColor: colors.background, borderColor: colors.border }]}> 
                <View style={styles.flex}><Button label="Atur ulang" tone="secondary" onPress={() => setDraft(defaultFilters)} /></View>
                <View style={styles.flex}><Button label="Terapkan filter" onPress={() => onApply(draft)} /></View>
              </View>
            </>
          )}
        </View>
      </View>
    </Modal>
  );
}

function FilterSection({ title, children }: { title: string; children: React.ReactNode }) {
  const { colors } = useAppTheme();
  return <View style={styles.filterSection}><Text style={[styles.sectionLabel, { color: colors.secondaryText }]}>{title}</Text><View style={[styles.optionGroup, { backgroundColor: colors.surface, borderColor: colors.border }]}>{children}</View></View>;
}

function FilterOption({ label, detail, selected = false, leadingIcon, trailing = 'check', onPress }: { label: string; detail?: string; selected?: boolean; leadingIcon?: MSCIconName; trailing?: 'check' | 'chevron'; onPress: () => void }) {
  const { colors } = useAppTheme();
  return <Pressable accessibilityRole={trailing === 'check' ? 'radio' : 'button'} accessibilityState={trailing === 'check' ? { selected } : undefined} onPress={onPress} style={({ pressed }) => [styles.filterOption, pressed && { backgroundColor: colors.secondaryBackground }]}>{leadingIcon ? <MSCIcon name={leadingIcon} color={colors.primaryAction} /> : null}<View style={styles.flexCopy}><Text style={[styles.body, { color: colors.primaryText }]}>{label}</Text>{detail ? <Text style={[styles.caption, { color: colors.secondaryText }]}>{detail}</Text> : null}</View>{trailing === 'chevron' ? <Text style={[styles.chevron, { color: colors.secondaryText }]}>›</Text> : selected ? <Text style={[styles.checkmark, { color: colors.primaryAction }]}>✓</Text> : null}</Pressable>;
}

function activityPresentation(item: ActivityItem): { copy: string; icon: MSCIconName; color: 'success' | 'warning' | 'destructive'; badge: string | null; tone: 'success' | 'warning' | 'destructive' } {
  if (item.kind === 'evidence_submitted') return {
    copy: `Mengirim bukti untuk ${item.step_title ?? 'langkah program'}`,
    icon: 'content',
    color: item.requires_review ? 'warning' : 'destructive',
    badge: item.requires_review ? 'Perlu pemeriksaan' : item.evidence_status === 'rejected' ? 'Ditolak' : null,
    tone: item.requires_review ? 'warning' : 'destructive',
  };
  if (item.kind === 'step_completed') return { copy: `Menyelesaikan langkah ${item.step_title ?? 'program'}`, icon: 'activity', color: 'success', badge: item.points === null ? null : `${item.points} poin`, tone: 'warning' };
  if (item.kind === 'participant_joined') return { copy: `Bergabung ke program ${item.program_title}`, icon: 'participants', color: 'success', badge: null, tone: 'success' };
  return { copy: `Menyelesaikan program ${item.program_title}`, icon: 'approved', color: 'success', badge: null, tone: 'success' };
}

function filterSummary(filters: ActivityFilters, data: CoachActivityFeed): string {
  const program = filters.programId ? data.programs.find((item) => item.program_id === filters.programId)?.title ?? 'Program dipilih' : 'Semua program';
  const kind = kindOptions.find((item) => item.value === filters.kind)?.label ?? 'Semua aktivitas';
  const time = timeOptions.find((item) => item.value === filters.timeRange)?.label ?? 'Hari ini';
  return `${program} • ${kind} • ${time}`;
}

function matchesTimeRange(value: string, range: TimeRange): boolean {
  const days = calendarDayDifference(localDateKey(value), todayKey());
  if (range === 'today') return days === 0;
  if (range === 'sevenDays') return days >= 0 && days < 7;
  return days >= 0 && days < 30;
}

function groupByDay(items: ActivityItem[]): { key: string; items: ActivityItem[] }[] {
  const grouped = new Map<string, ActivityItem[]>();
  items.forEach((item) => { const key = localDateKey(item.occurred_at); grouped.set(key, [...(grouped.get(key) ?? []), item]); });
  return [...grouped.entries()].sort(([left], [right]) => right.localeCompare(left)).map(([key, groupedItems]) => ({ key, items: groupedItems }));
}

function localDateKey(value: string | Date): string {
  const parts = new Intl.DateTimeFormat('en-CA', { timeZone: displayTimeZone, year: 'numeric', month: '2-digit', day: '2-digit' }).formatToParts(typeof value === 'string' ? new Date(value) : value);
  const part = (type: Intl.DateTimeFormatPartTypes) => parts.find((item) => item.type === type)?.value ?? '';
  return `${part('year')}-${part('month')}-${part('day')}`;
}

function todayKey(): string { return localDateKey(new Date()); }
function calendarDayDifference(earlier: string, later: string): number { return Math.round((Date.parse(`${later}T00:00:00Z`) - Date.parse(`${earlier}T00:00:00Z`)) / 86_400_000); }
function dateHeading(key: string): string {
  const difference = calendarDayDifference(key, todayKey());
  if (difference === 0) return 'Hari ini';
  if (difference === 1) return 'Kemarin';
  return new Intl.DateTimeFormat('id-ID', { dateStyle: 'full', timeZone: 'UTC' }).format(new Date(`${key}T12:00:00Z`));
}
function relativeTime(value: string): string {
  const minutes = Math.max(0, Math.floor((Date.now() - new Date(value).getTime()) / 60_000));
  if (minutes < 1) return 'Baru saja';
  if (minutes < 60) return `${minutes} menit yang lalu`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours} jam yang lalu`;
  const days = Math.floor(hours / 24);
  if (days < 7) return `${days} hari yang lalu`;
  return `${Math.floor(days / 7)} minggu yang lalu`;
}
function isPastProgram(program: CoachActivityFeed['programs'][number]): boolean { return program.ends_on < localDateKey(new Date()); }
function formatProgramDate(value: string, timeZone: string): string { return new Intl.DateTimeFormat('id-ID', { dateStyle: 'long', timeZone }).format(new Date(`${value}T12:00:00Z`)); }

const styles = StyleSheet.create({
  screen: { flex: 1, minHeight: 0 },
  controls: { width: '100%', maxWidth: 900, alignSelf: 'center', gap: primitiveTokens.space.medium, padding: primitiveTokens.space.medium },
  list: { width: '100%', maxWidth: 900, alignSelf: 'center', paddingHorizontal: primitiveTokens.space.medium, paddingBottom: 140, gap: primitiveTokens.space.large },
  filterSummary: { minHeight: 84, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.medium, borderWidth: 1, borderRadius: primitiveTokens.radius.large, padding: primitiveTokens.space.medium },
  group: { gap: primitiveTokens.space.small },
  sectionTitle: typographyTokens.title,
  activityRow: { minHeight: 126, flexDirection: 'row', alignItems: 'flex-start', gap: primitiveTokens.space.medium, paddingVertical: primitiveTokens.space.medium },
  activityMeta: { minHeight: 32, flexDirection: 'row', alignItems: 'center', flexWrap: 'wrap', gap: primitiveTokens.space.small, marginTop: primitiveTokens.space.xSmall },
  emptyWrap: { gap: primitiveTokens.space.small },
  centerText: { textAlign: 'center' },
  flexCopy: { flex: 1, minWidth: 0, gap: primitiveTokens.space.xxSmall },
  flex: { flex: 1, minWidth: 140 },
  sheetOverlay: { flex: 1, justifyContent: 'flex-end' },
  filterSheet: { width: '100%', height: '90%', borderTopWidth: 1, borderTopLeftRadius: primitiveTokens.radius.prominent, borderTopRightRadius: primitiveTokens.radius.prominent, overflow: 'hidden' },
  filterSheetWide: { maxWidth: 620, alignSelf: 'center', borderWidth: 1, borderBottomWidth: 0 },
  sheetHeader: { minHeight: 72, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: primitiveTokens.space.medium },
  sheetHeaderAction: { minWidth: 80, minHeight: componentTokens.minimumTouchTarget, justifyContent: 'center' },
  sheetHeaderSpacer: { width: 80 },
  sheetBody: { flexGrow: 1, padding: primitiveTokens.space.medium, paddingBottom: primitiveTokens.space.xLarge, gap: primitiveTokens.space.large },
  sheetActions: { flexDirection: 'row', gap: primitiveTokens.space.small, borderTopWidth: StyleSheet.hairlineWidth, padding: primitiveTokens.space.medium },
  searchField: { minHeight: componentTokens.inputHeight, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.small, borderWidth: 1, borderRadius: primitiveTokens.radius.large, paddingHorizontal: primitiveTokens.space.medium },
  searchInput: { flex: 1, minWidth: 0, ...typographyTokens.body },
  optionList: { gap: primitiveTokens.space.small, paddingBottom: primitiveTokens.space.large },
  filterSection: { gap: primitiveTokens.space.xSmall },
  sectionLabel: { ...typographyTokens.label, paddingHorizontal: primitiveTokens.space.xSmall },
  optionGroup: { borderWidth: StyleSheet.hairlineWidth, borderRadius: primitiveTokens.radius.large, overflow: 'hidden' },
  filterOption: { minHeight: 62, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.small, borderBottomWidth: StyleSheet.hairlineWidth, borderBottomColor: 'rgba(127,127,127,0.25)', paddingHorizontal: primitiveTokens.space.medium, paddingVertical: primitiveTokens.space.small },
  checkmark: { fontSize: 24, lineHeight: 28, fontWeight: '700' },
  chevron: { fontSize: 28, lineHeight: 32 },
  heading: typographyTokens.headline,
  cardTitle: typographyTokens.bodyStrong,
  body: typographyTokens.body,
  caption: typographyTokens.caption,
});
