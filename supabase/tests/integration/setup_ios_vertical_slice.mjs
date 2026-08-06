import { randomUUID } from "node:crypto";

const apiURL = requireEnvironment("API_URL");
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

async function responseJSON(response) {
  const text = await response.text();
  return text.length > 0 ? JSON.parse(text) : {};
}

async function expectSuccess(response, description) {
  const body = await responseJSON(response);
  if (!response.ok) {
    throw new Error(
      `${description}: HTTP ${response.status}`
        + (body.message ? ` (${body.message})` : ""),
    );
  }
  return body;
}

async function createUser(label) {
  const suffix = randomUUID();
  const email = `${label}-${suffix}@test.invalid`;
  const password = `Phase09-${suffix}!`;
  const user = await expectSuccess(
    await request("/auth/v1/admin/users", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        email,
        password,
        email_confirm: true,
      }),
    }),
    `create ${label} identity`,
  );
  return { id: user.id, email, password };
}

async function insert(table, rows) {
  await expectSuccess(
    await request(`/rest/v1/${table}`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Prefer: "return=minimal",
      },
      body: JSON.stringify(rows),
    }),
    `insert ${table}`,
  );
}

async function upsertProfiles(rows) {
  await expectSuccess(
    await request("/rest/v1/profiles?on_conflict=user_id", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Prefer: "resolution=merge-duplicates,return=minimal",
      },
      body: JSON.stringify(rows),
    }),
    "upsert bootstrapped profiles",
  );
}

function shellExport(name, value) {
  if (value.includes("'")) {
    throw new Error(`Unsafe shell value for ${name}`);
  }
  return `export ${name}='${value}'`;
}

const admin = await createUser("ios-live-admin");
const coach = await createUser("ios-live-coach");
const participant = await createUser("ios-live-participant");
const coachQR = `ios-coach-${randomUUID()}`;
const programID = randomUUID();
const dayID = randomUUID();
const stepID = randomUUID();
const questionID = randomUUID();
const localDate = new Intl.DateTimeFormat("en-CA", {
  timeZone: "Asia/Jakarta",
  year: "numeric",
  month: "2-digit",
  day: "2-digit",
}).format(new Date());

await upsertProfiles([
  {
    user_id: admin.id,
    role: "admin",
    display_name: "Admin iOS Live",
    current_coach_id: null,
    coach_qr_identifier: null,
    coach_is_approved: false,
  },
  {
    user_id: coach.id,
    role: "coach",
    display_name: "Coach iOS Live",
    current_coach_id: null,
    coach_qr_identifier: coachQR,
    coach_is_approved: true,
  },
  {
    user_id: participant.id,
    role: "participant",
    display_name: "Peserta iOS Live",
    current_coach_id: null,
    coach_qr_identifier: null,
    coach_is_approved: false,
  },
]);
await insert("programs", {
  id: programID,
  title: "Program iOS Live",
  status: "active",
  pace: "scheduled",
  duration_mode: "fixed_duration",
  starts_on: localDate,
  ends_on: localDate,
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
  title: "Hari iOS Live",
  scheduled_on: localDate,
});
await insert("program_steps", {
  id: stepID,
  program_day_id: dayID,
  step_order: 1,
  title: "Foto iOS Live",
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

process.stdout.write([
  shellExport("MSC_PHASE09_PROGRAM_ID", programID),
  shellExport("MSC_PHASE09_COACH_QR", coachQR),
  shellExport("MSC_PHASE09_COACH_EMAIL", coach.email),
  shellExport("MSC_PHASE09_COACH_PASSWORD", coach.password),
  shellExport("MSC_PHASE09_PARTICIPANT_EMAIL", participant.email),
  shellExport("MSC_PHASE09_PARTICIPANT_PASSWORD", participant.password),
].join("\n"));
