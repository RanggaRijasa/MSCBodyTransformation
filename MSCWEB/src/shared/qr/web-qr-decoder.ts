import { BarcodeDetector, prepareZXingModule } from 'barcode-detector';

const zxingReaderWasmPath = '/wasm/zxing-reader-3.1.1-6a858c01.wasm';
const maximumFrameDimension = 960;

let decoderPreparation: Promise<unknown> | undefined;
let qrDetector: BarcodeDetector | undefined;
let frameCanvas: HTMLCanvasElement | undefined;

export function isIosWebKitDevice(
  userAgent: string,
  platform: string,
  maximumTouchPoints: number,
): boolean {
  return /iPad|iPhone|iPod/iu.test(userAgent)
    || (platform === 'MacIntel' && maximumTouchPoints > 1);
}

export function scaledQrFrameSize(
  sourceWidth: number,
  sourceHeight: number,
): { width: number; height: number } {
  const scale = Math.min(1, maximumFrameDimension / Math.max(sourceWidth, sourceHeight));
  return {
    width: Math.max(1, Math.round(sourceWidth * scale)),
    height: Math.max(1, Math.round(sourceHeight * scale)),
  };
}

export async function prepareWebQrDecoder(): Promise<void> {
  decoderPreparation ??= Promise.resolve(prepareZXingModule({
    fireImmediately: true,
    overrides: {
      locateFile: (path: string, prefix: string) => path.endsWith('.wasm')
        ? zxingReaderWasmPath
        : `${prefix}${path}`,
    },
  }));
  await decoderPreparation;
}

export async function scanIosWebQrFrame(video: HTMLVideoElement): Promise<string | null> {
  if (video.readyState < HTMLMediaElement.HAVE_CURRENT_DATA
    || video.videoWidth <= 0
    || video.videoHeight <= 0) return null;

  await prepareWebQrDecoder();
  qrDetector ??= new BarcodeDetector({ formats: ['qr_code'] });
  frameCanvas ??= document.createElement('canvas');

  const size = scaledQrFrameSize(video.videoWidth, video.videoHeight);
  if (frameCanvas.width !== size.width) frameCanvas.width = size.width;
  if (frameCanvas.height !== size.height) frameCanvas.height = size.height;
  const context = frameCanvas.getContext('2d', { alpha: false, willReadFrequently: true });
  if (!context) throw new Error('qr_canvas_unavailable');
  context.drawImage(video, 0, 0, size.width, size.height);

  const results = await qrDetector.detect(frameCanvas);
  return results.find((result) => result.format === 'qr_code')?.rawValue ?? null;
}
