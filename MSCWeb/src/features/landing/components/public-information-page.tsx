import Link from "next/link";

import { copy } from "@/shared/i18n/id";

export function PublicInformationPage({
  summary,
  title,
}: Readonly<{ summary: string; title: string }>) {
  return (
    <main className="public-information-page">
      <div>
        <p className="landing-eyebrow">MSC Body Transformation</p>
        <h1>{title}</h1>
        <p>{summary}</p>
        <Link className="landing-text-link" href="/">
          {copy.landing.information.back}
        </Link>
      </div>
    </main>
  );
}
