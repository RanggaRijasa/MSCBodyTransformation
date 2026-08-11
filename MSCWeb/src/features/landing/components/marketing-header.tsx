import Link from "next/link";

import { InstallCta } from "@/features/pwa-install";
import { copy } from "@/shared/i18n/id";

export function MarketingHeader() {
  return (
    <header className="marketing-header">
      <div className="marketing-header__inner">
        <Link className="marketing-wordmark" href="/" aria-label="MSC Body Transformation">
          <span aria-hidden="true">MSC</span>
          <strong>Body Transformation</strong>
        </Link>
        <nav aria-label={copy.landing.navigation.label} className="marketing-nav">
          <a href="#program-publik">{copy.landing.navigation.program}</a>
          <a href="#cara-kerja">{copy.landing.navigation.howItWorks}</a>
          <a href="#untuk-coach">{copy.landing.navigation.forCoach}</a>
        </nav>
        <div className="marketing-header__actions">
          <Link className="marketing-sign-in" href="/masuk">
            {copy.landing.navigation.signIn}
          </Link>
          <InstallCta className="marketing-header__install" />
        </div>
        <details className="marketing-menu">
          <summary>{copy.landing.navigation.menu}</summary>
          <nav aria-label={`${copy.landing.navigation.label} mobile`}>
            <a href="#program-publik">{copy.landing.navigation.program}</a>
            <a href="#cara-kerja">{copy.landing.navigation.howItWorks}</a>
            <a href="#untuk-coach">{copy.landing.navigation.forCoach}</a>
            <Link href="/masuk">{copy.landing.navigation.signIn}</Link>
          </nav>
        </details>
      </div>
    </header>
  );
}
