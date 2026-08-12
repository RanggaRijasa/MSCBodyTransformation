import { act, render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it } from "vitest";

import { useSearchParams } from "../../development/shims/next-navigation";

function SearchFixture() {
  return <output>{useSearchParams().get("peran") ?? "semua"}</output>;
}

describe("shim next/navigation untuk gallery", () => {
  afterEach(() => history.replaceState({}, "", "/"));

  it("membaca query deterministik dan merender ulang pada popstate", () => {
    history.replaceState({}, "", "/?peran=coach");
    render(<SearchFixture />);
    expect(screen.getByText("coach")).toBeVisible();

    act(() => {
      history.pushState({}, "", "/?peran=participant");
      window.dispatchEvent(new PopStateEvent("popstate"));
    });
    expect(screen.getByText("participant")).toBeVisible();
  });
});
