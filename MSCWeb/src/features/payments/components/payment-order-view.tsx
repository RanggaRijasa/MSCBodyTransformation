"use client";

import Image from "next/image";
import { useRef, useState } from "react";
import { useRouter } from "next/navigation";

import type { PaymentOrder } from "@/domain/payments/payment";
import { ImageAcquisition } from "@/features/device-media";
import { PaymentStatus } from "@/features/payments/components/payment-status";
import type { ProcessedBrowserImage } from "@/infrastructure/browser-media/browser-image-processor";
import {
  createProgramDateTimeFormatter,
  formatCurrencyIDR,
  programTimezoneLabel,
} from "@/shared/formatting/indonesian-formatters";
import { AppButton } from "@/shared/ui/controls/actions";
import { Surface } from "@/shared/ui/surfaces/surfaces";

function deadline(order: PaymentOrder): string | null {
  const value = order.correctionExpiresAt ?? order.reservationExpiresAt;
  return value
    ? `${createProgramDateTimeFormatter(order.timezone).format(new Date(value))} ${programTimezoneLabel(order.timezone)}`
    : null;
}

export function PaymentOrderView({ initialOrder }: Readonly<{ initialOrder: PaymentOrder }>) {
  const router = useRouter();
  const uploadIdempotencyKey = useRef(crypto.randomUUID());
  const [image, setImage] = useState<ProcessedBrowserImage | null>(null);
  const [isUploading, setUploading] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const canUpload = new Set(["awaiting_evidence", "correction_required"]).has(initialOrder.status);
  const paymentDeadline = deadline(initialOrder);

  async function upload() {
    if (!image || isUploading) return;
    if (!navigator.onLine) {
      setMessage("Kamu sedang offline. Sambungkan perangkat lalu coba lagi.");
      return;
    }
    setUploading(true);
    setMessage(null);
    try {
      const body = new FormData();
      body.set("evidence", image.fullImage, "bukti-transfer.jpg");
      body.set("idempotencyKey", uploadIdempotencyKey.current);
      const response = await fetch(`/api/payments/${initialOrder.id}/evidence`, {
        body,
        cache: "no-store",
        method: "POST",
      });
      const result = (await response.json()) as { message?: string };
      if (!response.ok) throw new Error(result.message ?? "Bukti belum dapat dikirim.");
      setImage(null);
      router.refresh();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Bukti belum dapat dikirim.");
    } finally {
      setUploading(false);
    }
  }

  return (
    <div className="payment-page">
      <header className="payment-page__header">
        <p className="program-eyebrow">Transfer manual</p>
        <h1>Instruksi pembayaran</h1>
        <PaymentStatus status={initialOrder.status} />
      </header>

      <Surface className="payment-instructions" elevated>
        <dl>
          <div>
            <dt>Nominal tepat</dt>
            <dd className="monospaced-numeric">
              {formatCurrencyIDR.format(Number(initialOrder.amountMinor))}
            </dd>
          </div>
          <div>
            <dt>Bank</dt>
            <dd>{initialOrder.bankName}</dd>
          </div>
          <div>
            <dt>Nama pemilik</dt>
            <dd>{initialOrder.accountName}</dd>
          </div>
          <div>
            <dt>Nomor rekening</dt>
            <dd className="monospaced-numeric">{initialOrder.accountReference}</dd>
          </div>
          {paymentDeadline ? (
            <div>
              <dt>Batas pengiriman bukti</dt>
              <dd>{paymentDeadline}</dd>
            </div>
          ) : null}
        </dl>
        <p>
          Transfer diperiksa manual oleh Admin. Status belum terverifikasi sebelum pemeriksaan
          selesai.
        </p>
        <p>
          Pembayaran yang telah disetujui bersifat final. Penyelesaian khusus hanya ditangani Admin
          sesuai kebijakan.
        </p>
        {initialOrder.qrisObjectPath ? (
          <div className="payment-qris">
            <Image
              alt="QRIS statis tujuan transfer"
              height={640}
              loading="eager"
              src={`/api/payments/${initialOrder.id}/qris`}
              unoptimized
              width={640}
            />
            <p>QRIS ini hanya sarana transfer manual, bukan verifikasi otomatis.</p>
          </div>
        ) : null}
      </Surface>

      {initialOrder.status === "under_review" ? (
        <Surface>
          <h2>Menunggu pemeriksaan Admin</h2>
          <p>
            Bukti pembayaranmu sudah diterima. Status akan diperbarui setelah Admin menyelesaikan
            pemeriksaan.
          </p>
        </Surface>
      ) : null}
      {initialOrder.status === "approved" ? (
        <Surface>
          <h2>Pembayaran terverifikasi</h2>
          <p>Akses terkait pembayaran ini telah diproyeksikan oleh server.</p>
        </Surface>
      ) : null}
      {initialOrder.latestRejectionReason ? (
        <Surface className="payment-correction">
          <h2>Perbaiki bukti pembayaran</h2>
          <p>{initialOrder.latestRejectionReason}</p>
        </Surface>
      ) : null}

      {canUpload ? (
        <Surface className="payment-upload">
          <h2>Unggah bukti transfer</h2>
          <p>
            Gunakan JPEG, PNG, WebP, HEIC, atau HEIF. Foto dinormalisasi dan metadata lokasi
            dihapus.
          </p>
          <ImageAcquisition label="Bukti transfer" onProcessed={setImage} />
          <AppButton disabled={!image} isLoading={isUploading} onClick={() => void upload()}>
            Kirim untuk diperiksa
          </AppButton>
        </Surface>
      ) : null}
      {message ? (
        <p className="form-error-summary" role="alert">
          {message}
        </p>
      ) : null}
    </div>
  );
}
