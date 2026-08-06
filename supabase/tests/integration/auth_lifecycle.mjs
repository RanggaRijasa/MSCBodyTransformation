import assert from "node:assert/strict";
import { createHash, randomBytes, randomUUID } from "node:crypto";

const apiURL = requireEnvironment("API_URL");
const anonKey = process.env.ANON_KEY
  ?? requireEnvironment("PUBLISHABLE_KEY");
const serviceRoleKey = process.env.SERVICE_ROLE_KEY
  ?? requireEnvironment("SECRET_KEY");
const mailpitURL = process.env.MAILPIT_URL
  ?? requireEnvironment("INBUCKET_URL");

assertLocalURL(apiURL, "API_URL");
assertLocalURL(mailpitURL, "MAILPIT_URL");

const runID = randomUUID();
const email = `phase10-${runID}@test.invalid`;
const password = `Phase10-${runID}!`;
const replacementPassword = `Phase10-New-${runID}!`;
const coachEmail = `phase10-coach-${runID}@test.invalid`;
const coachPassword = `Phase10-Coach-${runID}!`;
const coachQR = `phase10-coach-${runID}`;
const createdUserIDs = [];

function requireEnvironment(name) {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

function assertLocalURL(value, name) {
  const url = new URL(value);
  assert.ok(
    ["127.0.0.1", "localhost", "::1"].includes(url.hostname),
    `${name} must target the local Supabase stack`,
  );
}

function base64URL(value) {
  return value.toString("base64url");
}

function makePKCE() {
  const verifier = base64URL(randomBytes(48));
  const challenge = base64URL(createHash("sha256").update(verifier).digest());
  return { verifier, challenge };
}

async function request(path, {
  method = "GET",
  token = anonKey,
  apiKey = anonKey,
  body,
  redirect = "follow",
} = {}) {
  return fetch(`${apiURL}${path}`, {
    method,
    redirect,
    headers: {
      apikey: apiKey,
      Authorization: `Bearer ${token}`,
      ...(body === undefined ? {} : { "Content-Type": "application/json" }),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
}

async function responseJSON(response) {
  const text = await response.text();
  return text.length === 0 ? {} : JSON.parse(text);
}

async function expectSuccess(response, label) {
  assert.ok(response.ok, `${label}: expected success, got HTTP ${response.status}`);
  return responseJSON(response);
}

async function createConfirmedCoach() {
  const user = await expectSuccess(
    await request("/auth/v1/admin/users", {
      method: "POST",
      token: serviceRoleKey,
      apiKey: serviceRoleKey,
      body: { email: coachEmail, password: coachPassword, email_confirm: true },
    }),
    "create Coach fixture",
  );
  createdUserIDs.push(user.id);
  const response = await request(`/rest/v1/profiles?user_id=eq.${user.id}`, {
    method: "PATCH",
    token: serviceRoleKey,
    apiKey: serviceRoleKey,
    body: {
      role: "coach",
      display_name: "Coach Auth Lokal",
      coach_qr_identifier: coachQR,
      coach_is_approved: true,
      onboarding_status: "active",
      provisional_expires_at: null,
      finalized_at: new Date().toISOString(),
    },
  });
  await expectSuccess(response, "activate Coach fixture");
}

async function waitForMail(recipient, subjectFragment) {
  for (let attempt = 0; attempt < 40; attempt += 1) {
    const listing = await fetch(`${mailpitURL}/api/v1/messages`);
    const body = await responseJSON(listing);
    const messages = body.messages ?? body.Messages ?? [];
    const match = messages.find((message) => {
      const recipients = message.To ?? message.to ?? [];
      const addresses = recipients.map((entry) => entry.Address ?? entry.address ?? "");
      const subject = message.Subject ?? message.subject ?? "";
      return addresses.includes(recipient) && subject.includes(subjectFragment);
    });
    if (match) {
      const id = match.ID ?? match.Id ?? match.id;
      const detail = await fetch(`${mailpitURL}/api/v1/message/${id}`);
      return responseJSON(detail);
    }
    await new Promise((resolve) => setTimeout(resolve, 250));
  }
  throw new Error("Expected local Auth email was not delivered");
}

function verificationURL(message) {
  const source = [message.HTML, message.Html, message.Text, message.text]
    .filter(Boolean)
    .join("\n")
    .replaceAll("&amp;", "&");
  const match = source.match(/https?:\/\/[^\s"'<>]+\/auth\/v1\/verify\?[^\s"'<>]+/);
  assert.ok(match, "Auth email did not contain a verification URL");
  return match[0];
}

async function followVerificationEmail(recipient, subject, verifier) {
  const message = await waitForMail(recipient, subject);
  const verifyResponse = await fetch(verificationURL(message), {
    redirect: "manual",
  });
  assert.ok(
    [302, 303].includes(verifyResponse.status),
    "verification endpoint must redirect",
  );
  const location = verifyResponse.headers.get("location");
  assert.ok(location, "verification redirect must include a location");
  const callback = new URL(location);
  assert.equal(callback.protocol, "mscbodytransformation:");
  const code = callback.searchParams.get("code");
  assert.ok(code, "PKCE callback must contain a one-time code");
  return expectSuccess(
    await request("/auth/v1/token?grant_type=pkce", {
      method: "POST",
      body: { auth_code: code, code_verifier: verifier },
    }),
    "exchange one-time callback code",
  );
}

async function deleteUser(id) {
  const response = await request(`/auth/v1/admin/users/${id}`, {
    method: "DELETE",
    token: serviceRoleKey,
    apiKey: serviceRoleKey,
  });
  assert.ok(
    response.ok || response.status === 404,
    `cleanup identity: expected success, got HTTP ${response.status}`,
  );
}

async function cleanupInterruptedTestIdentities() {
  const response = await expectSuccess(
    await request("/auth/v1/admin/users?per_page=1000", {
      token: serviceRoleKey,
      apiKey: serviceRoleKey,
    }),
    "list interrupted Phase 10 test identities",
  );
  const users = response.users ?? [];
  for (const user of users) {
    const testEmail = user.email ?? "";
    if (
      testEmail.startsWith("phase10-")
      && testEmail.endsWith("@test.invalid")
    ) {
      await deleteUser(user.id);
    }
  }
}

try {
  await cleanupInterruptedTestIdentities();
  await createConfirmedCoach();

  const signupPKCE = makePKCE();
  const signup = await expectSuccess(
    await request("/auth/v1/signup?redirect_to=mscbodytransformation%3A%2F%2Fauth%2Fcallback", {
      method: "POST",
      body: {
        email,
        password,
        code_challenge: signupPKCE.challenge,
        code_challenge_method: "s256",
        data: {
          display_name: "Peserta Auth Lokal",
          role: "admin",
          onboarding_status: "active",
        },
      },
    }),
    "sign up",
  );
  const signupUser = signup.user ?? signup;
  assert.ok(signupUser.id, "signup must return a user");
  assert.ok(
    !signup.access_token,
    "unverified signup must not open a session",
  );
  createdUserIDs.push(signupUser.id);

  const profiles = await expectSuccess(
    await request(`/rest/v1/profiles?user_id=eq.${signupUser.id}&select=user_id,role,onboarding_status,display_name`, {
      token: serviceRoleKey,
      apiKey: serviceRoleKey,
    }),
    "read bootstrapped profile",
  );
  assert.equal(profiles.length, 1, "signup must create exactly one profile");
  assert.equal(profiles[0].role, "participant", "metadata must not elevate role");
  assert.equal(profiles[0].onboarding_status, "provisional");

  let session = await followVerificationEmail(email, "Confirm", signupPKCE.verifier);
  assert.ok(
    Boolean(session.access_token && session.refresh_token),
    "verification must create a session",
  );

  const profileUpdate = await request("/rest/v1/rpc/update_my_profile", {
    method: "POST",
    token: session.access_token,
    body: {
      new_display_name: "Peserta Auth Lokal",
      new_phone_number: "+6281200000010",
      new_member_level: "member",
      new_account_purpose: "participant",
    },
  });
  await expectSuccess(profileUpdate, "update allowlisted profile fields");

  const elevation = await request(`/rest/v1/profiles?user_id=eq.${signupUser.id}`, {
    method: "PATCH",
    token: session.access_token,
    body: { role: "admin" },
  });
  assert.equal(elevation.status, 403, "Participant must not update protected role");

  await expectSuccess(
    await request("/rest/v1/rpc/finalize_participant_onboarding", {
      method: "POST",
      token: session.access_token,
      body: { coach_qr: coachQR },
    }),
    "finalize Participant onboarding",
  );

  const rotated = await expectSuccess(
    await request("/auth/v1/token?grant_type=refresh_token", {
      method: "POST",
      body: { refresh_token: session.refresh_token },
    }),
    "rotate refresh token",
  );
  assert.notEqual(rotated.refresh_token, session.refresh_token, "refresh token must rotate");
  session = rotated;

  const recoveryPKCE = makePKCE();
  await expectSuccess(
    await request("/auth/v1/recover?redirect_to=mscbodytransformation%3A%2F%2Fauth%2Fcallback", {
      method: "POST",
      body: {
        email,
        code_challenge: recoveryPKCE.challenge,
        code_challenge_method: "s256",
      },
    }),
    "request password recovery",
  );
  const recoverySession = await followVerificationEmail(
    email,
    "Reset",
    recoveryPKCE.verifier,
  );
  await expectSuccess(
    await request("/auth/v1/user", {
      method: "PUT",
      token: recoverySession.access_token,
      body: { password: replacementPassword },
    }),
    "update recovered password",
  );

  const login = await expectSuccess(
    await request("/auth/v1/token?grant_type=password", {
      method: "POST",
      body: { email, password: replacementPassword },
    }),
    "sign in with updated password",
  );
  await expectSuccess(
    await request("/auth/v1/logout", {
      method: "POST",
      token: login.access_token,
    }),
    "log out",
  );

  const reauthenticated = await expectSuccess(
    await request("/auth/v1/token?grant_type=password", {
      method: "POST",
      body: { email, password: replacementPassword },
    }),
    "reauthenticate before account deletion",
  );
  const deletion = await request("/functions/v1/delete-account", {
    method: "POST",
    token: reauthenticated.access_token,
  });
  assert.equal(
    deletion.status,
    204,
    "recently reauthenticated account deletion must complete immediately",
  );

  const deletedIdentity = await request(
    `/auth/v1/admin/users/${signupUser.id}`,
    {
      token: serviceRoleKey,
      apiKey: serviceRoleKey,
    },
  );
  assert.equal(
    deletedIdentity.status,
    404,
    "hard-deleted Auth identity must no longer exist",
  );

  const deletedProfiles = await expectSuccess(
    await request(
      `/rest/v1/profiles?user_id=eq.${signupUser.id}&select=user_id`,
      {
        token: serviceRoleKey,
        apiKey: serviceRoleKey,
      },
    ),
    "verify deleted application profile",
  );
  assert.equal(
    deletedProfiles.length,
    0,
    "hard deletion must cascade the redacted application profile",
  );

  process.stdout.write("Phase 10 local Auth lifecycle: PASS (22 checks)\n");
} finally {
  for (const id of createdUserIDs.reverse()) {
    await deleteUser(id);
  }
}
