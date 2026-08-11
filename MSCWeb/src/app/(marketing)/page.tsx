import { LandingPage } from "@/features/landing";
import {
  loadSafeLandingPublicData,
  loadTrustedLandingActor,
} from "@/features/landing/server/landing-boundaries";
import { absoluteSiteUrl } from "@/shared/config/site-url";

export const dynamic = "force-dynamic";

export default async function HomePage() {
  const [actor, publicData] = await Promise.all([
    loadTrustedLandingActor(),
    loadSafeLandingPublicData(),
  ]);
  const structuredData = {
    "@context": "https://schema.org",
    "@type": "WebSite",
    name: "MSC Body Transformation",
    url: absoluteSiteUrl("/"),
    inLanguage: "id-ID",
  };

  return (
    <>
      <LandingPage actor={actor} publicData={publicData} />
      <script
        dangerouslySetInnerHTML={{
          __html: JSON.stringify(structuredData).replaceAll("<", "\\u003c"),
        }}
        type="application/ld+json"
      />
    </>
  );
}
