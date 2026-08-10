import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";

const apiUrl = requireEnvironment("API_URL");
const anonKey = requireEnvironment("ANON_KEY");
const serviceRoleKey = process.env.SECRET_KEY ?? requireEnvironment("SERVICE_ROLE_KEY");
assert.ok(
  ["127.0.0.1", "localhost", "::1"].includes(new URL(apiUrl).hostname),
  "Phase 05 integration hanya boleh menargetkan Supabase lokal",
);

const createdUsers = [];
const createdPrograms = Array.from({ length: 4 }, () => randomUUID());
const coachApplications = [randomUUID(), randomUUID()];
const coachPayments = [randomUUID(), randomUUID()];
const coachEntitlements = [randomUUID(), randomUUID()];

function requireEnvironment(name) {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

async function request(path, options = {}) {
  const token = options.token ?? serviceRoleKey;
  return fetch(`${apiUrl}${path}`, {
    body: options.body === undefined ? undefined : JSON.stringify(options.body),
    headers: {
      apikey: options.apiKey ?? serviceRoleKey,
      Authorization: `Bearer ${token}`,
      ...(options.body === undefined ? {} : { "Content-Type": "application/json" }),
      ...options.headers,
    },
    method: options.method ?? "GET",
  });
}

async function json(response) {
  const text = await response.text();
  return text ? JSON.parse(text) : null;
}

async function expectOk(response, label) {
  const payload = await json(response);
  assert.ok(response.ok, `${label}: HTTP ${response.status} ${JSON.stringify(payload)}`);
  return payload;
}

async function insert(table, rows) {
  await expectOk(
    await request(`/rest/v1/${table}`, {
      body: rows,
      headers: { Prefer: "return=minimal" },
      method: "POST",
    }),
    `insert ${table}`,
  );
}

async function patch(table, query, values) {
  await expectOk(
    await request(`/rest/v1/${table}?${query}`, {
      body: values,
      headers: { Prefer: "return=minimal" },
      method: "PATCH",
    }),
    `patch ${table}`,
  );
}

async function remove(table, query) {
  const response = await request(`/rest/v1/${table}?${query}`, {
    headers: { Prefer: "return=minimal" },
    method: "DELETE",
  });
  if (!response.ok)
    throw new Error(`cleanup ${table}: ${response.status} ${await response.text()}`);
}

async function select(table, query) {
  return expectOk(await request(`/rest/v1/${table}?${query}`), `select ${table}`);
}

async function createUser(label) {
  const id = randomUUID();
  const email = `phase05-${label}-${id}@local.invalid`;
  const password = `Phase05-${id}!`;
  const user = await expectOk(
    await request("/auth/v1/admin/users", {
      body: { email, email_confirm: true, password },
      method: "POST",
    }),
    `create ${label}`,
  );
  createdUsers.push(user.id);
  return { email, id: user.id, password };
}

async function signIn(user) {
  const session = await expectOk(
    await request("/auth/v1/token?grant_type=password", {
      apiKey: anonKey,
      body: { email: user.email, password: user.password },
      method: "POST",
      token: anonKey,
    }),
    `sign in ${user.email}`,
  );
  return session.access_token;
}

async function enroll(token, programId, qr) {
  const response = await request("/rest/v1/rpc/enroll_free_program", {
    apiKey: anonKey,
    body: { scanned_coach_qr: qr, target_program_id: programId },
    method: "POST",
    token,
  });
  const payload = await json(response);
  return { ok: response.ok, payload };
}

async function activateCoach(coach, admin, index) {
  await insert("coach_applications", {
    applicant_user_id: coach.id,
    decided_at: new Date().toISOString(),
    decided_by: admin.id,
    display_name_snapshot: `Coach Lokal ${index + 1}`,
    draft_idempotency_key: `phase05-coach-${index}-${randomUUID()}`,
    has_completed_hom_sts: true,
    has_completed_ict: true,
    id: coachApplications[index],
    member_level_snapshot: "sc",
    participant_profile_id: coach.id,
    phone_number_snapshot: `+62810000000${index}`,
    status: "active",
    submitted_at: new Date().toISOString(),
    terms_version: "phase05-local",
  });
  await insert("coach_payment_records", {
    amount_minor_units: 100_000,
    application_id: coachApplications[index],
    id: coachPayments[index],
    price_band: "entry",
    provider_reference: `phase05-local-${index}-${randomUUID()}`,
    state: "verified",
    verified_at: new Date().toISOString(),
  });
  await insert("coach_access_entitlements", {
    application_id: coachApplications[index],
    coach_user_id: coach.id,
    ends_at: new Date(Date.now() + 30 * 86_400_000).toISOString(),
    id: coachEntitlements[index],
    payment_record_id: coachPayments[index],
    starts_at: new Date(Date.now() - 86_400_000).toISOString(),
    status: "active",
  });
}

function programRow(id, adminId, title, participantLimit = null) {
  return {
    created_by: adminId,
    duration_mode: "fixed_duration",
    ends_on: "2026-08-31",
    future_step_policy: "locked",
    id,
    participant_limit: participantLimit,
    pace: "scheduled",
    past_step_policy: "available",
    points_per_activity: 10,
    points_per_weight_kg: 100,
    pricing_mode: "free",
    published_at: new Date().toISOString(),
    quiz_passing_percentage: 70,
    starts_on: "2026-08-01",
    status: "active",
    summary: "Fixture lokal Phase 05.",
    timezone: "Asia/Makassar",
    title,
    wellness_disclaimer: "Program kebugaran non-diagnostik.",
  };
}

async function cleanup() {
  const programFilter = `program_id=in.(${createdPrograms.join(",")})`;
  const enrollments = await select("program_enrollments", `${programFilter}&select=id`);
  if (enrollments.length > 0) {
    const ids = enrollments.map(({ id }) => id).join(",");
    await remove("program_scores", `enrollment_id=in.(${ids})`);
  }
  await remove("program_enrollments", programFilter);
  await remove("programs", `id=in.(${createdPrograms.join(",")})`);
  await remove("coach_access_entitlements", `id=in.(${coachEntitlements.join(",")})`);
  await remove("coach_payment_records", `id=in.(${coachPayments.join(",")})`);
  await remove("coach_applications", `id=in.(${coachApplications.join(",")})`);
  if (createdUsers.length > 0) {
    await remove("audit_events", `actor_id=in.(${createdUsers.join(",")})`);
  }
  for (const userId of [...createdUsers].reverse()) {
    const response = await request(`/auth/v1/admin/users/${userId}`, { method: "DELETE" });
    assert.ok(response.ok, `cleanup auth user ${userId}: HTTP ${response.status}`);
  }
  assert.equal(
    (await select("programs", `id=in.(${createdPrograms.join(",")})&select=id`)).length,
    0,
    "fixture program dibersihkan",
  );
}

try {
  const admin = await createUser("admin");
  const coaches = [await createUser("coach-one"), await createUser("coach-two")];
  const participants = await Promise.all(
    ["duplicate", "capacity-one", "capacity-two", "coach-race"].map(createUser),
  );
  const coachQr = [`coach-${randomUUID()}`, `coach-${randomUUID()}`];

  await patch("profiles", `user_id=eq.${admin.id}`, {
    display_name: "Admin Phase 05",
    finalized_at: new Date().toISOString(),
    onboarding_status: "active",
    provisional_expires_at: null,
    role: "admin",
  });
  for (const [index, coach] of coaches.entries()) {
    await patch("profiles", `user_id=eq.${coach.id}`, {
      coach_is_approved: true,
      coach_qr_identifier: coachQr[index],
      display_name: `Coach Lokal ${index + 1}`,
      finalized_at: new Date().toISOString(),
      onboarding_status: "active",
      provisional_expires_at: null,
      role: "coach",
    });
    await activateCoach(coach, admin, index);
  }
  for (const [index, participant] of participants.entries()) {
    await patch("profiles", `user_id=eq.${participant.id}`, {
      display_name: `Peserta Lokal ${index + 1}`,
      finalized_at: new Date().toISOString(),
      onboarding_status: "active",
      provisional_expires_at: null,
      role: "participant",
    });
  }
  await insert("programs", [
    programRow(createdPrograms[0], admin.id, "Program Duplikat"),
    programRow(createdPrograms[1], admin.id, "Program Kapasitas", 1),
    programRow(createdPrograms[2], admin.id, "Program Coach Satu"),
    programRow(createdPrograms[3], admin.id, "Program Coach Dua"),
  ]);

  const publicPrograms = await expectOk(
    await request("/rest/v1/rpc/list_public_programs", {
      apiKey: anonKey,
      body: { result_limit: 50, result_offset: 0, target_program_id: null },
      method: "POST",
      token: anonKey,
    }),
    "Guest list public programs",
  );
  const ownFixture = publicPrograms.find(({ id }) => id === createdPrograms[0]);
  assert.ok(ownFixture, "program published muncul pada katalog Guest");
  assert.equal(ownFixture.created_by, undefined, "creator identity tidak bocor");
  assert.equal(ownFixture.coach_qr_identifier, undefined, "QR Coach tidak bocor");

  const tokens = await Promise.all(participants.map(signIn));
  const duplicate = await Promise.all([
    enroll(tokens[0], createdPrograms[0], coachQr[0]),
    enroll(tokens[0], createdPrograms[0], coachQr[0]),
  ]);
  assert.ok(
    duplicate.every(({ ok }) => ok),
    "duplicate click sama-sama idempoten",
  );
  assert.equal(
    duplicate[0].payload.id,
    duplicate[1].payload.id,
    "duplicate mengembalikan row sama",
  );
  assert.equal(
    (
      await select(
        "program_scores",
        `enrollment_id=eq.${duplicate[0].payload.id}&select=enrollment_id`,
      )
    ).length,
    1,
    "free enrollment membuat tepat satu score",
  );

  const capacity = await Promise.all([
    enroll(tokens[1], createdPrograms[1], coachQr[0]),
    enroll(tokens[2], createdPrograms[1], coachQr[0]),
  ]);
  assert.equal(capacity.filter(({ ok }) => ok).length, 1, "capacity race menerima satu peserta");
  assert.equal(
    capacity.filter(({ payload }) => payload?.message === "program_full").length,
    1,
    "capacity race menolak satu peserta dengan program_full",
  );

  const coachRace = await Promise.all([
    enroll(tokens[3], createdPrograms[2], coachQr[0]),
    enroll(tokens[3], createdPrograms[3], coachQr[1]),
  ]);
  assert.equal(coachRace.filter(({ ok }) => ok).length, 1, "same-Coach race menerima satu Coach");
  assert.equal(
    coachRace.filter(({ payload }) => payload?.message === "coach_mismatch").length,
    1,
    "same-Coach race menolak Coach berbeda",
  );

  const participantTwoView = await expectOk(
    await request(
      `/rest/v1/program_enrollments?participant_id=eq.${participants[0].id}&select=id`,
      { apiKey: anonKey, token: tokens[1] },
    ),
    "BOLA enrollment read",
  );
  assert.deepEqual(participantTwoView, [], "peserta lain tidak dapat membaca enrollment target");
  console.log("PASS Phase 05 enrollment/public/BOLA races (12 assertions)");
} finally {
  await cleanup();
}
