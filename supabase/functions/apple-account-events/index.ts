import {
  appleIdentityErrorResponse,
  callAppleServiceRPC,
  loadAppleIdentityConfiguration,
  sha256Hex,
  verifyAppleAccountEvent,
} from "../_shared/apple_identity.ts";
import { deleteAccountFromAppleEvent } from "../_shared/apple_account_cleanup.ts";
import { readLimitedText } from "../_shared/http_safety.ts";

type RecordedEvent = {
  inserted: boolean;
  account_id: string | null;
  requires_deletion: boolean;
};

export default {
  async fetch(request: Request): Promise<Response> {
    if (request.method !== "POST") {
      return appleIdentityErrorResponse(new Error("method_not_allowed"));
    }
    try {
      const rawBody = await readLimitedText(request, 16_384);
      const body = JSON.parse(rawBody) as { payload?: string };
      if (!body.payload || body.payload.length > 12_000) {
        throw new Error("request_invalid");
      }
      const configuration = loadAppleIdentityConfiguration();
      const event = await verifyAppleAccountEvent(configuration, body.payload);
      const recorded = await callAppleServiceRPC<RecordedEvent>(
        configuration,
        "record_apple_account_event",
        {
          target_event_jti: event.jti,
          target_event_type: event.type,
          target_apple_subject_hash: await sha256Hex(event.subject),
          target_event_time: event.eventTime.toISOString(),
        },
      );
      if (!recorded.inserted) {
        return new Response(null, {
          status: 204,
          headers: { "Cache-Control": "no-store" },
        });
      }
      if (recorded.requires_deletion && recorded.account_id) {
        try {
          await deleteAccountFromAppleEvent(configuration, recorded.account_id);
          await completeEvent(configuration, event.jti, true, null, false);
        } catch (error) {
          const code = error instanceof Error
            ? error.message
            : "apple_account_event_failed";
          const manual = code === "admin_account_deletion_not_allowed" ||
            code === "account_relationships_require_transfer";
          await completeEvent(configuration, event.jti, false, code, manual);
        }
      } else {
        await completeEvent(configuration, event.jti, true, null, false);
      }
      // A verified event is durably recorded before processing. Return 2xx so
      // Apple does not create a duplicate retry storm; internal retry state is
      // handled by apple-identity-reconciliation.
      return new Response(null, {
        status: 204,
        headers: { "Cache-Control": "no-store" },
      });
    } catch (error) {
      return appleIdentityErrorResponse(error);
    }
  },
};

async function completeEvent(
  configuration: ReturnType<typeof loadAppleIdentityConfiguration>,
  eventJTI: string,
  succeeded: boolean,
  errorCode: string | null,
  requiresManualAction: boolean,
): Promise<void> {
  await callAppleServiceRPC<void>(
    configuration,
    "complete_apple_account_event",
    {
      target_event_jti: eventJTI,
      succeeded,
      error_code: errorCode,
      requires_manual_action: requiresManualAction,
    },
  );
}
