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

import {
  useCoachParticipantDetail,
  useCoachParticipantDirectory,
} from './coach-experience-queries';
import type {
  CoachParticipantDetail,
  CoachParticipantDirectory,
} from './coach-experience-models';
import { getCoachReviewRepository } from './coach-review-repository';
import { componentTokens, primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { useResponsiveLayout } from '@/shared/design/useResponsiveLayout';
import { MSCIcon } from '@/shared/icons/MSCIcon';
import {
  Button,
  Card,
  InlineMessage,
  ProgressBar,
  StateView,
  StatusBadge,
  UserAvatar,
} from '@/shared/ui/primitives';

type DirectoryParticipant = CoachParticipantDirectory['participants'][number];
type DirectoryEnrollment = DirectoryParticipant['enrollments'][number];
type CompletionFilter = 'all' | 'inProgress' | 'complete' | 'attention';
type ParticipantSort = 'progress' | 'points' | 'lastActivity';
type FilterSelection = {
  programId: string | null;
  completion: CompletionFilter;
  sort: ParticipantSort;
};

const defaultFilters: FilterSelection = {
  programId: null,
  completion: 'all',
  sort: 'progress',
};

const completionOptions: readonly { value: CompletionFilter; label: string }[] = [
  { value: 'all', label: 'Semua status' },
  { value: 'inProgress', label: 'Sedang berjalan' },
  { value: 'complete', label: 'Selesai' },
  { value: 'attention', label: 'Perlu perhatian' },
];

const sortOptions: readonly { value: ParticipantSort; label: string }[] = [
  { value: 'progress', label: 'Kemajuan' },
  { value: 'points', label: 'Poin' },
  { value: 'lastActivity', label: 'Aktivitas terakhir' },
];

export function CoachParticipantDirectoryScreen({ authorized }: { authorized: boolean }) {
  const query = useCoachParticipantDirectory(authorized);
  if (!authorized) return <StateView kind="forbidden" />;
  if (query.isPending) return <StateView kind="loading" />;
  if (query.isError) {
    return <StateView kind="error" action={<Button label="Coba lagi" onPress={() => void query.refetch()} />} />;
  }
  if (!query.data) return <StateView kind="empty" />;
  return <ParticipantDirectory data={query.data} />;
}

function ParticipantDirectory({ data }: { data: CoachParticipantDirectory }) {
  const { colors } = useAppTheme();
  const [search, setSearch] = useState('');
  const [filters, setFilters] = useState(defaultFilters);
  const [filtersVisible, setFiltersVisible] = useState(false);
  const normalizedSearch = search.trim().toLocaleLowerCase('id-ID');

  const rows = useMemo(() => data.participants
    .map((participant) => ({ participant, enrollment: selectedEnrollment(participant, filters.programId) }))
    .filter((row): row is { participant: DirectoryParticipant; enrollment: DirectoryEnrollment } => row.enrollment !== undefined)
    .filter(({ participant }) => normalizedSearch.length === 0
      || participant.display_name.toLocaleLowerCase('id-ID').includes(normalizedSearch)
      || participant.city.toLocaleLowerCase('id-ID').includes(normalizedSearch))
    .filter(({ enrollment }) => matchesCompletion(enrollment, filters.completion))
    .sort((left, right) => compareRows(left, right, filters.sort)), [data.participants, filters, normalizedSearch]);

  const attentionCount = data.participants.filter((participant) => {
    const enrollment = selectedEnrollment(participant, null);
    return enrollment ? needsAttention(enrollment) : false;
  }).length;

  return (
    <View style={styles.screen} testID="coach.participants">
      <View style={[styles.directoryControls, { backgroundColor: colors.background }]}> 
        <Button label="Kembali ke dashboard" tone="secondary" icon="back" onPress={() => router.replace('/coach')} />
        <View style={[styles.summaryBar, { backgroundColor: colors.surface, borderColor: colors.border }]}> 
          <SummaryMetric icon="participants" value={data.participants.length} label="peserta" />
          <View style={[styles.verticalDivider, { backgroundColor: colors.border }]} />
          <SummaryMetric icon="warning" value={attentionCount} label="perlu perhatian" attention />
        </View>
        <View style={[styles.searchField, { backgroundColor: colors.surface, borderColor: colors.border }]}> 
          <MSCIcon name="search" color={colors.secondaryText} size="small" />
          <TextInput
            accessibilityLabel="Cari nama atau kota"
            placeholder="Cari nama atau kota"
            placeholderTextColor={colors.secondaryText}
            value={search}
            onChangeText={setSearch}
            style={[styles.searchInput, { color: colors.primaryText }]}
          />
          {search ? (
            <Pressable accessibilityRole="button" accessibilityLabel="Hapus pencarian" onPress={() => setSearch('')}>
              <MSCIcon name="rejected" color={colors.secondaryText} size="small" />
            </Pressable>
          ) : null}
        </View>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={`Filter dan urutkan, ${filterSummary(filters, data)}`}
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
            <Text style={[styles.cardTitle, { color: colors.primaryText }]}>Filter dan urutkan</Text>
            <Text style={[styles.body, { color: colors.secondaryText }]}>{filterSummary(filters, data)}</Text>
          </View>
          <Text accessibilityElementsHidden style={[styles.chevron, { color: colors.secondaryText }]}>›</Text>
        </Pressable>
      </View>

      <ScrollView contentContainerStyle={styles.directoryList}>
        {rows.length === 0 ? (
          <StateView kind="empty" action={<Button label="Atur ulang filter" tone="secondary" onPress={() => { setSearch(''); setFilters(defaultFilters); }} />} />
        ) : rows.map(({ participant, enrollment }) => (
          <ParticipantRow key={participant.participant_id} participant={participant} enrollment={enrollment} />
        ))}
      </ScrollView>

      {filtersVisible ? (
        <ParticipantFilterSheet
          data={data}
          selection={filters}
          onClose={() => setFiltersVisible(false)}
          onApply={(selection) => { setFilters(selection); setFiltersVisible(false); }}
        />
      ) : null}
    </View>
  );
}

function SummaryMetric({ icon, value, label, attention = false }: { icon: 'participants' | 'warning'; value: number; label: string; attention?: boolean }) {
  const { colors } = useAppTheme();
  const color = attention ? colors.primaryAction : colors.primaryText;
  return (
    <View style={styles.summaryMetric} accessibilityLabel={`${value} ${label}`}>
      <View style={[styles.summaryIcon, { backgroundColor: attention ? colors.secondaryBackground : colors.background }]}> 
        <MSCIcon name={icon} color={color} size="small" />
      </View>
      <View>
        <Text style={[styles.metricValue, { color: colors.primaryText }]}>{value.toLocaleString('id-ID')}</Text>
        <Text style={[styles.caption, { color: colors.secondaryText }]}>{label}</Text>
      </View>
    </View>
  );
}

function ParticipantRow({ participant, enrollment }: { participant: DirectoryParticipant; enrollment: DirectoryEnrollment }) {
  const { colors } = useAppTheme();
  const attention = needsAttention(enrollment);
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={`${participant.display_name}, ${enrollment.program_title}, ${enrollment.progress_percentage}%`}
      onPress={() => router.push(`/coach/participants/${participant.participant_id}?enrollment=${enrollment.enrollment_id}` as never)}
      style={({ pressed }) => ({ transform: [{ scale: pressed ? 0.99 : 1 }] })}
    >
      <Card>
        <View style={styles.participantRow}>
          <UserAvatar uri={participant.avatar_url ?? undefined} label={participant.display_name} size={64} />
          <View style={styles.flexCopy}>
            <View style={styles.rowBetween}>
              <Text style={[styles.cardTitle, { color: colors.primaryText }]}>{participant.display_name}</Text>
              <Text accessibilityElementsHidden style={[styles.chevron, { color: colors.secondaryText }]}>›</Text>
            </View>
            <Text style={[styles.body, { color: colors.secondaryText }]}>{enrollment.program_title}</Text>
            <View style={styles.progressLine}>
              <View style={[styles.progressTrack, { backgroundColor: colors.border }]}>
                <View style={[styles.progressFill, { backgroundColor: colors.primaryAction, width: `${enrollment.progress_percentage}%` }]} />
              </View>
              <Text style={[styles.numericStrong, { color: colors.primaryText }]}>{enrollment.progress_percentage}%</Text>
            </View>
            <View style={styles.statusWrap}>
              <View style={styles.activityLabel}>
                <View style={[styles.activityDot, { backgroundColor: colors.success }]} />
                <Text style={[styles.caption, { color: colors.secondaryText }]}>{relativeActivity(enrollment.last_activity_at)}</Text>
              </View>
              {attention ? <StatusBadge label="Perlu perhatian" tone="destructive" /> : null}
            </View>
          </View>
        </View>
      </Card>
    </Pressable>
  );
}

function ParticipantFilterSheet({ data, selection, onClose, onApply }: {
  data: CoachParticipantDirectory;
  selection: FilterSelection;
  onClose: () => void;
  onApply: (selection: FilterSelection) => void;
}) {
  const { colors } = useAppTheme();
  const layout = useResponsiveLayout();
  const [draft, setDraft] = useState(selection);
  const [historyVisible, setHistoryVisible] = useState(false);
  const [search, setSearch] = useState('');
  const currentPrograms = data.programs.filter((program) => !isPastProgram(program));
  const historicalPrograms = data.programs
    .filter(isPastProgram)
    .filter((program) => program.title.toLocaleLowerCase('id-ID').includes(search.trim().toLocaleLowerCase('id-ID')));

  return (
    <Modal transparent visible animationType="slide" onRequestClose={onClose}>
      <View style={[styles.sheetOverlay, { backgroundColor: colors.overlay }]}> 
        <View style={[styles.filterSheet, layout !== 'compact' && styles.filterSheetWide, { backgroundColor: colors.background, borderColor: colors.border }]} accessibilityViewIsModal>
          <View style={styles.sheetHeader}>
            <Pressable accessibilityRole="button" onPress={() => historyVisible ? setHistoryVisible(false) : onClose()} style={styles.sheetHeaderAction}>
              <Text style={[styles.body, { color: colors.primaryAction }]}>{historyVisible ? 'Kembali' : 'Tutup'}</Text>
            </Pressable>
            <Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>{historyVisible ? 'Riwayat program' : 'Filter peserta'}</Text>
            <View style={styles.sheetHeaderSpacer} />
          </View>
          {historyVisible ? (
            <View style={styles.sheetBody}>
              <View style={[styles.searchField, { backgroundColor: colors.surface, borderColor: colors.border }]}> 
                <MSCIcon name="search" color={colors.secondaryText} size="small" />
                <TextInput accessibilityLabel="Cari program selesai" placeholder="Cari program selesai" placeholderTextColor={colors.secondaryText} value={search} onChangeText={setSearch} style={[styles.searchInput, { color: colors.primaryText }]} />
              </View>
              <ScrollView contentContainerStyle={styles.optionList}>
                {historicalPrograms.map((program) => (
                  <FilterOption key={program.program_id} label={program.title} detail={formatProgramDate(program.ends_on, program.timezone)} selected={draft.programId === program.program_id} onPress={() => { setDraft((value) => ({ ...value, programId: program.program_id })); setHistoryVisible(false); }} />
                ))}
                {historicalPrograms.length === 0 ? <StateView kind="empty" /> : null}
              </ScrollView>
            </View>
          ) : (
            <>
              <ScrollView contentContainerStyle={styles.sheetBody}>
                <FilterSection title="Program">
                  <FilterOption label="Semua program" selected={draft.programId === null} onPress={() => setDraft((value) => ({ ...value, programId: null }))} />
                  {currentPrograms.map((program) => <FilterOption key={program.program_id} label={program.title} selected={draft.programId === program.program_id} onPress={() => setDraft((value) => ({ ...value, programId: program.program_id }))} />)}
                  <FilterOption label="Riwayat program" detail={historicalPrograms.length ? `${historicalPrograms.length} program selesai` : 'Belum ada program selesai'} trailing="chevron" onPress={() => setHistoryVisible(true)} />
                </FilterSection>
                <FilterSection title="Status penyelesaian">
                  {completionOptions.map((option) => <FilterOption key={option.value} label={option.label} selected={draft.completion === option.value} onPress={() => setDraft((value) => ({ ...value, completion: option.value }))} />)}
                </FilterSection>
                <FilterSection title="Urutkan menurut">
                  {sortOptions.map((option) => <FilterOption key={option.value} label={option.label} selected={draft.sort === option.value} onPress={() => setDraft((value) => ({ ...value, sort: option.value }))} />)}
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

function FilterOption({ label, detail, selected = false, trailing = 'check', onPress }: { label: string; detail?: string; selected?: boolean; trailing?: 'check' | 'chevron'; onPress: () => void }) {
  const { colors } = useAppTheme();
  return (
    <Pressable accessibilityRole={trailing === 'check' ? 'radio' : 'button'} accessibilityState={trailing === 'check' ? { selected } : undefined} onPress={onPress} style={({ pressed }) => [styles.filterOption, pressed && { backgroundColor: colors.secondaryBackground }]}>
      <View style={styles.flexCopy}><Text style={[styles.body, { color: colors.primaryText }]}>{label}</Text>{detail ? <Text style={[styles.caption, { color: colors.secondaryText }]}>{detail}</Text> : null}</View>
      {trailing === 'chevron' ? <Text style={[styles.chevron, { color: colors.secondaryText }]}>›</Text> : selected ? <Text style={[styles.checkmark, { color: colors.primaryAction }]}>✓</Text> : null}
    </Pressable>
  );
}

export function CoachParticipantDetailScreen({ participantId, enrollmentId, authorized }: { participantId: string; enrollmentId?: string; authorized: boolean }) {
  const query = useCoachParticipantDetail(participantId, enrollmentId, authorized);
  if (!authorized) return <StateView kind="forbidden" />;
  if (query.isPending) return <StateView kind="loading" />;
  if (query.isError) return <StateView kind="error" action={<Button label="Coba lagi" onPress={() => void query.refetch()} />} />;
  if (!query.data) return <StateView kind="empty" />;
  return <ParticipantDetail detail={query.data} />;
}

function ParticipantDetail({ detail }: { detail: CoachParticipantDetail }) {
  const { colors } = useAppTheme();
  const scrollRef = useRef<ScrollView>(null);
  const [evidenceY, setEvidenceY] = useState(0);
  const [progressY, setProgressY] = useState(0);
  const program = detail.program;
  return (
    <ScrollView ref={scrollRef} contentContainerStyle={styles.detailContent} testID="coach.participant.detail">
      <Button label="Kembali ke peserta saya" tone="secondary" icon="back" onPress={() => router.replace('/coach/participants')} />
      <Card>
        <View style={styles.profileRow}>
          <UserAvatar uri={detail.participant.avatar_url ?? undefined} label={detail.participant.display_name} size={88} />
          <View style={styles.flexCopy}>
            <Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>{detail.participant.display_name}</Text>
            <View style={styles.inlineLabel}><MSCIcon name="profile" color={colors.secondaryText} size="small" /><Text style={[styles.body, { color: colors.secondaryText }]}>{detail.participant.city || 'Kota belum dicantumkan'}</Text></View>
            {detail.enrollment?.status === 'completed' ? <StatusBadge label="Selesai" tone="success" /> : detail.enrollment ? <StatusBadge label="Aktif" tone="success" /> : null}
            {program ? <View style={[styles.inlineLabel, styles.profileProgram, { borderColor: colors.border }]}><MSCIcon name="reviewEvidence" color={colors.secondaryText} size="small" /><Text style={[styles.body, { color: colors.secondaryText }]}>{program.title}</Text></View> : null}
          </View>
        </View>
      </Card>

      {program ? (
        <Card>
          <Text style={[styles.cardTitle, { color: colors.primaryText }]}>Kemajuan program</Text>
          <ProgressBar label="Kemajuan program" value={detail.summary.progress_percentage / 100} />
          <Text style={[styles.body, { color: colors.primaryText }]}>Hari {detail.summary.current_day} dari {detail.days.length}</Text>
          <Text style={[styles.body, { color: colors.secondaryText }]}>{detail.summary.completed_step_count} dari {detail.summary.total_step_count} langkah selesai</Text>
        </Card>
      ) : <InlineMessage title="Belum ada program" message="Peserta ini belum memiliki enrollment aktif atau selesai bersama Coach ini." />}

      <DetailSection title="Riwayat berat badan">
        {detail.weigh_ins.length === 0 ? <EmptyCopy text="Timbang awal, harian, dan akhir akan tampil di sini." /> : (
          <Card>{detail.weigh_ins.map((weighIn, index) => <WeightRow key={weighIn.id} weighIn={weighIn} timeZone={program?.timezone ?? 'Asia/Makassar'} divider={index > 0} />)}</Card>
        )}
      </DetailSection>

      <DetailSection title="Ringkasan">
        <Card><View style={styles.metricsRow}><DetailMetric icon="leaderboard" value={detail.summary.total_points} label="Poin" /><DetailMetric icon="program" value={detail.summary.active_day_count} label="hari aktif" /><DetailMetric icon="reviewEvidence" value={detail.summary.evidence_count} label="bukti" /></View></Card>
      </DetailSection>

      <DetailSection title="Aktivitas terbaru">
        {detail.submissions.length === 0 ? <EmptyCopy text="Belum ada aktivitas yang dikirim." /> : <Card>{detail.submissions.slice(0, 2).map((submission, index) => <ActivityRow key={submission.id} submission={submission} divider={index > 0} />)}</Card>}
      </DetailSection>

      <View style={styles.detailActions}>
        <View style={styles.flex}><Button label="Lihat bukti" tone="secondary" onPress={() => scrollRef.current?.scrollTo({ y: evidenceY, animated: true })} /></View>
        <View style={styles.flex}><Button label="Lihat progres" onPress={() => scrollRef.current?.scrollTo({ y: progressY, animated: true })} /></View>
      </View>

      <View onLayout={(event) => setEvidenceY(event.nativeEvent.layout.y)}>
        <DetailSection title="Bukti peserta">
          {detail.submissions.length === 0 ? <EmptyCopy text="Bukti akan tampil setelah Peserta mengirim aktivitas." /> : detail.submissions.map((submission) => <EvidenceCard key={submission.id} submission={submission} timeZone={program?.timezone ?? 'Asia/Makassar'} />)}
        </DetailSection>
      </View>

      <View onLayout={(event) => setProgressY(event.nativeEvent.layout.y)}>
        <DetailSection title="Rincian progres">
          {detail.days.length === 0 ? <EmptyCopy text="Belum ada rincian hari program." /> : detail.days.map((day, index) => <ProgressDay key={day.id} day={day} initiallyExpanded={index === 0} />)}
        </DetailSection>
      </View>
    </ScrollView>
  );
}

function DetailSection({ title, children }: { title: string; children: React.ReactNode }) {
  const { colors } = useAppTheme();
  return <View style={styles.section}><Text accessibilityRole="header" style={[styles.sectionTitle, { color: colors.primaryText }]}>{title}</Text>{children}</View>;
}

function EmptyCopy({ text }: { text: string }) {
  const { colors } = useAppTheme();
  return <Card><Text style={[styles.body, { color: colors.secondaryText }]}>{text}</Text></Card>;
}

function WeightRow({ weighIn, timeZone, divider }: { weighIn: CoachParticipantDetail['weigh_ins'][number]; timeZone: string; divider: boolean }) {
  const { colors } = useAppTheme();
  return <View style={[styles.detailRow, divider && { borderTopColor: colors.border, borderTopWidth: StyleSheet.hairlineWidth }]}><View style={[styles.roundIcon, { backgroundColor: colors.secondaryBackground }]}><MSCIcon name="activity" color={colors.primaryAction} /></View><View style={styles.flexCopy}><Text style={[styles.cardTitle, { color: colors.primaryText }]}>{weightKindLabel(weighIn.kind)}</Text><Text style={[styles.body, { color: colors.secondaryText }]}>{formatDateTime(weighIn.recorded_at, timeZone)}</Text></View><Text style={[styles.metricValue, { color: colors.primaryText }]}>{weighIn.weight_kg.toLocaleString('id-ID', { maximumFractionDigits: 2 })} kg</Text></View>;
}

function DetailMetric({ icon, value, label }: { icon: 'leaderboard' | 'program' | 'reviewEvidence'; value: number; label: string }) {
  const { colors } = useAppTheme();
  return <View style={styles.detailMetric}><View style={[styles.roundIcon, { backgroundColor: colors.secondaryBackground }]}><MSCIcon name={icon} color={colors.primaryAction} /></View><Text style={[styles.metricValueLarge, { color: colors.primaryText }]}>{value.toLocaleString('id-ID')}</Text><Text style={[styles.body, { color: colors.secondaryText }]}>{label}</Text></View>;
}

function ActivityRow({ submission, divider }: { submission: CoachParticipantDetail['submissions'][number]; divider: boolean }) {
  const { colors } = useAppTheme();
  const status = submissionStatus(submission.status);
  return <View style={[styles.detailRow, divider && { borderTopColor: colors.border, borderTopWidth: StyleSheet.hairlineWidth }]}><View style={[styles.roundIcon, { backgroundColor: colors.secondaryBackground }]}><MSCIcon name={status.icon} color={colors[status.color]} /></View><View style={styles.flexCopy}><Text style={[styles.cardTitle, { color: colors.primaryText }]}>{submission.step_title}</Text><Text style={[styles.body, { color: colors.secondaryText }]}>{status.label}</Text></View></View>;
}

function EvidenceCard({ submission, timeZone }: { submission: CoachParticipantDetail['submissions'][number]; timeZone: string }) {
  const { colors } = useAppTheme();
  const status = submissionStatus(submission.status);
  return <Card><View style={styles.rowBetween}><View style={styles.flexCopy}><Text style={[styles.cardTitle, { color: colors.primaryText }]}>{submission.step_title}</Text><Text style={[styles.caption, { color: colors.secondaryText }]}>Hari {submission.day_number} • {submission.submitted_at ? formatDateTime(submission.submitted_at, timeZone) : 'Belum dikirim'}</Text></View><StatusBadge label={status.label} tone={status.tone} /></View>{submission.answers.map((answer) => <EvidenceAnswer key={answer.id} answer={answer} />)}{submission.review_note ? <InlineMessage title="Catatan pemeriksaan" message={submission.review_note} tone={submission.status === 'rejected' ? 'destructive' : 'info'} /> : null}<Button label="Buka detail bukti" tone="secondary" onPress={() => router.push(`/coach/reviews/${submission.id}` as never)} /></Card>;
}

function EvidenceAnswer({ answer }: { answer: CoachParticipantDetail['submissions'][number]['answers'][number] }) {
  const { colors } = useAppTheme();
  const [url, setUrl] = useState<string>();
  const [failed, setFailed] = useState(false);
  useEffect(() => {
    if (!answer.private_photo_path) return;
    let active = true;
    void getCoachReviewRepository().createPhotoUrl(answer.private_photo_path)
      .then((result) => { if (active) setUrl(result.url); })
      .catch(() => { if (active) setFailed(true); });
    return () => { active = false; };
  }, [answer.private_photo_path]);
  return <View style={styles.answerBlock}><Text style={[styles.bodyStrong, { color: colors.primaryText }]}>{answer.prompt}</Text>{url ? <Image accessibilityLabel={`Bukti foto, ${answer.prompt}`} resizeMode="cover" source={{ uri: url }} style={[styles.evidenceImage, { backgroundColor: colors.secondaryBackground }]} /> : failed ? <InlineMessage title="Foto tidak dapat dimuat" message="Muat ulang halaman untuk mencoba kembali." tone="destructive" /> : answer.private_photo_path ? <StateView kind="loading" /> : <Text style={[styles.body, { color: colors.secondaryText }]}>{answer.text_value ?? answer.number_value?.toLocaleString('id-ID') ?? 'Jawaban tersimpan'}</Text>}</View>;
}

function ProgressDay({ day, initiallyExpanded }: { day: CoachParticipantDetail['days'][number]; initiallyExpanded: boolean }) {
  const { colors } = useAppTheme();
  const [expanded, setExpanded] = useState(initiallyExpanded);
  const complete = day.steps.filter((step) => step.status === 'approved').length;
  return <View style={[styles.dayCard, { backgroundColor: colors.surface, borderColor: colors.border }]}><Pressable accessibilityRole="button" accessibilityState={{ expanded }} onPress={() => setExpanded((value) => !value)} style={({ pressed }) => [styles.dayHeader, pressed && { backgroundColor: colors.secondaryBackground }]}><View style={[styles.roundIcon, { backgroundColor: colors.secondaryBackground }]}><MSCIcon name="program" color={complete > 0 ? colors.info : colors.secondaryText} /></View><View style={styles.flexCopy}><Text style={[styles.cardTitle, { color: colors.primaryText }]}>Hari ke-{day.day_number}</Text><Text style={[styles.body, { color: colors.secondaryText }]}>{day.title}</Text><Text style={[styles.caption, { color: complete > 0 ? colors.info : colors.secondaryText }]}>{complete}/{day.steps.length} langkah</Text></View><Text style={[styles.expandGlyph, { color: colors.secondaryText }]}>{expanded ? '⌃' : '⌄'}</Text></Pressable>{expanded ? <View style={[styles.daySteps, { borderColor: colors.border }]}>{day.steps.map((step) => <StepStatusRow key={step.id} step={step} />)}</View> : null}</View>;
}

function StepStatusRow({ step }: { step: CoachParticipantDetail['days'][number]['steps'][number] }) {
  const { colors } = useAppTheme();
  const status = submissionStatus(step.status);
  return <View style={styles.stepRow}><View style={[styles.roundIconSmall, { backgroundColor: colors.secondaryBackground }]}><MSCIcon name={stepKindIcon(step.content_kind)} color={colors.secondaryText} size="small" /></View><Text style={[styles.cardTitle, styles.flexCopy, { color: colors.primaryText }]}>{step.title}</Text><View style={[styles.stepStatus, { backgroundColor: colors.secondaryBackground }]}><MSCIcon name={status.icon} color={colors[status.color]} size="small" /><Text style={[styles.caption, { color: colors.secondaryText }]}>{status.label}</Text></View></View>;
}

function selectedEnrollment(participant: DirectoryParticipant, programId: string | null): DirectoryEnrollment | undefined {
  if (programId) return participant.enrollments.find((enrollment) => enrollment.program_id === programId);
  return participant.enrollments.find((enrollment) => enrollment.enrollment_status === 'active') ?? participant.enrollments[0];
}

function needsAttention(enrollment: DirectoryEnrollment): boolean {
  return enrollment.enrollment_status !== 'completed' && enrollment.progress_percentage < 50;
}

function matchesCompletion(enrollment: DirectoryEnrollment, filter: CompletionFilter): boolean {
  if (filter === 'all') return true;
  if (filter === 'complete') return enrollment.enrollment_status === 'completed' || enrollment.progress_percentage === 100;
  if (filter === 'attention') return needsAttention(enrollment);
  return enrollment.enrollment_status === 'active' && !needsAttention(enrollment);
}

function compareRows(left: { participant: DirectoryParticipant; enrollment: DirectoryEnrollment }, right: { participant: DirectoryParticipant; enrollment: DirectoryEnrollment }, sort: ParticipantSort): number {
  const nameFallback = left.participant.display_name.localeCompare(right.participant.display_name, 'id-ID');
  if (sort === 'points') return right.enrollment.total_points - left.enrollment.total_points || nameFallback;
  if (sort === 'lastActivity') return new Date(right.enrollment.last_activity_at).getTime() - new Date(left.enrollment.last_activity_at).getTime() || nameFallback;
  return right.enrollment.progress_percentage - left.enrollment.progress_percentage || nameFallback;
}

function filterSummary(filters: FilterSelection, data: CoachParticipantDirectory): string {
  const program = filters.programId ? data.programs.find((item) => item.program_id === filters.programId)?.title ?? 'Program dipilih' : 'Semua program';
  const completion = completionOptions.find((item) => item.value === filters.completion)?.label ?? 'Semua status';
  const sort = sortOptions.find((item) => item.value === filters.sort)?.label ?? 'Kemajuan';
  return filters.completion === 'all' ? `${program} • ${sort}` : `${program} • ${completion} • ${sort}`;
}

function isPastProgram(program: CoachParticipantDirectory['programs'][number]): boolean {
  return program.ends_on < todayInTimeZone(program.timezone);
}

function todayInTimeZone(timeZone: string): string {
  const parts = new Intl.DateTimeFormat('en-CA', { timeZone, year: 'numeric', month: '2-digit', day: '2-digit' }).formatToParts(new Date());
  const value = (type: Intl.DateTimeFormatPartTypes) => parts.find((part) => part.type === type)?.value ?? '';
  return `${value('year')}-${value('month')}-${value('day')}`;
}

function relativeActivity(value: string): string {
  const days = Math.floor((Date.now() - new Date(value).getTime()) / 86_400_000);
  if (days <= 0) return 'Aktif hari ini';
  if (days === 1) return 'Aktif kemarin';
  if (days < 30) return `Aktif ${days} hari yang lalu`;
  const weeks = Math.floor(days / 7);
  return `Aktif ${weeks} minggu yang lalu`;
}

function formatDateTime(value: string, timeZone: string): string {
  return new Intl.DateTimeFormat('id-ID', { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit', timeZone, timeZoneName: 'short' }).format(new Date(value));
}

function formatProgramDate(value: string, timeZone: string): string {
  return new Intl.DateTimeFormat('id-ID', { dateStyle: 'long', timeZone }).format(new Date(`${value}T12:00:00Z`));
}

function weightKindLabel(kind: 'initial' | 'daily' | 'final'): string {
  return kind === 'initial' ? 'Timbang awal' : kind === 'final' ? 'Timbang akhir' : 'Timbang harian';
}

function submissionStatus(status: string): { label: string; icon: 'approved' | 'pending' | 'rejected' | 'info'; color: 'success' | 'warning' | 'destructive' | 'secondaryText'; tone: 'success' | 'warning' | 'destructive' | 'info' } {
  if (status === 'approved') return { label: 'Disetujui', icon: 'approved', color: 'success', tone: 'success' };
  if (status === 'pending') return { label: 'Menunggu pemeriksaan', icon: 'pending', color: 'warning', tone: 'warning' };
  if (status === 'rejected') return { label: 'Ditolak', icon: 'rejected', color: 'destructive', tone: 'destructive' };
  if (status === 'not_started') return { label: 'Belum dimulai', icon: 'info', color: 'secondaryText', tone: 'info' };
  return { label: 'Belum dimulai', icon: 'info', color: 'secondaryText', tone: 'info' };
}

function stepKindIcon(kind: string): 'activity' | 'content' | 'program' {
  if (kind.includes('weigh')) return 'activity';
  if (kind === 'article' || kind === 'form') return 'content';
  return 'program';
}

const styles = StyleSheet.create({
  screen: { flex: 1, minHeight: 0 },
  directoryControls: { width: '100%', maxWidth: 900, alignSelf: 'center', gap: primitiveTokens.space.medium, padding: primitiveTokens.space.medium },
  directoryList: { width: '100%', maxWidth: 900, alignSelf: 'center', paddingHorizontal: primitiveTokens.space.medium, paddingBottom: 140, gap: primitiveTokens.space.medium },
  summaryBar: { minHeight: 82, flexDirection: 'row', alignItems: 'stretch', borderWidth: 1, borderRadius: primitiveTokens.radius.large, overflow: 'hidden' },
  summaryMetric: { flex: 1, minWidth: 0, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.small, padding: primitiveTokens.space.medium },
  summaryIcon: { width: 40, height: 40, borderRadius: 20, alignItems: 'center', justifyContent: 'center' },
  verticalDivider: { width: StyleSheet.hairlineWidth, marginVertical: primitiveTokens.space.small },
  searchField: { minHeight: componentTokens.inputHeight, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.small, borderWidth: 1, borderRadius: primitiveTokens.radius.large, paddingHorizontal: primitiveTokens.space.medium },
  searchInput: { flex: 1, minWidth: 0, ...typographyTokens.body },
  filterSummary: { minHeight: 84, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.medium, borderWidth: 1, borderRadius: primitiveTokens.radius.large, padding: primitiveTokens.space.medium },
  participantRow: { flexDirection: 'row', alignItems: 'flex-start', gap: primitiveTokens.space.medium },
  rowBetween: { flexDirection: 'row', alignItems: 'flex-start', justifyContent: 'space-between', gap: primitiveTokens.space.small },
  progressLine: { flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.small },
  progressTrack: { flex: 1, height: 6, borderRadius: primitiveTokens.radius.capsule, overflow: 'hidden' },
  progressFill: { height: '100%', borderRadius: primitiveTokens.radius.capsule },
  statusWrap: { flexDirection: 'row', alignItems: 'center', flexWrap: 'wrap', gap: primitiveTokens.space.small },
  activityLabel: { flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.xSmall },
  activityDot: { width: 8, height: 8, borderRadius: 4 },
  flexCopy: { flex: 1, minWidth: 0, gap: primitiveTokens.space.xxSmall },
  flex: { flex: 1, minWidth: 150 },
  sheetOverlay: { flex: 1, justifyContent: 'flex-end' },
  filterSheet: { width: '100%', height: '90%', borderTopWidth: 1, borderTopLeftRadius: primitiveTokens.radius.prominent, borderTopRightRadius: primitiveTokens.radius.prominent, overflow: 'hidden' },
  filterSheetWide: { maxWidth: 620, alignSelf: 'center', borderWidth: 1, borderBottomWidth: 0 },
  sheetHeader: { minHeight: 72, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: primitiveTokens.space.medium },
  sheetHeaderAction: { minWidth: 80, minHeight: componentTokens.minimumTouchTarget, justifyContent: 'center' },
  sheetHeaderSpacer: { width: 80 },
  sheetBody: { flexGrow: 1, padding: primitiveTokens.space.medium, paddingBottom: primitiveTokens.space.xLarge, gap: primitiveTokens.space.large },
  optionList: { gap: primitiveTokens.space.small, paddingBottom: primitiveTokens.space.large },
  filterSection: { gap: primitiveTokens.space.xSmall },
  sectionLabel: { ...typographyTokens.label, paddingHorizontal: primitiveTokens.space.xSmall },
  optionGroup: { borderWidth: StyleSheet.hairlineWidth, borderRadius: primitiveTokens.radius.large, overflow: 'hidden' },
  filterOption: { minHeight: 62, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.small, borderBottomWidth: StyleSheet.hairlineWidth, borderBottomColor: 'rgba(127,127,127,0.25)', paddingHorizontal: primitiveTokens.space.medium, paddingVertical: primitiveTokens.space.small },
  checkmark: { fontSize: 24, lineHeight: 28, fontWeight: '700' },
  sheetActions: { flexDirection: 'row', gap: primitiveTokens.space.small, borderTopWidth: StyleSheet.hairlineWidth, padding: primitiveTokens.space.medium },
  detailContent: { width: '100%', maxWidth: 760, alignSelf: 'center', padding: primitiveTokens.space.medium, paddingBottom: 150, gap: primitiveTokens.space.large },
  profileRow: { flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.medium },
  inlineLabel: { flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.xSmall },
  profileProgram: { borderTopWidth: StyleSheet.hairlineWidth, paddingTop: primitiveTokens.space.xSmall, marginTop: primitiveTokens.space.xSmall },
  section: { gap: primitiveTokens.space.small },
  sectionTitle: typographyTokens.title,
  detailActions: { flexDirection: 'row', flexWrap: 'wrap', gap: primitiveTokens.space.small },
  metricsRow: { flexDirection: 'row', alignItems: 'stretch' },
  detailMetric: { flex: 1, minWidth: 0, alignItems: 'center', gap: primitiveTokens.space.xSmall, paddingHorizontal: primitiveTokens.space.xSmall },
  roundIcon: { width: 48, height: 48, borderRadius: 24, alignItems: 'center', justifyContent: 'center' },
  roundIconSmall: { width: 40, height: 40, borderRadius: 20, alignItems: 'center', justifyContent: 'center' },
  detailRow: { minHeight: 82, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.medium, paddingVertical: primitiveTokens.space.small },
  answerBlock: { gap: primitiveTokens.space.xSmall },
  evidenceImage: { width: '100%', height: 280, borderRadius: primitiveTokens.radius.large },
  dayCard: { borderWidth: 1, borderRadius: primitiveTokens.radius.large, overflow: 'hidden' },
  dayHeader: { minHeight: 110, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.medium, padding: primitiveTokens.space.medium },
  daySteps: { borderTopWidth: StyleSheet.hairlineWidth, paddingHorizontal: primitiveTokens.space.medium },
  stepRow: { minHeight: 76, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.small, borderBottomWidth: StyleSheet.hairlineWidth, borderBottomColor: 'rgba(127,127,127,0.22)' },
  stepStatus: { flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.xSmall, borderRadius: primitiveTokens.radius.capsule, paddingHorizontal: primitiveTokens.space.small, paddingVertical: primitiveTokens.space.xSmall },
  expandGlyph: { fontSize: 28, lineHeight: 32, fontWeight: '700' },
  heading: typographyTokens.headline,
  cardTitle: typographyTokens.bodyStrong,
  body: typographyTokens.body,
  bodyStrong: typographyTokens.bodyStrong,
  caption: typographyTokens.caption,
  numericStrong: { ...typographyTokens.bodyStrong, fontVariant: ['tabular-nums'] },
  metricValue: { ...typographyTokens.headline, fontVariant: ['tabular-nums'] },
  metricValueLarge: { ...typographyTokens.numericDisplay, fontVariant: ['tabular-nums'] },
  chevron: { fontSize: 28, lineHeight: 32 },
});
