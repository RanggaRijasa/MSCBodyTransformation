import Link from "next/link";

import { BrandMark } from "@/features/landing/components/brand-mark";
import { copy } from "@/shared/i18n/id";

export function MarketingFooter() {
  return (
    <footer className="marketing-footer">
      <div>
        <Link className="marketing-wordmark" href="/" aria-label="MSC Body Transformation">
          <BrandMark />
        </Link>
        <p>{copy.landing.footer.summary}</p>
      </div>
      <div className="marketing-footer__group">
        <strong>{copy.landing.footer.productTitle}</strong>
        <nav aria-label={copy.landing.footer.productNavigationLabel}>
          <Link href="/program">{copy.landing.navigation.program}</Link>
          <a href="#cara-kerja">{copy.landing.navigation.howItWorks}</a>
          <a href="#untuk-coach">{copy.landing.navigation.forCoach}</a>
        </nav>
      </div>
      <div className="marketing-footer__group">
        <strong>{copy.landing.footer.policyTitle}</strong>
        <nav aria-label={copy.landing.footer.navigationLabel}>
          <Link href="/privasi">{copy.landing.footer.privacy}</Link>
          <Link href="/ketentuan">{copy.landing.footer.terms}</Link>
          <Link href="/bantuan">{copy.landing.footer.help}</Link>
        </nav>
      </div>
      <p>{copy.landing.footer.disclaimer}</p>
    </footer>
  );
}
