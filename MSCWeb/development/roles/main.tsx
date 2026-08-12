import { StrictMode } from "react";
import { createRoot } from "react-dom/client";

import "@/app/globals.css";
import "../gallery-styles.css";
import "@/development/role-simulator.css";
import { RoleSimulator } from "@/development/role-simulator";

const rootElement = document.querySelector<HTMLElement>("#root");

if (!rootElement) {
  throw new Error("Simulator role development tidak tersedia.");
}

createRoot(rootElement).render(
  <StrictMode>
    <RoleSimulator />
  </StrictMode>,
);
