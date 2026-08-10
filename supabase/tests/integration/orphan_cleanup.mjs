import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";

const apiURL = requireEnvironment("API_URL");
const anonKey = process.env.ANON_KEY ?? requireEnvironment("PUBLISHABLE_KEY");
const serviceRoleKey = process.env.SERVICE_ROLE_KEY
  ?? requireEnvironment("SECRET_KEY");
const scheduledFunctionKey = process.env.SECRET_KEY ?? serviceRoleKey;

assert.ok(
  ["127.0.0.1", "localhost", "::1"].includes(new URL(apiURL).hostname),
  "Orphan cleanup test must target local Supabase",
);

function requireEnvironment(name) {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

async function request(path, {
  method = "GET",
  token = serviceRoleKey,
  apiKey = serviceRoleKey,
  body,
  prefer,
} = {}) {
  return fetch(`${apiURL}${path}`, {
    method,
    headers: {
      apikey: apiKey,
      Authorization: `Bearer ${token}`,
      ...(body === undefined ? {} : { "Content-Type": "application/json" }),
      ...(prefer ? { Prefer: prefer } : {}),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
}

async function payload(response) {
  const text = await response.text();
  return text ? JSON.parse(text) : null;
}

async function createUser(label) {
  const suffix = randomUUID();
  const email = `${label}-${suffix}@test.invalid`;
  const password = `Phase11-${suffix}!`;
  const response = await request("/auth/v1/admin/users", {
    method: "POST",
    body: { email, password, email_confirm: true },
  });
  assert.ok(response.ok, `Unable to create ${label}`);
  return { ...(await payload(response)), email, password };
}

async function signIn(user) {
  const response = await request("/auth/v1/token?grant_type=password", {
    method: "POST",
    token: anonKey,
    apiKey: anonKey,
    body: { email: user.email, password: user.password },
  });
  assert.ok(response.ok, `Unable to sign in ${user.email}`);
  return (await payload(response)).access_token;
}

let admin;
let participant;
try {
  admin = await createUser("phase11-cleanup-admin");
  participant = await createUser("phase11-cleanup-participant");
  const active = {
    onboarding_status: "active",
    provisional_expires_at: null,
    finalized_at: new Date().toISOString(),
  };
  for (const [user, role] of [[admin, "admin"], [participant, "participant"]]) {
    const response = await request(`/rest/v1/profiles?user_id=eq.${user.id}`, {
      method: "PATCH",
      body: { ...active, role, display_name: `Cleanup ${role}` },
      prefer: "return=minimal",
    });
    assert.ok(response.ok, `Unable to activate ${role} fixture`);
  }

  const participantToken = await signIn(participant);
  const denied = await request(
    "/functions/v1/cleanup-orphan-question-photos",
    {
      method: "POST",
      token: participantToken,
      apiKey: anonKey,
      body: { older_than_hours: 24, reason: "Tidak diizinkan." },
    },
  );
  assert.equal(denied.status, 403, "Participant cleanup must be denied");

  const scheduled = await request(
    "/functions/v1/cleanup-orphan-question-photos",
    {
      method: "POST",
      token: scheduledFunctionKey,
      apiKey: scheduledFunctionKey,
      body: {
        older_than_hours: 24,
        reason: "Pembersihan terjadwal Phase 13.1.",
      },
    },
  );
  const scheduledBody = await payload(scheduled);
  assert.ok(
    scheduled.ok,
    `Scheduled cleanup failed: ${JSON.stringify(scheduledBody)}`,
  );
  assert.equal(
    scheduledBody.deleted_count,
    0,
    "Scheduled service cleanup should accept a clean database",
  );

  const adminToken = await signIn(admin);
  const oversized = await request(
    "/functions/v1/cleanup-orphan-question-photos",
    {
      method: "POST",
      token: adminToken,
      apiKey: anonKey,
      body: {
        older_than_hours: 24,
        reason: "x".repeat(8_192),
      },
    },
  );
  assert.equal(oversized.status, 422, "Oversized cleanup body must be denied");

  const cleanup = await request(
    "/functions/v1/cleanup-orphan-question-photos",
    {
      method: "POST",
      token: adminToken,
      apiKey: anonKey,
      body: {
        older_than_hours: 24,
        reason: "Verifikasi cleanup Phase 11.",
      },
    },
  );
  const cleanupBody = await payload(cleanup);
  assert.ok(
    cleanup.ok,
    `Admin cleanup failed: ${JSON.stringify(cleanupBody)}`,
  );
  assert.equal(
    cleanupBody.deleted_count,
    0,
    "Clean database should have no expired orphan objects",
  );
  console.log("Phase 11 orphan cleanup checks passed: 4");
} finally {
  for (const user of [participant, admin]) {
    if (!user?.id) continue;
    await request(`/auth/v1/admin/users/${user.id}`, { method: "DELETE" });
  }
}
