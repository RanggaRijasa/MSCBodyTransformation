import { router } from 'expo-router';
import { useEffect, useRef, useState, type CSSProperties, type PropsWithChildren } from 'react';
import { Platform, Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { CoachPaymentOrderView } from '@/features/coach/CoachApplicationComponents';
import { memberLevelPresentation, type MemberLevel } from '@/features/coach/coach-experience-models';
import { useCoachApplicationMutation, useMyCoachPaymentOrders } from '@/features/coach/coach-experience-queries';
import type { AccountPurpose, ConfirmedCoach } from './onboarding-models';
import { getOnboardingRepository } from './onboarding-repository';
import { useAuth } from '@/shared/auth/AuthProvider';
import { rupiahFormatter } from '@/shared/design/formatters';
import { componentTokens, primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { MSCIcon, type MSCIconName } from '@/shared/icons/MSCIcon';
import { QRScanner } from '@/shared/qr/QRScanner';
import { Button, Card, Dialog, Field, InlineMessage, StateView, StatusBadge, UserAvatar } from '@/shared/ui/primitives';

const memberLevels = Object.keys(memberLevelPresentation) as MemberLevel[];

export function OnboardingProfileScreen() {
  const { colors } = useAppTheme();
  const { state, refreshSessionContext, signOut } = useAuth();
  const [displayName, setDisplayName] = useState('');
  const [phoneNumber, setPhoneNumber] = useState('');
  const [memberLevel, setMemberLevel] = useState<MemberLevel>('member');
  const [purpose, setPurpose] = useState<AccountPurpose>('participant');
  const [version, setVersion] = useState(1);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string>();
  const onboardingUserId = state.status === 'onboarding' ? state.context.user_id : null;
  const providerDisplayName = state.status === 'onboarding' ? state.providerDefaults.displayName : 'Peserta baru';

  useEffect(() => {
    let active = true;
    if (onboardingUserId === null) return undefined;
    void getOnboardingRepository().getProfile().then((profile) => {
      if (!active) return;
      setDisplayName(profile.display_name === 'Peserta baru' ? providerDisplayName : profile.display_name);
      setPhoneNumber(profile.phone_number ?? '');
      setMemberLevel(profile.member_level ?? 'member');
      setPurpose(profile.account_purpose);
      setVersion(profile.onboarding_version);
    }).catch((loadError) => {
      if (active) setError(loadError instanceof Error ? loadError.message : 'Profil belum dapat dimuat.');
    }).finally(() => { if (active) setLoading(false); });
    return () => { active = false; };
  }, [onboardingUserId, providerDisplayName]);

  if (state.status !== 'onboarding') return <StateView kind="loading" />;
  if (loading) return <OnboardingScaffold title="Lengkapi profil"><StateView kind="loading" /></OnboardingScaffold>;
  const nameValid = displayName.trim().length >= 2;
  const phoneValid = /^\+?[0-9]{8,15}$/u.test(phoneNumber.replace(/[\s-]/gu, ''));
  const canContinue = nameValid && phoneValid && !(purpose === 'coach_applicant' && memberLevel === 'member');

  const chooseMemberLevel = (level: MemberLevel) => {
    setMemberLevel(level);
    if (level === 'member' && purpose === 'coach_applicant') setPurpose('participant');
  };
  const save = async () => {
    setSaving(true); setError(undefined);
    try {
      await getOnboardingRepository().saveProfile({ displayName, phoneNumber, memberLevel, purpose, expectedVersion: version });
      const next = await refreshSessionContext();
      if (next.status === 'onboarding') {
        router.push((next.context.resume_step === 'participant_coach' ? '/onboarding/participant/coach' : '/onboarding/coach/eligibility') as never);
      }
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : 'Profil belum dapat disimpan.');
    } finally { setSaving(false); }
  };

  return (
    <OnboardingScaffold title="Lengkapi profil" onBack={() => { void signOut().then(() => router.replace('/login')); }} allowCancel>
      <Card>
        <View style={styles.identityRow}>
          <UserAvatar uri={state.providerDefaults.avatarUrl} label={displayName || 'Akun Google'} size={72} />
          <View style={styles.flexCopy}>
            <Text style={[styles.heading, { color: colors.primaryText }]}>Siapkan akun MSC</Text>
            <Text style={[styles.body, { color: colors.secondaryText }]}>Lengkapi data berikut sebelum akun dapat digunakan.</Text>
          </View>
        </View>
      </Card>
      <Card>
        <Field label="Nama" autoComplete="name" value={displayName} onChangeText={setDisplayName} error={!nameValid && displayName.length > 0 ? 'Masukkan minimal 2 karakter.' : undefined} />
        <Field label="Nomor HP" autoComplete="tel" keyboardType="phone-pad" value={phoneNumber} onChangeText={setPhoneNumber} message="Gunakan 8–15 angka. OTP tidak diperlukan pada tahap ini." error={!phoneValid && phoneNumber.length > 0 ? 'Nomor HP belum valid.' : undefined} />
      </Card>
      <View style={styles.sectionGap}>
        <Text accessibilityRole="header" style={[styles.sectionTitle, { color: colors.primaryText }]}>Level member</Text>
        {Platform.OS === 'web' ? (
          <select aria-label="Level member" value={memberLevel} onChange={(event) => chooseMemberLevel(event.currentTarget.value as MemberLevel)} style={memberSelectStyle(colors)}>
            {memberLevels.map((level) => <option key={level} value={level}>{memberLevelPresentation[level].label}</option>)}
          </select>
        ) : <View accessibilityRole="radiogroup" accessibilityLabel="Level member" style={styles.optionGrid}>{memberLevels.map((level) => <RadioChoice key={level} label={memberLevelPresentation[level].label} selected={memberLevel === level} onPress={() => chooseMemberLevel(level)} />)}</View>}
      </View>
      <View style={styles.sectionGap}>
        <Text accessibilityRole="header" style={[styles.sectionTitle, { color: colors.primaryText }]}>Tujuan akun</Text>
        <Text style={[styles.body, { color: colors.secondaryText }]}>Pilihan ini bukan pemilihan role. Semua akun baru tetap dimulai sebagai Peserta.</Text>
        <View accessibilityRole="radiogroup" accessibilityLabel="Tujuan akun" style={styles.sectionGap}>
          <PurposeChoice icon="participants" label="Lanjut sebagai Peserta" message="Hubungkan akun dengan Coach melalui QR untuk mengaktifkan akun Peserta." selected={purpose === 'participant'} onPress={() => setPurpose('participant')} />
          <PurposeChoice icon="coach" label="Ajukan menjadi Coach" message="Lengkapi syarat, pembayaran tiga bulan, dan persetujuan Admin." selected={purpose === 'coach_applicant'} disabled={memberLevel === 'member'} onPress={() => setPurpose('coach_applicant')} />
        </View>
        {memberLevel === 'member' ? <InlineMessage title="Coach tersedia mulai level SC" message="Naikkan level member terlebih dahulu. Data nama dan nomor HP tetap tersimpan di formulir ini." tone="warning" /> : null}
      </View>
      {error ? <InlineMessage title="Belum dapat dilanjutkan" message={error} tone="destructive" /> : null}
      <Button label={purpose === 'participant' ? 'Lanjut sebagai Peserta' : 'Lanjut ke syarat Coach'} disabled={!canContinue} loading={saving} onPress={() => void save()} />
    </OnboardingScaffold>
  );
}

export function ParticipantCoachOnboardingScreen() {
  const { colors } = useAppTheme();
  const { state, finishOnboarding } = useAuth();
  const rawQr = useRef<string | undefined>(undefined);
  const [confirmed, setConfirmed] = useState<ConfirmedCoach>();
  const [scannerOpen, setScannerOpen] = useState(false);
  const [scannerKey, setScannerKey] = useState(0);
  const [validating, setValidating] = useState(false);
  const [finalizing, setFinalizing] = useState(false);
  const [error, setError] = useState<string>();
  if (state.status !== 'onboarding') return <StateView kind="loading" />;

  const validate = async (payload: string) => {
    setValidating(true); setError(undefined);
    try {
      const coach = await getOnboardingRepository().validateCoachQr(payload);
      rawQr.current = payload;
      setConfirmed(coach);
      setScannerOpen(false);
    } catch (validationError) {
      rawQr.current = undefined;
      setConfirmed(undefined);
      setError(validationError instanceof Error ? validationError.message : 'QR Coach belum dapat diperiksa.');
      setScannerOpen(false);
      setScannerKey((value) => value + 1);
    } finally { setValidating(false); }
  };
  const finalize = async () => {
    if (!rawQr.current) return;
    setFinalizing(true); setError(undefined);
    try {
      await getOnboardingRepository().finalizeParticipant(rawQr.current, state.context.onboarding_version);
      rawQr.current = undefined;
      router.replace(await finishOnboarding() as never);
    } catch (finalizeError) {
      setError(finalizeError instanceof Error ? finalizeError.message : 'Akun Peserta belum dapat diaktifkan.');
      setConfirmed(undefined);
      rawQr.current = undefined;
    } finally { setFinalizing(false); }
  };

  return (
    <OnboardingScaffold title="Hubungkan dengan Coach" backTarget="/onboarding/profile" allowCancel>
      <InlineMessage title="Akun MSC belum aktif" message="Pindai QR Coach untuk memastikan pendamping yang benar. Tidak tersedia input kode manual." tone="info" />
      {scannerOpen ? <Card><QRScanner key={scannerKey} onScan={(payload) => void validate(payload)} onClose={() => setScannerOpen(false)} /></Card> : null}
      {!scannerOpen && !confirmed ? <Card><View style={styles.centered}><MSCIcon name="qr" color={colors.primaryAction} size="large" /><Text style={[styles.heading, { color: colors.primaryText }]}>Pindai QR Coach</Text><Text style={[styles.bodyCentered, { color: colors.secondaryText }]}>Minta QR terbaru dari Coach, lalu arahkan kamera hingga kode terbaca.</Text><Button label="Pindai QR Coach" icon="qr" loading={validating} onPress={() => setScannerOpen(true)} /></View></Card> : null}
      {confirmed ? <Card><View style={styles.identityRow}><UserAvatar uri={confirmed.avatar_url ?? undefined} label={confirmed.display_name} /><View style={styles.flexCopy}><StatusBadge label="Coach terkonfirmasi" tone="success" /><Text style={[styles.heading, { color: colors.primaryText }]}>{confirmed.display_name}</Text><Text style={[styles.body, { color: colors.secondaryText }]}>{confirmed.city ?? 'Lokasi belum dicantumkan'}</Text></View></View><Button label="Pindai ulang" tone="secondary" icon="qr" onPress={() => { rawQr.current = undefined; setConfirmed(undefined); setScannerKey((value) => value + 1); setScannerOpen(true); }} /></Card> : null}
      {error ? <InlineMessage title="QR belum dapat digunakan" message={error} tone="destructive" /> : null}
      <Button label="Aktifkan akun Peserta" disabled={!confirmed} loading={finalizing} onPress={() => void finalize()} />
    </OnboardingScaffold>
  );
}

export function CoachEligibilityOnboardingScreen() {
  const { colors } = useAppTheme();
  const { state, refreshSessionContext } = useAuth();
  const submit = useCoachApplicationMutation();
  const [homSts, setHomSts] = useState(false);
  const [ict, setIct] = useState(false);
  const [terms, setTerms] = useState(false);
  const [error, setError] = useState<string>();
  const [profile, setProfile] = useState<{ memberLevel: MemberLevel; version: number }>();
  const onboardingUserId = state.status === 'onboarding' ? state.context.user_id : null;
  useEffect(() => {
    let active = true;
    if (onboardingUserId === null) return undefined;
    void getOnboardingRepository().getProfile().then((value) => {
      if (active && value.member_level) setProfile({ memberLevel: value.member_level, version: value.onboarding_version });
    }).catch((loadError) => { if (active) setError(loadError instanceof Error ? loadError.message : 'Profil belum dapat dimuat.'); });
    return () => { active = false; };
  }, [onboardingUserId]);
  if (state.status !== 'onboarding') return <StateView kind="loading" />;
  if (!profile) return <OnboardingScaffold title="Syarat Coach"><StateView kind={error ? 'error' : 'loading'} /></OnboardingScaffold>;
  const memberLevel = profile.memberLevel;
  const presentation = memberLevel ? memberLevelPresentation[memberLevel] : undefined;
  const eligible = presentation?.price !== null && presentation !== undefined && homSts && ict && terms;
  const continueToPayment = async () => {
    if (!memberLevel) return;
    setError(undefined);
    try {
      if (state.context.onboarding_status === 'provisional') {
        await getOnboardingRepository().prepareCoachHandoff(profile.version);
      }
      await submit.mutateAsync({ memberLevel, hasCompletedHomSts: homSts, hasCompletedIct: ict, termsVersion: 'coach-web-v1', idempotencyKey: `coach-onboarding-${crypto.randomUUID()}` });
      await refreshSessionContext();
      router.replace('/onboarding/coach/payment');
    } catch (submitError) {
      setError(submitError instanceof Error ? submitError.message : 'Syarat Coach belum dapat disimpan.');
    }
  };
  return (
    <OnboardingScaffold title="Syarat Coach" backTarget={state.context.onboarding_status === 'provisional' ? '/onboarding/profile' : undefined} allowCancel>
      <Card>
        <Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>Ajukan menjadi Coach</Text>
        <Text style={[styles.body, { color: colors.secondaryText }]}>Akun tetap berwenang sebagai Peserta sampai Admin menyetujui pengajuan dan pembayaran.</Text>
      </Card>
      <Card>
        <Text style={[styles.cardTitle, { color: colors.primaryText }]}>Level dan biaya</Text>
        <DetailRow label="Level member" value={presentation?.label ?? 'Belum dipilih'} />
        <DetailRow label="Biaya akses" value={presentation?.price ? rupiahFormatter.format(presentation.price) : 'Belum memenuhi syarat'} />
        <DetailRow label="Masa akses" value="3 bulan" />
        <Text style={[styles.body, { color: colors.secondaryText }]}>Tidak ada perpanjangan otomatis.</Text>
      </Card>
      <Card>
        <Text style={[styles.cardTitle, { color: colors.primaryText }]}>Kelayakan</Text>
        <CheckRow label="Level SC atau lebih tinggi" checked={presentation?.price !== null} locked />
        <CheckRow label="Saya sudah menyelesaikan HOM STS" checked={homSts} onPress={() => setHomSts((value) => !value)} />
        <CheckRow label="Saya sudah menyelesaikan ICT" checked={ict} onPress={() => setIct((value) => !value)} />
        <CheckRow label="Saya menyatakan data benar dan menyetujui ketentuan aplikasi Coach" checked={terms} onPress={() => setTerms((value) => !value)} />
      </Card>
      {error || submit.error instanceof Error ? <InlineMessage title="Belum dapat dilanjutkan" message={error ?? (submit.error as Error).message} tone="destructive" /> : null}
      <Button label="Lanjut ke pembayaran Coach" disabled={!eligible} loading={submit.isPending} onPress={() => void continueToPayment()} />
    </OnboardingScaffold>
  );
}

export function CoachPaymentOnboardingScreen() {
  const { state, refreshSessionContext } = useAuth();
  const orders = useMyCoachPaymentOrders(state.status === 'onboarding');
  if (state.status !== 'onboarding') return <StateView kind="loading" />;
  if (orders.isPending) return <OnboardingScaffold title="Pembayaran Coach"><StateView kind="loading" /></OnboardingScaffold>;
  if (orders.isError || !orders.data?.[0]) return <OnboardingScaffold title="Pembayaran Coach" backTarget="/onboarding/coach/eligibility" allowCancel><StateView kind="error" action={<Button label="Kembali ke syarat Coach" onPress={() => router.replace('/onboarding/coach/eligibility')} />} /></OnboardingScaffold>;
  return <OnboardingScaffold title="Pembayaran Coach" backTarget="/onboarding/coach/eligibility" allowCancel><CoachPaymentOrderView order={orders.data[0]} onboarding embedded onSubmitted={() => { void refreshSessionContext().then(() => router.replace('/onboarding/coach/status')); }} /></OnboardingScaffold>;
}

export function CoachStatusOnboardingScreen() {
  const { colors } = useAppTheme();
  const { state, finishOnboarding } = useAuth();
  const authorized = state.status === 'onboarding' || (state.status === 'authenticated' && state.account.role === 'participant');
  const orders = useMyCoachPaymentOrders(authorized);
  if (!authorized || orders.isPending) return <OnboardingScaffold title="Status pengajuan"><StateView kind="loading" /></OnboardingScaffold>;
  const order = orders.data?.[0];
  if (orders.isError || !order) return <OnboardingScaffold title="Status pengajuan"><StateView kind="error" /></OnboardingScaffold>;
  if (order.status === 'correction_required') return <OnboardingScaffold title="Perbaiki bukti"><CoachPaymentOrderView order={order} embedded onSubmitted={() => router.replace('/onboarding/coach/status')} /></OnboardingScaffold>;
  const pending = order.status === 'under_review';
  const rejected = order.status === 'rejected';
  const closed = ['cancelled', 'expired', 'reversed'].includes(order.status);
  const approved = order.status === 'approved';
  return (
    <OnboardingScaffold title="Status pengajuan" allowCancel={state.status === 'onboarding'}>
      <Card><View style={styles.centered}><MSCIcon name={pending ? 'pending' : approved ? 'approved' : 'rejected'} color={pending ? colors.warning : approved ? colors.success : colors.destructive} size="large" /><Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>{pending ? 'Menunggu persetujuan Admin' : rejected ? 'Pengajuan ditolak' : closed ? 'Pembayaran ditutup' : approved ? 'Akses Coach aktif' : 'Status pembayaran belum dikenali'}</Text><Text style={[styles.bodyCentered, { color: colors.secondaryText }]}>{pending ? 'Bukti pembayaran sedang diperiksa. Akun tetap sebagai Peserta dan belum memiliki akses workspace Coach.' : rejected ? order.latest_rejection_reason ?? 'Lihat alasan Admin sebelum mengajukan kembali.' : closed ? 'Pesanan ini tidak dapat dilanjutkan. Tutup pendaftaran atau mulai pengajuan baru dari Profil setelah akun aktif.' : approved ? 'Akses Coach sudah aktif selama tiga bulan.' : 'Muat ulang atau hubungi Admin sebelum melanjutkan.'}</Text></View></Card>
      {pending ? <InlineMessage title="Akun tetap sebagai Peserta" message="Kamu dapat memakai aplikasi Peserta sambil menunggu pemeriksaan Admin." tone="info" /> : null}
      {state.status === 'authenticated' ? <Button label={rejected || closed ? 'Buka Profil untuk mengajukan lagi' : pending ? 'Masuk sebagai Peserta' : 'Buka dashboard Coach'} onPress={() => void finishOnboarding().then((destination) => router.replace((rejected || closed ? '/app/coach-application' : approved ? '/coach' : destination) as never))} /> : null}
    </OnboardingScaffold>
  );
}

export function OnboardingCleanupScreen() {
  const { signOut } = useAuth();
  const started = useRef(false);
  useEffect(() => { if (!started.current) { started.current = true; void signOut(); } }, [signOut]);
  return <OnboardingScaffold title="Membatalkan pendaftaran"><StateView kind="loading" /></OnboardingScaffold>;
}

function OnboardingScaffold({ title, backTarget, onBack, allowCancel = false, children }: PropsWithChildren<{ title: string; backTarget?: string; onBack?: () => void; allowCancel?: boolean }>) {
  const { colors } = useAppTheme();
  const { state, signOut, finishOnboarding } = useAuth();
  const [confirming, setConfirming] = useState(false);
  const [cancelling, setCancelling] = useState(false);
  const [cancelError, setCancelError] = useState<string>();
  const cancellationKey = useRef(`cancel-registration-${crypto.randomUUID()}`);
  const cancel = async () => {
    setCancelling(true); setCancelError(undefined);
    try {
      const result = await getOnboardingRepository().requestCancellation(cancellationKey.current);
      if (result === 'retained') router.replace(await finishOnboarding() as never);
      else await signOut();
    } catch (error) {
      setCancelError(error instanceof Error ? error.message : 'Pendaftaran belum dapat dibatalkan.');
    } finally { setCancelling(false); }
  };
  return (
    <SafeAreaView style={[styles.safe, { backgroundColor: colors.background }]}>
      <View style={[styles.header, { borderBottomColor: colors.border }]}>
        <View style={styles.headerSide}>{onBack || backTarget ? <HeaderAction label="Kembali" icon="back" onPress={onBack ?? (() => router.replace(backTarget as never))} /> : null}</View>
        <Text accessibilityRole="header" numberOfLines={2} style={[styles.headerTitle, { color: colors.primaryText }]}>{title}</Text>
        <View style={[styles.headerSide, styles.headerRight]}>{allowCancel ? <HeaderAction label="Tutup" onPress={() => setConfirming(true)} /> : null}</View>
      </View>
      <ScrollView style={styles.flex} contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled">{children}</ScrollView>
      <Dialog visible={confirming} title="Batalkan pendaftaran?" onClose={() => setConfirming(false)}>
        <Text style={[styles.body, { color: colors.secondaryText }]}>Jika dibatalkan sekarang, data provisional dan unggahan yang belum dikirim akan dibersihkan. Menutup tab saja tidak membatalkan; pendaftaran dapat dilanjutkan selama 24 jam.</Text>
        {state.status === 'onboarding' && state.context.resume_step === 'coach_status' ? <InlineMessage title="Riwayat pembayaran dipertahankan" message="Bukti yang sudah dikirim tidak akan dihapus. Akun tetap sebagai Peserta." tone="info" /> : null}
        {cancelError ? <InlineMessage title="Belum dapat dibatalkan" message={cancelError} tone="destructive" /> : null}
        <View style={styles.actions}><Button label="Lanjutkan pendaftaran" tone="secondary" onPress={() => setConfirming(false)} /><Button label="Batalkan pendaftaran" tone="destructive" loading={cancelling} onPress={() => void cancel()} /></View>
      </Dialog>
    </SafeAreaView>
  );
}

function HeaderAction({ label, icon, onPress }: { label: string; icon?: MSCIconName; onPress: () => void }) {
  const { colors } = useAppTheme();
  return <Pressable accessibilityRole="button" accessibilityLabel={label} onPress={onPress} style={({ pressed }) => [styles.headerAction, pressed && { opacity: 0.55 }]}>{icon ? <MSCIcon name={icon} color={colors.primaryText} /> : null}<Text style={[styles.headerActionText, { color: colors.primaryAction }]}>{label}</Text></Pressable>;
}

function RadioChoice({ label, selected, onPress }: { label: string; selected: boolean; onPress: () => void }) {
  const { colors } = useAppTheme();
  return <Pressable accessibilityRole="radio" accessibilityState={{ selected }} onPress={onPress} style={[styles.radioChoice, { backgroundColor: colors.surface, borderColor: selected ? colors.primaryAction : colors.border }]}><View style={[styles.radioDot, { borderColor: selected ? colors.primaryAction : colors.border }]}>{selected ? <View style={[styles.radioFill, { backgroundColor: colors.primaryAction }]} /> : null}</View><Text style={[styles.bodyStrong, { color: colors.primaryText }]}>{label}</Text></Pressable>;
}

function PurposeChoice({ icon, label, message, selected, disabled = false, onPress }: { icon: MSCIconName; label: string; message: string; selected: boolean; disabled?: boolean; onPress: () => void }) {
  const { colors } = useAppTheme();
  return <Pressable accessibilityRole="radio" accessibilityLabel={`${label}. ${message}`} accessibilityState={{ selected, disabled }} disabled={disabled} onPress={onPress} style={[styles.purposeChoice, { backgroundColor: colors.surface, borderColor: selected ? colors.primaryAction : colors.border, opacity: disabled ? 0.55 : 1 }]}><View style={[styles.purposeIcon, { backgroundColor: selected ? colors.primaryTintSurface : colors.secondaryBackground }]}><MSCIcon name={icon} color={selected ? colors.primaryAction : colors.primaryText} size="large" /></View><View style={styles.flexCopy}><Text style={[styles.heading, { color: colors.primaryText }]}>{label}</Text><Text style={[styles.body, { color: colors.secondaryText }]}>{message}</Text>{disabled ? <Text style={[styles.caption, { color: colors.warning }]}>Tersedia mulai level SC</Text> : null}</View><View style={[styles.radioDot, { borderColor: selected ? colors.primaryAction : colors.border }]}>{selected ? <View style={[styles.radioFill, { backgroundColor: colors.primaryAction }]} /> : null}</View></Pressable>;
}

function CheckRow({ label, checked, locked = false, onPress }: { label: string; checked: boolean; locked?: boolean; onPress?: () => void }) {
  const { colors } = useAppTheme();
  return <Pressable accessibilityRole="checkbox" accessibilityState={{ checked, disabled: locked }} aria-checked={checked} disabled={locked} onPress={onPress} style={[styles.checkRow, { backgroundColor: colors.surface, borderColor: checked ? colors.primaryAction : colors.border }]}><MSCIcon name={checked ? 'approved' : 'pending'} color={checked ? colors.success : colors.secondaryText} /><Text style={[styles.body, styles.flexCopy, { color: colors.primaryText }]}>{label}</Text></Pressable>;
}

function DetailRow({ label, value }: { label: string; value: string }) {
  const { colors } = useAppTheme();
  return <View style={[styles.detailRow, { borderBottomColor: colors.border }]}><Text style={[styles.body, { color: colors.secondaryText }]}>{label}</Text><Text style={[styles.bodyStrong, { color: colors.primaryText }]}>{value}</Text></View>;
}

function memberSelectStyle(colors: ReturnType<typeof useAppTheme>['colors']): CSSProperties {
  return {
    appearance: 'auto',
    backgroundColor: colors.surface,
    border: `2px solid ${colors.border}`,
    borderRadius: primitiveTokens.radius.medium,
    color: colors.primaryText,
    fontFamily: 'inherit',
    fontSize: typographyTokens.body.fontSize,
    fontWeight: 700,
    minHeight: 52,
    padding: '12px 16px',
    width: '100%',
  };
}

const styles = StyleSheet.create({
  safe: { flex: 1 }, flex: { flex: 1 },
  header: { minHeight: 68, borderBottomWidth: StyleSheet.hairlineWidth, paddingHorizontal: primitiveTokens.space.medium, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: primitiveTokens.space.small },
  headerSide: { width: 92 }, headerRight: { alignItems: 'flex-end' },
  headerTitle: { ...typographyTokens.headline, flex: 1, textAlign: 'center' },
  headerAction: { minHeight: componentTokens.minimumTouchTarget, minWidth: componentTokens.minimumTouchTarget, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.xxSmall },
  headerActionText: typographyTokens.bodyStrong,
  content: { width: '100%', maxWidth: 720, alignSelf: 'center', padding: primitiveTokens.space.large, paddingBottom: primitiveTokens.space.xxLarge, gap: primitiveTokens.space.large },
  identityRow: { flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.medium },
  flexCopy: { flex: 1, minWidth: 0 }, sectionGap: { gap: primitiveTokens.space.medium },
  optionGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: primitiveTokens.space.small },
  radioChoice: { minHeight: 52, minWidth: 140, flexGrow: 1, flexBasis: 150, borderWidth: 2, borderRadius: primitiveTokens.radius.medium, padding: primitiveTokens.space.medium, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.small },
  radioDot: { width: 24, height: 24, borderRadius: 12, borderWidth: 2, alignItems: 'center', justifyContent: 'center' },
  radioFill: { width: 12, height: 12, borderRadius: 6 },
  purposeChoice: { minHeight: 112, borderWidth: 2, borderRadius: primitiveTokens.radius.large, padding: primitiveTokens.space.medium, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.medium },
  purposeIcon: { width: 56, height: 56, borderRadius: primitiveTokens.radius.medium, alignItems: 'center', justifyContent: 'center' },
  centered: { alignItems: 'center', gap: primitiveTokens.space.medium },
  bodyCentered: { ...typographyTokens.body, textAlign: 'center', maxWidth: 520 },
  checkRow: { minHeight: 56, borderWidth: 1, borderRadius: primitiveTokens.radius.medium, padding: primitiveTokens.space.medium, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.small },
  detailRow: { minHeight: 52, borderBottomWidth: StyleSheet.hairlineWidth, flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', gap: primitiveTokens.space.medium },
  actions: { flexDirection: 'row', flexWrap: 'wrap', gap: primitiveTokens.space.small },
  heading: typographyTokens.headline, cardTitle: typographyTokens.headline,
  sectionTitle: typographyTokens.title, body: typographyTokens.body,
  bodyStrong: typographyTokens.bodyStrong, caption: typographyTokens.caption,
});
