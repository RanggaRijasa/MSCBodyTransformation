import { AppError } from "@/domain/errors/app-error";
import type {
  ParticipantProgram,
  ParticipantSubmission,
} from "@/domain/participant/participant-program";
import type { ProgramDayAccessState, PublicProgramStep } from "@/domain/programs/program";
import { failure, success, type Result } from "@/domain/result";

export type ParticipantStepPresentation = Readonly<{
  detail: string;
  href: string | null;
  status: "approved" | "available" | "locked" | "pending" | "read_only" | "rejected";
}>;

export function canonicalIndonesianWeight(input: string): Result<string, AppError> {
  const normalized = input.trim().replace(",", ".");
  if (!/^\d{1,3}(?:\.\d{1,2})?$/.test(normalized)) {
    return failure(
      new AppError(
        "validation_failed",
        "Masukkan berat dalam kilogram dengan maksimal dua desimal.",
      ),
    );
  }
  const [wholePart = "0", decimalPart] = normalized.split(".");
  const whole = Number.parseInt(wholePart, 10);
  const hundredths = Number.parseInt((decimalPart ?? "").padEnd(2, "0"), 10);
  const scaled = whole * 100 + hundredths;
  if (scaled < 2_000 || scaled > 40_000) {
    return failure(new AppError("validation_failed", "Berat harus antara 20 dan 400 kg."));
  }
  const trimmedDecimal = (decimalPart ?? "").replace(/0+$/, "");
  return success(trimmedDecimal ? `${whole}.${trimmedDecimal}` : String(whole));
}

export function latestSubmission(
  submissions: readonly ParticipantSubmission[],
  stepId: string,
): ParticipantSubmission | null {
  return (
    submissions
      .filter((submission) => submission.stepId === stepId)
      .toSorted((left, right) => right.attemptSequence - left.attemptSequence)[0] ?? null
  );
}

export function presentParticipantStep(
  step: PublicProgramStep,
  accessState: ProgramDayAccessState,
  participantProgram: ParticipantProgram,
): ParticipantStepPresentation {
  const submission = latestSubmission(participantProgram.submissions, step.id);
  const isWeighed = participantProgram.weighedStepIds.includes(step.id);
  if (submission?.status === "approved" || isWeighed) {
    return { detail: "Selesai dan tercatat", href: null, status: "approved" };
  }
  if (submission?.status === "pending") {
    return { detail: "Menunggu pemeriksaan Coach", href: null, status: "pending" };
  }
  if (submission?.status === "rejected") {
    return {
      detail: submission.reviewNote || "Perlu diperbaiki dan dikirim ulang",
      href: `/program/${participantProgram.program.id}/langkah/${step.id}`,
      status: "rejected",
    };
  }
  if (accessState === "locked" || accessState === "hidden") {
    return { detail: "Belum tersedia", href: null, status: "locked" };
  }
  if (accessState === "read_only") {
    return { detail: "Riwayat hanya dapat dilihat", href: null, status: "read_only" };
  }
  return {
    detail: step.verificationMode === "coach_review" ? "Akan diperiksa Coach" : "Siap dikerjakan",
    href: `/program/${participantProgram.program.id}/langkah/${step.id}`,
    status: "available",
  };
}

export function focusedParticipantDay(program: ParticipantProgram) {
  return (
    program.access.find((day) => day.isCurrentDay) ??
    program.access.find((day) => day.accessState === "available") ??
    program.access.at(-1) ??
    null
  );
}

export function selectParticipantProgram(
  programs: readonly ParticipantProgram[],
  requestedProgramId?: string,
): ParticipantProgram | null {
  return (
    programs.find(({ program }) => program.id === requestedProgramId) ??
    programs.find(({ enrollmentStatus }) => enrollmentStatus === "active") ??
    programs[0] ??
    null
  );
}
