import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import { AuthPage } from "@/features/auth/components/auth-page";
import { OnboardingForm } from "@/features/auth/components/onboarding-form";

vi.mock("next/navigation", () => ({ useRouter: () => ({ refresh: vi.fn(), replace: vi.fn() }) }));

describe("auth pages", () => {
  it("menampilkan Google sebagai provider utama tanpa Apple", () => {
    render(<AuthPage description="Masuk aman." mode="login" title="Masuk" />);
    const google = screen.getByRole("link", { name: "Lanjutkan dengan Google" });
    expect(google).toHaveAttribute(
      "href",
      expect.stringContaining("/auth/google/start?mode=login"),
    );
    expect(screen.queryByText(/Apple/i)).not.toBeInTheDocument();
    expect(screen.getByText(/email dan pemulihan password belum diaktifkan/i)).toBeVisible();
  });

  it("mencegah Participant mengetik kode Coach dan menyediakan pemindai", () => {
    render(<OnboardingForm />);
    expect(screen.getByRole("button", { name: "Pindai QR Coach" })).toBeEnabled();
    expect(screen.queryByRole("textbox", { name: /kode coach/i })).not.toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Simpan dan lanjutkan" })).toBeDisabled();
  });

  it("menahan pengajuan Coach level Member", () => {
    render(<OnboardingForm />);
    screen.getByRole("radio", { name: /Ajukan Coach/ }).click();
    expect(screen.getByText(/Level Member belum dapat mengajukan Coach/)).toBeVisible();
    expect(screen.getByRole("button", { name: "Simpan dan lanjutkan" })).toBeDisabled();
  });
});
