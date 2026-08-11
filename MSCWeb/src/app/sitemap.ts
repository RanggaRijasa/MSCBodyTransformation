import type { MetadataRoute } from "next";

import { absoluteSiteUrl } from "@/shared/config/site-url";

export default function sitemap(): MetadataRoute.Sitemap {
  return [
    { url: absoluteSiteUrl("/"), changeFrequency: "weekly", priority: 1 },
    { url: absoluteSiteUrl("/program"), changeFrequency: "daily", priority: 0.9 },
    { url: absoluteSiteUrl("/peringkat"), changeFrequency: "daily", priority: 0.7 },
    { url: absoluteSiteUrl("/coach"), changeFrequency: "weekly", priority: 0.7 },
  ];
}
