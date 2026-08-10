export type SupabaseRuntimeKeys = {
  publishableKey: string;
  secretKey: string;
};

export function loadSupabaseRuntimeKeys(): SupabaseRuntimeKeys {
  const publishableKey = firstNonEmpty([
    namedKey("SUPABASE_PUBLISHABLE_KEYS", "default"),
    Deno.env.get("SUPABASE_PUBLISHABLE_KEY"),
    Deno.env.get("SUPABASE_ANON_KEY"),
  ]);
  const secretKey = firstNonEmpty([
    namedKey("SUPABASE_SECRET_KEYS", "default"),
    Deno.env.get("SUPABASE_SECRET_KEY"),
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"),
  ]);
  if (!publishableKey || !secretKey) {
    throw new Error("server_configuration_missing");
  }
  return { publishableKey, secretKey };
}

export function serviceRequestHeaders(
  secretKey: string,
): Record<string, string> {
  const headers: Record<string, string> = { "apikey": secretKey };
  if (!secretKey.startsWith("sb_secret_")) {
    headers.Authorization = `Bearer ${secretKey}`;
  }
  return headers;
}

export function isAuthorizedServiceRequest(
  request: Request,
  secretKey: string,
): boolean {
  if (request.headers.get("apikey") === secretKey) return true;
  return !secretKey.startsWith("sb_secret_") &&
    request.headers.get("Authorization") === `Bearer ${secretKey}`;
}

function namedKey(environmentName: string, keyName: string): string | null {
  const rawValue = Deno.env.get(environmentName)?.trim();
  if (!rawValue) return null;
  try {
    const values = JSON.parse(rawValue) as Record<string, unknown>;
    const value = values[keyName];
    return typeof value === "string" && value.trim() ? value.trim() : null;
  } catch {
    throw new Error("server_configuration_invalid");
  }
}

function firstNonEmpty(
  candidates: Array<string | null | undefined>,
): string | null {
  for (const candidate of candidates) {
    const value = candidate?.trim();
    if (value) return value;
  }
  return null;
}
