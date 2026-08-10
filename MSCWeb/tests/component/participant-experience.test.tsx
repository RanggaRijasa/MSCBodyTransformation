import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, describe, expect, it, vi } from "vitest";

import type { ParticipantProgram } from "@/domain/participant/participant-program";
import type {
  PublicProgram,
  PublicProgramQuestion,
  PublicProgramStep,
} from "@/domain/programs/program";
import { ParticipantHome } from "@/features/participant/components/participant-home";
import { ParticipantRanking } from "@/features/participant/components/participant-ranking";
import { ParticipantStepContent } from "@/features/participant/components/participant-step-content";
import { ProgramActivity } from "@/features/participant/components/program-activity";
import { ProgramQuestionFields } from "@/features/participant/components/program-question-fields";

const refresh = vi.fn();
vi.mock("next/navigation", () => ({ useRouter: () => ({ refresh }) }));

function program(days: PublicProgram["days"] = []): PublicProgram {
  return {
    category: "Transformasi",
    coverAlternativeText: null,
    coverImageUrl: null,
    days,
    desiredPrice: null,
    endsOn: "2026-08-31",
    futureStepPolicy: "locked",
    id: "00000000-0000-4000-8000-000000000001",
    participantLimit: null,
    pastStepPolicy: "read_only",
    pointsPerActivity: 10,
    pointsPerWeightKilogram: "100.00",
    pricingMode: "free",
    quizPassingPercentage: 70,
    registrationClosesAt: null,
    startsOn: "2026-08-01",
    status: "active",
    summary: "Program aman.",
    timezone: "Asia/Makassar",
    title: "Program Agustus",
    wellnessDisclaimer: "Non-diagnostik.",
  };
}

function step(overrides: Partial<PublicProgramStep> = {}): PublicProgramStep {
  return {
    completionPolicy: "mark_complete",
    contentKind: "article",
    id: "00000000-0000-4000-8000-000000000011",
    instructions: "Baca panduan berikut.",
    mediaAlternativeText: null,
    mediaPath: null,
    mediaUrl: null,
    order: 1,
    questions: [],
    title: "Panduan",
    verificationMode: "automatic",
    videoAutoplay: false,
    videoRequired: false,
    videoThreshold: null,
    ...overrides,
  };
}

function participantProgram(): ParticipantProgram {
  const targetProgram = program([
    {
      dayNumber: 1,
      id: "00000000-0000-4000-8000-000000000021",
      scheduledOn: "2026-08-10",
      steps: [step()],
      summary: "Fokus hari ini.",
      title: "Hari pertama",
    },
  ]);
  return {
    access: [
      {
        accessState: "available",
        dayNumber: 1,
        enrollmentId: "00000000-0000-4000-8000-000000000031",
        isCurrentDay: true,
        programDayId: targetProgram.days[0]!.id,
        programId: targetProgram.id,
      },
    ],
    enrollmentId: "00000000-0000-4000-8000-000000000031",
    enrollmentStatus: "active",
    program: targetProgram,
    quizResults: [],
    score: {
      activityPoints: 0,
      adjustmentPoints: 0,
      progressPercentage: 25,
      quizPoints: 0,
      rank: 2,
      totalPoints: 0,
      weightPoints: 0,
    },
    submissions: [],
    weighedStepIds: [],
  };
}

afterEach(() => {
  vi.unstubAllGlobals();
  window.localStorage.clear();
  refresh.mockReset();
});

describe("pengalaman Peserta", () => {
  it("menjaga urutan Home dan Guest state public-safe", () => {
    render(
      <ParticipantHome
        actor="guest"
        coaches={[]}
        displayName=""
        programs={[]}
        publicPrograms={[program()]}
        selectedProgram={null}
        topFive={[]}
        winnerPosters={[]}
        winners={[]}
      />,
    );
    const headings = screen
      .getAllByRole("heading", { level: 2 })
      .map((heading) => heading.textContent);
    expect(headings).toEqual(["Program", "Fokus", "Top 5", "Pemenang", "Coach"]);
    expect(screen.getByRole("link", { name: "Masuk atau daftar" })).toHaveAttribute(
      "href",
      "/masuk?returnTo=%2Fhari-ini",
    );
    expect(screen.queryByText(/berat/i)).not.toBeInTheDocument();
  });

  it("membuka satu hari server dan menampilkan status langkah", () => {
    render(<ProgramActivity participantProgram={participantProgram()} />);
    expect(screen.getByText(/Hari ini · Hari pertama/)).toBeVisible();
    expect(screen.getByRole("link", { name: /Panduan/ })).toHaveAttribute(
      "href",
      expect.stringContaining("/langkah/"),
    );
    expect(screen.getByText("Tersedia")).toBeVisible();
  });

  it("merender heading, text, angka, pilihan, gambar, dan foto secara typed", () => {
    const kinds: PublicProgramQuestion[] = [
      { id: "heading", kind: "heading", options: [], order: 1, prompt: "Bagian refleksi" },
      { id: "text", kind: "text", options: [], order: 2, prompt: "Isi sesuai keadaanmu." },
      { id: "number", kind: "number", options: [], order: 3, prompt: "Berapa gelas?" },
      {
        id: "multiple",
        kind: "multiple_choice",
        options: [
          {
            id: "option",
            mediaAlternativeText: null,
            mediaPath: null,
            mediaUrl: null,
            order: 1,
            title: "Air putih",
          },
        ],
        order: 4,
        prompt: "Pilih kebiasaan",
      },
      {
        id: "image",
        kind: "image_choice",
        options: [
          {
            id: "image-option",
            mediaAlternativeText: "Pilihan gambar",
            mediaPath: null,
            mediaUrl: null,
            order: 1,
            title: "Gerakan A",
          },
        ],
        order: 5,
        prompt: "Pilih gerakan",
      },
      { id: "photo", kind: "photo_upload", options: [], order: 6, prompt: "Unggah foto" },
    ];
    render(<ProgramQuestionFields drafts={{}} errors={{}} onChange={vi.fn()} questions={kinds} />);
    expect(screen.getByRole("heading", { name: "Bagian refleksi" })).toBeVisible();
    expect(screen.getByRole("textbox", { name: "Berapa gelas?" })).toHaveAttribute(
      "inputmode",
      "decimal",
    );
    expect(screen.getByRole("checkbox", { name: "Air putih" })).toBeVisible();
    expect(screen.getByRole("radio", { name: "Gerakan A" })).toBeVisible();
    expect(screen.getByText("Belum ada foto dipilih.")).toBeVisible();
  });

  it("menganggap selesai hanya setelah prepare dan submit server sukses", async () => {
    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce(
        new Response(JSON.stringify({ submissionId: "00000000-0000-4000-8000-000000000041" }), {
          status: 200,
        }),
      )
      .mockResolvedValueOnce(
        new Response(JSON.stringify({ quizResult: null, status: "approved" }), { status: 200 }),
      );
    vi.stubGlobal("fetch", fetchMock);
    render(<ParticipantStepContent participantProgram={participantProgram()} step={step()} />);
    await userEvent.click(screen.getByRole("button", { name: "Kirim aktivitas" }));
    expect(await screen.findByText("Aktivitas berhasil disimpan oleh server.")).toBeVisible();
    expect(fetchMock).toHaveBeenCalledTimes(2);
    await waitFor(() => expect(refresh).toHaveBeenCalledOnce());
    expect(window.localStorage.length).toBe(0);
  });

  it("tidak mengaku selesai saat jaringan gagal", async () => {
    vi.stubGlobal("fetch", vi.fn().mockRejectedValue(new TypeError("offline")));
    render(<ParticipantStepContent participantProgram={participantProgram()} step={step()} />);
    await userEvent.click(screen.getByRole("button", { name: "Kirim aktivitas" }));
    expect(await screen.findByText(/belum terkirim/i)).toBeVisible();
    expect(refresh).not.toHaveBeenCalled();
  });

  it("menampilkan podium, posisi sendiri, riwayat, dan pagination tanpa data privat", () => {
    const selected = {
      ...participantProgram(),
      enrollmentStatus: "completed" as const,
      program: { ...participantProgram().program, status: "completed" as const },
      score: { ...participantProgram().score, rank: 31, totalPoints: 120 },
    };
    render(
      <ParticipantRanking
        currentEntry={{
          id: "own-score",
          isCurrentParticipant: true,
          participantDisplayName: "Peserta sendiri",
          participantId: "public-own",
          programId: selected.program.id,
          progressPercentage: 100,
          rank: 31,
          totalPoints: 120,
        }}
        entries={[
          {
            id: "leader",
            isCurrentParticipant: false,
            participantDisplayName: "Peserta teratas",
            participantId: "public-leader",
            programId: selected.program.id,
            progressPercentage: 100,
            rank: 1,
            totalPoints: 500,
          },
        ]}
        hasNextPage
        page={2}
        programs={[
          selected,
          {
            ...participantProgram(),
            program: { ...program(), id: "program-active", title: "Program aktif" },
          },
        ]}
        selected={selected}
        winners={[]}
      />,
    );
    expect(screen.getByText("Riwayat")).toBeVisible();
    expect(screen.getAllByText("Peringkat 31")).toHaveLength(2);
    expect(screen.getByText("Peserta teratas").closest("li")).toHaveClass("rank-1");
    expect(screen.getByRole("link", { name: "Sebelumnya" })).toHaveAttribute(
      "href",
      expect.stringContaining("page=1"),
    );
    expect(screen.getByRole("link", { name: "Berikutnya" })).toHaveAttribute(
      "href",
      expect.stringContaining("page=3"),
    );
    expect(screen.queryByText(/kg|nomor hp|bukti transfer/i)).not.toBeInTheDocument();
  });
});
