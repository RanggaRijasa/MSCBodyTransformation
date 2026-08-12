"use client";

import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";

import type { ParticipantProgram } from "@/domain/participant/participant-program";
import type { PublicProgramQuestion, PublicProgramStep } from "@/domain/programs/program";
import { ProgramVideoPlayer } from "@/features/device-media";
import { ProgramQuestionFields } from "@/features/participant/components/program-question-fields";
import { WeighInForm } from "@/features/participant/components/weigh-in-form";
import {
  emptyAnswerDraft,
  validateParticipantAnswers,
  type ParticipantAnswerDrafts,
} from "@/features/participant/model/participant-answer-state";
import { AppButton } from "@/shared/ui/controls/actions";
import { FormErrorSummary } from "@/shared/ui/forms/form-controls";
import { ProgramContentPreview } from "@/shared/ui/program/program-content-preview";
import { StatusBadge } from "@/shared/ui/status/status";
import { Surface } from "@/shared/ui/surfaces/surfaces";

type SubmissionResult = Readonly<{
  quizResult: Readonly<{
    awardedPoints: number;
    correctCount: number;
    passed: boolean;
    percentage: number;
    totalCount: number;
  }> | null;
  status: "approved" | "pending" | "rejected";
}>;

function interactiveQuestions(questions: readonly PublicProgramQuestion[]) {
  return questions.filter(({ kind }) => kind !== "heading" && kind !== "text");
}

export function ParticipantStepContent({
  participantProgram,
  step,
}: Readonly<{ participantProgram: ParticipantProgram; step: PublicProgramStep }>) {
  const router = useRouter();
  const abortReference = useRef<AbortController | null>(null);
  const [drafts, setDrafts] = useState<ParticipantAnswerDrafts>({});
  const [errors, setErrors] = useState<Readonly<Record<string, string>>>({});
  const [isSubmitting, setSubmitting] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [result, setResult] = useState<SubmissionResult | null>(null);
  const [videoComplete, setVideoComplete] = useState(!step.videoRequired);
  const storageKey = `msc.submission.key.${participantProgram.enrollmentId}.${step.id}`;

  useEffect(() => {
    const handleStorage = (event: StorageEvent) => {
      if (event.key === storageKey && event.newValue === null) {
        setMessage("Aktivitas diproses di tab lain. Muat ulang untuk melihat status terbaru.");
      }
    };
    window.addEventListener("storage", handleStorage);
    return () => {
      abortReference.current?.abort();
      window.removeEventListener("storage", handleStorage);
    };
  }, [storageKey]);

  function idempotencyKey() {
    const existing = window.localStorage.getItem(storageKey);
    if (existing) return existing;
    const created = crypto.randomUUID();
    window.localStorage.setItem(storageKey, created);
    return created;
  }

  async function prepare(key: string, signal: AbortSignal): Promise<string> {
    const response = await fetch("/api/participant/submissions/prepare", {
      body: JSON.stringify({
        enrollmentId: participantProgram.enrollmentId,
        idempotencyKey: key,
        stepId: step.id,
      }),
      headers: { "Content-Type": "application/json" },
      method: "POST",
      signal,
    });
    if (!response.ok) throw new Error("prepare_failed");
    const payload = (await response.json()) as { submissionId?: unknown };
    if (typeof payload.submissionId !== "string") throw new Error("prepare_invalid");
    return payload.submissionId;
  }

  async function uploadPhoto(
    question: PublicProgramQuestion,
    submissionId: string,
    signal: AbortSignal,
  ) {
    const photo = drafts[question.id]?.photo;
    if (!photo) throw new Error("photo_missing");
    const form = new FormData();
    form.set("image", new File([photo.fullImage], `${question.id}.jpg`, { type: "image/jpeg" }));
    form.set("questionId", question.id);
    form.set("submissionId", submissionId);
    const response = await fetch("/api/participant/submissions/photo", {
      body: form,
      method: "POST",
      signal,
    });
    if (!response.ok) throw new Error("photo_upload_failed");
    const payload = (await response.json()) as { privatePhotoPath?: unknown };
    if (typeof payload.privatePhotoPath !== "string") throw new Error("photo_receipt_invalid");
    return payload.privatePhotoPath;
  }

  async function buildAnswers(submissionId: string, signal: AbortSignal) {
    const answers = [];
    for (const question of interactiveQuestions(step.questions)) {
      const draft = drafts[question.id] ?? emptyAnswerDraft();
      const privatePhotoPath =
        question.kind === "photo_upload"
          ? await uploadPhoto(question, submissionId, signal)
          : undefined;
      answers.push({
        ...(question.kind === "number"
          ? { numberValue: draft.value.trim().replace(",", ".") }
          : {}),
        ...(privatePhotoPath ? { privatePhotoPath } : {}),
        questionId: question.id,
        ...(["single_choice", "multiple_choice", "image_choice"].includes(question.kind)
          ? { selectedOptionIds: draft.selectedOptionIds }
          : {}),
        ...(["short_answer", "long_answer"].includes(question.kind)
          ? { textValue: draft.value.trim() }
          : {}),
      });
    }
    return answers;
  }

  async function submit() {
    const nextErrors = validateParticipantAnswers(step.questions, drafts);
    setErrors(nextErrors);
    if (Object.keys(nextErrors).length || !videoComplete) {
      setMessage(
        !videoComplete
          ? "Tonton video sampai batas yang ditentukan sebelum mengirim."
          : "Lengkapi semua jawaban wajib.",
      );
      return;
    }
    setSubmitting(true);
    setMessage(null);
    setResult(null);
    const controller = new AbortController();
    abortReference.current = controller;
    const key = idempotencyKey();
    try {
      const submissionId = await prepare(key, controller.signal);
      const answers = await buildAnswers(submissionId, controller.signal);
      const response = await fetch("/api/participant/submissions/submit", {
        body: JSON.stringify({ answers, idempotencyKey: key, submissionId }),
        headers: { "Content-Type": "application/json" },
        method: "POST",
        signal: controller.signal,
      });
      if (!response.ok) throw new Error("submission_failed");
      const payload = (await response.json()) as SubmissionResult;
      window.localStorage.removeItem(storageKey);
      setResult(payload);
      setMessage(
        payload.status === "pending"
          ? "Jawaban terkirim dan menunggu pemeriksaan Coach."
          : "Aktivitas berhasil disimpan oleh server.",
      );
      // Pertahankan hasil kuis yang baru diterima agar tidak hilang ketika
      // refresh Server Component selesai lebih cepat pada browser tertentu.
      if (!payload.quizResult) router.refresh();
    } catch (caught) {
      if (caught instanceof DOMException && caught.name === "AbortError") return;
      setMessage(
        "Aktivitas belum terkirim. Periksa koneksi dan coba lagi; draft ini belum dianggap selesai.",
      );
    } finally {
      setSubmitting(false);
    }
  }

  if (["initial_weigh_in", "daily_weigh_in", "final_weigh_in"].includes(step.contentKind)) {
    return (
      <WeighInForm
        contentKind={step.contentKind as "initial_weigh_in" | "daily_weigh_in" | "final_weigh_in"}
        enrollmentId={participantProgram.enrollmentId}
        stepId={step.id}
      />
    );
  }

  return (
    <div className="participant-step-content">
      <ProgramContentPreview audience="participant" showQuestions={false} step={step} />
      {step.contentKind === "video" && step.mediaUrl ? (
        <ProgramVideoPlayer
          autoplay={step.videoAutoplay}
          captionsSrc="/captions/program-id.vtt"
          enrollmentId={participantProgram.enrollmentId}
          onWatchProgress={({ completed }) => setVideoComplete(completed)}
          requiredPercentage={step.videoThreshold ?? 90}
          src={step.mediaUrl}
          stepId={step.id}
          textAlternative={step.instructions || "Ikuti panduan aktivitas yang menyertai video."}
        />
      ) : null}
      {step.contentKind === "video" && !step.mediaUrl ? (
        <FormErrorSummary title="Video belum tersedia">
          <p>Konten video belum dapat dibuka. Coba lagi setelah Admin menerbitkan media.</p>
        </FormErrorSummary>
      ) : null}
      <ProgramQuestionFields
        drafts={drafts}
        errors={errors}
        onChange={(questionId, draft) =>
          setDrafts((current) => ({ ...current, [questionId]: draft }))
        }
        questions={step.questions}
      />
      {message ? (
        <p className="participant-submission-message" role="status">
          {message}
        </p>
      ) : null}
      {result?.quizResult ? (
        <Surface className="participant-quiz-result">
          <StatusBadge tone={result.quizResult.passed ? "success" : "warning"}>
            {result.quizResult.passed ? "Lulus" : "Belum lulus"}
          </StatusBadge>
          <p>
            {result.quizResult.correctCount} dari {result.quizResult.totalCount} jawaban benar ·{" "}
            {result.quizResult.percentage}% · {result.quizResult.awardedPoints} poin
          </p>
          <p>Hasil ini privat dan berasal dari penilaian server.</p>
        </Surface>
      ) : null}
      <AppButton
        disabled={
          isSubmitting || Boolean(result) || (step.contentKind === "video" && !step.mediaUrl)
        }
        isLoading={isSubmitting}
        onClick={() => void submit()}
      >
        {step.contentKind === "quiz" ? "Kirim kuis" : "Kirim aktivitas"}
      </AppButton>
    </div>
  );
}
