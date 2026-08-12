import type { LandingActor } from "@/features/landing/model/landing-actor";
import { resolveLandingDestination } from "@/features/landing/model/landing-actor";
import { LandingHero } from "@/features/landing/components/landing-hero";
import {
  AudienceSection,
  BenefitsSection,
  FaqSection,
  InstallCallout,
  StepsSection,
} from "@/features/landing/components/landing-sections";
import { PreviewSection } from "@/features/landing/components/landing-previews";
import { MarketingFooter } from "@/features/landing/components/marketing-footer";
import { MarketingHeader } from "@/features/landing/components/marketing-header";
import { MarketingRouteBehavior } from "@/features/landing/components/marketing-route-behavior";
import { PwaInstallProvider, StickyInstallBar } from "@/features/pwa-install";
import { copy } from "@/shared/i18n/id";

type LandingPageProperties = Readonly<{
  actor: LandingActor;
}>;

export function LandingPage({ actor }: LandingPageProperties) {
  return (
    <PwaInstallProvider actorDestination={resolveLandingDestination(actor)}>
      <div className="landing-page">
        <a className="skip-link" href="#landing-main">
          {copy.navigation.skipToContent}
        </a>
        <MarketingHeader />
        <main id="landing-main">
          <div className="landing-intro">
            <LandingHero />
            <BenefitsSection />
            <StepsSection />
          </div>
          <AudienceSection />
          <PreviewSection />
          <InstallCallout />
          <FaqSection />
        </main>
        <MarketingFooter />
        <StickyInstallBar />
        <MarketingRouteBehavior />
      </div>
    </PwaInstallProvider>
  );
}
