import { CameraView, type BarcodeScanningResult } from 'expo-camera';
import { useCallback, useEffect, useRef, useState } from 'react';
import { ActivityIndicator, Button, StyleSheet, Text, View } from 'react-native';

import { primitiveTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';

import { ExpoQrCameraAdapter } from './expo-qr-camera-adapter';
import {
  type QrCameraAdapter,
  type QrScannerState,
  resolveQrScannerState,
} from './qr-camera-adapter';

export type QRScannerProps = Readonly<{
  onScan: (payload: string) => void;
  onClose: () => void;
  cameraAdapter?: QrCameraAdapter;
}>;

const defaultCameraAdapter = new ExpoQrCameraAdapter();

export function QRScanner({
  onScan,
  onClose,
  cameraAdapter = defaultCameraAdapter,
}: QRScannerProps) {
  const { colors } = useAppTheme();
  const [state, setState] = useState<QrScannerState>({ kind: 'loading' });
  const hasScanned = useRef(false);

  const loadCamera = useCallback(async () => {
    setState({ kind: 'loading' });
    try {
      const isAvailable = await cameraAdapter.isAvailable();
      if (!isAvailable) {
        setState({ kind: 'unavailable' });
        return;
      }

      const permission = await cameraAdapter.getPermission();
      setState(resolveQrScannerState(isAvailable, permission));
    } catch {
      setState({ kind: 'error' });
    }
  }, [cameraAdapter]);

  useEffect(() => {
    let isMounted = true;

    async function load(): Promise<void> {
      try {
        const isAvailable = await cameraAdapter.isAvailable();
        if (!isMounted) return;
        if (!isAvailable) {
          setState({ kind: 'unavailable' });
          return;
        }

        const permission = await cameraAdapter.getPermission();
        if (isMounted) setState(resolveQrScannerState(isAvailable, permission));
      } catch {
        if (isMounted) setState({ kind: 'error' });
      }
    }

    void load();
    return () => {
      isMounted = false;
    };
  }, [cameraAdapter]);

  const requestPermission = useCallback(async () => {
    setState({ kind: 'loading' });
    try {
      const permission = await cameraAdapter.requestPermission();
      setState(resolveQrScannerState(true, permission));
    } catch {
      setState({ kind: 'error' });
    }
  }, [cameraAdapter]);

  const handleScan = useCallback(
    (result: BarcodeScanningResult) => {
      if (hasScanned.current || result.type !== 'qr') return;
      hasScanned.current = true;
      onScan(result.data);
    },
    [onScan],
  );

  if (state.kind === 'loading') {
    return (
      <View
        accessibilityRole="progressbar"
        style={[styles.stateContainer, { backgroundColor: colors.surface }]}
      >
        <ActivityIndicator />
        <Text style={{ color: colors.primaryText }}>Menyiapkan kamera…</Text>
      </View>
    );
  }

  if (state.kind === 'unavailable') {
    return (
      <ScannerMessage
        colors={colors}
        title="Kamera tidak tersedia"
        message="Kamera tidak tersedia di perangkat atau browser ini."
        onClose={onClose}
      />
    );
  }

  if (state.kind === 'denied') {
    return (
      <View
        accessibilityRole="alert"
        style={[styles.stateContainer, { backgroundColor: colors.surface }]}
      >
        <Text style={[styles.title, { color: colors.primaryText }]}>Izin kamera diperlukan</Text>
        <Text style={[styles.message, { color: colors.secondaryText }]}>
          {state.canAskAgain
            ? 'Izinkan kamera untuk memindai QR Coach.'
            : 'Izin kamera ditolak. Aktifkan izin kamera di pengaturan browser, lalu coba lagi.'}
        </Text>
        {state.canAskAgain ? (
          <Button color={colors.primaryAction} title="Izinkan kamera" onPress={requestPermission} />
        ) : null}
        <Button color={colors.primaryAction} title="Tutup" onPress={onClose} />
      </View>
    );
  }

  if (state.kind === 'error') {
    return (
      <View
        accessibilityRole="alert"
        style={[styles.stateContainer, { backgroundColor: colors.surface }]}
      >
        <Text style={[styles.title, { color: colors.primaryText }]}>Kamera tidak dapat dibuka</Text>
        <Text style={[styles.message, { color: colors.secondaryText }]}>
          Periksa izin kamera, lalu coba lagi.
        </Text>
        <Button color={colors.primaryAction} title="Coba lagi" onPress={loadCamera} />
        <Button color={colors.primaryAction} title="Tutup" onPress={onClose} />
      </View>
    );
  }

  return (
    <View style={[styles.scannerContainer, { backgroundColor: colors.surface }]}>
      <Text style={[styles.instructions, { color: colors.primaryText }]}>
        Arahkan kamera ke QR Coach.
      </Text>
      <CameraView
        active
        accessibilityLabel="Pemindai QR Coach"
        barcodeScannerSettings={{ barcodeTypes: ['qr'] }}
        facing="back"
        onBarcodeScanned={handleScan}
        onMountError={() => setState({ kind: 'error' })}
        style={styles.camera}
      />
      <Button color={colors.primaryAction} title="Tutup" onPress={onClose} />
    </View>
  );
}

function ScannerMessage({
  title,
  message,
  onClose,
  colors,
}: Readonly<{
  title: string;
  message: string;
  onClose: () => void;
  colors: ReturnType<typeof useAppTheme>['colors'];
}>) {
  return (
    <View
      accessibilityRole="alert"
      style={[styles.stateContainer, { backgroundColor: colors.surface }]}
    >
      <Text style={[styles.title, { color: colors.primaryText }]}>{title}</Text>
      <Text style={[styles.message, { color: colors.secondaryText }]}>{message}</Text>
      <Button color={colors.primaryAction} title="Tutup" onPress={onClose} />
    </View>
  );
}

const styles = StyleSheet.create({
  camera: {
    alignSelf: 'stretch',
    aspectRatio: 1,
    minHeight: 240,
  },
  instructions: {
    fontSize: 17,
    fontWeight: '600',
    textAlign: 'center',
  },
  message: {
    fontSize: 16,
    lineHeight: 24,
    textAlign: 'center',
  },
  scannerContainer: {
    gap: primitiveTokens.space.medium,
    padding: primitiveTokens.space.medium,
  },
  stateContainer: {
    alignItems: 'center',
    gap: primitiveTokens.space.small,
    justifyContent: 'center',
    minHeight: 240,
    padding: primitiveTokens.space.large,
  },
  title: {
    fontSize: 20,
    fontWeight: '700',
    textAlign: 'center',
  },
});
