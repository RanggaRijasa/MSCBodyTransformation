import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, describe, expect, it, vi } from "vitest";

import ForgotPasswordPage from "@/app/(auth)/lupa-password/page";
import LoginPage from "@/app/(auth)/masuk/page";
import RegisterPage from "@/app/(auth)/daftar/page";
import {
  AuthCloseControl,
  shouldUseAuthHistoryBack,
} from "@/features/auth/components/auth-close-control";
import { AuthPage } from "@/features/auth/components/auth-page";
import { GoogleAuthButton } from "@/features/auth/components/google-auth-button";
import { OnboardingForm } from "@/features/auth/components/onboarding-form";

const { refresh, replace } = vi.hoisted(() => ({ refresh: vi.fn(), replace: vi.fn() }));
vi.mock("next/navigation", () => ({ useRouter: () => ({ refresh, replace }) }));

afterEach(() => {
  Object.defineProperty(window.navigator, "onLine", { configurable: true, value: true });
});

describe("auth pages", () => {
  it("menampilkan tepat satu aksi Google tanpa kredensial atau provider lain", async () => {
    render(<AuthPage description="Masuk aman." mode="login" returnTo="/profil" title="Masuk" />);
    const google = screen.getByRole("link", { name: "Lanjutkan dengan Google" });
    expect(google).toHaveAttribute("href", "/auth/google/start?mode=login&returnTo=%2Fprofil");
    expect(screen.getAllByRole("link", { name: /Google/ })).toHaveLength(1);
    expect(screen.queryByRole("textbox")).not.toBeInTheDocument();
    expect(
      screen.queryByText(/Apple|password belum diaktifkan|provider utama|atau/i),
    ).not.toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Daftar" })).toHaveAttribute(
      "href",
      "/daftar?returnTo=%2Fprofil",
    );
    const heading = screen.getByRole("heading", { name: "Masuk" });
    expect(heading).toHaveAttribute("tabindex", "-1");
    await waitFor(() => expect(heading).toHaveFocus());
  });

  it("menyanitasi return-to eksternal dan mengekspos query error sebagai alert", async () => {
    render(
      await LoginPage({
        searchParams: Promise.resolve({ error: "provider", returnTo: "https://evil.example" }),
      }),
    );
    expect(screen.getByRole("alert")).toHaveTextContent(/Google belum dapat dihubungi/);
    expect(screen.getByRole("link", { name: "Lanjutkan dengan Google" })).toHaveAttribute(
      "href",
      "/auth/google/start?mode=login&returnTo=%2Fhari-ini",
    );
  });

  it("menyampaikan status keluar dan mempertahankan return-to saat daftar", async () => {
    const { unmount } = render(
      await LoginPage({ searchParams: Promise.resolve({ status: "keluar" }) }),
    );
    expect(screen.getByRole("status")).toHaveTextContent("Anda sudah keluar dengan aman.");
    unmount();
    render(await RegisterPage({ searchParams: Promise.resolve({ returnTo: "/program/demo" }) }));
    expect(screen.getByRole("link", { name: "Daftar dengan Google" })).toHaveAttribute(
      "href",
      "/auth/google/start?mode=register&returnTo=%2Fprogram%2Fdemo",
    );
    expect(screen.getByRole("link", { name: "Masuk" })).toHaveAttribute(
      "href",
      "/masuk?returnTo=%2Fprogram%2Fdemo",
    );
  });

  it("menormalisasi status keluar dan error campuran sebagai status sukses", async () => {
    render(
      await LoginPage({
        searchParams: Promise.resolve({ error: "provider", status: "keluar" }),
      }),
    );
    expect(screen.getByRole("status")).toHaveTextContent("Anda sudah keluar dengan aman.");
    expect(screen.queryByRole("alert")).not.toBeInTheDocument();
    expect(screen.queryByText(/Google belum dapat dihubungi/)).not.toBeInTheDocument();
  });

  it("menggunakan riwayat hanya untuk referrer same-origin dan selalu memiliki fallback aman", () => {
    expect(shouldUseAuthHistoryBack("https://msc.test/program", "https://msc.test", 2)).toBe(true);
    expect(shouldUseAuthHistoryBack("https://evil.example", "https://msc.test", 2)).toBe(false);
    expect(shouldUseAuthHistoryBack("https://msc.test/program", "https://msc.test", 1)).toBe(false);
    render(<AuthCloseControl />);
    expect(screen.getByRole("link", { name: "Tutup" })).toHaveAttribute("href", "/hari-ini");
  });

  it("menahan aksi Google saat offline dan menampilkan state pending tanpa fetch", () => {
    Object.defineProperty(window.navigator, "onLine", { configurable: true, value: false });
    const { unmount } = render(<GoogleAuthButton mode="login" />);
    fireEvent.click(screen.getByRole("link", { name: "Lanjutkan dengan Google" }));
    expect(screen.getByRole("alert")).toHaveTextContent(/Tidak ada koneksi/);
    unmount();

    Object.defineProperty(window.navigator, "onLine", { configurable: true, value: true });
    render(<GoogleAuthButton mode="login" />);
    const action = screen.getByRole("link", { name: "Lanjutkan dengan Google" });
    action.addEventListener("click", (event) => event.preventDefault(), { once: true });
    fireEvent.click(action);
    expect(screen.getByRole("link", { name: "Membuka Google…" })).toHaveAttribute(
      "aria-busy",
      "true",
    );
  });

  it("menjaga pemulihan tanpa input dan copy enumeration-safe", () => {
    render(<ForgotPasswordPage />);
    expect(screen.getByRole("heading", { name: "Lupa password" })).toBeVisible();
    expect(screen.queryByRole("textbox")).not.toBeInTheDocument();
    expect(screen.getByText(/respons akan tetap sama untuk setiap alamat email/i)).toBeVisible();
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

  it("mempertahankan payload onboarding Coach, attestations, dan state sibuk", async () => {
    const user = userEvent.setup();
    const fetchMock = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({ destination: "/hari-ini" }), {
        headers: { "Content-Type": "application/json" },
        status: 200,
      }),
    );
    vi.stubGlobal("fetch", fetchMock);
    render(<OnboardingForm />);

    await user.type(screen.getByRole("textbox", { name: "Nama lengkap" }), "Rani Aman");
    await user.type(screen.getByRole("textbox", { name: "Nomor HP" }), "+628123456789");
    await user.selectOptions(screen.getByRole("combobox", { name: "Level member" }), "sc");
    await user.click(screen.getByRole("radio", { name: /Ajukan Coach/ }));
    await user.click(screen.getByRole("checkbox", { name: /HOM STS/ }));
    await user.click(screen.getByRole("checkbox", { name: /ICT/ }));
    await user.click(screen.getByRole("button", { name: "Simpan dan lanjutkan" }));

    await waitFor(() => expect(fetchMock).toHaveBeenCalledOnce());
    expect(fetchMock).toHaveBeenCalledWith(
      "/api/onboarding",
      expect.objectContaining({ method: "POST" }),
    );
    const request = fetchMock.mock.calls[0]![1] as RequestInit;
    expect(JSON.parse(String(request.body))).toEqual({
      accountPurpose: "coach_applicant",
      coachQrPayload: null,
      displayName: "Rani Aman",
      hasCompletedHomSts: true,
      hasCompletedIct: true,
      memberLevel: "sc",
      phoneNumber: "+628123456789",
    });
    await waitFor(() => expect(replace).toHaveBeenCalledWith("/hari-ini"));
  });
});
