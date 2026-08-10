import type { Metadata } from "next";

import { PublicInformationPage } from "@/features/landing";
import { copy } from "@/shared/i18n/id";

export const metadata: Metadata = {
  alternates: { canonical: "/bantuan" },
  title: copy.landing.information.helpTitle,
  robots: "noindex",
};

export default function HelpPage() {
  return (
    <PublicInformationPage
      summary={copy.landing.information.helpSummary}
      title={copy.landing.information.helpTitle}
    />
  );
}
