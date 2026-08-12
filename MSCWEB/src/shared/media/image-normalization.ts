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
