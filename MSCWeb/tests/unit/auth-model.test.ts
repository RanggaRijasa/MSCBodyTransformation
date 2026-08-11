import { describe, expect, it } from "vitest";

import {
  canAccessRole,
  isCoachApplicantEligible,
  roleHome,
  validateOnboardingDraft,
} from "@/features/auth/model/auth-model";

const eligibleCoachDraft = {
  accountPurpose: "coach_applicant" as const,
  displayName: "Ayu Lestari",
  hasCompletedHomSts: true,
  hasCompletedIct: true,
  memberLevel: "sc" as const,
  phoneNumber: "+628123456789",
};

describe("auth and onboarding model", () => {
  it("tidak pernah menaikkan role dari pilihan tujuan akun", () => {
    expect(roleHome("participant")).toBe("/hari-ini");
    expect(canAccessRole("coach", "participant")).toBe(false);
    expect(canAccessRole("admin", "participant")).toBe(false);
    expect(canAccessRole("participant", "participant")).toBe(true);
  });

  it("mensyaratkan SC+ serta HOM STS dan ICT untuk pengajuan Coach", () => {
    expect(isCoachApplicantEligible(eligibleCoachDraft)).toBe(true);
    expect(isCoachApplicantEligible({ ...eligibleCoachDraft, memberLevel: "member" })).toBe(false);
    expect(isCoachApplicantEligible({ ...eligibleCoachDraft, hasCompletedIct: false })).toBe(false);
  });

  it("memvalidasi nama dan nomor HP dengan pesan Bahasa Indonesia", () => {
    expect(validateOnboardingDraft(eligibleCoachDraft)).toEqual([]);
    expect(
      validateOnboardingDraft({ ...eligibleCoachDraft, displayName: "A", phoneNumber: "123" }),
    ).toEqual(["Masukkan nama antara 2 sampai 80 karakter.", "Masukkan nomor HP yang valid."]);
  });
});
