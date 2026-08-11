import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";

import { FoundationStatus } from "@/features/foundation";

describe("FoundationStatus", () => {
  it("menampilkan interaksi dan copy Bahasa Indonesia", async () => {
    const user = userEvent.setup();
    render(<FoundationStatus />);

    const detailButton = screen.getByRole("button", { name: "Lihat detail" });
    expect(detailButton).toHaveAttribute("aria-expanded", "false");

    await user.click(detailButton);

    expect(screen.getByText(/TypeScript strict/)).toBeVisible();
    expect(screen.getByRole("button", { name: "Sembunyikan detail" })).toHaveAttribute(
      "aria-expanded",
      "true",
    );
  });
});
