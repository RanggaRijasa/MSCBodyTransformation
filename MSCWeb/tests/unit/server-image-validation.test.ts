import { describe, expect, it } from "vitest";

import {
  sanitizeServerImageUpload,
  validateServerImageUpload,
} from "@/application/media/server-image-validation";

function structuralJpeg(width: number, height: number): Uint8Array {
  return new Uint8Array([
    0xff,
    0xd8,
    0xff,
    0xc0,
    0x00,
    0x0b,
    0x08,
    (height >> 8) & 0xff,
    height & 0xff,
    (width >> 8) & 0xff,
    width & 0xff,
    0x01,
    0x01,
    0x11,
    0x00,
    0xff,
    0xda,
    0x00,
    0x08,
    0x01,
    0x01,
    0x00,
    0x00,
    0x3f,
    0x00,
    0x01,
    0x02,
    0x03,
    0xff,
    0xd9,
  ]);
}

function jpegWithPrivateMetadata(width: number, height: number): Uint8Array {
  const jpeg = structuralJpeg(width, height);
  const exif = new Uint8Array([
    0xff, 0xe1, 0x00, 0x0c, 0x45, 0x78, 0x69, 0x66, 0x00, 0x00, 0x47, 0x50, 0x53, 0x00,
  ]);
  const comment = new Uint8Array([0xff, 0xfe, 0x00, 0x06, 0x50, 0x49, 0x49, 0x00]);
  const result = new Uint8Array(jpeg.byteLength + exif.byteLength + comment.byteLength);
  result.set(jpeg.subarray(0, 2));
  result.set(exif, 2);
  result.set(comment, 2 + exif.byteLength);
  result.set(jpeg.subarray(2), 2 + exif.byteLength + comment.byteLength);
  return result;
}

describe("validasi gambar authoritative di server", () => {
  it("membaca dimensi JPEG terstruktur setelah magic-byte cocok", () => {
    const result = validateServerImageUpload(structuralJpeg(640, 480), "image/jpeg");
    expect(result).toEqual({
      isSuccess: true,
      value: { byteSize: 30, height: 480, mimeType: "image/jpeg", width: 640 },
    });
  });

  it("menolak MIME palsu dan JPEG tanpa scan data", () => {
    expect(validateServerImageUpload(structuralJpeg(640, 480), "image/png").isSuccess).toBe(false);
    expect(
      validateServerImageUpload(
        new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x02, 0xff, 0xd9]),
        "image/jpeg",
      ).isSuccess,
    ).toBe(false);
  });

  it("membuang EXIF, metadata aplikasi, dan komentar sebelum penyimpanan", () => {
    const input = jpegWithPrivateMetadata(640, 480);
    const result = sanitizeServerImageUpload(input, "image/jpeg");

    expect(result.isSuccess).toBe(true);
    if (!result.isSuccess) return;
    expect(result.value.bytes).toEqual(structuralJpeg(640, 480));
    expect(result.value.descriptor).toEqual({
      byteSize: 30,
      height: 480,
      mimeType: "image/jpeg",
      width: 640,
    });
    expect(new TextDecoder().decode(result.value.bytes)).not.toContain("GPS");
  });
});
