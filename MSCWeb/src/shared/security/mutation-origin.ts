import type { NextRequest } from "next/server";

function firstForwardedValue(value: string | null): string {
  return value?.split(",", 1)[0]?.trim() ?? "";
}

function effectiveRequestOrigin(request: NextRequest): string | null {
  const host =
    firstForwardedValue(request.headers.get("x-forwarded-host")) ||
    firstForwardedValue(request.headers.get("host"));
  const protocol =
    firstForwardedValue(request.headers.get("x-forwarded-proto")) ||
    request.nextUrl.protocol.replace(":", "");

  if (!host || (protocol !== "http" && protocol !== "https")) return null;

  try {
    const effectiveUrl = new URL(`${protocol}://${host}`);
    return effectiveUrl.host === host.toLowerCase() ? effectiveUrl.origin : null;
  } catch {
    return null;
  }
}

export function hasTrustedMutationOrigin(request: NextRequest): boolean {
  const fetchSite = request.headers.get("sec-fetch-site");
  if (fetchSite && !["same-origin", "same-site", "none"].includes(fetchSite)) return false;

  const origin = request.headers.get("origin");
  if (!origin) return fetchSite === "same-origin";
  try {
    const requestOrigin = effectiveRequestOrigin(request);
    return requestOrigin !== null && new URL(origin).origin === requestOrigin;
  } catch {
    return false;
  }
}
