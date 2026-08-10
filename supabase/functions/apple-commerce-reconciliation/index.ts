import {
  fetchAppleTransactionHistory,
  loadAppleServerAPIConfiguration,
} from "../_shared/apple_server_api.ts";
import {
  AppleSignedDataVerifier,
  type VerifiedAppleTransaction,
} from "../_shared/apple_verifier.ts";
import {
  callServiceRPC,
  errorResponse,
  jsonResponse,
  loadCommerceConfiguration,
} from "../_shared/commerce_http.ts";
import { isAuthorizedServiceRequest } from "../_shared/supabase_keys.ts";

type ClaimedTransaction = {
  transaction_id: string;
  environment: "sandbox" | "production";
};

export default {
  async fetch(request: Request): Promise<Response> {
    if (request.method !== "POST") {
      return errorResponse(new Error("method_not_allowed"));
    }
    try {
      const configuration = loadCommerceConfiguration();
      if (!isAuthorizedServiceRequest(request, configuration.secretKey)) {
        throw new Error("authentication_required");
      }
      const appleAPI = loadAppleServerAPIConfiguration(
        configuration.environment,
      );
      const claimed = await callServiceRPC<ClaimedTransaction[]>(
        configuration,
        "claim_apple_commerce_reconciliation_batch",
        { target_environment: appleAPI.environment, batch_size: 20 },
      );
      const verifier = new AppleSignedDataVerifier(configuration.environment);
      let reconciled = 0;
      let deferred = 0;
      for (const candidate of claimed ?? []) {
        try {
          const signedTransactions = await fetchAppleTransactionHistory(
            appleAPI,
            candidate.transaction_id,
          );
          let matched: VerifiedAppleTransaction | null = null;
          for (const signedTransaction of signedTransactions) {
            const transaction = await verifier.verifyNotificationTransaction(
              signedTransaction,
            );
            if (transaction.transactionID === candidate.transaction_id) {
              matched = transaction;
            }
          }
          if (!matched) throw new Error("transaction_not_found");
          const event = reconciliationEvent(matched);
          await callServiceRPC(configuration, "reconcile_apple_commerce_event", {
            target_external_transaction_id: matched.transactionID,
            target_environment: matched.environment,
            target_external_event_id:
              `server-api:${event.type}:${matched.signedPayloadHash}`,
            target_event_type: event.type,
            target_event_at: event.at,
            target_signed_payload_hash: matched.signedPayloadHash,
            target_decoded_fields: {
              source: "app_store_server_api",
              original_transaction_id: matched.originalTransactionID,
            },
          });
          await complete(configuration, candidate, true, null);
          reconciled += 1;
        } catch (error) {
          await complete(
            configuration,
            candidate,
            false,
            sanitizedErrorCode(error),
          );
          deferred += 1;
        }
      }
      return jsonResponse(200, { reconciled, deferred });
    } catch (error) {
      return errorResponse(error);
    }
  },
};

function reconciliationEvent(
  transaction: VerifiedAppleTransaction,
): { type: "verified" | "refund" | "revoke" | "expired"; at: string } {
  if (transaction.revocationAt) {
    return {
      type: transaction.revocationReason === "refund" ? "refund" : "revoke",
      at: transaction.revocationAt,
    };
  }
  if (
    transaction.expiresAt &&
    Date.parse(transaction.expiresAt) <= Date.now()
  ) {
    return { type: "expired", at: transaction.expiresAt };
  }
  return { type: "verified", at: transaction.signedAt };
}

async function complete(
  configuration: ReturnType<typeof loadCommerceConfiguration>,
  transaction: ClaimedTransaction,
  succeeded: boolean,
  errorCode: string | null,
): Promise<void> {
  await callServiceRPC<void>(
    configuration,
    "complete_apple_commerce_reconciliation",
    {
      target_external_transaction_id: transaction.transaction_id,
      target_environment: transaction.environment,
      succeeded,
      error_code: errorCode,
    },
  );
}

function sanitizedErrorCode(error: unknown): string {
  const candidate = error instanceof Error ? error.message : "unknown";
  const allowed = new Set([
    "apple_server_api_pagination_invalid",
    "apple_server_api_pagination_limit",
    "purchase_unverified",
    "transaction_mismatch",
    "transaction_not_found",
  ]);
  return allowed.has(candidate) ? candidate : "apple_server_api_unavailable";
}
