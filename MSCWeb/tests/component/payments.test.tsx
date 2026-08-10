import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";

import type { PaymentOrder } from "@/domain/payments/payment";
import { AdminPaymentDecision } from "@/features/payments/components/admin-payment-decision";
import { AdminPaymentQueue } from "@/features/payments/components/admin-payment-queue";
import { PaymentOrderView } from "@/features/payments/components/payment-order-view";

const refresh = vi.fn();
vi.mock("next/navigation", () => ({ useRouter: () => ({ refresh }) }));
vi.mock("@/features/device-media", () => ({
  ImageAcquisition: ({ label }: { label: string }) => <div aria-label={label}>Pemilih privat</div>,
}));

function order(overrides: Partial<PaymentOrder> = {}): PaymentOrder {
  return {
    accountName: "MSC Lokal",
    accountReference: "1234567890",
    amountMinor: "250000",
    bankName: "Bank Central Asia",
    correctionExpiresAt: null,
    createdAt: "2026-08-10T08:00:00Z",
    currency: "IDR",
    evidenceAttempts: [],
    id: "00000000-0000-4000-8000-000000000601",
    latestRejectionReason: null,
    programId: "00000000-0000-4000-8000-000000000501",
    purpose: "program_enrollment",
    qrisObjectPath: null,
    reservationExpiresAt: "2026-08-11T08:00:00Z",
    status: "awaiting_evidence",
    timezone: "Asia/Makassar",
    version: 1,
    ...overrides,
  };
}

beforeEach(() => refresh.mockReset());

describe("pembayaran manual", () => {
  it("menampilkan snapshot rekening, nominal, timezone, dan copy belum terverifikasi", () => {
    render(<PaymentOrderView initialOrder={order()} />);
    expect(screen.getByText(/Rp\s*250\.000/)).toBeVisible();
    expect(screen.getByText("Bank Central Asia")).toBeVisible();
    expect(screen.getByText("MSC Lokal")).toBeVisible();
    expect(screen.getByText("1234567890")).toBeVisible();
    expect(screen.getByText(/WITA/)).toBeVisible();
    expect(screen.getByText(/Status belum terverifikasi/)).toBeVisible();
    expect(screen.getByLabelText("Bukti transfer")).toBeVisible();
    expect(screen.queryByRole("button", { name: /refund/i })).not.toBeInTheDocument();
  });

  it("bukti yang sudah dikirim bersifat read-only selama pemeriksaan", () => {
    render(<PaymentOrderView initialOrder={order({ status: "under_review" })} />);
    expect(screen.getByRole("heading", { name: "Menunggu pemeriksaan Admin" })).toBeVisible();
    expect(screen.queryByLabelText("Bukti transfer")).not.toBeInTheDocument();
  });

  it("menampilkan QRIS statis sebagai sarana transfer manual", () => {
    render(
      <PaymentOrderView
        initialOrder={order({ qrisObjectPath: "destinations/example/qris.jpg" })}
      />,
    );
    expect(screen.getByRole("img", { name: "QRIS statis tujuan transfer" })).toBeVisible();
    expect(screen.getByText(/bukan verifikasi otomatis/)).toBeVisible();
  });

  it("menyediakan filter Admin untuk jenis, status, dan rentang tanggal", () => {
    render(
      <AdminPaymentQueue
        filters={{ purpose: "coach_access", status: "under_review" }}
        items={[
          {
            ...order({ purpose: "coach_access", programId: null, status: "under_review" }),
            ownerDisplayName: "Calon Coach",
            ownerEmailHint: "Identitas privat",
            relatedLabel: "Pengajuan Coach Calon Coach",
          },
        ]}
      />,
    );
    expect(screen.getByLabelText("Jenis pembayaran")).toHaveValue("coach_access");
    expect(screen.getByLabelText("Status")).toHaveValue("under_review");
    expect(screen.getByLabelText("Dari tanggal")).toBeVisible();
    expect(screen.getByLabelText("Sampai tanggal")).toBeVisible();
    expect(screen.getByText("Pengajuan Coach Calon Coach")).toBeVisible();
  });

  it("menampilkan alasan koreksi dan membuka satu upload baru", () => {
    render(
      <PaymentOrderView
        initialOrder={order({
          correctionExpiresAt: "2026-08-12T08:00:00Z",
          latestRejectionReason: "Nominal pada mutasi belum cocok. Unggah bukti perbaikan.",
          status: "correction_required",
          version: 2,
        })}
      />,
    );
    expect(screen.getByText(/Nominal pada mutasi belum cocok/)).toBeVisible();
    expect(screen.getByLabelText("Bukti transfer")).toBeVisible();
  });

  it("keputusan Admin memerlukan rekonsiliasi atau alasan", async () => {
    render(<AdminPaymentDecision order={order({ status: "under_review", version: 2 })} />);
    const approve = screen.getByRole("button", { name: "Setujui pembayaran" });
    const reject = screen.getByRole("button", { name: "Tolak dan minta perbaikan" });
    expect(approve).toBeDisabled();
    expect(reject).toBeDisabled();
    await userEvent.type(screen.getByLabelText("Referensi mutasi bank"), "MUTASI-001");
    await userEvent.click(
      screen.getByLabelText("Rekening tujuan pada mutasi cocok dengan snapshot pesanan"),
    );
    expect(approve).toBeEnabled();
    await userEvent.click(approve);
    expect(screen.getByRole("dialog", { name: "Konfirmasi persetujuan" })).toBeVisible();
    expect(screen.getByRole("button", { name: "Konfirmasi dan aktifkan" })).toBeVisible();
    await userEvent.type(
      screen.getByLabelText("Alasan dan instruksi koreksi"),
      "Nominal belum cocok.",
    );
    expect(reject).toBeEnabled();
  });
});
