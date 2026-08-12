import { useState } from 'react';
import { Button, ScrollView, StyleSheet, Text, View } from 'react-native';

import { componentTokens, primitiveTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { createPkceSupabaseClient } from '@/shared/auth/create-pkce-supabase-client';
import { SupabaseGoogleOAuthAdapter } from '@/shared/auth/supabase-google-oauth-adapter';
import { normalizeBrowserImage } from '@/shared/media/image-normalization';
import { AppShell } from '@/shared/navigation/AppShell';
import { QRScanner } from '@/shared/qr/QRScanner';

export default function FeasibilityRoute() {
  const { colors } = useAppTheme();
  const [isScannerOpen, setIsScannerOpen] = useState(false);
  const [scanStatus, setScanStatus] = useState('Belum ada QR yang dipindai.');
  const [imageStatus, setImageStatus] = useState('Pipeline gambar belum diuji.');
  const [oauthStatus, setOauthStatus] = useState('Alur Google OAuth belum dimulai.');

  async function runImageProbe() {
    setImageStatus('Memproses gambar uji di browser…');

    try {
      const input = await createExifOrientationSixJpeg();
      const normalized = await normalizeBrowserImage(input);
      const outputBytes = new Uint8Array(await normalized.blob.arrayBuffer());
      const outputText = new TextDecoder('latin1').decode(outputBytes);
      if (outputText.includes('2026:08:12')) {
        throw new Error('metadata remained');
      }
      setImageStatus(
        `Berhasil: ${normalized.width}×${normalized.height}, JPEG tanpa EXIF/GPS, ${normalized.byteSize} byte.`,
      );
    } catch {
      setImageStatus('Pipeline gambar gagal. Perbarui browser lalu coba lagi.');
    }
  }

  async function beginGoogleOAuth() {
    const url = process.env.EXPO_PUBLIC_SUPABASE_URL;
    const publishableKey = process.env.EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
    const callbackUrl = process.env.EXPO_PUBLIC_AUTH_REDIRECT_URL;

    if (!url || !publishableKey || !callbackUrl) {
      setOauthStatus('Konfigurasi OAuth lokal belum tersedia.');
      return;
    }

    setOauthStatus('Membuka Google untuk masuk…');
    try {
      const client = createPkceSupabaseClient({ url, publishableKey });
      const adapter = new SupabaseGoogleOAuthAdapter(client, callbackUrl);
      await adapter.signIn('/app/feasibility');
    } catch {
      setOauthStatus('Google tidak dapat dihubungi. Periksa koneksi lalu coba lagi.');
    }
  }

  return (
    <AppShell activeRoute="programs" title="Uji fondasi">
      <ScrollView contentContainerStyle={styles.content}>
        <View style={[styles.panel, { backgroundColor: colors.surface, borderColor: colors.border }]}>
          <Text accessibilityRole="header" style={[styles.title, { color: colors.primaryText }]}>Pemindai QR Coach</Text>
          <Text style={[styles.body, { color: colors.secondaryText }]}>
            Kamera hanya diminta saat pemindai dibuka. Tidak ada kolom kode manual.
          </Text>
          <Text accessibilityLiveRegion="polite" style={[styles.status, { color: colors.primaryText }]}>
            {scanStatus}
          </Text>
          {isScannerOpen ? (
            <QRScanner
              onClose={() => setIsScannerOpen(false)}
              onScan={() => {
                setScanStatus('QR terdeteksi. Payload diteruskan ke boundary validasi tanpa ditampilkan.');
                setIsScannerOpen(false);
              }}
            />
          ) : (
            <Button
              color={colors.primaryAction}
              title="Buka pemindai QR"
              onPress={() => setIsScannerOpen(true)}
            />
          )}
        </View>

        <View style={[styles.panel, { backgroundColor: colors.surface, borderColor: colors.border }]}>
          <Text accessibilityRole="header" style={[styles.title, { color: colors.primaryText }]}>Normalisasi gambar</Text>
          <Text style={[styles.body, { color: colors.secondaryText }]}>Uji ini mendekode, mengecilkan, dan menulis ulang gambar sebagai JPEG tanpa metadata sumber.</Text>
          <Text accessibilityLiveRegion="polite" style={[styles.status, { color: colors.primaryText }]}>{imageStatus}</Text>
          <Button color={colors.primaryAction} title="Uji pipeline gambar" onPress={runImageProbe} />
        </View>

        <View style={[styles.panel, { backgroundColor: colors.surface, borderColor: colors.border }]}>
          <Text accessibilityRole="header" style={[styles.title, { color: colors.primaryText }]}>Google OAuth lokal</Text>
          <Text style={[styles.body, { color: colors.secondaryText }]}>PKCE menyimpan verifier di browser ini dan hanya kembali ke route internal yang diizinkan.</Text>
          <Text accessibilityLiveRegion="polite" style={[styles.status, { color: colors.primaryText }]}>{oauthStatus}</Text>
          <Button color={colors.primaryAction} title="Uji masuk dengan Google" onPress={beginGoogleOAuth} />
        </View>
      </ScrollView>
    </AppShell>
  );
}

const styles = StyleSheet.create({
  content: {
    flexGrow: 1,
    width: '100%',
    maxWidth: componentTokens.contentMaxWidth,
    alignSelf: 'center',
    padding: primitiveTokens.space.large,
    gap: primitiveTokens.space.large,
  },
  panel: {
    borderWidth: StyleSheet.hairlineWidth,
    borderRadius: primitiveTokens.radius.large,
    padding: primitiveTokens.space.large,
    gap: primitiveTokens.space.medium,
  },
  title: {
    fontSize: 24,
    lineHeight: 30,
    fontWeight: '700',
  },
  body: {
    fontSize: 16,
    lineHeight: 24,
  },
  status: {
    fontSize: 15,
    lineHeight: 22,
  },
});

async function createExifOrientationSixJpeg(): Promise<Blob> {
  const canvas = document.createElement('canvas');
  canvas.width = 3_200;
  canvas.height = 2_400;
  const context = canvas.getContext('2d');
  if (context === null) throw new Error('canvas unavailable');

  context.fillStyle = '#D71920';
  context.fillRect(0, 0, 1_600, 2_400);
  context.fillStyle = '#FFD400';
  context.fillRect(1_600, 0, 1_600, 2_400);

  const source = await new Promise<Blob>((resolve, reject) => {
    canvas.toBlob((blob) => (blob === null ? reject(new Error('encode failed')) : resolve(blob)), 'image/jpeg', 0.9);
  });
  const jpeg = new Uint8Array(await source.arrayBuffer());
  const tiff = new Uint8Array(67);
  const view = new DataView(tiff.buffer);

  tiff.set([0x4d, 0x4d], 0); // Big-endian TIFF.
  view.setUint16(2, 42);
  view.setUint32(4, 8);
  view.setUint16(8, 2);
  view.setUint16(10, 0x0112); // Orientation.
  view.setUint16(12, 3);
  view.setUint32(14, 1);
  view.setUint16(18, 6); // Rotate 90° clockwise.
  view.setUint16(22, 0x8825); // GPS IFD pointer.
  view.setUint16(24, 4);
  view.setUint32(26, 1);
  view.setUint32(30, 38);
  view.setUint32(34, 0);
  view.setUint16(38, 1);
  view.setUint16(40, 0x001d); // GPS date stamp.
  view.setUint16(42, 2);
  view.setUint32(44, 11);
  view.setUint32(48, 56);
  view.setUint32(52, 0);
  tiff.set(new TextEncoder().encode('2026:08:12\0'), 56);

  const exifPrefix = new Uint8Array([0x45, 0x78, 0x69, 0x66, 0, 0]);
  const payloadLength = exifPrefix.length + tiff.length;
  const app1 = new Uint8Array(payloadLength + 4);
  app1.set([0xff, 0xe1, (payloadLength + 2) >> 8, (payloadLength + 2) & 0xff], 0);
  app1.set(exifPrefix, 4);
  app1.set(tiff, 10);

  return new Blob([jpeg.subarray(0, 2), app1, jpeg.subarray(2)], { type: 'image/jpeg' });
}
