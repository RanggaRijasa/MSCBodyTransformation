import type { Metadata } from "next";

import { PublicInformationPage } from "@/features/landing";
import { copy } from "@/shared/i18n/id";

export const metadata: Metadata = {
  alternates: { canonical: "/ketentuan" },
  title: copy.landing.information.termsTitle,
  robots: "noindex",
};

export default function TermsPage() {
  return (
    <PublicInformationPage
      summary={copy.landing.information.termsSummary}
      title={copy.landing.information.termsTitle}
    />
  );
}
