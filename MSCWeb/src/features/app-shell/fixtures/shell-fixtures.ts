import type { ProgramActivityModel } from "@/shared/ui";

export const shellProgramFixture: ProgramActivityModel = {
  title: "Program kebiasaan sehat",
  period: "10–30 Agustus 2026 · WITA",
  progress: 40,
  days: [
    {
      id: "fixture-day-1",
      label: "Hari 1 · Hari ini",
      isFocused: true,
      steps: [
        {
          id: "fixture-step-1",
          title: "Baca panduan hari ini",
          detail: "Artikel · 10 poin",
          status: "Tersedia",
          statusTone: "info",
        },
        {
          id: "fixture-step-2",
          title: "Catat kebiasaan",
          detail: "Form singkat · 15 poin",
          status: "Belum selesai",
          statusTone: "neutral",
        },
      ],
    },
    {
      id: "fixture-day-2",
      label: "Hari 2",
      steps: [
        {
          id: "fixture-step-3",
          title: "Aktivitas berikutnya",
          detail: "Tersedia sesuai jadwal program",
          status: "Terkunci",
          statusTone: "warning",
        },
      ],
    },
  ],
};
