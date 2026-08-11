import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "MSC Body Transformation",
    short_name: "MSC Body",
    description: "Program transformasi tubuh dengan aktivitas terarah dan dukungan Coach.",
    start_url: "/hari-ini",
    scope: "/",
    display: "standalone",
    background_color: "#f7f7f8",
    theme_color: "#d92d20",
    lang: "id-ID",
    dir: "ltr",
    id: "/hari-ini",
    icons: [
      {
        src: "/icons/app-icon-192.png",
        sizes: "192x192",
        type: "image/png",
        purpose: "any",
      },
      {
        src: "/icons/app-icon-512.png",
        sizes: "512x512",
        type: "image/png",
        purpose: "any",
      },
      {
        src: "/icons/app-icon-maskable-512.png",
        sizes: "512x512",
        type: "image/png",
        purpose: "maskable",
      },
    ],
    screenshots: [
      {
        src: "/images/pwa-participant-rc-v1.jpg",
        sizes: "358x1010",
        type: "image/jpeg",
        form_factor: "narrow",
        label: "Papan peringkat Peserta",
      },
      {
        src: "/images/pwa-coach-rc-v1.jpg",
        sizes: "1120x1497",
        type: "image/jpeg",
        form_factor: "wide",
        label: "Dashboard Coach",
      },
    ],
  };
}
