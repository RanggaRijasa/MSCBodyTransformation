import { InstallCta } from "@/features/pwa-install";
import { copy } from "@/shared/i18n/id";

function ProductPreviewPlaceholder() {
  return (
    <figure className="product-preview" aria-label={copy.landing.hero.previewLabel}>
      <figcaption>{copy.landing.hero.previewLabel}</figcaption>
      <div className="product-preview__screen">
        <div aria-hidden="true" className="product-preview__status" />
        <strong>{copy.landing.hero.previewTitle}</strong>
        <p>{copy.landing.hero.previewSummary}</p>
        <div aria-hidden="true" className="product-preview__progress">
          <span />
        </div>
        <div aria-hidden="true" className="product-preview__rows">
          <span />
          <span />
          <span />
        </div>
      </div>
    </figure>
  );
}

export function LandingHero() {
  return (
    <section className="landing-hero" aria-labelledby="landing-title">
      <div className="landing-hero__content">
        <p className="landing-eyebrow">{copy.landing.hero.eyebrow}</p>
        <h1 id="landing-title">{copy.landing.hero.title}</h1>
        <p className="landing-hero__summary">{copy.landing.hero.summary}</p>
        <div className="landing-hero__actions" id="hero-install-anchor">
          <InstallCta />
          <a className="landing-secondary-action" href="#program-publik">
            {copy.landing.hero.viewPrograms}
          </a>
        </div>
        <p className="landing-hero__trust">{copy.landing.hero.trust}</p>
      </div>
      <ProductPreviewPlaceholder />
    </section>
  );
}
