import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";

const apiURL = requireEnvironment("API_URL");
const anonKey = process.env.ANON_KEY
  ?? requireEnvironment("PUBLISHABLE_KEY");
const serviceRoleKey = process.env.SERVICE_ROLE_KEY
  ?? requireEnvironment("SECRET_KEY");

assertLocalURL(apiURL);

function requireEnvironment(name) {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

function assertLocalURL(value) {
  const hostname = new URL(value).hostname;
  assert.ok(
    ["127.0.0.1", "localhost", "::1"].includes(hostname),
    "Authenticated-read integration tests must target local Supabase",
  );
}

async function request(path, {
  method = "GET",
  token = anonKey,
  apiKey = anonKey,
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

async function responseJSON(response) {
  const text = await response.text();
  return text.length === 0 ? null : JSON.parse(text);
}

async function expectSuccess(response, label) {
  const errorBody = response.ok ? "" : await response.text();
  assert.ok(
    response.ok,
    `${label}: expected success, received HTTP ${response.status}`
      + (errorBody ? ` (${errorBody})` : ""),
  );
  return responseJSON(response);
}

async function createUser(label) {
  const suffix = randomUUID();
  const email = `${label}-${suffix}@test.invalid`;
  const password = `Phase11-${suffix}!`;
  const user = await expectSuccess(
    await request("/auth/v1/admin/users", {
      method: "POST",
      token: serviceRoleKey,
      apiKey: serviceRoleKey,
      body: { email, password, email_confirm: true },
    }),
    `create ${label} identity`,
  );
  return { ...user, email, password };
}

async function signIn(user) {
  const session = await expectSuccess(
    await request("/auth/v1/token?grant_type=password", {
      method: "POST",
      body: { email: user.email, password: user.password },
    }),
    "sign in local authenticated-read fixture",
  );
  return session.access_token;
}

async function serviceInsert(table, row) {
  await expectSuccess(
    await request(`/rest/v1/${table}`, {
      method: "POST",
      token: serviceRoleKey,
      apiKey: serviceRoleKey,
      body: row,
      prefer: "return=minimal",
    }),
    `insert ${table} fixture`,
  );
}

async function servicePatchProfile(userID, body) {
  await expectSuccess(
    await request(`/rest/v1/profiles?user_id=eq.${userID}`, {
      method: "PATCH",
      token: serviceRoleKey,
      apiKey: serviceRoleKey,
      body,
      prefer: "return=minimal",
    }),
    "activate authenticated-read profile fixture",
  );
}

async function serviceDelete(table, query) {
  await expectSuccess(
    await request(`/rest/v1/${table}?${query}`, {
      method: "DELETE",
      token: serviceRoleKey,
      apiKey: serviceRoleKey,
      prefer: "return=minimal",
    }),
    `delete ${table} fixture`,
  );
}

async function authenticatedRows(token, path) {
  return expectSuccess(
    await request(path, { token }),
    `authenticated GET ${path.split("?")[0]}`,
  );
}

async function authenticatedRPC(token, name) {
  return expectSuccess(
    await request(`/rest/v1/rpc/${name}`, {
      method: "POST",
      token,
      body: {},
    }),
    `authenticated RPC ${name}`,
  );
}

const fixture = {
  programID: randomUUID(),
  dayID: randomUUID(),
  stepID: randomUUID(),
  enrollmentAID: randomUUID(),
  enrollmentBID: randomUUID(),
  submissionAID: randomUUID(),
  submissionBID: randomUUID(),
  weighInAID: randomUUID(),
  weighInBID: randomUUID(),
};

let admin;
let coachA;
let coachB;
let participantA;
let participantB;

try {
  admin = await createUser("phase11-auth-admin");
  coachA = await createUser("phase11-auth-coach-a");
  coachB = await createUser("phase11-auth-coach-b");
  participantA = await createUser("phase11-auth-participant-a");
  participantB = await createUser("phase11-auth-participant-b");

  const activeProfileFields = {
    onboarding_status: "active",
    provisional_expires_at: null,
    finalized_at: new Date().toISOString(),
  };
  await servicePatchProfile(admin.id, {
    ...activeProfileFields,
    role: "admin",
    display_name: "Admin Auth Integration",
  });
  await servicePatchProfile(coachA.id, {
    ...activeProfileFields,
    role: "coach",
    display_name: "Coach Auth Integration A",
    city: "Denpasar",
    phone_number: "+6281200000801",
    coach_qr_identifier: `phase11-auth-${randomUUID()}`,
    coach_is_approved: true,
    coach_is_public: false,
  });
  await servicePatchProfile(coachB.id, {
    ...activeProfileFields,
    role: "coach",
    display_name: "Coach Auth Integration B",
    city: "Badung",
    phone_number: "+6281200000802",
    coach_qr_identifier: `phase11-auth-${randomUUID()}`,
    coach_is_approved: true,
    coach_is_public: false,
  });
  await servicePatchProfile(participantA.id, {
    ...activeProfileFields,
    display_name: "Peserta Auth Integration A",
    current_coach_id: coachA.id,
  });
  await servicePatchProfile(participantB.id, {
    ...activeProfileFields,
    display_name: "Peserta Auth Integration B",
    current_coach_id: coachB.id,
  });

  const dateParts = new Intl.DateTimeFormat("en-US", {
    timeZone: "Asia/Makassar",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(new Date());
  const datePart = (type) =>
    dateParts.find((part) => part.type === type)?.value;
  const today = `${datePart("year")}-${datePart("month")}-${datePart("day")}`;

  await serviceInsert("programs", {
    id: fixture.programID,
    title: "Program Auth Integration",
    summary: "Program pengujian baca terautentikasi.",
    status: "active",
    pace: "scheduled",
    duration_mode: "specific_dates",
    starts_on: today,
    ends_on: today,
    timezone: "Asia/Makassar",
    past_step_policy: "read_only",
    future_step_policy: "locked",
    wellness_disclaimer: "Program kebugaran non-diagnostik.",
    points_per_activity: 10,
    points_per_weight_kg: 100,
    quiz_passing_percentage: 70,
    pricing_mode: "free",
    published_at: new Date().toISOString(),
    created_by: admin.id,
  });
  await serviceInsert("program_days", {
    id: fixture.dayID,
    program_id: fixture.programID,
    day_number: 1,
    title: "Hari Auth Integration",
    scheduled_on: today,
  });
  await serviceInsert("program_steps", {
    id: fixture.stepID,
    program_day_id: fixture.dayID,
    step_order: 1,
    title: "Timbang Auth Integration",
    content_kind: "daily_weigh_in",
    completion_policy: "submit_weigh_in",
    verification_mode: "automatic",
  });
  await serviceInsert("program_enrollments", [
    {
      id: fixture.enrollmentAID,
      program_id: fixture.programID,
      participant_id: participantA.id,
      coach_id: coachA.id,
      status: "active",
    },
    {
      id: fixture.enrollmentBID,
      program_id: fixture.programID,
      participant_id: participantB.id,
      coach_id: coachB.id,
      status: "active",
    },
  ]);
  await serviceInsert("program_scores", [
    {
      enrollment_id: fixture.enrollmentAID,
      activity_points: 10,
      quiz_points: 0,
      weight_points: 0,
      adjustment_points: 0,
      progress_percentage: 50,
    },
    {
      enrollment_id: fixture.enrollmentBID,
      activity_points: 20,
      quiz_points: 0,
      weight_points: 100,
      adjustment_points: 0,
      progress_percentage: 75,
    },
  ]);
  await serviceInsert("step_submissions", [
    {
      id: fixture.submissionAID,
      enrollment_id: fixture.enrollmentAID,
      step_id: fixture.stepID,
      status: "pending",
    },
    {
      id: fixture.submissionBID,
      enrollment_id: fixture.enrollmentBID,
      step_id: fixture.stepID,
      status: "pending",
    },
  ]);
  await serviceInsert("weigh_ins", [
    {
      id: fixture.weighInAID,
      enrollment_id: fixture.enrollmentAID,
      step_id: fixture.stepID,
      kind: "daily",
      weight_kg: 70,
    },
    {
      id: fixture.weighInBID,
      enrollment_id: fixture.enrollmentBID,
      step_id: fixture.stepID,
      kind: "daily",
      weight_kg: 80,
    },
  ]);

  const tokenA = await signIn(participantA);
  const tokenB = await signIn(participantB);

  const ownProfile = await authenticatedRows(
    tokenA,
    `/rest/v1/profiles?select=user_id,public_profile_id,role,display_name,city,phone_number,current_coach_id,provider_avatar_url,member_level,onboarding_status,account_purpose&user_id=eq.${participantA.id}`,
  );
  assert.equal(ownProfile.length, 1);
  assert.equal(ownProfile[0].user_id, participantA.id);

  const otherProfile = await authenticatedRows(
    tokenA,
    `/rest/v1/profiles?select=user_id&user_id=eq.${participantB.id}`,
  );
  assert.deepEqual(otherProfile, []);

  const ownEnrollments = await authenticatedRows(
    tokenA,
    `/rest/v1/program_enrollments?select=id,participant_id&participant_id=eq.${participantA.id}`,
  );
  assert.equal(ownEnrollments.length, 1);
  assert.equal(ownEnrollments[0].id, fixture.enrollmentAID);

  const otherEnrollments = await authenticatedRows(
    tokenA,
    `/rest/v1/program_enrollments?select=id&participant_id=eq.${participantB.id}`,
  );
  assert.deepEqual(otherEnrollments, []);

  const otherSubmissions = await authenticatedRows(
    tokenA,
    `/rest/v1/step_submissions?select=id&enrollment_id=eq.${fixture.enrollmentBID}`,
  );
  assert.deepEqual(otherSubmissions, []);

  const otherWeights = await authenticatedRows(
    tokenA,
    `/rest/v1/weigh_ins?select=id&enrollment_id=eq.${fixture.enrollmentBID}`,
  );
  assert.deepEqual(otherWeights, []);

  const ownSubmissions = await authenticatedRows(
    tokenA,
    `/rest/v1/step_submissions?select=id,enrollment_id,step_id,attempt_sequence,status,submitted_at,reviewed_at,reviewer_id,review_note,step_submission_answers(id,question_id,text_value,number_value,selected_option_ids,private_photo_path),quiz_attempt_results(id,correct_count,total_count,percentage,passed,awarded_points,reopened_at,reopened_by,reopen_reason)&enrollment_id=eq.${fixture.enrollmentAID}`,
  );
  assert.equal(ownSubmissions.length, 1);
  assert.deepEqual(ownSubmissions[0].step_submission_answers, []);
  assert.equal(ownSubmissions[0].quiz_attempt_results, null);

  const ownWeights = await authenticatedRows(
    tokenA,
    `/rest/v1/weigh_ins?select=id,enrollment_id,step_id,kind,weight_kg,recorded_at&enrollment_id=eq.${fixture.enrollmentAID}`,
  );
  assert.equal(ownWeights.length, 1);

  const otherScore = await authenticatedRows(
    tokenA,
    `/rest/v1/program_scores?select=enrollment_id,weight_points&enrollment_id=eq.${fixture.enrollmentBID}`,
  );
  assert.deepEqual(otherScore, []);

  const ownScore = await authenticatedRows(
    tokenA,
    `/rest/v1/program_scores?select=public_id,enrollment_id,activity_points,quiz_points,weight_points,adjustment_points,progress_percentage,rank&enrollment_id=eq.${fixture.enrollmentAID}`,
  );
  assert.equal(ownScore.length, 1);

  const assignedCoach = await authenticatedRPC(
    tokenA,
    "get_my_assigned_coach",
  );
  assert.equal(assignedCoach.length, 1);
  assert.equal(assignedCoach[0].user_id, coachA.id);
  assert.deepEqual(
    Object.keys(assignedCoach[0]).sort(),
    [
      "city",
      "display_name",
      "is_approved",
      "is_public",
      "provider_avatar_url",
      "public_profile_id",
      "user_id",
    ],
  );

  const dayAccess = await authenticatedRPC(
    tokenA,
    "list_my_program_day_access",
  );
  assert.equal(dayAccess.length, 1);
  assert.equal(dayAccess[0].enrollment_id, fixture.enrollmentAID);
  assert.equal(dayAccess[0].access_state, "available");

  const dashboardA = await authenticatedRPC(
    tokenA,
    "get_my_dashboard_summary",
  );
  assert.equal(dashboardA.length, 1);
  assert.equal(dashboardA[0].active_enrollment_count, 1);
  assert.equal(dashboardA[0].pending_submission_count, 1);

  const assignedCoachB = await authenticatedRPC(
    tokenB,
    "get_my_assigned_coach",
  );
  assert.equal(assignedCoachB[0].user_id, coachB.id);

  const program = await authenticatedRows(
    tokenA,
    `/rest/v1/programs?select=id,program_days(id,program_steps(id,program_questions(id,program_question_options(id))))&id=eq.${fixture.programID}`,
  );
  assert.equal(program.length, 1);
  assert.ok(!JSON.stringify(program).includes("answer_key"));

  const answerKeys = await authenticatedRows(
    tokenA,
    `/rest/v1/program_answer_keys?select=question_id`,
  );
  assert.deepEqual(answerKeys, []);

  console.log("Phase 11 authenticated reads: 27 checks passed.");
} finally {
  await serviceDelete(
    "program_enrollments",
    `program_id=eq.${fixture.programID}`,
  );
  await serviceDelete("programs", `id=eq.${fixture.programID}`);

  for (const user of [
    participantB,
    participantA,
    coachB,
    coachA,
    admin,
  ]) {
    if (!user?.id) continue;
    await expectSuccess(
      await request(`/auth/v1/admin/users/${user.id}`, {
        method: "DELETE",
        token: serviceRoleKey,
        apiKey: serviceRoleKey,
      }),
      "delete authenticated-read Auth fixture",
    );
  }
}
