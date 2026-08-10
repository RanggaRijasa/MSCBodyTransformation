import { AppError } from "@/domain/errors/app-error";
import { failure, success, type Result } from "@/domain/result";

export const imageProcessingPolicy = {
  maximumInputBytes: 10 * 1024 * 1024,
  maximumOutputBytes: 5 * 1024 * 1024,
  maximumDimension: 1600,
  thumbnailDimension: 320,
  outputQuality: 0.82,
} as const;

export const acceptedImageMimeTypes = [
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/heic",
  "image/heif",
] as const;

export type AcceptedImageMimeType = (typeof acceptedImageMimeTypes)[number];

export type ProcessedImageDescriptor = Readonly<{
  byteSize: number;
  height: number;
  mimeType: "image/jpeg";
  width: number;
}>;

export function validateImageInput(
  input: Readonly<{
    byteSize: number;
    declaredMimeType: string;
  }>,
): Result<AcceptedImageMimeType, AppError> {
  const mimeType = input.declaredMimeType.toLowerCase();
  if (!(acceptedImageMimeTypes as readonly string[]).includes(mimeType)) {
    return failure(
      new AppError("validation_failed", "Gunakan foto JPEG, PNG, WebP, HEIC, atau HEIF."),
    );
  }
  if (input.byteSize <= 0 || input.byteSize > imageProcessingPolicy.maximumInputBytes) {
    return failure(new AppError("validation_failed", "Ukuran foto maksimal 10 MB."));
  }
  return success(mimeType as AcceptedImageMimeType);
}

export function resizedDimensions(
  width: number,
  height: number,
  maximumDimension: number = imageProcessingPolicy.maximumDimension,
): Readonly<{ height: number; width: number }> {
  if (width <= 0 || height <= 0 || maximumDimension <= 0) return { height: 0, width: 0 };
  const largest = Math.max(width, height);
  if (largest <= maximumDimension) return { height, width };
  const scale = maximumDimension / largest;
  return {
    height: Math.max(1, Math.round(height * scale)),
    width: Math.max(1, Math.round(width * scale)),
  };
}

export function validateProcessedImage(
  descriptor: ProcessedImageDescriptor,
): Result<ProcessedImageDescriptor, AppError> {
  if (
    descriptor.mimeType !== "image/jpeg" ||
    descriptor.byteSize <= 0 ||
    descriptor.byteSize > imageProcessingPolicy.maximumOutputBytes ||
    descriptor.width <= 0 ||
    descriptor.height <= 0 ||
    Math.max(descriptor.width, descriptor.height) > imageProcessingPolicy.maximumDimension
  ) {
    return failure(new AppError("validation_failed", "Hasil pemrosesan foto tidak valid."));
  }
  return success(descriptor);
}
