import { createHash } from "node:crypto";

type Bucket = { count: number; expiresAt: number };

const buckets = new Map<string, Bucket>();
const maximumBuckets = 5_000;

export type RequestLimitResult =
  | Readonly<{ allowed: true; remaining: number }>
  | Readonly<{ allowed: false; retryAfterSeconds: number }>;

function prune(now: number) {
  for (const [key, bucket] of buckets) {
    if (bucket.expiresAt <= now) buckets.delete(key);
  }
  while (buckets.size >= maximumBuckets) {
    const oldest = buckets.keys().next().value as string | undefined;
    if (!oldest) break;
    buckets.delete(oldest);
  }
}

export function opaqueRequestFingerprint(headers: Headers): string {
  const forwardedAddress = headers.get("x-forwarded-for")?.split(",", 1)[0]?.trim() ?? "local";
  const userAgent = headers.get("user-agent")?.slice(0, 256) ?? "unknown";
  return createHash("sha256").update(`${forwardedAddress}\n${userAgent}`, "utf8").digest("hex");
}

export function consumeRequestLimit(
  namespace: string,
  fingerprint: string,
  options: Readonly<{ limit: number; now?: number; windowMs: number }>,
): RequestLimitResult {
  const now = options.now ?? Date.now();
  prune(now);
  const key = `${namespace}:${fingerprint}`;
  const existing = buckets.get(key);
  if (!existing || existing.expiresAt <= now) {
    buckets.set(key, { count: 1, expiresAt: now + options.windowMs });
    return { allowed: true, remaining: options.limit - 1 };
  }
  if (existing.count >= options.limit) {
    return {
      allowed: false,
      retryAfterSeconds: Math.max(1, Math.ceil((existing.expiresAt - now) / 1_000)),
    };
  }
  existing.count += 1;
  return { allowed: true, remaining: options.limit - existing.count };
}

export function resetRequestLimitsForTests() {
  buckets.clear();
}
