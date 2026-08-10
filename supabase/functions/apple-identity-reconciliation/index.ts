import {
  appleIdentityErrorResponse,
  callAppleServiceRPC,
  ClaimedAppleCredential,
  loadAppleIdentityConfiguration,
} from "../_shared/apple_identity.ts";
import {
  deleteAccountFromAppleEvent,
  revokeClaimedAppleCredential,
} from "../_shared/apple_account_cleanup.ts";
import { isAuthorizedServiceRequest } from "../_shared/supabase_keys.ts";

type ClaimedEvent = {
  event_jti: string;
  event_type: string;
  account_id: string | null;
  requires_deletion: boolean;
};

export default {
  async fetch(request: Request): Promise<Response> {
    if (request.method !== "POST") {
      return appleIdentityErrorResponse(new Error("method_not_allowed"));
    }
    try {
      const configuration = loadAppleIdentityConfiguration();
      if (!isAuthorizedServiceRequest(request, configuration.secretKey)) {
        throw new Error("authentication_required");
      }
      const credentials = await callAppleServiceRPC<ClaimedAppleCredential[]>(
        configuration,
        "claim_pending_apple_identity_revocations",
        { batch_size: 25 },
      );
      let revoked = 0;
      for (const credential of credentials ?? []) {
        if (await revokeClaimedAppleCredential(configuration, credential)) {
          revoked += 1;
        }
      }

      const events = await callAppleServiceRPC<ClaimedEvent[]>(
        configuration,
        "claim_pending_apple_account_events",
        { batch_size: 25 },
      );
      let processed = 0;
      for (const event of events ?? []) {
        try {
          if (event.requires_deletion && event.account_id) {
            await deleteAccountFromAppleEvent(configuration, event.account_id);
          }
          await completeEvent(configuration, event, true, null, false);
          processed += 1;
        } catch (error) {
          const code = error instanceof Error
            ? error.message
            : "apple_account_event_failed";
          await completeEvent(
            configuration,
            event,
            false,
            code,
            code === "admin_account_deletion_not_allowed" ||
              code === "account_relationships_require_transfer",
          );
        }
      }
      return new Response(JSON.stringify({ revoked, processed }), {
        status: 200,
        headers: {
          "Content-Type": "application/json",
          "Cache-Control": "no-store",
        },
      });
    } catch (error) {
      return appleIdentityErrorResponse(error);
    }
  },
};

async function completeEvent(
  configuration: ReturnType<typeof loadAppleIdentityConfiguration>,
  event: ClaimedEvent,
  succeeded: boolean,
  errorCode: string | null,
  requiresManualAction: boolean,
): Promise<void> {
  await callAppleServiceRPC<void>(
    configuration,
    "complete_apple_account_event",
    {
      target_event_jti: event.event_jti,
      succeeded,
      error_code: errorCode,
      requires_manual_action: requiresManualAction,
    },
  );
}
