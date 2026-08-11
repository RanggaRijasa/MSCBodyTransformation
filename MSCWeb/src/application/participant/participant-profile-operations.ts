import "server-only";

import { randomUUID } from "node:crypto";

import { sanitizeServerImageUpload } from "@/application/media/server-image-validation";
import { AppError } from "@/domain/errors/app-error";
import { failure, success } from "@/domain/result";
import { getVerifiedSupabaseContext } from "@/infrastructure/supabase/auth/get-verified-actor";
import { createSupabaseServiceClient } from "@/infrastructure/supabase/client/service";

type ProfileContext = Readonly<{
  avatarUrl: string | null;
  coach: Readonly<{ city: string | null; displayName: string; photoUrl: string | null }> | null;
}>;

function record(value: unknown): Record<string, unknown> | null {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : null;
}

function profileError(error: unknown) {
  const message =
    error && typeof error === "object" && "message" in error ? String(error.message) : "";
  if (/permission/i.test(message))
    return new AppError("forbidden", "Tindakan ini tidak tersedia.", { cause: error });
  if (/coach.*unavailable|qr/i.test(message))
    return new AppError("validation_failed", "QR Coach tidak valid atau Coach belum aktif.", {
      cause: error,
    });
  if (/idempotency|duplicate|unique/i.test(message))
    return new AppError("conflict", "Permintaan ini sudah diproses.", { cause: error });
  return new AppError("unknown", "Profil belum dapat diperbarui.", { cause: error });
}

async function rawProfileContext() {
  const context = await getVerifiedSupabaseContext();
  if (!context.isSuccess) return context;
  const { data, error } = await context.value.supabase.rpc("get_my_participant_profile_context");
  return error
    ? failure(profileError(error))
    : success({ context: context.value, data: record(data) });
}

export async function loadParticipantProfileContextOperation(): Promise<
  ReturnType<typeof success<ProfileContext>> | ReturnType<typeof failure<AppError>>
> {
  const loaded = await rawProfileContext();
  if (!loaded.isSuccess) return loaded;
  const avatarPath =
    typeof loaded.value.data?.avatar_path === "string" ? loaded.value.data.avatar_path : null;
  const coachRow = record(loaded.value.data?.coach);
  const coachName = typeof coachRow?.display_name === "string" ? coachRow.display_name : null;
  return success({
    avatarUrl: avatarPath
      ? loaded.value.context.supabase.storage.from("public-media").getPublicUrl(avatarPath).data
          .publicUrl
      : null,
    coach: coachName
      ? {
          city: typeof coachRow?.city === "string" && coachRow.city ? coachRow.city : null,
          displayName: coachName,
          photoUrl: typeof coachRow?.photo_reference === "string" ? coachRow.photo_reference : null,
        }
      : null,
  });
}

export async function updateParticipantAvatarOperation(
  input: Readonly<{
    bytes: Uint8Array;
    declaredMimeType: string;
    idempotencyKey: string;
  }>,
) {
  if (!/^[A-Za-z0-9][A-Za-z0-9._:-]{15,127}$/.test(input.idempotencyKey)) {
    return failure(new AppError("validation_failed", "Permintaan foto profil tidak valid."));
  }
  const sanitized = sanitizeServerImageUpload(input.bytes, input.declaredMimeType);
  if (!sanitized.isSuccess) return sanitized;
  const loaded = await rawProfileContext();
  if (!loaded.isSuccess) return loaded;
  const previousPath =
    typeof loaded.value.data?.avatar_path === "string" ? loaded.value.data.avatar_path : null;
  const path = `avatars/${loaded.value.context.actor.userId}/${randomUUID()}.jpg`;
  let service;
  try {
    service = createSupabaseServiceClient();
  } catch (error) {
    return failure(error instanceof AppError ? error : profileError(error));
  }
  const upload = await service.storage.from("public-media").upload(path, sanitized.value.bytes, {
    cacheControl: "3600",
    contentType: "image/jpeg",
    upsert: false,
  });
  if (upload.error) return failure(profileError(upload.error));
  const update = await loaded.value.context.supabase.rpc("update_my_profile_avatar", {
    request_idempotency_key: input.idempotencyKey,
    target_path: path,
  });
  if (update.error) {
    await service.storage.from("public-media").remove([path]);
    return failure(profileError(update.error));
  }
  if (previousPath && previousPath !== path) {
    await service.storage.from("public-media").remove([previousPath]);
  }
  return success({
    avatarUrl: service.storage.from("public-media").getPublicUrl(path).data.publicUrl,
  });
}

export async function changeParticipantCoachOperation(
  input: Readonly<{
    coachQrPayload: string;
    idempotencyKey: string;
  }>,
) {
  if (
    input.coachQrPayload.length < 16 ||
    input.coachQrPayload.length > 128 ||
    !/^[A-Za-z0-9][A-Za-z0-9._:-]{15,127}$/.test(input.idempotencyKey)
  ) {
    return failure(new AppError("validation_failed", "QR Coach tidak valid."));
  }
  const context = await getVerifiedSupabaseContext();
  if (!context.isSuccess) return context;
  const { data, error } = await context.value.supabase.rpc("change_my_coach_from_qr", {
    request_idempotency_key: input.idempotencyKey,
    scanned_coach_qr: input.coachQrPayload,
  });
  if (error) return failure(profileError(error));
  const coach = record(data);
  return coach && typeof coach.display_name === "string"
    ? success({ displayName: coach.display_name })
    : failure(new AppError("validation_failed", "Hasil pergantian Coach tidak valid."));
}
