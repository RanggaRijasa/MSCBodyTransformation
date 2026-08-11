import type { AppError } from "@/domain/errors/app-error";
import type { Result } from "@/domain/result";

export interface ServiceHealthRepository {
  checkAvailability(): Promise<Result<"available", AppError>>;
}
