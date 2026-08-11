import { render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import { LandingPage } from "@/features/landing";
import { InstallCtaPresentation } from "@/features/pwa-install";

describe("landing dan install CTA", () => {
  it.each([
    ["prompt-ready", "Unduh MSC", "button"],
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
    await user.click(screen.getByRole("button", { name: "Unduh MSC" }));
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
    render(<LandingPage actor={{ kind: "authenticated", role: "coach" }} />);
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

  it("merender struktur redesign tanpa CTA visual yang tidak diminta", () => {
    render(<LandingPage actor={{ kind: "anonymous" }} />);

    expect(screen.getByRole("link", { name: "Lihat program" })).toHaveAttribute("href", "/program");
    const productPreview = screen.getByLabelText(/Pratinjau placeholder antarmuka PWA MSC/i);
    expect(productPreview).toBeVisible();
    expect(screen.queryByRole("heading", { name: "Program yang dapat dipilih" })).toBeNull();
    expect(screen.queryByText(/Selengkapnya|Lihat semua peringkat/i)).toBeNull();

    const stepsSection = screen
      .getByRole("heading", { name: "Empat langkah menuju program aktif" })
      .closest("section");
    expect(stepsSection).not.toBeNull();
    expect(within(stepsSection as HTMLElement).getAllByRole("listitem")).toHaveLength(4);

    const leaderboardSection = screen
      .getByRole("heading", { name: "Papan peringkat peserta" })
      .closest("section");
    expect(leaderboardSection).not.toBeNull();
    expect(within(leaderboardSection as HTMLElement).queryByRole("link")).toBeNull();
    expect(within(leaderboardSection as HTMLElement).queryByRole("button")).toBeNull();
  });
});
