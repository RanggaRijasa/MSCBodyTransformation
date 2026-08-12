import { cookies } from "next/headers";
import { NextResponse, type NextRequest } from "next/server";

import {
  PENDING_PROGRAM_COOKIE,
  PENDING_PROGRAM_TTL_SECONDS,
  createPendingProgramIntent,
} from "@/features/auth/model/auth-flow";
import { readAuthServerEnvironment } from "@/features/auth/server/auth-environment";
import { sealCookie } from "@/features/auth/server/sealed-cookie";
import { relativeRedirect } from "@/shared/security/relative-redirect";

export async function POST(request: NextRequest) {
  const formData = await request.formData();
  const programId = formData.get("programId");
  if (typeof programId !== "string") {
    return NextResponse.json({ code: "program_required" }, { status: 400 });
  }
  try {
    const environment = readAuthServerEnvironment();
    const intent = createPendingProgramIntent({
      environment: environment.environmentName,
      now: Math.floor(Date.now() / 1000),
      programId,
    });
    if (!intent) {
      return NextResponse.json({ code: "program_invalid" }, { status: 422 });
    }
    (await cookies()).set(
      PENDING_PROGRAM_COOKIE,
      await sealCookie(intent, environment.cookieSecret),
      {
        httpOnly: true,
        maxAge: PENDING_PROGRAM_TTL_SECONDS,
        path: "/",
        sameSite: "lax",
        secure: request.nextUrl.protocol === "https:",
      },
    );
    const query = new URLSearchParams({ returnTo: `/program/${programId}` });
    return relativeRedirect(`/masuk?${query.toString()}`, 303);
  } catch {
    return NextResponse.json({ code: "authentication_configuration_missing" }, { status: 503 });
  }
}
