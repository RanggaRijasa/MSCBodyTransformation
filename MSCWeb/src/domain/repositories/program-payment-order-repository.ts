import type { AppError } from "@/domain/errors/app-error";
import type { Result } from "@/domain/result";

export type ProgramPaymentOrderPreflight = Readonly<{
  amountMinor: string;
  currency: "IDR";
  orderId: string;
  reservationExpiresAt: string;
  status: "awaiting_evidence";
}>;

export type ProgramPaymentOrderRepository = Readonly<{
  create(
    input: Readonly<{ coachQrPayload: string; idempotencyKey: string; programId: string }>,
  ): Promise<Result<ProgramPaymentOrderPreflight, AppError>>;
}>;
