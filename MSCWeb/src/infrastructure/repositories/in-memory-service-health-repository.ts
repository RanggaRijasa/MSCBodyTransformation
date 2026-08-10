import { success, type Result } from "@/domain/result";
import type { ServiceHealthRepository } from "@/domain/repositories/service-health-repository";

export class InMemoryServiceHealthRepository implements ServiceHealthRepository {
  async checkAvailability(): Promise<Result<"available", never>> {
    return Promise.resolve(success("available"));
  }
}
