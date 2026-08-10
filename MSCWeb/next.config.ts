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
          {
            key: "Permissions-Policy",
            value: "camera=(self), microphone=(), geolocation=()",
          },
        ],
        source: "/:path*",
      },
    ];
  },
};

export default nextConfig;
