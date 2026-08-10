import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import type {
  CoachContext,
  CoachReviewItem,
  CoachRosterEntry,
} from "@/domain/coach/coach-experience";
import { CoachAccessState, CoachDashboard, CoachReviewQueue, CoachRoster } from "@/features/coach";

const context: CoachContext = {
  accessEndsAt: "2026-11-10T00:00:00Z",
  accessStartsAt: "2026-08-10T00:00:00Z",
  accessState: "active",
  applicationId: "application",
  applicationStatus: "active",
  avatarUrl: null,
  biography: "Mendampingi konsistensi.",
  city: "Denpasar",
  displayName: "Coach Uji",
  email: "coach@example.invalid",
  isPublic: true,
  paymentOrderId: null,
  paymentStatus: "verified",
  phoneNumber: "+628123456789",
};

const roster: CoachRosterEntry[] = [
  {
    activeEnrollmentCount: 0,
    attentionState: "not_enrolled",
    avatarUrl: null,
    city: "Denpasar",
    displayName: "Peserta Satu",
    lastActivityAt: null,
    memberLevel: "member",
    participantId: "00000000-0000-4000-8000-000000000001",
    pendingReviewCount: 0,
    points: 0,
    programId: null,
    programTitle: null,
    progressPercentage: 0,
    publicProfileId: "00000000-0000-4000-8000-000000000002",
  },
];

const review: CoachReviewItem = {
  answers: [],
  contentKind: "form",
  participantId: roster[0]!.participantId,
  participantName: roster[0]!.displayName,
  programId: "program-a",
  programTitle: "Program A",
  stepId: "step-a",
  stepTitle: "Refleksi",
  submissionId: "00000000-0000-4000-8000-000000000003",
  submittedAt: "2026-08-10T02:00:00Z",
};

describe("pengalaman Coach", () => {
  it("dashboard tidak membuat quick action Peserta saya ganda", () => {
    render(
      <CoachDashboard
        activity={[]}
        context={context}
        leaderboard={[]}
        programs={[]}
        reviews={[]}
        roster={roster}
      />,
    );
    expect(screen.getAllByRole("link", { name: /Peserta saya/ })).toHaveLength(1);
    expect(screen.getByRole("link", { name: "Ikuti program sebagai Peserta" })).toHaveAttribute(
      "href",
      "/hari-ini",
    );
  });

  it("roster membedakan Belum terdaftar tanpa membocorkan berat atau bukti", () => {
    render(<CoachRoster context={context} entries={roster} filters={{}} programs={[]} />);
    expect(screen.getAllByText("Belum terdaftar").at(-1)).toBeVisible();
    expect(screen.queryByText(/kg/i)).not.toBeInTheDocument();
    expect(screen.queryByRole("img", { name: /bukti/i })).not.toBeInTheDocument();
  });

  it("akses berakhir mempertahankan jalan kembali ke mode Peserta", () => {
    render(<CoachAccessState context={{ ...context, accessState: "expired" }} />);
    expect(screen.getByRole("heading", { name: "Akses Coach berakhir" })).toBeVisible();
    expect(screen.getByRole("link", { name: "Lanjut sebagai Peserta" })).toHaveAttribute(
      "href",
      "/hari-ini",
    );
  });

  it("mewajibkan alasan penolakan sebelum mengirim keputusan", async () => {
    const user = userEvent.setup();
    const request = vi.fn();
    vi.stubGlobal("fetch", request);
    render(<CoachReviewQueue context={context} filters={{}} items={[review]} programs={[]} />);
    await user.click(screen.getByRole("button", { name: "Tolak" }));
    expect(screen.getByRole("status")).toHaveTextContent("Tulis alasan penolakan");
    expect(request).not.toHaveBeenCalled();
  });

  it("menggunakan satu idempotency key untuk keputusan yang berhasil", async () => {
    const user = userEvent.setup();
    const request = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({ pointsAfter: 10, pointsBefore: 0 }), {
        headers: { "Content-Type": "application/json" },
        status: 200,
      }),
    );
    vi.stubGlobal("fetch", request);
    render(<CoachReviewQueue context={context} filters={{}} items={[review]} programs={[]} />);
    await user.type(screen.getByLabelText(/Alasan penolakan/), "Bukti belum sesuai.");
    await user.click(screen.getByRole("button", { name: "Tolak" }));
    expect(await screen.findByRole("status")).toHaveTextContent(
      "Skor direkonsiliasi dari 0 menjadi 10 poin",
    );
    expect(request).toHaveBeenCalledTimes(1);
    const [, init] = request.mock.calls[0] as [string, RequestInit];
    expect(JSON.parse(String(init.body))).toMatchObject({
      decision: "rejected",
      reason: "Bukti belum sesuai.",
    });
    expect(
      window.localStorage.getItem(`msc.coach.review.${review.submissionId}.rejected`),
    ).toBeNull();
  });
});
