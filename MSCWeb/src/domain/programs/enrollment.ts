import { AppError } from "@/domain/errors/app-error";

export type EnrollmentAvailability =
  "available" | "already_enrolled" | "program_full" | "program_unavailable" | "registration_closed";

export type CoachPreflight = Readonly<{
  city: string;
  displayName: string;
  photoUrl: string | null;
}>;

const knownAvailability = new Set<EnrollmentAvailability>([
  "available",
  "already_enrolled",
  "program_full",
  "program_unavailable",
  "registration_closed",
]);

export function parseEnrollmentAvailability(value: unknown): EnrollmentAvailability | null {
  return typeof value === "string" && knownAvailability.has(value as EnrollmentAvailability)
    ? (value as EnrollmentAvailability)
    : null;
}

export function mapEnrollmentProviderError(error: unknown): AppError {
  const message =
    error && typeof error === "object" && "message" in error
      ? String((error as { message: unknown }).message)
      : "";
  if (message.includes("registration_closed")) {
    return new AppError("conflict", "Pendaftaran program ini sudah ditutup.");
  }
  if (message.includes("program_full")) {
    return new AppError("conflict", "Kapasitas program sudah penuh.");
  }
  if (message.includes("coach_mismatch")) {
    return new AppError("conflict", "QR berasal dari Coach yang berbeda dengan Coach aktifmu.");
  }
  if (message.includes("coach_qr_invalid") || message.includes("coach_invalid")) {
    return new AppError("validation_failed", "QR Coach tidak valid atau Coach sudah tidak aktif.");
  }
  if (message.includes("already_enrolled")) {
    return new AppError("conflict", "Kamu sudah terdaftar pada program ini.");
  }
  if (message.includes("program_unavailable")) {
    return new AppError("conflict", "Program belum tersedia untuk pendaftaran.");
  }
  if (message.includes("permission_denied") || message.includes("profile_incomplete")) {
    return new AppError("forbidden", "Akun ini tidak dapat mendaftar program.");
  }
  return new AppError("unknown", "Pendaftaran belum dapat diproses. Coba lagi.");
}

export function isProgramIdentifier(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}
