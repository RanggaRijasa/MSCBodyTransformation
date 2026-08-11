import "server-only";

import { AppError } from "@/domain/errors/app-error";
import { failure, success, type Result } from "@/domain/result";
import {
  appRoles,
  memberLevels,
  type AccountPurpose,
  type AppRole,
  type AuthenticatedProfile,
  type MemberLevel,
  type OnboardingDraft,
  type OnboardingStatus,
} from "@/features/auth/model/auth-model";
import { getVerifiedSupabaseContext } from "@/infrastructure/supabase/auth/get-verified-actor";
import { createSupabaseServerClient } from "@/infrastructure/supabase/client/server";

type ProfileRow = Readonly<{
  account_purpose: string;
  provider_avatar_url: string | null;
  display_name: string;
  member_level: string | null;
  onboarding_status: string;
  phone_number: string | null;
  role: string;
}>;

const onboardingStatuses = new Set<OnboardingStatus>([
  "provisional",
  "coach_handoff_pending",
  "active",
  "cleanup_pending",
]);
const accountDeletionCodes = new Set([
  "recent_reauthentication_required",
  "admin_account_deletion_not_allowed",
  "account_relationships_require_transfer",
  "private_media_cleanup_required",
]);

function isRole(value: string): value is AppRole {
  return (appRoles as readonly string[]).includes(value);
}
function isMemberLevel(value: string): value is MemberLevel {
  return (memberLevels as readonly string[]).includes(value);
}
function isAccountPurpose(value: string): value is AccountPurpose {
  return value === "participant" || value === "coach_applicant";
}

function mapProfile(row: ProfileRow, email: string): AuthenticatedProfile | null {
  if (
    !isRole(row.role) ||
    !isAccountPurpose(row.account_purpose) ||
    !onboardingStatuses.has(row.onboarding_status as OnboardingStatus) ||
    (row.member_level !== null && !isMemberLevel(row.member_level))
  )
    return null;
  return {
    accountPurpose: row.account_purpose,
    avatarUrl: row.provider_avatar_url,
    displayName: row.display_name,
    email,
    memberLevel: row.member_level,
    onboardingStatus: row.onboarding_status as OnboardingStatus,
    phoneNumber: row.phone_number,
    role: row.role,
  };
}

export async function loadVerifiedProfileOperation(): Promise<
  Result<AuthenticatedProfile, AppError>
> {
  const context = await getVerifiedSupabaseContext();
  if (!context.isSuccess) return context;
  try {
    const { data, error } = await context.value.supabase
      .from("profiles")
      .select(
        "role,display_name,phone_number,provider_avatar_url,member_level,onboarding_status,account_purpose",
      )
      .eq("user_id", context.value.actor.userId)
      .single<ProfileRow>();
    if (error || !data)
      return failure(new AppError("unknown", "Profil belum dapat diverifikasi.", { cause: error }));
    const profile = mapProfile(data, context.value.actor.email);
    return profile
      ? success(profile)
      : failure(new AppError("unknown", "Status profil tidak valid."));
  } catch (error) {
    return failure(new AppError("unknown", "Profil belum dapat dimuat.", { cause: error }));
  }
}

export async function createGoogleAuthorizationUrl(redirectTo: string): Promise<string | null> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.auth.signInWithOAuth({
    provider: "google",
    options: { redirectTo, scopes: "openid email profile" },
  });
  return error ? null : data.url;
}

export async function exchangeAuthorizationCode(code: string): Promise<boolean> {
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase.auth.exchangeCodeForSession(code);
  return !error;
}

export async function signOutLocalSession(): Promise<void> {
  const supabase = await createSupabaseServerClient();
  await supabase.auth.signOut({ scope: "local" });
}

export async function updateProfileOperation(
  input: Readonly<{
    accountPurpose: AccountPurpose;
    displayName: string;
    memberLevel: MemberLevel;
    phoneNumber: string;
  }>,
): Promise<boolean> {
  const context = await getVerifiedSupabaseContext();
  if (!context.isSuccess) return false;
  return updateProfileWithClient(context.value.supabase, input);
}

async function updateProfileWithClient(
  supabase: Awaited<ReturnType<typeof createSupabaseServerClient>>,
  input: Readonly<{
    accountPurpose: AccountPurpose;
    displayName: string;
    memberLevel: MemberLevel;
    phoneNumber: string;
  }>,
): Promise<boolean> {
  const { error } = await supabase.rpc("update_my_profile", {
    new_account_purpose: input.accountPurpose,
    new_display_name: input.displayName.trim(),
    new_member_level: input.memberLevel,
    new_phone_number: input.phoneNumber,
  });
  return !error;
}

export async function completeOnboardingOperation(
  draft: OnboardingDraft,
  coachQrPayload?: string,
): Promise<"active" | "coach_handoff_pending" | null> {
  const context = await getVerifiedSupabaseContext();
  if (!context.isSuccess) return null;
  if (
    !(await updateProfileWithClient(context.value.supabase, {
      accountPurpose: draft.accountPurpose,
      displayName: draft.displayName,
      memberLevel: draft.memberLevel,
      phoneNumber: draft.phoneNumber,
    }))
  )
    return null;
  if (draft.accountPurpose === "participant") {
    if (!coachQrPayload) return null;
    const { error } = await context.value.supabase.rpc("finalize_participant_onboarding", {
      coach_qr: coachQrPayload,
    });
    return error ? null : "active";
  }
  const { error } = await context.value.supabase.rpc("prepare_coach_application_handoff");
  return error ? null : "coach_handoff_pending";
}

export async function cancelProvisionalIdentityOperation(): Promise<boolean> {
  const context = await getVerifiedSupabaseContext();
  if (!context.isSuccess) return false;
  const { error } = await context.value.supabase.rpc("cancel_my_provisional_identity");
  if (!error) await context.value.supabase.auth.signOut({ scope: "local" });
  return !error;
}

export async function deleteAccountOperation(): Promise<{ code?: string; success: boolean }> {
  const context = await getVerifiedSupabaseContext();
  if (!context.isSuccess) return { code: "authentication_required", success: false };
  const { error } = await context.value.supabase.functions.invoke("delete-account", {
    method: "POST",
  });
  if (!error) {
    await context.value.supabase.auth.signOut({ scope: "local" });
    return { success: true };
  }
  const errorResponse = error.context as Response | undefined;
  const payload = errorResponse
    ? ((await errorResponse
        .clone()
        .json()
        .catch(() => null)) as { code?: string } | null)
    : null;
  const code =
    payload?.code && accountDeletionCodes.has(payload.code)
      ? payload.code
      : "account_deletion_failed";
  return { code, success: false };
}
