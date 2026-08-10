import "server-only";

import { createHash } from "node:crypto";

import { sanitizeServerImageUpload } from "@/application/media/server-image-validation";
import { AppError } from "@/domain/errors/app-error";
import type {
  AdminPaymentEvent,
  AdminPaymentLedgerEntry,
  AdminPaymentQueueItem,
  PaymentDestinationSummary,
} from "@/domain/payments/payment";
import type { PaymentRepository } from "@/domain/repositories/payment-repository";
import { failure, success, type Result } from "@/domain/result";
import { getVerifiedSupabaseContext } from "@/infrastructure/supabase/auth/get-verified-actor";
import { createSupabaseServiceClient } from "@/infrastructure/supabase/client/service";
import {
  adminOrderSelect,
  mapAdminOrder,
  mapOrder,
  orderSelect,
  paymentError,
  type UnknownRow,
} from "@/infrastructure/supabase/payments/payment-row-mappers";

async function actorContext() {
  const context = await getVerifiedSupabaseContext();
  return context.isSuccess ? context : failure(context.error);
}

export const supabasePaymentRepository: PaymentRepository = {
  async createCoachOrder(input) {
    const context = await actorContext();
    if (!context.isSuccess) return context;
    const { data, error } = await context.value.supabase.rpc("create_coach_payment_order", {
      request_idempotency_key: input.idempotencyKey,
      target_application_id: input.applicationId,
    });
    if (error) return failure(paymentError(error));
    const row = data as UnknownRow | null;
    if (
      !row ||
      typeof row.order_id !== "string" ||
      row.currency !== "IDR" ||
      row.status !== "awaiting_evidence" ||
      (typeof row.amount_minor !== "string" && typeof row.amount_minor !== "number")
    )
      return failure(new AppError("validation_failed", "Hasil pesanan tidak valid."));
    return success({
      amountMinor: String(row.amount_minor),
      currency: "IDR",
      orderId: row.order_id,
      status: "awaiting_evidence",
    });
  },

  async createProgramOrder(input) {
    const context = await actorContext();
    if (!context.isSuccess) return context;
    const { data, error } = await context.value.supabase.rpc("create_program_payment_order", {
      coach_qr_payload: input.coachQrPayload,
      request_idempotency_key: input.idempotencyKey,
      target_program_id: input.programId,
    });
    if (error) return failure(paymentError(error));
    const row = data as UnknownRow | null;
    if (
      !row ||
      typeof row.order_id !== "string" ||
      row.currency !== "IDR" ||
      row.status !== "awaiting_evidence" ||
      typeof row.reservation_expires_at !== "string" ||
      (typeof row.amount_minor !== "string" && typeof row.amount_minor !== "number")
    )
      return failure(new AppError("validation_failed", "Hasil pesanan tidak valid."));
    return success({
      amountMinor: String(row.amount_minor),
      currency: "IDR",
      orderId: row.order_id,
      reservationExpiresAt: row.reservation_expires_at,
      status: "awaiting_evidence",
    });
  },

  async loadOwnerOrder(orderId) {
    const context = await actorContext();
    if (!context.isSuccess) return context;
    const { data, error } = await context.value.supabase
      .from("payment_orders")
      .select(orderSelect)
      .eq("id", orderId)
      .maybeSingle();
    if (error) return failure(paymentError(error));
    const order = mapOrder(data);
    return order
      ? success(order)
      : failure(new AppError("forbidden", "Pembayaran tidak ditemukan."));
  },

  async uploadEvidence(input) {
    const sanitized = sanitizeServerImageUpload(input.image, input.mimeType);
    if (!sanitized.isSuccess) return sanitized;
    const context = await actorContext();
    if (!context.isSuccess) return context;
    const { data: prepared, error: prepareError } = await context.value.supabase.rpc(
      "prepare_payment_evidence_attempt",
      { request_idempotency_key: input.idempotencyKey, target_order_id: input.orderId },
    );
    if (prepareError) return failure(paymentError(prepareError));
    const preparedRow = prepared as UnknownRow | null;
    if (
      !preparedRow ||
      typeof preparedRow.attempt_id !== "string" ||
      typeof preparedRow.object_path !== "string"
    )
      return failure(new AppError("validation_failed", "Tujuan unggahan tidak valid."));
    let storage;
    try {
      storage = createSupabaseServiceClient();
    } catch (error) {
      return failure(error instanceof AppError ? error : paymentError(error));
    }
    const upload = await storage.storage
      .from("payment-evidence")
      .upload(preparedRow.object_path, sanitized.value.bytes, {
        cacheControl: "0",
        contentType: "image/jpeg",
        upsert: false,
      });
    if (upload.error && !upload.error.message.toLowerCase().includes("exists"))
      return failure(paymentError(upload.error));
    const sha256 = createHash("sha256").update(sanitized.value.bytes).digest("hex");
    const { data, error } = await storage.rpc("submit_payment_evidence", {
      content_byte_size: sanitized.value.descriptor.byteSize,
      content_pixel_height: sanitized.value.descriptor.height,
      content_pixel_width: sanitized.value.descriptor.width,
      content_sha256_hex: sha256,
      submitting_owner_user_id: context.value.actor.userId,
      target_attempt_id: preparedRow.attempt_id,
    });
    if (error) {
      if (!upload.error)
        await storage.storage.from("payment-evidence").remove([preparedRow.object_path]);
      return failure(paymentError(error));
    }
    const order = mapOrder(data);
    if (order) return success(order);
    return this.loadOwnerOrder(input.orderId);
  },

  async listAdminQueue(filters = {}) {
    const context = await actorContext();
    if (!context.isSuccess) return context;
    let query = context.value.supabase
      .from("payment_orders")
      .select(adminOrderSelect)
      .order("created_at", { ascending: false })
      .limit(100);
    if (filters.purpose) query = query.eq("purpose", filters.purpose);
    if (filters.status) query = query.eq("status", filters.status);
    if (filters.createdFrom)
      query = query.gte("created_at", `${filters.createdFrom}T00:00:00+07:00`);
    if (filters.createdTo)
      query = query.lte("created_at", `${filters.createdTo}T23:59:59.999+07:00`);
    const { data, error } = await query;
    if (error) return failure(paymentError(error));
    const queue: AdminPaymentQueueItem[] = [];
    for (const raw of data ?? []) {
      const order = mapAdminOrder(raw);
      if (!order)
        return failure(new AppError("validation_failed", "Antrean pembayaran tidak valid."));
      queue.push(order);
    }
    const term = filters.search?.trim().toLocaleLowerCase("id-ID");
    return success(
      term
        ? queue.filter(
            (item) =>
              item.ownerDisplayName.toLocaleLowerCase("id-ID").includes(term) ||
              item.relatedLabel.toLocaleLowerCase("id-ID").includes(term) ||
              item.ownerEmailHint.toLocaleLowerCase("id-ID").includes(term),
          )
        : queue,
    );
  },

  async loadAdminOrder(orderId) {
    const context = await actorContext();
    if (!context.isSuccess) return context;
    const { data, error } = await context.value.supabase
      .from("payment_orders")
      .select(adminOrderSelect)
      .eq("id", orderId)
      .maybeSingle();
    if (error) return failure(paymentError(error));
    const order = mapAdminOrder(data);
    return order
      ? success(order)
      : failure(new AppError("forbidden", "Pembayaran tidak ditemukan."));
  },

  async approve(input) {
    const context = await actorContext();
    if (!context.isSuccess) return context;
    const { data, error } = await context.value.supabase.rpc("approve_payment_order", {
      destination_matches: input.destinationMatches,
      expected_version: input.version,
      reconciled_amount_minor: input.amountMinor,
      reconciliation_reference: input.reconciliationReference,
      target_order_id: input.orderId,
    });
    if (error) return failure(paymentError(error));
    const order = mapOrder(data);
    return order ? success(order) : this.loadOwnerOrder(input.orderId);
  },

  async reject(input) {
    const context = await actorContext();
    if (!context.isSuccess) return context;
    const { data, error } = await context.value.supabase.rpc("reject_payment_evidence", {
      expected_version: input.version,
      rejection_reason: input.reason,
      target_order_id: input.orderId,
    });
    if (error) return failure(paymentError(error));
    const order = mapOrder(data);
    return order ? success(order) : this.loadOwnerOrder(input.orderId);
  },
};

export async function loadAdminPaymentHistory(orderId: string): Promise<
  Result<
    Readonly<{
      events: readonly AdminPaymentEvent[];
      ledger: readonly AdminPaymentLedgerEntry[];
    }>,
    AppError
  >
> {
  const context = await actorContext();
  if (!context.isSuccess) return context;
  const [eventsResult, ledgerResult] = await Promise.all([
    context.value.supabase
      .from("payment_events")
      .select("id,event_type,created_at")
      .eq("order_id", orderId)
      .order("id"),
    context.value.supabase
      .from("payment_ledger")
      .select(
        "entry_kind,amount_minor,reconciliation_reference,verified_at,resolution_due_at,resolution_note",
      )
      .eq("order_id", orderId)
      .order("verified_at"),
  ]);
  if (eventsResult.error || ledgerResult.error)
    return failure(paymentError(eventsResult.error ?? ledgerResult.error));
  const events: AdminPaymentEvent[] = (eventsResult.data ?? []).flatMap((row) =>
    typeof row.id === "number" &&
    typeof row.event_type === "string" &&
    typeof row.created_at === "string"
      ? [{ createdAt: row.created_at, id: String(row.id), type: row.event_type }]
      : [],
  );
  const ledger: AdminPaymentLedgerEntry[] = (ledgerResult.data ?? []).flatMap((row) =>
    (row.entry_kind === "verified" || row.entry_kind === "reversal") &&
    typeof row.reconciliation_reference === "string" &&
    typeof row.verified_at === "string"
      ? [
          {
            amountMinor: String(row.amount_minor),
            kind: row.entry_kind,
            reconciliationReference: row.reconciliation_reference,
            resolutionDueAt:
              typeof row.resolution_due_at === "string" ? row.resolution_due_at : null,
            resolutionNote: typeof row.resolution_note === "string" ? row.resolution_note : null,
            verifiedAt: row.verified_at,
          },
        ]
      : [],
  );
  return success({ events, ledger });
}

export async function listPaymentDestinations(): Promise<
  Result<readonly PaymentDestinationSummary[], AppError>
> {
  const context = await actorContext();
  if (!context.isSuccess) return context;
  const { data, error } = await context.value.supabase
    .from("payment_destinations")
    .select(
      "id,version,bank_name,account_name,account_reference,effective_from,effective_until,status",
    )
    .order("version", { ascending: false })
    .limit(20);
  if (error) return failure(paymentError(error));
  const destinations: PaymentDestinationSummary[] = (data ?? []).flatMap((row) =>
    typeof row.id === "string" &&
    typeof row.version === "number" &&
    typeof row.bank_name === "string" &&
    typeof row.account_name === "string" &&
    typeof row.account_reference === "string" &&
    typeof row.effective_from === "string" &&
    (row.status === "active" || row.status === "scheduled" || row.status === "retired")
      ? [
          {
            accountName: row.account_name,
            accountReference: row.account_reference,
            bankName: row.bank_name,
            effectiveFrom: row.effective_from,
            effectiveUntil: typeof row.effective_until === "string" ? row.effective_until : null,
            id: row.id,
            status: row.status,
            version: row.version,
          },
        ]
      : [],
  );
  return success(destinations);
}

export async function downloadLatestPaymentEvidence(
  orderId: string,
): Promise<Result<Readonly<{ bytes: Uint8Array; mimeType: "image/jpeg" }>, AppError>> {
  const context = await actorContext();
  if (!context.isSuccess) return context;
  const { data, error } = await context.value.supabase
    .from("payment_evidence_attempts")
    .select("object_path, payment_orders!inner(id)")
    .eq("order_id", orderId)
    .in("status", ["submitted", "rejected", "approved"])
    .order("attempt_number", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (error || !data || typeof data.object_path !== "string")
    return failure(new AppError("forbidden", "Bukti pembayaran tidak ditemukan."));
  let storage;
  try {
    storage = createSupabaseServiceClient();
  } catch (serviceError) {
    return failure(serviceError instanceof AppError ? serviceError : paymentError(serviceError));
  }
  const download = await storage.storage.from("payment-evidence").download(data.object_path);
  if (download.error) return failure(paymentError(download.error));
  return success({
    bytes: new Uint8Array(await download.data.arrayBuffer()),
    mimeType: "image/jpeg",
  });
}

export async function downloadPaymentQris(
  orderId: string,
): Promise<Result<Readonly<{ bytes: Uint8Array; mimeType: "image/jpeg" }>, AppError>> {
  const order = await supabasePaymentRepository.loadOwnerOrder(orderId);
  if (!order.isSuccess || !order.value.qrisObjectPath)
    return failure(new AppError("forbidden", "QRIS pembayaran tidak ditemukan."));
  let storage;
  try {
    storage = createSupabaseServiceClient();
  } catch (error) {
    return failure(error instanceof AppError ? error : paymentError(error));
  }
  const download = await storage.storage
    .from("payment-destination-assets")
    .download(order.value.qrisObjectPath);
  if (download.error) return failure(paymentError(download.error));
  return success({
    bytes: new Uint8Array(await download.data.arrayBuffer()),
    mimeType: "image/jpeg",
  });
}
