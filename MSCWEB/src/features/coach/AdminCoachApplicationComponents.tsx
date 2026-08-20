import { useEffect, useState } from 'react';
import { Image, Pressable, StyleSheet, Text, View } from 'react-native';

import { registerPrivateObjectUrl } from '@/shared/auth/private-cache';
import { rupiahFormatter } from '@/shared/design/formatters';
import { primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { Button, Card, Field, InlineMessage, SegmentedControl, StateView, StatusBadge, UserAvatar } from '@/shared/ui/primitives';
import { memberLevelPresentation, type CoachPaymentOrder } from './coach-experience-models';
import { getCoachExperienceRepository, type CoachApplicationQueueItem } from './coach-experience-repository';
import { useAdminCoachApplications, useAdminCoachDecision } from './coach-experience-queries';

export function AdminCoachApplications({ authorized }: { authorized: boolean }) {
  const { colors } = useAppTheme();
  const queue = useAdminCoachApplications(authorized);
  const [scope, setScope] = useState<'action' | 'all'>('action');
  const [visibleCount, setVisibleCount] = useState(20);
  if (!authorized) return <StateView kind="forbidden" />;
  if (queue.isPending) return <StateView kind="loading" />;
  if (queue.isError) return <StateView kind="error" action={<Button label="Coba lagi" onPress={() => void queue.refetch()} />} />;
  const actionable = (queue.data ?? []).filter((item) => item.aggregate.application.status === 'submitted');
  const items = scope === 'action' ? actionable : queue.data ?? [];
  const visibleItems = items.slice(0, visibleCount);
  const changeScope = (next: 'action' | 'all') => { setScope(next); setVisibleCount(20); };
  return <View style={styles.root} testID="admin.coach-applications"><SegmentedControl label="Lingkup aplikasi Coach" value={scope} onChange={changeScope} options={[{ label: `Perlu tindakan (${actionable.length})`, value: 'action' }, { label: 'Semua aplikasi', value: 'all' }]} />{items.length === 0 ? <InlineMessage title={scope === 'action' ? 'Tidak ada aplikasi yang perlu ditindak' : 'Belum ada aplikasi Coach'} message={scope === 'action' ? 'Semua aplikasi Coach sudah diproses.' : 'Aplikasi Coach akan tampil di sini saat tersedia.'} tone={scope === 'action' ? 'success' : 'info'} /> : <View style={styles.content}><Text accessibilityLiveRegion="polite" style={[styles.summary, { color: colors.secondaryText }]}>Menampilkan {visibleItems.length} dari {items.length} aplikasi</Text>{visibleItems.map((item) => <ApplicationCard key={item.aggregate.application.id} item={item} />)}{visibleItems.length < items.length ? <Button label="Muat 20 aplikasi lagi" tone="secondary" onPress={() => setVisibleCount((count) => Math.min(count + 20, items.length))} /> : null}</View>}</View>;
}

function ApplicationCard({ item }: { item: CoachApplicationQueueItem }) {
  const { colors } = useAppTheme();
  const [expanded, setExpanded] = useState(false);
  const application = item.aggregate.application;
  const level = memberLevelPresentation[application.member_level_snapshot];
  return <Card><Pressable accessibilityRole="button" accessibilityState={{ expanded }} onPress={() => setExpanded((value) => !value)}><View style={styles.rowBetween}><View style={styles.identity}><UserAvatar label={application.display_name_snapshot} /><View style={styles.flexCopy}><Text accessibilityRole="header" style={[styles.cardTitle, { color: colors.primaryText }]}>{application.display_name_snapshot}</Text><Text style={[styles.body, { color: colors.secondaryText }]}>{level.label} · {level.price ? rupiahFormatter.format(level.price) : 'Tidak memenuhi syarat'}</Text></View></View><StatusBadge label={applicationStatus(application.status)} tone={application.status === 'active' ? 'success' : application.status === 'rejected' ? 'destructive' : 'warning'} /></View></Pressable>{expanded ? <ApplicationDetail item={item} /> : null}</Card>;
}

function ApplicationDetail({ item }: { item: CoachApplicationQueueItem }) {
  const { colors } = useAppTheme();
  const decision = useAdminCoachDecision();
  const [mode, setMode] = useState<'idle' | 'approve' | 'reject'>('idle');
  const [reference, setReference] = useState(''); const [matches, setMatches] = useState(false); const [reason, setReason] = useState('');
  const application = item.aggregate.application;
  const order = item.order;
  const approve = async () => { if (!order) return; await decision.mutateAsync({ kind: 'approve', order, reference, destinationMatches: matches }); setMode('idle'); };
  const reject = async () => { if (!order) return; await decision.mutateAsync({ kind: 'reject', order, reason }); setMode('idle'); };
  return <View style={styles.detail}><View style={styles.requirements}><Requirement label="Level SC atau lebih tinggi" met={application.member_level_snapshot !== 'member'} /><Requirement label="HOM STS" met={application.has_completed_hom_sts} /><Requirement label="ICT" met={application.has_completed_ict} /><Requirement label="Bukti pembayaran dikirim" met={order?.status === 'under_review' || order?.status === 'approved'} /></View>{order ? <><Text style={[styles.bodyStrong, { color: colors.primaryText }]}>Pembayaran {rupiahFormatter.format(order.amount_minor)} · {order.status}</Text><EvidencePreview order={order} /></> : <InlineMessage title="Pembayaran belum dibuat" message="Peserta perlu menyelesaikan langkah aplikasi dan membuat permintaan pembayaran." tone="warning" />}{decision.error instanceof Error ? <InlineMessage title="Keputusan belum diproses" message={decision.error.message} tone="destructive" /> : null}{order?.status === 'under_review' && application.status === 'submitted' ? mode === 'approve' ? <View style={styles.stack}><InlineMessage title="Aktivasi atomik" message="Satu tindakan akan menyetujui pembayaran, mengaktifkan peran Coach, membuat entitlement tiga bulan, QR unik, ledger, dan audit." tone="warning" /><Field label="Referensi rekonsiliasi" value={reference} onChangeText={setReference} /><Check label="Jumlah dan tujuan pembayaran cocok" checked={matches} onPress={() => setMatches((value) => !value)} /><View style={styles.actions}><Button label="Batal" tone="secondary" onPress={() => setMode('idle')} /><Button label="Setujui dan aktifkan Coach" disabled={reference.trim().length < 4 || !matches} loading={decision.isPending} onPress={() => void approve()} /></View></View> : mode === 'reject' ? <View style={styles.stack}><Field label="Alasan penolakan" value={reason} onChangeText={setReason} multiline /><View style={styles.actions}><Button label="Batal" tone="secondary" onPress={() => setMode('idle')} /><Button label="Tolak aplikasi" tone="destructive" disabled={reason.trim().length < 5} loading={decision.isPending} onPress={() => void reject()} /></View></View> : <View style={styles.actions}><Button label="Tolak" tone="destructive" onPress={() => setMode('reject')} /><Button label="Setujui dan aktifkan Coach" onPress={() => setMode('approve')} /></View> : null}</View>;
}

function Requirement({ label, met }: { label: string; met: boolean }) { return <StatusBadge label={`${label}: ${met ? 'sesuai' : 'belum'}`} tone={met ? 'success' : 'destructive'} />; }
function Check({ label, checked, onPress }: { label: string; checked: boolean; onPress: () => void }) { const { colors } = useAppTheme(); return <Pressable accessibilityRole="checkbox" accessibilityState={{ checked }} aria-checked={checked} onPress={onPress} style={[styles.check, { borderColor: checked ? colors.primaryAction : colors.border }]}><Text style={[styles.body, { color: colors.primaryText }]}>{checked ? '✓ ' : ''}{label}</Text></Pressable>; }

function EvidencePreview({ order }: { order: CoachPaymentOrder }) {
  const { colors } = useAppTheme(); const [url, setUrl] = useState<string>(); const [failed, setFailed] = useState(false);
  useEffect(() => { let active = true; let cleanup: (() => void) | undefined; void getCoachExperienceRepository().listAttempts(order.id).then((attempts) => attempts.find((attempt) => ['submitted', 'approved', 'rejected'].includes(attempt.status))).then((attempt) => attempt ? getCoachExperienceRepository().downloadEvidence(attempt.object_path) : Promise.reject(new Error('missing'))).then((blob) => { if (!active) return; const next = URL.createObjectURL(blob); const unregister = registerPrivateObjectUrl(next); cleanup = () => { URL.revokeObjectURL(next); unregister(); }; setUrl(next); }).catch(() => { if (active) setFailed(true); }); return () => { active = false; cleanup?.(); }; }, [order.id]);
  if (failed) return <InlineMessage title="Bukti belum dapat dimuat" message="Muat ulang sebelum mengambil keputusan." tone="destructive" />;
  if (!url) return <StateView kind="loading" />;
  return <Image accessibilityLabel="Bukti pembayaran aplikasi Coach" source={{ uri: url }} resizeMode="contain" style={[styles.evidence, { backgroundColor: colors.secondaryBackground }]} />;
}

function applicationStatus(value: string) { return ({ draft: 'Draf', ineligible: 'Belum memenuhi syarat', submitted: 'Menunggu Admin', accepted_pending_payment: 'Menunggu pembayaran', active: 'Aktif', rejected: 'Ditolak', expired: 'Kedaluwarsa' } as Record<string, string>)[value] ?? value; }

const styles = StyleSheet.create({
  root: { width: '100%', gap: primitiveTokens.space.medium },
  content: { width: '100%', gap: primitiveTokens.space.medium }, summary: typographyTokens.caption,
  rowBetween: { flexDirection: 'row', alignItems: 'flex-start', justifyContent: 'space-between', flexWrap: 'wrap', gap: primitiveTokens.space.medium },
  identity: { flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.medium }, flexCopy: { flex: 1, minWidth: 0, gap: primitiveTokens.space.xxSmall },
  detail: { borderTopWidth: StyleSheet.hairlineWidth, marginTop: primitiveTokens.space.medium, paddingTop: primitiveTokens.space.medium, gap: primitiveTokens.space.medium },
  requirements: { flexDirection: 'row', flexWrap: 'wrap', gap: primitiveTokens.space.xSmall },
  stack: { gap: primitiveTokens.space.medium }, actions: { flexDirection: 'row', flexWrap: 'wrap', gap: primitiveTokens.space.small },
  check: { minHeight: 48, borderWidth: 1, borderRadius: primitiveTokens.radius.medium, padding: primitiveTokens.space.medium, justifyContent: 'center' },
  evidence: { width: '100%', height: 360, borderRadius: primitiveTokens.radius.large },
  cardTitle: typographyTokens.headline, body: typographyTokens.body, bodyStrong: typographyTokens.bodyStrong,
});
