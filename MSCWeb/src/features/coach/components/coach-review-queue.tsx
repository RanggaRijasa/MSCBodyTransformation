"use client";

import { useState } from "react";

import type { CoachContext, CoachReviewItem } from "@/domain/coach/coach-experience";
import type { PublicProgram } from "@/domain/programs/program";
import { createProgramDateTimeFormatter } from "@/shared/formatting/indonesian-formatters";
import { AppButton, FilterForm, SelectField, Surface, TextField } from "@/shared/ui";
import { CoachAccessState } from "./coach-access-state";
import { CoachAnswer } from "./coach-participant-detail";

export function CoachReviewQueue({
  context,
  filters,
  items,
  programs,
}: Readonly<{
  context: CoachContext;
  filters: Readonly<{
    contentKind?: string | undefined;
    programId?: string | undefined;
    submittedSince?: string | undefined;
  }>;
  items: readonly CoachReviewItem[];
  programs: readonly PublicProgram[];
}>) {
  if (context.accessState !== "active") return <CoachAccessState context={context} />;
  return (
    <div className="coach-review-queue">
      <header>
        <p className="coach-eyebrow">Pemeriksaan</p>
        <h1>Antrean pemeriksaan</h1>
        <p>Setujui atau tolak aktivitas subjektif. Penolakan selalu memerlukan alasan.</p>
      </header>
      <FilterForm className="coach-filters" method="get">
        <SelectField
          defaultValue={filters.programId ?? ""}
          id="coach-review-program"
          label="Program"
          name="program"
        >
          <option value="">Semua program</option>
          {programs.map((program) => (
            <option key={program.id} value={program.id}>
              {program.title}
            </option>
          ))}
        </SelectField>
        <SelectField
          defaultValue={filters.contentKind ?? ""}
          id="coach-review-kind"
          label="Jenis"
          name="jenis"
        >
          <option value="">Semua jenis</option>
          <option value="form">Form</option>
          <option value="article">Artikel</option>
          <option value="video">Video</option>
        </SelectField>
        <TextField
          defaultValue={filters.submittedSince}
          id="coach-review-since"
          label="Dikirim sejak"
          name="sejak"
          type="datetime-local"
        />
        <AppButton type="submit" variant="secondary">
          Terapkan
        </AppButton>
      </FilterForm>
      <div className="coach-review-list">
        {items.map((item) => (
          <ReviewCard item={item} key={item.submissionId} />
        ))}
        {!items.length ? (
          <Surface>
            <h2>Antrean kosong</h2>
            <p>Tidak ada aktivitas yang menunggu keputusan untuk filter ini.</p>
          </Surface>
        ) : null}
      </div>
    </div>
  );
}

function ReviewCard({ item }: Readonly<{ item: CoachReviewItem }>) {
  const [reason, setReason] = useState("");
  const [isBusy, setBusy] = useState(false);
  const [isComplete, setComplete] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  async function decide(decision: "approved" | "rejected") {
    if (decision === "rejected" && !reason.trim()) {
      setMessage("Tulis alasan penolakan terlebih dahulu.");
      return;
    }
    setBusy(true);
    setMessage(null);
    try {
      const storageKey = `msc.coach.review.${item.submissionId}.${decision}`;
      let key = window.localStorage.getItem(storageKey);
      if (!key) {
        key = crypto.randomUUID();
        window.localStorage.setItem(storageKey, key);
      }
      const response = await fetch(`/api/coach/reviews/${item.submissionId}`, {
        body: JSON.stringify({ decision, idempotencyKey: key, reason }),
        headers: { "Content-Type": "application/json" },
        method: "POST",
      });
      const payload = (await response.json()) as { pointsAfter?: number; pointsBefore?: number };
      if (!response.ok) throw new Error("review_failed");
      window.localStorage.removeItem(storageKey);
      setMessage(
        `Keputusan tersimpan. Skor direkonsiliasi dari ${payload.pointsBefore ?? 0} menjadi ${payload.pointsAfter ?? 0} poin.`,
      );
      setComplete(true);
    } catch {
      setMessage(
        "Keputusan belum tersimpan. Muat ulang jika aktivitas sudah diperiksa di tab lain.",
      );
    } finally {
      setBusy(false);
    }
  }
  return (
    <Surface className="coach-review-card">
      <header>
        <div>
          <h2>{item.participantName}</h2>
          <p>
            {item.programTitle} · {item.stepTitle}
          </p>
          <time dateTime={item.submittedAt}>
            {createProgramDateTimeFormatter("Asia/Jakarta").format(new Date(item.submittedAt))} WIB
          </time>
        </div>
      </header>
      {item.answers.map((answer) => (
        <CoachAnswer answer={answer} key={answer.questionId} submissionId={item.submissionId} />
      ))}
      <TextField
        id={`reason-${item.submissionId}`}
        label="Alasan penolakan (wajib saat menolak)"
        maxLength={500}
        onChange={(event) => setReason(event.target.value)}
        value={reason}
      />
      <div className="coach-actions">
        <AppButton disabled={isBusy || isComplete} onClick={() => void decide("approved")}>
          Setujui
        </AppButton>
        <AppButton
          disabled={isBusy || isComplete}
          onClick={() => void decide("rejected")}
          variant="destructive"
        >
          Tolak
        </AppButton>
      </div>
      {message ? <p role="status">{message}</p> : null}
    </Surface>
  );
}
