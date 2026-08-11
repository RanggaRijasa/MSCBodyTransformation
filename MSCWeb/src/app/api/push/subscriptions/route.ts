import { NextResponse, type NextRequest } from "next/server";

import { emitSafeOperationalEvent } from "@/application/observability/safe-operational-event";
import {
  registerPushSubscriptionOperation,
  revokePushSubscriptionOperation,
  type PushUserAgentFamily,
} from "@/application/push/push-subscription-operations";
import { hasTrustedMutationOrigin } from "@/shared/security/mutation-origin";

const privateHeaders = { "Cache-Control": "private, no-store, max-age=0" };
const supportedFamilies = new Set<PushUserAgentFamily>([
  "android_chrome",
  "desktop_chromium",
  "desktop_safari",
  "ios_safari",
  "other",
]);

function statusFor(code: string) {
  if (code === "unauthorized") return 401;
  if (code === "validation_failed") return 422;
  if (code === "conflict") return 429;
  return 503;
}

export async function POST(request: NextRequest) {
  if (!hasTrustedMutationOrigin(request))
    return NextResponse.json({ code: "origin_rejected" }, { status: 403, headers: privateHeaders });
  let body: Record<string, unknown>;
  try {
    body = (await request.json()) as Record<string, unknown>;
  } catch {
    return NextResponse.json({ code: "payload_invalid" }, { status: 400, headers: privateHeaders });
  }
  const family = body.userAgentFamily;
  if (
    typeof body.endpoint !== "string" ||
    typeof body.p256dh !== "string" ||
    typeof body.authSecret !== "string" ||
    typeof family !== "string" ||
    !supportedFamilies.has(family as PushUserAgentFamily)
  )
    return NextResponse.json({ code: "payload_invalid" }, { status: 422, headers: privateHeaders });

  const result = await registerPushSubscriptionOperation({
    authSecret: body.authSecret,
    endpoint: body.endpoint,
    p256dh: body.p256dh,
    userAgentFamily: family as PushUserAgentFamily,
  });
  if (result.isSuccess)
    emitSafeOperationalEvent({
      correlationId: request.headers.get("x-msc-correlation-id") ?? "",
      event: "push_subscription_registered",
    });
  return result.isSuccess
    ? NextResponse.json({ status: "active" }, { headers: privateHeaders })
    : NextResponse.json(
        { code: result.error.code, message: result.error.message },
        { status: statusFor(result.error.code), headers: privateHeaders },
      );
}

export async function DELETE(request: NextRequest) {
  if (!hasTrustedMutationOrigin(request))
    return NextResponse.json({ code: "origin_rejected" }, { status: 403, headers: privateHeaders });
  let endpoint: unknown;
  try {
    endpoint = ((await request.json()) as Record<string, unknown>).endpoint;
  } catch {
    endpoint = null;
  }
  if (typeof endpoint !== "string")
    return NextResponse.json({ code: "payload_invalid" }, { status: 422, headers: privateHeaders });
  const result = await revokePushSubscriptionOperation(endpoint);
  if (result.isSuccess)
    emitSafeOperationalEvent({
      correlationId: request.headers.get("x-msc-correlation-id") ?? "",
      event: "push_subscription_revoked",
    });
  return result.isSuccess
    ? new NextResponse(null, { status: 204, headers: privateHeaders })
    : NextResponse.json(
        { code: result.error.code, message: result.error.message },
        { status: statusFor(result.error.code), headers: privateHeaders },
      );
}
