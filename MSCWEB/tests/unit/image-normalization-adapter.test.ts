import { describe, expect, it, vi } from 'vitest';

import {
  browserImageNormalizationRuntime,
  calculateContainSize,
  ImageNormalizationError,
  MAX_IMAGE_INPUT_BYTES,
  normalizeBrowserImage,
  validateImageInput,
  type ImageNormalizationRuntime,
} from '../../src/shared/media/image-normalization';

describe('image normalization adapter', () => {
  it('allows a large source to be resized before enforcing the 8 MiB output limit', () => {
    expect(() =>
      validateImageInput({ size: MAX_IMAGE_INPUT_BYTES + 1, type: 'image/jpeg' }),
    ).not.toThrow();
  });

  it('rejects a MIME type that cannot enter the raster pipeline', () => {
    expect(() => validateImageInput({ size: 128, type: 'image/svg+xml' })).toThrowError(
      new ImageNormalizationError('unsupportedType'),
    );
  });

  it('calculates a contain resize without enlarging the source', () => {
    expect(calculateContainSize({ width: 4_000, height: 3_000 }, { width: 2_048, height: 2_048 })).toEqual({
      width: 2_048,
      height: 1_536,
    });
    expect(calculateContainSize({ width: 640, height: 480 }, { width: 2_048, height: 2_048 })).toEqual({
      width: 640,
      height: 480,
    });
  });

  it('normalizes through the injected decoder and JPEG renderer, then releases the bitmap', async () => {
    const close = vi.fn();
    const renderJpeg = vi.fn(async () => new Blob(['jpeg'], { type: 'image/jpeg' }));
    const runtime: ImageNormalizationRuntime = {
      decode: vi.fn(async () => ({
        width: 4_000,
        height: 2_000,
        source: {} as CanvasImageSource,
        close,
      })),
      renderJpeg,
    };
    const input = new Blob(['source'], { type: 'image/png' });

    const result = await normalizeBrowserImage(input, { maxWidth: 1_000, maxHeight: 1_000, quality: 0.75 }, runtime);

    expect(runtime.decode).toHaveBeenCalledWith(input);
    expect(renderJpeg).toHaveBeenCalledWith(expect.objectContaining({ width: 4_000, height: 2_000 }), { width: 1_000, height: 500 }, 0.75);
    expect(result).toMatchObject({ mimeType: 'image/jpeg', width: 1_000, height: 500 });
    expect(close).toHaveBeenCalledOnce();
  });

  it('asks createImageBitmap to apply the source EXIF orientation', async () => {
    const close = vi.fn();
    const createBitmap = vi.fn(async () => ({ width: 100, height: 200, close }));
    vi.stubGlobal('createImageBitmap', createBitmap);
    const input = new Blob(['jpeg'], { type: 'image/jpeg' });

    const decoded = await browserImageNormalizationRuntime.decode(input);

    expect(createBitmap).toHaveBeenCalledWith(input, { imageOrientation: 'from-image' });
    decoded.close?.();
    expect(close).toHaveBeenCalledOnce();
    vi.unstubAllGlobals();
  });

  it('maps decoder failures to actionable typed errors', async () => {
    const runtime: ImageNormalizationRuntime = {
      decode: vi.fn(async () => {
        throw new DOMException('decode failed');
      }),
      renderJpeg: vi.fn(),
    };

    await expect(
      normalizeBrowserImage(new Blob(['bad'], { type: 'image/jpeg' }), {}, runtime),
    ).rejects.toMatchObject({ code: 'decodeFailed' });
  });

  it('rejects a normalized output that still exceeds 8 MiB', async () => {
    const runtime: ImageNormalizationRuntime = {
      decode: vi.fn(async () => ({
        width: 100,
        height: 100,
        source: {} as CanvasImageSource,
      })),
      renderJpeg: vi.fn(async () =>
        new Blob([new Uint8Array(MAX_IMAGE_INPUT_BYTES + 1)], { type: 'image/jpeg' }),
      ),
    };

    await expect(
      normalizeBrowserImage(new Blob(['source'], { type: 'image/jpeg' }), {}, runtime),
    ).rejects.toMatchObject({ code: 'fileTooLarge' });
  });
});
