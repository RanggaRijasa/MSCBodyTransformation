import { router } from 'expo-router';
import type { ReactNode } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';

import { numberFormatter } from '@/shared/design/formatters';
import { componentTokens, primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { useResponsiveLayout } from '@/shared/design/useResponsiveLayout';
import { MSCIcon, type MSCIconName } from '@/shared/icons/MSCIcon';
import { Button, Card, InlineMessage, StateView } from '@/shared/ui/primitives';
import { useAdminDashboard, useAdminMutation } from './admin-queries';
import type { AdminDashboard } from './admin-models';

export function AdminDashboardExperience({ authorized }: { authorized: boolean }) {
  const { colors } = useAppTheme();
  const dashboard = useAdminDashboard(authorized);
  const mutation = useAdminMutation();
  const layout = useResponsiveLayout();
  if (!authorized) return <StateView kind="forbidden" />;
  if (dashboard.isPending) return <StateView kind="loading" />;
  if (dashboard.isError || !dashboard.data) return <StateView kind="error" action={<Button label="Coba lagi" onPress={() => void dashboard.refetch()} />} />;
  const snapshot = dashboard.data;
  return (
    <ScrollView contentContainerStyle={[styles.screen, layout === 'wide' && styles.screenWide]} testID="admin.dashboard">
      <View style={styles.intro}>
        <Text accessibilityRole="header" style={[styles.introTitle, { color: colors.primaryText }]}>Kendali operasional hari ini</Text>
        <Text style={[styles.body, { color: colors.secondaryText }]}>Data Supabase lokal.</Text>
        {dashboard.isFetching ? <Text accessibilityLiveRegion="polite" style={[styles.caption, { color: colors.info }]}>Memperbarui data operasional…</Text> : null}
      </View>
      <AttentionSection snapshot={snapshot} />
      <QuickActions busy={mutation.isPending} onCreate={() => void mutation.mutateAsync({ kind: 'createProgram' }).then((id) => router.push(`/admin/programs/${id}` as never))} />
      <DailyOverview snapshot={snapshot} />
      <RecentAudit snapshot={snapshot} />
      {mutation.error instanceof Error ? <InlineMessage title="Aksi belum selesai" message={mutation.error.message} tone="destructive" /> : null}
    </ScrollView>
  );
}

function AttentionSection({ snapshot }: { snapshot: AdminDashboard }) {
  const total = snapshot.pending_reviews + snapshot.pending_coach_approvals + snapshot.pending_payments;
  return <SectionTitle title="Perlu tindakan">{total === 0 ? <Card><InlineMessage title="Tidak ada tindakan mendesak" message="Semua antrean operasional sudah tertangani." tone="success" /></Card> : <Card>
    <AttentionRow icon="pending" count={snapshot.pending_reviews} title="Pemeriksaan tertunda" subtitle="Bukti peserta menunggu keputusan Coach." onPress={() => router.push('/admin/operations?scope=evidence' as never)} testID="admin.dashboard.attention.reviews" />
    <AttentionRow icon="participants" count={snapshot.pending_coach_approvals} title="Persetujuan Coach" subtitle="Akun baru perlu ditinjau." onPress={() => router.push('/admin/people?scope=coach&pending=1' as never)} testID="admin.dashboard.attention.coachApprovals" />
    <AttentionRow icon="bank" count={snapshot.pending_payments} title="Pembayaran manual" subtitle="Bukti pembayaran perlu diperiksa Admin." onPress={() => router.push('/admin/payments' as never)} testID="admin.dashboard.attention.payments" />
  </Card>}</SectionTitle>;
}

function AttentionRow({ icon, count, title, subtitle, onPress, testID }: { icon: MSCIconName; count: number; title: string; subtitle: string; onPress: () => void; testID?: string }) {
  const { colors } = useAppTheme();
  if (count === 0) return null;
  return <Pressable accessibilityRole="button" accessibilityLabel={`${count}, ${title}, ${subtitle}`} onPress={onPress} testID={testID} style={({ pressed }) => [styles.attentionRow, { borderColor: colors.border, opacity: pressed ? 0.72 : 1 }]}>
    <View style={[styles.attentionIcon, { backgroundColor: colors.podiumGoldSurface }]}><MSCIcon name={icon} color={colors.podiumGold} /></View>
    <View style={[styles.countBadge, { backgroundColor: colors.accent }]}><Text style={[styles.count, { color: primitiveTokens.color.black }]}>{numberFormatter.format(count)}</Text></View>
    <View style={styles.flex}><Text style={[styles.cardTitle, { color: colors.primaryText }]}>{title}</Text><Text style={[styles.caption, { color: colors.secondaryText }]}>{subtitle}</Text></View>
    <MSCIcon name="chevron" color={colors.secondaryText} />
  </Pressable>;
}

function QuickActions({ busy, onCreate }: { busy: boolean; onCreate: () => void }) {
  return <SectionTitle title="Akses cepat"><View style={styles.quickGrid} testID="admin.dashboard.quickActions">
    <QuickAction icon="plus" title="Buat program" primary onPress={onCreate} disabled={busy} testID="admin.dashboard.action.createProgram" />
    <QuickAction icon="image" title="Tambah poster" onPress={() => router.push('/admin/content?create=poster' as never)} testID="admin.dashboard.action.addWinnerPoster" />
  </View></SectionTitle>;
}

function QuickAction({ icon, title, primary = false, onPress, disabled = false, testID }: { icon: MSCIconName; title: string; primary?: boolean; onPress: () => void; disabled?: boolean; testID: string }) {
  const { colors } = useAppTheme();
  return <Pressable accessibilityRole="button" accessibilityState={{ disabled }} disabled={disabled} onPress={onPress} testID={testID} style={({ pressed }) => [styles.quickAction, { backgroundColor: colors.surface, borderColor: colors.border, opacity: disabled ? 0.5 : pressed ? 0.72 : 1, transform: [{ scale: pressed ? 0.98 : 1 }] }]}> 
    <View style={styles.quickActionHeader}><View style={[styles.quickIcon, { backgroundColor: primary ? colors.primaryTintSurface : colors.secondaryBackground }]}><MSCIcon name={icon} color={primary ? colors.primaryAction : colors.primaryText} /></View><MSCIcon name="chevron" color={colors.secondaryText} /></View>
    <Text style={[styles.cardTitle, { color: colors.primaryText }]}>{title}</Text>
  </Pressable>;
}

function DailyOverview({ snapshot }: { snapshot: AdminDashboard }) {
  return <SectionTitle title="Gambaran hari ini"><Card><View style={styles.metrics}>
    <Metric icon="activeProgram" value={snapshot.program_counts.active} label="Program aktif" testID="admin.dashboard.metric.activePrograms" />
    <Metric icon="participants" value={snapshot.active_participant_count} label="Peserta aktif" showDivider testID="admin.dashboard.metric.activeParticipants" />
    <Metric icon="program" value={snapshot.program_counts.scheduled} label="Terjadwal" showDivider testID="admin.dashboard.metric.scheduled" />
  </View></Card></SectionTitle>;
}

function Metric({ icon, value, label, showDivider = false, testID }: { icon: MSCIconName; value: number; label: string; showDivider?: boolean; testID: string }) {
  const { colors } = useAppTheme();
  return <View testID={testID} style={[styles.metric, showDivider && styles.metricDivider, { borderColor: colors.border }]}><MSCIcon name={icon} color={colors.primaryAction} /><Text style={[styles.metricValue, { color: colors.primaryText }]}>{numberFormatter.format(value)}</Text><Text style={[styles.metricLabel, { color: colors.secondaryText }]}>{label}</Text></View>;
}

function RecentAudit({ snapshot }: { snapshot: AdminDashboard }) {
  const { colors } = useAppTheme();
  return <SectionTitle title="Aktivitas terbaru"><Card>{snapshot.audit_events.length === 0 ? <Text style={[styles.body, { color: colors.secondaryText }]}>Belum ada aktivitas Admin.</Text> : snapshot.audit_events.map((event, index) => <View key={event.id} style={[styles.auditRow, index > 0 && { borderColor: colors.border }]}><View style={[styles.auditIcon, { backgroundColor: colors.secondaryBackground }]}><MSCIcon name="clipboard" color={colors.primaryAction} /></View><View style={styles.flex}><Text style={[styles.bodyStrong, { color: colors.primaryText }]}>{auditLabel(event.kind)}</Text><Text style={[styles.body, { color: colors.secondaryText }]}>{event.summary}</Text><Text style={[styles.caption, { color: colors.secondaryText }]}>{formatDateTime(event.created_at)}</Text></View></View>)}</Card></SectionTitle>;
}

function SectionTitle({ title, children }: { title: string; children: ReactNode }) { const { colors } = useAppTheme(); return <View style={styles.section}><Text accessibilityRole="header" style={[styles.sectionTitle, { color: colors.primaryText }]}>{title}</Text>{children}</View>; }
function auditLabel(kind: string) { return ({ program_created: 'Draft program dibuat', program_updated: 'Draft program diperbarui', program_published: 'Program diterbitkan', program_archived: 'Program diarsipkan', coach_application_decided: 'Pengajuan Coach diputuskan', payment_approved: 'Pembayaran disetujui', score_adjusted: 'Poin disesuaikan', winners_locked: 'Pemenang dikunci' } as Record<string, string>)[kind] ?? 'Aktivitas Admin'; }
function formatDateTime(value: string) { return new Intl.DateTimeFormat('id-ID', { dateStyle: 'medium', timeStyle: 'short', timeZone: 'Asia/Makassar' }).format(new Date(value)); }

const styles = StyleSheet.create({
  screen: { width: '100%', maxWidth: componentTokens.contentMaxWidth, alignSelf: 'center', padding: primitiveTokens.space.medium, paddingBottom: 140, gap: primitiveTokens.space.large }, screenWide: { maxWidth: 1_200, padding: primitiveTokens.space.xLarge },
  intro: { gap: primitiveTokens.space.xxSmall }, introTitle: typographyTokens.headline, body: typographyTokens.body, bodyStrong: typographyTokens.bodyStrong, caption: typographyTokens.caption, cardTitle: typographyTokens.bodyStrong,
  section: { gap: primitiveTokens.space.small }, sectionTitle: typographyTokens.headline,
  attentionRow: { minHeight: 76, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.small, borderTopWidth: StyleSheet.hairlineWidth, paddingVertical: primitiveTokens.space.small }, attentionIcon: { width: 48, height: 48, borderRadius: primitiveTokens.radius.medium, alignItems: 'center', justifyContent: 'center' }, countBadge: { minWidth: 38, height: 38, borderRadius: primitiveTokens.radius.small, alignItems: 'center', justifyContent: 'center', paddingHorizontal: primitiveTokens.space.xSmall }, count: typographyTokens.headline,
  quickGrid: { flexDirection: 'row', gap: primitiveTokens.space.small }, quickAction: { flex: 1, minWidth: 0, minHeight: 124, borderWidth: 1, borderRadius: primitiveTokens.radius.large, padding: primitiveTokens.space.medium, justifyContent: 'space-between', gap: primitiveTokens.space.medium }, quickActionHeader: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: primitiveTokens.space.small }, quickIcon: { width: 48, height: 48, borderRadius: primitiveTokens.radius.medium, alignItems: 'center', justifyContent: 'center' },
  metrics: { flexDirection: 'row' }, metric: { flex: 1, minWidth: 0, alignItems: 'center', gap: primitiveTokens.space.xxSmall, paddingHorizontal: primitiveTokens.space.xSmall, paddingVertical: primitiveTokens.space.small }, metricDivider: { borderLeftWidth: StyleSheet.hairlineWidth }, metricValue: { ...typographyTokens.numericDisplay, fontVariant: ['tabular-nums'] }, metricLabel: { ...typographyTokens.caption, textAlign: 'center' },
  auditRow: { flexDirection: 'row', gap: primitiveTokens.space.small, paddingVertical: primitiveTokens.space.small, borderTopWidth: StyleSheet.hairlineWidth }, auditIcon: { width: 40, height: 40, borderRadius: primitiveTokens.radius.small, alignItems: 'center', justifyContent: 'center' }, flex: { flex: 1, minWidth: 0 },
});
