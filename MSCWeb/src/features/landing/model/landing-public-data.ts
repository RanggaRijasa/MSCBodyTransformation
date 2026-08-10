import type {
  PublicCoachTeaser,
  PublicProgramTeaser,
} from "@/features/landing/model/public-teaser";

export type LandingPublicData = Readonly<{
  availability: "available" | "unavailable";
  coaches: readonly PublicCoachTeaser[];
  programs: readonly PublicProgramTeaser[];
}>;

export interface LandingPublicRepository {
  loadPublicLandingData(): Promise<LandingPublicData>;
}

export async function loadLandingPublicData(
  repository: LandingPublicRepository,
): Promise<LandingPublicData> {
  try {
    return await repository.loadPublicLandingData();
  } catch {
    return { availability: "unavailable", coaches: [], programs: [] };
  }
}
