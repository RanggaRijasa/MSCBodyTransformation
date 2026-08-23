import { beforeEach, describe, expect, it, vi } from 'vitest';

import { ExpoQrCameraAdapter } from '../../src/shared/qr/expo-qr-camera-adapter';
import { resolveQrScannerState } from '../../src/shared/qr/qr-camera-adapter';
import { isQrDarkModule } from '../../src/shared/qr/qr-matrix';
import { isIosWebKitDevice, scaledQrFrameSize } from '../../src/shared/qr/web-qr-decoder';

const cameraMocks = vi.hoisted(() => ({
  isAvailableAsync: vi.fn(),
  getCameraPermissionsAsync: vi.fn(),
  requestCameraPermissionsAsync: vi.fn(),
}));

vi.mock('expo-camera', () => ({
  CameraView: { isAvailableAsync: cameraMocks.isAvailableAsync },
  Camera: {
    getCameraPermissionsAsync: cameraMocks.getCameraPermissionsAsync,
    requestCameraPermissionsAsync: cameraMocks.requestCameraPermissionsAsync,
  },
}));

describe('Expo QR camera adapter', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('maps Expo availability and permission without exposing framework types', async () => {
    cameraMocks.isAvailableAsync.mockResolvedValue(true);
    cameraMocks.getCameraPermissionsAsync.mockResolvedValue({
      status: 'granted',
      canAskAgain: true,
    });
    const adapter = new ExpoQrCameraAdapter();

    await expect(adapter.isAvailable()).resolves.toBe(true);
    await expect(adapter.getPermission()).resolves.toEqual({
      status: 'granted',
      canAskAgain: true,
    });
  });

  it('requests permission only through the narrow adapter', async () => {
    cameraMocks.requestCameraPermissionsAsync.mockResolvedValue({
      status: 'denied',
      canAskAgain: false,
    });
    const adapter = new ExpoQrCameraAdapter();

    await expect(adapter.requestPermission()).resolves.toEqual({
      status: 'denied',
      canAskAgain: false,
    });
  });
});

describe('QR scanner state', () => {
  it('represents unavailable, denied, and ready states explicitly', () => {
    expect(
      resolveQrScannerState(false, { status: 'undetermined', canAskAgain: true }),
    ).toEqual({ kind: 'unavailable' });
    expect(resolveQrScannerState(true, { status: 'denied', canAskAgain: false })).toEqual({
      kind: 'denied',
      canAskAgain: false,
    });
    expect(resolveQrScannerState(true, { status: 'granted', canAskAgain: true })).toEqual({
      kind: 'ready',
    });
  });

  it('detects iPhone, iPad, and touch-enabled iPad desktop identity for fallback scanning', () => {
    expect(isIosWebKitDevice('Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X)', 'iPhone', 5)).toBe(true);
    expect(isIosWebKitDevice('Mozilla/5.0 (Macintosh; Intel Mac OS X)', 'MacIntel', 5)).toBe(true);
    expect(isIosWebKitDevice('Mozilla/5.0 (Macintosh; Intel Mac OS X)', 'MacIntel', 0)).toBe(false);
    expect(isIosWebKitDevice('Mozilla/5.0 (Linux; Android 15)', 'Linux armv8l', 5)).toBe(false);
  });

  it('bounds fallback camera frames without changing their aspect ratio', () => {
    expect(scaledQrFrameSize(1920, 1080)).toEqual({ width: 960, height: 540 });
    expect(scaledQrFrameSize(720, 1280)).toEqual({ width: 540, height: 960 });
    expect(scaledQrFrameSize(640, 480)).toEqual({ width: 640, height: 480 });
  });

  it('renders nonzero toqr modules as dark instead of producing an inverted QR', () => {
    expect(isQrDarkModule(1)).toBe(true);
    expect(isQrDarkModule(0)).toBe(false);
  });
});
