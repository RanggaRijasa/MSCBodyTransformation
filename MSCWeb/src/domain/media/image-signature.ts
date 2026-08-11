import { AppError } from "@/domain/errors/app-error";
import { failure, success, type Result } from "@/domain/result";

export type DecodedImageMimeType =
  "image/jpeg" | "image/png" | "image/webp" | "image/heic" | "image/heif";

function ascii(bytes: Uint8Array, start: number, length: number): string {
  return String.fromCharCode(...bytes.slice(start, start + length));
}

export function detectImageMimeType(bytes: Uint8Array): DecodedImageMimeType | null {
  if (bytes.length >= 3 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) {
    return "image/jpeg";
  }
  if (
    bytes.length >= 8 &&
    bytes[0] === 0x89 &&
    ascii(bytes, 1, 3) === "PNG" &&
    bytes[4] === 0x0d &&
    bytes[5] === 0x0a &&
    bytes[6] === 0x1a &&
    bytes[7] === 0x0a
  ) {
    return "image/png";
  }
  if (bytes.length >= 12 && ascii(bytes, 0, 4) === "RIFF" && ascii(bytes, 8, 4) === "WEBP") {
    return "image/webp";
  }
  if (bytes.length >= 12 && ascii(bytes, 4, 4) === "ftyp") {
    const brand = ascii(bytes, 8, 4);
    if (["heic", "heix", "hevc", "hevx"].includes(brand)) return "image/heic";
    if (["heif", "heim", "heis", "mif1", "msf1"].includes(brand)) return "image/heif";
  }
  return null;
}

export function verifyImageSignature(
  bytes: Uint8Array,
  declaredMimeType: string,
): Result<DecodedImageMimeType, AppError> {
  const detected = detectImageMimeType(bytes);
  if (!detected || detected !== declaredMimeType.toLowerCase()) {
    return failure(new AppError("validation_failed", "Isi file tidak sesuai dengan format foto."));
  }
  return success(detected);
}
