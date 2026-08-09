import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";

const apiURL = requireEnvironment("API_URL");
const anonKey = process.env.ANON_KEY ?? requireEnvironment("PUBLISHABLE_KEY");
const serviceRoleKey = process.env.SERVICE_ROLE_KEY ??
  requireEnvironment("SECRET_KEY");

assert.ok(
  ["127.0.0.1", "localhost", "::1"].includes(new URL(apiURL).hostname),
  "Phase 12 integration must target local Supabase",
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
  headers = {},
  prefer,
} = {}) {
  return fetch(`${apiURL}${path}`, {
    method,
    headers: {
      apikey: apiKey,
      Authorization: `Bearer ${token}`,
      ...(body === undefined ? {} : { "Content-Type": "application/json" }),
      ...(prefer ? { Prefer: prefer } : {}),
      ...headers,
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
}

async function payload(response) {
  const text = await response.text();
  return text ? JSON.parse(text) : null;
}

async function expectStatus(response, status, label) {
  const body = await payload(response);
  assert.equal(
    response.status,
    status,
    `${label}: expected HTTP ${status}, received ${response.status} ${JSON.stringify(body)}`,
  );
  return body;
}

async function createUser(label) {
  const suffix = randomUUID();
  const email = `${label}-${suffix}@test.invalid`;
  const password = `Phase12-${suffix}!`;
  const user = await expectStatus(
    await request("/auth/v1/admin/users", {
      method: "POST",
      body: { email, password, email_confirm: true },
    }),
    200,
    `create ${label}`,
  );
  return { id: user.id, email, password };
}

async function signIn(user) {
  const session = await expectStatus(
    await request("/auth/v1/token?grant_type=password", {
      method: "POST",
      token: anonKey,
      apiKey: anonKey,
      body: { email: user.email, password: user.password },
    }),
    200,
    `sign in ${user.email}`,
  );
  return session.access_token;
}

async function insert(table, body) {
  await expectStatus(
    await request(`/rest/v1/${table}`, {
      method: "POST",
      body,
      prefer: "return=minimal",
    }),
    201,
    `insert ${table}`,
  );
}

async function patch(table, query, body) {
  await expectStatus(
    await request(`/rest/v1/${table}?${query}`, {
      method: "PATCH",
      body,
      prefer: "return=minimal",
    }),
    204,
    `patch ${table}`,
  );
}

async function remove(table, query) {
  await expectStatus(
    await request(`/rest/v1/${table}?${query}`, {
      method: "DELETE",
      prefer: "return=minimal",
    }),
    204,
    `delete ${table}`,
  );
}

function base64URL(value) {
  return Buffer.from(JSON.stringify(value)).toString("base64url");
}

function xcodeSignedTransaction({
  transactionID,
  originalTransactionID = transactionID,
  productID,
  appAccountToken,
  bundleID = "com.ranggar.MSCBodyTransformation",
  signedAt = Date.now(),
}) {
  const transaction = {
    originalTransactionId: originalTransactionID,
    transactionId: transactionID,
    webOrderLineItemId: transactionID,
    bundleId: bundleID,
    productId: productID,
    purchaseDate: signedAt - 1_000,
    originalPurchaseDate: signedAt - 1_000,
    quantity: 1,
    type: "Non-Consumable",
    appAccountToken,
    inAppOwnershipType: "PURCHASED",
    signedDate: signedAt,
    environment: "Xcode",
    storefront: "IDN",
    storefrontId: "143476",
    transactionReason: "PURCHASE",
    currency: "IDR",
    price: 250_000_000,
  };
  return `${base64URL({ alg: "ES256", typ: "JWT" })}.${base64URL(transaction)}.AA`;
}

function xcodeSignedNotification({ notificationUUID, signedAt = Date.now() }) {
  const notification = {
    notificationType: "TEST",
    notificationUUID,
    data: {
      bundleId: "com.ranggar.MSCBodyTransformation",
      environment: "Xcode",
    },
    version: "2.0",
    signedDate: signedAt,
  };
  return `${base64URL({ alg: "ES256", typ: "JWT" })}.${base64URL(notification)}.AA`;
}

async function commerce(token, path, { method = "GET", body, idempotencyKey } = {}) {
  return request(`/functions/v1/commerce/${path}`, {
    method,
    token,
    apiKey: anonKey,
    body,
    headers: idempotencyKey ? { "Idempotency-Key": idempotencyKey } : {},
  });
}

const createdUsers = [];
let fulfilledTransactionID = null;
let fulfilledEnrollmentID = null;
let fulfilledEntitlementID = null;
const ids = {
  application: randomUUID(),
  payment: randomUUID(),
  entitlement: randomUUID(),
  program: randomUUID(),
  mapping: randomUUID(),
  notification: randomUUID(),
};

try {
  const admin = await createUser("phase12-edge-admin");
  const coach = await createUser("phase12-edge-coach");
  const participant = await createUser("phase12-edge-participant");
  const attacker = await createUser("phase12-edge-attacker");
  createdUsers.push(admin, coach, participant, attacker);
  const coachQR = `coach_${randomUUID().replaceAll("-", "")}`;

  const activeProfile = {
    onboarding_status: "active",
    provisional_expires_at: null,
    finalized_at: new Date().toISOString(),
  };
  await patch("profiles", `user_id=eq.${admin.id}`, {
    ...activeProfile,
    role: "admin",
    display_name: "Admin Commerce Edge",
  });
  await patch("profiles", `user_id=eq.${coach.id}`, {
    ...activeProfile,
    role: "coach",
    display_name: "Coach Commerce Edge",
    phone_number: "+6281200000012",
    member_level: "sc",
    coach_is_approved: true,
    coach_qr_identifier: coachQR,
  });
  for (const [user, displayName] of [
    [participant, "Peserta Commerce Edge"],
    [attacker, "Peserta Commerce Lain"],
  ]) {
    await patch("profiles", `user_id=eq.${user.id}`, {
      ...activeProfile,
      display_name: displayName,
      phone_number: "+6281299999912",
      ...(user.id === attacker.id ? { current_coach_id: coach.id } : {}),
    });
  }

  await insert("coach_applications", {
    id: ids.application,
    applicant_user_id: coach.id,
    participant_profile_id: coach.id,
    display_name_snapshot: "Coach Commerce Edge",
    phone_number_snapshot: "+6281200000012",
    member_level_snapshot: "sc",
    has_completed_hom_sts: true,
    has_completed_ict: true,
    terms_version: "phase12-edge-v1",
    status: "active",
    draft_idempotency_key: `phase12-${randomUUID()}`,
    submitted_at: new Date().toISOString(),
    decided_at: new Date().toISOString(),
    decided_by: admin.id,
  });
  await insert("coach_payment_records", {
    id: ids.payment,
    application_id: ids.application,
    state: "verified",
    price_band: "entry",
    amount_minor_units: 100_000,
    provider_reference: `fixture-${randomUUID()}`,
    verified_at: new Date().toISOString(),
  });
  await insert("coach_access_entitlements", {
    id: ids.entitlement,
    application_id: ids.application,
    payment_record_id: ids.payment,
    coach_user_id: coach.id,
    status: "active",
    starts_at: new Date(Date.now() - 86_400_000).toISOString(),
    ends_at: new Date(Date.now() + 86_400_000).toISOString(),
  });
  await insert("programs", {
    id: ids.program,
    title: "Program Commerce Edge",
    status: "active",
    pace: "scheduled",
    duration_mode: "specific_dates",
    starts_on: new Date().toISOString().slice(0, 10),
    ends_on: new Date(Date.now() + 7 * 86_400_000).toISOString().slice(0, 10),
    timezone: "Asia/Makassar",
    participant_limit: 5,
    past_step_policy: "available",
    future_step_policy: "locked",
    wellness_disclaimer: "Program kebugaran non-diagnostik.",
    points_per_activity: 10,
    points_per_weight_kg: 100,
    quiz_passing_percentage: 70,
    pricing_mode: "paid",
    desired_price: 250_000,
    created_by: admin.id,
    published_at: new Date().toISOString(),
    registration_closes_at: new Date(Date.now() + 86_400_000).toISOString(),
  });
  await insert("program_store_products", {
    id: ids.mapping,
    program_id: ids.program,
    platform: "app_store",
    environment: "xcode",
    product_id: "local.msc.program.phase12.edge",
    product_type: "non_consumable",
    provisioning_status: "ready",
    actual_price: 250_000,
    currency_code: "IDR",
  });

  const participantToken = await signIn(participant);
  const attackerToken = await signIn(attacker);

  await expectStatus(
    await request("/rest/v1/rpc/resolve_coach_qr_for_enrollment", {
      method: "POST",
      token: participantToken,
      apiKey: anonKey,
      body: { scanned_coach_qr: coachQR },
    }),
    200,
    "paid program Coach QR selection",
  );

  await expectStatus(
    await request("/rest/v1/rpc/create_program_purchase_intent", {
      method: "POST",
      body: {
        target_program_id: ids.program,
        caller_account_id: participant.id,
        target_environment: "xcode",
        request_idempotency_key: `rpc-${randomUUID()}`,
      },
    }),
    200,
    "trusted program preflight RPC fixture",
  );

  const unauthenticated = await fetch(
    `${apiURL}/functions/v1/commerce/history`,
    { headers: { apikey: anonKey } },
  );
  assert.equal(unauthenticated.status, 401, "commerce rejects missing user JWT");

  const invalidNotification = await expectStatus(
    await request("/functions/v1/commerce-apple-notifications", {
      method: "POST",
      token: anonKey,
      apiKey: anonKey,
      body: { signedPayload: "tampered.payload.signature" },
    }),
    422,
    "tampered Apple notification",
  );
  assert.equal(invalidNotification.code, "purchase_unverified");

  const signedNotification = xcodeSignedNotification({
    notificationUUID: ids.notification,
  });
  const acceptedNotification = await expectStatus(
    await request("/functions/v1/commerce-apple-notifications", {
      method: "POST",
      token: anonKey,
      apiKey: anonKey,
      body: { signedPayload: signedNotification },
    }),
    202,
    "valid local Apple TEST notification",
  );
  assert.equal(acceptedNotification.status, "accepted");
  assert.equal(acceptedNotification.duplicate, false);

  const duplicateNotification = await expectStatus(
    await request("/functions/v1/commerce-apple-notifications", {
      method: "POST",
      token: anonKey,
      apiKey: anonKey,
      body: { signedPayload: signedNotification },
    }),
    202,
    "duplicate local Apple TEST notification",
  );
  assert.equal(duplicateNotification.duplicate, true);

  const notificationRows = await expectStatus(
    await request(
      `/rest/v1/apple_notification_inbox?notification_uuid=eq.${ids.notification}&select=status`,
    ),
    200,
    "durable notification inbox",
  );
  assert.equal(notificationRows.length, 1);
  assert.equal(notificationRows[0].status, "processed");

  const preflight = await expectStatus(
    await commerce(participantToken, `programs/${ids.program}/preflight`, {
      method: "POST",
      idempotencyKey: `edge-${randomUUID()}`,
    }),
    200,
    "program preflight",
  );
  assert.equal(preflight.subjectKind, "program");
  assert.equal(preflight.productId, "local.msc.program.phase12.edge");
  assert.equal(preflight.environment, "xcode");

  const pending = await expectStatus(
    await commerce(
      participantToken,
      `intents/${preflight.purchaseIntentId}/pending`,
      { method: "POST" },
    ),
    200,
    "mark intent pending",
  );
  assert.equal(pending.status, "purchase_pending");

  const malformed = await expectStatus(
    await commerce(participantToken, "apple/verify", {
      method: "POST",
      body: {
        purchaseIntentId: preflight.purchaseIntentId,
        signedTransaction: "tampered.payload.signature",
      },
    }),
    422,
    "tampered local transaction",
  );
  assert.equal(malformed.code, "purchase_unverified");

  const stolenIntent = await expectStatus(
    await commerce(attackerToken, "apple/verify", {
      method: "POST",
      body: {
        purchaseIntentId: preflight.purchaseIntentId,
        signedTransaction: xcodeSignedTransaction({
          transactionID: `edge-wrong-account-${randomUUID()}`,
          productID: preflight.productId,
          appAccountToken: preflight.appAccountToken,
        }),
      },
    }),
    409,
    "another account cannot claim an intent",
  );
  assert.equal(stolenIntent.code, "purchase_intent_expired");

  const transactionID = `edge-valid-${randomUUID()}`;
  const signedTransaction = xcodeSignedTransaction({
    transactionID,
    productID: preflight.productId,
    appAccountToken: preflight.appAccountToken,
  });
  const fulfilled = await expectStatus(
    await commerce(participantToken, "apple/verify", {
      method: "POST",
      body: {
        purchaseIntentId: preflight.purchaseIntentId,
        signedTransaction,
      },
    }),
    200,
    "valid Xcode transaction fulfillment",
  );
  assert.equal(fulfilled.status, "verified");
  assert.equal(fulfilled.idempotent, false);
  fulfilledTransactionID = fulfilled.transactionId;
  fulfilledEnrollmentID = fulfilled.enrollmentId;
  fulfilledEntitlementID = fulfilled.programEntitlementId;

  const boundProfiles = await expectStatus(
    await request(`/rest/v1/profiles?user_id=eq.${participant.id}&select=current_coach_id`),
    200,
    "verified fulfillment Coach binding",
  );
  assert.equal(boundProfiles[0].current_coach_id, coach.id);

  const duplicate = await expectStatus(
    await commerce(participantToken, "apple/verify", {
      method: "POST",
      body: {
        purchaseIntentId: preflight.purchaseIntentId,
        signedTransaction,
      },
    }),
    200,
    "duplicate transaction fulfillment",
  );
  assert.equal(duplicate.transactionId, fulfilled.transactionId);
  assert.equal(duplicate.idempotent, true);

  const history = await expectStatus(
    await commerce(participantToken, "history"),
    200,
    "commerce history",
  );
  assert.equal(history.transactions.length, 1);
  assert.equal(history.transactions[0].subjectKind, "program");
  assert.equal(history.transactions[0].priceMilliunits, 250_000_000);
  assert.equal("signedTransaction" in history.transactions[0], false);

  const restored = await expectStatus(
    await commerce(participantToken, "apple/restore", {
      method: "POST",
      body: { transactions: [{ signedTransaction }] },
    }),
    200,
    "restore current entitlement",
  );
  assert.equal(restored.fulfillments.length, 1);
  assert.equal(restored.fulfillments[0].idempotent, true);

  process.stdout.write("Phase 12 commerce integration: 29 assertions passed.\n");
} finally {
  try {
    await remove(
      "apple_notification_inbox",
      `notification_uuid=eq.${ids.notification}`,
    );
    if (fulfilledEntitlementID) {
      await remove(
        "program_entitlement_events",
        `entitlement_id=eq.${fulfilledEntitlementID}`,
      );
    }
    if (fulfilledEnrollmentID) {
      await remove("program_scores", `enrollment_id=eq.${fulfilledEnrollmentID}`);
    }
    await remove("program_enrollments", `program_id=eq.${ids.program}`);
    await remove("program_entitlements", `program_id=eq.${ids.program}`);
    if (fulfilledTransactionID) {
      await remove(
        "commerce_transaction_events",
        `transaction_id=eq.${fulfilledTransactionID}`,
      );
    }
    await remove("commerce_purchase_intents", `program_id=eq.${ids.program}`);
    await remove("commerce_transactions", `program_id=eq.${ids.program}`);
    await remove("program_store_products", `id=eq.${ids.mapping}`);
    await remove("programs", `id=eq.${ids.program}`);
    await remove("coach_access_entitlements", `id=eq.${ids.entitlement}`);
    await remove("coach_payment_records", `id=eq.${ids.payment}`);
    await remove("coach_applications", `id=eq.${ids.application}`);
  } catch {
    // The dedicated phase12-edge identity prefix permits deterministic cleanup
    // after an interrupted local-only test without printing credentials.
  }
  for (const user of createdUsers.reverse()) {
    await request(`/auth/v1/admin/users/${user.id}`, { method: "DELETE" })
      .catch(() => null);
  }
}
