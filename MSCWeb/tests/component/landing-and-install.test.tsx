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
    expect(
      within(screen.getByRole("banner")).queryByText(
        /Unduh MSC|Cara memasang(?: di iPhone)?|Gunakan di browser|Buka aplikasi/,
      ),
    ).toBeNull();
    const productPreview = screen.getByRole("figure", { name: "Pratinjau aplikasi" });
    expect(productPreview).toBeVisible();
    expect(screen.queryByRole("heading", { name: "Program yang dapat dipilih" })).toBeNull();
    expect(screen.queryByText(/Selengkapnya|Lihat semua peringkat/i)).toBeNull();

    const stepsSection = screen
      .getByRole("heading", { name: "Empat langkah menuju program aktif" })
      .closest("section");
    expect(stepsSection).not.toBeNull();
    expect(within(stepsSection as HTMLElement).getAllByRole("listitem")).toHaveLength(4);

    const previewSection = screen
      .getByRole("heading", { name: "Pratinjau aplikasi MSC untuk Peserta, Coach, dan Admin" })
      .closest("section");
    expect(previewSection).not.toBeNull();
    expect(within(previewSection as HTMLElement).getAllByRole("figure")).toHaveLength(3);
    expect(within(previewSection as HTMLElement).getByText("Peserta")).toBeVisible();
    expect(within(previewSection as HTMLElement).getByText("Coach")).toBeVisible();
    expect(within(previewSection as HTMLElement).getByText("Admin")).toBeVisible();
    expect(
      within(previewSection as HTMLElement).getByRole("img", {
        name: "Pratinjau PWA Peserta dengan program aktif dan fokus hari ini",
      }),
    ).toHaveAttribute("src", expect.stringContaining("landing-participant-v1.jpg"));
    expect(within(previewSection as HTMLElement).getAllByRole("img")).toHaveLength(3);
    expect(within(previewSection as HTMLElement).queryByRole("link")).toBeNull();
    expect(within(previewSection as HTMLElement).queryByRole("button")).toBeNull();
  });
});
