import "server-only";

const encoder = new TextEncoder();
const decoder = new TextDecoder();

function encodeBase64Url(bytes: Uint8Array): string {
  return Buffer.from(bytes).toString("base64url");
}

function decodeBase64Url(value: string): ArrayBuffer {
  const bytes = Buffer.from(value, "base64url");
  return Uint8Array.from(bytes).buffer;
}

async function signingKey(secret: string): Promise<CryptoKey> {
  if (secret.length < 32) {
    throw new Error("AUTH_FLOW_COOKIE_SECRET harus memiliki sedikitnya 32 karakter.");
  }
  return crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { hash: "SHA-256", name: "HMAC" },
    false,
    ["sign", "verify"],
  );
}

export async function sealCookie<Value>(value: Value, secret: string): Promise<string> {
  const payload = encodeBase64Url(encoder.encode(JSON.stringify(value)));
  const signature = await crypto.subtle.sign(
    "HMAC",
    await signingKey(secret),
    encoder.encode(payload),
  );
  return `${payload}.${encodeBase64Url(new Uint8Array(signature))}`;
}

export async function unsealCookie<Value>(value: string, secret: string): Promise<Value | null> {
  const [payload, signature, extra] = value.split(".");
  if (!payload || !signature || extra) {
    return null;
  }
  const isValid = await crypto.subtle.verify(
    "HMAC",
    await signingKey(secret),
    decodeBase64Url(signature),
    encoder.encode(payload),
  );
  if (!isValid) {
    return null;
  }
  try {
    return JSON.parse(decoder.decode(decodeBase64Url(payload))) as Value;
  } catch {
    return null;
  }
}
