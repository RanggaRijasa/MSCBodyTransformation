import Image from "next/image";

import { InstallCta } from "@/features/pwa-install";
import { copy } from "@/shared/i18n/id";

function ProductPreview() {
  return (
    <figure className="product-preview">
      <Image
        alt={copy.landing.hero.previewAlt}
        className="product-preview__image"
        height={1010}
        priority
        sizes="(max-width: 48rem) 88vw, 27rem"
        src="/images/pwa-participant-rc-v1.jpg"
        width={358}
      />
      <figcaption>{copy.landing.hero.previewLabel}</figcaption>
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
      <ProductPreview />
    </section>
  );
}
