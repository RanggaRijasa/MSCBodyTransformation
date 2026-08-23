import { useEffect, useState } from 'react';
import {
  Platform,
  Pressable,
  StyleSheet,
  Text,
  View,
} from 'react-native';

import type { PublicProgram, PublicProgramStep } from '@/features/public/public-models';
import type {
  ParticipantDayAccess,
  ParticipantEnrollment,
  ParticipantScore,
  ParticipantSubmission,
} from './participant-models';
import { ParticipantSubmissionForm } from './ParticipantSubmissionForm';
import {
  latestSubmissionForStep,
  relevantDayAccess,
  stepKindLabel,
  submissionPresentation,
} from './participant-program-policy';
import { dateFormatter, formatProgramDateRange, numberFormatter, rupiahFormatter } from '@/shared/design/formatters';
import { componentTokens, primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { MSCIcon } from '@/shared/icons/MSCIcon';
import { Button, Card, InlineMessage, ProgressBar, StatusBadge } from '@/shared/ui/primitives';

export function ProgramOffer({
  program,
  enrollment,
  onPrimaryAction,
}: {
  program: PublicProgram;
  enrollment?: ParticipantEnrollment;
  onPrimaryAction: () => void;
}) {
  const { colors } = useAppTheme();
  const price = program.pricing_mode === 'free'
    ? 'Gratis'
    : rupiahFormatter.format(program.desired_price ?? 0);
  const action = enrollment?.status === 'active'
    ? 'Buka aktivitas'
    : enrollment?.status === 'completed'
      ? 'Lihat riwayat'
      : enrollment?.status === 'pending'
        ? 'Menunggu aktivasi'
        : enrollment?.status === 'waiting_for_payment'
          ? 'Lihat pembayaran'
        : 'Gabung program';

  return (
    <View style={styles.stack} testID="participant.program.offer">
      <View
        accessibilityRole="image"
        accessibilityLabel={program.cover_alt_text ?? `Cover ${program.title}`}
        style={[styles.poster, { backgroundColor: primitiveTokens.color.nearBlack, borderColor: colors.primaryAction }]}
      >
        <View style={[styles.posterAccent, { backgroundColor: colors.primaryAction }]} />
        <MSCIcon name="program" size="large" color={colors.accent} />
        <Text style={[styles.posterEyebrow, { color: colors.accent }]}>{program.category || 'Program transformasi'}</Text>
        <Text style={[styles.posterTitle, { color: primitiveTokens.color.white }]}>{program.title}</Text>
        <Text style={[styles.posterBody, { color: '#E4E4E7' }]}>{program.summary}</Text>
      </View>

      <Card>
        <View style={styles.metaGrid}>
          <Meta label="Jadwal" value={`${formatDate(program.starts_on)} – ${formatDate(program.ends_on ?? program.starts_on)}`} />
          <Meta label="Zona waktu" value={program.timezone} />
          <Meta label="Biaya" value={price} />
          <Meta label="Aktivitas" value={`${numberFormatter.format(program.program_days.reduce((total, day) => total + day.program_steps.length, 0))} langkah`} />
        </View>
        <Button
          label={action}
          disabled={enrollment?.status === 'pending'}
          onPress={onPrimaryAction}
        />
      </Card>

      <Card>
        <Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>Tujuan program</Text>
        <Text style={[styles.body, { color: colors.secondaryText }]}>{program.summary}</Text>
        <Text style={[styles.body, { color: colors.secondaryText }]}>{program.wellness_disclaimer || 'Program ini mendukung kebiasaan wellness dan bukan pengganti saran tenaga kesehatan.'}</Text>
      </Card>
    </View>
  );
}

export function ProgramActivity({
  program,
  enrollment,
  accesses,
  submissions,
  score,
  selectedStepId,
  onOpenStep,
  onCloseStep,
}: {
  program: PublicProgram;
  enrollment: ParticipantEnrollment;
  accesses: ParticipantDayAccess[];
  submissions: ParticipantSubmission[];
  score?: ParticipantScore;
  selectedStepId?: string;
  onOpenStep: (stepId: string) => void;
  onCloseStep: () => void;
}) {
  const { colors } = useAppTheme();
  const visibleAccesses = accesses.filter((access) => access.access_state !== 'hidden');
  const initialAccess = relevantDayAccess(visibleAccesses);
  const [expandedDayId, setExpandedDayId] = useState(initialAccess?.program_day_id);
  const selectedStep = program.program_days
    .flatMap((day) => day.program_steps)
    .find((step) => step.id === selectedStepId);
  const selectedAccess = selectedStep
    ? visibleAccesses.find((access) => program.program_days.some((day) => day.id === access.program_day_id && day.program_steps.some((step) => step.id === selectedStep.id)))
    : undefined;

  useEffect(() => {
    if (Platform.OS !== 'web' || selectedStepId || !initialAccess) return;
    globalThis.document
      ?.querySelector(`[data-testid="participant.program.day.${initialAccess.day_number}"]`)
      ?.scrollIntoView({ block: 'nearest' });
  }, [initialAccess, selectedStepId]);

  if (selectedStep) {
    return (
      <StepRenderer
        step={selectedStep}
        enrollment={enrollment}
        access={selectedAccess}
        submission={latestSubmissionForStep(submissions, selectedStep.id)}
        onBack={onCloseStep}
      />
    );
  }

  return (
    <View style={styles.stack} testID="participant.program.activity">
      <Card>
        <View style={styles.rowBetween}>
          <View style={styles.flexCopy}>
            <Text style={[styles.eyebrow, { color: colors.primaryAction }]}>Program diikuti</Text>
            <Text accessibilityRole="header" style={[styles.title, { color: colors.primaryText }]}>{program.title}</Text>
          </View>
          <StatusBadge label={enrollment.status === 'completed' ? 'Selesai' : 'Aktif'} tone="success" />
        </View>
        <Text style={[styles.body, styles.programDate, { color: colors.secondaryText }]}>{formatProgramDateRange(program.starts_on, program.ends_on ?? program.starts_on)}</Text>
        {score ? <ProgressBar label="Progres program" value={score.progress_percentage / 100} /> : <InlineMessage title="Progres belum tersedia" message="Ringkasan akan tampil setelah server menghitung progres program." />}
        {score ? (
          <View style={styles.scoreRow}>
            <CompactServerValue label="Poin aktivitas" value={score.activity_points} />
            <CompactServerValue label="Peringkat" value={score.rank} />
          </View>
        ) : null}
      </Card>

      <View style={styles.sectionHeading}>
        <Text accessibilityRole="header" style={[styles.title, { color: colors.primaryText }]}>Aktivitas program</Text>
        <Text style={[styles.body, { color: colors.secondaryText }]}>Status hari dan akses berasal dari server program.</Text>
      </View>

      <ProgramDayList program={program} accesses={visibleAccesses} submissions={submissions} expandedDayId={expandedDayId} onExpandedDayChange={setExpandedDayId} onOpenStep={onOpenStep} />
    </View>
  );
}

export function ProgramDefinitionPreview({ program, role }: { program: PublicProgram; role: 'participant' | 'coach' }) {
  const { colors } = useAppTheme();
  const [expandedDayId, setExpandedDayId] = useState(program.program_days[0]?.id);
  const accesses: ParticipantDayAccess[] = program.program_days.map((day, index) => ({
    enrollment_id: program.id, program_id: program.id, program_day_id: day.id,
    day_number: day.day_number, access_state: 'available', is_current_day: index === 0,
  }));
  return <View style={styles.stack} testID="admin.program.preview.shared-renderer">
    <View style={styles.sectionHeading}><Text accessibilityRole="header" style={[styles.title, { color: colors.primaryText }]}>Aktivitas program</Text><Text style={[styles.body, { color: colors.secondaryText }]}>{role === 'participant' ? 'Peserta dapat membuka dan menyelesaikan langkah yang tersedia.' : 'Coach memantau urutan langkah dan membuka pemeriksaan sesuai kewenangan.'}</Text></View>
    <ProgramDayList program={program} accesses={accesses} submissions={[]} expandedDayId={expandedDayId} onExpandedDayChange={setExpandedDayId} onOpenStep={() => undefined} />
  </View>;
}

function ProgramDayList({ program, accesses, submissions, expandedDayId, onExpandedDayChange, onOpenStep }: { program: PublicProgram; accesses: ParticipantDayAccess[]; submissions: ParticipantSubmission[]; expandedDayId?: string; onExpandedDayChange: (id?: string) => void; onOpenStep: (id: string) => void }) {
  const { colors } = useAppTheme();
  return <>{program.program_days.map((day) => {
    const access = accesses.find((candidate) => candidate.program_day_id === day.id);
    if (!access) return null;
    const expanded = expandedDayId === day.id;
    const locked = access.access_state === 'locked';
    return <View key={day.id} style={[styles.dayCard, { backgroundColor: colors.surface, borderColor: access.is_current_day ? colors.primaryAction : colors.border }]}><Pressable testID={`participant.program.day.${day.day_number}`} accessibilityRole="button" accessibilityState={{ expanded }} accessibilityLabel={`${access.is_current_day ? 'Hari ini, ' : ''}Hari ke-${day.day_number}, ${day.title}`} onPress={() => onExpandedDayChange(expanded ? undefined : day.id)} style={styles.dayHeader}><View style={[styles.dayIcon, { backgroundColor: colors.secondaryBackground }]}><MSCIcon name={locked ? 'forbidden' : 'program'} color={locked ? colors.warning : colors.primaryAction} /></View><View style={styles.flexCopy}><Text style={[styles.cardTitle, { color: colors.primaryText }]}>{access.is_current_day ? 'Hari ini · ' : ''}Hari ke-{day.day_number}</Text><Text style={[styles.body, { color: colors.secondaryText }]}>{day.title}</Text></View><Text style={[styles.expandGlyph, { color: colors.secondaryText }]}>{expanded ? '−' : '+'}</Text></Pressable>{expanded ? <View style={[styles.dayContent, { borderColor: colors.border }]}>{locked ? <InlineMessage title="Aktivitas belum tersedia" message="Kembali saat jadwal program membuka hari ini." tone="warning" /> : day.program_steps.length ? day.program_steps.map((step) => <StepRow key={step.id} step={step} submission={latestSubmissionForStep(submissions, step.id)} readOnly={access.access_state === 'read_only'} onPress={() => onOpenStep(step.id)} />) : <InlineMessage title="Belum ada aktivitas" message="Hari ini belum memiliki langkah yang diterbitkan." />}</View> : null}</View>;
  })}</>;
}

function StepRow({
  step,
  submission,
  readOnly,
  onPress,
}: {
  step: PublicProgramStep;
  submission?: ParticipantSubmission;
  readOnly: boolean;
  onPress: () => void;
}) {
  const { colors } = useAppTheme();
  const presentation = submissionPresentation(submission?.status);
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={`${step.title}, ${presentation.label}`}
      onPress={onPress}
      style={({ pressed }) => [styles.stepRow, { opacity: pressed ? 0.7 : 1 }]}
    >
      <View style={[styles.stepIcon, { backgroundColor: colors.secondaryBackground }]}>
        <MSCIcon name={submission?.status === 'approved' ? 'approved' : readOnly ? 'info' : 'activity'} color={submission?.status === 'approved' ? colors.success : colors.primaryAction} />
      </View>
      <View style={styles.flexCopy}>
        <Text style={[styles.cardTitle, { color: colors.primaryText }]}>{step.title}</Text>
        <Text style={[styles.caption, { color: colors.secondaryText }]}>{stepKindLabel(step.content_kind)} · {presentation.label}{readOnly ? ' · Hanya baca' : ''}</Text>
      </View>
      <Text style={[styles.chevron, { color: colors.secondaryText }]}>›</Text>
    </Pressable>
  );
}

export function StepRenderer({
  step,
  enrollment,
  access,
  submission,
  onBack,
}: {
  step: PublicProgramStep;
  enrollment: ParticipantEnrollment;
  access?: ParticipantDayAccess;
  submission?: ParticipantSubmission;
  onBack: () => void;
}) {
  const { colors } = useAppTheme();
  const presentation = submissionPresentation(submission?.status);
  const readOnly = access?.access_state === 'read_only';
  const locked = access?.access_state === 'locked' || access === undefined;

  return (
    <View style={styles.stepScreen} testID="participant.step.renderer">
      <Button label="Kembali ke aktivitas" tone="secondary" icon="back" onPress={onBack} />
      <Card>
        <View style={styles.rowBetween}>
          <Text accessibilityRole="header" style={[styles.title, { color: colors.primaryText }]}>{step.title}</Text>
          <StatusBadge label={presentation.label} tone={presentation.tone} />
        </View>
        <Text style={[styles.eyebrow, { color: colors.primaryAction }]}>{stepKindLabel(step.content_kind)}</Text>
        <Text style={[styles.body, { color: colors.secondaryText }]}>{step.instructions || 'Ikuti petunjuk aktivitas yang diterbitkan program.'}</Text>
        {submission?.status === 'rejected' && submission.review_note ? (
          <InlineMessage title="Perlu diperbaiki" message={submission.review_note} tone="destructive" />
        ) : null}
      </Card>

      {locked ? <InlineMessage title="Aktivitas belum tersedia" message="Langkah ini belum dibuka oleh jadwal server program." tone="warning" /> : (
        <View style={styles.stack}>
          {step.content_kind === 'article' || step.content_kind === 'video' ? <StepContent step={step} /> : null}
          <ParticipantSubmissionForm
            step={step}
            enrollment={enrollment}
            submission={submission}
            disabled={readOnly || submission?.status === 'pending' || submission?.status === 'approved'}
          />
        </View>
      )}
    </View>
  );
}

function StepContent({ step }: { step: PublicProgramStep }) {
  switch (step.content_kind) {
    case 'article':
      return <ArticleRenderer step={step} />;
    case 'video':
      return <VideoRenderer step={step} />;
    default:
      return null;
  }
}

function ArticleRenderer({ step }: { step: PublicProgramStep }) {
  const { colors } = useAppTheme();
  return (
    <Card>
      <Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>Bacaan</Text>
      <Text style={[styles.body, { color: colors.secondaryText }]}>{step.instructions || 'Materi bacaan program.'}</Text>
      {step.media_alt_text ? <Text style={[styles.caption, { color: colors.secondaryText }]}>Media: {step.media_alt_text}</Text> : null}
    </Card>
  );
}

function VideoRenderer({ step }: { step: PublicProgramStep }) {
  const { colors } = useAppTheme();
  return (
    <Card>
      <View accessibilityRole="image" accessibilityLabel={step.media_alt_text ?? `Video ${step.title}`} style={[styles.videoFrame, { backgroundColor: primitiveTokens.color.nearBlack }]}>
        <MSCIcon name="activity" color={colors.accent} size="large" />
        <Text style={[styles.cardTitle, { color: primitiveTokens.color.white }]}>Video program</Text>
      </View>
      {step.video_required ? <InlineMessage title="Wajib ditonton" message={`Tonton minimal ${numberFormatter.format(step.video_threshold)}% sebelum mengirim aktivitas.`} /> : null}
    </Card>
  );
}

function Meta({ label, value }: { label: string; value: string }) {
  const { colors } = useAppTheme();
  return (
    <View style={styles.metaItem}>
      <Text style={[styles.caption, { color: colors.secondaryText }]}>{label}</Text>
      <Text style={[styles.cardTitle, { color: colors.primaryText }]}>{value}</Text>
    </View>
  );
}

function CompactServerValue({ label, value }: { label: string; value: number | null }) {
  const { colors } = useAppTheme();
  return (
    <View style={[styles.serverValue, { backgroundColor: colors.secondaryBackground }]}>
      <Text style={[styles.numeric, { color: colors.primaryText }]}>{value === null ? '—' : numberFormatter.format(value)}</Text>
      <Text style={[styles.caption, { color: colors.secondaryText }]}>{label}</Text>
    </View>
  );
}

function formatDate(value: string): string {
  return dateFormatter.format(new Date(`${value}T12:00:00Z`));
}

const stickyPosition = Platform.OS === 'web' ? ({ position: 'sticky' } as const) : {};

const styles = StyleSheet.create({
  stack: { gap: primitiveTokens.space.large },
  poster: { minHeight: 300, borderRadius: primitiveTokens.radius.prominent, borderWidth: 2, padding: primitiveTokens.space.xLarge, overflow: 'hidden', justifyContent: 'flex-end', gap: primitiveTokens.space.small },
  posterAccent: { position: 'absolute', top: -100, right: -70, width: 260, height: 260, borderRadius: 130, opacity: 0.8 },
  posterEyebrow: { ...typographyTokens.label, textTransform: 'uppercase', letterSpacing: 1.2 },
  posterTitle: typographyTokens.titleLarge,
  posterBody: typographyTokens.body,
  metaGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: primitiveTokens.space.medium },
  metaItem: { flexGrow: 1, flexBasis: 180, minWidth: 0, gap: primitiveTokens.space.xxSmall },
  rowBetween: { flexDirection: 'row', alignItems: 'flex-start', justifyContent: 'space-between', gap: primitiveTokens.space.medium },
  flexCopy: { flex: 1, minWidth: 0, gap: primitiveTokens.space.xxSmall },
  title: typographyTokens.title,
  heading: typographyTokens.headline,
  cardTitle: typographyTokens.bodyStrong,
  body: typographyTokens.body,
  programDate: { fontVariant: ['tabular-nums'] },
  caption: typographyTokens.caption,
  eyebrow: typographyTokens.label,
  sectionHeading: { gap: primitiveTokens.space.xxSmall },
  scoreRow: { flexDirection: 'row', flexWrap: 'wrap', gap: primitiveTokens.space.small },
  serverValue: { flex: 1, minWidth: 140, borderRadius: primitiveTokens.radius.medium, padding: primitiveTokens.space.medium, gap: primitiveTokens.space.xxSmall },
  numeric: { ...typographyTokens.numericDisplay, fontVariant: ['tabular-nums'] },
  dayCard: { borderWidth: 1, borderRadius: primitiveTokens.radius.large, overflow: 'hidden' },
  dayHeader: { minHeight: 72, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.medium, padding: primitiveTokens.space.medium },
  dayIcon: { width: 44, height: 44, borderRadius: primitiveTokens.radius.capsule, alignItems: 'center', justifyContent: 'center' },
  expandGlyph: { fontSize: 30, lineHeight: 32 },
  dayContent: { borderTopWidth: StyleSheet.hairlineWidth, padding: primitiveTokens.space.medium, gap: primitiveTokens.space.small },
  stepRow: { minHeight: 64, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.small, paddingVertical: primitiveTokens.space.xSmall },
  stepIcon: { width: 44, height: 44, borderRadius: primitiveTokens.radius.capsule, alignItems: 'center', justifyContent: 'center' },
  chevron: { fontSize: 28, lineHeight: 32 },
  stepScreen: { gap: primitiveTokens.space.large },
  stickyAction: { ...stickyPosition, zIndex: 2, borderWidth: StyleSheet.hairlineWidth, borderRadius: primitiveTokens.radius.large, padding: primitiveTokens.space.medium, gap: primitiveTokens.space.small },
  videoFrame: { minHeight: 220, borderRadius: primitiveTokens.radius.large, alignItems: 'center', justifyContent: 'center', gap: primitiveTokens.space.small },
  questionGroup: { gap: primitiveTokens.space.small },
  option: { minHeight: componentTokens.minimumTouchTarget, borderWidth: 2, borderRadius: primitiveTokens.radius.medium, padding: primitiveTokens.space.medium, justifyContent: 'center' },
  answerField: { minHeight: 96, borderWidth: 1, borderRadius: primitiveTokens.radius.medium, padding: primitiveTokens.space.medium, ...typographyTokens.body, textAlignVertical: 'top' },
});
