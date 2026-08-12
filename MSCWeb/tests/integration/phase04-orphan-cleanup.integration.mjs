import assert from "node:assert/strict";

const apiUrl = requireEnvironment("API_URL");
const secretKey = process.env.SECRET_KEY ?? requireEnvironment("SERVICE_ROLE_KEY");
const endpoint = `${apiUrl}/functions/v1/cleanup-orphan-question-photos`;

assert.ok(
  ["127.0.0.1", "localhost", "::1"].includes(new URL(apiUrl).hostname),
  "Phase 04 cleanup test hanya boleh menargetkan Supabase lokal",
);

function requireEnvironment(name) {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

async function request({ body, headers = {}, method = "POST" } = {}) {
  const serializedBody = body === undefined ? undefined : JSON.stringify(body);
  return fetch(endpoint, {
    body: serializedBody,
    headers: {
      ...(serializedBody === undefined
        ? {}
        : {
            "Content-Length": String(Buffer.byteLength(serializedBody)),
            "Content-Type": "application/json",
          }),
      ...headers,
    },
    method,
  });
}

assert.equal((await request({ method: "GET" })).status, 405, "method selain POST ditolak");
assert.equal(
  (await request({ body: { older_than_hours: 876_000 } })).status,
  401,
  "request tanpa identity ditolak",
);

const safeCleanup = await request({
  body: {
    older_than_hours: 876_000,
    reason: "Verifikasi non-destruktif Phase 04.",
  },
  headers: { apikey: secretKey },
});
const safePayload = await safeCleanup.json();
assert.ok(safeCleanup.ok, `service cleanup gagal: ${JSON.stringify(safePayload)}`);
assert.equal(
  safePayload.deleted_count,
  0,
  "retention 100 tahun tidak boleh menghapus object lokal",
);

const oversized = await request({
  body: { older_than_hours: 876_000, reason: "x".repeat(8_192) },
  headers: { apikey: secretKey },
});
assert.equal(oversized.status, 422, "request cleanup oversized ditolak");
assert.equal(
  (await oversized.json()).code,
  "request_invalid",
  "request cleanup oversized ditolak pada batas pembacaan body",
);

console.log("PASS Phase 04 orphan cleanup boundary (5 assertions, 0 object deleted)");
