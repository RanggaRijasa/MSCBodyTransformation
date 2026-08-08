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
  const body = await responseJSON(response);
  assert.ok(
    response.ok,
    `${description}: expected success, received HTTP ${response.status}`
      + (body.message ? ` (${body.message})` : ""),
  );
  return body;
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
  const user = await expectSuccess(response, `create ${label} identity`);
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
  const session = await expectSuccess(response, `sign in ${user.email}`);
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

async function upsertProfiles(rows) {
  const response = await request("/rest/v1/profiles?on_conflict=user_id", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Prefer: "resolution=merge-duplicates,return=minimal",
    },
    body: JSON.stringify(rows),
  });
  await expectSuccess(response, "upsert bootstrapped profile fixtures");
}

async function rpc(name, token, body) {
  const response = await request(`/rest/v1/rpc/${name}`, {
    method: "POST",
    token,
    apiKey: anonKey,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  const payload = await responseJSON(response);
  return {
    ok: response.ok,
    status: response.status,
    body: payload,
    message: payload.message,
  };
}

async function selectRows(table, query) {
  const response = await request(`/rest/v1/${table}?${query}`);
  return expectSuccess(response, `select ${table}`);
}

const admin = await createUser("submission-admin");
const coach = await createUser("submission-coach");
const participant = await createUser("submission-participant");
const coachQR = `coach-${randomUUID()}`;

await upsertProfiles([
  {
    user_id: admin.id,
    role: "admin",
    display_name: "Admin Submission Race",
    current_coach_id: null,
    coach_qr_identifier: null,
    coach_is_approved: false,
  },
  {
    user_id: coach.id,
    role: "coach",
    display_name: "Coach Submission Race",
    current_coach_id: null,
    coach_qr_identifier: coachQR,
    coach_is_approved: true,
  },
  {
    user_id: participant.id,
    role: "participant",
    display_name: "Peserta Submission Race",
    current_coach_id: coach.id,
    coach_qr_identifier: null,
    coach_is_approved: false,
  },
]);
await activateCoachEntitlement(
  insert,
  coach.id,
  admin.id,
  "Coach Submission Race",
);

const programID = randomUUID();
const dayID = randomUUID();
const formStepID = randomUUID();
const formQuestionID = randomUUID();
const quizStepID = randomUUID();
const quizQuestionID = randomUUID();
const correctOptionID = randomUUID();
const incorrectOptionID = randomUUID();
const enrollmentID = randomUUID();

await insert("programs", {
  id: programID,
  title: "Program Submission Race",
  status: "active",
  pace: "scheduled",
  duration_mode: "fixed_duration",
  starts_on: "2026-08-01",
  ends_on: "2026-08-31",
  timezone: "Asia/Jakarta",
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
  title: "Hari Submission Race",
  scheduled_on: "2026-08-04",
});
await insert("program_steps", [
  {
    id: formStepID,
    program_day_id: dayID,
    step_order: 1,
    title: "Form Race",
    content_kind: "form",
    completion_policy: "answer_all_questions",
    verification_mode: "coach_review",
  },
  {
    id: quizStepID,
    program_day_id: dayID,
    step_order: 2,
    title: "Quiz Race",
    content_kind: "quiz",
    completion_policy: "automatic_quiz",
    verification_mode: "automatic",
  },
]);
await insert("program_questions", [
  {
    id: formQuestionID,
    step_id: formStepID,
    question_order: 1,
    kind: "short_answer",
    prompt: "Jawaban lengkap?",
  },
  {
    id: quizQuestionID,
    step_id: quizStepID,
    question_order: 1,
    kind: "single_choice",
    prompt: "Pilih jawaban benar",
  },
]);
await insert("program_question_options", [
  {
    id: correctOptionID,
    question_id: quizQuestionID,
    option_order: 1,
    title: "Benar",
  },
  {
    id: incorrectOptionID,
    question_id: quizQuestionID,
    option_order: 2,
    title: "Salah",
  },
]);
await insert("program_answer_keys", {
  question_id: quizQuestionID,
  selected_option_ids: [correctOptionID],
});
await insert("program_enrollments", {
  id: enrollmentID,
  program_id: programID,
  participant_id: participant.id,
  coach_id: coach.id,
  status: "active",
});
await insert("program_scores", { enrollment_id: enrollmentID });

const participantToken = await signIn(participant);
const coachToken = await signIn(coach);

const formIdempotencyKey = `form-${randomUUID()}`;
const concurrentFormDrafts = await Promise.all([
  rpc("prepare_step_submission", participantToken, {
    target_enrollment_id: enrollmentID,
    target_step_id: formStepID,
    request_idempotency_key: formIdempotencyKey,
  }),
  rpc("prepare_step_submission", participantToken, {
    target_enrollment_id: enrollmentID,
    target_step_id: formStepID,
    request_idempotency_key: formIdempotencyKey,
  }),
]);
assert.ok(
  concurrentFormDrafts.every((result) => result.ok),
  "duplicate submission preparation should resolve successfully",
);
assert.equal(
  concurrentFormDrafts[0].body.id,
  concurrentFormDrafts[1].body.id,
  "duplicate submission preparation should return one draft",
);

const formSubmissionID = concurrentFormDrafts[0].body.id;
const formAnswers = [{
  question_id: formQuestionID,
  text_value: "Lengkap",
}];
const concurrentFormFinalizations = await Promise.all([
  rpc("submit_step_answers", participantToken, {
    target_submission_id: formSubmissionID,
    submitted_answers: formAnswers,
    request_idempotency_key: formIdempotencyKey,
  }),
  rpc("submit_step_answers", participantToken, {
    target_submission_id: formSubmissionID,
    submitted_answers: formAnswers,
    request_idempotency_key: formIdempotencyKey,
  }),
]);
assert.ok(
  concurrentFormFinalizations.every((result) => result.ok),
  "duplicate final submission should resolve successfully",
);
assert.ok(
  concurrentFormFinalizations.every(
    (result) => result.body.status === "pending",
  ),
  "duplicate final submission should resolve to one pending review",
);
const formAnswerRows = await selectRows(
  "step_submission_answers",
  `submission_id=eq.${formSubmissionID}&select=id`,
);
assert.equal(
  formAnswerRows.length,
  1,
  "duplicate final submission should persist one typed answer",
);

const reviewIdempotencyKey = `review-${randomUUID()}`;
const concurrentReviews = await Promise.all([
  rpc("review_step_submission", coachToken, {
    target_submission_id: formSubmissionID,
    review_decision: "approved",
    review_reason: null,
    request_idempotency_key: reviewIdempotencyKey,
  }),
  rpc("review_step_submission", coachToken, {
    target_submission_id: formSubmissionID,
    review_decision: "approved",
    review_reason: null,
    request_idempotency_key: reviewIdempotencyKey,
  }),
]);
assert.ok(
  concurrentReviews.every((result) => result.ok),
  "duplicate Coach review should resolve successfully",
);
assert.ok(
  concurrentReviews.every(
    (result) => result.body.status === "approved",
  ),
  "duplicate Coach review should preserve the approved decision",
);
const reviewAudits = await selectRows(
  "audit_events",
  `kind=eq.submission_approved&subject_id=eq.${formSubmissionID}&select=id`,
);
assert.equal(
  reviewAudits.length,
  1,
  "duplicate Coach review should write one audit event",
);

const quizIdempotencyKey = `quiz-${randomUUID()}`;
const concurrentQuizDrafts = await Promise.all([
  rpc("prepare_step_submission", participantToken, {
    target_enrollment_id: enrollmentID,
    target_step_id: quizStepID,
    request_idempotency_key: quizIdempotencyKey,
  }),
  rpc("prepare_step_submission", participantToken, {
    target_enrollment_id: enrollmentID,
    target_step_id: quizStepID,
    request_idempotency_key: quizIdempotencyKey,
  }),
]);
assert.ok(
  concurrentQuizDrafts.every((result) => result.ok),
  "concurrent quiz preparation should resolve successfully",
);
assert.equal(
  concurrentQuizDrafts[0].body.id,
  concurrentQuizDrafts[1].body.id,
  "concurrent quiz preparation should return one attempt",
);

const quizSubmissionID = concurrentQuizDrafts[0].body.id;
const quizAnswers = [{
  question_id: quizQuestionID,
  selected_option_ids: [correctOptionID],
}];
const concurrentQuizSubmissions = await Promise.all([
  rpc("submit_step_answers", participantToken, {
    target_submission_id: quizSubmissionID,
    submitted_answers: quizAnswers,
    request_idempotency_key: quizIdempotencyKey,
  }),
  rpc("submit_step_answers", participantToken, {
    target_submission_id: quizSubmissionID,
    submitted_answers: quizAnswers,
    request_idempotency_key: quizIdempotencyKey,
  }),
]);
assert.ok(
  concurrentQuizSubmissions.every((result) => result.ok),
  "concurrent quiz submission should resolve successfully",
);
assert.ok(
  concurrentQuizSubmissions.every(
    (result) => result.body.status === "approved",
  ),
  "concurrent quiz submission should produce one approved attempt",
);
const quizRows = await selectRows(
  "quiz_attempt_results",
  `submission_id=eq.${quizSubmissionID}`
    + "&select=id,correct_count,awarded_points",
);
assert.equal(
  quizRows.length,
  1,
  "concurrent quiz submission should persist one result",
);
assert.equal(
  quizRows[0].awarded_points,
  10,
  "server should award quiz points once",
);

const scoreRows = await selectRows(
  "program_scores",
  `enrollment_id=eq.${enrollmentID}`
    + "&select=activity_points,quiz_points,progress_percentage",
);
assert.deepEqual(
  scoreRows[0],
  {
    activity_points: 10,
    quiz_points: 10,
    progress_percentage: 100,
  },
  "score reconciliation should remain deterministic after retries",
);

console.log("PASS submission/review race integration checks (15 assertions)");
