import { AppError } from "@/domain/errors/app-error";

export type CameraFailureKind =
  "insecure_context" | "permission_denied" | "camera_unavailable" | "camera_busy" | "unknown";

export class CameraFailure extends AppError {
  readonly kind: CameraFailureKind;

  constructor(kind: CameraFailureKind, message: string, cause?: unknown) {
    super(kind === "permission_denied" ? "forbidden" : "unknown", message, { cause });
    this.kind = kind;
  }
}

function mapCameraError(error: unknown): CameraFailure {
  if (error instanceof DOMException) {
    if (error.name === "NotAllowedError" || error.name === "SecurityError") {
      return new CameraFailure(
        "permission_denied",
        "Akses kamera ditolak. Izinkan kamera di pengaturan browser, lalu coba lagi.",
        error,
      );
    }
    if (error.name === "NotFoundError" || error.name === "OverconstrainedError") {
      return new CameraFailure("camera_unavailable", "Kamera yang sesuai tidak ditemukan.", error);
    }
    if (error.name === "NotReadableError" || error.name === "AbortError") {
      return new CameraFailure("camera_busy", "Kamera sedang digunakan aplikasi lain.", error);
    }
  }
  return new CameraFailure("unknown", "Kamera belum dapat dibuka.", error);
}

export async function openEnvironmentCamera(): Promise<MediaStream> {
  if (!window.isSecureContext || !navigator.mediaDevices?.getUserMedia) {
    throw new CameraFailure(
      "insecure_context",
      "Kamera hanya tersedia melalui koneksi HTTPS yang aman.",
    );
  }
  try {
    return await navigator.mediaDevices.getUserMedia({
      audio: false,
      video: { facingMode: { ideal: "environment" } },
    });
  } catch (error) {
    throw mapCameraError(error);
  }
}

export function stopCamera(stream: MediaStream | null): void {
  stream?.getTracks().forEach((track) => track.stop());
}

export async function captureCameraFrame(video: HTMLVideoElement): Promise<File> {
  if (video.videoWidth <= 0 || video.videoHeight <= 0) {
    throw new CameraFailure("camera_unavailable", "Pratinjau kamera belum siap.");
  }
  const canvas = document.createElement("canvas");
  canvas.width = video.videoWidth;
  canvas.height = video.videoHeight;
  const context = canvas.getContext("2d", { alpha: false });
  if (!context) throw new CameraFailure("unknown", "Foto belum dapat diambil.");
  context.drawImage(video, 0, 0);
  const blob = await new Promise<Blob | null>((resolve) =>
    canvas.toBlob(resolve, "image/jpeg", 0.92),
  );
  if (!blob) throw new CameraFailure("unknown", "Foto belum dapat diambil.");
  return new File([blob], "foto-kamera.jpg", { lastModified: Date.now(), type: "image/jpeg" });
}
