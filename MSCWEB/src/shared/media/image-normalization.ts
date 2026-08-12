export const MAX_IMAGE_INPUT_BYTES = 8 * 1024 * 1024;
export const DEFAULT_IMAGE_MAX_WIDTH = 2_048;
export const DEFAULT_IMAGE_MAX_HEIGHT = 2_048;
export const DEFAULT_JPEG_QUALITY = 0.82;

const SUPPORTED_IMAGE_MIME_TYPES = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/heic',
  'image/heif',
]);

export type ImageNormalizationErrorCode =
  | 'fileTooLarge'
  | 'unsupportedType'
  | 'decodeFailed'
  | 'invalidDimensions'
  | 'canvasUnavailable'
  | 'encodeFailed';

const JPEG_START_OF_IMAGE = [0xff, 0xd8, 0xff] as const;

const ERROR_MESSAGES: Record<ImageNormalizationErrorCode, string> = {
  fileTooLarge: 'Ukuran foto terlalu besar. Pilih foto berukuran maksimal 8 MB.',
  unsupportedType: 'Format foto tidak didukung. Pilih foto JPEG, PNG, WebP, HEIC, atau HEIF.',
  decodeFailed: 'Foto tidak dapat dibaca. Pilih foto lain lalu coba lagi.',
  invalidDimensions: 'Ukuran foto tidak valid. Pilih foto lain lalu coba lagi.',
  canvasUnavailable: 'Foto tidak dapat diproses di browser ini. Perbarui browser lalu coba lagi.',
  encodeFailed: 'Foto gagal diproses. Pilih foto lain lalu coba lagi.',
};

export class ImageNormalizationError extends Error {
  readonly code: ImageNormalizationErrorCode;

  constructor(code: ImageNormalizationErrorCode) {
    super(ERROR_MESSAGES[code]);
    this.name = 'ImageNormalizationError';
    this.code = code;
  }
}

export type ImageDimensions = Readonly<{
  width: number;
  height: number;
}>;

export type DecodedBrowserImage = ImageDimensions &
  Readonly<{
    source: CanvasImageSource;
    close?: () => void;
  }>;

export interface ImageNormalizationRuntime {
  decode(input: Blob): Promise<DecodedBrowserImage>;
  renderJpeg(
    image: DecodedBrowserImage,
    outputDimensions: ImageDimensions,
    quality: number,
  ): Promise<Blob>;
}

export type ImageNormalizationOptions = Readonly<{
  maxWidth?: number;
  maxHeight?: number;
  quality?: number;
}>;

export type NormalizedImage = Readonly<{
  blob: Blob;
  mimeType: 'image/jpeg';
  width: number;
  height: number;
  byteSize: number;
}>;

export function validateImageInput(input: Pick<Blob, 'size' | 'type'>): void {
  if (!SUPPORTED_IMAGE_MIME_TYPES.has(input.type.toLowerCase())) {
    throw new ImageNormalizationError('unsupportedType');
  }
}

export function calculateContainSize(
  input: ImageDimensions,
  maximum: ImageDimensions,
): ImageDimensions {
  if (
    !Number.isFinite(input.width) ||
    !Number.isFinite(input.height) ||
    input.width <= 0 ||
    input.height <= 0 ||
    !Number.isFinite(maximum.width) ||
    !Number.isFinite(maximum.height) ||
    maximum.width <= 0 ||
    maximum.height <= 0
  ) {
    throw new ImageNormalizationError('invalidDimensions');
  }

  const scale = Math.min(1, maximum.width / input.width, maximum.height / input.height);

  return {
    width: Math.max(1, Math.round(input.width * scale)),
    height: Math.max(1, Math.round(input.height * scale)),
  };
}

export async function normalizeBrowserImage(
  input: Blob,
  options: ImageNormalizationOptions = {},
  runtime: ImageNormalizationRuntime = browserImageNormalizationRuntime,
): Promise<NormalizedImage> {
  validateImageInput(input);

  const maxWidth = options.maxWidth ?? DEFAULT_IMAGE_MAX_WIDTH;
  const maxHeight = options.maxHeight ?? DEFAULT_IMAGE_MAX_HEIGHT;
  const quality = options.quality ?? DEFAULT_JPEG_QUALITY;

  if (!Number.isFinite(quality) || quality <= 0 || quality > 1) {
    throw new ImageNormalizationError('encodeFailed');
  }

  let decoded: DecodedBrowserImage;
  try {
    decoded = await runtime.decode(input);
  } catch (error) {
    if (error instanceof ImageNormalizationError) {
      throw error;
    }
    throw new ImageNormalizationError('decodeFailed');
  }

  try {
    const outputDimensions = calculateContainSize(decoded, {
      width: maxWidth,
      height: maxHeight,
    });
    const blob = await runtime.renderJpeg(decoded, outputDimensions, quality);

    if (blob.type !== 'image/jpeg') {
      throw new ImageNormalizationError('encodeFailed');
    }
    if (!(await hasJpegSignature(blob))) {
      throw new ImageNormalizationError('encodeFailed');
    }
    if (blob.size > MAX_IMAGE_INPUT_BYTES) {
      throw new ImageNormalizationError('fileTooLarge');
    }

    return {
      blob,
      mimeType: 'image/jpeg',
      width: outputDimensions.width,
      height: outputDimensions.height,
      byteSize: blob.size,
    };
  } catch (error) {
    if (error instanceof ImageNormalizationError) {
      throw error;
    }
    throw new ImageNormalizationError('encodeFailed');
  } finally {
    decoded.close?.();
  }
}

export async function normalizeBrowserImageOffMainThread(
  input: Blob,
  options: ImageNormalizationOptions = {},
): Promise<NormalizedImage> {
  validateImageInput(input);
  if (
    typeof Worker === 'undefined'
    || typeof OffscreenCanvas === 'undefined'
    || typeof URL.createObjectURL !== 'function'
  ) {
    return normalizeBrowserImage(input, options);
  }

  const maxWidth = options.maxWidth ?? DEFAULT_IMAGE_MAX_WIDTH;
  const maxHeight = options.maxHeight ?? DEFAULT_IMAGE_MAX_HEIGHT;
  const quality = options.quality ?? DEFAULT_JPEG_QUALITY;
  if (!Number.isFinite(quality) || quality <= 0 || quality > 1) {
    throw new ImageNormalizationError('encodeFailed');
  }

  const source = `self.onmessage = async ({ data }) => {
    try {
      const bitmap = await createImageBitmap(data.input, { imageOrientation: 'from-image' });
      const scale = Math.min(1, data.maxWidth / bitmap.width, data.maxHeight / bitmap.height);
      const width = Math.max(1, Math.round(bitmap.width * scale));
      const height = Math.max(1, Math.round(bitmap.height * scale));
      const canvas = new OffscreenCanvas(width, height);
      const context = canvas.getContext('2d');
      if (!context) throw new Error('canvas_unavailable');
      context.imageSmoothingEnabled = true;
      context.imageSmoothingQuality = 'high';
      context.drawImage(bitmap, 0, 0, width, height);
      bitmap.close();
      const blob = await canvas.convertToBlob({ type: 'image/jpeg', quality: data.quality });
      self.postMessage({ ok: true, blob, width, height });
    } catch {
      self.postMessage({ ok: false });
    }
  };`;
  const workerUrl = URL.createObjectURL(new Blob([source], { type: 'text/javascript' }));
  const worker = new Worker(workerUrl);
  try {
    const result = await new Promise<{ blob: Blob; width: number; height: number }>((resolve, reject) => {
      worker.onmessage = (event: MessageEvent<{ ok: boolean; blob?: Blob; width?: number; height?: number }>) => {
        const { data } = event;
        if (!data.ok || !data.blob || !data.width || !data.height) {
          reject(new ImageNormalizationError('decodeFailed'));
          return;
        }
        resolve({ blob: data.blob, width: data.width, height: data.height });
      };
      worker.onerror = () => reject(new ImageNormalizationError('decodeFailed'));
      worker.postMessage({ input, maxWidth, maxHeight, quality });
    });
    if (result.blob.type !== 'image/jpeg' || !(await hasJpegSignature(result.blob))) {
      throw new ImageNormalizationError('encodeFailed');
    }
    if (result.blob.size > MAX_IMAGE_INPUT_BYTES) throw new ImageNormalizationError('fileTooLarge');
    return {
      blob: result.blob,
      mimeType: 'image/jpeg',
      width: result.width,
      height: result.height,
      byteSize: result.blob.size,
    };
  } finally {
    worker.terminate();
    URL.revokeObjectURL(workerUrl);
  }
}

export async function hasJpegSignature(input: Blob): Promise<boolean> {
  if (input.size < JPEG_START_OF_IMAGE.length) return false;
  const signature = new Uint8Array(await input.slice(0, JPEG_START_OF_IMAGE.length).arrayBuffer());
  return JPEG_START_OF_IMAGE.every((byte, index) => signature[index] === byte);
}

export const browserImageNormalizationRuntime: ImageNormalizationRuntime = {
  async decode(input) {
    if (typeof createImageBitmap !== 'function') {
      throw new ImageNormalizationError('canvasUnavailable');
    }

    const bitmap = await createImageBitmap(input, { imageOrientation: 'from-image' });
    return {
      width: bitmap.width,
      height: bitmap.height,
      source: bitmap,
      close: () => bitmap.close(),
    };
  },

  async renderJpeg(image, outputDimensions, quality) {
    if (typeof document === 'undefined') {
      throw new ImageNormalizationError('canvasUnavailable');
    }

    const canvas = document.createElement('canvas');
    canvas.width = outputDimensions.width;
    canvas.height = outputDimensions.height;

    const context = canvas.getContext('2d');
    if (context === null) {
      throw new ImageNormalizationError('canvasUnavailable');
    }

    context.imageSmoothingEnabled = true;
    context.imageSmoothingQuality = 'high';
    context.drawImage(image.source, 0, 0, outputDimensions.width, outputDimensions.height);

    return await new Promise<Blob>((resolve, reject) => {
      canvas.toBlob(
        (blob) => {
          if (blob === null) {
            reject(new ImageNormalizationError('encodeFailed'));
            return;
          }
          resolve(blob);
        },
        'image/jpeg',
        quality,
      );
    });
  },
};
