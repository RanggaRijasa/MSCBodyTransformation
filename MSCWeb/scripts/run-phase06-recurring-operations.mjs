import assert from "node:assert/strict";

import { createClient } from "@supabase/supabase-js";

const apiUrl = process.env.API_URL ?? process.env.NEXT_PUBLIC_SUPABASE_URL;
const serviceKey =
  process.env.SECRET_KEY ??
  process.env.SERVICE_ROLE_KEY ??
  process.env.SUPABASE_TEST_SERVICE_ROLE_KEY;

assert.ok(apiUrl, "API_URL Supabase lokal wajib tersedia.");
assert.ok(serviceKey, "Secret Supabase lokal wajib tersedia.");
assert.ok(
  ["127.0.0.1", "localhost", "::1"].includes(new URL(apiUrl).hostname),
  "Recurring operation Phase 06 hanya boleh berjalan terhadap Supabase lokal.",
);

const service = createClient(apiUrl, serviceKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});
const bucket = service.storage.from("payment-evidence");
const now = new Date();
const orphanCutoff = now.getTime() - 24 * 60 * 60 * 1000;

async function must(operation, label) {
  const result = await operation;
  if (result.error) throw new Error(`${label}: ${result.error.message}`);
  return result.data;
}

async function listObjects(prefix = "") {
  const objects = [];
  for (let offset = 0; ; offset += 1_000) {
    const entries = await must(
      bucket.list(prefix, { limit: 1_000, offset, sortBy: { column: "name", order: "asc" } }),
      "daftar objek bukti pembayaran",
    );
    for (const entry of entries) {
      const path = prefix ? `${prefix}/${entry.name}` : entry.name;
      if (entry.id === null) objects.push(...(await listObjects(path)));
      else objects.push({ createdAt: entry.created_at, path });
    }
    if (entries.length < 1_000) break;
  }
  return objects;
}

const expiredOrders = await must(service.rpc("expire_payment_orders"), "expiry order");
const dueAttempts = await must(
  service
    .from("payment_evidence_attempts")
    .select("object_path,payment_orders!inner(retention_after)")
    .neq("status", "deleted")
    .lte("payment_orders.retention_after", now.toISOString()),
  "muat bukti melewati retention",
);
const duePaths = dueAttempts.map(({ object_path: objectPath }) => objectPath);
if (duePaths.length > 0) await must(bucket.remove(duePaths), "hapus bukti melewati retention");

const knownAttempts = await must(
  service.from("payment_evidence_attempts").select("object_path"),
  "muat indeks bukti pembayaran",
);
const knownPaths = new Set(knownAttempts.map(({ object_path: objectPath }) => objectPath));
const objects = await listObjects();
const orphanPaths = objects
  .filter(
    ({ createdAt, path }) =>
      !knownPaths.has(path) &&
      typeof createdAt === "string" &&
      new Date(createdAt).getTime() <= orphanCutoff,
  )
  .map(({ path }) => path);
if (orphanPaths.length > 0) await must(bucket.remove(orphanPaths), "hapus objek bukti orphan");

const markedEvidence = await must(
  service.rpc("cleanup_expired_payment_evidence"),
  "tandai bukti terhapus",
);

console.log(
  JSON.stringify({
    expiredOrders,
    markedEvidence,
    removedEvidenceObjects: duePaths.length,
    removedOrphanObjects: orphanPaths.length,
  }),
);
