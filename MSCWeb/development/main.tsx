import { StrictMode } from "react";
import { createRoot } from "react-dom/client";

import "@/app/globals.css";
import { StateGallery } from "@/development/state-gallery";

const rootElement = document.querySelector<HTMLElement>("#root");

if (!rootElement) {
  throw new Error("Root galeri pengembangan tidak tersedia.");
}

createRoot(rootElement).render(
  <StrictMode>
    <StateGallery />
  </StrictMode>,
);
