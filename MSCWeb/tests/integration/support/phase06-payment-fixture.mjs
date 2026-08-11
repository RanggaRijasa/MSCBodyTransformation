import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { randomUUID } from "node:crypto";
import { fileURLToPath } from "node:url";

import { createClient } from "@supabase/supabase-js";

export function requiredEnvironment(name) {
  const value = process.env[name];
  if (!value) throw new Error(`Missing ${name}`);
  return value;
}

export async function must(operation, label) {
  const result = await operation;
  assert.equal(result.error, null, `${label}: ${result.error?.message ?? "unknown"}`);
  return result.data;
}

export async function createIdentity({ anonKey, apiUrl, service, users }, label) {
  const email = `phase06-${label}-${randomUUID()}@local.invalid`;
  const password = `Phase06-${randomUUID()}!`;
  const data = await must(
    service.auth.admin.createUser({ email, email_confirm: true, password }),
    `create ${label}`,
  );
  users.push(data.user.id);
  const client = createClient(apiUrl, anonKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  await must(client.auth.signInWithPassword({ email, password }), `sign in ${label}`);
  return { client, id: data.user.id };
}

export async function updateProfile(service, user, values) {
  await must(
    service
      .from("profiles")
      .update({
        finalized_at: new Date().toISOString(),
        onboarding_status: "active",
        provisional_expires_at: null,
        ...values,
      })
      .eq("user_id", user.id),
    `profile ${user.id}`,
  );
}

export async function rpc(client, name, body) {
  return must(client.rpc(name, body), `rpc ${name}`);
}

export async function prepareAndUpload(service, client, orderId, label) {
  const prepared = await rpc(client, "prepare_payment_evidence_attempt", {
    request_idempotency_key: `phase06-upload-${label}-${randomUUID()}`,
    target_order_id: orderId,
  });
  const bytes = Uint8Array.from([0xff, 0xd8, 0xff, 0xda, 0x00, 0x01, 0xff, 0xd9]);
  await must(
    service.storage.from("payment-evidence").upload(prepared.object_path, bytes, {
      cacheControl: "0",
      contentType: "image/jpeg",
      upsert: false,
    }),
    `upload ${label}`,
  );
  return prepared;
}

export async function uploadAndSubmit(service, client, orderId, label) {
  const prepared = await prepareAndUpload(service, client, orderId, label);
  const actor = await must(client.auth.getUser(), `verified owner ${label}`);
  return rpc(service, "submit_payment_evidence", {
    content_byte_size: 8,
    content_pixel_height: 1,
    content_pixel_width: 1,
    content_sha256_hex: "a".repeat(64),
    submitting_owner_user_id: actor.user.id,
    target_attempt_id: prepared.attempt_id,
  });
}

export function paidProgram(id, adminId, title) {
  return {
    created_by: adminId,
    desired_price: 250000,
    duration_mode: "fixed_duration",
    ends_on: "2026-08-31",
    future_step_policy: "locked",
    id,
    pace: "scheduled",
    past_step_policy: "available",
    points_per_activity: 10,
    points_per_weight_kg: 100,
    pricing_mode: "paid",
    published_at: new Date().toISOString(),
    quiz_passing_percentage: 70,
    starts_on: "2026-08-01",
    status: "active",
    summary: "Fixture manual payment lokal.",
    timezone: "Asia/Makassar",
    title,
    wellness_disclaimer: "Program kebugaran non-diagnostik.",
  };
}

export async function verifyExpiryAndRestoreCases({
  adminClient,
  coach,
  orderIds,
  participantOne,
  participantTwo,
  programs,
  service,
}) {
  const restoreOrder = await rpc(participantTwo.client, "create_program_payment_order", {
    coach_qr_payload: "phase06-integration-coach-qr",
    request_idempotency_key: `phase06-restore-${randomUUID()}`,
    target_program_id: programs[2],
  });
  orderIds.push(restoreOrder.order_id);
  const preparedAtExpiry = await prepareAndUpload(
    service,
    participantTwo.client,
    restoreOrder.order_id,
    "expiry-race",
  );
  await must(
    service
      .from("payment_orders")
      .update({ reservation_expires_at: new Date(Date.now() - 60_000).toISOString() })
      .eq("id", restoreOrder.order_id),
    "expire prepared order",
  );
  const [lateSubmit, expiry] = await Promise.all([
    service.rpc("submit_payment_evidence", {
      content_byte_size: 8,
      content_pixel_height: 1,
      content_pixel_width: 1,
      content_sha256_hex: "b".repeat(64),
      submitting_owner_user_id: participantTwo.id,
      target_attempt_id: preparedAtExpiry.attempt_id,
    }),
    service.rpc("expire_payment_orders"),
  ]);
  assert.match(lateSubmit.error?.message ?? "", /expired|not_uploadable/);
  assert.equal(expiry.error, null);
  const expiredOrder = await must(
    service
      .from("payment_orders")
      .select("status,version")
      .eq("id", restoreOrder.order_id)
      .single(),
    "expiry wins submit race",
  );
  assert.equal(expiredOrder.status, "expired");
  const restoredOrder = await rpc(adminClient, "restore_expired_payment_order", {
    expected_version: expiredOrder.version,
    target_order_id: restoreOrder.order_id,
  });
  assert.equal(restoredOrder.status, "correction_required");
  const cancelledOrder = await rpc(participantTwo.client, "cancel_payment_order", {
    target_order_id: restoreOrder.order_id,
  });
  assert.equal(cancelledOrder.status, "cancelled");

  const fullOrder = await rpc(participantTwo.client, "create_program_payment_order", {
    coach_qr_payload: "phase06-integration-coach-qr",
    request_idempotency_key: `phase06-full-restore-${randomUUID()}`,
    target_program_id: programs[3],
  });
  orderIds.push(fullOrder.order_id);
  await must(
    service
      .from("payment_orders")
      .update({ reservation_expires_at: new Date(Date.now() - 60_000).toISOString() })
      .eq("id", fullOrder.order_id),
    "expire full restore order",
  );
  await rpc(service, "expire_payment_orders", {});
  await must(
    service.from("program_enrollments").insert({
      coach_id: coach.id,
      participant_id: participantOne.id,
      program_id: programs[3],
      status: "active",
    }),
    "occupy restored program capacity",
  );
  const expiredFullOrder = await must(
    service.from("payment_orders").select("version").eq("id", fullOrder.order_id).single(),
    "full order version",
  );
  const restoreFull = await adminClient.rpc("restore_expired_payment_order", {
    expected_version: expiredFullOrder.version,
    target_order_id: fullOrder.order_id,
  });
  assert.match(restoreFull.error?.message ?? "", /program_full/);
}

export async function verifyRetentionCleanup(service, databaseUrl, orderId, ownerUserId) {
  const orphanPath = `orders/${randomUUID()}/attempts/${randomUUID()}/normalized.jpg`;
  const orphanBytes = Uint8Array.from([0xff, 0xd8, 0xff, 0xd9]);
  await must(
    service.storage.from("payment-evidence").upload(orphanPath, orphanBytes, {
      contentType: "image/jpeg",
      upsert: false,
    }),
    "create orphan evidence fixture",
  );
  execFileSync("/opt/homebrew/opt/postgresql@16/bin/psql", [
    "-X",
    "-w",
    "-v",
    "ON_ERROR_STOP=1",
    "-d",
    databaseUrl,
    "-c",
    `update storage.objects set created_at = statement_timestamp() - interval '2 days'
      where bucket_id = 'payment-evidence' and name = '${orphanPath}';`,
  ]);
  await must(
    service
      .from("payment_orders")
      .update({ retention_after: new Date(Date.now() - 60_000).toISOString() })
      .eq("id", orderId),
    "make payment evidence due for cleanup",
  );
  const recurringOperationsPath = fileURLToPath(
    new URL("../../../scripts/run-phase06-recurring-operations.mjs", import.meta.url),
  );
  const recurringResult = JSON.parse(
    execFileSync(process.execPath, [recurringOperationsPath], {
      encoding: "utf8",
      env: process.env,
    }),
  );
  assert.ok(recurringResult.removedEvidenceObjects >= 1);
  assert.ok(recurringResult.markedEvidence >= 1);
  assert.ok(recurringResult.removedOrphanObjects >= 1);
  const orphanDownload = await service.storage.from("payment-evidence").download(orphanPath);
  assert.ok(orphanDownload.error, "orphan object older than grace period is removed");
  assert.equal(
    (
      await must(
        service.from("payment_evidence_attempts").select("status").eq("order_id", orderId).single(),
        "retained evidence metadata",
      )
    ).status,
    "deleted",
  );
  assert.equal(
    (
      await must(
        service.from("payment_ledger").select("id").eq("order_id", orderId),
        "retained payment ledger",
      )
    ).length,
    2,
  );
  await must(
    service.from("program_enrollments").delete().eq("participant_id", ownerUserId),
    "remove account enrollment projections",
  );
  await must(
    service.from("profiles").delete().eq("user_id", ownerUserId),
    "delete retained payment owner profile",
  );
  const anonymizedOrder = await must(
    service.from("payment_orders").select("owner_user_id").eq("id", orderId).single(),
    "retained anonymized payment order",
  );
  assert.equal(anonymizedOrder.owner_user_id, null);
}

export async function cleanupPhase06Fixture({
  coachApplicationId,
  databaseUrl,
  destinationId,
  orderIds,
  programs,
  seededCoachObjects,
  service,
  users,
}) {
  const fallback = ["00000000-0000-0000-0000-000000000000"];
  const { data: evidence } = await service
    .from("payment_evidence_attempts")
    .select("object_path")
    .in("order_id", orderIds.length ? orderIds : fallback);
  const paths = (evidence ?? []).map(({ object_path: objectPath }) => objectPath);
  if (paths.length) await service.storage.from("payment-evidence").remove(paths);
  const quoted = (values) => values.map((value) => `'${value}'`).join(",");
  const orderList = quoted(orderIds.length ? orderIds : fallback);
  const programList = quoted(programs);
  const userList = quoted(users.length ? users : fallback);
  const destinationClause = destinationId ? `or id = '${destinationId}'` : "";
  const sql = `
    begin;
    alter table public.payment_events disable trigger payment_events_no_update_or_delete;
    alter table public.payment_ledger disable trigger payment_ledger_no_update_or_delete;
    delete from public.payment_events where order_id in (${orderList});
    delete from public.payment_ledger where order_id in (${orderList});
    delete from public.payment_evidence_attempts where order_id in (${orderList});
    delete from public.payment_orders where id in (${orderList});
    delete from public.program_scores where enrollment_id in (
      select id from public.program_enrollments where program_id in (${programList})
    );
    delete from public.program_enrollments where program_id in (${programList});
    delete from public.programs where id in (${programList});
    delete from public.coach_access_entitlements where application_id in (
      '${seededCoachObjects[0]}', '${coachApplicationId}'
    );
    delete from public.coach_payment_records where application_id in (
      '${seededCoachObjects[0]}', '${coachApplicationId}'
    );
    delete from public.coach_applications where id in (
      '${seededCoachObjects[0]}', '${coachApplicationId}'
    );
    delete from public.payment_destinations where created_by in (${userList}) ${destinationClause};
    delete from public.audit_events where actor_id in (${userList});
    alter table public.payment_events enable trigger payment_events_no_update_or_delete;
    alter table public.payment_ledger enable trigger payment_ledger_no_update_or_delete;
    commit;
  `;
  execFileSync("/opt/homebrew/opt/postgresql@16/bin/psql", [
    "-X",
    "-w",
    "-v",
    "ON_ERROR_STOP=1",
    "-d",
    databaseUrl,
    "-c",
    sql,
  ]);
  for (const userId of [...users].reverse()) await service.auth.admin.deleteUser(userId);
}
