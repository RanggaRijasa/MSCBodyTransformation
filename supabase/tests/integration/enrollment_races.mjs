import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";

const apiURL = requireEnvironment("API_URL");
const anonKey = requireEnvironment("ANON_KEY");
const serviceRoleKey = requireEnvironment("SERVICE_ROLE_KEY");

function requireEnvironment(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

async function request(path, {
  method = "GET",
  token = serviceRoleKey,
  apiKey = serviceRoleKey,
  headers = {},
  body,
} = {}) {
  return fetch(`${apiURL}${path}`, {
    method,
    headers: {
      apikey: apiKey,
      Authorization: `Bearer ${token}`,
      ...headers,
    },
    body,
  });
}

async function responseJSON(response) {
  const text = await response.text();
  return text.length > 0 ? JSON.parse(text) : {};
}

async function expectSuccess(response, description) {
  const errorBody = response.ok ? "" : await response.text();
  assert.ok(
    response.ok,
    `${description}: expected success, received HTTP ${response.status}`
      + (errorBody ? ` (${errorBody})` : ""),
  );
  return response;
}

async function createUser(label) {
  const suffix = randomUUID();
  const email = `${label}-${suffix}@test.invalid`;
  const password = `Phase09-${suffix}!`;
  const response = await request("/auth/v1/admin/users", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      email,
      password,
      email_confirm: true,
    }),
  });
  await expectSuccess(response, `create ${label} identity`);
  const user = await responseJSON(response);
  return { id: user.id, email, password };
}

async function signIn(user) {
  const response = await request("/auth/v1/token?grant_type=password", {
    method: "POST",
    token: anonKey,
    apiKey: anonKey,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      email: user.email,
      password: user.password,
    }),
  });
  await expectSuccess(response, `sign in ${user.email}`);
  const session = await responseJSON(response);
  assert.ok(session.access_token, "Auth response did not include an access token");
  return session.access_token;
}

async function insert(table, rows) {
  const response = await request(`/rest/v1/${table}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Prefer: "return=minimal",
    },
    body: JSON.stringify(rows),
  });
  await expectSuccess(response, `insert ${table} fixtures`);
}

async function selectRows(table, query) {
  const response = await request(`/rest/v1/${table}?${query}`);
  await expectSuccess(response, `select ${table}`);
  return responseJSON(response);
}

async function enroll(token, programID, coachQR) {
  const response = await request("/rest/v1/rpc/enroll_free_program", {
    method: "POST",
    token,
    apiKey: anonKey,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      target_program_id: programID,
      scanned_coach_qr: coachQR,
    }),
  });
  const body = await responseJSON(response);
  return {
    ok: response.ok,
    status: response.status,
    body,
    message: body.message,
  };
}

async function adminEnroll(token, programID, participantID, reason) {
  const response = await request("/rest/v1/rpc/admin_enroll_participant", {
    method: "POST",
    token,
    apiKey: anonKey,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      target_program_id: programID,
      target_participant_id: participantID,
      reason,
    }),
  });
  const body = await responseJSON(response);
  return {
    ok: response.ok,
    status: response.status,
    body,
    message: body.message,
  };
}

const admin = await createUser("race-admin");
const coachOne = await createUser("race-coach-one");
const coachTwo = await createUser("race-coach-two");
const duplicateParticipant = await createUser("race-duplicate");
const capacityParticipantOne = await createUser("race-capacity-one");
const capacityParticipantTwo = await createUser("race-capacity-two");
const coachRaceParticipant = await createUser("race-coach-mismatch");
const wrongQRParticipant = await createUser("race-wrong-qr");
const deadlineParticipant = await createUser("race-deadline");

const coachOneQR = `coach-${randomUUID()}`;
const coachTwoQR = `coach-${randomUUID()}`;

await insert("profiles", [
  {
    user_id: admin.id,
    role: "admin",
    display_name: "Admin Race",
    current_coach_id: null,
    coach_qr_identifier: null,
    coach_is_approved: false,
  },
  {
    user_id: coachOne.id,
    role: "coach",
    display_name: "Coach Race Satu",
    current_coach_id: null,
    coach_qr_identifier: coachOneQR,
    coach_is_approved: true,
  },
  {
    user_id: coachTwo.id,
    role: "coach",
    display_name: "Coach Race Dua",
    current_coach_id: null,
    coach_qr_identifier: coachTwoQR,
    coach_is_approved: true,
  },
  ...[
    duplicateParticipant,
    capacityParticipantOne,
    capacityParticipantTwo,
    coachRaceParticipant,
    wrongQRParticipant,
    deadlineParticipant,
  ].map((participant, index) => ({
    user_id: participant.id,
    role: "participant",
    display_name: `Peserta Race ${index + 1}`,
    current_coach_id:
      participant.id === deadlineParticipant.id ? coachOne.id : null,
    coach_qr_identifier: null,
    coach_is_approved: false,
  })),
]);

const duplicateProgramID = randomUUID();
const capacityProgramID = randomUUID();
const coachRaceProgramOneID = randomUUID();
const coachRaceProgramTwoID = randomUUID();
const deadlineProgramID = randomUUID();

const programFixture = (id, title, participantLimit) => ({
  id,
  title,
  status: "active",
  pace: "scheduled",
  duration_mode: "fixed_duration",
  starts_on: "2026-08-01",
  ends_on: "2026-08-31",
  timezone: "Asia/Makassar",
  participant_limit: participantLimit,
  registration_closes_at: null,
  past_step_policy: "available",
  future_step_policy: "locked",
  wellness_disclaimer: "Program kebugaran non-diagnostik.",
  points_per_activity: 10,
  points_per_weight_kg: 100,
  quiz_passing_percentage: 70,
  pricing_mode: "free",
  created_by: admin.id,
});

await insert("programs", [
  programFixture(duplicateProgramID, "Race Duplikat", null),
  programFixture(capacityProgramID, "Race Kapasitas", 1),
  programFixture(coachRaceProgramOneID, "Race Coach Satu", null),
  programFixture(coachRaceProgramTwoID, "Race Coach Dua", null),
  {
    ...programFixture(deadlineProgramID, "Race Deadline", null),
    registration_closes_at: new Date(Date.now() - 60_000).toISOString(),
  },
]);

const adminToken = await signIn(admin);
const duplicateToken = await signIn(duplicateParticipant);
const capacityTokenOne = await signIn(capacityParticipantOne);
const capacityTokenTwo = await signIn(capacityParticipantTwo);
const coachRaceToken = await signIn(coachRaceParticipant);
const wrongQRToken = await signIn(wrongQRParticipant);
const deadlineToken = await signIn(deadlineParticipant);

const duplicateResults = await Promise.all([
  enroll(duplicateToken, duplicateProgramID, coachOneQR),
  enroll(duplicateToken, duplicateProgramID, coachOneQR),
]);
assert.ok(
  duplicateResults.every((result) => result.ok),
  "duplicate concurrent enrollments should both resolve idempotently",
);
assert.equal(
  duplicateResults[0].body.id,
  duplicateResults[1].body.id,
  "duplicate concurrent enrollments should return the same enrollment",
);
const duplicateRows = await selectRows(
  "program_enrollments",
  `program_id=eq.${duplicateProgramID}`
    + `&participant_id=eq.${duplicateParticipant.id}`
    + "&select=id",
);
assert.equal(
  duplicateRows.length,
  1,
  "duplicate concurrent enrollments should persist one row",
);
const duplicateScores = await selectRows(
  "program_scores",
  `enrollment_id=eq.${duplicateResults[0].body.id}&select=enrollment_id`,
);
assert.equal(
  duplicateScores.length,
  1,
  "duplicate concurrent enrollments should persist one score row",
);

const capacityResults = await Promise.all([
  enroll(capacityTokenOne, capacityProgramID, coachOneQR),
  enroll(capacityTokenTwo, capacityProgramID, coachOneQR),
]);
assert.equal(
  capacityResults.filter((result) => result.ok).length,
  1,
  "capacity race should admit exactly one Participant",
);
assert.equal(
  capacityResults.filter((result) => result.message === "program_full").length,
  1,
  "capacity race should reject exactly one Participant as full",
);
const capacityRows = await selectRows(
  "program_enrollments",
  `program_id=eq.${capacityProgramID}&select=id`,
);
assert.equal(
  capacityRows.length,
  1,
  "capacity race should persist exactly one enrollment",
);

const coachRaceResults = await Promise.all([
  enroll(coachRaceToken, coachRaceProgramOneID, coachOneQR),
  enroll(coachRaceToken, coachRaceProgramTwoID, coachTwoQR),
]);
assert.equal(
  coachRaceResults.filter((result) => result.ok).length,
  1,
  "same-Participant Coach race should accept exactly one Coach",
);
assert.equal(
  coachRaceResults.filter(
    (result) => result.message === "coach_mismatch",
  ).length,
  1,
  "same-Participant Coach race should reject the conflicting Coach",
);

const wrongQRResult = await enroll(
  wrongQRToken,
  duplicateProgramID,
  `invalid-${randomUUID()}`,
);
assert.equal(
  wrongQRResult.message,
  "coach_qr_invalid",
  "unknown Coach QR should fail without creating enrollment",
);

const closedEnrollment = await enroll(
  deadlineToken,
  deadlineProgramID,
  coachOneQR,
);
assert.equal(
  closedEnrollment.message,
  "registration_closed",
  "Participant enrollment should fail after the registration cutoff",
);

const adminDeadlineEnrollment = await adminEnroll(
  adminToken,
  deadlineProgramID,
  deadlineParticipant.id,
  "Verifikasi Admin untuk enrollment setelah batas waktu.",
);
assert.ok(
  adminDeadlineEnrollment.ok,
  "Admin should enroll after the cutoff through the protected RPC",
);
const deadlineRows = await selectRows(
  "program_enrollments",
  `program_id=eq.${deadlineProgramID}`
    + `&participant_id=eq.${deadlineParticipant.id}`
    + "&select=id",
);
assert.equal(
  deadlineRows.length,
  1,
  "Admin cutoff override should persist exactly one enrollment",
);
const deadlineAudits = await selectRows(
  "audit_events",
  `subject_id=eq.${deadlineParticipant.id}`
    + "&kind=eq.participant_enrolled&select=payload",
);
assert.equal(
  deadlineAudits[0]?.payload?.registration_deadline_bypassed,
  true,
  "Admin cutoff override should be explicitly audited",
);

console.log("PASS enrollment race integration checks (14 assertions)");
