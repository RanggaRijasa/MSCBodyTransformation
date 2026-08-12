"use client";

import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";

import type { ProgramContentKind } from "@/domain/programs/program";
import { canonicalIndonesianWeight } from "@/domain/services/participant-program";
import { AppButton } from "@/shared/ui/controls/actions";
import { FormErrorSummary, TextField } from "@/shared/ui/forms/form-controls";

const kinds: Readonly<
  Record<
    Extract<ProgramContentKind, "initial_weigh_in" | "daily_weigh_in" | "final_weigh_in">,
    "initial" | "daily" | "final"
  >
> = {
  daily_weigh_in: "daily",
  final_weigh_in: "final",
  initial_weigh_in: "initial",
};

export function WeighInForm({
  contentKind,
  enrollmentId,
  stepId,
}: Readonly<{ contentKind: keyof typeof kinds; enrollmentId: string; stepId: string }>) {
  const router = useRouter();
  const abortReference = useRef<AbortController | null>(null);
  const [weight, setWeight] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setSubmitting] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  useEffect(() => () => abortReference.current?.abort(), []);

  async function submit() {
    const parsed = canonicalIndonesianWeight(weight);
    if (!parsed.isSuccess) {
      setError(parsed.error.message);
      return;
    }
    setError(null);
    setMessage(null);
    setSubmitting(true);
    const controller = new AbortController();
    abortReference.current = controller;
    const storageKey = `msc.weigh-in.key.${enrollmentId}.${stepId}`;
    let idempotencyKey = window.localStorage.getItem(storageKey);
    if (!idempotencyKey) {
      idempotencyKey = crypto.randomUUID();
      window.localStorage.setItem(storageKey, idempotencyKey);
    }
    try {
      const response = await fetch("/api/participant/weigh-ins", {
        body: JSON.stringify({
          enrollmentId,
          idempotencyKey,
          kind: kinds[contentKind],
          stepId,
          weight: parsed.value,
        }),
        headers: { "Content-Type": "application/json" },
        method: "POST",
        signal: controller.signal,
      });
      if (!response.ok) throw new Error("weigh_in_failed");
      window.localStorage.removeItem(storageKey);
      setWeight("");
      setMessage("Berat berhasil dicatat secara privat oleh server.");
      router.refresh();
    } catch (caught) {
      if (caught instanceof DOMException && caught.name === "AbortError") return;
      setMessage(
        "Berat belum tersimpan. Periksa koneksi dan coba lagi; data tidak dianggap terkirim.",
      );
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="participant-weigh-in">
      <TextField
        autoComplete="off"
        description="Data berat bersifat privat dan tidak tampil di papan peringkat."
        {...(error ? { error } : {})}
        id="participant-weight"
        inputMode="decimal"
        label="Berat badan (kg)"
        onChange={(event) => setWeight(event.target.value)}
        value={weight}
      />
      <p>
        Catat sesuai pengukuranmu. Fitur ini mendukung kebugaran dan bukan alat diagnosis medis.
      </p>
      {message ? (
        <FormErrorSummary
          title={message.includes("berhasil") ? "Pencatatan selesai" : "Pencatatan belum selesai"}
        >
          <p>{message}</p>
        </FormErrorSummary>
      ) : null}
      <AppButton disabled={isSubmitting} isLoading={isSubmitting} onClick={() => void submit()}>
        Simpan berat
      </AppButton>
    </div>
  );
}
