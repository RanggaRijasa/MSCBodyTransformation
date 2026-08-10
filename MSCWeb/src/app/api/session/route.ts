import { NextResponse } from "next/server";

import { loadVerifiedProfileOperation } from "@/application/auth/server-auth-operations";

const privateHeaders = { "Cache-Control": "private, no-store" };

export async function GET() {
  const profile = await loadVerifiedProfileOperation();
  if (!profile.isSuccess) {
    return NextResponse.json({ state: "guest" }, { headers: privateHeaders });
  }
  return NextResponse.json(
    {
      role: profile.value.role,
      state: profile.value.onboardingStatus === "active" ? "authenticated" : "onboarding",
    },
    { headers: privateHeaders },
  );
}
