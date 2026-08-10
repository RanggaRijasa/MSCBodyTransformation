import {
  authenticateCommerceUser,
  callServiceRPC,
  callUserRPC,
  errorResponse,
  isUUID,
  jsonResponse,
  loadCommerceConfiguration,
  requestAuthorization,
  requireIdempotencyKey,
} from "../_shared/commerce_http.ts";
import { readLimitedJSON } from "../_shared/http_safety.ts";
import {
  AppleSignedDataVerifier,
  type PurchaseIntentVerificationContext,
  type VerifiedAppleTransaction,
} from "../_shared/apple_verifier.ts";

type PurchaseIntentRow = {
  purchase_intent_id: string;
  subject_kind: "program" | "coach_access";
  product_id: string;
  app_account_token: string;
  environment: "xcode" | "local_testing" | "sandbox" | "production";
  expires_at: string;
  status: string;
  program_id?: string;
  coach_id?: string;
  coach_application_id?: string;
  price_band?: string;
};

type PendingIntentRow = {
  id: string;
  status: string;
  expires_at: string;
};

type CommerceFulfillmentRow = {
  transaction_id: string;
  subject_kind: "program" | "coach_access";
  status: string;
  program_id?: string;
  enrollment_id?: string;
  program_entitlement_id?: string;
  coach_application_id?: string;
  coach_entitlement_id?: string;
  coach_access_starts_at?: string;
  coach_access_ends_at?: string;
  idempotent: boolean;
};

function purchaseIntentResponse(row: PurchaseIntentRow): Response {
  return jsonResponse(200, {
    purchaseIntentId: row.purchase_intent_id,
    subjectKind: row.subject_kind,
    productId: row.product_id,
    appAccountToken: row.app_account_token,
    environment: row.environment,
    expiresAt: row.expires_at,
    status: row.status,
  });
}

function routeParts(request: Request): string[] {
  const parts = new URL(request.url).pathname.split("/").filter(Boolean);
  const commerceIndex = parts.lastIndexOf("commerce");
  return commerceIndex >= 0 ? parts.slice(commerceIndex + 1) : parts;
}

function fulfillmentResponse(result: CommerceFulfillmentRow): Record<string, unknown> {
  return {
    transactionId: result.transaction_id,
    subjectKind: result.subject_kind,
    status: result.status,
    programId: result.program_id ?? null,
    enrollmentId: result.enrollment_id ?? null,
    programEntitlementId: result.program_entitlement_id ?? null,
    coachApplicationId: result.coach_application_id ?? null,
    coachEntitlementId: result.coach_entitlement_id ?? null,
    coachAccessStartsAt: result.coach_access_starts_at ?? null,
    coachAccessEndsAt: result.coach_access_ends_at ?? null,
    idempotent: result.idempotent,
  };
}

function requireExactObject(
  value: unknown,
  requiredKeys: string[],
  optionalKeys: string[] = [],
): Record<string, unknown> {
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    throw new Error("request_invalid");
  }
  const result = value as Record<string, unknown>;
  const allowedKeys = new Set([...requiredKeys, ...optionalKeys]);
  if (
    requiredKeys.some((key) => !(key in result)) ||
    Object.keys(result).some((key) => !allowedKeys.has(key))
  ) {
    throw new Error("request_invalid");
  }
  return result;
}

function commerceTransactionResponse(
  row: Record<string, unknown>,
): Record<string, unknown> {
  return {
    id: row.id,
    subjectKind: row.subject_kind,
    programId: row.program_id ?? null,
    coachApplicationId: row.coach_application_id ?? null,
    provider: row.provider,
    environment: row.environment,
    productId: row.product_id,
    productType: row.product_type,
    status: row.status,
    purchasedAt: row.purchased_at ?? null,
    expiresAt: row.expires_at ?? null,
    revocationAt: row.revocation_at ?? null,
    currencyCode: row.currency_code ?? null,
    priceMilliunits: row.price_milliunits ?? null,
  };
}

async function fulfillVerifiedTransaction(
  configuration: ReturnType<typeof loadCommerceConfiguration>,
  userID: string,
  purchaseIntentID: string,
  transaction: VerifiedAppleTransaction,
): Promise<CommerceFulfillmentRow> {
  return await callServiceRPC<CommerceFulfillmentRow>(
    configuration,
    "fulfill_apple_purchase",
    {
      target_purchase_intent_id: purchaseIntentID,
      caller_account_id: userID,
      target_external_transaction_id: transaction.transactionID,
      target_original_transaction_id: transaction.originalTransactionID,
      verified_product_id: transaction.productID,
      verified_app_account_token: transaction.appAccountToken,
      verified_environment: transaction.environment,
      target_signed_payload_hash: transaction.signedPayloadHash,
      target_purchased_at: transaction.purchasedAt,
      target_signed_at: transaction.signedAt,
      target_expires_at: transaction.expiresAt,
      target_currency_code: transaction.currencyCode,
      target_price_milliunits: transaction.priceMilliunits,
    },
  );
}

export default {
  async fetch(request: Request): Promise<Response> {
    try {
      const authorization = requestAuthorization(request);
      const configuration = loadCommerceConfiguration();
      const userID = await authenticateCommerceUser(
        configuration,
        authorization,
      );
      const parts = routeParts(request);

      if (
        request.method === "POST" && parts.length === 3 &&
        parts[0] === "programs" && parts[2] === "preflight" &&
        isUUID(parts[1])
      ) {
        const idempotencyKey = requireIdempotencyKey(request);
        await callServiceRPC(configuration, "consume_commerce_rate_limit", {
          caller_account_id: userID,
          target_operation: "program_preflight",
        });
        const result = await callServiceRPC<PurchaseIntentRow>(
          configuration,
          "create_program_purchase_intent",
          {
            target_program_id: parts[1],
            caller_account_id: userID,
            target_environment: configuration.environment,
            request_idempotency_key: idempotencyKey,
          },
        );
        return purchaseIntentResponse(result);
      }

      if (
        request.method === "POST" && parts.length === 2 &&
        parts[0] === "coach-access" && parts[1] === "preflight"
      ) {
        const idempotencyKey = requireIdempotencyKey(request);
        await callServiceRPC(configuration, "consume_commerce_rate_limit", {
          caller_account_id: userID,
          target_operation: "coach_preflight",
        });
        const result = await callServiceRPC<PurchaseIntentRow>(
          configuration,
          "create_coach_purchase_intent",
          {
            caller_account_id: userID,
            target_environment: configuration.environment,
            request_idempotency_key: idempotencyKey,
          },
        );
        return purchaseIntentResponse(result);
      }

      if (
        request.method === "POST" && parts.length === 3 &&
        parts[0] === "intents" && parts[2] === "pending" &&
        isUUID(parts[1])
      ) {
        const result = await callServiceRPC<PendingIntentRow>(
          configuration,
          "mark_purchase_intent_pending",
          {
            target_purchase_intent_id: parts[1],
            caller_account_id: userID,
          },
        );
        return jsonResponse(200, {
          purchaseIntentId: result.id,
          status: result.status,
          expiresAt: result.expires_at,
        });
      }

      if (
        request.method === "GET" && parts.length === 1 &&
        parts[0] === "history"
      ) {
        const result = await callUserRPC<Record<string, unknown>[]>(
          configuration,
          "list_my_commerce_history",
          {},
          authorization,
        );
        return jsonResponse(200, {
          transactions: result.map(commerceTransactionResponse),
        });
      }

      if (
        request.method === "POST" && parts.length === 2 &&
        parts[0] === "apple" && parts[1] === "verify"
      ) {
        const body = requireExactObject(
          await readLimitedJSON(request, 131_072),
          ["purchaseIntentId", "signedTransaction"],
        );
        if (
          typeof body.purchaseIntentId !== "string" ||
          !isUUID(body.purchaseIntentId) ||
          typeof body.signedTransaction !== "string"
        ) {
          throw new Error("request_invalid");
        }
        await callServiceRPC(configuration, "consume_commerce_rate_limit", {
          caller_account_id: userID,
          target_operation: "verify",
        });
        const context = await callServiceRPC<PurchaseIntentVerificationContext>(
          configuration,
          "get_purchase_intent_for_verification",
          {
            target_purchase_intent_id: body.purchaseIntentId,
            caller_account_id: userID,
          },
        );
        const verifier = new AppleSignedDataVerifier(configuration.environment);
        const transaction = await verifier.verifyTransaction(
          body.signedTransaction,
          context,
        );
        const result = await fulfillVerifiedTransaction(
          configuration,
          userID,
          body.purchaseIntentId,
          transaction,
        );
        return jsonResponse(200, fulfillmentResponse(result));
      }

      if (
        request.method === "POST" && parts.length === 2 &&
        parts[0] === "apple" && parts[1] === "restore"
      ) {
        const body = requireExactObject(
          await readLimitedJSON(request, 4_194_304),
          ["transactions"],
        );
        if (
          !Array.isArray(body.transactions) ||
          body.transactions.length < 1 || body.transactions.length > 100
        ) {
          throw new Error("request_invalid");
        }
        await callServiceRPC(configuration, "consume_commerce_rate_limit", {
          caller_account_id: userID,
          target_operation: "restore",
        });
        const verifier = new AppleSignedDataVerifier(configuration.environment);
        const results: Record<string, unknown>[] = [];
        for (const rawCandidate of body.transactions) {
          const candidate = requireExactObject(
            rawCandidate,
            ["signedTransaction"],
            ["purchaseIntentId"],
          );
          if (typeof candidate.signedTransaction !== "string") {
            throw new Error("request_invalid");
          }
          const transaction = await verifier.verifyTransaction(
            candidate.signedTransaction,
          );
          if (
            candidate.purchaseIntentId !== undefined &&
            candidate.purchaseIntentId !== null &&
            (typeof candidate.purchaseIntentId !== "string" ||
              !isUUID(candidate.purchaseIntentId))
          ) {
            throw new Error("request_invalid");
          }
          let purchaseIntentID = typeof candidate.purchaseIntentId === "string"
            ? candidate.purchaseIntentId
            : null;
          if (!purchaseIntentID) {
            purchaseIntentID = await callServiceRPC<string>(
              configuration,
              "resolve_purchase_intent_for_restore",
              {
                caller_account_id: userID,
                verified_product_id: transaction.productID,
                verified_app_account_token: transaction.appAccountToken,
                target_environment: transaction.environment,
              },
            );
          }
          const context = await callServiceRPC<PurchaseIntentVerificationContext>(
            configuration,
            "get_purchase_intent_for_verification",
            {
              target_purchase_intent_id: purchaseIntentID,
              caller_account_id: userID,
            },
          );
          const checkedTransaction = await verifier.verifyTransaction(
            candidate.signedTransaction,
            context,
          );
          const fulfillment = await fulfillVerifiedTransaction(
            configuration,
            userID,
            purchaseIntentID,
            checkedTransaction,
          );
          results.push(fulfillmentResponse(fulfillment));
        }
        return jsonResponse(200, { fulfillments: results });
      }

      return errorResponse(new Error("route_not_found"));
    } catch (error) {
      return errorResponse(error);
    }
  },
};
