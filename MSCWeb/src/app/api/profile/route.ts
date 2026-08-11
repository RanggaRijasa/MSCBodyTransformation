import { NextResponse } from "next/server";

import { updateProfileOperation } from "@/application/auth/server-auth-operations";
import { memberLevels, type MemberLevel } from "@/features/auth/model/auth-model";
import { loadVerifiedProfile } from "@/features/auth/server/profile-repository";

type ProfileUpdateRequest = Readonly<{ displayName?: unknown; phoneNumber?: unknown }>;

export async function PATCH(request: Request) {
  const profile = await loadVerifiedProfile();
  if (!profile.isSuccess)
    return NextResponse.json({ code: "authentication_required" }, { status: 401 });
  let body: ProfileUpdateRequest;
  try {
    body = (await request.json()) as ProfileUpdateRequest;
  } catch {
    return NextResponse.json({ code: "request_invalid" }, { status: 400 });
  }
  if (typeof body.displayName !== "string" || typeof body.phoneNumber !== "string")
    return NextResponse.json({ code: "validation_failed" }, { status: 422 });
  const memberLevel = profile.value.memberLevel;
  if (!memberLevel || !(memberLevels as readonly string[]).includes(memberLevel))
    return NextResponse.json({ code: "profile_incomplete" }, { status: 409 });
  const didUpdate = await updateProfileOperation({
    accountPurpose: profile.value.accountPurpose,
    displayName: body.displayName,
    memberLevel: memberLevel as MemberLevel,
    phoneNumber: body.phoneNumber,
  });
  if (!didUpdate) return NextResponse.json({ code: "profile_update_failed" }, { status: 409 });
  return NextResponse.json({ status: "updated" }, { headers: { "Cache-Control": "no-store" } });
}
