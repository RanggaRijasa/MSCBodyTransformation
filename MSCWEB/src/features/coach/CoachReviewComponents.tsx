import { router } from 'expo-router';
import { useEffect, useMemo, useRef, useState } from 'react';
import {
  Image,
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';

import type { CoachReviewItem } from './coach-review-models';
import { useCoachReviewDecision, useCoachReviews } from './coach-review-queries';
import { getCoachReviewRepository } from './coach-review-repository';
import { componentTokens, primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { useResponsiveLayout } from '@/shared/design/useResponsiveLayout';
import { MSCIcon } from '@/shared/icons/MSCIcon';
import { Button, Card, Dialog, Field, InlineMessage, SegmentedControl, StateView, UserAvatar } from '@/shared/ui/primitives';

type ReviewScope = 'action' | 'all';
type ReviewStatusFilter = 'all' | 'needsApproval' | 'automatic' | 'approved' | 'rejected';
type ReviewFilterSelection = { programId: string | null; status: ReviewStatusFilter };
type ReviewProgram = CoachReviewItem['program'];

const allFilters: ReviewFilterSelection = { programId: null, status: 'all' };
const statusOptions: readonly { value: ReviewStatusFilter; label: string }[] = [
  { value: 'all', label: 'Semua status' },
  { value: 'needsApproval', label: 'Perlu persetujuan' },
  { value: 'automatic', label: 'Poin otomatis' },
  { value: 'approved', label: 'Disetujui' },
  { value: 'rejected', label: 'Ditolak' },
];

export function CoachReviewQueue({ items, onRetry }: { items: CoachReviewItem[]; onRetry: () => void }) {
  const { colors } = useAppTheme();
  const [scope, setScope] = useState<ReviewScope>('action');
  const [filters, setFilters] = useState<ReviewFilterSelection>(allFilters);
  const [filtersVisible, setFiltersVisible] = useState(false);
  const programs = useMemo(
    () => [...new Map(items.map((item) => [item.program.id, item.program])).values()]
      .sort((left, right) => left.title.localeCompare(right.title, 'id-ID')),
    [items],
  );
  const pendingCount = items.filter(needsCoachAction).length;
  const visible = items.filter((item) => (
    (scope === 'all' || needsCoachAction(item))
    && (filters.programId === null || item.program.id === filters.programId)
    && matchesStatus(item, filters.status)
  ));

  return (
    <View style={styles.screen} testID="coach.review.queue">
      <View style={[styles.fixedControls, { backgroundColor: colors.background }]}> 
        <Button
          label="Kembali ke dashboard"
          tone="secondary"
          icon="back"
          onPress={() => router.replace('/coach')}
        />
        <SegmentedControl
          label="Lingkup bukti"
          value={scope}
          onChange={setScope}
          options={[{ label: `Perlu tindakan (${pendingCount})`, value: 'action' }, { label: 'Semua bukti', value: 'all' }]}
        />
        <FilterSummaryButton
          summary={filterSummary(filters, programs)}
          onPress={() => setFiltersVisible(true)}
        />
      </View>
      <ScrollView contentContainerStyle={styles.listContent}>
        {visible.length === 0 ? (
          <ReviewEmptyState scope={scope} onRetry={onRetry} />
        ) : visible.map((item) => <CoachReviewRow key={item.id} item={item} />)}
      </ScrollView>
      {filtersVisible ? (
        <ReviewFilterSheet
          programs={programs}
          selection={filters}
          onClose={() => setFiltersVisible(false)}
          onApply={(selection) => {
            setFilters(selection);
            setFiltersVisible(false);
          }}
        />
      ) : null}
    </View>
  );
}

function FilterSummaryButton({ summary, onPress }: { summary: string; onPress: () => void }) {
  const { colors } = useAppTheme();
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={`Filter bukti, ${summary}`}
      accessibilityHint="Buka pilihan program dan status bukti"
      onPress={onPress}
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
        <Text style={[styles.cardTitle, { color: colors.primaryText }]}>Filter bukti</Text>
        <Text style={[styles.body, { color: colors.secondaryText }]}>{summary}</Text>
      </View>
      <Text accessibilityElementsHidden style={[styles.chevron, { color: colors.secondaryText }]}>›</Text>
    </Pressable>
  );
}

function ReviewFilterSheet({
  programs,
  selection,
  onClose,
  onApply,
}: {
  programs: ReviewProgram[];
  selection: ReviewFilterSelection;
  onClose: () => void;
  onApply: (selection: ReviewFilterSelection) => void;
}) {
  const { colors } = useAppTheme();
  const layout = useResponsiveLayout();
  const [draft, setDraft] = useState(selection);
  const [historyVisible, setHistoryVisible] = useState(false);
  const [search, setSearch] = useState('');

  const currentPrograms = programs.filter((program) => !isPastProgram(program));
  const historicalPrograms = programs.filter(isPastProgram).filter((program) => (
    program.title.toLocaleLowerCase('id-ID').includes(search.trim().toLocaleLowerCase('id-ID'))
  ));

  return (
    <Modal transparent visible animationType="slide" onRequestClose={onClose}>
      <View style={[styles.sheetOverlay, { backgroundColor: colors.overlay }]}> 
        <View
          accessibilityViewIsModal
          style={[
            styles.filterSheet,
            layout !== 'compact' && styles.filterSheetWide,
            { backgroundColor: colors.background, borderColor: colors.border },
          ]}
        >
          <View style={styles.sheetHeader}>
            <Pressable accessibilityRole="button" accessibilityLabel={historyVisible ? 'Kembali ke filter bukti' : 'Tutup filter bukti'} onPress={() => historyVisible ? setHistoryVisible(false) : onClose()} style={styles.sheetHeaderAction}>
              <Text style={[styles.headerActionText, { color: colors.primaryAction }]}>{historyVisible ? 'Kembali' : 'Tutup'}</Text>
            </Pressable>
            <Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>{historyVisible ? 'Riwayat program' : 'Filter bukti'}</Text>
            <View style={styles.sheetHeaderSpacer} />
          </View>

          {historyVisible ? (
            <View style={styles.sheetBody}>
              <View style={[styles.searchField, { backgroundColor: colors.surface, borderColor: colors.border }]}> 
                <MSCIcon name="search" color={colors.secondaryText} size="small" />
                <TextInput
                  accessibilityLabel="Cari program selesai"
                  placeholder="Cari program selesai"
                  placeholderTextColor={colors.secondaryText}
                  value={search}
                  onChangeText={setSearch}
                  style={[styles.searchInput, { color: colors.primaryText }]}
                />
              </View>
              <ScrollView contentContainerStyle={styles.optionList}>
                {historicalPrograms.length === 0 ? (
                  <StateView kind="empty" />
                ) : historicalPrograms.map((program) => (
                  <FilterOption
                    key={program.id}
                    label={program.title}
                    detail={formatProgramEnd(program)}
                    selected={draft.programId === program.id}
                    onPress={() => {
                      setDraft((value) => ({ ...value, programId: program.id }));
                      setHistoryVisible(false);
                    }}
                  />
                ))}
              </ScrollView>
            </View>
          ) : (
            <>
              <ScrollView contentContainerStyle={styles.sheetBody}>
                <FilterSection title="Program">
                  <FilterOption label="Semua program" selected={draft.programId === null} onPress={() => setDraft((value) => ({ ...value, programId: null }))} />
                  {currentPrograms.map((program) => (
                    <FilterOption key={program.id} label={program.title} selected={draft.programId === program.id} onPress={() => setDraft((value) => ({ ...value, programId: program.id }))} />
                  ))}
                  <FilterOption label="Riwayat program" detail={historicalPrograms.length > 0 ? `${historicalPrograms.length} program selesai` : 'Belum ada program selesai'} onPress={() => setHistoryVisible(true)} trailing="chevron" />
                </FilterSection>
                <FilterSection title="Status bukti">
                  {statusOptions.map((option) => (
                    <FilterOption key={option.value} label={option.label} selected={draft.status === option.value} onPress={() => setDraft((value) => ({ ...value, status: option.value }))} />
                  ))}
                </FilterSection>
              </ScrollView>
              <View style={[styles.sheetActions, { backgroundColor: colors.background, borderColor: colors.border }]}> 
                <View style={styles.flex}><Button label="Atur ulang" tone="secondary" onPress={() => setDraft(allFilters)} /></View>
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
  return (
    <View style={styles.filterSection}>
      <Text style={[styles.sectionLabel, { color: colors.secondaryText }]}>{title}</Text>
      <View style={[styles.optionGroup, { backgroundColor: colors.surface, borderColor: colors.border }]}>{children}</View>
    </View>
  );
}

function FilterOption({
  label,
  detail,
  selected = false,
  trailing = 'check',
  onPress,
}: {
  label: string;
  detail?: string;
  selected?: boolean;
  trailing?: 'check' | 'chevron';
  onPress: () => void;
}) {
  const { colors } = useAppTheme();
  return (
    <Pressable
      accessibilityRole={trailing === 'check' ? 'radio' : 'button'}
      accessibilityState={trailing === 'check' ? { selected } : undefined}
      onPress={onPress}
      style={({ pressed }) => [styles.filterOption, pressed && { backgroundColor: colors.secondaryBackground }]}
    >
      <View style={styles.flexCopy}>
        <Text style={[styles.body, { color: colors.primaryText }]}>{label}</Text>
        {detail ? <Text style={[styles.caption, { color: colors.secondaryText }]}>{detail}</Text> : null}
      </View>
      {trailing === 'chevron' ? <Text style={[styles.chevron, { color: colors.secondaryText }]}>›</Text> : selected ? <Text style={[styles.checkmark, { color: colors.primaryAction }]}>✓</Text> : null}
    </Pressable>
  );
}

function ReviewEmptyState({ scope, onRetry }: { scope: ReviewScope; onRetry: () => void }) {
  const { colors } = useAppTheme();
  return (
    <View style={styles.emptyState} accessibilityRole="summary">
      <MSCIcon name={scope === 'action' ? 'approved' : 'info'} color={scope === 'action' ? colors.success : colors.primaryAction} size="large" />
      <Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>{scope === 'action' ? 'Semua bukti sudah diperiksa' : 'Belum ada bukti'}</Text>
      <Text style={[styles.bodyCentered, { color: colors.secondaryText }]}>{scope === 'action' ? 'Bukti baru yang memerlukan persetujuan akan tampil di sini.' : 'Bukti peserta akan tampil setelah dikirim.'}</Text>
      <Button label="Muat ulang" tone="secondary" onPress={onRetry} />
    </View>
  );
}

function CoachReviewRow({ item }: { item: CoachReviewItem }) {
  const { colors } = useAppTheme();
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={`${item.participant.display_name}, ${item.step.title}, ${statusLabel(item)}`}
      onPress={() => router.push(`/coach/reviews/${item.id}` as never)}
      style={({ pressed }) => ({ transform: [{ scale: pressed ? 0.99 : 1 }] })}
    >
      <Card>
        <View style={styles.rowTop}>
          <UserAvatar uri={item.participant.avatar_url ?? undefined} label={item.participant.display_name} />
          <View style={styles.flexCopy}>
            <Text style={[styles.cardTitle, { color: colors.primaryText }]}>{item.participant.display_name}</Text>
            <Text style={[styles.body, { color: colors.primaryText }]}>{item.step.title}</Text>
            <Text style={[styles.caption, { color: colors.secondaryText }]}>{item.program.title} • Hari {item.day.day_number}</Text>
            <Text style={[styles.caption, styles.numeric, { color: colors.secondaryText }]}>{formatDateTime(item.submitted_at, item.program.timezone)}</Text>
          </View>
          <Text accessibilityElementsHidden style={[styles.chevron, { color: colors.secondaryText }]}>›</Text>
        </View>
        <View style={[styles.rowDivider, { backgroundColor: colors.border }]} />
        <ReviewStatusPill item={item} />
      </Card>
    </Pressable>
  );
}

function ReviewStatusPill({ item }: { item: CoachReviewItem }) {
  const { colors } = useAppTheme();
  const statusColor = item.step.verification_mode === 'automatic' || item.status === 'approved'
    ? colors.success
    : item.status === 'rejected'
      ? colors.destructive
      : colors.primaryAction;
  const icon = item.step.verification_mode === 'automatic' || item.status === 'approved'
    ? 'approved'
    : item.status === 'rejected'
      ? 'rejected'
      : 'warning';
  return (
    <View style={[styles.reviewStatus, { backgroundColor: colors.secondaryBackground }]}> 
      <MSCIcon name={icon} color={statusColor} size="small" />
      <Text style={[styles.captionStrong, { color: statusColor }]}>{statusLabel(item)}</Text>
    </View>
  );
}

export function CoachReviewDetail({ submissionId }: { submissionId: string }) {
  const { colors } = useAppTheme();
  const reviews = useCoachReviews(true);
  const decision = useCoachReviewDecision();
  const item = reviews.data?.find((review) => review.id === submissionId);
  const [reason, setReason] = useState('');
  const [mode, setMode] = useState<'idle' | 'approve' | 'reject'>('idle');
  const idempotencyKeys = useRef({
    approved: `web-review-${submissionId}-approved-${crypto.randomUUID()}`,
    rejected: `web-review-${submissionId}-rejected-${crypto.randomUUID()}`,
  });

  if (reviews.isPending) return <StateView kind="loading" />;
  if (reviews.isError) return <StateView kind="error" action={<Button label="Coba lagi" onPress={() => void reviews.refetch()} />} />;
  if (!item) return <StateView kind="empty" action={<Button label="Kembali ke antrean" onPress={() => router.replace('/coach/reviews')} />} />;

  const submitDecision = async (next: 'approved' | 'rejected') => {
    try {
      await decision.mutateAsync({ submissionId: item.id, decision: next, reason: next === 'rejected' ? reason : undefined, idempotencyKey: idempotencyKeys.current[next] });
      router.replace('/coach/reviews');
    } catch {
      setMode('idle');
    }
  };

  return (
    <View style={styles.detailScreen} testID="coach.review.detail">
      <ScrollView contentContainerStyle={styles.detailContent}>
        <Pressable accessibilityRole="button" accessibilityLabel="Kembali ke antrean" onPress={() => router.back()} style={({ pressed }) => [styles.compactBack, pressed && { opacity: 0.65 }]}>
          <MSCIcon name="back" color={colors.primaryText} />
          <Text style={[styles.bodyStrong, { color: colors.primaryText }]}>Kembali</Text>
        </Pressable>
        <ReviewModeBanner item={item} />
        <Card>
          <View style={styles.rowTop}>
            <UserAvatar uri={item.participant.avatar_url ?? undefined} label={item.participant.display_name} />
            <View style={styles.flexCopy}>
              <Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>{item.participant.display_name}</Text>
              <Text style={[styles.body, { color: colors.secondaryText }]}>{item.program.title}</Text>
            </View>
          </View>
          <View style={styles.contextTags}>
            <ContextTag icon="program" label={`Hari ${item.day.day_number}`} />
            <ContextTag icon="reviewEvidence" label={item.step.title} />
          </View>
          <Text style={[styles.body, { color: colors.primaryText }]}>{item.step.instructions || 'Ikuti petunjuk langkah program.'}</Text>
        </Card>

        <View style={styles.stack}>
          <Text accessibilityRole="header" style={[styles.sectionTitle, { color: colors.primaryText }]}>Bukti yang dikirim</Text>
          {item.answers.length === 0 ? <Text style={[styles.body, { color: colors.secondaryText }]}>Belum ada jawaban yang dapat ditampilkan.</Text> : item.answers.map((answer) => (
            <Card key={answer.id}>
              <Text style={[styles.cardTitle, { color: colors.primaryText }]}>{answer.prompt}</Text>
              {answer.private_photo_path ? <PrivateReviewImage objectPath={answer.private_photo_path} /> : (
                <Text style={[styles.body, { color: colors.primaryText }]}>{answer.text_value ?? answer.number_value?.toLocaleString('id-ID') ?? (answer.selected_option_titles.length ? answer.selected_option_titles.join(', ') : 'Belum dijawab')}</Text>
              )}
            </Card>
          ))}
          {item.quiz_result ? <QuizResult result={item.quiz_result} /> : null}
          <Text style={[styles.caption, styles.numeric, { color: colors.secondaryText }]}>Dikirim {formatDateTime(item.submitted_at, item.program.timezone)}</Text>
        </View>
        {item.review_note ? <InlineMessage title="Catatan pemeriksaan" message={item.review_note} tone={item.status === 'rejected' ? 'destructive' : 'info'} /> : null}
        {decision.error instanceof Error ? <InlineMessage title="Status sudah berubah" message={decision.error.message} tone="destructive" /> : null}
      </ScrollView>

      {needsCoachAction(item) ? (
        <View style={[styles.stickyActions, { backgroundColor: colors.background, borderColor: colors.border }]}> 
          {mode === 'reject' ? (
            <View style={styles.stack}>
              <Field label="Alasan penolakan" value={reason} onChangeText={setReason} multiline message="Alasan akan terlihat oleh Peserta agar bukti dapat diperbaiki." />
              <View style={styles.actionRow}>
                <View style={styles.flex}><Button label="Batal" tone="secondary" onPress={() => setMode('idle')} /></View>
                <View style={styles.flex}><Button label="Tolak bukti" tone="destructive" loading={decision.isPending} disabled={!reason.trim()} onPress={() => void submitDecision('rejected')} /></View>
              </View>
            </View>
          ) : (
            <View style={styles.actionRow}>
              <View style={styles.flex}><Button label="Tolak bukti" tone="secondary" onPress={() => setMode('reject')} /></View>
              <View style={styles.flex}><Button label={`Setujui • ${item.program.points_per_activity.toLocaleString('id-ID')} poin`} onPress={() => setMode('approve')} /></View>
            </View>
          )}
        </View>
      ) : null}

      <Dialog visible={mode === 'approve'} title="Setujui bukti?" onClose={() => setMode('idle')}>
        <Text style={[styles.body, { color: colors.secondaryText }]}>Jawaban akan disetujui dan {item.program.points_per_activity.toLocaleString('id-ID')} poin aktivitas diberikan satu kali oleh server.</Text>
        <View style={styles.actionRow}>
          <View style={styles.flex}><Button label="Batal" tone="secondary" onPress={() => setMode('idle')} /></View>
          <View style={styles.flex}><Button label="Setujui bukti" loading={decision.isPending} onPress={() => void submitDecision('approved')} /></View>
        </View>
      </Dialog>
    </View>
  );
}

function ReviewModeBanner({ item }: { item: CoachReviewItem }) {
  if (item.step.verification_mode === 'automatic') {
    return <InlineMessage title="Poin otomatis" message="Poin diberikan otomatis sesuai aturan langkah program." tone="success" />;
  }
  if (item.status === 'pending') {
    return <InlineMessage title="Persetujuan Coach diperlukan" message={`${item.program.points_per_activity.toLocaleString('id-ID')} poin diberikan setelah jawaban disetujui.`} tone="warning" />;
  }
  return <InlineMessage title={statusLabel(item)} message={item.status === 'approved' ? 'Bukti telah disetujui dan poin aktivitas sudah diproses.' : 'Bukti telah ditolak. Catatan pemeriksaan dapat dilihat Peserta.'} tone={item.status === 'approved' ? 'success' : 'destructive'} />;
}

function ContextTag({ icon, label }: { icon: 'program' | 'reviewEvidence'; label: string }) {
  const { colors } = useAppTheme();
  return (
    <View style={styles.contextTag}>
      <MSCIcon name={icon} color={colors.secondaryText} size="small" />
      <Text style={[styles.caption, { color: colors.secondaryText }]}>{label}</Text>
    </View>
  );
}

function QuizResult({ result }: { result: NonNullable<CoachReviewItem['quiz_result']> }) {
  const { colors } = useAppTheme();
  return (
    <Card>
      <Text style={[styles.cardTitle, { color: colors.primaryText }]}>Hasil kuis</Text>
      <ResultRow label="Jawaban benar" value={`${result.correct_count} dari ${result.total_count}`} />
      <ResultRow label="Nilai" value={`${result.percentage}%`} />
      <ResultRow label="Status" value={result.passed ? 'Lulus' : 'Belum lulus'} />
    </Card>
  );
}

function ResultRow({ label, value }: { label: string; value: string }) {
  const { colors } = useAppTheme();
  return (
    <View style={styles.resultRow}>
      <Text style={[styles.body, { color: colors.secondaryText }]}>{label}</Text>
      <Text style={[styles.bodyStrong, styles.numeric, { color: colors.primaryText }]}>{value}</Text>
    </View>
  );
}

function PrivateReviewImage({ objectPath }: { objectPath: string }) {
  const { colors } = useAppTheme();
  const [url, setUrl] = useState<string>();
  const [failed, setFailed] = useState(false);
  const [expanded, setExpanded] = useState(false);
  useEffect(() => {
    let active = true;
    void getCoachReviewRepository().createPhotoUrl(objectPath).then((result) => {
      if (active) setUrl(result.url);
    }).catch(() => {
      if (active) setFailed(true);
    });
    return () => { active = false; };
  }, [objectPath]);
  if (failed) return <InlineMessage title="Foto tidak dapat dimuat" message="Muat ulang sebelum mengambil keputusan." tone="destructive" />;
  if (!url) return <StateView kind="loading" />;
  return (
    <Pressable accessibilityRole="button" accessibilityLabel={expanded ? 'Perkecil bukti foto' : 'Perbesar bukti foto'} accessibilityState={{ expanded }} onPress={() => setExpanded((value) => !value)} style={styles.photoFrame}>
      <Image accessibilityLabel="Bukti foto peserta" resizeMode={expanded ? 'contain' : 'cover'} source={{ uri: url }} style={[styles.reviewImage, expanded && styles.reviewImageExpanded, { backgroundColor: colors.secondaryBackground }]} />
      <View style={[styles.expandLabel, { backgroundColor: colors.elevatedSurface }]}> 
        <Text style={[styles.captionStrong, { color: colors.primaryText }]}>{expanded ? 'Perkecil' : 'Perbesar'}</Text>
      </View>
    </Pressable>
  );
}

function needsCoachAction(item: CoachReviewItem): boolean {
  return item.step.verification_mode === 'coach_review' && item.status === 'pending';
}

function matchesStatus(item: CoachReviewItem, status: ReviewStatusFilter): boolean {
  if (status === 'all') return true;
  if (status === 'needsApproval') return needsCoachAction(item);
  if (status === 'automatic') return item.step.verification_mode === 'automatic';
  return item.step.verification_mode === 'coach_review' && item.status === status;
}

function statusLabel(item: CoachReviewItem): string {
  if (item.step.verification_mode === 'automatic') return 'Poin otomatis';
  if (item.status === 'pending') return 'Perlu persetujuan';
  if (item.status === 'approved') return 'Disetujui';
  if (item.status === 'rejected') return 'Ditolak';
  return 'Digantikan';
}

function filterSummary(selection: ReviewFilterSelection, programs: ReviewProgram[]): string {
  const program = selection.programId ? programs.find((item) => item.id === selection.programId)?.title ?? 'Program dipilih' : 'Semua program';
  const status = statusOptions.find((item) => item.value === selection.status)?.label ?? 'Semua status';
  return `${program} • ${status}`;
}

function isPastProgram(program: ReviewProgram): boolean {
  return program.ends_on < todayInTimeZone(program.timezone);
}

function formatProgramEnd(program: ReviewProgram): string {
  return new Intl.DateTimeFormat('id-ID', { dateStyle: 'long', timeZone: program.timezone }).format(new Date(`${program.ends_on}T12:00:00Z`));
}

function todayInTimeZone(timeZone: string): string {
  const parts = new Intl.DateTimeFormat('en-CA', { timeZone, year: 'numeric', month: '2-digit', day: '2-digit' }).formatToParts(new Date());
  const value = (type: Intl.DateTimeFormatPartTypes) => parts.find((part) => part.type === type)?.value ?? '';
  return `${value('year')}-${value('month')}-${value('day')}`;
}

function formatDateTime(value: string, timeZone: string): string {
  return new Intl.DateTimeFormat('id-ID', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    timeZone,
    timeZoneName: 'short',
  }).format(new Date(value));
}

const styles = StyleSheet.create({
  screen: { flex: 1, minHeight: 0 },
  fixedControls: { width: '100%', maxWidth: 900, alignSelf: 'center', gap: primitiveTokens.space.medium, padding: primitiveTokens.space.medium },
  filterSummary: { minHeight: 84, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.medium, borderWidth: 1, borderRadius: primitiveTokens.radius.large, padding: primitiveTokens.space.medium },
  listContent: { width: '100%', maxWidth: 900, alignSelf: 'center', paddingHorizontal: primitiveTokens.space.medium, paddingTop: primitiveTokens.space.xSmall, paddingBottom: primitiveTokens.space.xLarge, gap: primitiveTokens.space.medium },
  emptyState: { width: '100%', maxWidth: componentTokens.readingMaxWidth, alignSelf: 'center', alignItems: 'center', paddingHorizontal: primitiveTokens.space.large, paddingVertical: primitiveTokens.space.xxLarge, gap: primitiveTokens.space.small },
  sheetOverlay: { flex: 1, justifyContent: 'flex-end' },
  filterSheet: { width: '100%', height: '88%', borderTopWidth: 1, borderTopLeftRadius: primitiveTokens.radius.prominent, borderTopRightRadius: primitiveTokens.radius.prominent, overflow: 'hidden' },
  filterSheetWide: { maxWidth: 620, height: '90%', alignSelf: 'center', borderWidth: 1, borderBottomWidth: 0 },
  sheetHeader: { minHeight: 72, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: primitiveTokens.space.medium },
  sheetHeaderAction: { minWidth: 80, minHeight: componentTokens.minimumTouchTarget, justifyContent: 'center' },
  sheetHeaderSpacer: { width: 80 },
  headerActionText: typographyTokens.body,
  sheetBody: { flexGrow: 1, padding: primitiveTokens.space.medium, paddingBottom: primitiveTokens.space.xLarge, gap: primitiveTokens.space.large },
  filterSection: { gap: primitiveTokens.space.xSmall },
  sectionLabel: { ...typographyTokens.label, paddingHorizontal: primitiveTokens.space.xSmall },
  optionGroup: { borderWidth: StyleSheet.hairlineWidth, borderRadius: primitiveTokens.radius.large, overflow: 'hidden' },
  optionList: { gap: primitiveTokens.space.small, paddingBottom: primitiveTokens.space.large },
  filterOption: { minHeight: 62, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.small, borderBottomWidth: StyleSheet.hairlineWidth, borderBottomColor: 'rgba(127,127,127,0.25)', paddingHorizontal: primitiveTokens.space.medium, paddingVertical: primitiveTokens.space.small },
  checkmark: { fontSize: 24, lineHeight: 28, fontWeight: '700' },
  sheetActions: { flexDirection: 'row', gap: primitiveTokens.space.small, borderTopWidth: StyleSheet.hairlineWidth, padding: primitiveTokens.space.medium },
  searchField: { minHeight: componentTokens.inputHeight, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.small, borderWidth: 1, borderRadius: primitiveTokens.radius.capsule, paddingHorizontal: primitiveTokens.space.medium },
  searchInput: { flex: 1, minWidth: 0, ...typographyTokens.body },
  detailScreen: { flex: 1, minHeight: 0 },
  detailContent: { width: '100%', maxWidth: 760, alignSelf: 'center', padding: primitiveTokens.space.medium, paddingBottom: 180, gap: primitiveTokens.space.large },
  compactBack: { minHeight: componentTokens.minimumTouchTarget, alignSelf: 'flex-start', flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.xSmall, paddingHorizontal: primitiveTokens.space.small },
  rowTop: { flexDirection: 'row', alignItems: 'flex-start', gap: primitiveTokens.space.medium },
  rowDivider: { height: StyleSheet.hairlineWidth },
  flexCopy: { flex: 1, minWidth: 0, gap: primitiveTokens.space.xxSmall },
  contextTags: { flexDirection: 'row', flexWrap: 'wrap', gap: primitiveTokens.space.small },
  contextTag: { flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.xSmall },
  stack: { gap: primitiveTokens.space.medium },
  actionRow: { flexDirection: 'row', flexWrap: 'wrap', gap: primitiveTokens.space.small },
  flex: { flex: 1, minWidth: 150 },
  stickyActions: { position: 'absolute', left: 0, right: 0, bottom: 0, borderTopWidth: StyleSheet.hairlineWidth, padding: primitiveTokens.space.medium },
  reviewStatus: { alignSelf: 'flex-start', minHeight: 34, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.xSmall, borderRadius: primitiveTokens.radius.medium, paddingHorizontal: primitiveTokens.space.small },
  photoFrame: { position: 'relative' },
  reviewImage: { width: '100%', height: 320, borderRadius: primitiveTokens.radius.large },
  reviewImageExpanded: { height: 620 },
  expandLabel: { position: 'absolute', top: primitiveTokens.space.small, right: primitiveTokens.space.small, minHeight: 36, justifyContent: 'center', borderRadius: primitiveTokens.radius.capsule, paddingHorizontal: primitiveTokens.space.small },
  resultRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: primitiveTokens.space.medium },
  heading: typographyTokens.headline,
  sectionTitle: typographyTokens.title,
  cardTitle: typographyTokens.bodyStrong,
  body: typographyTokens.body,
  bodyStrong: typographyTokens.bodyStrong,
  bodyCentered: { ...typographyTokens.body, textAlign: 'center' },
  caption: typographyTokens.caption,
  captionStrong: { ...typographyTokens.caption, fontWeight: '700' },
  numeric: { fontVariant: ['tabular-nums'] },
  chevron: { fontSize: 28, lineHeight: 32 },
});
