import "server-only";

const allowedEvents = new Set([
  "push_subscription_registered",
  "push_subscription_revoked",
  "request_origin_rejected",
]);
const correlationPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export function emitSafeOperationalEvent(
  input: Readonly<{
    correlationId: string;
    event: string;
    value?: number;
  }>,
) {
  if (!allowedEvents.has(input.event) || !correlationPattern.test(input.correlationId)) return;
  const payload = {
    correlationId: input.correlationId,
    event: input.event,
    ...(Number.isFinite(input.value) ? { value: input.value } : {}),
  };
  console.info(JSON.stringify(payload));
}
