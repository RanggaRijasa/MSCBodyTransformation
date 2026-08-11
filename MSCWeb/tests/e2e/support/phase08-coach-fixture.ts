import type { SupabaseClient, User } from "@supabase/supabase-js";

import { must } from "./phase06-browser-fixture";

export async function createCoachAccessFixture(
  service: SupabaseClient,
  administrator: User,
  input: Readonly<{
    applicationId: string;
    coach: User;
    displayName: string;
    endsAt: string;
    entitlementId: string;
    paymentId: string;
    status: "active" | "expired";
  }>,
) {
  const startsAt =
    input.status === "expired"
      ? new Date(new Date(input.endsAt).getTime() - 30 * 86_400_000).toISOString()
      : new Date(Date.now() - 86_400_000).toISOString();
  await must(
    service.from("coach_applications").insert({
      applicant_user_id: input.coach.id,
      decided_at: new Date().toISOString(),
      decided_by: administrator.id,
      display_name_snapshot: input.displayName,
      draft_idempotency_key: `phase08-${crypto.randomUUID()}`,
      has_completed_hom_sts: true,
      has_completed_ict: true,
      id: input.applicationId,
      member_level_snapshot: "sc",
      participant_profile_id: input.coach.id,
      phone_number_snapshot: "+628700000008",
      status: input.status,
      submitted_at: new Date().toISOString(),
      terms_version: "phase08-local",
    }),
    `aplikasi ${input.displayName}`,
  );
  await must(
    service.from("coach_payment_records").insert({
      amount_minor_units: 100000,
      application_id: input.applicationId,
      id: input.paymentId,
      price_band: "entry",
      provider_reference: `phase08-${crypto.randomUUID()}`,
      state: "verified",
      verified_at: new Date().toISOString(),
    }),
    `pembayaran ${input.displayName}`,
  );
  await must(
    service.from("coach_access_entitlements").insert({
      application_id: input.applicationId,
      coach_user_id: input.coach.id,
      ends_at: input.endsAt,
      id: input.entitlementId,
      payment_record_id: input.paymentId,
      starts_at: startsAt,
      status: input.status,
    }),
    `akses ${input.displayName}`,
  );
}
