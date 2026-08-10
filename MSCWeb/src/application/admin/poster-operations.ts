import "server-only";

import { randomUUID } from "node:crypto";

import { sanitizeServerImageUpload } from "@/application/media/server-image-validation";
import { AppError } from "@/domain/errors/app-error";
import { failure, success } from "@/domain/result";
import { getVerifiedSupabaseContext } from "@/infrastructure/supabase/auth/get-verified-actor";
import { createSupabaseServiceClient } from "@/infrastructure/supabase/client/service";

export async function uploadManagedWinnerPoster(
  input: Readonly<{
    alternativeText: string;
    bytes: Uint8Array;
    declaredMimeType: string;
    operation: "add" | "replace";
    posterId: string | null;
    reason: string;
    snapshotId: string | null;
  }>,
) {
  const context = await getVerifiedSupabaseContext();
  if (!context.isSuccess) return context;
  const sanitized = sanitizeServerImageUpload(input.bytes, input.declaredMimeType);
  if (!sanitized.isSuccess) return sanitized;
  const ratio = sanitized.value.descriptor.width / sanitized.value.descriptor.height;
  if (Math.abs(ratio - 9 / 16) > 0.04) {
    return failure(new AppError("validation_failed", "Gunakan poster dengan rasio 9:16."));
  }

  const posterId = input.operation === "replace" && input.posterId ? input.posterId : randomUUID();
  let programId: string | null = null;
  let winnerSnapshotId: string | null = null;
  let oldPath: string | null = null;
  if (input.operation === "add" && input.snapshotId) {
    const snapshot = await context.value.supabase
      .from("winner_snapshots")
      .select("id,program_id")
      .eq("id", input.snapshotId)
      .maybeSingle();
    if (snapshot.error || !snapshot.data) {
      return failure(new AppError("validation_failed", "Snapshot pemenang tidak tersedia."));
    }
    programId = snapshot.data.program_id;
    winnerSnapshotId = snapshot.data.id;
  } else if (input.operation === "replace") {
    const poster = await context.value.supabase
      .from("winner_posters")
      .select("program_id,winner_snapshot_id,media_path")
      .eq("id", posterId)
      .maybeSingle();
    if (poster.error || !poster.data) {
      return failure(new AppError("forbidden", "Poster tidak tersedia."));
    }
    programId = poster.data.program_id;
    winnerSnapshotId = poster.data.winner_snapshot_id;
    oldPath = poster.data.media_path;
  }
  if (!programId || !winnerSnapshotId) {
    return failure(new AppError("validation_failed", "Pilih snapshot pemenang."));
  }

  const mediaPath = `winners/${posterId}/${randomUUID()}.jpg`;
  let service;
  try {
    service = createSupabaseServiceClient();
  } catch (error) {
    return failure(
      error instanceof AppError ? error : new AppError("unknown", "Penyimpanan belum tersedia."),
    );
  }
  const upload = await service.storage
    .from("public-media")
    .upload(mediaPath, sanitized.value.bytes, {
      cacheControl: "31536000",
      contentType: "image/jpeg",
      upsert: false,
    });
  if (upload.error) return failure(new AppError("unknown", "Poster belum dapat diunggah."));
  const mutation = await context.value.supabase.rpc("manage_winner_poster", {
    operation: input.operation,
    reason: input.reason,
    request_idempotency_key: `poster-${randomUUID()}`,
    target_alt_text: input.alternativeText,
    target_media_path: mediaPath,
    target_poster_id: posterId,
    target_program_id: programId,
    target_snapshot_id: winnerSnapshotId,
  });
  if (mutation.error) {
    await service.storage.from("public-media").remove([mediaPath]);
    return failure(new AppError("conflict", "Poster belum dapat disimpan."));
  }
  if (oldPath && oldPath !== mediaPath) {
    await service.storage.from("public-media").remove([oldPath]);
  }
  return success({ id: posterId });
}
