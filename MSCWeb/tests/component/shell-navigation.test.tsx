import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import { ShellNavigation, isNavigationItemActive } from "@/features/app-shell";
import {
  adminMobileNavigation,
  adminNavigation,
  participantNavigation,
} from "@/features/app-shell/model/navigation-items";

vi.mock("next/navigation", () => ({
  usePathname: () => "/admin/program",
}));

describe("ShellNavigation", () => {
  it("menandai tepat satu destination aktif dengan aria-current", () => {
    render(<ShellNavigation items={adminNavigation} kind="admin" label="Navigasi Admin" />);

    expect(screen.getByRole("navigation", { name: "Navigasi Admin" })).toBeVisible();
    expect(screen.getByRole("link", { name: "Program" })).toHaveAttribute("aria-current", "page");
    expect(screen.getByRole("link", { name: "Dashboard" })).not.toHaveAttribute("aria-current");
  });

  it("membedakan root exact dari child route", () => {
    const dashboard = adminNavigation[0];
    expect(dashboard).toBeDefined();
    if (!dashboard) return;

    expect(isNavigationItemActive("/admin", dashboard)).toBe(true);
    expect(isNavigationItemActive("/admin/program", dashboard)).toBe(false);
  });

  it("menjaga lima destination mobile dan enam destination desktop Admin", () => {
    expect(adminMobileNavigation.map(({ href }) => href)).toEqual([
      "/admin",
      "/admin/program",
      "/admin/orang",
      "/admin/konten",
      "/admin/pengaturan",
    ]);
    expect(adminNavigation.map(({ href }) => href)).toEqual([
      "/admin",
      "/admin/pembayaran",
      "/admin/program",
      "/admin/orang",
      "/admin/konten",
      "/admin/pengaturan",
    ]);
  });

  it("memakai Beranda sebagai label tab utama Peserta tanpa mengubah route", () => {
    expect(participantNavigation[0]).toMatchObject({ href: "/hari-ini", label: "Beranda" });
  });
});
