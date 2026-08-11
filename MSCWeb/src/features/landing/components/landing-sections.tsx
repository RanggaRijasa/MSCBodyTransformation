import Image from "next/image";
import Link from "next/link";

import type { LandingPublicData } from "@/features/landing/model/landing-public-data";
import { InstallCta } from "@/features/pwa-install";
import { copy } from "@/shared/i18n/id";

export function BenefitsSection() {
  return (
    <section className="landing-section" aria-labelledby="benefits-title">
      <p className="landing-eyebrow">{copy.landing.benefits.eyebrow}</p>
      <h2 id="benefits-title">{copy.landing.benefits.title}</h2>
      <div className="landing-card-grid">
        {copy.landing.benefits.items.map((item, index) => (
          <article className="landing-card" key={item.title}>
            <span aria-hidden="true" className="landing-card__number">
              {index + 1}
            </span>
            <h3>{item.title}</h3>
            <p>{item.description}</p>
          </article>
        ))}
      </div>
    </section>
  );
}

export function StepsSection() {
  return (
    <section className="landing-section landing-section--tinted" id="cara-kerja" tabIndex={-1}>
      <div className="landing-section__heading">
        <p className="landing-eyebrow">{copy.landing.steps.eyebrow}</p>
        <h2>{copy.landing.steps.title}</h2>
      </div>
      <ol className="landing-steps">
        {copy.landing.steps.items.map((item) => (
          <li key={item.title}>
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

export function ProgramsSection({ publicData }: Readonly<{ publicData: LandingPublicData }>) {
  const message =
    publicData.availability === "unavailable"
      ? copy.landing.programs.unavailable
      : copy.landing.programs.empty;
  return (
    <section
      className="landing-section"
      id="program-publik"
      aria-labelledby="program-title"
      tabIndex={-1}
    >
      <div className="landing-section__heading">
        <h2 id="program-title">{copy.landing.programs.title}</h2>
        {publicData.programs.length === 0 ? <p>{message}</p> : null}
      </div>
      {publicData.programs.length > 0 ? (
        <div className="landing-card-grid">
          {publicData.programs.map((program) => (
            <article className="landing-card" key={program.id}>
              <p className="landing-card__meta">{program.scheduleLabel}</p>
              <h3>{program.title}</h3>
              <p>{program.summary}</p>
            </article>
          ))}
        </div>
      ) : null}
      <Link className="landing-text-link" href="/program">
        {copy.landing.programs.browse}
      </Link>
    </section>
  );
}

export function AudienceSection() {
  return (
    <section className="landing-section landing-audiences" aria-labelledby="audience-title">
      <h2 id="audience-title">{copy.landing.audiences.title}</h2>
      <div>
        <article>
          <h3>{copy.landing.audiences.participantTitle}</h3>
          <p>{copy.landing.audiences.participantSummary}</p>
        </article>
        <article id="untuk-coach" tabIndex={-1}>
          <h3>{copy.landing.audiences.coachTitle}</h3>
          <p>{copy.landing.audiences.coachSummary}</p>
        </article>
      </div>
      <figure className="landing-coach-preview">
        <Image
          alt={copy.landing.audiences.coachPreviewAlt}
          height={1497}
          loading="lazy"
          sizes="(max-width: 48rem) calc(100vw - 2rem), 70rem"
          src="/images/pwa-coach-rc-v1.jpg"
          width={1120}
        />
        <figcaption>{copy.landing.audiences.coachPreviewCaption}</figcaption>
      </figure>
    </section>
  );
}

export function InstallCallout() {
  return (
    <section className="landing-install-callout" aria-labelledby="install-callout-title">
      <div>
        <h2 id="install-callout-title">{copy.landing.install.calloutTitle}</h2>
        <p>{copy.landing.install.calloutSummary}</p>
        <small>{copy.landing.install.availability}</small>
      </div>
      <InstallCta />
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
