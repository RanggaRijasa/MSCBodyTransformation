import { fireEvent, render, screen, within } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

vi.mock("@/application/admin/admin-mutations", () => ({
  adjustScoreAction: vi.fn(),
  archiveProgramAction: vi.fn(),
  completeProgramAction: vi.fn(),
  correctWeighInAction: vi.fn(),
  decideCoachApplicationAction: vi.fn(),
  duplicateProgramAction: vi.fn(),
  enrollParticipantAction: vi.fn(),
  lockWinnersAction: vi.fn(),
  managePosterAction: vi.fn(),
  publishProgramAction: vi.fn(),
  reopenProgramAction: vi.fn(),
  reopenQuizAttemptAction: vi.fn(),
  saveProgramDraftAction: vi.fn(),
  transferCoachAction: vi.fn(),
}));

vi.mock("@/features/admin/components/admin-poster-uploader", () => ({
  AdminPosterUploader: () => <div data-testid="poster-uploader" />,
}));

import { createBlankProgramDraft, type AdminProgramListItem } from "@/domain/admin/admin-program";
import { AdminContent } from "@/features/admin/components/admin-content";
import { AdminDashboard } from "@/features/admin/components/admin-dashboard";
import { AdminPeople } from "@/features/admin/components/admin-people";
import { AdminProgramDetail } from "@/features/admin/components/admin-program-detail";
import { AdminProgramEditor } from "@/features/admin/components/admin-program-editor";
import { AdminProgramList } from "@/features/admin/components/admin-program-list";

function program(index: number): AdminProgramListItem {
  return {
    desiredPrice: index % 2 ? "250000" : null,
    endsOn: "2026-08-31",
    enrollmentCount: index,
    id: `program-${index}`,
    participantLimit: 50,
    pricingMode: index % 2 ? "paid" : "free",
    startsOn: "2026-08-01",
    status: index % 3 ? "active" : "draft",
    title: `Program ${index}`,
  };
}

describe("pengalaman Admin", () => {
  it("menampilkan action counts dan quick actions yang berbeda", () => {
    render(
      <AdminDashboard
        snapshot={{
          activePrograms: 2,
          closureBlockers: 1,
          coachApplications: 3,
          paymentReviews: 4,
          recentAudit: [],
          systemAttention: 5,
        }}
      />,
    );
    expect(screen.getByText("Pembayaran menunggu")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Buka antrean" })).toHaveAttribute(
      "href",
      "/admin/pembayaran",
    );
    expect(screen.getByRole("link", { name: "Buat program" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Tambah poster" })).toBeInTheDocument();
    expect(screen.getByRole("heading", { level: 1, name: "Dashboard" })).toBeVisible();
    expect(screen.queryByText("Ringkasan operasional")).not.toBeInTheDocument();
    expect(screen.getByText(/Kendali operasional hari ini/)).toBeVisible();
    expect(screen.getByText("Belum ada aktivitas Admin yang dapat ditampilkan.")).toBeVisible();
    expect(
      within(
        screen.getByRole("heading", { name: "Program perlu ditutup" }).closest("article")!,
      ).getByText("1"),
    ).toBeVisible();
    expect(screen.getByRole("link", { name: "Buka program" })).toHaveAttribute(
      "href",
      "/admin/program?status=completed",
    );
    expect(screen.getByRole("link", { name: "Tinjau pengajuan" })).toHaveAttribute(
      "href",
      "/admin/orang?bagian=pengajuan",
    );
  });

  it("memiliki empty state dan pagination bounded untuk data besar", () => {
    const { rerender } = render(<AdminProgramList items={[]} query="" status="" />);
    expect(screen.getByRole("heading", { name: "Tidak ada program" })).toBeInTheDocument();
    rerender(
      <AdminProgramList
        items={Array.from({ length: 25 }, (_, index) => program(index + 1))}
        page={2}
        query=""
        status=""
      />,
    );
    expect(screen.getByText("Halaman 2")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Halaman sebelumnya" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Halaman berikutnya" })).toBeInTheDocument();
    expect(screen.getAllByRole("link", { name: "Buka program" })).toHaveLength(12);
  });

  it("menerapkan search dan status tanpa merender data di luar hasil", () => {
    render(
      <AdminProgramList
        items={[program(1), { ...program(2), status: "completed", title: "Program Selesai" }]}
        query="Selesai"
        status="completed"
      />,
    );
    expect(screen.getByRole("heading", { name: "Program Selesai" })).toBeInTheDocument();
    expect(screen.queryByRole("heading", { name: "Program 1" })).not.toBeInTheDocument();
  });

  it("mengoperasikan tab editor dengan keyboard dan relasi panel yang eksplisit", () => {
    const draft = createBlankProgramDraft(
      () => "00000000-0000-4000-8000-000000000001",
      "2026-08-12",
    );
    render(<AdminProgramEditor initialDraft={draft} />);

    const settings = screen.getByRole("tab", { name: "Pengaturan" });
    const content = screen.getByRole("tab", { name: "Hari dan konten" });
    expect(settings).toHaveAttribute("aria-controls", "admin-editor-settings-panel");
    expect(settings).toHaveAttribute("aria-selected", "true");

    fireEvent.keyDown(settings, { key: "ArrowRight" });
    expect(content).toHaveFocus();
    expect(content).toHaveAttribute("aria-selected", "true");
    expect(screen.getByRole("tabpanel")).toHaveAttribute(
      "aria-labelledby",
      "admin-editor-content-tab",
    );
    fireEvent.click(screen.getByRole("button", { name: "Tambah langkah" }));
    expect(screen.getByRole("option", { name: "Artikel" })).toHaveValue("article");
    expect(screen.queryByRole("option", { name: "article" })).not.toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: "Tambah pertanyaan" }));
    expect(screen.getByRole("option", { name: "Jawaban singkat" })).toHaveValue("short_answer");
    expect(screen.queryByRole("option", { name: "short_answer" })).not.toBeInTheDocument();

    fireEvent.keyDown(content, { key: "Home" });
    expect(settings).toHaveFocus();
    expect(settings).toHaveAttribute("aria-selected", "true");
  });

  it("menampilkan empty state direktori dan pengajuan secara terpisah", () => {
    render(
      <AdminPeople
        applications={[]}
        correctionTargets={{ enrollments: [], weighIns: [] }}
        operationPeople={[]}
        people={[]}
        programs={[]}
        role="coach"
        search="Rina"
      />,
    );

    expect(screen.getByRole("heading", { name: "Tidak ada orang yang cocok" })).toBeVisible();
    expect(screen.getByRole("heading", { name: "Belum ada pengajuan Coach" })).toBeVisible();
    expect(screen.getByRole("link", { name: "Semua" })).toHaveAttribute(
      "href",
      "/admin/orang?q=Rina",
    );
    expect(screen.getByRole("link", { name: "Peserta" })).toHaveAttribute(
      "href",
      "/admin/orang?q=Rina&peran=participant",
    );
    const selectedRole = screen.getByRole("link", { name: "Coach" });
    expect(selectedRole).toHaveAttribute("aria-current", "page");
    selectedRole.focus();
    expect(selectedRole).toHaveFocus();
  });

  it("memberi nama persisten pada seluruh field operasi dan melokalkan status", () => {
    const participant = {
      coachAccessEndsAt: null,
      coachApplicationStatus: null,
      displayName: "Peserta Operasi",
      email: "Email tidak ditampilkan",
      id: "participant-1",
      memberLevel: "world_team",
      role: "participant" as const,
    };
    const coach = {
      ...participant,
      displayName: "Coach Operasi",
      id: "coach-1",
      role: "coach" as const,
    };
    render(
      <AdminPeople
        applications={[
          {
            applicantId: "applicant-1",
            displayName: "Calon Coach",
            hasCompletedHomSts: true,
            hasCompletedIct: true,
            id: "application-1",
            memberLevel: "SC",
            paymentStatus: "under_review",
            status: "submitted",
            submittedAt: "2026-08-12T00:00:00Z",
          },
        ]}
        correctionTargets={{
          enrollments: [{ id: "enrollment-1", label: "Peserta • Program" }],
          weighIns: [{ id: "weight-1", label: "Peserta • timbang awal" }],
        }}
        operationPeople={[participant, coach]}
        people={[participant, coach]}
        programs={[program(1)]}
        role=""
        search=""
      />,
    );

    fireEvent.click(screen.getByText("Operasi koreksi terkontrol"));
    for (const control of screen.getAllByRole("textbox")) expect(control).toHaveAccessibleName();
    for (const control of screen.getAllByRole("spinbutton")) expect(control).toHaveAccessibleName();
    for (const control of screen.getAllByRole("combobox")) expect(control).toHaveAccessibleName();
    expect(screen.getByText("Menunggu keputusan")).toBeVisible();
    expect(screen.getByText("Status pembayaran: Sedang diperiksa")).toBeVisible();
    expect(screen.getAllByText("World Team")).toHaveLength(2);
    expect(screen.queryByText("world_team", { exact: true })).not.toBeInTheDocument();
    expect(screen.queryByText("submitted", { exact: true })).not.toBeInTheDocument();
    expect(screen.queryByText("under_review", { exact: true })).not.toBeInTheDocument();
  });

  it("melokalkan status program dan jumlah hambatan penutupan", () => {
    const draft = {
      ...createBlankProgramDraft(() => "00000000-0000-4000-8000-000000000002", "2026-08-12"),
      status: "completed" as const,
      title: "Program selesai",
    };
    render(
      <AdminProgramDetail
        closure={{
          canComplete: false,
          canLock: false,
          canReopen: true,
          failedQuizAttempts: 0,
          failedQuizzes: [],
          incompleteEnrollments: 0,
          missingFinalWeights: 1,
          pendingReviews: 1,
          programId: draft.id,
          status: "completed",
          winnerSnapshotId: null,
        }}
        draft={draft}
      />,
    );

    expect(screen.getByText("Program Selesai")).toBeVisible();
    expect(screen.getByText("2 hambatan")).toBeVisible();
    expect(screen.queryByText("completed", { exact: true })).not.toBeInTheDocument();
    expect(screen.queryByText(/blocker/)).not.toBeInTheDocument();
  });

  it("menampilkan poster publik dengan alt tersimpan tanpa mengekspos raw path", () => {
    const { rerender } = render(<AdminContent posters={[]} snapshots={[]} />);
    expect(screen.getByRole("heading", { name: "Belum ada poster" })).toBeVisible();

    rerender(
      <AdminContent
        posters={[
          {
            alternativeText: "Poster pemenang Agustus",
            id: "poster-1",
            imageUrl:
              "http://127.0.0.1:54321/storage/v1/object/public/public-media/winners/poster.jpg",
            isPublished: true,
            mediaPath: "winners/private-looking-path/poster.jpg",
            programId: "program-1",
            programTitle: "Program Agustus",
            publishedAt: "2026-08-12T00:00:00Z",
            snapshotId: "snapshot-1",
          },
        ]}
        snapshots={[]}
      />,
    );

    expect(screen.getByRole("img", { name: "Poster pemenang Agustus" })).toBeVisible();
    expect(screen.queryByText("winners/private-looking-path/poster.jpg")).not.toBeInTheDocument();
  });
});
