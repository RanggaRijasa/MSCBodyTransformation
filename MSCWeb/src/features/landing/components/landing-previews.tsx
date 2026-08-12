import Image from "next/image";

import { copy } from "@/shared/i18n/id";

const previews = [
  { image: "/images/landing-participant-v1.jpg", role: "participant" },
  { image: "/images/landing-coach-v1.jpg", role: "coach" },
  { image: "/images/landing-admin-v1.jpg", role: "admin" },
] as const;

export function PreviewSection() {
  return (
    <section className="landing-section landing-previews" aria-labelledby="previews-title">
      <p className="landing-eyebrow">{copy.landing.previews.eyebrow}</p>
      <h2 className="visually-hidden" id="previews-title">
        {copy.landing.previews.title}
      </h2>
      <div className="landing-previews__grid">
        {previews.map(({ image, role }) => (
          <figure className="landing-preview-card" data-role={role} key={role}>
            <div className="landing-preview-card__media">
              <Image
                alt={copy.landing.previews.imageAlt[role]}
                className="landing-preview-card__image"
                height={293}
                sizes="(max-width: 47.99rem) calc(100vw - 2rem), (max-width: 70rem) 33vw, 22rem"
                src={image}
                width={390}
              />
            </div>
            <figcaption>
              <strong>{copy.landing.previews.roles[role]}</strong>
              <span>{copy.landing.hero.previewLabel}</span>
            </figcaption>
          </figure>
        ))}
      </div>
    </section>
  );
}
