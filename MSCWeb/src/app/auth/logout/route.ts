import { cookies } from "next/headers";

import { signOutLocalSession } from "@/application/auth/server-auth-operations";
import { AUTH_FLOW_COOKIE, PENDING_PROGRAM_COOKIE } from "@/features/auth/model/auth-flow";
import { relativeRedirect } from "@/shared/security/relative-redirect";

export async function POST() {
  try {
    await signOutLocalSession();
  } catch {
    // Cookie cleanup below remains safe when the provider is temporarily unavailable.
  }

  const cookieStore = await cookies();
  cookieStore.delete(AUTH_FLOW_COOKIE);
  cookieStore.delete(PENDING_PROGRAM_COOKIE);
  const response = relativeRedirect("/masuk?status=keluar", 303);
  response.headers.set("Cache-Control", "no-store");
  response.headers.set("Clear-Site-Data", '"cache", "storage"');
  return response;
}
