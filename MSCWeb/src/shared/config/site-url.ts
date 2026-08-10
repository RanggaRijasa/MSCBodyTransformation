const localSiteOrigin = "http://localhost:3000";

export function getSiteOrigin(): URL {
  const configured = process.env.NEXT_PUBLIC_SITE_URL?.trim();
  if (!configured) return new URL(localSiteOrigin);

  const url = new URL(configured);
  if (!/https?:/.test(url.protocol) || url.username || url.password) {
    throw new Error("NEXT_PUBLIC_SITE_URL harus berupa origin HTTP(S) tanpa kredensial.");
  }
  url.pathname = "/";
  url.search = "";
  url.hash = "";
  return url;
}

export function absoluteSiteUrl(pathname = "/"): string {
  return new URL(pathname, getSiteOrigin()).toString();
}
