import type { MetadataRoute } from "next";

import { absoluteSiteUrl } from "@/shared/config/site-url";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: "*",
      allow: ["/", "/program", "/peringkat", "/coach"],
      disallow: [
        "/admin/",
        "/auth/",
        "/bantuan",
        "/coach-area/",
        "/hari-ini",
        "/masuk",
        "/daftar",
        "/lupa-kata-sandi",
        "/ketentuan",
        "/pembayaran/",
        "/profil",
        "/privasi",
      ],
    },
    sitemap: absoluteSiteUrl("/sitemap.xml"),
  };
}
