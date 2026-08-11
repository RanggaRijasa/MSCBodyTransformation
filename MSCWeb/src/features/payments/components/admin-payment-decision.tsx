"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

import type { PaymentOrder } from "@/domain/payments/payment";
import { AppButton, Surface } from "@/shared/ui";

export function AdminPaymentDecision({ order }: Readonly<{ order: PaymentOrder }>) {
  const router = useRouter();
  const [amount, setAmount] = useState(order.amountMinor);
  const [destinationMatches, setDestinationMatches] = useState(false);
  const [reference, setReference] = useState("");
  const [reason, setReason] = useState("");
  const [isSubmitting, setSubmitting] = useState(false);
  const [isConfirmingApproval, setConfirmingApproval] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  async function decide(decision: "approve" | "reject") {
    setSubmitting(true);
    setMessage(null);
    try {
      const response = await fetch(`/api/admin/payments/${order.id}/decision`, {
        body: JSON.stringify({
          amountMinor: amount,
          decision,
          destinationMatches,
          reason,
          reconciliationReference: reference,
          version: order.version,
        }),
        cache: "no-store",
        headers: { "Content-Type": "application/json" },
        method: "POST",
      });
      const result = (await response.json()) as { message?: string };
      if (!response.ok) throw new Error(result.message ?? "Keputusan belum dapat disimpan.");
      setConfirmingApproval(false);
      router.refresh();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Keputusan belum dapat disimpan.");
    } finally {
      setSubmitting(false);
    }
  }

  if (order.status !== "under_review") return null;
  return (
    <Surface className="payment-decision">
      <h2>Keputusan Admin</h2>
      <label>
        Nominal pada mutasi
        <input
          inputMode="numeric"
          onChange={(event) => setAmount(event.target.value)}
          value={amount}
        />
      </label>
      <label>
        Referensi mutasi bank
        <input onChange={(event) => setReference(event.target.value)} value={reference} />
      </label>
      <label className="payment-decision__check">
        <input
          checked={destinationMatches}
          onChange={(event) => setDestinationMatches(event.target.checked)}
          type="checkbox"
        />
        Rekening tujuan pada mutasi cocok dengan snapshot pesanan
      </label>
      <label>
        Alasan dan instruksi koreksi
        <textarea onChange={(event) => setReason(event.target.value)} rows={4} value={reason} />
      </label>
      <div className="media-action-row">
        <AppButton
          disabled={!destinationMatches || reference.trim().length < 4}
          isLoading={isSubmitting}
          onClick={() => setConfirmingApproval(true)}
        >
          Setujui pembayaran
        </AppButton>
        <AppButton
          disabled={reason.trim().length < 5}
          isLoading={isSubmitting}
          onClick={() => void decide("reject")}
          variant="destructive"
        >
          Tolak dan minta perbaikan
        </AppButton>
      </div>
      {isConfirmingApproval ? (
        <div
          aria-labelledby="payment-approval-confirmation-title"
          className="payment-confirmation"
          role="dialog"
        >
          <h3 id="payment-approval-confirmation-title">Konfirmasi persetujuan</h3>
          <p>
            Pastikan nominal {amount} dan referensi {reference.trim()} sudah cocok dengan mutasi
            bank. Tindakan ini langsung mengaktifkan akses terkait.
          </p>
          <div className="media-action-row">
            <AppButton isLoading={isSubmitting} onClick={() => void decide("approve")}>
              Konfirmasi dan aktifkan
            </AppButton>
            <AppButton
              disabled={isSubmitting}
              onClick={() => setConfirmingApproval(false)}
              variant="secondary"
            >
              Periksa lagi
            </AppButton>
          </div>
        </div>
      ) : null}
      {message ? (
        <p className="form-error-summary" role="alert">
          {message}
        </p>
      ) : null}
    </Surface>
  );
}
