import { AppError } from "@/domain/errors/app-error";
import {
  validateProcessedImage,
  type ProcessedImageDescriptor,
} from "@/domain/media/image-contract";
import { verifyImageSignature } from "@/domain/media/image-signature";
import { failure, success, type Result } from "@/domain/result";

const startOfFrameMarkers = new Set([
  0xc0, 0xc1, 0xc2, 0xc3, 0xc5, 0xc6, 0xc7, 0xc9, 0xca, 0xcb, 0xcd, 0xce, 0xcf,
]);
const applicationMetadataMarkerStart = 0xe1;
const applicationMetadataMarkerEnd = 0xef;
const commentMarker = 0xfe;

export type SanitizedServerImage = Readonly<{
  bytes: Uint8Array;
  descriptor: ProcessedImageDescriptor;
}>;

function readUint16(bytes: Uint8Array, offset: number): number | null {
  const high = bytes[offset];
  const low = bytes[offset + 1];
  return high === undefined || low === undefined ? null : (high << 8) | low;
}

function inspectJpegStructure(
  bytes: Uint8Array,
): Result<Readonly<{ height: number; width: number }>, AppError> {
  if (
    bytes.length < 16 ||
    bytes[0] !== 0xff ||
    bytes[1] !== 0xd8 ||
    bytes.at(-2) !== 0xff ||
    bytes.at(-1) !== 0xd9
  ) {
    return failure(new AppError("validation_failed", "Struktur foto JPEG tidak lengkap."));
  }

  let offset = 2;
  let dimensions: Readonly<{ height: number; width: number }> | null = null;
  let hasScanData = false;
  while (offset + 4 <= bytes.length) {
    while (offset < bytes.length && bytes[offset] === 0xff) offset += 1;
    const marker = bytes[offset];
    offset += 1;
    if (marker === undefined || marker === 0xd9) break;
    if (marker === 0x00 || (marker >= 0xd0 && marker <= 0xd7)) continue;
    if (offset + 2 > bytes.length) break;
    const segmentLength = readUint16(bytes, offset);
    if (segmentLength === null) break;
    if (segmentLength < 2 || offset + segmentLength > bytes.length) break;
    if (startOfFrameMarkers.has(marker)) {
      if (segmentLength < 8) break;
      const height = readUint16(bytes, offset + 3);
      const width = readUint16(bytes, offset + 5);
      if (height === null || width === null) break;
      dimensions = { height, width };
    }
    if (marker === 0xda) {
      hasScanData = offset + segmentLength < bytes.length - 2;
      break;
    }
    offset += segmentLength;
  }

  if (!dimensions || dimensions.width <= 0 || dimensions.height <= 0 || !hasScanData) {
    return failure(
      new AppError("validation_failed", "Foto JPEG tidak dapat didekode dengan aman."),
    );
  }
  return success(dimensions);
}

function joinSegments(segments: readonly Uint8Array[]): Uint8Array {
  const byteSize = segments.reduce((total, segment) => total + segment.byteLength, 0);
  const joined = new Uint8Array(byteSize);
  let offset = 0;
  for (const segment of segments) {
    joined.set(segment, offset);
    offset += segment.byteLength;
  }
  return joined;
}

function stripJpegMetadata(bytes: Uint8Array): Result<Uint8Array, AppError> {
  const segments: Uint8Array[] = [bytes.subarray(0, 2)];
  let offset = 2;

  while (offset < bytes.length - 2) {
    const markerStart = offset;
    while (offset < bytes.length && bytes[offset] === 0xff) offset += 1;
    const marker = bytes[offset];
    offset += 1;
    if (marker === undefined || marker === 0x00 || marker === 0xd9) break;
    if ((marker >= 0xd0 && marker <= 0xd7) || marker === 0x01) {
      segments.push(bytes.subarray(markerStart, offset));
      continue;
    }

    const segmentLength = readUint16(bytes, offset);
    if (segmentLength === null || segmentLength < 2) break;
    const segmentEnd = offset + segmentLength;
    if (segmentEnd > bytes.length) break;
    if (marker === 0xda) {
      segments.push(bytes.subarray(markerStart));
      return success(joinSegments(segments));
    }

    const isPrivateMetadata =
      (marker >= applicationMetadataMarkerStart && marker <= applicationMetadataMarkerEnd) ||
      marker === commentMarker;
    if (!isPrivateMetadata) segments.push(bytes.subarray(markerStart, segmentEnd));
    offset = segmentEnd;
  }

  return failure(new AppError("validation_failed", "Metadata foto JPEG tidak dapat diproses."));
}

/**
 * Server upload adapters must call this before writing a browser-produced JPEG.
 * Browser validation is only an early user-facing check and is never authoritative.
 */
export function validateServerImageUpload(
  bytes: Uint8Array,
  declaredMimeType: string,
): Result<ProcessedImageDescriptor, AppError> {
  const signature = verifyImageSignature(bytes.subarray(0, 16), declaredMimeType);
  if (!signature.isSuccess || signature.value !== "image/jpeg") {
    return failure(
      new AppError("validation_failed", "Server hanya menerima foto JPEG yang valid."),
    );
  }
  const structure = inspectJpegStructure(bytes);
  if (!structure.isSuccess) return structure;
  const descriptor: ProcessedImageDescriptor = {
    byteSize: bytes.byteLength,
    height: structure.value.height,
    mimeType: "image/jpeg",
    width: structure.value.width,
  };
  const policy = validateProcessedImage(descriptor);
  return policy.isSuccess ? success(descriptor) : policy;
}

/**
 * Removes EXIF/IPTC/vendor application segments and comments before private storage.
 * APP0/JFIF and image-coding segments are retained so normalized browser JPEGs stay decodable.
 */
export function sanitizeServerImageUpload(
  bytes: Uint8Array,
  declaredMimeType: string,
): Result<SanitizedServerImage, AppError> {
  const original = validateServerImageUpload(bytes, declaredMimeType);
  if (!original.isSuccess) return original;
  const stripped = stripJpegMetadata(bytes);
  if (!stripped.isSuccess) return stripped;
  const sanitized = validateServerImageUpload(stripped.value, "image/jpeg");
  return sanitized.isSuccess
    ? success({ bytes: stripped.value, descriptor: sanitized.value })
    : sanitized;
}
