import type { AppError } from "@/domain/errors/app-error";
import type {
  AdminPaymentQueueFilters,
  AdminPaymentQueueItem,
  PaymentOrder,
} from "@/domain/payments/payment";
import type { Result } from "@/domain/result";

export type PaymentRepository = Readonly<{
  approve(
    input: Readonly<{
      amountMinor: string;
      destinationMatches: boolean;
      orderId: string;
      reconciliationReference: string;
      version: number;
    }>,
  ): Promise<Result<PaymentOrder, AppError>>;
  createProgramOrder(
    input: Readonly<{
      coachQrPayload: string;
      idempotencyKey: string;
      programId: string;
    }>,
  ): Promise<
    Result<
      Readonly<{
        amountMinor: string;
        currency: "IDR";
        orderId: string;
        reservationExpiresAt: string;
        status: "awaiting_evidence";
      }>,
      AppError
    >
  >;
  createCoachOrder(input: Readonly<{ applicationId: string; idempotencyKey: string }>): Promise<
    Result<
      Readonly<{
        amountMinor: string;
        currency: "IDR";
        orderId: string;
        status: "awaiting_evidence";
      }>,
      AppError
    >
  >;
  listAdminQueue(
    filters?: AdminPaymentQueueFilters,
  ): Promise<Result<readonly AdminPaymentQueueItem[], AppError>>;
  loadAdminOrder(orderId: string): Promise<Result<AdminPaymentQueueItem, AppError>>;
  loadOwnerOrder(orderId: string): Promise<Result<PaymentOrder, AppError>>;
  reject(
    input: Readonly<{
      orderId: string;
      reason: string;
      version: number;
    }>,
  ): Promise<Result<PaymentOrder, AppError>>;
  uploadEvidence(
    input: Readonly<{
      idempotencyKey: string;
      image: Uint8Array;
      mimeType: string;
      orderId: string;
    }>,
  ): Promise<Result<PaymentOrder, AppError>>;
}>;
