import {
  beginUpload,
  completeUpload,
  failUpload,
  updateUploadProgress,
  type UploadFailureKind,
  type UploadState,
} from "@/domain/media/upload-lifecycle";

export type PrivateImageUploadPort = Readonly<{
  upload: (
    request: Readonly<{
      idempotencyKey: string;
      image: Blob;
      onProgress: (progress: number) => void;
      purpose: "payment_evidence" | "profile_photo" | "question_answer" | "winner_poster";
      signal: AbortSignal;
    }>,
  ) => Promise<Readonly<{ receiptId: string; serverValidation: "passed" }>>;
}>;

export async function uploadPrivateImage(
  port: PrivateImageUploadPort,
  input: Readonly<{
    idempotencyKey: string;
    image: Blob;
    onStateChange: (state: UploadState) => void;
    purpose: "payment_evidence" | "profile_photo" | "question_answer" | "winner_poster";
    signal: AbortSignal;
  }>,
): Promise<UploadState> {
  let state: UploadState = beginUpload({ idempotencyKey: input.idempotencyKey, kind: "ready" });
  input.onStateChange(state);
  try {
    const receipt = await port.upload({
      idempotencyKey: input.idempotencyKey,
      image: input.image,
      onProgress: (progress) => {
        state = updateUploadProgress(state, progress);
        input.onStateChange(state);
      },
      purpose: input.purpose,
      signal: input.signal,
    });
    if (receipt.serverValidation !== "passed") throw new Error("server_validation_missing");
    state = completeUpload(state, receipt.receiptId);
  } catch (error) {
    const reason: UploadFailureKind =
      error instanceof DOMException && error.name === "AbortError"
        ? "cancelled"
        : typeof navigator !== "undefined" && !navigator.onLine
          ? "offline"
          : "unknown";
    state = failUpload(state, reason);
  }
  input.onStateChange(state);
  return state;
}
