import { beforeEach, describe, expect, it, vi } from 'vitest';

import { ExpoQrCameraAdapter } from '../../src/shared/qr/expo-qr-camera-adapter';
import { resolveQrScannerState } from '../../src/shared/qr/qr-camera-adapter';

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
});
