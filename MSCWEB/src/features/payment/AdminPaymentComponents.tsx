import { router } from 'expo-router';
import { useEffect, useMemo, useState } from 'react';
import { Image, Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';

import { registerPrivateObjectUrl } from '@/shared/auth/private-cache';
import { rupiahFormatter } from '@/shared/design/formatters';
import { primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { useResponsiveLayout } from '@/shared/design/useResponsiveLayout';
import { Button, Card, Field, InlineMessage, SegmentedControl, StateView, StatusBadge, UserAvatar } from '@/shared/ui/primitives';
import { paymentStatusPresentation, type PaymentQueueItem } from './payment-models';
import { getPaymentRepository } from './payment-repository';
import { useAdminPaymentDecision, useAdminPaymentEvents, useAdminPaymentQueue, usePaymentAttempts } from './payment-queries';

type QueueScope = 'action' | 'all';

export function AdminPaymentQueue({ items, onRetry }: { items: PaymentQueueItem[]; onRetry: () => void }) {
  const { colors } = useAppTheme();
  const [scope, setScope] = useState<QueueScope>('action');
  const [programId, setProgramId] = useState('all');
  const programs = useMemo(() => [...new Map(items.map((item) => [item.program.id, item.program])).values()], [items]);
  const actionItems = items.filter((item) => item.order.status === 'under_review');
  const visible = items.filter((item) => (scope === 'all' || item.order.status === 'under_review') && (programId === 'all' || item.program.id === programId));

  return (
    <View style={styles.queueScreen} testID="admin.payment.queue">
      <View style={[styles.fixedControls, { backgroundColor: colors.background, borderColor: colors.border }]}> 
        <SegmentedControl label="Lingkup pembayaran" value={scope} onChange={setScope} options={[{ label: `Perlu tindakan (${actionItems.length})`, value: 'action' }, { label: 'Semua pembayaran', value: 'all' }]} />
        <ScrollView horizontal contentContainerStyle={styles.filterRow} showsHorizontalScrollIndicator={false} accessibilityLabel="Filter program">
          <FilterChip label="Semua program" selected={programId === 'all'} onPress={() => setProgramId('all')} />
          {programs.map((program) => <FilterChip key={program.id} label={program.title} selected={programId === program.id} onPress={() => setProgramId(program.id)} />)}
        </ScrollView>
      </View>
      <ScrollView contentContainerStyle={styles.listContent}>
        {visible.length === 0 ? <StateView kind="empty" action={<Button label="Muat ulang" tone="secondary" onPress={onRetry} />} /> : visible.map((item) => <PaymentQueueRow key={item.order.id} item={item} />)}
      </ScrollView>
    </View>
  );
}

function FilterChip({ label, selected, onPress }: { label: string; selected: boolean; onPress: () => void }) {
  const { colors } = useAppTheme();
  return <Pressable accessibilityRole="button" accessibilityState={{ selected }} onPress={onPress} style={[styles.filterChip, { borderColor: selected ? colors.primaryAction : colors.border, backgroundColor: selected ? colors.secondaryBackground : colors.surface }]}><Text style={[styles.captionStrong, { color: colors.primaryText }]}>{label}</Text></Pressable>;
}

function PaymentQueueRow({ item }: { item: PaymentQueueItem }) {
  const { colors } = useAppTheme();
  const isCompact = useResponsiveLayout() === 'compact';
  const status = paymentStatusPresentation(item.order.status);
  return (
    <Pressable accessibilityRole="button" accessibilityLabel={`${item.participant.display_name}, ${item.program.title}, ${status.label}`} onPress={() => router.push(`/admin/payments/${item.order.id}` as never)}>
      <Card>
        <View style={[styles.rowTop, isCompact && styles.compactRowTop]}>
          <View style={[styles.identityGroup, isCompact && styles.compactIdentityGroup]}>
            <UserAvatar uri={item.participant.provider_avatar_url ?? undefined} label={item.participant.display_name} />
            <View style={styles.flexCopy}>
              <Text style={[styles.cardTitle, { color: colors.primaryText }]}>{item.participant.display_name}</Text>
              <Text style={[styles.body, { color: colors.primaryText }]}>{item.program.title}</Text>
              <Text style={[styles.caption, styles.numeric, { color: colors.secondaryText }]}>{rupiahFormatter.format(item.order.amount_minor)} · {formatDateTime(item.order.evidence_submitted_at ?? item.order.created_at)}</Text>
              {isCompact ? <View style={styles.compactStatus}><StatusBadge label={status.label} tone={status.tone} /></View> : null}
            </View>
          </View>
          {!isCompact ? <StatusBadge label={status.label} tone={status.tone} /> : null}
        </View>
      </Card>
    </Pressable>
  );
}

export function AdminPaymentDetail({ orderId }: { orderId: string }) {
  const { colors } = useAppTheme();
  const isCompact = useResponsiveLayout() === 'compact';
  const queue = useAdminPaymentQueue(true);
  const attempts = usePaymentAttempts(orderId, true);
  const events = useAdminPaymentEvents(orderId, true);
  const decision = useAdminPaymentDecision();
  const item = queue.data?.find((candidate) => candidate.order.id === orderId);
  const [mode, setMode] = useState<'idle' | 'approve' | 'reject'>('idle');
  const [reason, setReason] = useState('');
  const [reference, setReference] = useState('');
  const [destinationMatches, setDestinationMatches] = useState(false);

  if (queue.isPending || attempts.isPending || events.isPending) return <StateView kind="loading" />;
  if (queue.isError || attempts.isError || events.isError) return <StateView kind="error" action={<Button label="Coba lagi" onPress={() => void Promise.all([queue.refetch(), attempts.refetch(), events.refetch()])} />} />;
  if (!item) return <StateView kind="empty" action={<Button label="Kembali ke antrean" onPress={() => router.replace('/admin/payments')} />} />;
  const { order } = item;
  const latestSubmitted = attempts.data?.find((attempt) => ['submitted', 'approved', 'rejected'].includes(attempt.status));
  const status = paymentStatusPresentation(order.status);

  const submitDecision = async () => {
    try {
      if (mode === 'approve') await decision.mutateAsync({ kind: 'approve', order, reference, destinationMatches });
      if (mode === 'reject') await decision.mutateAsync({ kind: 'reject', order, reason });
      router.replace('/admin/payments');
    } catch {
      setMode('idle');
      await Promise.all([queue.refetch(), attempts.refetch(), events.refetch()]);
    }
  };

  return (
    <View style={styles.detailScreen} testID="admin.payment.detail">
      <ScrollView contentContainerStyle={styles.detailContent}>
        <Button label="Kembali ke antrean" tone="secondary" icon="back" onPress={() => router.back()} />
        <Card>
          <View style={[styles.rowTop, isCompact && styles.compactRowTop]}>
            <View style={[styles.identityGroup, isCompact && styles.compactIdentityGroup]}>
              <UserAvatar uri={item.participant.provider_avatar_url ?? undefined} label={item.participant.display_name} />
              <View style={styles.flexCopy}>
                <Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>{item.participant.display_name}</Text>
                <Text style={[styles.body, { color: colors.secondaryText }]}>{item.program.title}</Text>
                <Text style={[styles.cardTitle, styles.numeric, { color: colors.primaryText }]}>{rupiahFormatter.format(order.amount_minor)}</Text>
                {isCompact ? <View style={styles.compactStatus}><StatusBadge label={status.label} tone={status.tone} /></View> : null}
              </View>
            </View>
            {!isCompact ? <StatusBadge label={status.label} tone={status.tone} /> : null}
          </View>
          <Detail label="ID pembayaran" value={order.id} />
          <Detail label="Tujuan saat dibuat" value={`${order.bank_name_snapshot} · ${order.account_name_snapshot} · ${order.account_reference_snapshot}`} />
        </Card>

        <View style={styles.stack}>
          <Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>Bukti pembayaran</Text>
          {latestSubmitted ? <PrivateEvidenceImage objectPath={latestSubmitted.object_path} /> : <InlineMessage title="Bukti belum tersedia" message="Jangan mengambil keputusan sebelum bukti dapat dimuat." tone="warning" />}
        </View>

        <Card>
          <Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>Riwayat percobaan</Text>
          {attempts.data?.map((attempt) => <View key={attempt.id} style={[styles.historyRow, { borderColor: colors.border }]}><Text style={[styles.cardTitle, { color: colors.primaryText }]}>Percobaan {attempt.attempt_number}</Text><Text style={[styles.caption, { color: colors.secondaryText }]}>{attempt.status} · {formatDateTime(attempt.submitted_at ?? attempt.prepared_at)}</Text>{attempt.rejection_reason ? <Text style={[styles.body, { color: colors.destructive }]}>{attempt.rejection_reason}</Text> : null}</View>)}
        </Card>

        <Card>
          <Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>Jejak status</Text>
          {events.data?.map((event) => <View key={event.id} style={[styles.historyRow, { borderColor: colors.border }]}><Text style={[styles.cardTitle, { color: colors.primaryText }]}>{eventLabel(event.event_type)}</Text><Text style={[styles.caption, { color: colors.secondaryText }]}>{formatDateTime(event.created_at)}</Text></View>)}
        </Card>
        {decision.error instanceof Error ? <InlineMessage title="Status sudah berubah" message={decision.error.message} tone="destructive" /> : null}
      </ScrollView>

      {order.status === 'under_review' ? (
        <View style={[styles.stickyActions, { backgroundColor: colors.background, borderColor: colors.border }]}> 
          {mode === 'reject' ? (
            <View style={styles.stack}>
              <Field label="Alasan penolakan" value={reason} onChangeText={setReason} multiline message="Alasan akan terlihat oleh Peserta untuk perbaikan bukti." />
              <ActionButtons onCancel={() => setMode('idle')} confirmLabel="Tolak bukti" destructive disabled={reason.trim().length < 5} loading={decision.isPending} onConfirm={() => void submitDecision()} />
            </View>
          ) : mode === 'approve' ? (
            <View style={styles.stack}>
              <InlineMessage title="Konfirmasi persetujuan" message={`${item.program.title} · ${item.participant.display_name} · ${rupiahFormatter.format(order.amount_minor)}. Persetujuan akan mengaktifkan enrollment secara atomik.`} tone="warning" />
              <Field label="Referensi rekonsiliasi" value={reference} onChangeText={setReference} message="Masukkan referensi internal, minimal 4 karakter." />
              <Pressable accessibilityRole="checkbox" accessibilityState={{ checked: destinationMatches }} aria-checked={destinationMatches} onPress={() => setDestinationMatches((value) => !value)} style={[styles.checkbox, { borderColor: destinationMatches ? colors.primaryAction : colors.border, backgroundColor: colors.surface }]}><Text style={[styles.body, { color: colors.primaryText }]}>{destinationMatches ? '✓ ' : ''}Tujuan dan jumlah cocok dengan catatan pembayaran</Text></Pressable>
              <ActionButtons onCancel={() => setMode('idle')} confirmLabel="Setujui pembayaran" disabled={reference.trim().length < 4 || !destinationMatches} loading={decision.isPending} onConfirm={() => void submitDecision()} />
            </View>
          ) : (
            <View style={styles.actionRow}><View style={styles.flex}><Button label="Tolak" tone="destructive" onPress={() => setMode('reject')} /></View><View style={styles.flex}><Button label="Setujui" onPress={() => setMode('approve')} /></View></View>
          )}
        </View>
      ) : null}
    </View>
  );
}

function ActionButtons({ onCancel, onConfirm, confirmLabel, destructive = false, disabled, loading }: { onCancel: () => void; onConfirm: () => void; confirmLabel: string; destructive?: boolean; disabled: boolean; loading: boolean }) {
  return <View style={styles.actionRow}><View style={styles.flex}><Button label="Batal" tone="secondary" onPress={onCancel} /></View><View style={styles.flex}><Button label={confirmLabel} tone={destructive ? 'destructive' : 'primary'} disabled={disabled} loading={loading} onPress={onConfirm} /></View></View>;
}

function PrivateEvidenceImage({ objectPath }: { objectPath: string }) {
  const { colors } = useAppTheme();
  const [url, setUrl] = useState<string>();
  const [failed, setFailed] = useState(false);
  const [expanded, setExpanded] = useState(false);
  useEffect(() => {
    let active = true;
    let cleanup: (() => void) | undefined;
    void getPaymentRepository().downloadEvidence(objectPath).then((blob) => {
      if (!active) return;
      const nextUrl = URL.createObjectURL(blob);
      const unregister = registerPrivateObjectUrl(nextUrl);
      cleanup = () => { URL.revokeObjectURL(nextUrl); unregister(); };
      setUrl(nextUrl);
    }).catch(() => { if (active) setFailed(true); });
    return () => { active = false; cleanup?.(); };
  }, [objectPath]);
  if (failed) return <InlineMessage title="Bukti tidak dapat dimuat" message="Muat ulang sebelum mengambil keputusan." tone="destructive" />;
  if (!url) return <StateView kind="loading" />;
  return <Pressable accessibilityRole="button" accessibilityLabel={expanded ? 'Perkecil bukti pembayaran' : 'Perbesar bukti pembayaran'} accessibilityState={{ expanded }} onPress={() => setExpanded((value) => !value)}><Image accessibilityLabel="Bukti pembayaran pribadi" resizeMode={expanded ? 'contain' : 'cover'} source={{ uri: url }} style={[styles.evidenceImage, expanded && styles.evidenceImageExpanded, { backgroundColor: colors.secondaryBackground }]} /><Text style={[styles.caption, { color: colors.secondaryText }]}>{expanded ? 'Ketuk untuk memperkecil' : 'Ketuk untuk memperbesar'}</Text></Pressable>;
}

function Detail({ label, value }: { label: string; value: string }) {
  const { colors } = useAppTheme();
  return <View style={styles.detail}><Text style={[styles.caption, { color: colors.secondaryText }]}>{label}</Text><Text selectable style={[styles.cardTitle, { color: colors.primaryText }]}>{value}</Text></View>;
}

function eventLabel(value: string) {
  return { order_created: 'Permintaan dibuat', upload_intent_created: 'Unggahan disiapkan', evidence_submitted: 'Bukti dikirim', evidence_rejected: 'Bukti ditolak', payment_approved: 'Pembayaran disetujui' }[value] ?? 'Status diperbarui';
}

function formatDateTime(value: string) {
  return new Intl.DateTimeFormat('id-ID', { dateStyle: 'medium', timeStyle: 'short', timeZone: 'Asia/Makassar' }).format(new Date(value));
}

const styles = StyleSheet.create({
  queueScreen: { flex: 1, minHeight: 0 },
  fixedControls: { gap: primitiveTokens.space.small, borderBottomWidth: StyleSheet.hairlineWidth, padding: primitiveTokens.space.medium },
  filterRow: { gap: primitiveTokens.space.xSmall },
  filterChip: { minHeight: 44, borderWidth: 1, borderRadius: primitiveTokens.radius.capsule, justifyContent: 'center', paddingHorizontal: primitiveTokens.space.medium },
  listContent: { width: '100%', maxWidth: 900, alignSelf: 'center', padding: primitiveTokens.space.large, gap: primitiveTokens.space.medium },
  detailScreen: { flex: 1, minHeight: 0 },
  detailContent: { width: '100%', maxWidth: 900, alignSelf: 'center', padding: primitiveTokens.space.large, paddingBottom: 300, gap: primitiveTokens.space.large },
  rowTop: { flexDirection: 'row', flexWrap: 'wrap', alignItems: 'flex-start', gap: primitiveTokens.space.medium },
  compactRowTop: { flexDirection: 'column' },
  identityGroup: { flex: 1, minWidth: 260, flexDirection: 'row', alignItems: 'flex-start', gap: primitiveTokens.space.medium },
  compactIdentityGroup: { width: '100%', flex: 0, minWidth: 0 },
  compactStatus: { alignSelf: 'flex-start', marginTop: primitiveTokens.space.xSmall },
  flexCopy: { flex: 1, minWidth: 0, gap: primitiveTokens.space.xxSmall },
  stack: { gap: primitiveTokens.space.medium },
  actionRow: { flexDirection: 'row', flexWrap: 'wrap', gap: primitiveTokens.space.small },
  flex: { flex: 1, minWidth: 160 },
  stickyActions: { position: 'absolute', left: 0, right: 0, bottom: 0, borderTopWidth: StyleSheet.hairlineWidth, padding: primitiveTokens.space.medium },
  checkbox: { minHeight: 48, borderWidth: 2, borderRadius: primitiveTokens.radius.medium, padding: primitiveTokens.space.medium, justifyContent: 'center' },
  evidenceImage: { width: '100%', height: 300, borderRadius: primitiveTokens.radius.large },
  evidenceImageExpanded: { height: 600 },
  historyRow: { borderTopWidth: StyleSheet.hairlineWidth, paddingTop: primitiveTokens.space.small, gap: primitiveTokens.space.xxSmall },
  detail: { gap: primitiveTokens.space.xxSmall },
  heading: typographyTokens.headline,
  cardTitle: typographyTokens.bodyStrong,
  body: typographyTokens.body,
  caption: typographyTokens.caption,
  captionStrong: { ...typographyTokens.caption, fontWeight: '700' },
  numeric: { fontVariant: ['tabular-nums'] },
});
