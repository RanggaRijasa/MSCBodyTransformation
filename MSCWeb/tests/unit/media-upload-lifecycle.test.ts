import { describe, expect, it } from "vitest";

import {
  beginUpload,
  completeUpload,
  failUpload,
  updateUploadProgress,
  type UploadState,
} from "@/domain/media/upload-lifecycle";

describe("upload lifecycle", () => {
  it("menjaga idempotency key dan progres monoton", () => {
    let state: UploadState = beginUpload({ idempotencyKey: "upload-001", kind: "ready" });
    state = updateUploadProgress(state, 0.7);
    state = updateUploadProgress(state, 0.2);
    expect(state).toEqual({ idempotencyKey: "upload-001", kind: "uploading", progress: 0.7 });
    expect(completeUpload(state, "receipt-001")).toEqual({
      kind: "uploaded",
      receiptId: "receipt-001",
    });
  });

  it("mengizinkan retry hanya untuk failure yang aman", () => {
    const uploading = beginUpload({ idempotencyKey: "upload-002", kind: "ready" });
    const offline = failUpload(uploading, "offline");
    expect(beginUpload(offline).kind).toBe("uploading");
    const conflict = failUpload(uploading, "conflict");
    expect(beginUpload(conflict)).toEqual(conflict);
  });

  it("tidak menggandakan upload setelah receipt terminal", () => {
    const uploaded: UploadState = { kind: "uploaded", receiptId: "receipt-003" };
    expect(beginUpload(uploaded)).toEqual(uploaded);
  });
});
