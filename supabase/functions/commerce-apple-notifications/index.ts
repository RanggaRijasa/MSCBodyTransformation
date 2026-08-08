import {
  AppleSignedDataVerifier,
  type VerifiedAppleTransaction,
} from "../_shared/apple_verifier.ts";
import {
  callServiceRPC,
  errorResponse,
  isUUID,
  jsonResponse,
  loadCommerceConfiguration,
} from "../_shared/commerce_http.ts";

type NotificationInboxResult = {
  notification_uuid: string;
  status: "pending" | "processed" | "dead_letter";
  is_duplicate: boolean;
};

function requireExactSignedPayloadBody(value: unknown): string {
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    throw new Error("request_invalid");
  }
  const body = value as Record<string, unknown>;
  if (
    Object.keys(body).length !== 1 ||
    typeof body.signedPayload !== "string" ||
    body.signedPayload.length === 0
  ) {
    throw new Error("request_invalid");
  }
  return body.signedPayload;
}

function notificationEventType(notificationType: string):
  | "refund"
  | "revoke"
  | "expired"
  | "verified"
  | null {
  switch (notificationType) {
    case "REFUND":
      return "refund";
    case "REVOKE":
      return "revoke";
    case "EXPIRED":
      return "expired";
    case "ONE_TIME_CHARGE":
      return "verified";
    default:
      return null;
  }
}

function matchesConfiguredEnvironment(
  payloadEnvironment: unknown,
  configuredEnvironment: "xcode" | "local_testing" | "sandbox" | "production",
): boolean {
  if (typeof payloadEnvironment !== "string") return false;
  const normalizedPayload = payloadEnvironment
    .replaceAll("_", "")
    .toLowerCase();
  const normalizedConfiguration = configuredEnvironment
    .replaceAll("_", "")
    .toLowerCase();
  return normalizedPayload === normalizedConfiguration;
}

export default {
  async fetch(request: Request): Promise<Response> {
    let recordedNotificationUUID: string | null = null;
    try {
      if (request.method !== "POST") {
        throw new Error("method_not_allowed");
      }
      const configuration = loadCommerceConfiguration();

      const signedPayload = requireExactSignedPayloadBody(
        await request.json().catch(() => null),
      );
      const verifier = new AppleSignedDataVerifier(configuration.environment);
      const verifiedNotification = await verifier.verifyNotification(
        signedPayload,
      );
      const payload = verifiedNotification.payload;
      const notificationUUID = payload.notificationUUID;
      const notificationType = payload.notificationType;
      const signedAt = payload.signedDate;
      if (
        typeof notificationUUID !== "string" || !isUUID(notificationUUID) ||
        typeof notificationType !== "string" || notificationType.length === 0 ||
        typeof signedAt !== "number" || !Number.isSafeInteger(signedAt) ||
        !matchesConfiguredEnvironment(
          payload.data?.environment,
          configuration.environment,
        )
      ) {
        throw new Error("purchase_unverified");
      }

      const signedTransaction = payload.data?.signedTransactionInfo;
      let transaction: VerifiedAppleTransaction | null = null;
      if (typeof signedTransaction === "string") {
        transaction = await verifier.verifyNotificationTransaction(
          signedTransaction,
        );
      }

      const inbox = await callServiceRPC<NotificationInboxResult>(
        configuration,
        "record_apple_notification",
        {
          target_notification_uuid: notificationUUID,
          target_environment: configuration.environment,
          target_notification_type: notificationType,
          target_subtype: payload.subtype ?? null,
          target_transaction_id: transaction?.transactionID ?? null,
          target_original_transaction_id:
            transaction?.originalTransactionID ?? null,
          target_signed_at: new Date(signedAt).toISOString(),
          target_signed_payload_hash: verifiedNotification.signedPayloadHash,
          target_decoded_fields: {
            version: payload.version ?? null,
            has_signed_transaction: transaction !== null,
          },
        },
      );
      recordedNotificationUUID = notificationUUID;

      if (inbox.is_duplicate && inbox.status === "processed") {
        return jsonResponse(202, { status: "accepted", duplicate: true });
      }

      const eventType = notificationEventType(notificationType);
      if (eventType && transaction) {
        await callServiceRPC(configuration, "reconcile_apple_commerce_event", {
          target_external_transaction_id: transaction.transactionID,
          target_environment: configuration.environment,
          target_external_event_id: notificationUUID,
          target_event_type: eventType,
          target_event_at: transaction.revocationAt ??
            new Date(signedAt).toISOString(),
          target_signed_payload_hash: verifiedNotification.signedPayloadHash,
          target_decoded_fields: {
            notification_type: notificationType,
            subtype: payload.subtype ?? null,
          },
        });
      }

      await callServiceRPC(configuration, "complete_apple_notification", {
        target_notification_uuid: notificationUUID,
        did_succeed: true,
        target_error_code: null,
      });
      return jsonResponse(202, {
        status: "accepted",
        duplicate: inbox.is_duplicate,
      });
    } catch (error) {
      if (recordedNotificationUUID) {
        try {
          const configuration = loadCommerceConfiguration();
          await callServiceRPC(configuration, "complete_apple_notification", {
            target_notification_uuid: recordedNotificationUUID,
            did_succeed: false,
            target_error_code: "notification_processing_failed",
          });
        } catch {
          // Apple receives a failure response and retries. No signed payload,
          // credential, or backend error detail is written to logs here.
        }
      }
      return errorResponse(error);
    }
  },
};
