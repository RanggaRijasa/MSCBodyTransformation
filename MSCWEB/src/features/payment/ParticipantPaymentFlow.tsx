import { router } from 'expo-router';
import { useEffect, useRef, useState } from 'react';
import { Image, Platform, ScrollView, StyleSheet, Text, View } from 'react-native';

import type { PublicProgram } from '@/features/public/public-models';
import { repeatableLocalFixtureCategory } from '@/features/participant/participant-program-policy';
import { useAuth } from '@/shared/auth/AuthProvider';
import { registerPrivateObjectUrl } from '@/shared/auth/private-cache';
import { isLocalDevelopmentEnvironment } from '@/shared/config/public-environment';
import { rupiahFormatter } from '@/shared/design/formatters';
import { primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { normalizeBrowserImageOffMainThread } from '@/shared/media/image-normalization';
import { QRScanner } from '@/shared/qr/QRScanner';
import { Button, Card, Dialog, IconButton, InlineMessage, ProgressBar, StateView, StatusBadge } from '@/shared/ui/primitives';
import { getPaymentRepository } from './payment-repository';
import {
  useCreateProgramPaymentOrder,
  useEnrollFreeProgram,
  useOwnPaymentOrders,
  useSubmitPaymentEvidence,
} from './payment-queries';
import { paymentStatusPresentation, type PaymentOrder } from './payment-models';

export function ParticipantPaymentFlow({ program }: { program: PublicProgram }) {
  const { colors } = useAppTheme();
  const { state } = useAuth();
  const isCoach = state.status === 'authenticated' && state.account.role === 'coach';
  const orders = useOwnPaymentOrders(program.id, program.pricing_mode === 'paid');
  const createOrder = useCreateProgramPaymentOrder();
  const enrollFree = useEnrollFreeProgram();
  const [scannerVisible, setScannerVisible] = useState(false);
  const [error, setError] = useState<string>();
  const orderKey = useRef(`web-payment-${program.id}-${crypto.randomUUID()}`);
  const latestOrder = orders.data?.[0];
  const shouldLoadPaymentOrders = program.pricing_mode === 'paid';

  const handleScan = async (payload: string) => {
    setScannerVisible(false);
    setError(undefined);
    try {
      if (program.pricing_mode === 'free') {
        await enrollFree.mutateAsync({ programId: program.id, rawPayload: payload });
        router.replace(`/app/programs/${program.id}` as never);
      } else {
        await createOrder.mutateAsync({ programId: program.id, rawPayload: payload, idempotencyKey: orderKey.current });
      }
    } catch (scanError) {
      setError(scanError instanceof Error ? scanError.message : 'Pendaftaran belum dapat diproses. Coba pindai kembali.');
    }
  };

  if (shouldLoadPaymentOrders && orders.isPending) return <StateView kind="loading" />;
  if (shouldLoadPaymentOrders && orders.isError) return <StateView kind="error" action={<Button label="Coba lagi" onPress={() => void orders.refetch()} />} />;
  if (latestOrder) {
    return (
      <PaymentOrderView
        isLocalFixture={program.category === repeatableLocalFixtureCategory}
        order={latestOrder}
        programTitle={program.title}
      />
    );
  }

  return (
    <ScrollView contentContainerStyle={styles.screen} style={styles.scrollArea} testID="participant.enrollment.flow">
      <Card>
        <Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>Daftar ke {program.title}</Text>
        <Text style={[styles.body, { color: colors.secondaryText }]}>{isCoach ? 'Pindai QR Coach milikmu sendiri untuk melanjutkan. QR Coach lain tidak dapat digunakan.' : 'Pindai QR Coach untuk memastikan pendamping yang benar. Kode tidak dapat diketik atau disalin.'}</Text>
        <Button label={isCoach ? 'Pindai QR Coach milikmu' : 'Pindai QR Coach'} icon="qr" loading={enrollFree.isPending || createOrder.isPending} onPress={() => setScannerVisible(true)} />
      </Card>

      {error ? <InlineMessage title="Belum dapat dilanjutkan" message={error} tone="destructive" /> : null}
      <Button label="Kembali ke detail program" tone="secondary" icon="back" onPress={() => router.back()} />
      <Dialog visible={scannerVisible} title={isCoach ? 'Pindai QR Coach milikmu' : 'Pindai QR Coach'} onClose={() => setScannerVisible(false)}>
        <QRScanner onScan={(payload) => void handleScan(payload)} onClose={() => setScannerVisible(false)} />
      </Dialog>
    </ScrollView>
  );
}

function PaymentOrderView({
  isLocalFixture,
  order,
  programTitle,
}: {
  isLocalFixture: boolean;
  order: PaymentOrder;
  programTitle: string;
}) {
  const { colors } = useAppTheme();
  const submitEvidence = useSubmitPaymentEvidence(order.program_id);
  const [file, setFile] = useState<File>();
  const [previewUrl, setPreviewUrl] = useState<string>();
  const [progress, setProgress] = useState({ value: 0, message: '' });
  const [copied, setCopied] = useState<string>();
  const [localTestPending, setLocalTestPending] = useState(false);
  const [localTestResult, setLocalTestResult] = useState<string>();
  const [localTestError, setLocalTestError] = useState<string>();
  const uploadKey = useRef(`web-proof-${order.id}-${crypto.randomUUID()}`);
  const evidenceInputRef = useRef<HTMLInputElement>(null);
  const previewCleanup = useRef<(() => void) | undefined>(undefined);
  const presentation = paymentStatusPresentation(order.status);
  const canUpload = order.status === 'awaiting_evidence' || order.status === 'correction_required';
  const canRepeatLocalUpload = order.status === 'under_review'
    && isLocalFixture
    && isLocalDevelopmentEnvironment();
  const showUploadSection = canUpload || canRepeatLocalUpload;
  const uploadBusy = submitEvidence.isPending || localTestPending;
  const uploadLabel = canRepeatLocalUpload
    ? (file ? 'Ganti foto uji lokal' : 'Upload foto uji lokal')
    : (file ? 'Ganti bukti pembayaran' : 'Upload bukti pembayaran');

  useEffect(() => () => previewCleanup.current?.(), []);

  const selectFile = (nextFile?: File) => {
    previewCleanup.current?.();
    previewCleanup.current = undefined;
    setFile(nextFile);
    if (!nextFile) {
      if (evidenceInputRef.current) evidenceInputRef.current.value = '';
      setPreviewUrl(undefined);
      return;
    }
    const url = URL.createObjectURL(nextFile);
    const unregister = registerPrivateObjectUrl(url);
    previewCleanup.current = () => { URL.revokeObjectURL(url); unregister(); };
    setPreviewUrl(url);
  };

  const copy = async (label: string, value: string) => {
    try {
      const copiedWithoutPermissionPrompt = copyTextWithTemporaryField(value);
      if (!copiedWithoutPermissionPrompt) await navigator.clipboard.writeText(value);
      setCopied(`${label} disalin`);
    } catch {
      setCopied(`${label} belum dapat disalin`);
    }
  };

  const submit = async () => {
    if (!file) return;
    if (canRepeatLocalUpload) {
      setLocalTestPending(true);
      setLocalTestResult(undefined);
      setLocalTestError(undefined);
      setProgress({ value: 0.25, message: 'Memproses foto uji lokal…' });
      try {
        await normalizeBrowserImageOffMainThread(file, { maxWidth: 2_048, maxHeight: 2_048 });
        setProgress({ value: 0, message: '' });
        selectFile(undefined);
        setLocalTestResult('Foto uji berhasil diproses. Bukti yang sedang diperiksa Admin tidak diubah.');
      } catch {
        setProgress({ value: 0, message: '' });
        setLocalTestError('Foto uji belum dapat diproses. Pilih foto lain lalu coba kembali.');
      } finally {
        setLocalTestPending(false);
      }
      return;
    }
    try {
      await submitEvidence.mutateAsync({ orderId: order.id, file, idempotencyKey: uploadKey.current, onProgress: (value, message) => setProgress({ value, message }) });
      selectFile(undefined);
    } catch {
      setProgress({ value: 0, message: '' });
    }
  };

  return (
    <ScrollView contentContainerStyle={styles.screen} style={styles.scrollArea} testID="participant.payment.order">
      <Card>
        <View style={styles.between}>
          <Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>Pembayaran program</Text>
          <StatusBadge label={presentation.label} tone={presentation.tone} />
        </View>
        <Detail label="Program" value={programTitle} />
        <Detail
          label="Jumlah"
          value={rupiahFormatter.format(order.amount_minor)}
          numeric
          copyLabel="Salin jumlah pembayaran"
          onCopy={() => void copy('Jumlah', String(order.amount_minor))}
        />
        {copied?.startsWith('Jumlah') ? <Text accessibilityLiveRegion="polite" style={[styles.copyFeedback, { color: colors.secondaryText }]}>{copied}</Text> : null}
        <Detail label="ID pembayaran" value={order.id} numeric />
        <InlineMessage title={presentation.label} message={presentation.message} tone={presentation.tone} />
        {order.latest_rejection_reason ? <InlineMessage title="Alasan Admin" message={order.latest_rejection_reason} tone="destructive" /> : null}
      </Card>

      {canUpload ? (
        <Card>
          <Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>Tujuan pembayaran</Text>
          {order.qris_object_path_snapshot ? (
            <View style={styles.qrisBlock}>
              <Text accessibilityRole="header" style={[styles.cardTitle, { color: colors.primaryText }]}>QRIS</Text>
              <PrivateDestinationImage objectPath={order.qris_object_path_snapshot} />
            </View>
          ) : null}
          <Detail label="Bank" value={`${order.bank_code_snapshot} · ${order.bank_name_snapshot}`} />
          <Detail label="Atas nama" value={order.account_name_snapshot} />
          <Detail
            label="Nomor rekening"
            value={order.account_reference_snapshot}
            numeric
            copyLabel="Salin nomor rekening"
            onCopy={() => void copy('Nomor rekening', order.account_reference_snapshot)}
          />
          {copied?.startsWith('Nomor rekening') ? <Text accessibilityLiveRegion="polite" style={[styles.copyFeedback, { color: colors.secondaryText }]}>{copied}</Text> : null}
          <Text style={[styles.body, { color: colors.secondaryText }]}>{order.instructions_snapshot}</Text>
          {order.reservation_expires_at ? <Text style={[styles.caption, { color: colors.secondaryText }]}>Selesaikan sebelum {formatDateTime(order.reservation_expires_at)}.</Text> : null}
        </Card>
      ) : null}

      {showUploadSection ? (
        <Card>
          <Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>Bukti pembayaran</Text>
          {order.status === 'under_review' ? (
            <InlineMessage
              title="Upload dikunci sementara"
              message="Bukti sudah terkirim dan sedang diperiksa Admin. Upload bukti pembayaran akan terbuka kembali jika Admin menolak."
              tone="warning"
            />
          ) : null}
          {canRepeatLocalUpload ? (
            <InlineMessage
              title="Mode pengujian lokal"
              message="Kamu tetap dapat memilih dan memproses foto berulang. Foto uji berikut tidak dikirim ke Admin dan tidak mengganti bukti yang sedang diperiksa."
              tone="info"
            />
          ) : null}
          {previewUrl ? <Image accessibilityLabel="Pratinjau bukti pembayaran" resizeMode="contain" source={{ uri: previewUrl }} style={[styles.preview, { backgroundColor: colors.secondaryBackground }]} /> : null}
          {Platform.OS === 'web' ? (
            <View style={styles.uploadAction}>
              <label
                className="payment-file-button"
                style={fileButtonStyle(colors, uploadBusy)}
              >
                {uploadLabel}
                <input
                  ref={evidenceInputRef}
                  accept="image/jpeg,image/png,image/webp,image/heic,image/heif"
                  aria-label={uploadLabel}
                  className="payment-native-file-input"
                  disabled={uploadBusy}
                  onChange={(event) => {
                    const selectedFile = event.currentTarget.files?.[0];
                    event.currentTarget.value = '';
                    setLocalTestResult(undefined);
                    setLocalTestError(undefined);
                    selectFile(selectedFile);
                  }}
                  style={fileInputOverlayStyle}
                  type="file"
                />
              </label>
            </View>
          ) : null}
          {file ? <Text style={[styles.fileName, { color: colors.secondaryText }]}>{file.name}</Text> : null}
          {progress.value > 0 && progress.value < 1 ? <ProgressBar label={progress.message} value={progress.value} /> : null}
          {submitEvidence.error instanceof Error ? <InlineMessage title="Bukti belum terkirim" message={submitEvidence.error.message} tone="destructive" /> : null}
          {localTestResult ? <InlineMessage title="Uji upload selesai" message={localTestResult} tone="success" /> : null}
          {localTestError ? <InlineMessage title="Uji upload belum selesai" message={localTestError} tone="destructive" /> : null}
          {file ? (
            <Button
              label={canRepeatLocalUpload ? 'Selesaikan uji upload lokal' : 'Kirim bukti pembayaran'}
              loading={uploadBusy}
              onPress={() => void submit()}
            />
          ) : null}
        </Card>
      ) : null}

      {order.status === 'under_review' && !canRepeatLocalUpload ? (
        <Card>
          <Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>Bukti pembayaran</Text>
          <InlineMessage
            title="Upload dikunci sementara"
            message="Bukti sudah terkirim dan sedang diperiksa Admin. Upload bukti pembayaran akan terbuka kembali jika Admin menolak."
            tone="warning"
          />
        </Card>
      ) : null}

      <Button label="Kembali ke program" tone="secondary" icon="back" onPress={() => router.replace(`/app/programs/${order.program_id}` as never)} />
    </ScrollView>
  );
}

function PrivateDestinationImage({ objectPath }: { objectPath: string }) {
  const { colors } = useAppTheme();
  const [url, setUrl] = useState<string>();
  const [failed, setFailed] = useState(false);
  useEffect(() => {
    let active = true;
    let cleanup: (() => void) | undefined;
    void getPaymentRepository().downloadDestinationAsset(objectPath).then((blob) => {
      if (!active) return;
      const nextUrl = URL.createObjectURL(blob);
      const unregister = registerPrivateObjectUrl(nextUrl);
      cleanup = () => { URL.revokeObjectURL(nextUrl); unregister(); };
      setUrl(nextUrl);
    }).catch(() => { if (active) setFailed(true); });
    return () => { active = false; cleanup?.(); };
  }, [objectPath]);
  if (failed) return <InlineMessage title="QRIS tidak dapat dimuat" message="Gunakan transfer bank atau muat ulang halaman." tone="destructive" />;
  if (!url) return <StateView kind="loading" />;
  return <Image accessibilityLabel="QRIS tujuan pembayaran" resizeMode="contain" source={{ uri: url }} style={[styles.qris, { backgroundColor: colors.secondaryBackground }]} />;
}

function Detail({
  label,
  value,
  numeric = false,
  copyLabel,
  onCopy,
}: {
  label: string;
  value: string;
  numeric?: boolean;
  copyLabel?: string;
  onCopy?: () => void;
}) {
  const { colors } = useAppTheme();
  return (
    <View style={styles.detail}>
      <Text style={[styles.caption, { color: colors.secondaryText }]}>{label}</Text>
      <View style={styles.detailValueRow}>
        <Text selectable style={[styles.cardTitle, numeric && styles.numeric, styles.detailValue, { color: colors.primaryText }]}>{value}</Text>
        {copyLabel && onCopy ? <IconButton label={copyLabel} icon="copy" onPress={onCopy} /> : null}
      </View>
    </View>
  );
}

function formatDateTime(value: string) {
  return new Intl.DateTimeFormat('id-ID', { dateStyle: 'medium', timeStyle: 'short', timeZone: 'Asia/Makassar' }).format(new Date(value));
}

function copyTextWithTemporaryField(value: string) {
  if (typeof document === 'undefined' || typeof document.execCommand !== 'function') return false;
  const previousFocus = document.activeElement as HTMLElement | null;
  const field = document.createElement('textarea');
  field.value = value;
  field.readOnly = true;
  field.setAttribute('aria-hidden', 'true');
  Object.assign(field.style, { position: 'fixed', inset: '0 auto auto 0', opacity: '0', pointerEvents: 'none' });
  document.body.appendChild(field);
  field.select();
  try {
    return document.execCommand('copy');
  } finally {
    field.remove();
    previousFocus?.focus();
  }
}

const fileInputOverlayStyle = {
  cursor: 'pointer',
  height: '100%',
  inset: 0,
  opacity: 0.01,
  position: 'absolute',
  width: '100%',
} as const;

function fileButtonStyle(
  colors: ReturnType<typeof useAppTheme>['colors'],
  disabled: boolean,
) {
  return {
    alignItems: 'center',
    appearance: 'none',
    backgroundColor: colors.surface,
    border: `2px solid ${colors.border}`,
    borderRadius: primitiveTokens.radius.medium,
    boxShadow: `0 4px 0 ${colors.border}`,
    color: colors.primaryText,
    cursor: disabled ? 'not-allowed' : 'pointer',
    display: 'inline-flex',
    fontFamily: 'inherit',
    fontSize: typographyTokens.bodyStrong.fontSize,
    fontWeight: typographyTokens.bodyStrong.fontWeight,
    justifyContent: 'center',
    minHeight: 52,
    opacity: disabled ? 0.55 : 1,
    padding: '12px 20px',
    position: 'relative',
    transform: 'translateY(0) scale(1)',
    transition: `background-color ${primitiveTokens.duration.fast}ms ${primitiveTokens.easing.standard}, box-shadow ${primitiveTokens.duration.fast}ms ${primitiveTokens.easing.standard}, transform ${primitiveTokens.duration.fast}ms ${primitiveTokens.easing.standard}`,
  } as const;
}

const styles = StyleSheet.create({
  scrollArea: { flex: 1, minHeight: 0, width: '100%' },
  screen: { width: '100%', maxWidth: 900, alignSelf: 'center', padding: primitiveTokens.space.large, gap: primitiveTokens.space.large },
  row: { flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.medium },
  between: { flexDirection: 'row', flexWrap: 'wrap', alignItems: 'center', justifyContent: 'space-between', gap: primitiveTokens.space.small },
  flexCopy: { flex: 1, minWidth: 0, gap: primitiveTokens.space.xxSmall },
  detail: { gap: primitiveTokens.space.xxSmall },
  detailValueRow: { flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.xSmall },
  detailValue: { flexShrink: 1 },
  preview: { width: '100%', height: 280, borderRadius: primitiveTokens.radius.large },
  uploadAction: { alignItems: 'center' },
  qrisBlock: { gap: primitiveTokens.space.small },
  qris: { width: '100%', maxWidth: 360, height: 360, alignSelf: 'center', borderRadius: primitiveTokens.radius.large },
  heading: typographyTokens.headline,
  cardTitle: typographyTokens.bodyStrong,
  body: typographyTokens.body,
  caption: typographyTokens.caption,
  copyFeedback: { ...typographyTokens.caption, textAlign: 'center' },
  fileName: { ...typographyTokens.caption, textAlign: 'center' },
  numeric: { fontVariant: ['tabular-nums'] },
});
