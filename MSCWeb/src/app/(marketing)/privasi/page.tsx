import type { Metadata } from "next";

import { PublicInformationPage } from "@/features/landing";
import { copy } from "@/shared/i18n/id";

export const metadata: Metadata = {
  alternates: { canonical: "/privasi" },
  title: copy.landing.information.privacyTitle,
  robots: "noindex",
};

export default function PrivacyPage() {
  return (
    <PublicInformationPage
      summary={copy.landing.information.privacySummary}
      title={copy.landing.information.privacyTitle}
    />
  );
}
