"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

import type { AdminWinnerSnapshot } from "@/domain/admin/admin-operations";
import type { ProcessedBrowserImage } from "@/infrastructure/browser-media/browser-image-processor";
import { ImageAcquisition } from "@/features/device-media";
import { AppButton } from "@/shared/ui/controls/actions";

export function AdminPosterUploader({
  mode,
  posterId,
  snapshots = [],
}: Readonly<{
  mode: "add" | "replace";
  posterId?: string;
  snapshots?: readonly AdminWinnerSnapshot[];
}>) {
  const router = useRouter();
  const [image, setImage] = useState<ProcessedBrowserImage | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  async function submit(form: FormData) {
    if (!image) return;
    setSubmitting(true);
    setMessage(null);
    form.set("image", new File([image.fullImage], "poster.jpg", { type: "image/jpeg" }));
    form.set("operation", mode);
    if (posterId) form.set("posterId", posterId);
    try {
      const response = await fetch("/api/admin/content/posters", {
        body: form,
        cache: "no-store",
        method: "POST",
      });
      const payload = (await response.json()) as { message?: string };
      if (!response.ok) throw new Error(payload.message ?? "Poster belum dapat disimpan.");
      router.refresh();
      setMessage(
        mode === "add" ? "Draft poster tersimpan." : "Poster diganti dan kembali menjadi draft.",
      );
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Poster belum dapat disimpan.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <form action={(form) => void submit(form)} className="admin-poster-upload-form">
      {mode === "add" ? (
        <label>
          Snapshot pemenang
          <select name="snapshotId" required>
            <option value="">Pilih program yang pemenangnya sudah dikunci</option>
            {snapshots.map((snapshot) => (
              <option key={snapshot.id} value={snapshot.id}>
                {snapshot.programTitle}
              </option>
            ))}
          </select>
        </label>
      ) : null}
      <ImageAcquisition label="Pilih poster 9:16" onProcessed={setImage} />
      <label>
        Teks alternatif
        <textarea name="alternativeText" required />
      </label>
      <label>
        Alasan
        <textarea name="reason" required />
      </label>
      <AppButton disabled={!image} isLoading={submitting} type="submit">
        {mode === "add" ? "Simpan sebagai draft" : "Ganti poster"}
      </AppButton>
      {message ? <p aria-live="polite">{message}</p> : null}
    </form>
  );
}
