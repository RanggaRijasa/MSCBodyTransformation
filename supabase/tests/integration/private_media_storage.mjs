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

async function expectDenied(response, description) {
  assert.ok(
    !response.ok,
    `${description}: request unexpectedly succeeded`,
  );
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

async function update(table, query, values) {
  const response = await request(`/rest/v1/${table}?${query}`, {
    method: "PATCH",
    headers: {
      "Content-Type": "application/json",
      Prefer: "return=minimal",
    },
    body: JSON.stringify(values),
  });
  await expectSuccess(response, `update ${table} fixture`);
}

function storagePath(path) {
  return path.split("/").map(encodeURIComponent).join("/");
}

const admin = await createUser("admin");
const coach = await createUser("coach");
const unrelatedCoach = await createUser("unrelated-coach");
const participant = await createUser("participant");
const unrelatedParticipant = await createUser("unrelated-participant");

await insert("profiles", [
  {
    user_id: admin.id,
    role: "admin",
    display_name: "Admin Integration",
    current_coach_id: null,
    coach_qr_identifier: null,
    coach_is_approved: false,
  },
  {
    user_id: coach.id,
    role: "coach",
    display_name: "Coach Integration",
    current_coach_id: null,
    coach_qr_identifier: `coach-${randomUUID()}`,
    coach_is_approved: true,
  },
  {
    user_id: unrelatedCoach.id,
    role: "coach",
    display_name: "Coach Tidak Terkait",
    current_coach_id: null,
    coach_qr_identifier: `coach-${randomUUID()}`,
    coach_is_approved: true,
  },
  {
    user_id: participant.id,
    role: "participant",
    display_name: "Peserta Integration",
    current_coach_id: coach.id,
    coach_qr_identifier: null,
    coach_is_approved: false,
  },
  {
    user_id: unrelatedParticipant.id,
    role: "participant",
    display_name: "Peserta Tidak Terkait",
    current_coach_id: unrelatedCoach.id,
    coach_qr_identifier: null,
    coach_is_approved: false,
  },
]);

const programID = randomUUID();
const dayID = randomUUID();
const stepID = randomUUID();
const questionID = randomUUID();
const enrollmentID = randomUUID();
const submissionID = randomUUID();
const objectID = randomUUID();
const secondObjectID = randomUUID();

await insert("programs", {
  id: programID,
  title: "Program Integration Storage",
  status: "active",
  pace: "scheduled",
  duration_mode: "fixed_duration",
  starts_on: "2026-08-01",
  ends_on: "2026-08-31",
  timezone: "Asia/Makassar",
  past_step_policy: "available",
  future_step_policy: "locked",
  wellness_disclaimer: "Program kebugaran non-diagnostik.",
  points_per_activity: 10,
  points_per_weight_kg: 100,
  quiz_passing_percentage: 70,
  pricing_mode: "free",
  created_by: admin.id,
});
await insert("program_days", {
  id: dayID,
  program_id: programID,
  day_number: 1,
  title: "Hari Foto",
  scheduled_on: "2026-08-01",
});
await insert("program_steps", {
  id: stepID,
  program_day_id: dayID,
  step_order: 1,
  title: "Unggah Foto",
  content_kind: "form",
  completion_policy: "answer_all_questions",
  verification_mode: "coach_review",
});
await insert("program_questions", {
  id: questionID,
  step_id: stepID,
  question_order: 1,
  kind: "photo_upload",
  prompt: "Unggah foto jawaban",
});
await insert("program_enrollments", {
  id: enrollmentID,
  program_id: programID,
  participant_id: participant.id,
  coach_id: coach.id,
  status: "active",
});
await insert("step_submissions", {
  id: submissionID,
  enrollment_id: enrollmentID,
  step_id: stepID,
  status: "pending",
});

const participantToken = await signIn(participant);
const coachToken = await signIn(coach);
const unrelatedCoachToken = await signIn(unrelatedCoach);
const unrelatedParticipantToken = await signIn(unrelatedParticipant);
const adminToken = await signIn(admin);

const objectPath = [
  participant.id,
  enrollmentID,
  submissionID,
  questionID,
  `${objectID}.jpg`,
].join("/");
const wrongMIMEPath = [
  participant.id,
  enrollmentID,
  submissionID,
  questionID,
  `${secondObjectID}.jpg`,
].join("/");
const encodedObjectPath = storagePath(objectPath);
const jpegBytes = Uint8Array.from([0xff, 0xd8, 0xff, 0xd9]);

await expectDenied(
  await request(
    `/storage/v1/object/question-photos/${storagePath(wrongMIMEPath)}`,
    {
      method: "POST",
      token: participantToken,
      apiKey: anonKey,
      headers: { "Content-Type": "image/png" },
      body: jpegBytes,
    },
  ),
  "bucket rejects a non-JPEG MIME type",
);

await expectSuccess(
  await request(`/storage/v1/object/question-photos/${encodedObjectPath}`, {
    method: "POST",
    token: participantToken,
    apiKey: anonKey,
    headers: { "Content-Type": "image/jpeg" },
    body: jpegBytes,
  }),
  "Participant uploads private photo",
);

await expectSuccess(
  await request(
    `/storage/v1/object/authenticated/question-photos/${encodedObjectPath}`,
    {
      token: participantToken,
      apiKey: anonKey,
    },
  ),
  "Participant downloads own private photo",
);
await expectSuccess(
  await request(
    `/storage/v1/object/authenticated/question-photos/${encodedObjectPath}`,
    {
      token: coachToken,
      apiKey: anonKey,
    },
  ),
  "assigned Coach downloads private photo",
);
await expectDenied(
  await request(
    `/storage/v1/object/authenticated/question-photos/${encodedObjectPath}`,
    {
      token: unrelatedCoachToken,
      apiKey: anonKey,
    },
  ),
  "unrelated Coach cannot download private photo",
);
await expectDenied(
  await request(
    `/storage/v1/object/authenticated/question-photos/${encodedObjectPath}`,
    {
      token: unrelatedParticipantToken,
      apiKey: anonKey,
    },
  ),
  "unrelated Participant cannot download private photo",
);

await expectSuccess(
  await request(
    `/storage/v1/object/sign/question-photos/${encodedObjectPath}`,
    {
      method: "POST",
      token: coachToken,
      apiKey: anonKey,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ expiresIn: 60 }),
    },
  ),
  "assigned Coach creates a short-lived signed URL",
);
await expectDenied(
  await request(
    `/storage/v1/object/sign/question-photos/${encodedObjectPath}`,
    {
      method: "POST",
      token: unrelatedCoachToken,
      apiKey: anonKey,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ expiresIn: 60 }),
    },
  ),
  "unrelated Coach cannot create a signed URL",
);
await expectSuccess(
  await request(
    `/storage/v1/object/sign/question-photos/${encodedObjectPath}`,
    {
      method: "POST",
      token: adminToken,
      apiKey: anonKey,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ expiresIn: 60 }),
    },
  ),
  "Admin creates a short-lived signed URL",
);

await expectSuccess(
  await request(`/storage/v1/object/question-photos/${encodedObjectPath}`, {
    method: "POST",
    token: participantToken,
    apiKey: anonKey,
    headers: {
      "Content-Type": "image/jpeg",
      "x-upsert": "true",
    },
    body: jpegBytes,
  }),
  "Participant retries with upsert while submission is pending",
);
await expectDenied(
  await request(`/storage/v1/object/question-photos/${encodedObjectPath}`, {
    method: "POST",
    token: coachToken,
    apiKey: anonKey,
    headers: {
      "Content-Type": "image/jpeg",
      "x-upsert": "true",
    },
    body: jpegBytes,
  }),
  "Coach cannot replace Participant private media",
);

await expectSuccess(
  await request(`/storage/v1/object/question-photos/${encodedObjectPath}`, {
    method: "DELETE",
    token: participantToken,
    apiKey: anonKey,
  }),
  "Participant deletes their pending private photo",
);
await expectDenied(
  await request(
    `/storage/v1/object/authenticated/question-photos/${encodedObjectPath}`,
    {
      token: participantToken,
      apiKey: anonKey,
    },
  ),
  "deleted private photo is no longer downloadable",
);
await expectSuccess(
  await request(`/storage/v1/object/question-photos/${encodedObjectPath}`, {
    method: "POST",
    token: participantToken,
    apiKey: anonKey,
    headers: { "Content-Type": "image/jpeg" },
    body: jpegBytes,
  }),
  "Participant can upload the pending private photo again",
);

await update(
  "step_submissions",
  `id=eq.${encodeURIComponent(submissionID)}`,
  { status: "approved" },
);
await expectDenied(
  await request(`/storage/v1/object/question-photos/${encodedObjectPath}`, {
    method: "POST",
    token: participantToken,
    apiKey: anonKey,
    headers: {
      "Content-Type": "image/jpeg",
      "x-upsert": "true",
    },
    body: jpegBytes,
  }),
  "Participant cannot replace media after review",
);
await expectDenied(
  await request(`/storage/v1/object/question-photos/${encodedObjectPath}`, {
    method: "DELETE",
    token: participantToken,
    apiKey: anonKey,
  }),
  "Participant cannot delete media after review",
);

console.log("PASS private-media Storage API integration checks (16 assertions)");
