type WorkerRequest = Readonly<{
  bytes: ArrayBuffer;
  maximumDimension: number;
  outputQuality: number;
  sourceMimeType: string;
  thumbnailDimension: number;
}>;

type WorkerResponse =
  | Readonly<{
      fullBytes: ArrayBuffer;
      height: number;
      kind: "success";
      thumbnailBytes: ArrayBuffer;
      width: number;
    }>
  | Readonly<{ kind: "failure" }>;

type WorkerScope = Readonly<{
  addEventListener: (
    type: "message",
    listener: (event: MessageEvent<WorkerRequest>) => void,
  ) => void;
  postMessage: (message: WorkerResponse, transfer?: Transferable[]) => void;
}>;

const workerScope = self as unknown as WorkerScope;

function targetSize(width: number, height: number, limit: number) {
  const scale = Math.min(1, limit / Math.max(width, height));
  return {
    height: Math.max(1, Math.round(height * scale)),
    width: Math.max(1, Math.round(width * scale)),
  };
}

async function renderJpeg(bitmap: ImageBitmap, limit: number, quality: number) {
  const size = targetSize(bitmap.width, bitmap.height, limit);
  const canvas = new OffscreenCanvas(size.width, size.height);
  const context = canvas.getContext("2d", { alpha: false });
  if (!context) throw new Error("canvas_unavailable");
  context.drawImage(bitmap, 0, 0, size.width, size.height);
  const blob = await canvas.convertToBlob({ quality, type: "image/jpeg" });
  return { blob, ...size };
}

workerScope.addEventListener("message", (event) => {
  void (async () => {
    try {
      const request = event.data;
      const source = new Blob([request.bytes], { type: request.sourceMimeType });
      const bitmap = await createImageBitmap(source, { imageOrientation: "from-image" });
      const full = await renderJpeg(bitmap, request.maximumDimension, request.outputQuality);
      const thumbnail = await renderJpeg(bitmap, request.thumbnailDimension, 0.76);
      bitmap.close();
      const fullBytes = await full.blob.arrayBuffer();
      const thumbnailBytes = await thumbnail.blob.arrayBuffer();
      workerScope.postMessage(
        {
          fullBytes,
          height: full.height,
          kind: "success",
          thumbnailBytes,
          width: full.width,
        },
        [fullBytes, thumbnailBytes],
      );
    } catch {
      workerScope.postMessage({ kind: "failure" });
    }
  })();
});

export {};
