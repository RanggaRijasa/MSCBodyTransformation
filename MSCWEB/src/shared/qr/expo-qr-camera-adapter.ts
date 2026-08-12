import { Camera, CameraView, type PermissionResponse } from 'expo-camera';

import type { QrCameraAdapter, QrCameraPermission } from './qr-camera-adapter';

export class ExpoQrCameraAdapter implements QrCameraAdapter {
  async isAvailable(): Promise<boolean> {
    return await CameraView.isAvailableAsync();
  }

  async getPermission(): Promise<QrCameraPermission> {
    return mapPermission(await Camera.getCameraPermissionsAsync());
  }

  async requestPermission(): Promise<QrCameraPermission> {
    return mapPermission(await Camera.requestCameraPermissionsAsync());
  }
}

function mapPermission(permission: PermissionResponse): QrCameraPermission {
  const status =
    permission.status === 'granted'
      ? 'granted'
      : permission.status === 'denied'
        ? 'denied'
        : 'undetermined';

  return {
    status,
    canAskAgain: permission.canAskAgain,
  };
}
