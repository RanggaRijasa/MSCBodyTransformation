import { AppError } from "@/domain/errors/app-error";
import {
  imageProcessingPolicy,
  resizedDimensions,
  validateProcessedImage,
  type ProcessedImageDescriptor,
} from "@/domain/media/image-contract";
import type { ProcessedBrowserImage } from "@/infrastructure/browser-media/browser-image-processor";

type DecodedSource = Readonly<{
  close: () => void;
  height: number;
  source: CanvasImageSource;
  width: number;
}>;

function abortIfNeeded(signal?: AbortSignal) {
  if (signal?.aborted) throw new DOMException("Pemrosesan dibatalkan.", "AbortError");
}

async function yieldToBrowser(signal?: AbortSignal) {
  await new Promise<void>((resolve) => requestAnimationFrame(() => resolve()));
  abortIfNeeded(signal);
}

async function decode(file: File): Promise<DecodedSource> {
  if (typeof createImageBitmap === "function") {
    const bitmap = await createImageBitmap(file, { imageOrientation: "from-image" });
    return {
      close: () => bitmap.close(),
      height: bitmap.height,
      source: bitmap,
      width: bitmap.width,
    };
  }
  const objectUrl = URL.createObjectURL(file);
  const image = new Image();
  image.src = objectUrl;
  try {
    await image.decode();
    return {
      close: () => URL.revokeObjectURL(objectUrl),
      height: image.naturalHeight,
      source: image,
      width: image.naturalWidth,
    };
  } catch (error) {
    URL.revokeObjectURL(objectUrl);
    throw error;
  }
}

async function render(
  decoded: DecodedSource,
  limit: number,
  quality: number,
): Promise<Readonly<{ blob: Blob; height: number; width: number }>> {
  const size = resizedDimensions(decoded.width, decoded.height, limit);
  const canvas = document.createElement("canvas");
  canvas.width = size.width;
  canvas.height = size.height;
  const context = canvas.getContext("2d", { alpha: false });
  if (!context) throw new AppError("configuration_invalid", "Canvas foto tidak tersedia.");
  context.drawImage(decoded.source, 0, 0, size.width, size.height);
  const blob = await new Promise<Blob | null>((resolve) =>
    canvas.toBlob(resolve, "image/jpeg", quality),
  );
  if (!blob) throw new AppError("validation_failed", "Foto tidak dapat dikonversi ke JPEG.");
  return { blob, ...size };
}

export async function processImageWithCanvasFallback(
  file: File,
  signal?: AbortSignal,
): Promise<ProcessedBrowserImage> {
  abortIfNeeded(signal);
  await yieldToBrowser(signal);
  const decoded = await decode(file);
  try {
    const full = await render(
      decoded,
      imageProcessingPolicy.maximumDimension,
      imageProcessingPolicy.outputQuality,
    );
    await yieldToBrowser(signal);
    const thumbnail = await render(decoded, imageProcessingPolicy.thumbnailDimension, 0.76);
    const descriptor: ProcessedImageDescriptor = {
      byteSize: full.blob.size,
      height: full.height,
      mimeType: "image/jpeg",
      width: full.width,
    };
    const validation = validateProcessedImage(descriptor);
    if (!validation.isSuccess) throw validation.error;
    return { descriptor, fullImage: full.blob, thumbnail: thumbnail.blob };
  } finally {
    decoded.close();
  }
}
