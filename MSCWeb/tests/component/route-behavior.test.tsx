import { act, render, waitFor } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";

let pathname = "/admin/orang";
let search = "peran=coach";

vi.mock("next/navigation", () => ({
  usePathname: () => pathname,
  useSearchParams: () => new URLSearchParams(search),
}));

import { RouteBehavior } from "@/features/app-shell/components/route-behavior";
import { requestShellRouteFocus } from "@/shared/route-transition";

function ShellFixture() {
  return (
    <>
      <main id="app-main-content">
        <h1>Orang</h1>
      </main>
      <RouteBehavior />
    </>
  );
}

describe("RouteBehavior", () => {
  beforeEach(() => {
    pathname = "/admin/orang";
    search = "peran=coach";
    sessionStorage.clear();
  });

  it("memfokuskan H1 baru yang menggantikan H1 stale setelah stream RSC", async () => {
    const view = render(<ShellFixture />);
    pathname = "/admin/program";
    search = "";
    view.rerender(<ShellFixture />);

    const main = document.getElementById("app-main-content")!;
    await act(async () => {
      main.append(document.createElement("span"));
      await new Promise<void>((resolve) => requestAnimationFrame(() => resolve()));
      await new Promise<void>((resolve) => requestAnimationFrame(() => resolve()));
    });
    expect(document.querySelector("h1")).not.toHaveFocus();
    const newHeading = document.createElement("h1");
    newHeading.textContent = "Program";
    await act(async () => {
      main.replaceChildren(newHeading);
    });

    await waitFor(() => expect(newHeading).toHaveFocus());
    expect(newHeading).toHaveAttribute("tabindex", "-1");
  });

  it("memfokuskan penggantian H1 yang tiba setelah frame settle awal", async () => {
    const view = render(<ShellFixture />);
    pathname = "/admin/program";
    search = "";
    view.rerender(<ShellFixture />);

    const firstHeading = document.createElement("h1");
    firstHeading.textContent = "Program memuat";
    const main = document.getElementById("app-main-content")!;
    await act(async () => {
      main.replaceChildren(firstHeading);
      await new Promise<void>((resolve) => requestAnimationFrame(() => resolve()));
      await new Promise<void>((resolve) => requestAnimationFrame(() => resolve()));
    });
    await waitFor(() => expect(firstHeading).toHaveFocus());

    const streamedHeading = document.createElement("h1");
    streamedHeading.textContent = "Program";
    await act(async () => {
      main.replaceChildren(streamedHeading);
    });

    await waitFor(() => expect(streamedHeading).toHaveFocus());
    expect(streamedHeading).toHaveAttribute("tabindex", "-1");
  });

  it("mengikuti main baru ketika layout RSC mengganti seluruh shell", async () => {
    const initialMain = document.createElement("main");
    initialMain.id = "app-main-content";
    const initialHeading = document.createElement("h1");
    initialHeading.textContent = "Orang";
    initialMain.append(initialHeading);
    document.body.append(initialMain);
    const view = render(<RouteBehavior />);
    pathname = "/admin/program";
    search = "";
    view.rerender(<RouteBehavior />);

    const replacementMain = document.createElement("main");
    replacementMain.id = "app-main-content";
    const replacementHeading = document.createElement("h1");
    replacementHeading.textContent = "Program";
    replacementMain.append(replacementHeading);
    await act(async () => {
      document.getElementById("app-main-content")!.replaceWith(replacementMain);
    });

    await waitFor(() => expect(replacementHeading).toHaveFocus());
    expect(replacementHeading).toHaveAttribute("tabindex", "-1");
    replacementMain.remove();
  });

  it("berhenti pada deadline ketika route baru tidak menghasilkan H1", async () => {
    const view = render(<ShellFixture />);
    pathname = "/admin/program";
    search = "";
    view.rerender(<ShellFixture />);
    document.getElementById("app-main-content")!.replaceChildren();

    await act(async () => {
      await new Promise((resolve) => window.setTimeout(resolve, 3_100));
    });

    expect(document.activeElement).toBe(document.body);
    expect(sessionStorage.getItem("msc-shell-route")).toBe("/admin/program?");
  }, 4_000);

  it("tidak mencuri fokus yang berpindah sebelum H1 baru pertama muncul", async () => {
    const view = render(<ShellFixture />);
    const navigationTrigger = document.createElement("a");
    navigationTrigger.href = "/admin/program";
    document.body.append(navigationTrigger);
    navigationTrigger.focus();
    pathname = "/admin/program";
    search = "";
    view.rerender(<ShellFixture />);

    const persistentAction = document.createElement("button");
    persistentAction.textContent = "Buka bantuan";
    document.body.append(persistentAction);
    persistentAction.focus();
    const newHeading = document.createElement("h1");
    newHeading.textContent = "Program";
    await act(async () => {
      document.getElementById("app-main-content")!.replaceChildren(newHeading);
    });

    await waitFor(() => expect(persistentAction).toHaveFocus());
    expect(newHeading).not.toHaveAttribute("tabindex");
    navigationTrigger.remove();
    persistentAction.remove();
  });

  it("mengikuti query baru tetapi tidak mencuri fokus setelah pengguna berpindah", async () => {
    const view = render(<ShellFixture />);
    search = "peran=participant";
    view.rerender(<ShellFixture />);
    const queryHeading = document.createElement("h1");
    queryHeading.textContent = "Orang";
    await act(async () => {
      document.getElementById("app-main-content")!.replaceChildren(queryHeading);
    });
    await waitFor(() => expect(queryHeading).toHaveFocus());

    const action = document.createElement("button");
    action.textContent = "Aksi dialog";
    document.body.append(action);
    action.focus();
    expect(queryHeading).not.toHaveAttribute("tabindex");
    const replacement = document.createElement("h1");
    replacement.textContent = "Orang";
    await act(async () => {
      document.getElementById("app-main-content")!.replaceChildren(replacement);
    });

    await waitFor(() => expect(action).toHaveFocus());
    action.remove();
  });

  it("menjaga route sebelumnya ketika layout client diremount oleh stream", async () => {
    const view = render(<ShellFixture />);
    window.history.pushState(null, "", "/masuk?returnTo=%2Fadmin%2Forang");
    view.unmount();
    pathname = "/admin/program";
    search = "";
    const main = document.createElement("main");
    main.id = "app-main-content";
    const heading = document.createElement("h1");
    heading.textContent = "Program";
    main.append(heading);
    document.body.append(main);
    render(<RouteBehavior />);

    await waitFor(() => expect(heading).toHaveFocus());
    await waitFor(() => expect(sessionStorage.getItem("msc-shell-route")).toBe("/admin/program?"));
    main.remove();
  });

  it("memenuhi permintaan fokus eksplisit ketika marker sudah sama dengan route tujuan", async () => {
    sessionStorage.setItem("msc-shell-route", "/admin/orang?peran=coach");
    requestShellRouteFocus("/admin/orang?peran=coach");
    const view = render(<ShellFixture />);
    const heading = view.getByRole("heading", { level: 1, name: "Orang" });

    await waitFor(() => expect(heading).toHaveFocus());
    expect(sessionStorage.getItem("msc-shell-focus-request")).toBe("/admin/orang?peran=coach");
  });
});
