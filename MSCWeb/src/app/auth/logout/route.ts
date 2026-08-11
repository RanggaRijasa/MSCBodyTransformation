import { cookies } from "next/headers";
import { NextResponse, type NextRequest } from "next/server";

import { signOutLocalSession } from "@/application/auth/server-auth-operations";
import { AUTH_FLOW_COOKIE, PENDING_PROGRAM_COOKIE } from "@/features/auth/model/auth-flow";

export async function POST(request: NextRequest) {
  try {
    await signOutLocalSession();
  } catch {
    // Cookie cleanup below remains safe when the provider is temporarily unavailable.
  }

  const cookieStore = await cookies();
  cookieStore.delete(AUTH_FLOW_COOKIE);
  cookieStore.delete(PENDING_PROGRAM_COOKIE);
  const response = NextResponse.redirect(new URL("/masuk?status=keluar", request.url), 303);
  response.headers.set("Cache-Control", "no-store");
  response.headers.set("Clear-Site-Data", '"cache", "storage"');
  return response;
}
