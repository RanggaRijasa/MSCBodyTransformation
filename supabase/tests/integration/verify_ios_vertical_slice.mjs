const apiURL = requireEnvironment("API_URL");
const serviceRoleKey = requireEnvironment("SERVICE_ROLE_KEY");
const programID = requireEnvironment("MSC_PHASE09_PROGRAM_ID");

function requireEnvironment(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

async function request(path) {
  const response = await fetch(`${apiURL}${path}`, {
    headers: {
      apikey: serviceRoleKey,
      Authorization: `Bearer ${serviceRoleKey}`,
    },
  });
  const body = await response.json();
  if (!response.ok) {
    throw new Error(`Verification request failed: HTTP ${response.status}`);
  }
  return body;
}

function expect(condition, description) {
  if (!condition) {
    throw new Error(`FAIL: ${description}`);
  }
}

const enrollments = await request(
  `/rest/v1/program_enrollments?program_id=eq.${programID}`
    + "&select=id,status",
);
expect(enrollments.length === 1, "exactly one enrollment was created");
expect(enrollments[0].status === "active", "enrollment is active");

const enrollmentID = enrollments[0].id;
const submissions = await request(
  `/rest/v1/step_submissions?enrollment_id=eq.${enrollmentID}`
    + "&select=id,status",
);
expect(submissions.length === 1, "exactly one submission was created");
expect(submissions[0].status === "approved", "Coach approved submission");

const answers = await request(
  `/rest/v1/step_submission_answers`
    + `?submission_id=eq.${submissions[0].id}`
    + "&select=private_photo_path",
);
expect(answers.length === 1, "typed photo answer was stored");
expect(
  typeof answers[0].private_photo_path === "string",
  "private photo path was stored",
);

const scores = await request(
  `/rest/v1/program_scores?enrollment_id=eq.${enrollmentID}`
    + "&select=activity_points,quiz_points,weight_points,"
    + "adjustment_points,progress_percentage,rank",
);
expect(scores.length === 1, "authoritative score was created");
expect(scores[0].activity_points === 10, "activity points are authoritative");
expect(scores[0].quiz_points === 0, "quiz points remain zero");
expect(scores[0].weight_points === 0, "weight points remain zero");
expect(scores[0].adjustment_points === 0, "adjustments remain zero");
expect(
  scores[0].activity_points
    + scores[0].quiz_points
    + scores[0].weight_points
    + scores[0].adjustment_points === 10,
  "authoritative score components total ten",
);
expect(scores[0].progress_percentage === 100, "progress is complete");
expect(scores[0].rank === 1, "rank is deterministic");

process.stdout.write("PASS: iOS local Supabase vertical slice persisted\n");
