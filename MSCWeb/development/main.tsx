import { StrictMode } from "react";
import { createRoot } from "react-dom/client";

import "@/app/globals.css";
import "./gallery-styles.css";
import {
  DevelopmentGalleryApp,
  developmentViewFromSearch,
  developmentViewLabels,
} from "@/development/development-gallery-app";

const rootElement = document.querySelector<HTMLElement>("#root");

if (!rootElement) {
  throw new Error("Root galeri pengembangan tidak tersedia.");
}

const selectedView = developmentViewFromSearch(window.location.search);
document.title = `${developmentViewLabels[selectedView]} · MSC development`;

createRoot(rootElement).render(
  <StrictMode>
    <DevelopmentGalleryApp selectedView={selectedView} />
  </StrictMode>,
);
