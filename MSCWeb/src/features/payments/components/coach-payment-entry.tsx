"use client";

import { useRef, useState } from "react";
import { useRouter } from "next/navigation";

import { AppButton } from "@/shared/ui/controls/actions";
import { Surface } from "@/shared/ui/surfaces/surfaces";

export function CoachPaymentEntry({ applicationId }: Readonly<{ applicationId: string }>) {
  const router = useRouter();
  const idempotencyKey = useRef(crypto.randomUUID());
  const [isSubmitting, setSubmitting] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  async function createOrder() {
    setSubmitting(true);
    setMessage(null);
    try {
      const response = await fetch(`/api/coach-applications/${applicationId}/payment-order`, {
        body: JSON.stringify({ idempotencyKey: idempotencyKey.current }),
        cache: "no-store",
        headers: { "Content-Type": "application/json" },
        method: "POST",
      });
      const result = (await response.json()) as { message?: string; orderId?: string };
      if (!response.ok || !result.orderId)
        throw new Error(result.message ?? "Instruksi pembayaran belum dapat dibuat.");
      router.push(`/pembayaran/${result.orderId}`);
    } catch (error) {
      setMessage(
        error instanceof Error ? error.message : "Instruksi pembayaran belum dapat dibuat.",
      );
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <Surface className="payment-upload" elevated>
      <h2>Aktifkan akses Coach</h2>
      <p>
        Kelayakanmu sudah diterima. Buat instruksi transfer untuk periode akses Coach tiga bulan.
      </p>
      <AppButton isLoading={isSubmitting} onClick={() => void createOrder()}>
        Buat instruksi pembayaran
      </AppButton>
      {message ? (
        <p className="form-error-summary" role="alert">
          {message}
        </p>
      ) : null}
    </Surface>
  );
}
