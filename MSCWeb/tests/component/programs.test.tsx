import { act, render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import type { PublicProgram } from "@/domain/programs/program";
import { ProgramCatalog } from "@/features/programs/components/program-catalog";
import { ProgramDetail } from "@/features/programs/components/program-detail";
import { ProgramEnrollmentFlow } from "@/features/programs/components/program-enrollment-flow";
import type { QrDecoder } from "@/infrastructure/qr/browser-qr-decoder";

const replace = vi.fn();
const refresh = vi.fn();
vi.mock("next/navigation", () => ({ useRouter: () => ({ refresh, replace }) }));

function program(overrides: Partial<PublicProgram> = {}): PublicProgram {
  return {
    category: "Transformasi",
    coverAlternativeText: null,
    coverImageUrl: null,
    days: [],
    desiredPrice: null,
    endsOn: "2026-09-30",
    futureStepPolicy: "locked",
    id: "00000000-0000-4000-8000-000000000001",
    participantLimit: 50,
    pastStepPolicy: "available",
    pointsPerActivity: 10,
    pointsPerWeightKilogram: "100.00",
    pricingMode: "free",
    quizPassingPercentage: 80,
    registrationClosesAt: "2026-08-20T00:00:00Z",
    startsOn: "2026-09-01",
    status: "scheduled",
    summary: "Program kebugaran yang terarah.",
    timezone: "Asia/Makassar",
    title: "MSC September",
    wellnessDisclaimer: "Bukan layanan diagnosis medis.",
    ...overrides,
  };
}

beforeEach(() => {
  replace.mockReset();
  refresh.mockReset();
  window.localStorage.clear();
});

afterEach(() => vi.unstubAllGlobals());

describe("program", () => {
  it("katalog Guest hanya menampilkan Tersedia dan Riwayat tanpa projection pribadi", () => {
    render(
      <ProgramCatalog
        isAuthenticatedParticipant={false}
        now={new Date("2026-08-10T00:00:00Z")}
        sections={{ available: [program()], followed: [], history: [] }}
      />,
    );
    expect(screen.queryByRole("heading", { name: "Diikuti" })).not.toBeInTheDocument();
    expect(screen.getByRole("heading", { name: "Tersedia" })).toBeVisible();
    expect(screen.getByText("MSC September")).toBeVisible();
    expect(screen.queryByText(/enrollment/i)).not.toBeInTheDocument();
  });

  it("detail program closed tetap terlihat tetapi tidak membuka pendaftaran", () => {
    render(
      <ProgramDetail
        actor="participant"
        mode="offer"
        now={new Date("2026-08-21T00:00:00Z")}
        program={program()}
      />,
    );
    expect(screen.getByRole("heading", { name: "MSC September" })).toBeVisible();
    expect(screen.getByText("Pendaftaran program ini sudah ditutup.")).toBeVisible();
    expect(screen.queryByRole("link", { name: /Daftar/ })).not.toBeInTheDocument();
  });

  it("program yang diikuti diarahkan server model ke aktivitas", () => {
    render(
      <ProgramDetail
        actor="participant"
        mode="activity"
        now={new Date("2026-08-10T00:00:00Z")}
        program={program()}
      />,
    );
    expect(screen.getByRole("link", { name: "Buka aktivitas program" })).toHaveAttribute(
      "href",
      "/hari-ini?program=00000000-0000-4000-8000-000000000001",
    );
  });

  it("memvalidasi QR di server lalu mendaftarkan program gratis tanpa menampilkan token", async () => {
    const user = userEvent.setup();
    let emitScan: ((value: string) => void) | undefined;
    const decoder: QrDecoder = {
      createSession: async (_video, callback) => {
        emitScan = callback;
        return { destroy: vi.fn(), start: async () => undefined, stop: vi.fn() };
      },
      hasCamera: async () => true,
      scanImage: async () => "",
    };
    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce(
        new Response(
          JSON.stringify({ city: "Denpasar", displayName: "Coach Aman", photoUrl: null }),
          { status: 200 },
        ),
      )
      .mockResolvedValueOnce(
        new Response(
          JSON.stringify({
            enrollmentId: "00000000-0000-4000-8000-000000000099",
            programId: "00000000-0000-4000-8000-000000000001",
          }),
          { status: 200 },
        ),
      );
    vi.stubGlobal("fetch", fetchMock);
    render(
      <ProgramEnrollmentFlow
        availability="available"
        pricingMode="free"
        programId="00000000-0000-4000-8000-000000000001"
        programTitle="MSC September"
        qrDecoder={decoder}
      />,
    );

    await user.click(screen.getByRole("button", { name: "Pindai QR Coach" }));
    await waitFor(() => expect(emitScan).toBeDefined());
    act(() => emitScan?.(`${window.location.origin}/gabung/coach/coach_test_12345678`));
    expect(await screen.findByRole("heading", { name: "Coach Aman" })).toBeVisible();
    expect(screen.queryByText("coach_test_12345678")).not.toBeInTheDocument();
    await user.click(screen.getByRole("button", { name: "Konfirmasi pendaftaran" }));

    await waitFor(() =>
      expect(replace).toHaveBeenCalledWith("/program/00000000-0000-4000-8000-000000000001"),
    );
    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(window.localStorage.length).toBe(0);
  });

  it("capacity full tidak menyediakan scanner", () => {
    render(
      <ProgramEnrollmentFlow
        availability="program_full"
        pricingMode="free"
        programId="00000000-0000-4000-8000-000000000001"
        programTitle="MSC September"
      />,
    );
    expect(screen.getByText("Kapasitas program penuh")).toBeVisible();
    expect(screen.queryByRole("button", { name: "Pindai QR Coach" })).not.toBeInTheDocument();
  });
});
