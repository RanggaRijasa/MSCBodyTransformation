export type QrScannerSession = Readonly<{
  destroy: () => void;
  start: () => Promise<void>;
  stop: () => void;
}>;

export type QrDecoder = Readonly<{
  createSession: (
    video: HTMLVideoElement,
    onDecode: (rawValue: string) => void,
  ) => Promise<QrScannerSession>;
  hasCamera: () => Promise<boolean>;
  scanImage: (file: File) => Promise<string>;
}>;

export const browserQrDecoder: QrDecoder = {
  async createSession(video, onDecode) {
    const { default: QrScanner } = await import("qr-scanner");
    const scanner = new QrScanner(video, (result) => onDecode(result.data), {
      calculateScanRegion: (source) => {
        const size = Math.min(source.videoWidth, source.videoHeight);
        const x = Math.max(0, (source.videoWidth - size) / 2);
        const y = Math.max(0, (source.videoHeight - size) / 2);
        return { downScaledHeight: 400, downScaledWidth: 400, height: size, width: size, x, y };
      },
      highlightCodeOutline: true,
      highlightScanRegion: true,
      maxScansPerSecond: 10,
      preferredCamera: "environment",
      returnDetailedScanResult: true,
    });
    return {
      destroy: () => scanner.destroy(),
      start: () => scanner.start(),
      stop: () => scanner.stop(),
    };
  },
  async hasCamera() {
    const { default: QrScanner } = await import("qr-scanner");
    return QrScanner.hasCamera();
  },
  async scanImage(file) {
    const { default: QrScanner } = await import("qr-scanner");
    const result = await QrScanner.scanImage(file, {
      alsoTryWithoutScanRegion: true,
      returnDetailedScanResult: true,
    });
    return result.data;
  },
};
