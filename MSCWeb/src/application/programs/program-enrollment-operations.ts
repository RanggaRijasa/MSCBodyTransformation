import "server-only";

import { AppError } from "@/domain/errors/app-error";
import {
  isProgramIdentifier,
  mapEnrollmentProviderError,
  parseEnrollmentAvailability,
  type CoachPreflight,
  type EnrollmentAvailability,
} from "@/domain/programs/enrollment";
import { failure, success, type Result } from "@/domain/result";
import { getVerifiedSupabaseContext } from "@/infrastructure/supabase/auth/get-verified-actor";

type CoachPreflightRow = Readonly<{
  city?: unknown;
  display_name?: unknown;
  photo_reference?: unknown;
}>;

async function availability(programId: string): Promise<Result<EnrollmentAvailability, AppError>> {
  if (!isProgramIdentifier(programId)) {
    return failure(new AppError("validation_failed", "Program tidak valid."));
  }
  const context = await getVerifiedSupabaseContext();
  if (!context.isSuccess) return context;
  const { data, error } = await context.value.supabase.rpc(
    "pending_program_enrollment_availability",
    { target_program_id: programId },
  );
  if (error) return failure(mapEnrollmentProviderError(error));
  const parsed = parseEnrollmentAvailability(data);
  return parsed
    ? success(parsed)
    : failure(new AppError("validation_failed", "Status pendaftaran tidak valid."));
}

export const loadEnrollmentAvailabilityOperation = availability;

export async function resolveCoachForProgramOperation(
  programId: string,
  coachQrPayload: string,
): Promise<Result<CoachPreflight, AppError>> {
  const programAvailability = await availability(programId);
  if (!programAvailability.isSuccess) return programAvailability;
  if (programAvailability.value !== "available") {
    return failure(mapEnrollmentProviderError({ message: programAvailability.value }));
  }
  if (coachQrPayload.length < 16 || coachQrPayload.length > 128) {
    return failure(new AppError("validation_failed", "QR Coach tidak valid."));
  }
  const context = await getVerifiedSupabaseContext();
  if (!context.isSuccess) return context;
  const { data, error } = await context.value.supabase.rpc("resolve_coach_qr_for_enrollment", {
    scanned_coach_qr: coachQrPayload,
  });
  if (error) return failure(mapEnrollmentProviderError(error));
  const row = data as CoachPreflightRow | null;
  if (!row || typeof row.display_name !== "string" || typeof row.city !== "string") {
    return failure(new AppError("validation_failed", "Data Coach tidak valid."));
  }
  return success({
    city: row.city,
    displayName: row.display_name,
    photoUrl: typeof row.photo_reference === "string" ? row.photo_reference : null,
  });
}

export async function enrollFreeProgramOperation(
  programId: string,
  coachQrPayload: string,
): Promise<Result<Readonly<{ enrollmentId: string; programId: string }>, AppError>> {
  if (
    !isProgramIdentifier(programId) ||
    coachQrPayload.length < 16 ||
    coachQrPayload.length > 128
  ) {
    return failure(new AppError("validation_failed", "Permintaan pendaftaran tidak valid."));
  }
  const context = await getVerifiedSupabaseContext();
  if (!context.isSuccess) return context;
  const { data, error } = await context.value.supabase.rpc("enroll_free_program", {
    scanned_coach_qr: coachQrPayload,
    target_program_id: programId,
  });
  if (error) return failure(mapEnrollmentProviderError(error));
  const row = data as { id?: unknown; program_id?: unknown } | null;
  if (!row || typeof row.id !== "string" || row.program_id !== programId) {
    return failure(new AppError("validation_failed", "Hasil pendaftaran tidak valid."));
  }
  return success({ enrollmentId: row.id, programId });
}
