import "server-only";

import type { LandingActor } from "@/features/landing/model/landing-actor";
import type {
  LandingPublicData,
  LandingPublicRepository,
} from "@/features/landing/model/landing-public-data";
import { loadLandingPublicData } from "@/features/landing/model/landing-public-data";
import { loadVerifiedProfile } from "@/features/auth";

const localPublicRepository: LandingPublicRepository = {
  async loadPublicLandingData(): Promise<LandingPublicData> {
    return { availability: "available", coaches: [], programs: [] };
  },
};

export async function loadTrustedLandingActor(): Promise<LandingActor> {
  const profile = await loadVerifiedProfile();
  if (!profile.isSuccess || profile.value.onboardingStatus !== "active") {
    return { kind: "anonymous" };
  }
  return { kind: "authenticated", role: profile.value.role };
}

export function loadSafeLandingPublicData(): Promise<LandingPublicData> {
  return loadLandingPublicData(localPublicRepository);
}
