import type { Metadata } from "next";
import { Poppins } from "next/font/google";
import type { ReactNode } from "react";

import "@/features/landing/styles/landing.css";
import "@/features/landing/styles/landing-sections.css";
import "@/features/landing/styles/landing-results.css";
import "@/features/landing/styles/landing-responsive.css";
import "@/features/landing/styles/landing-narrow.css";
import "@/features/pwa-install/styles/pwa-install.css";
import { copy } from "@/shared/i18n/id";

const poppins = Poppins({
  display: "swap",
  subsets: ["latin"],
  variable: "--font-poppins",
  weight: ["400", "500", "600", "700", "800"],
});

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
  return <div className={poppins.variable}>{children}</div>;
}
