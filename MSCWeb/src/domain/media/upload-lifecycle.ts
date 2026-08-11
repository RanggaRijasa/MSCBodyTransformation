export type UploadFailureKind = "cancelled" | "conflict" | "offline" | "timeout" | "unknown";

export type UploadState =
  | Readonly<{ kind: "idle" }>
  | Readonly<{ idempotencyKey: string; kind: "ready" }>
  | Readonly<{ idempotencyKey: string; kind: "uploading"; progress: number }>
  | Readonly<{
      idempotencyKey: string;
      kind: "failed";
      reason: UploadFailureKind;
      retryable: boolean;
    }>
  | Readonly<{ kind: "uploaded"; receiptId: string }>;

export function beginUpload(state: UploadState): UploadState {
  if (state.kind !== "ready" && state.kind !== "failed") return state;
  if (state.kind === "failed" && !state.retryable) return state;
  return { idempotencyKey: state.idempotencyKey, kind: "uploading", progress: 0 };
}

export function updateUploadProgress(state: UploadState, progress: number): UploadState {
  if (state.kind !== "uploading") return state;
  return { ...state, progress: Math.min(1, Math.max(state.progress, progress)) };
}

export function failUpload(state: UploadState, reason: UploadFailureKind): UploadState {
  if (state.kind !== "uploading") return state;
  return {
    idempotencyKey: state.idempotencyKey,
    kind: "failed",
    reason,
    retryable: reason === "offline" || reason === "timeout" || reason === "unknown",
  };
}

export function completeUpload(state: UploadState, receiptId: string): UploadState {
  if (state.kind !== "uploading" || receiptId.trim().length === 0) return state;
  return { kind: "uploaded", receiptId };
}
