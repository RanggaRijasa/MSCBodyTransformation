import { createClient, type SupabaseClient, type User } from "@supabase/supabase-js";
import type { BrowserContext } from "@playwright/test";

import { addSupabaseSession, createIdentity, must } from "./phase06-browser-fixture";
import { createCoachAccessFixture } from "./phase08-coach-fixture";

const baseUrl = "http://127.0.0.1:3000";
const password = "Phase11A-shell-local-2026!";
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const publishableKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
const serviceKey = process.env.SUPABASE_TEST_SERVICE_ROLE_KEY;

function isLoopbackUrl(value: string | undefined) {
  if (!value) return false;
  try {
    return /^(127\.0\.0\.1|localhost|::1)$/.test(new URL(value).hostname);
  } catch {
    return false;
  }
}

export const hasPhase11AShellAuthEnvironment = Boolean(
  isLoopbackUrl(supabaseUrl) && publishableKey && serviceKey,
);

export const phase11AShellAuthSkipReason =
  "Memerlukan NEXT_PUBLIC_SUPABASE_URL loopback, publishable key, dan service key lokal.";

type ShellActor = "admin" | "coach";

type FixtureIds = Readonly<{
  application: string;
  entitlement: string;
  payment: string;
}>;

export type Phase11AShellFixture = Readonly<{
  administrator: User;
  coach: User;
  ids: FixtureIds;
  service: SupabaseClient;
  users: readonly User[];
}>;

async function deleteFixtureRows(service: SupabaseClient, ids: FixtureIds) {
  await must(
    service.from("coach_access_entitlements").delete().eq("id", ids.entitlement),
    "hapus akses Coach shell",
  );
  await must(
    service.from("coach_payment_records").delete().eq("id", ids.payment),
    "hapus pembayaran Coach shell",
  );
  await must(
    service.from("coach_applications").delete().eq("id", ids.application),
    "hapus pengajuan Coach shell",
  );
}

async function deleteUsers(service: SupabaseClient, users: readonly User[]) {
  for (const user of [...users].reverse()) {
    await must(service.auth.admin.deleteUser(user.id), "hapus user shell");
  }
}

export async function createPhase11AShellFixture(): Promise<Phase11AShellFixture> {
  if (!hasPhase11AShellAuthEnvironment || !supabaseUrl || !serviceKey) {
    throw new Error(phase11AShellAuthSkipReason);
  }

  const service = createClient(supabaseUrl, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const users: User[] = [];
  const ids = {
    application: crypto.randomUUID(),
    entitlement: crypto.randomUUID(),
    payment: crypto.randomUUID(),
  };

  try {
    const administrator = await createIdentity(service, users, password, "phase11a-shell-admin");
    const coach = await createIdentity(service, users, password, "phase11a-shell-coach");
    const activeProfile = {
      finalized_at: new Date().toISOString(),
      onboarding_status: "active",
      provisional_expires_at: null,
    };

    await must(
      service
        .from("profiles")
        .update({
          ...activeProfile,
          display_name: "Admin Shell Phase 11A",
          role: "admin",
        })
        .eq("user_id", administrator.id),
      "profil Admin shell",
    );
    await must(
      service
        .from("profiles")
        .update({
          ...activeProfile,
          coach_biography: "Pendamping kebiasaan sehat untuk fixture lokal.",
          coach_is_approved: true,
          coach_is_public: true,
          coach_qr_identifier: `phase11a_shell_${coach.id.replaceAll("-", "_")}`,
          city: "Denpasar",
          display_name: "Coach Shell Phase 11A",
          role: "coach",
        })
        .eq("user_id", coach.id),
      "profil Coach shell",
    );
    await createCoachAccessFixture(service, administrator, {
      applicationId: ids.application,
      coach,
      displayName: "Coach Shell Phase 11A",
      endsAt: new Date(Date.now() + 30 * 86_400_000).toISOString(),
      entitlementId: ids.entitlement,
      paymentId: ids.payment,
      status: "active",
    });

    return { administrator, coach, ids, service, users };
  } catch (error) {
    try {
      await deleteFixtureRows(service, ids);
      await deleteUsers(service, users);
    } catch {
      // Pertahankan kegagalan setup asli; afterAll tidak tersedia untuk fixture yang belum jadi.
    }
    throw error;
  }
}

export async function cleanupPhase11AShellFixture(fixture: Phase11AShellFixture) {
  await deleteFixtureRows(fixture.service, fixture.ids);
  await deleteUsers(fixture.service, fixture.users);
}

export async function addPhase11AShellSession(
  context: BrowserContext,
  fixture: Phase11AShellFixture,
  actor: ShellActor,
) {
  if (!supabaseUrl || !publishableKey) throw new Error(phase11AShellAuthSkipReason);
  const user = actor === "admin" ? fixture.administrator : fixture.coach;
  if (!user.email) throw new Error(`Email fixture ${actor} tidak tersedia.`);
  await addSupabaseSession(context, {
    baseUrl,
    email: user.email,
    password,
    publishableKey,
    supabaseUrl,
  });
}
