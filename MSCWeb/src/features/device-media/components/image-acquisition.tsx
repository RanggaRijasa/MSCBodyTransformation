"use client";

import Image from "next/image";
import { useEffect, useMemo, useRef, useState } from "react";

import {
  BrowserImageProcessor,
  type ProcessedBrowserImage,
} from "@/infrastructure/browser-media/browser-image-processor";
import { AppButton } from "@/shared/ui/controls/actions";
import { CameraCaptureDialog } from "@/features/device-media/components/camera-capture-dialog";

type ProcessingState = "idle" | "processing" | "ready" | "error";

export type ImageProcessor = Readonly<{
  process(file: File, signal?: AbortSignal): Promise<ProcessedBrowserImage>;
}>;

export function ImageAcquisition({
  label = "Unggah foto",
  onProcessed,
  processor,
}: Readonly<{
  label?: string;
  onProcessed: (image: ProcessedBrowserImage) => void;
  processor?: ImageProcessor;
}>) {
  const imageProcessor = useMemo(() => processor ?? new BrowserImageProcessor(), [processor]);
  const abortReference = useRef<AbortController | null>(null);
  const previewUrlReference = useRef<string | null>(null);
  const [isCameraOpen, setCameraOpen] = useState(false);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [state, setState] = useState<ProcessingState>("idle");
  const [message, setMessage] = useState<string | null>(null);

  useEffect(() => {
    return () => {
      abortReference.current?.abort();
      if (previewUrlReference.current) URL.revokeObjectURL(previewUrlReference.current);
    };
  }, []);

  async function process(file: File) {
    abortReference.current?.abort();
    const controller = new AbortController();
    abortReference.current = controller;
    setState("processing");
    setMessage(null);
    try {
      const result = await imageProcessor.process(file, controller.signal);
      if (previewUrlReference.current) URL.revokeObjectURL(previewUrlReference.current);
      const nextPreviewUrl = URL.createObjectURL(result.thumbnail);
      previewUrlReference.current = nextPreviewUrl;
      setPreviewUrl(nextPreviewUrl);
      setState("ready");
      onProcessed(result);
    } catch (error) {
      if (error instanceof DOMException && error.name === "AbortError") return;
      setState("error");
      setMessage(error instanceof Error ? error.message : "Foto belum dapat diproses.");
    }
  }

  function remove() {
    abortReference.current?.abort();
    if (previewUrlReference.current) URL.revokeObjectURL(previewUrlReference.current);
    previewUrlReference.current = null;
    setPreviewUrl(null);
    setMessage(null);
    setState("idle");
  }

  return (
    <section aria-label={label} className="image-acquisition">
      {previewUrl ? (
        <div className="image-acquisition__preview">
          <Image
            alt="Pratinjau foto yang dipilih"
            fill
            sizes="320px"
            src={previewUrl}
            unoptimized
          />
        </div>
      ) : (
        <div className="image-acquisition__empty">Belum ada foto dipilih.</div>
      )}
      <div className="media-action-row">
        <label className="app-action app-action--secondary">
          <span>Pilih dari galeri</span>
          <input
            accept="image/jpeg,image/png,image/webp,image/heic,image/heif"
            onChange={(event) => {
              const file = event.target.files?.[0];
              if (file) void process(file);
              event.currentTarget.value = "";
            }}
            type="file"
          />
        </label>
        <AppButton onClick={() => setCameraOpen(true)} variant="secondary">
          Gunakan kamera
        </AppButton>
        {state === "ready" ? (
          <AppButton onClick={remove} variant="destructive">
            Hapus foto
          </AppButton>
        ) : null}
      </div>
      {state === "processing" ? (
        <p aria-live="polite">Memproses dan menghapus metadata foto…</p>
      ) : null}
      {message ? (
        <p className="form-error-summary" role="alert">
          {message}
        </p>
      ) : null}
      <CameraCaptureDialog
        isOpen={isCameraOpen}
        onCapture={(file) => void process(file)}
        onClose={() => setCameraOpen(false)}
      />
    </section>
  );
}
