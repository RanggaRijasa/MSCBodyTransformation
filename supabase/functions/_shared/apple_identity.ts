import { fetchWithTimeout } from "./http_safety.ts";
import {
  loadSupabaseRuntimeKeys,
  serviceRequestHeaders,
} from "./supabase_keys.ts";

export type AppleIdentityConfiguration = {
  projectURL: string;
  publishableKey: string;
  secretKey: string;
  clientID: string;
  teamID: string;
  keyID: string;
  privateKeyPEM: string;
  encryptionKey: Uint8Array;
};

export type AppleAccountEvent = {
  jti: string;
  type:
    | "email-enabled"
    | "email-disabled"
    | "consent-revoked"
    | "account-deleted";
  subject: string;
  eventTime: Date;
};

export type ClaimedAppleCredential = {
  id: string;
  encrypted_refresh_token: string;
  encryption_nonce: string;
};

type AppleTokenResponse = {
  refresh_token?: string;
  id_token?: string;
};

type AppleIDTokenPayload = {
  iss?: string;
  aud?: string | string[];
  exp?: number;
  sub?: string;
};

type AppleNotificationPayload = {
  iss?: string;
  aud?: string;
  iat?: number;
  jti?: string;
  events?: {
    type?: string;
    sub?: string;
    event_time?: number;
  };
};

type AppleJWK = JsonWebKey & { kid?: string; alg?: string };

let cachedAppleKeys:
  | { expiresAt: number; keys: AppleJWK[] }
  | undefined;

export function loadAppleIdentityConfiguration(): AppleIdentityConfiguration {
  const projectURL = Deno.env.get("SUPABASE_URL");
  const keys = loadSupabaseRuntimeKeys();
  const clientID = Deno.env.get("APPLE_SIGN_IN_CLIENT_ID");
  const teamID = Deno.env.get("APPLE_SIGN_IN_TEAM_ID");
  const keyID = Deno.env.get("APPLE_SIGN_IN_KEY_ID");
  const privateKey = Deno.env.get("APPLE_SIGN_IN_PRIVATE_KEY");
  const encryptionKeyValue = Deno.env.get("APPLE_TOKEN_ENCRYPTION_KEY");
  if (
    !projectURL || !clientID ||
    !teamID || !keyID || !privateKey || !encryptionKeyValue
  ) {
    throw new Error("server_configuration_missing");
  }
  const encryptionKey = decodeBase64Flexible(encryptionKeyValue);
  if (encryptionKey.byteLength !== 32) {
    throw new Error("server_configuration_invalid");
  }
  return {
    projectURL,
    publishableKey: keys.publishableKey,
    secretKey: keys.secretKey,
    clientID,
    teamID,
    keyID,
    privateKeyPEM: privateKey.replaceAll("\\n", "\n"),
    encryptionKey,
  };
}

export async function authenticateSupabaseUser(
  configuration: AppleIdentityConfiguration,
  authorization: string,
): Promise<{ id: string; appleSubjects: string[] }> {
  if (!authorization.startsWith("Bearer ")) {
    throw new Error("authentication_required");
  }
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
  const payload = await response.json() as {
    id?: string;
    identities?: Array<{
      provider?: string;
      identity_data?: { sub?: string };
    }>;
  };
  if (!payload.id) {
    throw new Error("authentication_required");
  }
  const appleSubjects = (payload.identities ?? [])
    .filter((identity) => identity.provider === "apple")
    .map((identity) => identity.identity_data?.sub)
    .filter((subject): subject is string => Boolean(subject));
  return { id: payload.id, appleSubjects };
}

export async function exchangeAppleAuthorizationCode(
  configuration: AppleIdentityConfiguration,
  authorizationCode: string,
): Promise<{ refreshToken: string; subject: string }> {
  const clientSecret = await createAppleClientSecret(configuration);
  const response = await fetchWithTimeout("https://appleid.apple.com/auth/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: configuration.clientID,
      client_secret: clientSecret,
      code: authorizationCode,
      grant_type: "authorization_code",
    }),
  });
  const payload = await response.json().catch(() => null) as
    | AppleTokenResponse
    | null;
  if (!response.ok || !payload?.refresh_token || !payload.id_token) {
    throw new Error("apple_authorization_code_invalid");
  }
  const tokenPayload = decodeJWSPayload<AppleIDTokenPayload>(payload.id_token);
  const audience = Array.isArray(tokenPayload.aud)
    ? tokenPayload.aud
    : [tokenPayload.aud];
  if (
    tokenPayload.iss !== "https://appleid.apple.com" ||
    !audience.includes(configuration.clientID) ||
    !tokenPayload.sub ||
    !tokenPayload.exp || tokenPayload.exp <= Math.floor(Date.now() / 1000)
  ) {
    throw new Error("apple_identity_mismatch");
  }
  return {
    refreshToken: payload.refresh_token,
    subject: tokenPayload.sub,
  };
}

export async function encryptAppleRefreshToken(
  configuration: AppleIdentityConfiguration,
  refreshToken: string,
): Promise<{ ciphertext: string; nonce: string }> {
  const key = await importEncryptionKey(configuration.encryptionKey);
  const nonce = crypto.getRandomValues(new Uint8Array(12));
  const encrypted = await crypto.subtle.encrypt(
    { name: "AES-GCM", iv: nonce },
    key,
    new TextEncoder().encode(refreshToken),
  );
  return {
    ciphertext: encodeBase64URL(new Uint8Array(encrypted)),
    nonce: encodeBase64URL(nonce),
  };
}

export async function decryptAppleRefreshToken(
  configuration: AppleIdentityConfiguration,
  credential: ClaimedAppleCredential,
): Promise<string> {
  const key = await importEncryptionKey(configuration.encryptionKey);
  try {
    const decrypted = await crypto.subtle.decrypt(
      { name: "AES-GCM", iv: decodeBase64URL(credential.encryption_nonce) },
      key,
      decodeBase64URL(credential.encrypted_refresh_token),
    );
    return new TextDecoder().decode(decrypted);
  } catch {
    throw new Error("apple_credential_decryption_failed");
  }
}

export async function revokeAppleRefreshToken(
  configuration: AppleIdentityConfiguration,
  refreshToken: string,
): Promise<void> {
  const clientSecret = await createAppleClientSecret(configuration);
  const response = await fetchWithTimeout("https://appleid.apple.com/auth/revoke", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: configuration.clientID,
      client_secret: clientSecret,
      token: refreshToken,
      token_type_hint: "refresh_token",
    }),
  });
  if (!response.ok) {
    throw new Error("apple_revoke_failed");
  }
}

export async function verifyAppleAccountEvent(
  configuration: AppleIdentityConfiguration,
  signedPayload: string,
): Promise<AppleAccountEvent> {
  const parts = signedPayload.split(".");
  if (parts.length !== 3) {
    throw new Error("apple_notification_invalid");
  }
  const header = JSON.parse(
    new TextDecoder().decode(decodeBase64URL(parts[0])),
  ) as { alg?: string; kid?: string };
  if (header.alg !== "ES256" || !header.kid) {
    throw new Error("apple_notification_invalid");
  }
  const keys = await applePublicKeys();
  const jwk = keys.find((candidate) => candidate.kid === header.kid);
  if (!jwk) {
    cachedAppleKeys = undefined;
    throw new Error("apple_notification_key_unknown");
  }
  const key = await crypto.subtle.importKey(
    "jwk",
    jwk,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["verify"],
  );
  const verified = await crypto.subtle.verify(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    decodeBase64URL(parts[2]),
    new TextEncoder().encode(`${parts[0]}.${parts[1]}`),
  );
  if (!verified) {
    throw new Error("apple_notification_signature_invalid");
  }
  const payload = decodeJWSPayload<AppleNotificationPayload>(signedPayload);
  const now = Math.floor(Date.now() / 1000);
  const allowedTypes = new Set([
    "email-enabled",
    "email-disabled",
    "consent-revoked",
    "account-deleted",
  ]);
  if (
    payload.iss !== "https://appleid.apple.com" ||
    payload.aud !== configuration.clientID ||
    !payload.iat || payload.iat > now + 300 || payload.iat < now - 86_400 ||
    !payload.jti || !payload.events?.sub || !payload.events.event_time ||
    !payload.events.type || !allowedTypes.has(payload.events.type)
  ) {
    throw new Error("apple_notification_invalid");
  }
  return {
    jti: payload.jti,
    type: payload.events.type as AppleAccountEvent["type"],
    subject: payload.events.sub,
    eventTime: new Date(payload.events.event_time * 1000),
  };
}

export async function sha256Hex(value: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(value),
  );
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

export async function callAppleServiceRPC<Result>(
  configuration: AppleIdentityConfiguration,
  functionName: string,
  body: Record<string, unknown>,
): Promise<Result> {
  const response = await fetchWithTimeout(
    new URL(`/rest/v1/rpc/${functionName}`, configuration.projectURL),
    {
      method: "POST",
      headers: {
        ...serviceRequestHeaders(configuration.secretKey),
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    },
  );
  const responseText = await response.text();
  if (!response.ok) {
    let message = "apple_identity_operation_failed";
    try {
      const payload = JSON.parse(responseText) as { message?: string };
      const allowed = new Set([
        "admin_account_deletion_not_allowed",
        "account_relationships_require_transfer",
        "private_media_cleanup_required",
        "apple_identity_mismatch",
        "request_invalid",
      ]);
      if (payload.message && allowed.has(payload.message)) {
        message = payload.message;
      }
    } catch {
      // The sanitized fallback remains authoritative.
    }
    throw new Error(message);
  }
  if (!responseText) {
    return undefined as Result;
  }
  return JSON.parse(responseText) as Result;
}

export function appleIdentityErrorResponse(error: unknown): Response {
  const candidate = error instanceof Error ? error.message : "unknown";
  const allowed = new Set([
    "apple_authorization_code_invalid",
    "apple_identity_mismatch",
    "apple_notification_invalid",
    "apple_notification_signature_invalid",
    "authentication_required",
    "method_not_allowed",
    "request_invalid",
    "server_configuration_invalid",
    "server_configuration_missing",
  ]);
  const code = allowed.has(candidate)
    ? candidate
    : "apple_identity_operation_failed";
  const status = code === "authentication_required"
    ? 401
    : code === "method_not_allowed"
    ? 405
    : code.endsWith("_invalid")
    ? 400
    : 500;
  return new Response(JSON.stringify({ code }), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Cache-Control": "no-store",
    },
  });
}

async function createAppleClientSecret(
  configuration: AppleIdentityConfiguration,
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = encodeBase64URL(
    new TextEncoder().encode(JSON.stringify({
      alg: "ES256",
      kid: configuration.keyID,
      typ: "JWT",
    })),
  );
  const payload = encodeBase64URL(
    new TextEncoder().encode(JSON.stringify({
      iss: configuration.teamID,
      iat: now,
      exp: now + 300,
      aud: "https://appleid.apple.com",
      sub: configuration.clientID,
    })),
  );
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToDER(configuration.privateKeyPEM),
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    new TextEncoder().encode(`${header}.${payload}`),
  );
  return `${header}.${payload}.${encodeBase64URL(new Uint8Array(signature))}`;
}

async function importEncryptionKey(rawKey: Uint8Array): Promise<CryptoKey> {
  return await crypto.subtle.importKey(
    "raw",
    rawKey,
    { name: "AES-GCM" },
    false,
    ["encrypt", "decrypt"],
  );
}

async function applePublicKeys(): Promise<AppleJWK[]> {
  if (cachedAppleKeys && cachedAppleKeys.expiresAt > Date.now()) {
    return cachedAppleKeys.keys;
  }
  const response = await fetchWithTimeout("https://appleid.apple.com/auth/keys", {
    headers: { "Accept": "application/json" },
  });
  if (!response.ok) {
    throw new Error("apple_notification_key_unavailable");
  }
  const payload = await response.json() as { keys?: AppleJWK[] };
  if (!payload.keys?.length) {
    throw new Error("apple_notification_key_unavailable");
  }
  cachedAppleKeys = {
    expiresAt: Date.now() + 15 * 60 * 1000,
    keys: payload.keys,
  };
  return payload.keys;
}

function decodeJWSPayload<Value>(signedValue: string): Value {
  const parts = signedValue.split(".");
  if (parts.length !== 3) {
    throw new Error("apple_notification_invalid");
  }
  try {
    return JSON.parse(
      new TextDecoder().decode(decodeBase64URL(parts[1])),
    ) as Value;
  } catch {
    throw new Error("apple_notification_invalid");
  }
}

function pemToDER(pem: string): Uint8Array {
  const base64 = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replaceAll(/\s/g, "");
  if (!base64) {
    throw new Error("server_configuration_invalid");
  }
  return decodeBase64Flexible(base64);
}

function encodeBase64URL(value: Uint8Array): string {
  let binary = "";
  for (const byte of value) binary += String.fromCharCode(byte);
  return btoa(binary)
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");
}

function decodeBase64URL(value: string): Uint8Array {
  return decodeBase64Flexible(
    value.replaceAll("-", "+").replaceAll("_", "/"),
  );
}

function decodeBase64Flexible(value: string): Uint8Array {
  const padding = "=".repeat((4 - value.length % 4) % 4);
  const decoded = atob(`${value}${padding}`);
  return Uint8Array.from(decoded, (character) => character.charCodeAt(0));
}
