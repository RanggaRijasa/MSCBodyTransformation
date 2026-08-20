import { router } from 'expo-router';
import { useEffect, useRef, useState } from 'react';
import { Image, Platform, Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';

import { rupiahFormatter } from '@/shared/design/formatters';
import { primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { registerPrivateObjectUrl } from '@/shared/auth/private-cache';
import { Button, Card, InlineMessage, ProgressBar, StateView, StatusBadge } from '@/shared/ui/primitives';
import { memberLevelPresentation, type CoachPaymentOrder, type MemberLevel } from './coach-experience-models';
import { getCoachExperienceRepository } from './coach-experience-repository';
import { useCoachApplicationMutation, useMyCoachApplication, useMyCoachPaymentOrders, useSubmitCoachPaymentEvidence } from './coach-experience-queries';

const memberLevels = Object.keys(memberLevelPresentation) as MemberLevel[];

export function CoachApplicationFlow({ authorized }: { authorized: boolean }) {
  const { colors } = useAppTheme();
  const application = useMyCoachApplication(authorized);
  const orders = useMyCoachPaymentOrders(authorized);
  const submit = useCoachApplicationMutation();
  const [memberLevel, setMemberLevel] = useState<MemberLevel>('sc');
  const [homSts, setHomSts] = useState(false);
  const [ict, setIct] = useState(false);
  const [terms, setTerms] = useState(false);

  if (!authorized) return <StateView kind="forbidden" />;
  if (application.isPending || orders.isPending) return <StateView kind="loading" />;
  if (application.isError || orders.isError) return <StateView kind="error" action={<Button label="Coba lagi" onPress={() => void Promise.all([application.refetch(), orders.refetch()])} />} />;

  const latestOrder = orders.data?.find((order) => !['rejected', 'cancelled', 'expired', 'reversed'].includes(order.status));
  if (latestOrder) return <CoachPaymentOrderView order={latestOrder} />;
  const current = application.data?.application;
  if (current?.status === 'active') {
    return <StateView kind="empty" action={<Button label="Buka dashboard Coach" onPress={() => router.replace('/coach')} />} />;
  }
  const price = memberLevelPresentation[memberLevel].price;
  const eligible = price !== null && homSts && ict && terms;

  return (
    <ScrollView contentContainerStyle={styles.content} testID="coach.application.flow">
      <Card>
        <Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>Ajukan akses Coach</Text>
        <Text style={[styles.body, { color: colors.secondaryText }]}>Pilih level akun dan nyatakan persyaratan yang sudah selesai. Admin tetap memverifikasi bukti pembayaran serta kelayakan sebelum akses aktif.</Text>
      </Card>

      <Card>
        <Text style={[styles.cardTitle, { color: colors.primaryText }]}>Level member</Text>
        <View style={styles.levelGrid}>
          {memberLevels.map((level) => {
            const selected = level === memberLevel;
            return (
              <Pressable key={level} accessibilityRole="radio" accessibilityState={{ selected }} onPress={() => setMemberLevel(level)} style={[styles.levelChoice, { borderColor: selected ? colors.primaryAction : colors.border, backgroundColor: selected ? colors.secondaryBackground : colors.surface }]}>
                <Text style={[styles.bodyStrong, { color: colors.primaryText }]}>{memberLevelPresentation[level].label}</Text>
                <Text style={[styles.caption, { color: colors.secondaryText }]}>{memberLevelPresentation[level].price === null ? 'Belum memenuhi syarat' : `${rupiahFormatter.format(memberLevelPresentation[level].price as number)} · 3 bulan`}</Text>
              </Pressable>
            );
          })}
        </View>
      </Card>

      <Card>
        <Text style={[styles.cardTitle, { color: colors.primaryText }]}>Persyaratan</Text>
        <CheckRow label="Saya berada di level SC atau lebih tinggi" checked={price !== null} locked />
        <CheckRow label="Saya sudah menyelesaikan HOM STS" checked={homSts} onPress={() => setHomSts((value) => !value)} />
        <CheckRow label="Saya sudah menyelesaikan ICT" checked={ict} onPress={() => setIct((value) => !value)} />
        <CheckRow label="Saya menyatakan data ini benar dan menyetujui ketentuan aplikasi Coach" checked={terms} onPress={() => setTerms((value) => !value)} />
      </Card>

      {price === null ? <InlineMessage title="Level belum memenuhi syarat" message="Aplikasi Coach tersedia mulai level SC." tone="destructive" /> : (
        <InlineMessage title={`Biaya ${rupiahFormatter.format(price)}`} message="Biaya ditentukan server berdasarkan level. Akses berlaku tiga bulan dan tidak diperpanjang otomatis." tone="warning" />
      )}
      {current?.rejection_reason ? <InlineMessage title="Aplikasi sebelumnya ditolak" message={current.rejection_reason} tone="destructive" /> : null}
      {submit.error instanceof Error ? <InlineMessage title="Belum dapat dilanjutkan" message={submit.error.message} tone="destructive" /> : null}
      <Button label="Lanjut ke pembayaran" disabled={!eligible} loading={submit.isPending} onPress={() => void submit.mutateAsync({ memberLevel, hasCompletedHomSts: homSts, hasCompletedIct: ict, termsVersion: 'coach-web-v1', idempotencyKey: `coach-draft-${crypto.randomUUID()}` })} />
      <Button label="Kembali ke profil" tone="secondary" icon="back" onPress={() => router.back()} />
    </ScrollView>
  );
}

function CheckRow({ label, checked, locked = false, onPress }: { label: string; checked: boolean; locked?: boolean; onPress?: () => void }) {
  const { colors } = useAppTheme();
  return (
    <Pressable accessibilityRole="checkbox" accessibilityState={{ checked, disabled: locked }} aria-checked={checked} disabled={locked} onPress={onPress} style={[styles.checkRow, { borderColor: checked ? colors.primaryAction : colors.border, backgroundColor: colors.surface }]}>
      <Text style={[styles.body, { color: colors.primaryText }]}>{checked ? '✓ ' : ''}{label}</Text>
    </Pressable>
  );
}

export function CoachPaymentOrderView({ order, onboarding = false, embedded = false, onSubmitted }: { order: CoachPaymentOrder; onboarding?: boolean; embedded?: boolean; onSubmitted?: () => void }) {
  const { colors } = useAppTheme();
  const submitEvidence = useSubmitCoachPaymentEvidence();
  const [file, setFile] = useState<File>();
  const [progress, setProgress] = useState({ value: 0, message: '' });
  const [error, setError] = useState<string>();
  const inputRef = useRef<HTMLInputElement>(null);
  const uploadKey = useRef(`coach-proof-${order.id}-${crypto.randomUUID()}`);
  const canUpload = order.status === 'awaiting_evidence' || order.status === 'correction_required';

  const submit = async () => {
    if (!file) return;
    setError(undefined);
    try {
      await submitEvidence.mutateAsync({ orderId: order.id, file, idempotencyKey: uploadKey.current, onboarding, onProgress: (value, message) => setProgress({ value, message }) });
      setFile(undefined);
      if (inputRef.current) inputRef.current.value = '';
      onSubmitted?.();
    } catch (uploadError) {
      setError(uploadError instanceof Error ? uploadError.message : 'Bukti belum dapat dikirim.');
    }
  };

  const content = (
    <>
      <InlineMessage title={order.status === 'under_review' ? 'Sedang diperiksa Admin' : order.status === 'approved' ? 'Akses Coach aktif' : order.status === 'correction_required' ? 'Bukti perlu diperbaiki' : 'Selesaikan pembayaran'} message={order.status === 'under_review' ? 'Akun tetap sebagai Peserta selama Admin memeriksa bukti.' : order.status === 'approved' ? 'Masuk kembali bila dashboard Coach belum muncul.' : order.latest_rejection_reason ?? 'Gunakan rekening atau QRIS di bawah, lalu unggah bukti pembayaran.'} tone={order.status === 'approved' ? 'success' : order.status === 'correction_required' ? 'destructive' : 'warning'} />
      <Card>
        <Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>Tujuan pembayaran</Text>
        {order.qris_object_path_snapshot ? <PrivateQris objectPath={order.qris_object_path_snapshot} /> : null}
        <PaymentDetail label="Bank" value={`${order.bank_code_snapshot} · ${order.bank_name_snapshot}`} />
        <PaymentDetail label="Atas nama" value={order.account_name_snapshot} />
        <PaymentDetail label="Nomor rekening" value={order.account_reference_snapshot} />
        <PaymentDetail label="Biaya akses Coach" value={rupiahFormatter.format(order.amount_minor)} />
        <Text style={[styles.caption, { color: colors.secondaryText }]}>Akses berlaku tiga bulan tanpa perpanjangan otomatis setelah Admin menyetujui pembayaran.</Text>
      </Card>

      <Card>
        <Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>Bukti pembayaran</Text>
        {canUpload && Platform.OS === 'web' ? <input ref={inputRef} aria-label="Pilih bukti pembayaran Coach" type="file" accept="image/jpeg,image/png,image/webp,image/heic,image/heif" onChange={(event) => setFile(event.currentTarget.files?.[0])} /> : null}
        {file ? <Text style={[styles.caption, { color: colors.secondaryText }]}>{file.name}</Text> : null}
        {progress.value > 0 ? <ProgressBar label={progress.message} value={progress.value} /> : null}
        {canUpload ? <Button label="Kirim bukti pembayaran" icon="upload" disabled={!file} loading={submitEvidence.isPending} onPress={() => void submit()} /> : <StatusBadge label={order.status === 'under_review' ? 'Terkunci selama pemeriksaan' : order.status} tone={order.status === 'approved' ? 'success' : 'warning'} />}
      </Card>
      {error ? <InlineMessage title="Unggahan gagal" message={error} tone="destructive" /> : null}
      <Button label={onboarding ? 'Kembali ke syarat Coach' : 'Kembali ke profil'} tone="secondary" icon="back" onPress={() => onboarding ? router.replace('/onboarding/coach/eligibility') : router.replace('/app/profile')} />
    </>
  );
  return embedded
    ? <View style={[styles.content, styles.embeddedContent]} testID="coach.application.payment">{content}</View>
    : <ScrollView contentContainerStyle={styles.content} testID="coach.application.payment">{content}</ScrollView>;
}

function PrivateQris({ objectPath }: { objectPath: string }) {
  const { colors } = useAppTheme();
  const [url, setUrl] = useState<string>();
  const [failed, setFailed] = useState(false);
  useEffect(() => {
    let active = true;
    let cleanup: (() => void) | undefined;
    void getCoachExperienceRepository().downloadDestinationAsset(objectPath).then((blob) => {
      if (!active) return;
      const next = URL.createObjectURL(blob);
      const unregister = registerPrivateObjectUrl(next);
      cleanup = () => { URL.revokeObjectURL(next); unregister(); };
      setUrl(next);
    }).catch(() => { if (active) setFailed(true); });
    return () => { active = false; cleanup?.(); };
  }, [objectPath]);
  if (failed) return <InlineMessage title="QRIS tidak dapat dimuat" message="Gunakan transfer bank atau muat ulang." tone="destructive" />;
  if (!url) return <StateView kind="loading" />;
  return <Image accessibilityLabel="QRIS pembayaran aplikasi Coach" resizeMode="contain" source={{ uri: url }} style={[styles.qris, { backgroundColor: colors.secondaryBackground }]} />;
}

function PaymentDetail({ label, value }: { label: string; value: string }) {
  const { colors } = useAppTheme();
  return <View style={styles.detail}><Text style={[styles.caption, { color: colors.secondaryText }]}>{label}</Text><Text selectable style={[styles.bodyStrong, { color: colors.primaryText }]}>{value}</Text></View>;
}

const styles = StyleSheet.create({
  content: { width: '100%', maxWidth: 760, alignSelf: 'center', padding: primitiveTokens.space.large, gap: primitiveTokens.space.large, paddingBottom: 140 },
  embeddedContent: { padding: 0, paddingBottom: 0 },
  heading: typographyTokens.title,
  cardTitle: typographyTokens.headline,
  body: typographyTokens.body,
  bodyStrong: typographyTokens.bodyStrong,
  caption: typographyTokens.caption,
  levelGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: primitiveTokens.space.small },
  levelChoice: { minWidth: 190, flexGrow: 1, flexBasis: 220, minHeight: 72, borderWidth: 2, borderRadius: primitiveTokens.radius.medium, padding: primitiveTokens.space.medium, justifyContent: 'center', gap: primitiveTokens.space.xxSmall },
  checkRow: { minHeight: 52, borderWidth: 1, borderRadius: primitiveTokens.radius.medium, padding: primitiveTokens.space.medium, justifyContent: 'center' },
  qris: { width: '100%', height: 320, borderRadius: primitiveTokens.radius.large },
  detail: { gap: primitiveTokens.space.xxSmall },
});
