import Link from "next/link";

import { BrandMark } from "@/features/landing/components/brand-mark";
import { copy } from "@/shared/i18n/id";

export function MarketingHeader() {
  return (
    <header className="marketing-header">
      <div className="marketing-header__inner">
        <Link className="marketing-wordmark" href="/" aria-label="MSC Body Transformation">
          <BrandMark eager />
        </Link>
        <nav aria-label={copy.landing.navigation.label} className="marketing-nav">
          <Link href="/program">{copy.landing.navigation.program}</Link>
          <a href="#cara-kerja">{copy.landing.navigation.howItWorks}</a>
          <a href="#untuk-coach">{copy.landing.navigation.forCoach}</a>
        </nav>
        <div className="marketing-header__actions">
          <Link className="marketing-sign-in" href="/masuk">
            {copy.landing.navigation.signIn}
          </Link>
        </div>
        <details className="marketing-menu">
          <summary tabIndex={0}>{copy.landing.navigation.menu}</summary>
          <nav aria-label={`${copy.landing.navigation.label} seluler`}>
            <Link href="/program">{copy.landing.navigation.program}</Link>
            <a href="#cara-kerja">{copy.landing.navigation.howItWorks}</a>
            <a href="#untuk-coach">{copy.landing.navigation.forCoach}</a>
            <Link href="/masuk">{copy.landing.navigation.signIn}</Link>
          </nav>
        </details>
      </div>
    </header>
  );
}
