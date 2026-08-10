export const appRoles = ["participant", "coach", "admin"] as const;
export type AppRole = (typeof appRoles)[number];

export const memberLevels = [
  "member",
  "sc",
  "sb",
  "supervisor",
  "world_team",
  "tab_team",
  "get_team",
  "millionaire_team",
  "presidents_team",
] as const;

export type MemberLevel = (typeof memberLevels)[number];
export type AccountPurpose = "participant" | "coach_applicant";
export type OnboardingStatus =
  "provisional" | "coach_handoff_pending" | "active" | "cleanup_pending";

export type AuthenticatedProfile = Readonly<{
  accountPurpose: AccountPurpose;
  avatarUrl: string | null;
  displayName: string;
  email: string;
  memberLevel: MemberLevel | null;
  onboardingStatus: OnboardingStatus;
  phoneNumber: string | null;
  role: AppRole;
}>;

export type OnboardingDraft = Readonly<{
  accountPurpose: AccountPurpose;
  displayName: string;
  hasCompletedHomSts: boolean;
  hasCompletedIct: boolean;
  memberLevel: MemberLevel;
  phoneNumber: string;
}>;

export const memberLevelLabels: Readonly<Record<MemberLevel, string>> = {
  member: "Member",
  sc: "SC",
  sb: "SB",
  supervisor: "Supervisor",
  world_team: "World Team",
  tab_team: "TAB Team",
  get_team: "GET Team",
  millionaire_team: "Millionaire Team",
  presidents_team: "President’s Team",
};

const coachEligibleLevels = new Set<MemberLevel>(
  memberLevels.filter((level) => level !== "member"),
);

export function isCoachApplicantEligible(draft: OnboardingDraft): boolean {
  return (
    draft.accountPurpose === "coach_applicant" &&
    coachEligibleLevels.has(draft.memberLevel) &&
    draft.hasCompletedHomSts &&
    draft.hasCompletedIct
  );
}

export function validateOnboardingDraft(draft: OnboardingDraft): readonly string[] {
  const errors: string[] = [];
  const normalizedName = draft.displayName.trim();
  const normalizedPhone = draft.phoneNumber.replace(/[\s()-]/g, "");

  if (normalizedName.length < 2 || normalizedName.length > 80) {
    errors.push("Masukkan nama antara 2 sampai 80 karakter.");
  }
  if (!/^\+?[0-9]{8,15}$/.test(normalizedPhone)) {
    errors.push("Masukkan nomor HP yang valid.");
  }
  if (draft.accountPurpose === "coach_applicant" && !isCoachApplicantEligible(draft)) {
    errors.push(
      "Pengajuan Coach memerlukan level SC atau lebih tinggi serta konfirmasi HOM STS dan ICT.",
    );
  }
  return errors;
}

export function roleHome(role: AppRole): string {
  switch (role) {
    case "admin":
      return "/admin";
    case "coach":
      return "/coach-area";
    case "participant":
      return "/hari-ini";
  }
}

export function canAccessRole(requiredRole: AppRole, actualRole: AppRole): boolean {
  return requiredRole === actualRole || (requiredRole === "participant" && actualRole === "coach");
}
