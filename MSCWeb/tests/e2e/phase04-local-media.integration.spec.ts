import { createServerClient } from "@supabase/ssr";
import { createClient } from "@supabase/supabase-js";
import { expect, test } from "@playwright/test";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const publishableKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
const serviceRoleKey = process.env.SUPABASE_TEST_SERVICE_ROLE_KEY;
const baseUrl = "http://127.0.0.1:3000";
const email = "phase04-coach-qr@local.invalid";
const password = "Phase04-local-only-2026!";

test.skip(
  !supabaseUrl || !publishableKey || !serviceRoleKey,
  "Memerlukan credential runtime Supabase lokal.",
);

test("Coach terverifikasi menerima QR visual privat tanpa payload mentah", async ({ context }) => {
  if (!supabaseUrl || !publishableKey || !serviceRoleKey) {
    throw new Error("Konfigurasi integration test Supabase lokal tidak tersedia.");
  }
  expect(new URL(supabaseUrl).hostname).toMatch(/^(127\.0\.0\.1|localhost)$/);
  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: existing } = await admin.auth.admin.listUsers({ page: 1, perPage: 1_000 });
  const oldUser = existing.users.find((candidate) => candidate.email === email);
  if (oldUser) await admin.auth.admin.deleteUser(oldUser.id);
  const { data, error } = await admin.auth.admin.createUser({
    email,
    email_confirm: true,
    password,
    user_metadata: { display_name: "Coach lokal Phase 04" },
  });
  if (error || !data.user) throw error ?? new Error("Coach lokal tidak dibuat.");
  const rawIdentifier = "phase04-local-coach-opaque-qr";

  try {
    const { error: profileError } = await admin
      .from("profiles")
      .update({
        coach_is_approved: true,
        coach_qr_identifier: rawIdentifier,
        finalized_at: new Date().toISOString(),
        onboarding_status: "active",
        provisional_expires_at: null,
        role: "coach",
      })
      .eq("user_id", data.user.id);
    if (profileError) throw profileError;

    const cookieJar = new Map<string, string>();
    const authClient = createServerClient(supabaseUrl, publishableKey, {
      cookies: {
        getAll: () => [...cookieJar].map(([name, value]) => ({ name, value })),
        setAll: (values) => {
          for (const { name, value } of values) cookieJar.set(name, value);
        },
      },
    });
    const { error: signInError } = await authClient.auth.signInWithPassword({ email, password });
    if (signInError) throw signInError;
    await context.addCookies(
      [...cookieJar].map(([name, value]) => ({ name, value, url: baseUrl })),
    );

    const response = await context.request.get("/api/coach/qr-image");
    expect(response.status()).toBe(200);
    expect(response.headers()["content-type"]).toContain("image/svg+xml");
    expect(response.headers()["cache-control"]).toContain("no-store");
    expect(response.headers()["content-security-policy"]).toContain("default-src 'none'");
    const svg = await response.text();
    expect(svg).toContain("<svg");
    expect(svg).not.toContain(rawIdentifier);
  } finally {
    await admin.auth.admin.deleteUser(data.user.id);
  }
});
