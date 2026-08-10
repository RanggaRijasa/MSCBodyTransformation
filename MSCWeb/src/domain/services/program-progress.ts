import { AppError } from "@/domain/errors/app-error";
import { failure, success, type Result } from "@/domain/result";

export function calculateCompletionPercentage(
  completedActivityCount: number,
  requiredActivityCount: number,
): Result<number, AppError> {
  if (
    !Number.isInteger(completedActivityCount) ||
    !Number.isInteger(requiredActivityCount) ||
    completedActivityCount < 0 ||
    requiredActivityCount < 0 ||
    completedActivityCount > requiredActivityCount
  ) {
    return failure(new AppError("validation_failed", "Jumlah aktivitas program tidak valid."));
  }

  if (requiredActivityCount === 0) {
    return success(0);
  }

  return success(Math.round((completedActivityCount / requiredActivityCount) * 100));
}
