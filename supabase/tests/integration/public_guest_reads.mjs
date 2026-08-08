import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { activateCoachEntitlement } from "./phase11_fixture_helpers.mjs";

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

async function serviceRequest(path, {
  method = "GET",
  headers = {},
  body,
} = {}) {
  return fetch(`${apiURL}${path}`, {
    method,
    headers: {
      apikey: serviceRoleKey,
      Authorization: `Bearer ${serviceRoleKey}`,
      ...headers,
    },
    body,
  });
}

async function guestRequest(path, {
  method = "GET",
  headers = {},
  body,
} = {}) {
  return fetch(`${apiURL}${path}`, {
    method,
    headers: {
      apikey: anonKey,
      ...headers,
    },
    body,
  });
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

async function responseJSON(response) {
  const text = await response.text();
  return text.length > 0 ? JSON.parse(text) : null;
}

async function createUser(label) {
  const suffix = randomUUID();
  const response = await serviceRequest("/auth/v1/admin/users", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      email: `${label}-${suffix}@test.invalid`,
      password: `Phase11-${suffix}!`,
      email_confirm: true,
    }),
  });
  await expectSuccess(response, `create ${label} identity`);
  return responseJSON(response);
}

async function upsertProfile(profile) {
  const response = await serviceRequest(
    "/rest/v1/profiles?on_conflict=user_id",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Prefer: "resolution=merge-duplicates,return=representation",
      },
      body: JSON.stringify(profile),
    },
  );
  await expectSuccess(response, "upsert public-read profile fixture");
  const rows = await responseJSON(response);
  return rows[0];
}

async function insert(table, row) {
  const response = await serviceRequest(`/rest/v1/${table}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Prefer: "return=minimal",
    },
    body: JSON.stringify(row),
  });
  await expectSuccess(response, `insert ${table} fixture`);
}

async function deleteRows(table, query) {
  const response = await serviceRequest(`/rest/v1/${table}?${query}`, {
    method: "DELETE",
    headers: { Prefer: "return=minimal" },
  });
  await expectSuccess(response, `delete ${table} fixtures`);
}

async function rpc(name, body) {
  const response = await guestRequest(`/rest/v1/rpc/${name}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  await expectSuccess(response, `Guest call ${name}`);
  return responseJSON(response);
}

function assertNoKeys(value, forbiddenKeys, description) {
  const serialized = JSON.stringify(value);
  for (const key of forbiddenKeys) {
    assert.ok(
      !serialized.includes(`"${key}"`),
      `${description} unexpectedly contains ${key}`,
    );
  }
}

const fixture = {
  programID: randomUUID(),
  dayID: randomUUID(),
  stepID: randomUUID(),
  questionID: randomUUID(),
  optionID: randomUUID(),
  enrollmentID: randomUUID(),
  snapshotID: randomUUID(),
  winnerID: randomUUID(),
  posterID: randomUUID(),
};

let admin;
let coach;
let participant;
let coachEntitlementFixture;

try {
  admin = await createUser("phase11-public-admin");
  coach = await createUser("phase11-public-coach");
  participant = await createUser("phase11-public-participant");

  await upsertProfile({
    user_id: admin.id,
    role: "admin",
    display_name: "Admin Public Integration",
    onboarding_status: "active",
    provisional_expires_at: null,
    finalized_at: new Date().toISOString(),
  });
  const publicCoach = await upsertProfile({
    user_id: coach.id,
    role: "coach",
    display_name: "Coach Public Integration",
    city: "Denpasar",
    phone_number: "+6281200000111",
    coach_qr_identifier: `private-${randomUUID()}`,
    coach_is_approved: true,
    coach_is_public: true,
    onboarding_status: "active",
    provisional_expires_at: null,
    finalized_at: new Date().toISOString(),
  });
  const publicParticipant = await upsertProfile({
    user_id: participant.id,
    role: "participant",
    display_name: "Peserta Public Integration",
    phone_number: "+6281200000112",
    current_coach_id: coach.id,
    onboarding_status: "active",
    provisional_expires_at: null,
    finalized_at: new Date().toISOString(),
  });
  coachEntitlementFixture = await activateCoachEntitlement(
    insert,
    coach.id,
    admin.id,
    "Coach Public Integration",
  );

  await insert("programs", {
    id: fixture.programID,
    title: "Program Public Integration",
    summary: "Program untuk menguji Guest.",
    status: "completed",
    pace: "scheduled",
    duration_mode: "fixed_duration",
    starts_on: "2026-07-01",
    ends_on: "2026-07-31",
    timezone: "Asia/Makassar",
    past_step_policy: "available",
    future_step_policy: "locked",
    wellness_disclaimer: "Program kebugaran non-diagnostik.",
    points_per_activity: 10,
    points_per_weight_kg: 100,
    quiz_passing_percentage: 70,
    pricing_mode: "free",
    published_at: new Date().toISOString(),
    created_by: admin.id,
  });
  await insert("program_days", {
    id: fixture.dayID,
    program_id: fixture.programID,
    day_number: 1,
    title: "Hari Public Integration",
    scheduled_on: "2026-07-01",
  });
  await insert("program_steps", {
    id: fixture.stepID,
    program_day_id: fixture.dayID,
    step_order: 1,
    title: "Kuis Public Integration",
    content_kind: "quiz",
    completion_policy: "automatic_quiz",
    verification_mode: "automatic",
  });
  await insert("program_questions", {
    id: fixture.questionID,
    step_id: fixture.stepID,
    question_order: 1,
    kind: "single_choice",
    prompt: "Pertanyaan publik",
  });
  await insert("program_question_options", {
    id: fixture.optionID,
    question_id: fixture.questionID,
    option_order: 1,
    title: "Pilihan publik",
  });
  await insert("program_answer_keys", {
    question_id: fixture.questionID,
    selected_option_ids: [fixture.optionID],
  });
  await insert("program_enrollments", {
    id: fixture.enrollmentID,
    program_id: fixture.programID,
    participant_id: participant.id,
    coach_id: coach.id,
    status: "completed",
    completed_at: new Date().toISOString(),
  });
  await insert("program_scores", {
    enrollment_id: fixture.enrollmentID,
    activity_points: 100,
    quiz_points: 20,
    weight_points: 300,
    adjustment_points: 5,
    progress_percentage: 100,
    rank: 1,
  });
  await insert("winner_snapshots", {
    id: fixture.snapshotID,
    program_id: fixture.programID,
    locked_by: admin.id,
    locked_at: new Date().toISOString(),
  });
  await insert("program_winners", {
    id: fixture.winnerID,
    snapshot_id: fixture.snapshotID,
    participant_id: participant.id,
    rank: 1,
    display_name: "Peserta Public Integration",
    total_points: 425,
  });
  await insert("winner_posters", {
    id: fixture.posterID,
    program_id: fixture.programID,
    winner_snapshot_id: fixture.snapshotID,
    media_path: "winner-posters/public-integration.jpg",
    alt_text: "Poster pemenang public integration",
    is_published: true,
    published_at: new Date().toISOString(),
  });

  const programs = await rpc("list_public_programs", {
    target_program_id: fixture.programID,
    result_limit: 1,
    result_offset: 0,
  });
  assert.equal(programs.length, 1);
  assert.equal(programs[0].program_days.length, 1);
  assertNoKeys(
    programs,
    ["created_by", "accepted_text_values", "selected_option_ids"],
    "public program payload",
  );

  const coaches = await rpc("list_public_coaches", {
    result_limit: 100,
    result_offset: 0,
  });
  const coachRow = coaches.find((row) => row.id === publicCoach.public_profile_id);
  assert.ok(coachRow, "public Coach fixture was not returned");
  assert.notEqual(coachRow.id, coach.id);
  assertNoKeys(
    coachRow,
    ["user_id", "phone_number", "coach_qr_identifier"],
    "public Coach payload",
  );

  const leaderboard = await rpc("list_public_leaderboard", {
    target_program_id: fixture.programID,
    result_limit: 100,
    result_offset: 0,
  });
  assert.equal(leaderboard.length, 1);
  assert.equal(leaderboard[0].participant_id, publicParticipant.public_profile_id);
  assert.notEqual(leaderboard[0].participant_id, participant.id);
  assert.equal(leaderboard[0].total_points, 425);
  assertNoKeys(
    leaderboard,
    ["enrollment_id", "weight_points", "weight_kg"],
    "public leaderboard payload",
  );

  const winners = await rpc("list_public_winners", {
    target_program_id: fixture.programID,
    result_limit: 5,
    result_offset: 0,
  });
  assert.equal(winners.length, 1);
  assert.equal(winners[0].participant_id, publicParticipant.public_profile_id);

  const posters = await rpc("list_public_winner_posters", {
    result_limit: 100,
    result_offset: 0,
  });
  assert.ok(
    posters.some((row) => row.id === fixture.posterID),
    "published poster fixture was not returned",
  );

  for (const table of [
    "profiles",
    "program_enrollments",
    "weigh_ins",
    "step_submissions",
    "step_submission_answers",
    "program_answer_keys",
    "commerce_transactions",
    "program_entitlements",
    "audit_events",
  ]) {
    const response = await guestRequest(`/rest/v1/${table}?select=*`);
    assert.ok(
      !response.ok,
      `Guest unexpectedly read private base table ${table}`,
    );
  }

  console.log("Phase 11 public Guest reads: 22 checks passed.");
} finally {
  if (fixture.posterID) {
    await deleteRows("winner_posters", `id=eq.${fixture.posterID}`);
    await deleteRows("program_winners", `id=eq.${fixture.winnerID}`);
    await deleteRows("winner_snapshots", `id=eq.${fixture.snapshotID}`);
    await deleteRows(
      "program_scores",
      `enrollment_id=eq.${fixture.enrollmentID}`,
    );
    await deleteRows(
      "program_enrollments",
      `id=eq.${fixture.enrollmentID}`,
    );
    await deleteRows(
      "program_answer_keys",
      `question_id=eq.${fixture.questionID}`,
    );
    await deleteRows(
      "program_question_options",
      `id=eq.${fixture.optionID}`,
    );
    await deleteRows(
      "program_questions",
      `id=eq.${fixture.questionID}`,
    );
    await deleteRows("program_steps", `id=eq.${fixture.stepID}`);
    await deleteRows("program_days", `id=eq.${fixture.dayID}`);
    await deleteRows("programs", `id=eq.${fixture.programID}`);
  }
  if (coachEntitlementFixture) {
    await deleteRows(
      "coach_access_entitlements",
      `application_id=eq.${coachEntitlementFixture.applicationID}`,
    );
    await deleteRows(
      "coach_payment_records",
      `id=eq.${coachEntitlementFixture.paymentID}`,
    );
    await deleteRows(
      "coach_applications",
      `id=eq.${coachEntitlementFixture.applicationID}`,
    );
  }

  for (const user of [participant, coach, admin]) {
    if (user?.id) {
      const response = await serviceRequest(
        `/auth/v1/admin/users/${user.id}`,
        { method: "DELETE" },
      );
      await expectSuccess(response, "delete public-read Auth fixture");
    }
  }
}
