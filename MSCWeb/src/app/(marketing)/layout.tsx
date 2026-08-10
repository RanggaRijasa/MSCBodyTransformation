import type { Metadata } from "next";
import type { ReactNode } from "react";

import { copy } from "@/shared/i18n/id";

export const metadata: Metadata = {
  title: copy.landing.metadata.title,
  description: copy.landing.metadata.description,
  alternates: { canonical: "/" },
  openGraph: {
    type: "website",
    locale: "id_ID",
    url: "/",
    siteName: "MSC Body Transformation",
    title: copy.landing.metadata.title,
    description: copy.landing.metadata.description,
  },
  twitter: {
    card: "summary_large_image",
    title: copy.landing.metadata.title,
    description: copy.landing.metadata.description,
  },
};

export default function MarketingLayout({ children }: Readonly<{ children: ReactNode }>) {
  return children;
}
