import { router } from 'expo-router';
import { toQR } from 'toqr';
import { useMemo, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import Svg, { Rect } from 'react-native-svg';

import { primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { useResponsiveLayout } from '@/shared/design/useResponsiveLayout';
import { MSCIcon, type MSCIconName } from '@/shared/icons/MSCIcon';
import { publicCoachMediaUrl } from '@/shared/media/public-coach-media';
import { isQrDarkModule } from '@/shared/qr/qr-matrix';
import { Button, Card, InlineMessage, StateView, StatusBadge, UserAvatar } from '@/shared/ui/primitives';
import { useCoachWorkspace } from './coach-experience-queries';
import type { CoachWorkspace } from './coach-experience-models';

type WorkspaceScreen = 'dashboard' | 'qr';

export function CoachWorkspaceContent({ authorized, screen }: { authorized: boolean; screen: WorkspaceScreen }) {
  const workspace = useCoachWorkspace(authorized);
  if (!authorized) return <StateView kind="forbidden" />;
  if (workspace.isPending) return <StateView kind="loading" />;
  if (workspace.isError) {
    return <View style={styles.state}><InlineMessage title="Akses Coach tidak aktif" message={workspace.error instanceof Error ? workspace.error.message : 'Muat ulang sesi untuk memeriksa akses.'} tone="destructive" /><Button label="Coba lagi" onPress={() => void workspace.refetch()} /></View>;
  }
  if (!workspace.data) return <StateView kind="empty" />;
  if (screen === 'dashboard') return <CoachDashboard workspace={workspace.data} />;
  return <CoachIdentifier payload={workspace.data.qr_payload} />;
}

function CoachDashboard({ workspace }: { workspace: CoachWorkspace }) {
  const { colors } = useAppTheme();
  const layout = useResponsiveLayout();
  const isCompact = layout === 'compact';
  const summary = createDashboardSummary(workspace);
  const actions: readonly { label: string; icon: MSCIconName; href: string; badge?: number; badgeTone?: 'attention' | 'primary' }[] = [
    { label: 'Periksa bukti', icon: 'reviewEvidence', href: '/coach/reviews', badge: workspace.pending_review_count, badgeTone: 'attention' },
    { label: 'Peserta saya', icon: 'participants', href: '/coach/participants', badge: workspace.assigned_participant_count },
    { label: 'Aktivitas terbaru', icon: 'activity', href: '/coach/activity' },
    { label: 'Peringkat', icon: 'leaderboard', href: '/coach/leaderboard' },
    { label: 'Program saya', icon: 'program', href: '/coach/programs' },
    { label: 'QR pendaftaran', icon: 'qr', href: '/coach/qr' },
  ];
  return (
    <ScrollView contentContainerStyle={styles.content} testID="coach.dashboard">
      <Pressable accessibilityRole="button" onPress={() => router.push('/coach/profile')}>
        <Card>
          <View style={styles.identityRow}>
            <UserAvatar uri={publicCoachMediaUrl(workspace.profile.photo_reference) ?? workspace.profile.provider_avatar_url ?? undefined} label={workspace.profile.display_name} size={72} />
            <View style={styles.flexCopy}><Text style={[styles.caption, { color: colors.secondaryText }]}>Selamat datang</Text><Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>{workspace.profile.display_name}</Text><StatusBadge label="Coach terverifikasi" tone="success" /></View>
          </View>
        </Card>
      </Pressable>
      <Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>Aksi cepat</Text>
      <View style={[styles.actionGrid, isCompact ? styles.actionGridCompact : null]} testID="coach.quick-actions">
        {actions.map((action) => <QuickAction key={action.label} {...action} compact={isCompact} />)}
      </View>
      <Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>Ringkasan pendampingan</Text>
      <Card>
        <View style={styles.summaryMetrics} testID="coach.dashboard-summary">
          <SummaryMetric icon="participants" label="peserta" value={summary.participantCount} />
          <View style={[styles.summaryDivider, { backgroundColor: colors.border }]} />
          <SummaryMetric icon="progress" label="progres" value={`${summary.averageProgress}%`} />
          <View style={[styles.summaryDivider, { backgroundColor: colors.border }]} />
          <SummaryMetric icon="activeProgram" label="program aktif" value={summary.activeProgramCount} />
        </View>
      </Card>
    </ScrollView>
  );
}

function QuickAction({ label, icon, href, badge, badgeTone = 'primary', compact }: { label: string; icon: MSCIconName; href: string; badge?: number; badgeTone?: 'attention' | 'primary'; compact: boolean }) {
  const { colors } = useAppTheme();
  const badgeBackground = badgeTone === 'attention' ? colors.accent : colors.primaryAction;
  const badgeForeground = badgeTone === 'attention' ? primitiveTokens.color.nearBlack : primitiveTokens.color.white;
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={badge ? `${label}, ${badge}` : label}
      onPress={() => router.push(href as never)}
      testID="coach.quick-action"
      style={({ hovered, pressed }) => [
        styles.actionCard,
        compact ? styles.actionCardCompact : null,
        {
          backgroundColor: pressed ? colors.secondaryBackground : colors.surface,
          borderColor: hovered ? colors.primaryAction : colors.border,
          transform: [{ scale: pressed ? 0.97 : 1 }],
        },
      ]}
    >
      <MSCIcon name={icon} color={colors.primaryText} size={compact ? 'medium' : 'large'} />
      <Text numberOfLines={2} style={[styles.bodyStrong, styles.actionLabel, compact ? styles.actionLabelCompact : null, { color: colors.primaryText }]}>{label}</Text>
      <View style={[styles.actionAccent, { backgroundColor: colors.primaryAction }]} />
      {badge !== undefined && badge > 0 ? <View style={[styles.countBadge, compact ? styles.countBadgeCompact : null, { backgroundColor: badgeBackground }]}><Text style={[styles.countBadgeText, { color: badgeForeground }]}>{badge}</Text></View> : null}
    </Pressable>
  );
}

function CoachIdentifier({ payload }: { payload: string }) {
  const { colors } = useAppTheme();
  const [message, setMessage] = useState<string>();
  const matrix = useMemo(() => toQR(payload), [payload]);
  const extent = Math.sqrt(matrix.byteLength) | 0;
  const quietZone = 4;
  const size = extent + quietZone * 2;
  const share = async () => {
    try {
      const blob = await renderQrPng(matrix, extent, quietZone);
      const file = new File([blob], 'qr-pendaftaran-coach.png', { type: 'image/png' });
      if (navigator.share && navigator.canShare?.({ files: [file] })) {
        await navigator.share({ title: 'QR pendaftaran Coach', files: [file] });
        setMessage('QR dibagikan.');
      } else {
        const link = document.createElement('a');
        link.href = URL.createObjectURL(blob); link.download = file.name; link.click();
        URL.revokeObjectURL(link.href);
        setMessage('Gambar QR diunduh.');
      }
    } catch { setMessage('QR belum dapat dibagikan. Coba lagi.'); }
  };
  return <ScrollView contentContainerStyle={styles.content} testID="coach.qr"><BackButton /><Card><Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>QR pendaftaran</Text><View style={styles.qrFrame}><Svg accessibilityLabel="QR pendaftaran Coach" width="100%" height="100%" viewBox={`0 0 ${size} ${size}`}><Rect width={size} height={size} fill="#ffffff" />{[...matrix].map((value, index) => isQrDarkModule(value) ? <Rect key={index} x={(index % extent) + quietZone} y={Math.floor(index / extent) + quietZone} width="1" height="1" fill="#000000" /> : null)}</Svg></View><Text style={[styles.body, { color: colors.secondaryText }]}>Minta Peserta memindai QR ini saat memilih program. Kode internal tidak ditampilkan atau dapat disalin.</Text><Button label="Bagikan QR Coach" icon="qr" onPress={() => void share()} />{message ? <Text style={[styles.caption, { color: colors.secondaryText }]}>{message}</Text> : null}</Card></ScrollView>;
}

function BackButton() { return <Button label="Kembali ke dashboard" tone="secondary" icon="back" onPress={() => router.back()} />; }

function SummaryMetric({ icon, label, value }: { icon: MSCIconName; label: string; value: number | string }) {
  const { colors } = useAppTheme();
  return (
    <View
      accessible
      accessibilityLabel={`${value} ${label}`}
      style={styles.summaryMetric}
      testID="coach.dashboard-summary-metric"
    >
      <MSCIcon name={icon} color={colors.secondaryText} size="medium" />
      <Text style={[styles.summaryValue, { color: colors.primaryText }]}>{value}</Text>
      <Text style={[styles.summaryLabel, { color: colors.secondaryText }]}>{label}</Text>
    </View>
  );
}

function createDashboardSummary(workspace: CoachWorkspace) {
  const primaryEnrollmentByParticipant = new Map<string, CoachWorkspace['participants'][number]>();
  for (const participant of workspace.participants) {
    const current = primaryEnrollmentByParticipant.get(participant.participant_id);
    if (!current || (current.enrollment_status !== 'active' && participant.enrollment_status === 'active')) {
      primaryEnrollmentByParticipant.set(participant.participant_id, participant);
    }
  }
  const primaryEnrollments = [...primaryEnrollmentByParticipant.values()];
  const averageProgress = primaryEnrollments.length === 0
    ? 0
    : Math.floor(primaryEnrollments.reduce((total, participant) => total + participant.progress_percentage, 0) / primaryEnrollments.length);
  return {
    participantCount: workspace.assigned_participant_count,
    averageProgress,
    activeProgramCount: workspace.programs.filter((program) => program.status === 'active').length,
  };
}

async function renderQrPng(matrix: Uint8Array, extent: number, quietZone: number): Promise<Blob> {
  const scale = 12;
  const canvas = document.createElement('canvas');
  canvas.width = canvas.height = (extent + quietZone * 2) * scale;
  const context = canvas.getContext('2d');
  if (!context) throw new Error('canvas_unavailable');
  context.fillStyle = '#ffffff'; context.fillRect(0, 0, canvas.width, canvas.height);
  context.fillStyle = '#000000';
  matrix.forEach((value, index) => { if (isQrDarkModule(value)) context.fillRect(((index % extent) + quietZone) * scale, (Math.floor(index / extent) + quietZone) * scale, scale, scale); });
  return new Promise((resolve, reject) => canvas.toBlob((blob) => blob ? resolve(blob) : reject(new Error('png_unavailable')), 'image/png'));
}

const styles = StyleSheet.create({
  state: { width: '100%', maxWidth: 720, alignSelf: 'center', padding: primitiveTokens.space.large, gap: primitiveTokens.space.medium },
  content: { width: '100%', maxWidth: 960, alignSelf: 'center', padding: primitiveTokens.space.large, paddingBottom: 140, gap: primitiveTokens.space.large },
  identityRow: { flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.medium },
  rowBetween: { flexDirection: 'row', alignItems: 'flex-start', justifyContent: 'space-between', gap: primitiveTokens.space.medium, flexWrap: 'wrap' },
  flexCopy: { flex: 1, minWidth: 0, gap: primitiveTokens.space.xxSmall },
  heading: typographyTokens.title,
  cardTitle: typographyTokens.headline,
  body: typographyTokens.body,
  bodyStrong: typographyTokens.bodyStrong,
  caption: typographyTokens.caption,
  numeric: { ...typographyTokens.body, fontVariant: ['tabular-nums'] },
  numericStrong: { ...typographyTokens.bodyStrong, fontVariant: ['tabular-nums'] },
  actionGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: primitiveTokens.space.medium },
  actionGridCompact: { gap: primitiveTokens.space.xSmall },
  actionCard: { minHeight: 148, flexGrow: 1, flexBasis: '30%', maxWidth: '32%', borderWidth: 1, borderRadius: primitiveTokens.radius.large, padding: primitiveTokens.space.large, justifyContent: 'center', alignItems: 'center', gap: primitiveTokens.space.small, position: 'relative' },
  actionCardCompact: { minHeight: 136, paddingHorizontal: primitiveTokens.space.xSmall, paddingVertical: primitiveTokens.space.medium, gap: primitiveTokens.space.xSmall },
  actionLabel: { textAlign: 'center' },
  actionLabelCompact: { fontSize: 14, lineHeight: 19 },
  actionAccent: { width: 30, height: 3, borderRadius: primitiveTokens.radius.capsule },
  countBadge: { position: 'absolute', top: 12, right: 12, minWidth: 28, height: 28, borderRadius: 14, alignItems: 'center', justifyContent: 'center', paddingHorizontal: 7 },
  countBadgeCompact: { top: 8, right: 8, minWidth: 24, height: 24, borderRadius: 12, paddingHorizontal: 6 },
  countBadgeText: { fontWeight: '800' },
  summaryMetrics: { minHeight: 104, flexDirection: 'row', alignItems: 'center' },
  summaryMetric: { flex: 1, minWidth: 0, minHeight: 88, alignSelf: 'stretch', alignItems: 'center', justifyContent: 'center', gap: primitiveTokens.space.xxSmall, paddingHorizontal: primitiveTokens.space.xxSmall },
  summaryDivider: { width: StyleSheet.hairlineWidth, height: 64 },
  summaryValue: { fontSize: 28, lineHeight: 32, fontWeight: '900', fontVariant: ['tabular-nums'] },
  summaryLabel: { ...typographyTokens.body, textAlign: 'center' },
  qrFrame: { width: '100%', maxWidth: 440, aspectRatio: 1, alignSelf: 'center', backgroundColor: '#ffffff', padding: primitiveTokens.space.small, borderRadius: primitiveTokens.radius.large },
});
