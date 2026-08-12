import { createClient, type SupabaseClient, type User } from "@supabase/supabase-js";
import type { BrowserContext } from "@playwright/test";

import { addSupabaseSession, createIdentity, must } from "./phase06-browser-fixture";
import { createCoachAccessFixture } from "./phase08-coach-fixture";

const baseUrl = "http://127.0.0.1:3000";
const password = "Phase11A-participant-local-2026!";
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const publishableKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
const serviceKey = process.env.SUPABASE_TEST_SERVICE_ROLE_KEY;

function isLoopback(value: string | undefined) {
  if (!value) return false;
  try {
    return /^(127\.0\.0\.1|localhost|::1)$/.test(new URL(value).hostname);
  } catch {
    return false;
  }
}

export const hasParticipantVisualEnvironment = Boolean(
  isLoopback(supabaseUrl) && publishableKey && serviceKey,
);
export const participantVisualSkipReason =
  "Memerlukan URL, publishable key, dan service key Supabase lokal loopback.";

type FixtureIds = Readonly<{
  application: string;
  day: string;
  enrollment: string;
  entitlement: string;
  payment: string;
  program: string;
  step: string;
}>;

export type ParticipantVisualFixture = Readonly<{
  ids: FixtureIds;
  participant: User;
  service: SupabaseClient;
  users: readonly User[];
}>;

async function deleteUsers(service: SupabaseClient, users: readonly User[]) {
  for (const user of [...users].reverse()) {
    await must(service.auth.admin.deleteUser(user.id), "hapus user visual Peserta");
  }
}

async function deleteFixtureRows(service: SupabaseClient, ids: FixtureIds) {
  await service.from("program_scores").delete().eq("enrollment_id", ids.enrollment);
  await service.from("program_enrollments").delete().eq("id", ids.enrollment);
  await service.from("programs").delete().eq("id", ids.program);
  await service.from("coach_access_entitlements").delete().eq("id", ids.entitlement);
  await service.from("coach_payment_records").delete().eq("id", ids.payment);
  await service.from("coach_applications").delete().eq("id", ids.application);
}

export async function createParticipantVisualFixture(): Promise<ParticipantVisualFixture> {
  if (!hasParticipantVisualEnvironment || !supabaseUrl || !serviceKey) {
    throw new Error(participantVisualSkipReason);
  }
  const service = createClient(supabaseUrl, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const users: User[] = [];
  const ids = {
    application: crypto.randomUUID(),
    day: crypto.randomUUID(),
    enrollment: crypto.randomUUID(),
    entitlement: crypto.randomUUID(),
    payment: crypto.randomUUID(),
    program: crypto.randomUUID(),
    step: crypto.randomUUID(),
  };

  try {
    const administrator = await createIdentity(service, users, password, "phase11a-visual-admin");
    const coach = await createIdentity(service, users, password, "phase11a-visual-coach");
    const participant = await createIdentity(
      service,
      users,
      password,
      "phase11a-visual-participant",
    );
    const active = {
      finalized_at: new Date().toISOString(),
      onboarding_status: "active",
      provisional_expires_at: null,
    };
    await must(
      service
        .from("profiles")
        .update({ ...active, role: "admin" })
        .eq("user_id", administrator.id),
      "profil Admin visual",
    );
    await must(
      service
        .from("profiles")
        .update({
          ...active,
          city: "Denpasar",
          coach_biography: "Pendamping kebiasaan sehat untuk fixture lokal.",
          coach_is_approved: true,
          coach_is_public: true,
          coach_qr_identifier: `phase11a_visual_${coach.id.replaceAll("-", "_")}`,
          display_name: "Coach Pendamping Phase 11A",
          role: "coach",
        })
        .eq("user_id", coach.id),
      "profil Coach visual",
    );
    await must(
      service
        .from("profiles")
        .update({
          ...active,
          current_coach_id: coach.id,
          display_name: "Peserta Visual Phase 11A",
          member_level: "member",
          phone_number: "+6281111111107",
          role: "participant",
        })
        .eq("user_id", participant.id),
      "profil Peserta visual",
    );
    await createCoachAccessFixture(service, administrator, {
      applicationId: ids.application,
      coach,
      displayName: "Coach Pendamping Phase 11A",
      endsAt: new Date(Date.now() + 30 * 86_400_000).toISOString(),
      entitlementId: ids.entitlement,
      paymentId: ids.payment,
      status: "active",
    });

    const today = new Intl.DateTimeFormat("en-CA", {
      day: "2-digit",
      month: "2-digit",
      timeZone: "Asia/Jakarta",
      year: "numeric",
    }).format(new Date());
    await must(
      service.from("programs").insert({
        created_by: administrator.id,
        desired_price: null,
        duration_mode: "fixed_duration",
        ends_on: today,
        future_step_policy: "locked",
        id: ids.program,
        pace: "scheduled",
        past_step_policy: "read_only",
        points_per_activity: 10,
        points_per_weight_kg: 100,
        pricing_mode: "free",
        published_at: new Date().toISOString(),
        quiz_passing_percentage: 70,
        starts_on: today,
        status: "active",
        summary: "Program visual lokal tanpa data pribadi sensitif.",
        timezone: "Asia/Jakarta",
        title: "Program Fokus Phase 11A",
        wellness_disclaimer: "Program kebugaran non-diagnostik.",
      }),
      "program visual",
    );
    await must(
      service.from("program_days").insert({
        day_number: 1,
        id: ids.day,
        program_id: ids.program,
        scheduled_on: today,
        summary: "Mulai dari satu langkah yang aman.",
        title: "Hari fokus",
      }),
      "hari visual",
    );
    await must(
      service.from("program_steps").insert({
        completion_policy: "mark_complete",
        content_kind: "article",
        id: ids.step,
        instructions: "Baca panduan lalu lanjutkan saat siap.",
        program_day_id: ids.day,
        step_order: 1,
        title: "Panduan hari ini",
        verification_mode: "automatic",
      }),
      "langkah visual",
    );
    await must(
      service.from("program_enrollments").insert({
        coach_id: coach.id,
        id: ids.enrollment,
        participant_id: participant.id,
        program_id: ids.program,
        status: "active",
      }),
      "enrollment visual",
    );
    await must(
      service.from("program_scores").insert({ enrollment_id: ids.enrollment }),
      "skor visual",
    );
    return { ids, participant, service, users };
  } catch (error) {
    await deleteFixtureRows(service, ids).catch(() => undefined);
    await deleteUsers(service, users).catch(() => undefined);
    throw error;
  }
}

export async function cleanupParticipantVisualFixture(fixture: ParticipantVisualFixture) {
  await deleteFixtureRows(fixture.service, fixture.ids);
  await deleteUsers(fixture.service, fixture.users);
}

export async function addParticipantVisualSession(
  context: BrowserContext,
  fixture: ParticipantVisualFixture,
) {
  if (!supabaseUrl || !publishableKey || !fixture.participant.email) {
    throw new Error(participantVisualSkipReason);
  }
  await addSupabaseSession(context, {
    baseUrl,
    email: fixture.participant.email,
    password,
    publishableKey,
    supabaseUrl,
  });
}
