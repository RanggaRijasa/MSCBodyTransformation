import Link from "next/link";

import { InstallCta } from "@/features/pwa-install";
import { copy } from "@/shared/i18n/id";

function ProductPreview() {
  const preview = copy.landing.hero.preview;

  return (
    <figure className="product-preview" aria-label={copy.landing.hero.previewAlt}>
      <div className="product-preview__orbit" aria-hidden="true" />
      <div className="product-preview__phone" aria-hidden="true">
        <span className="product-preview__speaker" />
        <p>{preview.greeting}</p>
        <small>{preview.program}</small>
        <div className="product-preview__progress">
          <strong>{preview.progress}</strong>
          <span>{preview.progressLabel}</span>
        </div>
        <div className="product-preview__tasks">
          {preview.tasks.map((task) => (
            <span key={task}>
              <i />
              {task}
              <b>{preview.complete}</b>
            </span>
          ))}
        </div>
      </div>
      <div className="product-preview__rank" aria-hidden="true">
        <span>{preview.rankLabel}</span>
        <strong>{preview.rankValue}</strong>
        <small>{preview.rankDetail}</small>
      </div>
      <div className="product-preview__score" aria-hidden="true">
        <span>{preview.scoreLabel}</span>
        <strong>{preview.scoreValue}</strong>
        <small>{preview.scoreDetail}</small>
      </div>
      <figcaption>{copy.landing.hero.previewLabel}</figcaption>
    </figure>
  );
}

export function LandingHero() {
  return (
    <section className="landing-hero" aria-labelledby="landing-title">
      <div className="landing-hero__content">
        <p className="landing-eyebrow">{copy.landing.hero.eyebrow}</p>
        <h1 id="landing-title">
          {copy.landing.hero.titleLead} <span>{copy.landing.hero.titleAccent}</span>
        </h1>
        <p className="landing-hero__summary">{copy.landing.hero.summary}</p>
        <div className="landing-hero__actions" id="hero-install-anchor">
          <InstallCta />
          <Link className="landing-secondary-action" href="/program">
            {copy.landing.hero.viewPrograms}
          </Link>
        </div>
      </div>
      <ProductPreview />
    </section>
  );
}
