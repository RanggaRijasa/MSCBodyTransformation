"use client";

import { useCallback, useEffect, useRef, useState } from "react";

import { parseCoachQrUrl, type OpaqueCoachQrPayload } from "@/domain/media/qr-payload";
import {
  browserQrDecoder,
  type QrDecoder,
  type QrScannerSession,
} from "@/infrastructure/qr/browser-qr-decoder";
import { AppButton } from "@/shared/ui/controls/actions";
import { ModalDialog } from "@/shared/ui/overlays/modal-dialog";

type ScannerState = "checking" | "scanning" | "permission_denied" | "unavailable" | "error";

type QrScannerDialogProperties = Readonly<{
  decoder?: QrDecoder;
  isOpen: boolean;
  onClose: () => void;
  onScan: (payload: OpaqueCoachQrPayload) => void;
}>;

function scannerFailureState(error: unknown): ScannerState {
  const candidate = error as { message?: unknown; name?: unknown } | null;
  const message =
    candidate && typeof candidate === "object"
      ? `${String(candidate.name ?? "")} ${String(candidate.message ?? "")}`.toLowerCase()
      : "";
  return /denied|notallowed|permission/.test(message) ? "permission_denied" : "error";
}

function stateMessage(state: ScannerState): string {
  switch (state) {
    case "checking":
      return "Memeriksa kamera…";
    case "scanning":
      return "Arahkan kamera ke QR Coach.";
    case "permission_denied":
      return "Akses kamera ditolak. Izinkan kamera di pengaturan browser, atau pindai dari gambar QR.";
    case "unavailable":
      return "Kamera tidak tersedia. Kamu tetap dapat memilih gambar QR dari perangkat.";
    case "error":
      return "QR belum dapat dipindai. Coba lagi atau pilih gambar QR yang jelas.";
  }
}

export function QrScannerDialog({
  decoder = browserQrDecoder,
  isOpen,
  onClose,
  onScan,
}: QrScannerDialogProperties) {
  const videoReference = useRef<HTMLVideoElement>(null);
  const sessionReference = useRef<QrScannerSession | null>(null);
  const [state, setState] = useState<ScannerState>("checking");
  const [validationMessage, setValidationMessage] = useState<string | null>(null);

  const acceptRawValue = useCallback(
    (rawValue: string) => {
      const parsed = parseCoachQrUrl(rawValue, [window.location.origin]);
      if (!parsed.isSuccess) {
        setValidationMessage("QR ini bukan QR Coach MSC yang valid.");
        return;
      }
      sessionReference.current?.stop();
      onScan(parsed.value);
      onClose();
    },
    [onClose, onScan],
  );

  useEffect(() => {
    if (!isOpen) return;
    let isCurrent = true;

    void (async () => {
      await Promise.resolve();
      if (isCurrent) {
        setState("checking");
        setValidationMessage(null);
      }
      try {
        if (!(await decoder.hasCamera())) {
          if (isCurrent) setState("unavailable");
          return;
        }
        const video = videoReference.current;
        if (!video) throw new Error("video_unavailable");
        const session = await decoder.createSession(video, acceptRawValue);
        sessionReference.current = session;
        await session.start();
        if (isCurrent) setState("scanning");
        else session.destroy();
      } catch (error) {
        if (isCurrent) setState(scannerFailureState(error));
      }
    })();

    return () => {
      isCurrent = false;
      sessionReference.current?.destroy();
      sessionReference.current = null;
    };
  }, [acceptRawValue, decoder, isOpen]);

  async function scanSelectedImage(file: File | undefined) {
    if (!file) return;
    setValidationMessage(null);
    try {
      acceptRawValue(await decoder.scanImage(file));
    } catch {
      setValidationMessage("QR tidak ditemukan pada gambar. Pilih gambar lain yang lebih jelas.");
    }
  }

  return (
    <ModalDialog
      description="Kamera hanya aktif selama pemindai terbuka. Tidak ada kode Coach yang dapat diketik."
      isOpen={isOpen}
      onClose={onClose}
      title="Pindai QR Coach"
      variant="sheet"
    >
      <div className="qr-scanner">
        <div className="qr-scanner__preview">
          <video aria-label="Pratinjau kamera QR" muted playsInline ref={videoReference} />
          <span aria-hidden="true" className="qr-scanner__frame" />
        </div>
        <p aria-live="polite" className="qr-scanner__status">
          {stateMessage(state)}
        </p>
        {validationMessage ? (
          <p className="form-error-summary" role="alert">
            {validationMessage}
          </p>
        ) : null}
        <label className="app-action app-action--secondary qr-scanner__file-action">
          <span>Pilih gambar QR</span>
          <input
            accept="image/jpeg,image/png,image/webp,image/heic,image/heif"
            onChange={(event) => {
              void scanSelectedImage(event.target.files?.[0]);
              event.currentTarget.value = "";
            }}
            type="file"
          />
        </label>
        <AppButton onClick={onClose} variant="secondary">
          Tutup pemindai
        </AppButton>
      </div>
    </ModalDialog>
  );
}
