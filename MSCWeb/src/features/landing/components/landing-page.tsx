import type { LandingActor } from "@/features/landing/model/landing-actor";
import { resolveLandingDestination } from "@/features/landing/model/landing-actor";
import type { LandingPublicData } from "@/features/landing/model/landing-public-data";
import { LandingHero } from "@/features/landing/components/landing-hero";
import {
  AudienceSection,
  BenefitsSection,
  FaqSection,
  InstallCallout,
  ProgramsSection,
  StepsSection,
} from "@/features/landing/components/landing-sections";
import { MarketingFooter } from "@/features/landing/components/marketing-footer";
import { MarketingHeader } from "@/features/landing/components/marketing-header";
import { MarketingRouteBehavior } from "@/features/landing/components/marketing-route-behavior";
import { PwaInstallProvider, StickyInstallBar } from "@/features/pwa-install";
import { copy } from "@/shared/i18n/id";

type LandingPageProperties = Readonly<{
  actor: LandingActor;
  publicData: LandingPublicData;
}>;

export function LandingPage({ actor, publicData }: LandingPageProperties) {
  return (
    <PwaInstallProvider actorDestination={resolveLandingDestination(actor)}>
      <a className="skip-link" href="#landing-main">
        {copy.navigation.skipToContent}
      </a>
      <MarketingHeader />
      <main id="landing-main">
        <LandingHero />
        <BenefitsSection />
        <StepsSection />
        <ProgramsSection publicData={publicData} />
        <AudienceSection />
        <InstallCallout />
        <FaqSection />
      </main>
      <MarketingFooter />
      <StickyInstallBar />
      <MarketingRouteBehavior />
    </PwaInstallProvider>
  );
}
