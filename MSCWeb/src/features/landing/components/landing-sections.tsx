import Image from "next/image";

import { InstallCta } from "@/features/pwa-install";
import { AppIcon, type AppIconName } from "@/shared/ui";
import { copy } from "@/shared/i18n/id";

const benefitIcons: readonly AppIconName[] = ["program", "coach", "ranking"];
const stepIcons: readonly AppIconName[] = ["dashboard", "coach", "payment", "check"];
const participantIcons: readonly AppIconName[] = ["home", "program", "ranking", "info"];
const coachIcons: readonly AppIconName[] = ["people", "check", "ranking", "dashboard"];

export function BenefitsSection() {
  return (
    <section className="landing-section landing-benefits" aria-labelledby="benefits-title">
      <p className="landing-eyebrow">{copy.landing.benefits.eyebrow}</p>
      <h2 id="benefits-title">
        {copy.landing.benefits.titleLead} <span>{copy.landing.benefits.titleAccent}</span>
      </h2>
      <div className="landing-benefits__items">
        {copy.landing.benefits.items.map((item, index) => (
          <article key={item.title}>
            <AppIcon name={benefitIcons[index] ?? "program"} variant="outline" />
            <div>
              <h3>{item.title}</h3>
              <p>{item.description}</p>
            </div>
          </article>
        ))}
      </div>
    </section>
  );
}

export function StepsSection() {
  return (
    <section
      className="landing-section landing-steps-section"
      id="cara-kerja"
      aria-labelledby="steps-title"
      tabIndex={-1}
    >
      <div className="landing-section__heading">
        <p className="landing-eyebrow">{copy.landing.steps.eyebrow}</p>
        <h2 id="steps-title">{copy.landing.steps.title}</h2>
      </div>
      <ol className="landing-steps">
        {copy.landing.steps.items.map((item, index) => (
          <li key={item.title}>
            <span className="landing-step__number">{index + 1}</span>
            <span className="landing-step__icon" aria-hidden="true">
              <AppIcon name={stepIcons[index] ?? "program"} variant="outline" />
            </span>
            <div>
              <h3>{item.title}</h3>
              <p>{item.description}</p>
            </div>
          </li>
        ))}
      </ol>
    </section>
  );
}

function CapabilityList({
  icons,
  items,
}: Readonly<{ icons: readonly AppIconName[]; items: readonly string[] }>) {
  return (
    <ul>
      {items.map((item, index) => (
        <li key={item}>
          <AppIcon name={icons[index] ?? "info"} variant="outline" />
          <span>{item}</span>
        </li>
      ))}
    </ul>
  );
}

export function AudienceSection() {
  return (
    <section className="landing-section landing-audiences" aria-labelledby="audience-title">
      <h2 className="visually-hidden" id="audience-title">
        {copy.landing.audiences.title}
      </h2>
      <div className="landing-audiences__panels">
        <article>
          <p className="landing-eyebrow">{copy.landing.audiences.participantEyebrow}</p>
          <h3>{copy.landing.audiences.participantTitle}</h3>
          <p>{copy.landing.audiences.participantSummary}</p>
          <CapabilityList
            icons={participantIcons}
            items={copy.landing.audiences.participantCapabilities}
          />
        </article>
        <div className="landing-audiences__mark" aria-hidden="true">
          <Image alt="" height={84} loading="eager" src="/icons/app-icon-192.png" width={84} />
        </div>
        <article id="untuk-coach" tabIndex={-1}>
          <p className="landing-eyebrow">{copy.landing.audiences.coachEyebrow}</p>
          <h3>{copy.landing.audiences.coachTitle}</h3>
          <p>{copy.landing.audiences.coachSummary}</p>
          <CapabilityList icons={coachIcons} items={copy.landing.audiences.coachCapabilities} />
        </article>
      </div>
    </section>
  );
}

export function InstallCallout() {
  return (
    <section className="landing-install-callout" aria-labelledby="install-callout-title">
      <div className="landing-install-callout__copy">
        <p className="landing-eyebrow">{copy.landing.install.eyebrow}</p>
        <h2 id="install-callout-title">{copy.landing.install.calloutTitle}</h2>
        <p>{copy.landing.install.calloutSummary}</p>
      </div>
      <span aria-hidden="true" className="landing-install-callout__route">
        <svg viewBox="0 0 160 72">
          <circle cx="12" cy="19" r="6" />
          <path d="M18 19C38 5 59 9 59 28c0 21 16 28 43 24h40" />
          <path d="m132 44 12 8-12 9" />
        </svg>
      </span>
      <div className="landing-install-callout__action">
        <InstallCta />
        <div>
          <Image alt="" height={80} loading="eager" src="/icons/app-icon-192.png" width={80} />
          <strong>MSC</strong>
          <span>Body Transformation</span>
        </div>
      </div>
    </section>
  );
}

export function FaqSection() {
  return (
    <section className="landing-section landing-faq" aria-labelledby="faq-title">
      <p className="landing-eyebrow">{copy.landing.faq.eyebrow}</p>
      <h2 id="faq-title">{copy.landing.faq.title}</h2>
      <div>
        {copy.landing.faq.items.map((item) => (
          <details key={item.question}>
            <summary>{item.question}</summary>
            <p>{item.answer}</p>
          </details>
        ))}
      </div>
    </section>
  );
}
