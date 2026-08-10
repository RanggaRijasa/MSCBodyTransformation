import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { useCallback, useState } from "react";
import { describe, expect, it, vi } from "vitest";

import { shellProgramFixture } from "@/features/app-shell/fixtures/shell-fixtures";
import { AppButton, Avatar, ModalDialog, ProgramActivityRenderer, TextField } from "@/shared/ui";

function DialogHarness() {
  const [isOpen, setOpen] = useState(false);
  const close = useCallback(() => setOpen(false), []);
  return (
    <>
      <AppButton onClick={() => setOpen(true)}>Buka filter</AppButton>
      <ModalDialog isOpen={isOpen} onClose={close} title="Atur filter">
        <TextField id="dialog-search" label="Cari program" />
      </ModalDialog>
    </>
  );
}

describe("shared UI", () => {
  it("menyampaikan loading dan disabled pada tombol", () => {
    render(<AppButton isLoading>Menyimpan</AppButton>);

    const button = screen.getByRole("button", { name: "Menyimpan" });
    expect(button).toBeDisabled();
    expect(button).toHaveAttribute("aria-busy", "true");
  });

  it("menghubungkan inline error ke field", () => {
    render(<TextField error="Nama perlu diisi." id="display-name" label="Nama tampilan" />);

    const field = screen.getByRole("textbox", { name: "Nama tampilan" });
    expect(field).toHaveAttribute("aria-invalid", "true");
    expect(field).toHaveAccessibleDescription("Nama perlu diisi.");
  });

  it("memakai ikon orang kosong tanpa inisial sebagai fallback avatar", () => {
    const { container } = render(<Avatar name="Foto profil Raka" />);

    expect(screen.getByRole("img", { name: "Foto profil Raka" })).toBeVisible();
    expect(container.querySelector("svg")).not.toBeNull();
    expect(screen.queryByText("FR")).not.toBeInTheDocument();
  });

  it("membuka dialog, memindahkan fokus, dan menutup melalui history", async () => {
    const user = userEvent.setup();
    const historyBack = vi.spyOn(window.history, "back").mockImplementation(() => undefined);
    render(<DialogHarness />);

    await user.click(screen.getByRole("button", { name: "Buka filter" }));

    const dialog = screen.getByRole("dialog", { name: "Atur filter" });
    expect(dialog).toBeVisible();
    const closeButton = await screen.findByRole("button", { name: "Tutup" });
    await waitFor(() => expect(closeButton).toHaveFocus());

    await user.click(screen.getByRole("button", { name: "Tutup" }));
    expect(historyBack).toHaveBeenCalledOnce();
    historyBack.mockRestore();
  });

  it("menjaga hierarchy renderer untuk Peserta dan Coach", () => {
    const { rerender } = render(
      <ProgramActivityRenderer audience="participant" model={shellProgramFixture} />,
    );

    expect(screen.getByRole("heading", { name: shellProgramFixture.title })).toBeVisible();
    expect(screen.getByText("Aktivitas program")).toBeVisible();
    expect(screen.queryByText(/berat badan/i)).not.toBeInTheDocument();

    rerender(<ProgramActivityRenderer audience="coach" model={shellProgramFixture} />);
    expect(screen.getByText("Pemantauan program")).toBeVisible();
    expect(screen.getByRole("heading", { name: shellProgramFixture.title })).toBeVisible();
  });
});
