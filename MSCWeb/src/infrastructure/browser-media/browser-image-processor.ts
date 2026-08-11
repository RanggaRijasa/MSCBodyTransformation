import { AppError } from "@/domain/errors/app-error";
import {
  imageProcessingPolicy,
  validateImageInput,
  validateProcessedImage,
  type ProcessedImageDescriptor,
} from "@/domain/media/image-contract";
import { verifyImageSignature } from "@/domain/media/image-signature";
import { processImageWithCanvasFallback } from "@/infrastructure/browser-media/canvas-image-fallback";

export type ProcessedBrowserImage = Readonly<{
  descriptor: ProcessedImageDescriptor;
  fullImage: Blob;
  thumbnail: Blob;
}>;

type WorkerSuccess = Readonly<{
  fullBytes: ArrayBuffer;
  height: number;
  kind: "success";
  thumbnailBytes: ArrayBuffer;
  width: number;
}>;
type WorkerResponse = WorkerSuccess | Readonly<{ kind: "failure" }>;
type WorkerFactory = () => Worker;

function defaultWorkerFactory(): Worker {
  return new Worker(new URL("./image-processor.worker.ts", import.meta.url), { type: "module" });
}

function abortError(): DOMException {
  return new DOMException("Pemrosesan dibatalkan.", "AbortError");
}

export class BrowserImageProcessor {
  readonly #workerFactory: WorkerFactory;

  constructor(workerFactory: WorkerFactory = defaultWorkerFactory) {
    this.#workerFactory = workerFactory;
  }

  async process(file: File, signal?: AbortSignal): Promise<ProcessedBrowserImage> {
    const inputValidation = validateImageInput({
      byteSize: file.size,
      declaredMimeType: file.type,
    });
    if (!inputValidation.isSuccess) throw inputValidation.error;
    if (signal?.aborted) throw abortError();

    const bytes = await file.arrayBuffer();
    const signature = verifyImageSignature(
      new Uint8Array(bytes, 0, Math.min(16, bytes.byteLength)),
      file.type,
    );
    if (!signature.isSuccess) throw signature.error;
    if (signal?.aborted) throw abortError();
    if (typeof Worker === "undefined" || typeof OffscreenCanvas === "undefined") {
      return processImageWithCanvasFallback(file, signal);
    }

    const response = await this.#runWorker(bytes, file.type, signal);
    const fullImage = new Blob([response.fullBytes], { type: "image/jpeg" });
    const thumbnail = new Blob([response.thumbnailBytes], { type: "image/jpeg" });
    const descriptor: ProcessedImageDescriptor = {
      byteSize: fullImage.size,
      height: response.height,
      mimeType: "image/jpeg",
      width: response.width,
    };
    const outputValidation = validateProcessedImage(descriptor);
    if (!outputValidation.isSuccess) throw outputValidation.error;
    return { descriptor, fullImage, thumbnail };
  }

  #runWorker(
    bytes: ArrayBuffer,
    sourceMimeType: string,
    signal?: AbortSignal,
  ): Promise<WorkerSuccess> {
    return new Promise((resolve, reject) => {
      const worker = this.#workerFactory();
      const cleanup = () => {
        worker.terminate();
        signal?.removeEventListener("abort", handleAbort);
      };
      const handleAbort = () => {
        cleanup();
        reject(abortError());
      };
      worker.addEventListener("error", () => {
        cleanup();
        reject(new AppError("unknown", "Foto belum dapat diproses."));
      });
      worker.addEventListener("message", (event: MessageEvent<WorkerResponse>) => {
        cleanup();
        if (event.data.kind === "success") resolve(event.data);
        else reject(new AppError("validation_failed", "Foto tidak dapat dibaca oleh browser."));
      });
      signal?.addEventListener("abort", handleAbort, { once: true });
      worker.postMessage(
        {
          bytes,
          maximumDimension: imageProcessingPolicy.maximumDimension,
          outputQuality: imageProcessingPolicy.outputQuality,
          sourceMimeType,
          thumbnailDimension: imageProcessingPolicy.thumbnailDimension,
        },
        [bytes],
      );
    });
  }
}
