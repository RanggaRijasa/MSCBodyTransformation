import { fetchWithTimeout } from "./http_safety.ts";
import {
  loadSupabaseRuntimeKeys,
  serviceRequestHeaders,
} from "./supabase_keys.ts";

export type CommerceEnvironment =
  | "xcode"
  | "local_testing"
  | "sandbox"
  | "production";

export type CommerceFunctionConfiguration = {
  projectURL: string;
  publishableKey: string;
  secretKey: string;
  environment: CommerceEnvironment;
};

type SupabaseUser = {
  id?: string;
};

type PostgrestError = {
  message?: string;
};

const jsonHeaders = {
  "Content-Type": "application/json",
  "Cache-Control": "no-store",
};

const clientErrorCodes = new Set([
  "already_enrolled",
  "application_not_found",
  "application_terminal",
  "coach_approval_required",
  "coach_eligibility_incomplete",
  "coach_invalid",
  "coach_required",
  "fulfillment_failed",
  "payment_not_required",
  "permission_denied",
  "product_not_ready",
  "profile_incomplete",
  "program_full",
  "program_unavailable",
  "purchase_unverified",
  "purchase_intent_expired",
  "rate_limited",
  "registration_closed",
  "reservation_conflict",
  "revoked",
  "refunded",
  "transaction_mismatch",
  "transaction_replayed",
]);

export function jsonResponse(
  status: number,
  payload: Record<string, unknown>,
): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: jsonHeaders,
  });
}

export function loadCommerceConfiguration(): CommerceFunctionConfiguration {
  const projectURL = Deno.env.get("SUPABASE_URL");
  const keys = loadSupabaseRuntimeKeys();
  const environment = Deno.env.get("COMMERCE_APPLE_ENVIRONMENT");
  if (!projectURL) {
    throw new Error("server_configuration_missing");
  }
  if (
    environment !== "xcode" && environment !== "local_testing" &&
    environment !== "sandbox" && environment !== "production"
  ) {
    throw new Error("commerce_environment_missing");
  }
  return {
    projectURL,
    publishableKey: keys.publishableKey,
    secretKey: keys.secretKey,
    environment,
  };
}

export function requestAuthorization(request: Request): string {
  const authorization = request.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) {
    throw new Error("authentication_required");
  }
  return authorization;
}

export async function authenticateCommerceUser(
  configuration: CommerceFunctionConfiguration,
  authorization: string,
): Promise<string> {
  const response = await fetchWithTimeout(
    new URL("/auth/v1/user", configuration.projectURL),
    {
      method: "GET",
      headers: {
        "apikey": configuration.publishableKey,
        "Authorization": authorization,
      },
    },
  );
  if (!response.ok) {
    throw new Error("authentication_required");
  }
  const user = await response.json() as SupabaseUser;
  if (!user.id) {
    throw new Error("authentication_required");
  }
  return user.id;
}

export async function callServiceRPC<Result>(
  configuration: CommerceFunctionConfiguration,
  functionName: string,
  body: Record<string, unknown>,
): Promise<Result> {
  return await callRPC<Result>(
    configuration,
    functionName,
    body,
    null,
    configuration.secretKey,
  );
}

export async function callUserRPC<Result>(
  configuration: CommerceFunctionConfiguration,
  functionName: string,
  body: Record<string, unknown>,
  authorization: string,
): Promise<Result> {
  return await callRPC<Result>(
    configuration,
    functionName,
    body,
    authorization,
    configuration.publishableKey,
  );
}

async function callRPC<Result>(
  configuration: CommerceFunctionConfiguration,
  functionName: string,
  body: Record<string, unknown>,
  authorization: string | null,
  apiKey: string,
): Promise<Result> {
  const response = await fetchWithTimeout(
    new URL(`/rest/v1/rpc/${functionName}`, configuration.projectURL),
    {
      method: "POST",
      headers: {
        "apikey": apiKey,
        ...(authorization
          ? { "Authorization": authorization }
          : serviceRequestHeaders(apiKey)),
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    },
  );
  const responseText = await response.text();
  if (!response.ok) {
    let payload: PostgrestError | null = null;
    try {
      payload = responseText.length > 0
        ? JSON.parse(responseText) as PostgrestError
        : null;
    } catch {
      payload = null;
    }
    const candidate = payload?.message?.trim();
    throw new Error(
      candidate && clientErrorCodes.has(candidate)
        ? candidate
        : "commerce_operation_failed",
    );
  }
  if (responseText.length === 0) {
    return undefined as Result;
  }
  return JSON.parse(responseText) as Result;
}

export function requireIdempotencyKey(request: Request): string {
  const value = request.headers.get("Idempotency-Key")?.trim() ?? "";
  if (value.length < 8 || value.length > 128) {
    throw new Error("idempotency_key_invalid");
  }
  return value;
}

export function errorResponse(error: unknown): Response {
  const candidate = error instanceof Error ? error.message : "unknown";
  const edgeErrorCodes = new Set([
    "authentication_required",
    "apple_server_api_configuration_invalid",
    "apple_server_api_configuration_missing",
    "apple_server_api_environment_invalid",
    "commerce_environment_missing",
    "idempotency_key_invalid",
    "method_not_allowed",
    "request_invalid",
    "route_not_found",
    "server_configuration_missing",
  ]);
  const code = clientErrorCodes.has(candidate) || edgeErrorCodes.has(candidate)
    ? candidate
    : "commerce_operation_failed";
  const status = code === "authentication_required"
    ? 401
    : code === "permission_denied"
    ? 403
    : code === "rate_limited"
    ? 429
    : code === "method_not_allowed"
    ? 405
    : code === "route_not_found"
    ? 404
    : code.endsWith("_invalid") || code === "request_invalid" ||
        code === "purchase_unverified"
    ? 422
    : code === "server_configuration_missing" ||
        code === "apple_server_api_configuration_invalid" ||
        code === "apple_server_api_configuration_missing" ||
        code === "apple_server_api_environment_invalid" ||
        code === "commerce_environment_missing"
    ? 500
    : 409;
  return jsonResponse(status, { code });
}

export function isUUID(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
    .test(value);
}
