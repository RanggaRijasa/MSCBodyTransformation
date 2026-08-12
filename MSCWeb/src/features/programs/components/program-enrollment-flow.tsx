"use client";

import { useRef, useState } from "react";
import { useRouter } from "next/navigation";

import type { CoachPreflight, EnrollmentAvailability } from "@/domain/programs/enrollment";
import type { OpaqueCoachQrPayload } from "@/domain/media/qr-payload";
import { QrScannerDialog } from "@/features/device-media";
import type { QrDecoder } from "@/infrastructure/qr/browser-qr-decoder";
import { AppButton } from "@/shared/ui/controls/actions";
import { StatusBadge } from "@/shared/ui/status/status";
import { Surface } from "@/shared/ui/surfaces/surfaces";

type FlowState = "ready" | "checking" | "coach_confirm" | "submitting" | "complete" | "error";

const availabilityCopy: Readonly<
  Record<Exclude<EnrollmentAvailability, "available">, { description: string; title: string }>
> = {
  already_enrolled: {
    description: "Buka program dari bagian Diikuti.",
    title: "Kamu sudah terdaftar",
  },
  program_full: {
    description: "Tidak ada kursi yang tersedia saat ini.",
    title: "Kapasitas program penuh",
  },
  program_unavailable: {
    description: "Program belum dapat menerima pendaftaran.",
    title: "Pendaftaran tidak tersedia",
  },
  registration_closed: {
    description: "Batas waktu pendaftaran program sudah lewat.",
    title: "Pendaftaran ditutup",
  },
};

export function ProgramEnrollmentFlow({
  availability,
  pricingMode,
  programId,
  programTitle,
  qrDecoder,
}: Readonly<{
  availability: EnrollmentAvailability;
  pricingMode: "free" | "paid";
  programId: string;
  programTitle: string;
  qrDecoder?: QrDecoder;
}>) {
  const router = useRouter();
  const paymentIdempotencyKey = useRef<string | null>(null);
  const [coach, setCoach] = useState<CoachPreflight | null>(null);
  const [coachQrPayload, setCoachQrPayload] = useState<OpaqueCoachQrPayload | null>(null);
  const [isScannerOpen, setScannerOpen] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [state, setState] = useState<FlowState>("ready");

  if (availability !== "available") {
    const copy = availabilityCopy[availability];
    return (
      <Surface className="program-enrollment-state">
        <StatusBadge tone="warning">Tidak tersedia</StatusBadge>
        <h1>{copy.title}</h1>
        <p>{copy.description}</p>
      </Surface>
    );
  }

  async function resolveCoach(payload: OpaqueCoachQrPayload) {
    if (!navigator.onLine) {
      setMessage("Kamu sedang offline. Sambungkan perangkat lalu coba lagi.");
      return;
    }
    setState("checking");
    setMessage(null);
    setCoachQrPayload(payload);
    try {
      const response = await fetch(`/api/programs/${programId}/coach-preflight`, {
        body: JSON.stringify({ coachQrPayload: payload }),
        cache: "no-store",
        headers: { "Content-Type": "application/json" },
        method: "POST",
      });
      const result = (await response.json()) as CoachPreflight & { message?: string };
      if (!response.ok) throw new Error(result.message ?? "QR Coach belum dapat divalidasi.");
      setCoach({ city: result.city, displayName: result.displayName, photoUrl: result.photoUrl });
      setState("coach_confirm");
    } catch (error) {
      setCoachQrPayload(null);
      setState("error");
      setMessage(error instanceof Error ? error.message : "QR Coach belum dapat divalidasi.");
    }
  }

  async function confirmEnrollment() {
    if (!coachQrPayload || !coach || state === "submitting") return;
    if (!navigator.onLine) {
      setMessage("Kamu sedang offline. Sambungkan perangkat lalu coba lagi.");
      return;
    }
    setState("submitting");
    setMessage(null);
    try {
      const isFree = pricingMode === "free";
      paymentIdempotencyKey.current ??= crypto.randomUUID();
      const response = await fetch(
        isFree
          ? `/api/programs/${programId}/enroll/free`
          : `/api/programs/${programId}/payment-order`,
        {
          body: JSON.stringify(
            isFree
              ? { coachQrPayload }
              : { coachQrPayload, idempotencyKey: paymentIdempotencyKey.current },
          ),
          cache: "no-store",
          headers: { "Content-Type": "application/json" },
          method: "POST",
        },
      );
      const result = (await response.json()) as { message?: string; orderId?: string };
      if (!response.ok) throw new Error(result.message ?? "Pendaftaran belum dapat diproses.");
      setCoachQrPayload(null);
      setState("complete");
      if (isFree) {
        router.replace(`/program/${programId}`);
        router.refresh();
      } else if (result.orderId) {
        router.replace(`/pembayaran/${result.orderId}`);
      }
    } catch (error) {
      setState("error");
      setMessage(error instanceof Error ? error.message : "Pendaftaran belum dapat diproses.");
    }
  }

  return (
    <div className="program-enrollment-flow">
      <header>
        <p className="program-eyebrow">Pendaftaran program</p>
        <h1>{programTitle}</h1>
        <p>Pindai QR Coach. Server akan memeriksa Coach, kapasitas, dan batas pendaftaran.</p>
      </header>
      {coach ? (
        <Surface className="program-enrollment-coach">
          <StatusBadge tone="success">Coach valid</StatusBadge>
          <h2>{coach.displayName}</h2>
          <p>{coach.city || "Lokasi tidak dicantumkan"}</p>
          <p>Pastikan ini Coach yang akan mendampingimu.</p>
          <div className="media-action-row">
            <AppButton isLoading={state === "submitting"} onClick={() => void confirmEnrollment()}>
              {pricingMode === "free" ? "Konfirmasi pendaftaran" : "Lanjut ke pembayaran"}
            </AppButton>
            <AppButton
              disabled={state === "submitting"}
              onClick={() => {
                setCoach(null);
                setCoachQrPayload(null);
                setState("ready");
              }}
              variant="secondary"
            >
              Pindai ulang
            </AppButton>
          </div>
        </Surface>
      ) : (
        <AppButton isLoading={state === "checking"} onClick={() => setScannerOpen(true)}>
          Pindai QR Coach
        </AppButton>
      )}
      {pricingMode === "paid" ? (
        <p className="program-enrollment-reservation">
          Pesanan pembayaran yang valid akan mereservasi satu kursi selama 24 jam. Bukti yang
          dikirim sebelum masa reservasi berakhir mempertahankan kursi selama pemeriksaan Admin.
        </p>
      ) : null}
      {message ? (
        <p className="form-error-summary" role="alert">
          {message}
        </p>
      ) : null}
      <QrScannerDialog
        {...(qrDecoder ? { decoder: qrDecoder } : {})}
        isOpen={isScannerOpen}
        onClose={() => setScannerOpen(false)}
        onScan={(payload) => void resolveCoach(payload)}
      />
    </div>
  );
}
