import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import { LandingPage } from "@/features/landing";
import { InstallCtaPresentation } from "@/features/pwa-install";

const emptyPublicData = { availability: "available", coaches: [], programs: [] } as const;

describe("landing dan install CTA", () => {
  it.each([
    ["prompt-ready", "Pasang aplikasi", "button"],
    ["ios-guidance", "Cara memasang di iPhone", "button"],
    ["manual-guidance", "Cara memasang", "button"],
    ["standalone", "Buka aplikasi", "link"],
    ["unsupported", "Gunakan di browser", "link"],
    ["not-ready", "Gunakan di browser", "link"],
  ] as const)("merender state %s secara actionable", (kind, label, role) => {
    render(
      <InstallCtaPresentation
        actorDestination="/hari-ini"
        kind={kind}
        onGuidance={() => undefined}
        onPrompt={() => undefined}
      />,
    );
    expect(screen.getByRole(role, { name: label })).toBeVisible();
  });

  it("memanggil prompt dan guidance hanya lewat aksi pengguna", async () => {
    const user = userEvent.setup();
    const onPrompt = vi.fn();
    const onGuidance = vi.fn();
    const { rerender } = render(
      <InstallCtaPresentation
        actorDestination="/program"
        kind="prompt-ready"
        onGuidance={onGuidance}
        onPrompt={onPrompt}
      />,
    );
    await user.click(screen.getByRole("button", { name: "Pasang aplikasi" }));
    expect(onPrompt).toHaveBeenCalledOnce();

    rerender(
      <InstallCtaPresentation
        actorDestination="/program"
        kind="ios-guidance"
        onGuidance={onGuidance}
        onPrompt={onPrompt}
      />,
    );
    await user.click(screen.getByRole("button", { name: "Cara memasang di iPhone" }));
    expect(onGuidance).toHaveBeenCalledOnce();
  });

  it("menjaga hero, FAQ, dan CTA role dari actor server", () => {
    render(
      <LandingPage actor={{ kind: "authenticated", role: "coach" }} publicData={emptyPublicData} />,
    );
    expect(
      screen.getByRole("heading", { name: "Transformasi lebih terarah, bersama Coach." }),
    ).toBeVisible();
    expect(screen.getByText("Apa itu MSC Body Transformation?")).toBeVisible();
    expect(screen.getAllByRole("link", { name: "Gunakan di browser" })[0]).toHaveAttribute(
      "href",
      "/coach-area",
    );
    expect(screen.queryByText(/testimoni|rating|peserta aktif/i)).not.toBeInTheDocument();
  });
});
