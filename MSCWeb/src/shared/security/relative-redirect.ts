import { NextResponse } from "next/server";

type RelativeRedirectStatus = 301 | 302 | 303 | 307 | 308;

const redirectValidationOrigin = "https://msc.invalid";

export function relativeRedirect(location: string, status: RelativeRedirectStatus = 307) {
  const parsed = new URL(location, redirectValidationOrigin);
  if (
    !location.startsWith("/") ||
    location.startsWith("//") ||
    location.includes("\\") ||
    parsed.origin !== redirectValidationOrigin ||
    parsed.username ||
    parsed.password
  ) {
    throw new Error("Redirect internal harus memakai path relatif yang aman.");
  }
  return new NextResponse(null, { headers: { Location: location }, status });
}
