import "server-only";

import { AppError } from "@/domain/errors/app-error";
import { failure, success, type Result } from "@/domain/result";
import { getVerifiedSupabaseContext } from "@/infrastructure/supabase/auth/get-verified-actor";
import { consumeAuthenticatedRateLimit } from "@/application/security/authenticated-rate-limit";

const base64UrlPattern = /^[A-Za-z0-9_-]+$/;

export type PushUserAgentFamily =
  "android_chrome" | "desktop_chromium" | "desktop_safari" | "ios_safari" | "other";

export type PushSubscriptionInput = Readonly<{
  authSecret: string;
  endpoint: string;
  p256dh: string;
  userAgentFamily: PushUserAgentFamily;
}>;

function validate(input: PushSubscriptionInput): AppError | null {
  try {
    const endpoint = new URL(input.endpoint);
    if (endpoint.protocol !== "https:" || input.endpoint.length > 2048)
      throw new TypeError("endpoint");
  } catch {
    return new AppError("validation_failed", "Subscription push tidak valid.");
  }
  if (
    !base64UrlPattern.test(input.p256dh) ||
    !base64UrlPattern.test(input.authSecret) ||
    input.p256dh.length < 32 ||
    input.authSecret.length < 8
  )
    return new AppError("validation_failed", "Kunci subscription push tidak valid.");
  return null;
}

function pushError(error: unknown): AppError {
  const message = error instanceof Error ? error.message : String(error);
  if (/rate_limit_exceeded/i.test(message))
    return new AppError("conflict", "Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.");
  return new AppError("unknown", "Pengaturan notifikasi belum dapat disimpan.");
}

export async function registerPushSubscriptionOperation(
  input: PushSubscriptionInput,
): Promise<Result<Readonly<{ subscriptionId: string }>, AppError>> {
  const invalid = validate(input);
  if (invalid) return failure(invalid);
  const context = await getVerifiedSupabaseContext();
  if (!context.isSuccess) return failure(context.error);

  const limit = await consumeAuthenticatedRateLimit(
    context.value,
    "push_subscription",
    input.endpoint,
  );
  if (!limit.isSuccess) return limit;

  const result = await context.value.supabase.rpc("register_my_web_push_subscription", {
    target_auth_secret: input.authSecret,
    target_endpoint: input.endpoint,
    target_p256dh: input.p256dh,
    target_user_agent_family: input.userAgentFamily,
  });
  if (result.error || typeof result.data !== "string") return failure(pushError(result.error));
  return success({ subscriptionId: result.data });
}

export async function revokePushSubscriptionOperation(
  endpoint: string,
): Promise<Result<Readonly<{ revoked: boolean }>, AppError>> {
  const invalid = validate({
    authSecret: "abcdefgh",
    endpoint,
    p256dh: "abcdefghijklmnopqrstuvwxyzABCDEFGH",
    userAgentFamily: "other",
  });
  if (invalid) return failure(invalid);
  const context = await getVerifiedSupabaseContext();
  if (!context.isSuccess) return failure(context.error);
  const limit = await consumeAuthenticatedRateLimit(context.value, "push_subscription", endpoint);
  if (!limit.isSuccess) return limit;
  const result = await context.value.supabase.rpc("revoke_my_web_push_subscription", {
    target_endpoint: endpoint,
  });
  if (result.error || typeof result.data !== "boolean") return failure(pushError(result.error));
  return success({ revoked: result.data });
}
