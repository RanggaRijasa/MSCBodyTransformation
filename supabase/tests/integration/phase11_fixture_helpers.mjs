import { randomUUID } from "node:crypto";

export async function activateCoachEntitlement(
  insert,
  coachID,
  adminID,
  label,
) {
  const applicationID = randomUUID();
  const paymentID = randomUUID();
  await insert("coach_applications", {
    id: applicationID,
    applicant_user_id: coachID,
    participant_profile_id: coachID,
    display_name_snapshot: label,
    phone_number_snapshot: "+6281200000000",
    member_level_snapshot: "sc",
    has_completed_hom_sts: true,
    has_completed_ict: true,
    terms_version: "integration-v1",
    status: "active",
    draft_idempotency_key: `fixture-${randomUUID()}`,
    submitted_at: new Date().toISOString(),
    decided_at: new Date().toISOString(),
    decided_by: adminID,
  });
  await insert("coach_payment_records", {
    id: paymentID,
    application_id: applicationID,
    state: "verified",
    price_band: "entry",
    amount_minor_units: 100000,
    duration_months: 3,
    provider_reference: `fixture-${randomUUID()}`,
    verified_at: new Date().toISOString(),
  });
  await insert("coach_access_entitlements", {
    application_id: applicationID,
    payment_record_id: paymentID,
    coach_user_id: coachID,
    status: "active",
    starts_at: new Date(Date.now() - 60_000).toISOString(),
    ends_at: new Date(Date.now() + 90 * 86_400_000).toISOString(),
  });
  return { applicationID, paymentID };
}
