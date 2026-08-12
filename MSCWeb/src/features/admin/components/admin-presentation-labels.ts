import type { AdminProgramStatus } from "@/domain/admin/admin-program";
import type { PaymentOrderStatus } from "@/domain/payments/payment";
import type { ProgramContentKind, ProgramQuestionKind } from "@/domain/programs/program";

const adminMemberLevelLabels: Readonly<Record<string, string>> = {
  get_team: "GET Team",
  member: "Member",
  millionaire_team: "Millionaire Team",
  presidents_team: "President’s Team",
  sb: "SB",
  sc: "SC",
  supervisor: "Supervisor",
  tab_team: "TAB Team",
  world_team: "World Team",
};

export const adminProgramStatusLabels: Readonly<Record<AdminProgramStatus, string>> = {
  active: "Aktif",
  archived: "Diarsipkan",
  completed: "Selesai",
  draft: "Draft",
  scheduled: "Terjadwal",
};

export const programContentKindLabels: Readonly<Record<ProgramContentKind, string>> = {
  article: "Artikel",
  daily_weigh_in: "Timbang harian",
  final_weigh_in: "Timbang akhir",
  form: "Formulir",
  initial_weigh_in: "Timbang awal",
  quiz: "Kuis",
  video: "Video",
};

export const programQuestionKindLabels: Readonly<Record<ProgramQuestionKind, string>> = {
  heading: "Judul bagian",
  image_choice: "Pilihan gambar",
  long_answer: "Jawaban panjang",
  multiple_choice: "Pilihan ganda",
  number: "Angka",
  photo_upload: "Unggah foto privat",
  short_answer: "Jawaban singkat",
  single_choice: "Pilihan tunggal",
  text: "Teks panduan",
};

const coachApplicationStatusLabels: Readonly<Record<string, string>> = {
  accepted_pending_payment: "Kelayakan diterima, menunggu pembayaran",
  active: "Aktif",
  expired: "Kedaluwarsa",
  rejected: "Ditolak",
  submitted: "Menunggu keputusan",
};

const paymentStatusLabels: Readonly<Record<PaymentOrderStatus, string>> = {
  approved: "Terverifikasi",
  awaiting_evidence: "Menunggu bukti",
  cancelled: "Dibatalkan",
  correction_required: "Perlu perbaikan",
  expired: "Kedaluwarsa",
  rejected: "Ditolak",
  reversal_pending: "Penyelesaian khusus tertunda",
  reversed: "Penyelesaian khusus selesai",
  under_review: "Sedang diperiksa",
};

export function coachApplicationStatusLabel(status: string) {
  return coachApplicationStatusLabels[status] ?? "Status belum tersedia";
}

export function paymentStatusLabel(status: string | null) {
  if (!status) return "Belum ada pembayaran";
  return paymentStatusLabels[status as PaymentOrderStatus] ?? "Status belum tersedia";
}

export function adminMemberLevelLabel(level: string | null) {
  if (!level) return "Level belum tersedia";
  const normalized = level.toLowerCase();
  return adminMemberLevelLabels[normalized] ?? "Level belum tersedia";
}
