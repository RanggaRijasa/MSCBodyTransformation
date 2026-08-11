import "server-only";

import { createHash } from "node:crypto";

import { AppError } from "@/domain/errors/app-error";
import { failure, success, type Result } from "@/domain/result";
import type { VerifiedSupabaseContext } from "@/infrastructure/supabase/auth/get-verified-actor";

export type RateLimitedOperation =
  | "admin_search"
  | "payment_order"
  | "payment_review"
  | "push_subscription"
  | "qr_validation"
  | "submission"
  | "upload";

function opaqueSubject(subject: string): string {
  return createHash("sha256").update(subject.slice(0, 512), "utf8").digest("hex");
}

export async function consumeAuthenticatedRateLimit(
  context: VerifiedSupabaseContext,
  operation: RateLimitedOperation,
  subject: string,
): Promise<Result<Readonly<{ remaining: number }>, AppError>> {
  const { data, error } = await context.supabase.rpc("consume_web_rate_limit", {
    target_operation: operation,
    target_subject_hash: opaqueSubject(subject || operation),
  });
  if (error) {
    const providerMessage = error.message ?? "";
    if (/rate_limit_exceeded/i.test(providerMessage)) {
      return failure(
        new AppError("conflict", "Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi."),
      );
    }
    return failure(new AppError("unknown", "Permintaan belum dapat diproses."));
  }
  return typeof data === "number"
    ? success({ remaining: data })
    : failure(new AppError("unknown", "Batas permintaan belum dapat diverifikasi."));
}
