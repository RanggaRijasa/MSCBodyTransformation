import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";

const apiURL = requireEnvironment("API_URL");
const anonKey = process.env.ANON_KEY ?? requireEnvironment("PUBLISHABLE_KEY");
const serviceRoleKey = process.env.SERVICE_ROLE_KEY
  ?? requireEnvironment("SECRET_KEY");

assert.ok(
  ["127.0.0.1", "localhost", "::1"].includes(new URL(apiURL).hostname),
  "Phase 11 race test must target local Supabase",
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

async function json(response) {
  const value = await response.text();
  return value ? JSON.parse(value) : null;
}

async function success(response, label) {
  const body = await json(response);
  assert.ok(
    response.ok,
    `${label}: HTTP ${response.status} ${JSON.stringify(body)}`,
  );
  return body;
}

async function createUser(label) {
  const suffix = randomUUID();
  const email = `${label}-${suffix}@test.invalid`;
  const password = `Phase11-${suffix}!`;
  const user = await success(
    await request("/auth/v1/admin/users", {
      method: "POST",
      body: { email, password, email_confirm: true },
    }),
    `create ${label}`,
  );
  return { id: user.id, email, password };
}

async function signIn(user) {
  const session = await success(
    await request("/auth/v1/token?grant_type=password", {
      method: "POST",
      token: anonKey,
      apiKey: anonKey,
      body: { email: user.email, password: user.password },
    }),
    `sign in ${user.email}`,
  );
  return session.access_token;
}

async function patchProfile(userID, body) {
  await success(
    await request(`/rest/v1/profiles?user_id=eq.${userID}`, {
      method: "PATCH",
      body,
      prefer: "return=minimal",
    }),
    "patch profile fixture",
  );
}

async function rpc(token, name, body) {
  return request(`/rest/v1/rpc/${name}`, {
    method: "POST",
    token,
    apiKey: anonKey,
    body,
  });
}

let admin;
let applicant;
try {
  admin = await createUser("phase11-race-admin");
  applicant = await createUser("phase11-race-applicant");
  const active = {
    onboarding_status: "active",
    provisional_expires_at: null,
    finalized_at: new Date().toISOString(),
  };
  await patchProfile(admin.id, {
    ...active,
    role: "admin",
    display_name: "Admin Phase 11 Race",
  });
  await patchProfile(applicant.id, {
    ...active,
    role: "participant",
    display_name: "Calon Coach Phase 11 Race",
    phone_number: "+6281200001100",
    member_level: "sc",
  });

  const adminToken = await signIn(admin);
  const applicantToken = await signIn(applicant);
  const draft = await success(
    await rpc(applicantToken, "save_my_coach_application_draft", {
      member_level: "sc",
      applicant_has_completed_hom_sts: true,
      applicant_has_completed_ict: true,
      accepted_terms_version: "terms-phase11-race",
      request_idempotency_key: `draft-${randomUUID()}`,
    }),
    "save application draft",
  );
  await success(
    await rpc(applicantToken, "submit_my_coach_application", {
      target_application_id: draft.id,
      request_idempotency_key: `submit-${randomUUID()}`,
    }),
    "submit application",
  );

  const forbiddenPayment = await request("/rest/v1/coach_payment_records", {
    method: "POST",
    token: applicantToken,
    apiKey: anonKey,
    body: {
      application_id: draft.id,
      state: "verified",
      price_band: "entry",
      amount_minor_units: 100000,
      duration_months: 3,
    },
  });
  assert.equal(
    forbiddenPayment.ok,
    false,
    "Applicant must not create verified payment state",
  );

  const [approve, reject] = await Promise.all([
    rpc(adminToken, "decide_coach_application", {
      target_application_id: draft.id,
      decision: "approved",
      decision_reason: null,
      request_idempotency_key: `approve-${randomUUID()}`,
    }),
    rpc(adminToken, "decide_coach_application", {
      target_application_id: draft.id,
      decision: "rejected",
      decision_reason: "Keputusan balapan deterministik.",
      request_idempotency_key: `reject-${randomUUID()}`,
    }),
  ]);
  assert.equal(
    Number(approve.ok) + Number(reject.ok),
    1,
    "Concurrent approve/reject must produce exactly one terminal success",
  );

  const aggregate = await success(
    await request(
      `/rest/v1/coach_applications?id=eq.${draft.id}&select=status`,
    ),
    "read terminal application fixture",
  );
  assert.ok(
    ["accepted_pending_payment", "rejected"].includes(aggregate[0]?.status),
    "Application must have one terminal status",
  );

  console.log("Phase 11 Coach application race checks passed: 4");
} finally {
  for (const user of [applicant, admin]) {
    if (!user?.id) continue;
    await request(`/auth/v1/admin/users/${user.id}`, { method: "DELETE" });
  }
}
