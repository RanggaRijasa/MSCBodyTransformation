import { describe, expect, it } from "vitest";

import {
  imageProcessingPolicy,
  resizedDimensions,
  validateImageInput,
  validateProcessedImage,
} from "@/domain/media/image-contract";
import { detectImageMimeType, verifyImageSignature } from "@/domain/media/image-signature";

describe("kontrak gambar", () => {
  it("membatasi MIME dan ukuran input", () => {
    expect(validateImageInput({ byteSize: 1024, declaredMimeType: "image/jpeg" }).isSuccess).toBe(
      true,
    );
    expect(
      validateImageInput({ byteSize: 1024, declaredMimeType: "image/svg+xml" }).isSuccess,
    ).toBe(false);
    expect(
      validateImageInput({
        byteSize: imageProcessingPolicy.maximumInputBytes + 1,
        declaredMimeType: "image/png",
      }).isSuccess,
    ).toBe(false);
  });

  it("menentukan dimensi resize tanpa memperbesar gambar kecil", () => {
    expect(resizedDimensions(800, 600)).toEqual({ height: 600, width: 800 });
    expect(resizedDimensions(4000, 3000)).toEqual({ height: 1200, width: 1600 });
    expect(resizedDimensions(0, 3000)).toEqual({ height: 0, width: 0 });
  });

  it("mendeteksi magic bytes dan menolak MIME palsu", () => {
    const jpeg = new Uint8Array([0xff, 0xd8, 0xff, 0xe0]);
    const png = new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
    const webp = new TextEncoder().encode("RIFF0000WEBP");
    expect(detectImageMimeType(jpeg)).toBe("image/jpeg");
    expect(detectImageMimeType(png)).toBe("image/png");
    expect(detectImageMimeType(webp)).toBe("image/webp");
    expect(verifyImageSignature(jpeg, "image/png").isSuccess).toBe(false);
  });

  it("hanya menerima JPEG hasil pemrosesan dalam batas server", () => {
    expect(
      validateProcessedImage({
        byteSize: 200_000,
        height: 1200,
        mimeType: "image/jpeg",
        width: 1600,
      }).isSuccess,
    ).toBe(true);
    expect(
      validateProcessedImage({
        byteSize: imageProcessingPolicy.maximumOutputBytes + 1,
        height: 1200,
        mimeType: "image/jpeg",
        width: 1600,
      }).isSuccess,
    ).toBe(false);
  });
});
