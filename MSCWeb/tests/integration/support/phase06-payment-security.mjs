import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";

import { must, rpc, uploadAndSubmit } from "./phase06-payment-fixture.mjs";

export async function verifyCoachEvidenceIsolation({ coachClient, orderId, service }) {
  const existingEvidence = await must(
    service
      .from("payment_evidence_attempts")
      .select("object_path")
      .eq("order_id", orderId)
      .single(),
    "existing private evidence path",
  );
  const coachMetadataRead = await must(
    coachClient.from("payment_evidence_attempts").select("id").eq("order_id", orderId),
    "Coach evidence metadata horizontal read",
  );
  assert.deepEqual(coachMetadataRead, []);
  const coachObjectRead = await coachClient.storage
    .from("payment-evidence")
    .download(existingEvidence.object_path);
  assert.ok(coachObjectRead.error, "Coach tidak dapat membaca object bukti Participant");
}

export async function verifyAdminDecisionRace({
  adminOneClient,
  adminTwoClient,
  orderIds,
  participantClient,
  programId,
  service,
}) {
  const order = await rpc(participantClient, "create_program_payment_order", {
    coach_qr_payload: "phase06-integration-coach-qr",
    request_idempotency_key: `phase06-decision-race-${randomUUID()}`,
    target_program_id: programId,
  });
  orderIds.push(order.order_id);
  const review = await uploadAndSubmit(service, participantClient, order.order_id, "decision-race");
  const decisions = await Promise.all([
    adminOneClient.rpc("approve_payment_order", {
      destination_matches: true,
      expected_version: review.version,
      reconciled_amount_minor: 250000,
      reconciliation_reference: "MUTASI-RACE-001",
      target_order_id: order.order_id,
    }),
    adminTwoClient.rpc("reject_payment_evidence", {
      expected_version: review.version,
      rejection_reason: "Bukti race ditolak oleh keputusan Admin yang menang.",
      target_order_id: order.order_id,
    }),
  ]);
  assert.equal(decisions.filter(({ error }) => error === null).length, 1);
  const finalOrder = await must(
    service.from("payment_orders").select("status").eq("id", order.order_id).single(),
    "decision race final state",
  );
  assert.ok(["approved", "correction_required"].includes(finalOrder.status));
  const ledger = await must(
    service.from("payment_ledger").select("id").eq("order_id", order.order_id),
    "decision race ledger",
  );
  assert.equal(ledger.length, finalOrder.status === "approved" ? 1 : 0);
}
