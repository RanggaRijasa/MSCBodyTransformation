import { ImageResponse } from "next/og";

import { copy } from "@/shared/i18n/id";

export const alt = copy.landing.metadata.socialAlt;
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default function OpenGraphImage() {
  return new ImageResponse(
    <div
      style={{
        alignItems: "stretch",
        background: "#111111",
        color: "#ffffff",
        display: "flex",
        height: "100%",
        padding: "72px",
        position: "relative",
        width: "100%",
      }}
    >
      <div
        style={{
          background: "#d92d20",
          borderRadius: "999px",
          height: "520px",
          position: "absolute",
          right: "-110px",
          top: "-130px",
          width: "520px",
        }}
      />
      <div style={{ display: "flex", flexDirection: "column", justifyContent: "space-between" }}>
        <div style={{ alignItems: "center", display: "flex", fontSize: "30px", fontWeight: 800 }}>
          <div
            style={{
              alignItems: "center",
              background: "#d92d20",
              borderRadius: "18px",
              display: "flex",
              height: "72px",
              justifyContent: "center",
              marginRight: "24px",
              width: "72px",
            }}
          >
            MSC
          </div>
          Body Transformation
        </div>
        <div style={{ display: "flex", flexDirection: "column", maxWidth: "900px" }}>
          <div style={{ color: "#f5c542", fontSize: "28px", fontWeight: 800 }}>
            {copy.landing.hero.eyebrow}
          </div>
          <div
            style={{ fontSize: "68px", fontWeight: 900, letterSpacing: "-3px", lineHeight: 1.02 }}
          >
            {copy.landing.hero.title}
          </div>
        </div>
      </div>
    </div>,
    size,
  );
}
