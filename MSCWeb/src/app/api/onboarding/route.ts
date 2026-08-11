import { NextResponse } from "next/server";

import {
  cancelProvisionalIdentityOperation,
  completeOnboardingOperation,
} from "@/application/auth/server-auth-operations";
import {
  memberLevels,
  validateOnboardingDraft,
  type AccountPurpose,
  type MemberLevel,
  type OnboardingDraft,
} from "@/features/auth/model/auth-model";

type OnboardingRequest = Partial<OnboardingDraft> & Readonly<{ coachQrPayload?: unknown }>;

function isMemberLevel(value: unknown): value is MemberLevel {
  return typeof value === "string" && (memberLevels as readonly string[]).includes(value);
}
function isPurpose(value: unknown): value is AccountPurpose {
  return value === "participant" || value === "coach_applicant";
}
function parseDraft(body: OnboardingRequest): OnboardingDraft | null {
  if (
    typeof body.displayName !== "string" ||
    typeof body.phoneNumber !== "string" ||
    typeof body.hasCompletedHomSts !== "boolean" ||
    typeof body.hasCompletedIct !== "boolean" ||
    !isMemberLevel(body.memberLevel) ||
    !isPurpose(body.accountPurpose)
  )
    return null;
  return {
    accountPurpose: body.accountPurpose,
    displayName: body.displayName,
    hasCompletedHomSts: body.hasCompletedHomSts,
    hasCompletedIct: body.hasCompletedIct,
    memberLevel: body.memberLevel,
    phoneNumber: body.phoneNumber,
  };
}

export async function POST(request: Request) {
  let body: OnboardingRequest;
  try {
    body = (await request.json()) as OnboardingRequest;
  } catch {
    return NextResponse.json({ code: "request_invalid" }, { status: 400 });
  }
  const draft = parseDraft(body);
  const errors = draft ? validateOnboardingDraft(draft) : ["Data profil belum lengkap."];
  if (!draft || errors.length > 0)
    return NextResponse.json({ code: "validation_failed", errors }, { status: 422 });

  if (
    draft.accountPurpose === "participant" &&
    (typeof body.coachQrPayload !== "string" || body.coachQrPayload.trim().length === 0)
  ) {
    return NextResponse.json({ code: "coach_qr_required" }, { status: 409 });
  }
  const status = await completeOnboardingOperation(
    draft,
    typeof body.coachQrPayload === "string" ? body.coachQrPayload : undefined,
  );
  if (!status)
    return NextResponse.json(
      {
        code: draft.accountPurpose === "participant" ? "coach_qr_invalid" : "coach_handoff_failed",
      },
      { status: 409 },
    );
  return NextResponse.json({ destination: "/hari-ini", status });
}

export async function DELETE() {
  if (!(await cancelProvisionalIdentityOperation()))
    return NextResponse.json({ code: "cleanup_not_allowed" }, { status: 409 });
  return new NextResponse(null, { status: 204, headers: { "Cache-Control": "no-store" } });
}
