import "server-only";

import { redirect } from "next/navigation";

import { canAccessRole, roleHome, type AppRole } from "@/features/auth/model/auth-model";
import { safeReturnTo } from "@/features/auth/model/auth-flow";
import { loadVerifiedProfile } from "@/features/auth/server/profile-repository";

export async function requireVerifiedProfile(returnTo: string) {
  const profile = await loadVerifiedProfile();
  if (!profile.isSuccess) {
    redirect(`/masuk?returnTo=${encodeURIComponent(safeReturnTo(returnTo))}`);
  }
  return profile.value;
}

export async function requireRole(requiredRole: AppRole, returnTo: string) {
  const profile = await requireVerifiedProfile(returnTo);
  if (profile.onboardingStatus === "provisional") {
    redirect("/onboarding");
  }
  if (!canAccessRole(requiredRole, profile.role)) {
    redirect(roleHome(profile.role));
  }
  return profile;
}
