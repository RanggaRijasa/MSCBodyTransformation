"use client";

import { useEffect, useRef, useState } from "react";

import {
  captureCameraFrame,
  openEnvironmentCamera,
  stopCamera,
  type CameraFailure,
} from "@/infrastructure/browser-media/browser-camera";
import { AppButton } from "@/shared/ui/controls/actions";
import { ModalDialog } from "@/shared/ui/overlays/modal-dialog";

type CameraState = "opening" | "ready" | "permission_denied" | "unavailable" | "error";

function mapFailure(error: unknown): CameraState {
  const failure = error as CameraFailure;
  if (failure.kind === "permission_denied") return "permission_denied";
  if (failure.kind === "camera_unavailable" || failure.kind === "insecure_context")
    return "unavailable";
  return "error";
}

function cameraMessage(state: CameraState): string {
  switch (state) {
    case "opening":
      return "Membuka kamera…";
    case "ready":
      return "Pastikan foto terlihat jelas sebelum mengambil gambar.";
    case "permission_denied":
      return "Akses kamera ditolak. Izinkan kamera di pengaturan browser atau pilih foto dari galeri.";
    case "unavailable":
      return "Kamera tidak tersedia pada perangkat atau koneksi ini. Pilih foto dari galeri.";
    case "error":
      return "Kamera mengalami kendala. Tutup lalu coba lagi.";
  }
}

export function CameraCaptureDialog({
  isOpen,
  onCapture,
  onClose,
}: Readonly<{
  isOpen: boolean;
  onCapture: (file: File) => void;
  onClose: () => void;
}>) {
  const streamReference = useRef<MediaStream | null>(null);
  const videoReference = useRef<HTMLVideoElement>(null);
  const [state, setState] = useState<CameraState>("opening");

  useEffect(() => {
    if (!isOpen) return;
    let isCurrent = true;
    const video = videoReference.current;
    void (async () => {
      await Promise.resolve();
      if (isCurrent) setState("opening");
      try {
        const stream = await openEnvironmentCamera();
        if (!isCurrent) {
          stopCamera(stream);
          return;
        }
        streamReference.current = stream;
        if (!video) throw new Error("video_unavailable");
        video.srcObject = stream;
        await video.play();
        setState("ready");
      } catch (error) {
        if (isCurrent) setState(mapFailure(error));
      }
    })();
    return () => {
      isCurrent = false;
      stopCamera(streamReference.current);
      streamReference.current = null;
      if (video) video.srcObject = null;
    };
  }, [isOpen]);

  async function capture() {
    try {
      const video = videoReference.current;
      if (!video) throw new Error("video_unavailable");
      onCapture(await captureCameraFrame(video));
      onClose();
    } catch {
      setState("error");
    }
  }

  return (
    <ModalDialog
      description="Kamera hanya digunakan setelah kamu membuka layar ini."
      isOpen={isOpen}
      onClose={onClose}
      title="Ambil foto"
      variant="sheet"
    >
      <div className="camera-capture">
        <video aria-label="Pratinjau kamera foto" muted playsInline ref={videoReference} />
        <p aria-live="polite">{cameraMessage(state)}</p>
        <div className="media-action-row">
          <AppButton disabled={state !== "ready"} onClick={() => void capture()}>
            Ambil foto
          </AppButton>
          <AppButton onClick={onClose} variant="secondary">
            Batal
          </AppButton>
        </div>
      </div>
    </ModalDialog>
  );
}
