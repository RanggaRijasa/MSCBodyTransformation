import type { NextConfig } from "next";

function supabaseImagePattern(): Array<{
  hostname: string;
  pathname: string;
  port: string;
  protocol: "http" | "https";
}> {
  try {
    const url = new URL(process.env.NEXT_PUBLIC_SUPABASE_URL ?? "");
    if (url.protocol !== "http:" && url.protocol !== "https:") return [];
    return [
      {
        hostname: url.hostname,
        pathname: "/storage/v1/object/public/public-media/**",
        port: url.port,
        protocol: url.protocol.slice(0, -1) as "http" | "https",
      },
    ];
  } catch {
    return [];
  }
}

const nextConfig: NextConfig = {
  images: { remotePatterns: supabaseImagePattern() },
  poweredByHeader: false,
  reactStrictMode: true,
  async headers() {
    return [
      {
        headers: [
          { key: "Cross-Origin-Opener-Policy", value: "same-origin-allow-popups" },
          { key: "Cross-Origin-Resource-Policy", value: "same-origin" },
          { key: "Origin-Agent-Cluster", value: "?1" },
          {
            key: "Permissions-Policy",
            value: "camera=(self), microphone=(), geolocation=(), payment=(), usb=()",
          },
          { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
          {
            key: "Strict-Transport-Security",
            value: "max-age=63072000; includeSubDomains; preload",
          },
          { key: "X-Content-Type-Options", value: "nosniff" },
          { key: "X-Frame-Options", value: "DENY" },
        ],
        source: "/:path*",
      },
      {
        headers: [{ key: "Cache-Control", value: "private, no-store, max-age=0" }],
        source:
          "/:path(hari-ini|coach|profil|peringkat|program|pembayaran|akses-coach|coach-area|admin|api|auth)/:rest*",
      },
      {
        headers: [{ key: "Cache-Control", value: "private, no-store, max-age=0" }],
        source: "/",
      },
      {
        headers: [{ key: "Cache-Control", value: "no-cache, no-store, must-revalidate" }],
        source: "/sw.js",
      },
      {
        headers: [
          { key: "Cache-Control", value: "no-cache, no-store, must-revalidate" },
          {
            key: "Content-Security-Policy",
            value:
              "default-src 'self'; style-src 'unsafe-inline'; script-src 'none'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'",
          },
        ],
        source: "/offline.html",
      },
      {
        headers: [{ key: "Cache-Control", value: "no-cache, max-age=0" }],
        source: "/manifest.webmanifest",
      },
      {
        headers: [{ key: "Cache-Control", value: "public, max-age=31536000, immutable" }],
        source: "/icons/:path*",
      },
    ];
  },
};

export default nextConfig;
