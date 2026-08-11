import { readFileSync } from "node:fs";
import { join } from "node:path";

const webRoot = new URL("../", import.meta.url).pathname;
const read = (relativePath) => readFileSync(join(webRoot, relativePath));
const text = (relativePath) => read(relativePath).toString("utf8");
const failures = [];
const assert = (condition, message) => {
  if (!condition) failures.push(message);
};

const worker = text("public/sw.js");
assert(
  worker.includes('fetch(request, { cache: "no-store" })'),
  "Navigasi SW wajib network/no-store.",
);
assert(worker.includes("PUBLIC_ASSETS.has(url.pathname)"), "Aset publik SW wajib exact allowlist.");
assert(!worker.includes("ignoreSearch: true"), "SW tidak boleh mengabaikan query cache.");
assert(!/PUBLIC_ASSETS[\s\S]{0,800}\/api\//.test(worker), "API tidak boleh masuk allowlist SW.");

const headers = text("next.config.ts");
for (const required of [
  "Strict-Transport-Security",
  "X-Content-Type-Options",
  "Permissions-Policy",
  "Referrer-Policy",
  "private, no-store",
])
  assert(headers.includes(required), `Header security hilang: ${required}`);

const proxy = text("src/proxy.ts");
assert(proxy.includes("hasTrustedMutationOrigin"), "Mutation origin gate wajib terpusat di proxy.");
assert(proxy.includes("X-Correlation-ID"), "Correlation ID aman wajib tersedia.");

const envExample = text(".env.example");
for (const line of envExample.split("\n")) {
  if (/^(?:NEXT_PUBLIC_WEB_PUSH|WEB_PUSH|PUSH_DISPATCH)/.test(line))
    assert(line.endsWith("="), `Contoh secret push harus kosong: ${line.split("=", 1)[0]}`);
}

for (const image of [
  "public/images/pwa-participant-rc-v1.jpg",
  "public/images/pwa-coach-rc-v1.jpg",
]) {
  const bytes = read(image);
  assert(!bytes.includes(Buffer.from("Exif\0\0", "binary")), `${image} masih mengandung EXIF.`);
  assert(!bytes.includes(Buffer.from("http", "ascii")), `${image} mengandung URL dalam metadata.`);
}

const dispatcher = text("supabase/functions/push-dispatch/index.ts");
assert(
  dispatcher.includes("timingSafeEqual"),
  "Dispatcher wajib memverifikasi secret secara konstan.",
);
assert(!dispatcher.includes("console.log"), "Dispatcher tidak boleh menulis payload ke log.");
assert(
  dispatcher.includes("statusCode === 404 || statusCode === 410"),
  "Endpoint stale wajib direvoke.",
);

if (failures.length > 0) {
  for (const failure of failures) console.error(`FAIL: ${failure}`);
  process.exit(1);
}
console.log("Gate security/cache/metadata Phase 11 lulus.");
