import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";

import { createClient } from "@supabase/supabase-js";

import {
  cleanupPhase06Fixture,
  createIdentity,
  must,
  paidProgram as program,
  requiredEnvironment as required,
  rpc,
  updateProfile,
  uploadAndSubmit as uploadAndSubmitFixture,
  verifyExpiryAndRestoreCases,
  verifyRetentionCleanup,
} from "./support/phase06-payment-fixture.mjs";
import {
  verifyAdminDecisionRace,
  verifyCoachEvidenceIsolation,
} from "./support/phase06-payment-security.mjs";

const apiUrl = required("API_URL");
const databaseUrl = required("DB_URL");
const anonKey = required("ANON_KEY");
const serviceKey = process.env.SECRET_KEY ?? required("SERVICE_ROLE_KEY");
assert.ok(["127.0.0.1", "localhost", "::1"].includes(new URL(apiUrl).hostname));
assert.ok(["127.0.0.1", "localhost", "::1"].includes(new URL(databaseUrl).hostname));

const service = createClient(apiUrl, serviceKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});
const users = [];
const programs = [randomUUID(), randomUUID(), randomUUID(), randomUUID(), randomUUID()];
const seededCoachObjects = [randomUUID(), randomUUID(), randomUUID()];
const coachApplicationId = randomUUID();
const orderIds = [];
let destinationId;

const identity = (label) => createIdentity({ anonKey, apiUrl, service, users }, label);
const profile = (user, values) => updateProfile(service, user, values);
const uploadAndSubmit = (client, orderId, label) =>
  uploadAndSubmitFixture(service, client, orderId, label);
const cleanup = () =>
  cleanupPhase06Fixture({
    coachApplicationId,
    databaseUrl,
    destinationId,
    orderIds,
    programs,
    seededCoachObjects,
    service,
    users,
  });

try {
  const adminOne = await identity("admin-one");
  const adminTwo = await identity("admin-two");
  const coach = await identity("coach");
  const participantOne = await identity("participant-one");
  const participantTwo = await identity("participant-two");
  const applicant = await identity("applicant");
  await profile(adminOne, { display_name: "Admin Manual Satu", role: "admin" });
  await profile(adminTwo, { display_name: "Admin Manual Dua", role: "admin" });
  await profile(coach, {
    coach_is_approved: true,
    coach_qr_identifier: "phase06-integration-coach-qr",
    display_name: "Coach Manual",
    role: "coach",
  });
  await profile(participantOne, { display_name: "Peserta Manual Satu", role: "participant" });
  await profile(participantTwo, { display_name: "Peserta Manual Dua", role: "participant" });
  await profile(applicant, { display_name: "Calon Coach Manual", role: "participant" });

  await must(
    service.from("coach_applications").insert({
      applicant_user_id: coach.id,
      decided_at: new Date().toISOString(),
      decided_by: adminOne.id,
      display_name_snapshot: "Coach Manual",
      draft_idempotency_key: `phase06-seed-${randomUUID()}`,
      has_completed_hom_sts: true,
      has_completed_ict: true,
      id: seededCoachObjects[0],
      member_level_snapshot: "sc",
      participant_profile_id: coach.id,
      phone_number_snapshot: "+628600000001",
      status: "active",
      submitted_at: new Date().toISOString(),
      terms_version: "phase06-local",
    }),
    "seed coach application",
  );
  await must(
    service.from("coach_payment_records").insert({
      amount_minor_units: 100000,
      application_id: seededCoachObjects[0],
      id: seededCoachObjects[1],
      price_band: "entry",
      provider_reference: `seed-${randomUUID()}`,
      state: "verified",
      verified_at: new Date().toISOString(),
    }),
    "seed coach payment",
  );
  await must(
    service.from("coach_access_entitlements").insert({
      application_id: seededCoachObjects[0],
      coach_user_id: coach.id,
      ends_at: new Date(Date.now() + 30 * 86400000).toISOString(),
      id: seededCoachObjects[2],
      payment_record_id: seededCoachObjects[1],
      starts_at: new Date(Date.now() - 86400000).toISOString(),
      status: "active",
    }),
    "seed coach entitlement",
  );
  const destination = await rpc(adminOne.client, "create_payment_destination", {
    destination_account_name: "MSC Lokal",
    destination_account_reference: "1234567890",
    destination_bank_code: "BCA",
    destination_bank_name: "Bank Central Asia",
    destination_qris_object_path: null,
    effective_at: new Date().toISOString(),
  });
  destinationId = destination.id;
  await must(
    service
      .from("programs")
      .insert([
        program(programs[0], adminOne.id, "Program Manual Happy"),
        program(programs[1], adminOne.id, "Program Manual Retry"),
        program(programs[2], adminOne.id, "Program Manual Restore"),
        { ...program(programs[3], adminOne.id, "Program Manual Full"), participant_limit: 1 },
        program(programs[4], adminOne.id, "Program Manual Decision Race"),
      ]),
    "seed paid programs",
  );

  const createBody = {
    coach_qr_payload: "phase06-integration-coach-qr",
    request_idempotency_key: `phase06-program-${randomUUID()}`,
    target_program_id: programs[0],
  };
  const duplicateOrders = await Promise.all([
    participantOne.client.rpc("create_program_payment_order", createBody),
    participantOne.client.rpc("create_program_payment_order", createBody),
  ]);
  assert.ok(duplicateOrders.every(({ error }) => !error));
  assert.equal(duplicateOrders[0].data.order_id, duplicateOrders[1].data.order_id);
  orderIds.push(duplicateOrders[0].data.order_id);
  const otherRead = await must(
    participantTwo.client.from("payment_orders").select("id").eq("id", orderIds[0]),
    "horizontal order read",
  );
  assert.deepEqual(otherRead, []);
  const storageRead = await participantTwo.client.storage
    .from("payment-evidence")
    .download(`orders/${orderIds[0]}/forbidden.jpg`);
  assert.ok(storageRead.error, "actor lain tidak dapat membaca bucket privat");

  const underReview = await uploadAndSubmit(participantOne.client, orderIds[0], "happy");
  await verifyCoachEvidenceIsolation({
    coachClient: coach.client,
    orderId: orderIds[0],
    service,
  });
  await must(
    service
      .from("payment_orders")
      .update({ reservation_expires_at: new Date(Date.now() - 60_000).toISOString() })
      .eq("id", orderIds[0]),
    "move submitted reservation past expiry",
  );
  assert.equal(await rpc(service, "expire_payment_orders", {}), 0);
  assert.equal(
    (
      await must(
        service.from("payment_orders").select("status").eq("id", orderIds[0]).single(),
        "submitted reservation remains",
      )
    ).status,
    "under_review",
  );
  const decisions = await Promise.all([
    adminOne.client.rpc("approve_payment_order", {
      destination_matches: true,
      expected_version: underReview.version,
      reconciled_amount_minor: 250000,
      reconciliation_reference: "MUTASI-HAPPY-001",
      target_order_id: orderIds[0],
    }),
    adminTwo.client.rpc("approve_payment_order", {
      destination_matches: true,
      expected_version: underReview.version,
      reconciled_amount_minor: 250000,
      reconciliation_reference: "MUTASI-HAPPY-001",
      target_order_id: orderIds[0],
    }),
  ]);
  assert.ok(decisions.every(({ error, data }) => !error && data.status === "approved"));
  assert.equal(
    (await must(service.from("payment_ledger").select("id").eq("order_id", orderIds[0]), "ledger"))
      .length,
    1,
  );
  const reversal = await rpc(adminOne.client, "record_exceptional_reversal", {
    mark_completed: false,
    reconciliation_reference: "REVERSAL-HAPPY-001",
    resolution_note: "Pengembalian dana khusus sedang diproses.",
    target_order_id: orderIds[0],
  });
  assert.equal(reversal.status, "reversal_pending");
  const reversalReplay = await rpc(adminTwo.client, "record_exceptional_reversal", {
    mark_completed: false,
    reconciliation_reference: "REVERSAL-HAPPY-001",
    resolution_note: "Pengembalian dana khusus sedang diproses.",
    target_order_id: orderIds[0],
  });
  assert.equal(reversalReplay.status, "reversal_pending");
  assert.equal(
    (
      await must(
        service.from("payment_ledger").select("id").eq("order_id", orderIds[0]),
        "verified and reversal ledger",
      )
    ).length,
    2,
  );
  assert.equal(
    (
      await must(
        service.from("program_enrollments").select("status").eq("program_id", programs[0]),
        "enrollment",
      )
    )[0].status,
    "active",
  );

  const retryOrder = await rpc(participantTwo.client, "create_program_payment_order", {
    coach_qr_payload: "phase06-integration-coach-qr",
    request_idempotency_key: `phase06-retry-${randomUUID()}`,
    target_program_id: programs[1],
  });
  orderIds.push(retryOrder.order_id);
  let review = await uploadAndSubmit(participantTwo.client, retryOrder.order_id, "retry-1");
  for (let attempt = 1; attempt <= 3; attempt += 1) {
    const corrected = await rpc(adminOne.client, "reject_payment_evidence", {
      expected_version: review.version,
      rejection_reason: `Bukti ${attempt} belum cocok, unggah perbaikan.`,
      target_order_id: retryOrder.order_id,
    });
    if (attempt < 3)
      review = await uploadAndSubmit(
        participantTwo.client,
        retryOrder.order_id,
        `retry-${attempt + 1}`,
      );
    else assert.equal(corrected.status, "correction_required");
  }
  const fourth = await participantTwo.client.rpc("prepare_payment_evidence_attempt", {
    request_idempotency_key: `phase06-upload-four-${randomUUID()}`,
    target_order_id: retryOrder.order_id,
  });
  assert.match(fourth.error?.message ?? "", /evidence_attempt_limit/);

  await verifyExpiryAndRestoreCases({
    adminClient: adminOne.client,
    coach,
    orderIds,
    participantOne,
    participantTwo,
    programs,
    service,
  });

  await verifyAdminDecisionRace({
    adminOneClient: adminOne.client,
    adminTwoClient: adminTwo.client,
    orderIds,
    participantClient: participantTwo.client,
    programId: programs[4],
    service,
  });

  await must(
    service.from("coach_applications").insert({
      applicant_user_id: applicant.id,
      decided_at: new Date().toISOString(),
      decided_by: adminOne.id,
      display_name_snapshot: "Calon Coach Manual",
      draft_idempotency_key: `phase06-app-${randomUUID()}`,
      has_completed_hom_sts: true,
      has_completed_ict: true,
      id: coachApplicationId,
      member_level_snapshot: "supervisor",
      participant_profile_id: applicant.id,
      phone_number_snapshot: "+628600000099",
      status: "accepted_pending_payment",
      submitted_at: new Date().toISOString(),
      terms_version: "phase06-local",
    }),
    "coach applicant",
  );
  const coachOrder = await rpc(applicant.client, "create_coach_payment_order", {
    request_idempotency_key: `phase06-coach-order-${randomUUID()}`,
    target_application_id: coachApplicationId,
  });
  orderIds.push(coachOrder.order_id);
  let coachReview = await uploadAndSubmit(applicant.client, coachOrder.order_id, "coach-1");
  const coachCorrection = await rpc(adminOne.client, "reject_payment_evidence", {
    expected_version: coachReview.version,
    rejection_reason: "Referensi mutasi belum terlihat, unggah ulang.",
    target_order_id: coachOrder.order_id,
  });
  assert.equal(
    (
      await must(
        service.from("coach_applications").select("status").eq("id", coachApplicationId).single(),
        "accepted stays",
      )
    ).status,
    "accepted_pending_payment",
  );
  coachReview = await uploadAndSubmit(applicant.client, coachOrder.order_id, "coach-2");
  await rpc(adminOne.client, "approve_payment_order", {
    destination_matches: true,
    expected_version: coachReview.version,
    reconciled_amount_minor: 150000,
    reconciliation_reference: "MUTASI-COACH-001",
    target_order_id: coachOrder.order_id,
  });
  assert.equal(
    (
      await must(
        service.from("profiles").select("role").eq("user_id", applicant.id).single(),
        "coach role",
      )
    ).role,
    "coach",
  );
  assert.equal(
    (
      await must(
        service
          .from("coach_access_entitlements")
          .select("id")
          .eq("application_id", coachApplicationId),
        "coach entitlement",
      )
    ).length,
    1,
  );
  const firstCoachEntitlement = await must(
    service
      .from("coach_access_entitlements")
      .select("ends_at")
      .eq("application_id", coachApplicationId)
      .single(),
    "first Coach entitlement period",
  );
  const renewalOrder = await rpc(applicant.client, "create_coach_payment_order", {
    request_idempotency_key: `phase06-coach-renewal-${randomUUID()}`,
    target_application_id: coachApplicationId,
  });
  orderIds.push(renewalOrder.order_id);
  const renewalReview = await uploadAndSubmit(
    applicant.client,
    renewalOrder.order_id,
    "coach-renewal",
  );
  await rpc(adminOne.client, "approve_payment_order", {
    destination_matches: true,
    expected_version: renewalReview.version,
    reconciled_amount_minor: 150000,
    reconciliation_reference: "MUTASI-COACH-RENEWAL-001",
    target_order_id: renewalOrder.order_id,
  });
  const coachPeriods = await must(
    service
      .from("coach_access_entitlements")
      .select("starts_at,ends_at,period_sequence")
      .eq("application_id", coachApplicationId)
      .order("period_sequence"),
    "Coach renewal periods",
  );
  assert.equal(coachPeriods.length, 2);
  assert.equal(coachPeriods[1].starts_at, firstCoachEntitlement.ends_at);
  await verifyRetentionCleanup(service, databaseUrl, orderIds[0], participantOne.id);
  void coachCorrection;
  console.log("PASS Phase 06 manual payment atomicity/RLS/retention/retry scenarios");
} finally {
  await cleanup();
}
