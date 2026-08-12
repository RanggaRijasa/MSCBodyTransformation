import { router } from 'expo-router';
import { useEffect, useMemo, useRef, useState } from 'react';
import { Image, Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';

import type { CoachReviewItem } from './coach-review-models';
import { useCoachReviewDecision, useCoachReviews } from './coach-review-queries';
import { getCoachReviewRepository } from './coach-review-repository';
import { primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { Button, Card, Field, InlineMessage, SegmentedControl, StateView, StatusBadge, UserAvatar } from '@/shared/ui/primitives';

type ReviewScope = 'action' | 'all';

export function CoachReviewQueue({ items, onRetry }: { items: CoachReviewItem[]; onRetry: () => void }) {
  const { colors } = useAppTheme();
  const [scope, setScope] = useState<ReviewScope>('action');
  const [programId, setProgramId] = useState<string>('all');
  const programs = useMemo(() => [...new Map(items.map((item) => [item.program.id, item.program])).values()], [items]);
  const pendingCount = items.filter((item) => item.status === 'pending').length;
  const visible = items.filter((item) => (scope === 'all' || item.status === 'pending') && (programId === 'all' || item.program.id === programId));

  return (
    <View style={styles.screen} testID="coach.review.queue">
      <View style={[styles.fixedControls, { backgroundColor: colors.background, borderColor: colors.border }]}> 
        <SegmentedControl
          label="Lingkup bukti"
          value={scope}
          onChange={setScope}
          options={[{ label: `Perlu tindakan (${pendingCount})`, value: 'action' }, { label: 'Semua bukti', value: 'all' }]}
        />
        <ScrollView horizontal contentContainerStyle={styles.filterRow} showsHorizontalScrollIndicator={false} accessibilityLabel="Filter program">
          <FilterChip label="Semua program" selected={programId === 'all'} onPress={() => setProgramId('all')} />
          {programs.map((program) => <FilterChip key={program.id} label={program.title} selected={programId === program.id} onPress={() => setProgramId(program.id)} />)}
        </ScrollView>
      </View>
      <ScrollView contentContainerStyle={styles.listContent}>
        {visible.length === 0 ? (
          <StateView kind="empty" action={<Button label="Muat ulang" tone="secondary" onPress={onRetry} />} />
        ) : visible.map((item) => <CoachReviewRow key={item.id} item={item} />)}
      </ScrollView>
    </View>
  );
}

function FilterChip({ label, selected, onPress }: { label: string; selected: boolean; onPress: () => void }) {
  const { colors } = useAppTheme();
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ selected }}
      onPress={onPress}
      style={[styles.filterChip, { borderColor: selected ? colors.primaryAction : colors.border, backgroundColor: selected ? colors.secondaryBackground : colors.surface }]}
    >
      <Text style={[styles.captionStrong, { color: colors.primaryText }]}>{label}</Text>
    </Pressable>
  );
}

function CoachReviewRow({ item }: { item: CoachReviewItem }) {
  const { colors } = useAppTheme();
  return (
    <Pressable accessibilityRole="button" accessibilityLabel={`${item.participant.display_name}, ${item.step.title}, ${statusLabel(item.status)}`} onPress={() => router.push(`/coach/reviews/${item.id}` as never)}>
      <Card>
        <View style={styles.rowTop}>
          <UserAvatar uri={item.participant.avatar_url ?? undefined} label={item.participant.display_name} />
          <View style={styles.flexCopy}>
            <Text style={[styles.cardTitle, { color: colors.primaryText }]}>{item.participant.display_name}</Text>
            <Text style={[styles.body, { color: colors.primaryText }]}>{item.step.title}</Text>
            <Text style={[styles.caption, { color: colors.secondaryText }]}>{item.program.title} · Hari ke-{item.day.day_number}</Text>
            <Text style={[styles.caption, { color: colors.secondaryText }]}>{formatDateTime(item.submitted_at)}</Text>
          </View>
          <Text accessibilityElementsHidden style={[styles.chevron, { color: colors.secondaryText }]}>›</Text>
        </View>
        <StatusBadge label={statusLabel(item.status)} tone={statusTone(item.status)} />
      </Card>
    </Pressable>
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
        <Button label="Kembali ke antrean" tone="secondary" icon="back" onPress={() => router.back()} />
        <Card>
          <View style={styles.rowTop}>
            <UserAvatar uri={item.participant.avatar_url ?? undefined} label={item.participant.display_name} />
            <View style={styles.flexCopy}>
              <Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>{item.participant.display_name}</Text>
              <Text style={[styles.body, { color: colors.secondaryText }]}>{item.program.title} · Hari ke-{item.day.day_number}</Text>
              <Text style={[styles.body, { color: colors.secondaryText }]}>{item.step.title}</Text>
            </View>
            <StatusBadge label={statusLabel(item.status)} tone={statusTone(item.status)} />
          </View>
        </Card>
        <View style={styles.stack}>
          <Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>Bukti yang dikirim</Text>
          {item.answers.map((answer) => (
            <Card key={answer.id}>
              <Text style={[styles.cardTitle, { color: colors.primaryText }]}>{answer.prompt}</Text>
              {answer.private_photo_path ? <PrivateReviewImage objectPath={answer.private_photo_path} /> : (
                <Text style={[styles.body, { color: colors.secondaryText }]}>{answer.text_value ?? answer.number_value?.toLocaleString('id-ID') ?? (answer.selected_option_ids.length ? 'Pilihan tersimpan' : 'Belum dijawab')}</Text>
              )}
            </Card>
          ))}
        </View>
        {item.review_note ? <InlineMessage title="Catatan pemeriksaan" message={item.review_note} tone={item.status === 'rejected' ? 'destructive' : 'info'} /> : null}
        {decision.error instanceof Error ? <InlineMessage title="Status sudah berubah" message={decision.error.message} tone="destructive" /> : null}
      </ScrollView>
      {item.status === 'pending' ? (
        <View style={[styles.stickyActions, { backgroundColor: colors.background, borderColor: colors.border }]}> 
          {mode === 'reject' ? (
            <View style={styles.stack}>
              <Field label="Alasan penolakan" value={reason} onChangeText={setReason} multiline message="Alasan akan terlihat oleh Peserta agar bukti dapat diperbaiki." />
              <View style={styles.actionRow}>
                <View style={styles.flex}><Button label="Batal" tone="secondary" onPress={() => setMode('idle')} /></View>
                <View style={styles.flex}><Button label="Tolak bukti" tone="destructive" loading={decision.isPending} disabled={!reason.trim()} onPress={() => void submitDecision('rejected')} /></View>
              </View>
            </View>
          ) : mode === 'approve' ? (
            <View style={styles.stack}>
              <InlineMessage title="Setujui bukti?" message="Poin aktivitas akan dihitung satu kali oleh server." tone="warning" />
              <View style={styles.actionRow}>
                <View style={styles.flex}><Button label="Batal" tone="secondary" onPress={() => setMode('idle')} /></View>
                <View style={styles.flex}><Button label="Setujui bukti" loading={decision.isPending} onPress={() => void submitDecision('approved')} /></View>
              </View>
            </View>
          ) : (
            <View style={styles.actionRow}>
              <View style={styles.flex}><Button label="Tolak" tone="destructive" onPress={() => setMode('reject')} /></View>
              <View style={styles.flex}><Button label="Setujui" onPress={() => setMode('approve')} /></View>
            </View>
          )}
        </View>
      ) : null}
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
    <Pressable accessibilityRole="button" accessibilityLabel={expanded ? 'Perkecil bukti foto' : 'Perbesar bukti foto'} accessibilityState={{ expanded }} onPress={() => setExpanded((value) => !value)}>
      <Image accessibilityLabel="Bukti foto peserta" resizeMode={expanded ? 'contain' : 'cover'} source={{ uri: url }} style={[styles.reviewImage, expanded && styles.reviewImageExpanded, { backgroundColor: colors.secondaryBackground }]} />
      <Text style={[styles.caption, { color: colors.secondaryText }]}>{expanded ? 'Ketuk untuk memperkecil' : 'Ketuk untuk memperbesar'}</Text>
    </Pressable>
  );
}

function statusLabel(status: CoachReviewItem['status']): string {
  if (status === 'pending') return 'Perlu tindakan';
  if (status === 'approved') return 'Disetujui';
  if (status === 'rejected') return 'Ditolak';
  return 'Digantikan';
}

function statusTone(status: CoachReviewItem['status']): 'success' | 'warning' | 'destructive' | 'info' {
  if (status === 'approved') return 'success';
  if (status === 'pending') return 'warning';
  if (status === 'rejected') return 'destructive';
  return 'info';
}

function formatDateTime(value: string): string {
  return new Intl.DateTimeFormat('id-ID', { dateStyle: 'medium', timeStyle: 'short', timeZone: 'Asia/Makassar' }).format(new Date(value));
}

const styles = StyleSheet.create({
  screen: { flex: 1, minHeight: 0 },
  fixedControls: { gap: primitiveTokens.space.small, borderBottomWidth: StyleSheet.hairlineWidth, padding: primitiveTokens.space.medium },
  filterRow: { gap: primitiveTokens.space.xSmall },
  filterChip: { minHeight: 44, borderWidth: 1, borderRadius: primitiveTokens.radius.capsule, justifyContent: 'center', paddingHorizontal: primitiveTokens.space.medium },
  listContent: { width: '100%', maxWidth: 900, alignSelf: 'center', padding: primitiveTokens.space.large, gap: primitiveTokens.space.medium },
  detailScreen: { flex: 1, minHeight: 0 },
  detailContent: { width: '100%', maxWidth: 900, alignSelf: 'center', padding: primitiveTokens.space.large, paddingBottom: 220, gap: primitiveTokens.space.large },
  rowTop: { flexDirection: 'row', alignItems: 'flex-start', gap: primitiveTokens.space.medium },
  flexCopy: { flex: 1, minWidth: 0, gap: primitiveTokens.space.xxSmall },
  stack: { gap: primitiveTokens.space.medium },
  actionRow: { flexDirection: 'row', flexWrap: 'wrap', gap: primitiveTokens.space.small },
  flex: { flex: 1, minWidth: 150 },
  stickyActions: { position: 'absolute', left: 0, right: 0, bottom: 0, borderTopWidth: StyleSheet.hairlineWidth, padding: primitiveTokens.space.medium },
  reviewImage: { width: '100%', height: 280, borderRadius: primitiveTokens.radius.large },
  reviewImageExpanded: { height: 560 },
  heading: typographyTokens.headline,
  cardTitle: typographyTokens.bodyStrong,
  body: typographyTokens.body,
  caption: typographyTokens.caption,
  captionStrong: { ...typographyTokens.caption, fontWeight: '700' },
  chevron: { fontSize: 28, lineHeight: 32 },
});
