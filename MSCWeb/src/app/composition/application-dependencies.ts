import { SystemClock, type Clock } from "@/core/clock/clock";
import {
  CryptoIdentifierGenerator,
  type IdentifierGenerator,
} from "@/core/identifiers/identifier-generator";
import type { ServiceHealthRepository } from "@/domain/repositories/service-health-repository";
import { InMemoryServiceHealthRepository } from "@/infrastructure/repositories/in-memory-service-health-repository";
import { UnavailableServiceHealthRepository } from "@/infrastructure/repositories/unavailable-service-health-repository";

export type ApplicationDependencies = Readonly<{
  clock: Clock;
  identifierGenerator: IdentifierGenerator;
  serviceHealthRepository: ServiceHealthRepository;
}>;

export type ApplicationComposition = "local-demo" | "supabase";

export function makeApplicationDependencies(
  composition: ApplicationComposition,
): ApplicationDependencies {
  return {
    clock: new SystemClock(),
    identifierGenerator: new CryptoIdentifierGenerator(),
    serviceHealthRepository:
      composition === "local-demo"
        ? new InMemoryServiceHealthRepository()
        : new UnavailableServiceHealthRepository(),
  };
}
