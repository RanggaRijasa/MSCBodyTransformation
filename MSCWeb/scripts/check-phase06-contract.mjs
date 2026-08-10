import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

const root = new URL("../", import.meta.url);
const [
  contract,
  domain,
  migration,
  coachRoute,
  programRoute,
  evidenceRoute,
  imageValidation,
  paymentRepository,
] = await Promise.all(
  [
    "docs/contracts/MANUAL_PAYMENT_OPENAPI.yaml",
    "src/domain/payments/payment.ts",
    "supabase/migrations/20260810090000_phase06_manual_payments.sql",
    "src/app/api/coach-applications/[applicationId]/payment-order/route.ts",
    "src/app/api/programs/[programId]/payment-order/route.ts",
    "src/app/api/payments/[paymentId]/evidence/route.ts",
    "src/application/media/server-image-validation.ts",
    "src/infrastructure/supabase/payments/supabase-payment-repository.ts",
  ].map((path) => readFile(new URL(path, root), "utf8")),
);

const statuses = [
  "awaiting_evidence",
  "under_review",
  "correction_required",
  "approved",
  "expired",
  "cancelled",
  "rejected",
  "reversal_pending",
  "reversed",
];

for (const status of statuses) {
  assert.ok(domain.includes(`"${status}"`), `Status ${status} hilang dari domain TypeScript.`);
  assert.ok(contract.includes(`- ${status}`), `Status ${status} hilang dari OpenAPI.`);
  assert.ok(migration.includes(`'${status}'`), `Status ${status} hilang dari SQL.`);
}

for (const [path, source] of [
  ["/api/programs/{programId}/payment-order", programRoute],
  ["/api/coach-applications/{applicationId}/payment-order", coachRoute],
  ["/api/payments/{paymentId}/evidence", evidenceRoute],
]) {
  assert.ok(contract.includes(path), `Endpoint ${path} hilang dari OpenAPI.`);
  assert.ok(source.includes("no-store"), `Endpoint ${path} wajib menonaktifkan cache.`);
}

assert.ok(contract.includes("clientAuthoritativeFields: []"));
assert.ok(contract.includes("legacyStoreKitRuntimeUsedByWeb: false"));
assert.ok(contract.includes("evidenceThumbnailPolicy: client-preview-only-no-server-retention"));
assert.ok(contract.includes("destinationAssetBucket: payment-destination-assets-private"));
assert.ok(imageValidation.includes("sanitizeServerImageUpload"));
assert.ok(imageValidation.includes("stripJpegMetadata"));
assert.ok(paymentRepository.includes("sanitized.value.bytes"));
assert.doesNotMatch(
  `${coachRoute}\n${programRoute}\n${evidenceRoute}`,
  /NEXT_PUBLIC_(?:SUPABASE_)?(?:SECRET|SERVICE_ROLE|DATABASE|JWT)/,
);

console.log("Kontrak manual payment sinkron dengan SQL, TypeScript, dan route server.");
