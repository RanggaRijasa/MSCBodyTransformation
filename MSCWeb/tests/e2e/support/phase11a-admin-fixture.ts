import { createClient, type SupabaseClient, type User } from "@supabase/supabase-js";
import type { BrowserContext } from "@playwright/test";
import { readFile } from "node:fs/promises";

import { addSupabaseSession, createIdentity, must } from "./phase06-browser-fixture";

const baseUrl = "http://127.0.0.1:3000";
const password = "Phase11A-admin-visual-local-2026!";

type VisualFixture = Readonly<{
  administrator: User;
  password: string;
  posterAlternativeText: string;
  posterMediaPath: string;
  programId: string;
  programTitle: string;
  publishableKey: string;
  service: SupabaseClient;
  supabaseUrl: string;
  users: readonly User[];
}>;

function programPayload(programId: string, programTitle: string) {
  const today = new Intl.DateTimeFormat("en-CA", {
    day: "2-digit",
    month: "2-digit",
    timeZone: "Asia/Makassar",
    year: "numeric",
  }).format(new Date());
  const tomorrow = new Intl.DateTimeFormat("en-CA", {
    day: "2-digit",
    month: "2-digit",
    timeZone: "Asia/Makassar",
    year: "numeric",
  }).format(new Date(Date.now() + 86_400_000));
  return {
    days: [
      {
        day_number: 1,
        id: crypto.randomUUID(),
        scheduled_on: today,
        steps: [
          {
            completion_policy: "mark_complete",
            content_kind: "article",
            id: crypto.randomUUID(),
            instructions: "Baca panduan operasional visual.",
            questions: [],
            step_order: 1,
            title: "Panduan pembuka",
            verification_mode: "automatic",
          },
        ],
        title: "Hari pertama",
      },
    ],
    desired_price: null,
    duration_mode: "fixed_duration",
    ends_on: tomorrow,
    future_step_policy: "locked",
    id: programId,
    pace: "scheduled",
    participant_limit: 25,
    past_step_policy: "available",
    points_per_activity: 10,
    points_per_weight_kg: 100,
    pricing_mode: "free",
    quiz_passing_percentage: 70,
    registration_closes_at: new Date(Date.now() + 86_400_000).toISOString(),
    starts_on: today,
    summary: "Fixture lokal deterministik untuk penerimaan visual Admin.",
    timezone: "Asia/Makassar",
    title: programTitle,
    wellness_disclaimer: "Program kebugaran non-diagnostik.",
  };
}

export async function createAdminVisualFixture(): Promise<VisualFixture> {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const publishableKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
  const serviceKey = process.env.SUPABASE_TEST_SERVICE_ROLE_KEY;
  if (!supabaseUrl || !publishableKey || !serviceKey)
    throw new Error("Lingkungan Supabase lokal Admin tidak lengkap.");
  if (!/^(127\.0\.0\.1|localhost)$/.test(new URL(supabaseUrl).hostname))
    throw new Error("Fixture Admin hanya boleh memakai Supabase loopback.");

  const service = createClient(supabaseUrl, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const users: User[] = [];
  const programId = crypto.randomUUID();
  const programTitle = `Program visual Admin ${crypto.randomUUID().slice(0, 8)}`;
  const snapshotId = crypto.randomUUID();
  const posterId = crypto.randomUUID();
  const posterAlternativeText = "Poster pemenang fixture visual Admin";
  const posterMediaPath = `winners/${posterId}/poster.jpg`;
  const administrator = await createIdentity(service, users, password, "phase11a-admin-visual");
  try {
    const active = {
      finalized_at: new Date().toISOString(),
      onboarding_status: "active",
      provisional_expires_at: null,
    };
    await must(
      service
        .from("profiles")
        .update({
          ...active,
          display_name: "Admin Visual Phase 11A",
          member_level: "world_team",
          role: "admin",
        })
        .eq("user_id", administrator.id),
      "profil Admin visual",
    );
    const authenticated = createClient(supabaseUrl, publishableKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
    await must(
      authenticated.auth.signInWithPassword({ email: administrator.email ?? "", password }),
      "login Admin visual",
    );
    await must(
      authenticated.rpc("save_program_draft", {
        program_payload: programPayload(programId, programTitle),
        request_idempotency_key: `phase11a-admin-${crypto.randomUUID()}`,
      }),
      "draft visual Admin",
    );
    await must(
      service.from("winner_snapshots").insert({
        id: snapshotId,
        locked_at: new Date().toISOString(),
        locked_by: administrator.id,
        program_id: programId,
      }),
      "snapshot visual Admin",
    );
    const jpeg = await readFile(
      new URL("../../../public/images/pwa-participant-rc-v1.jpg", import.meta.url),
    );
    await must(
      service.storage.from("public-media").upload(posterMediaPath, jpeg, {
        contentType: "image/jpeg",
        upsert: false,
      }),
      "media poster visual Admin",
    );
    await must(
      service.from("winner_posters").insert({
        alt_text: posterAlternativeText,
        id: posterId,
        is_published: true,
        media_path: posterMediaPath,
        program_id: programId,
        published_at: new Date().toISOString(),
        winner_snapshot_id: snapshotId,
      }),
      "poster visual Admin",
    );
  } catch (error) {
    await cleanupAdminResources(service, posterMediaPath, programId, users);
    throw error;
  }
  return {
    administrator,
    password,
    posterAlternativeText,
    posterMediaPath,
    programId,
    programTitle,
    publishableKey,
    service,
    supabaseUrl,
    users,
  };
}

export async function addAdminVisualSession(context: BrowserContext, fixture: VisualFixture) {
  await addSupabaseSession(context, {
    baseUrl,
    email: fixture.administrator.email ?? "",
    password: fixture.password,
    publishableKey: fixture.publishableKey,
    supabaseUrl: fixture.supabaseUrl,
  });
}

export async function cleanupAdminVisualFixture(fixture: VisualFixture | undefined) {
  if (!fixture) return;
  await cleanupAdminResources(
    fixture.service,
    fixture.posterMediaPath,
    fixture.programId,
    fixture.users,
  );
}

async function cleanupAdminResources(
  service: SupabaseClient,
  posterMediaPath: string,
  programId: string,
  users: readonly User[],
) {
  await must(service.storage.from("public-media").remove([posterMediaPath]), "cleanup media Admin");
  await must(
    service.from("winner_posters").delete().eq("program_id", programId),
    "cleanup poster Admin",
  );
  await must(
    service.from("winner_snapshots").delete().eq("program_id", programId),
    "cleanup snapshot Admin",
  );
  await must(service.from("programs").delete().eq("id", programId), "cleanup program Admin");
  for (const user of [...users].reverse()) {
    const result = await service.auth.admin.deleteUser(user.id);
    if (result.error) throw new Error(`cleanup identity Admin: ${result.error.message}`);
  }
}
