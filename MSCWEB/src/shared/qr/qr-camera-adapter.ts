export type QrCameraPermission = Readonly<{
  status: 'granted' | 'denied' | 'undetermined';
  canAskAgain: boolean;
}>;

export interface QrCameraAdapter {
  isAvailable(): Promise<boolean>;
  getPermission(): Promise<QrCameraPermission>;
  requestPermission(): Promise<QrCameraPermission>;
}

export type QrScannerState =
  | Readonly<{ kind: 'loading' }>
  | Readonly<{ kind: 'ready' }>
  | Readonly<{ kind: 'unavailable' }>
  | Readonly<{ kind: 'denied'; canAskAgain: boolean }>
  | Readonly<{ kind: 'error' }>;

export function resolveQrScannerState(
  isAvailable: boolean,
  permission: QrCameraPermission,
): QrScannerState {
  if (!isAvailable) {
    return { kind: 'unavailable' };
  }
  if (permission.status === 'granted') {
    return { kind: 'ready' };
  }
  return { kind: 'denied', canAskAgain: permission.canAskAgain };
}
