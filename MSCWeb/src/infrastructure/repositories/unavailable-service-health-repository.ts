import { AppError } from "@/domain/errors/app-error";
import { failure, type Result } from "@/domain/result";
import type { ServiceHealthRepository } from "@/domain/repositories/service-health-repository";

export class UnavailableServiceHealthRepository implements ServiceHealthRepository {
  async checkAvailability(): Promise<Result<"available", AppError>> {
    return Promise.resolve(
      failure(new AppError("configuration_invalid", "Layanan belum dikonfigurasi.")),
    );
  }
}
