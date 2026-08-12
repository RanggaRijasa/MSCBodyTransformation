import type { AdminProgramStatus } from "@/domain/admin/admin-program";

export type AdminDashboardSnapshot = Readonly<{
  activePrograms: number;
  coachApplications: number;
  closureBlockers: number;
  paymentReviews: number;
  recentAudit: readonly AdminAuditItem[];
  systemAttention: number;
}>;

export type AdminAuditItem = Readonly<{
  actorLabel: string;
  id: string;
  kind: string;
  occurredAt: string;
  reason: string;
  subjectId: string | null;
}>;

export type AdminPerson = Readonly<{
  coachAccessEndsAt: string | null;
  coachApplicationStatus: string | null;
  displayName: string;
  email: string;
  id: string;
  memberLevel: string | null;
  role: "admin" | "coach" | "participant";
}>;

export type AdminWinnerPoster = Readonly<{
  alternativeText: string;
  id: string;
  imageUrl: string;
  isPublished: boolean;
  mediaPath: string;
  programId: string;
  programTitle: string;
  publishedAt: string | null;
  snapshotId: string;
}>;

export type AdminWinnerSnapshot = Readonly<{
  id: string;
  programId: string;
  programTitle: string;
}>;

export type AdminCoachApplication = Readonly<{
  applicantId: string;
  displayName: string;
  hasCompletedHomSts: boolean;
  hasCompletedIct: boolean;
  id: string;
  memberLevel: string;
  paymentStatus: string | null;
  status: string;
  submittedAt: string | null;
}>;

export type AdminProgramClosure = Readonly<{
  canComplete: boolean;
  canLock: boolean;
  canReopen: boolean;
  failedQuizAttempts: number;
  failedQuizzes: readonly Readonly<{
    attemptSequence: number;
    enrollmentId: string;
    participantDisplayName: string;
    percentage: number;
    stepId: string;
    stepTitle: string;
  }>[];
  incompleteEnrollments: number;
  missingFinalWeights: number;
  pendingReviews: number;
  programId: string;
  status: AdminProgramStatus;
  winnerSnapshotId: string | null;
}>;

export type AdminCorrectionTargets = Readonly<{
  enrollments: readonly Readonly<{ id: string; label: string }>[];
  weighIns: readonly Readonly<{ id: string; label: string }>[];
}>;

export const safeAuditLabels: Readonly<Record<string, string>> = {
  coach_application_accepted: "Pengajuan Coach diterima",
  coach_application_rejected: "Pengajuan Coach ditolak",
  coach_transferred: "Coach peserta dipindahkan",
  managed_content_updated: "Konten terkelola diperbarui",
  payment_approved: "Pembayaran diverifikasi",
  payment_rejected: "Pembayaran memerlukan tindak lanjut",
  program_archived: "Program diarsipkan",
  program_completed: "Program diselesaikan",
  program_created: "Draft program dibuat",
  program_published: "Program diterbitkan",
  program_reopened: "Program dibuka kembali",
  program_updated: "Draft program diperbarui",
  quiz_attempt_reopened: "Percobaan kuis dibuka kembali",
  score_adjusted: "Poin peserta disesuaikan",
  weigh_in_corrected: "Data timbang dikoreksi",
  winners_locked: "Pemenang dikunci",
};

export function safeAuditKind(kind: string) {
  return safeAuditLabels[kind] ?? "Aktivitas Admin";
}
