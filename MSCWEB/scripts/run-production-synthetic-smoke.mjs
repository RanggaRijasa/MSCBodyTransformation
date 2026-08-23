import { chmod, writeFile } from 'node:fs/promises';
import { randomBytes, randomUUID } from 'node:crypto';
import { spawnSync } from 'node:child_process';

const supabaseUrl = requiredEnvironment('EXPO_PUBLIC_SUPABASE_URL').replace(/\/$/u, '');
const publishableKey = requiredEnvironment('EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY');
const secretKey = requiredEnvironment('SUPABASE_SECRET_KEY');
const productionOrigin = (process.env.PRODUCTION_ORIGIN ?? 'https://msc-body-transformation.com').replace(/\/$/u, '');
const runId = `w08-prod-smoke-${new Date().toISOString().replace(/[-:.]/gu, '').replace('T', '-').replace('Z', '')}-${randomBytes(4).toString('hex')}`;
const manifestPath = new URL(`../.w08-${runId}.local.json`, import.meta.url);
const password = `${randomBytes(24).toString('base64url')}Aa1!`;
const fixtureJpeg = Buffer.from('/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////2wBDAf//////////////////////////////////////////////////////////////////////////////////////wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAf/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIQAxAAAAF//8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABBQJ//8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAgBAwEBPwF//8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAgBAgEBPwF//8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQAGPwJ//8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPyF//9oADAMBAAIAAwAAABD/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oACAEDAQE/EB//xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oACAECAQE/EB//xAAUEAEAAAAAAAAAAAAAAAAAAAAA/9oACAEBAAE/EB//2Q==', 'base64');

const state = {
  runId,
  googleOAuth: 'DEFERRED',
  created: {},
  checks: {},
  cleanup: {},
  residual: {},
};

function requiredEnvironment(name) {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(`Environment ${name} wajib tersedia.`);
  return value;
}

function encodedObjectPath(path) {
  return path.split('/').map(encodeURIComponent).join('/');
}

async function request(url, options = {}, expected = [200]) {
  const response = await fetch(url, options);
  if (!expected.includes(response.status)) {
    let errorCode = '';
    if ((response.headers.get('content-type') ?? '').includes('json')) {
      const payload = await response.json().catch(() => null);
      const candidate = payload?.error_code ?? payload?.code;
      if (typeof candidate === 'string' && /^[a-z0-9_-]{1,80}$/iu.test(candidate)) {
        errorCode = ` (${candidate})`;
      }
    }
    throw new Error(`Request ${new URL(url).pathname} gagal dengan HTTP ${response.status}${errorCode}.`);
  }
  if (response.status === 204 || response.headers.get('content-length') === '0') return null;
  const contentType = response.headers.get('content-type') ?? '';
  return contentType.includes('json') ? response.json() : response.text();
}

function serviceHeaders(extra = {}) {
  return {
    apikey: secretKey,
    Authorization: `Bearer ${secretKey}`,
    ...extra,
  };
}

async function rest(table, method, body, query = '') {
  return request(`${supabaseUrl}/rest/v1/${table}${query ? `?${query}` : ''}`, {
    method,
    headers: serviceHeaders({
      'Content-Type': 'application/json',
      Prefer: method === 'POST' ? 'return=representation' : 'return=minimal',
    }),
    body: body === undefined ? undefined : JSON.stringify(body),
  }, method === 'POST' ? [200, 201] : [200, 204]);
}

async function rpc(name, token, body = {}) {
  return request(`${supabaseUrl}/rest/v1/rpc/${name}`, {
    method: 'POST',
    headers: {
      apikey: publishableKey,
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
}

async function createIdentity(role) {
  const email = `msc+${runId}-${role}@example.invalid`;
  const result = await request(`${supabaseUrl}/auth/v1/admin/users`, {
    method: 'POST',
    headers: serviceHeaders({ 'Content-Type': 'application/json' }),
    body: JSON.stringify({
      email,
      password,
      email_confirm: true,
      user_metadata: { display_name: `Synthetic Smoke ${role} ${runId}` },
    }),
  }, [200, 201]);
  state.created[`${role}Email`] = email;
  state.created[`${role}UserId`] = result.id;
  return { email, id: result.id };
}

async function deleteById(table, id) {
  if (!id) return;
  await rest(table, 'DELETE', undefined, `id=eq.${encodeURIComponent(id)}`);
}

function sqlLiteral(value) {
  return `'${String(value).replaceAll("'", "''")}'`;
}

function databaseQuery(sql) {
  const result = spawnSync('supabase', [
    'db', 'query', '--linked', '--workdir', '..', '--output', 'json', sql,
  ], { cwd: new URL('..', import.meta.url), encoding: 'utf8' });
  if (result.status !== 0) throw new Error('Query database synthetic smoke gagal.');
  const payload = JSON.parse(result.stdout);
  return Array.isArray(payload.rows) ? payload.rows : [];
}

function databaseDelete(table, id) {
  if (!id) return;
  const allowedTables = new Set([
    'payment_destinations',
    'payment_evidence_attempts',
    'payment_orders',
  ]);
  if (!allowedTables.has(table)) throw new Error('Tabel cleanup database tidak diizinkan.');
  databaseQuery(`delete from public.${table} where id = ${sqlLiteral(id)}::uuid;`);
}

async function deleteByColumn(table, column, value) {
  if (!value) return;
  await rest(table, 'DELETE', undefined, `${column}=eq.${encodeURIComponent(value)}`);
}

async function removeObject(bucket, path) {
  if (!path) return;
  await request(`${supabaseUrl}/storage/v1/object/${bucket}/${encodedObjectPath(path)}`, {
    method: 'DELETE',
    headers: serviceHeaders(),
  }, [200, 204, 404]);
}

async function persistManifest() {
  await writeFile(manifestPath, `${JSON.stringify(state, null, 2)}\n`, { mode: 0o600 });
  await chmod(manifestPath, 0o600);
}

async function residualCount(table, column, value) {
  const rows = await request(`${supabaseUrl}/rest/v1/${table}?select=${encodeURIComponent(column)}&${column}=eq.${encodeURIComponent(value)}`, {
    headers: serviceHeaders(),
  });
  return Array.isArray(rows) ? rows.length : -1;
}

async function run() {
  const participant = await createIdentity('participant');
  const coach = await createIdentity('coach');
  state.checks.syntheticAdminIdentities = 'PASS';
  state.checks.emailPasswordAuthentication = 'DEFERRED_PROVIDER_DISABLED';

  await rest('profiles', 'PATCH', {
    role: 'coach',
    coach_qr_identifier: `synthetic-${randomUUID()}`,
    coach_is_approved: true,
    coach_is_public: true,
  }, `user_id=eq.${coach.id}`);

  const application = (await rest('coach_applications', 'POST', {
    applicant_user_id: coach.id,
    participant_profile_id: coach.id,
    display_name_snapshot: `Synthetic Smoke Coach ${runId}`,
    phone_number_snapshot: '+620000000000',
    member_level_snapshot: 'sc',
    has_completed_hom_sts: true,
    has_completed_ict: true,
    terms_version: `synthetic-${runId}`,
    status: 'draft',
    draft_idempotency_key: `${runId}-coach`,
  }))[0];
  state.created.coachApplicationId = application.id;
  const coachPayment = (await rest('coach_payment_records', 'POST', {
    application_id: application.id,
    state: 'pending',
    price_band: 'entry',
    amount_minor_units: 1,
  }))[0];
  state.created.coachPaymentRecordId = coachPayment.id;
  const entitlement = (await rest('coach_access_entitlements', 'POST', {
    application_id: application.id,
    payment_record_id: coachPayment.id,
    coach_user_id: coach.id,
    status: 'active',
    starts_at: new Date(Date.now() - 60_000).toISOString(),
    ends_at: new Date(Date.now() + 3_600_000).toISOString(),
  }))[0];
  state.created.coachEntitlementId = entitlement.id;

  const namespace = (await rest('coach_public_media_namespaces', 'POST', {
    coach_user_id: coach.id,
  }))[0];
  const coachMediaPath = `coaches/${namespace.media_namespace}/avatar/${randomUUID()}.jpg`;
  state.created.coachMediaPath = coachMediaPath;
  await request(`${supabaseUrl}/storage/v1/object/coach-public-media/${encodedObjectPath(coachMediaPath)}`, {
    method: 'POST',
    headers: serviceHeaders({
      'Content-Type': 'image/jpeg',
      'x-upsert': 'false',
    }),
    body: fixtureJpeg,
  }, [200, 201]);
  const handle = `synthetic-${randomBytes(8).toString('hex')}`;
  await rest('coach_public_profile_drafts', 'POST', {
    coach_user_id: coach.id,
    public_handle: handle,
    profile_photo_object_path: coachMediaPath,
    professional_headline: 'Fixture Coach non-billable',
    biography: `Synthetic production smoke ${runId}`,
    service_area: 'Synthetic',
    instagram_url: '',
    tiktok_url: '',
    website_url: '',
    whatsapp_number: '',
    phone_number: '',
    show_instagram: false,
    show_tiktok: false,
    show_website: false,
    show_whatsapp: false,
    show_phone: false,
  });
  await rest('coach_public_profiles', 'POST', {
    coach_user_id: coach.id,
    public_handle: handle,
    display_name: `Synthetic Smoke Coach ${runId}`,
    photo_kind: 'storage',
    photo_reference: coachMediaPath,
    professional_headline: 'Fixture Coach non-billable',
    biography: `Synthetic production smoke ${runId}`,
    service_area: 'Synthetic',
  });
  const privateAsset = databaseQuery(`
    insert into private.coach_public_media_assets(
      coach_user_id, object_path, media_folder
    ) values (
      ${sqlLiteral(coach.id)}::uuid,
      ${sqlLiteral(coachMediaPath)},
      'avatar'
    ) returning id::text;
  `)[0];
  state.created.coachHandle = handle;
  state.created.coachAssetId = privateAsset.id;

  const publishedProfile = await rpc('get_public_coach_profile', publishableKey, {
    target_handle: handle,
  });
  if (publishedProfile?.photo_reference !== privateAsset.id) {
    throw new Error('Public Coach profile tidak memproyeksikan opaque asset UUID.');
  }

  const gateway = await fetch(`${supabaseUrl}/functions/v1/public-coach-media/${privateAsset.id}`);
  if (gateway.status !== 200 || !gateway.headers.get('content-type')?.includes('image/jpeg')) {
    throw new Error(`Gateway Coach synthetic gagal dengan HTTP ${gateway.status}.`);
  }
  state.checks.opaqueCoachMedia = 'PASS';
  const directCoachStorage = await fetch(`${supabaseUrl}/storage/v1/object/public/coach-public-media/${encodedObjectPath(coachMediaPath)}`);
  if (directCoachStorage.status < 400) throw new Error('Direct Coach Storage tidak fail closed.');
  state.checks.directCoachStorageBlocked = 'PASS';

  await rest('profiles', 'PATCH', { coach_is_public: false }, `user_id=eq.${coach.id}`);
  const invalidatedGateway = await fetch(`${supabaseUrl}/functions/v1/public-coach-media/${privateAsset.id}`);
  if (invalidatedGateway.status !== 404) throw new Error(`Invalidasi gateway menghasilkan HTTP ${invalidatedGateway.status}.`);
  await rest('profiles', 'PATCH', { coach_is_public: true }, `user_id=eq.${coach.id}`);
  state.checks.coachPublicationInvalidation = 'PASS';

  const socialPage = await fetch(`${productionOrigin}/c/${handle}`);
  const socialHtml = await socialPage.text();
  if (socialPage.status !== 200 || !socialHtml.includes('Fixture Coach non-billable') || !socialHtml.includes('og:title')) {
    throw new Error(`Metadata sosial synthetic gagal dengan HTTP ${socialPage.status}.`);
  }
  state.checks.socialMetadata = 'PASS';

  const today = new Date();
  const tomorrow = new Date(today.getTime() + 86_400_000);
  const program = (await rest('programs', 'POST', {
    title: `NON-BILLABLE ${runId}`,
    summary: `Fixture synthetic non-billable ${runId}`,
    status: 'active',
    pace: 'scheduled',
    duration_mode: 'specific_dates',
    starts_on: today.toISOString().slice(0, 10),
    ends_on: tomorrow.toISOString().slice(0, 10),
    timezone: 'Asia/Jakarta',
    past_step_policy: 'available',
    future_step_policy: 'locked',
    wellness_disclaimer: 'Fixture synthetic; bukan saran medis.',
    points_per_activity: 0,
    points_per_weight_kg: 0,
    quiz_passing_percentage: 0,
    pricing_mode: 'free',
    desired_price: null,
    published_at: new Date().toISOString(),
    created_by: coach.id,
  }))[0];
  state.created.programId = program.id;
  const enrollment = (await rest('program_enrollments', 'POST', {
    program_id: program.id,
    participant_id: participant.id,
    coach_id: coach.id,
    status: 'active',
  }))[0];
  state.created.enrollmentId = enrollment.id;
  state.checks.nonBillableEnrollment = 'PASS';

  const destinationVersion = 1_000_000_000 + Math.floor(Math.random() * 900_000_000);
  const destinationId = randomUUID();
  const accountReference = `TEST-${runId}`.slice(0, 64);
  databaseQuery(`
    insert into public.payment_destinations(
      id, version, bank_code, bank_name, account_name, account_reference,
      instructions, effective_from, status, created_by
    ) values (
      ${sqlLiteral(destinationId)}::uuid,
      ${destinationVersion},
      'SYNTHETIC',
      'Synthetic test bank',
      'Synthetic non-billable',
      ${sqlLiteral(accountReference)},
      'Jangan melakukan transfer. Fixture synthetic non-billable.',
      statement_timestamp(),
      'retired',
      ${sqlLiteral(coach.id)}::uuid
    );
  `);
  state.created.paymentDestinationId = destinationId;
  const paymentOrderId = randomUUID();
  databaseQuery(`
    insert into public.payment_orders(
      id, owner_user_id, purpose, program_id, pending_enrollment_id,
      coach_user_id_snapshot, amount_minor, declared_method, destination_id,
      destination_version, bank_code_snapshot, bank_name_snapshot,
      account_name_snapshot, account_reference_snapshot, instructions_snapshot,
      timezone_snapshot, reserved_at, reservation_expires_at, status,
      idempotency_key
    ) values (
      ${sqlLiteral(paymentOrderId)}::uuid,
      ${sqlLiteral(participant.id)}::uuid,
      'program_enrollment',
      ${sqlLiteral(program.id)}::uuid,
      ${sqlLiteral(enrollment.id)}::uuid,
      ${sqlLiteral(coach.id)}::uuid,
      1,
      'bank_transfer',
      ${sqlLiteral(destinationId)}::uuid,
      ${destinationVersion},
      'SYNTHETIC',
      'Synthetic test bank',
      'Synthetic non-billable',
      ${sqlLiteral(accountReference)},
      'Jangan melakukan transfer. Fixture synthetic non-billable.',
      'Asia/Jakarta',
      statement_timestamp(),
      statement_timestamp() + interval '1 hour',
      'awaiting_evidence',
      ${sqlLiteral(`${runId}-order`.slice(0, 128))}
    );
  `);
  state.created.paymentOrderId = paymentOrderId;
  const attemptId = randomUUID();
  const evidencePath = `orders/${paymentOrderId}/attempts/${attemptId}/normalized.jpg`;
  databaseQuery(`
    insert into public.payment_evidence_attempts(
      id, order_id, attempt_number, upload_idempotency_key, object_path, status
    ) values (
      ${sqlLiteral(attemptId)}::uuid,
      ${sqlLiteral(paymentOrderId)}::uuid,
      1,
      ${sqlLiteral(`${runId}-evidence`.slice(0, 128))},
      ${sqlLiteral(evidencePath)},
      'prepared'
    );
  `);
  state.created.paymentAttemptId = attemptId;
  state.created.paymentEvidencePath = evidencePath;
  await request(`${supabaseUrl}/storage/v1/object/payment-evidence/${encodedObjectPath(evidencePath)}`, {
    method: 'POST',
    headers: serviceHeaders({
      'Content-Type': 'image/jpeg',
      'x-upsert': 'false',
    }),
    body: fixtureJpeg,
  }, [200, 201]);
  const directEvidence = await fetch(`${supabaseUrl}/storage/v1/object/public/payment-evidence/${encodedObjectPath(evidencePath)}`);
  if (directEvidence.status < 400) throw new Error('Direct payment Storage tidak fail closed.');
  const signed = await request(`${supabaseUrl}/storage/v1/object/sign/payment-evidence/${encodedObjectPath(evidencePath)}`, {
    method: 'POST',
    headers: serviceHeaders({ 'Content-Type': 'application/json' }),
    body: JSON.stringify({ expiresIn: 60 }),
  });
  const signedPath = signed.signedURL ?? signed.signedUrl;
  if (!signedPath) throw new Error('Signed URL payment fixture tidak dibuat.');
  const signedUrl = /^https?:\/\//iu.test(signedPath)
    ? signedPath
    : new URL(
      signedPath.startsWith('/storage/v1/')
        ? signedPath
        : `/storage/v1${signedPath.startsWith('/') ? '' : '/'}${signedPath}`,
      supabaseUrl,
    ).toString();
  const signedResponse = await fetch(signedUrl);
  if (signedResponse.status !== 200) throw new Error(`Signed URL payment fixture menghasilkan HTTP ${signedResponse.status}.`);
  databaseQuery(`
    update public.payment_orders
    set status = 'cancelled', updated_at = statement_timestamp()
    where id = ${sqlLiteral(paymentOrderId)}::uuid;
  `);
  state.checks.privatePaymentEvidence = 'PASS';
  state.checks.realTransfer = 'NOT_PERFORMED';
}

async function cleanup() {
  const cleanupSteps = [
    ['paymentEvidenceObject', () => removeObject('payment-evidence', state.created.paymentEvidencePath)],
    ['coachMediaObject', () => removeObject('coach-public-media', state.created.coachMediaPath)],
    ['paymentAttempt', () => databaseDelete('payment_evidence_attempts', state.created.paymentAttemptId)],
    ['paymentOrder', () => databaseDelete('payment_orders', state.created.paymentOrderId)],
    ['enrollment', () => deleteById('program_enrollments', state.created.enrollmentId)],
    ['program', () => deleteById('programs', state.created.programId)],
    ['paymentDestination', () => databaseDelete('payment_destinations', state.created.paymentDestinationId)],
    ['coachPublicProfile', () => deleteByColumn('coach_public_profiles', 'coach_user_id', state.created.coachUserId)],
    ['coachPublicDraft', () => deleteByColumn('coach_public_profile_drafts', 'coach_user_id', state.created.coachUserId)],
    ['coachEntitlement', () => deleteById('coach_access_entitlements', state.created.coachEntitlementId)],
    ['coachPaymentRecord', () => deleteById('coach_payment_records', state.created.coachPaymentRecordId)],
    ['coachApplication', () => deleteById('coach_applications', state.created.coachApplicationId)],
  ];
  for (const [name, action] of cleanupSteps) {
    try {
      await action();
      state.cleanup[name] = 'PASS';
    } catch {
      state.cleanup[name] = 'FAILED';
    }
  }
  for (const role of ['participant', 'coach']) {
    const userId = state.created[`${role}UserId`];
    if (!userId) continue;
    try {
      await request(`${supabaseUrl}/auth/v1/admin/users/${userId}?should_soft_delete=false`, {
        method: 'DELETE',
        headers: serviceHeaders(),
      }, [200, 204, 404]);
      state.cleanup[`${role}Identity`] = 'PASS';
    } catch {
      state.cleanup[`${role}Identity`] = 'FAILED';
    }
  }
}

async function verifyResiduals() {
  const checks = [
    ['programs', 'id', state.created.programId],
    ['program_enrollments', 'id', state.created.enrollmentId],
    ['payment_orders', 'id', state.created.paymentOrderId],
    ['payment_evidence_attempts', 'id', state.created.paymentAttemptId],
    ['coach_public_profiles', 'coach_user_id', state.created.coachUserId],
    ['coach_access_entitlements', 'id', state.created.coachEntitlementId],
    ['profiles', 'user_id', state.created.participantUserId],
    ['profiles', 'user_id', state.created.coachUserId],
  ];
  const databaseOnlyTables = new Set([
    'payment_destinations',
    'payment_evidence_attempts',
    'payment_orders',
  ]);
  for (const [table, column, value] of checks) {
    if (!value) continue;
    if (databaseOnlyTables.has(table)) {
      const rows = databaseQuery(`
        select count(*)::integer as count from public.${table}
        where ${column} = ${sqlLiteral(value)}::uuid;
      `);
      state.residual[`${table}.${column}`] = rows[0]?.count ?? -1;
    } else {
      state.residual[`${table}.${column}`] = await residualCount(table, column, value);
    }
  }
  if (state.created.coachAssetId) {
    const privateRows = databaseQuery(`
      select count(*)::integer as count
      from private.coach_public_media_assets
      where id = ${sqlLiteral(state.created.coachAssetId)}::uuid;
    `);
    state.residual['private.coach_public_media_assets.id'] = privateRows[0]?.count ?? -1;
  }
  for (const role of ['participant', 'coach']) {
    const userId = state.created[`${role}UserId`];
    if (!userId) continue;
    const response = await fetch(`${supabaseUrl}/auth/v1/admin/users/${userId}`, {
      headers: serviceHeaders(),
    });
    state.residual[`auth.users.${role}`] = response.status === 404 ? 0 : 1;
  }
  const nonzero = Object.values(state.residual).some((count) => count !== 0);
  state.checks.zeroResidualPublicRows = nonzero ? 'FAIL' : 'PASS';
}

let runError;
try {
  await run();
  state.status = 'SMOKE_PASS_CLEANUP_PENDING';
} catch (error) {
  runError = error;
  state.status = 'SMOKE_FAIL_CLEANUP_PENDING';
  state.error = error instanceof Error ? error.message : 'Kesalahan synthetic smoke.';
} finally {
  await cleanup();
  await verifyResiduals();
  const cleanupFailed = Object.values(state.cleanup).includes('FAILED')
    || Object.values(state.residual).some((count) => count !== 0);
  state.status = runError || cleanupFailed ? 'FAIL' : 'PASS';
  await persistManifest();
}

console.log(JSON.stringify({
  status: state.status,
  runId: state.runId,
  checks: state.checks,
  cleanup: state.cleanup,
  residual: state.residual,
  manifest: manifestPath.pathname,
}, null, 2));

if (state.status !== 'PASS') process.exitCode = 1;
