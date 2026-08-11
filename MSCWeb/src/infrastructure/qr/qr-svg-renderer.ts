import { renderSVG } from "uqr";

export function renderQrSvg(payload: string): string {
  return renderSVG(payload, { border: 4, ecc: "M" });
}
