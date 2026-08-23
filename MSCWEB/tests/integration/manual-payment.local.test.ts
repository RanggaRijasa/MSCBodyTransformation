import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { createHash, randomUUID } from 'node:crypto';
import { expect, it } from 'vitest';
import { paymentOrderSchema } from '../../src/features/payment/payment-models';

const localUrl = process.env.API_URL;
const publishableKey = process.env.PUBLISHABLE_KEY ?? process.env.ANON_KEY;
const secretKey = process.env.SECRET_KEY ?? process.env.SERVICE_ROLE_KEY;
const canRun = localUrl !== undefined && publishableKey !== undefined && secretKey !== undefined;
const jpeg = Buffer.from('/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////2wBDAf//////////////////////////////////////////////////////////////////////////////////////wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAX/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIQAxAAAAF//8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABBQJ//8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAgBAwEBPwF//8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAgBAgEBPwF//8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQAGPwJ//8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPyF//9oADAMBAAIAAwAAABD/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oACAEDAQE/EB//xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oACAECAQE/EB//xAAUEAEAAAAAAAAAAAAAAAAAAAAA/9oACAEBAAE/EB//2Q==', 'base64');

it.runIf(canRun)('enforces free and paid W05 enrollment, private evidence, atomic approval, and concurrent decisions locally', async () => {
  const url = new URL(localUrl as string);
  expect(['127.0.0.1', 'localhost']).toContain(url.hostname);
  const service = createClient(localUrl as string, secretKey as string, { auth: { persistSession: false, autoRefreshToken: false } });
  const suffix = randomUUID();
  const paidProgramId = randomUUID();
  const freeProgramId = randomUUID();
  const fullProgramId = randomUUID();
  const inactiveProgramId = randomUUID();
  const retentionProgramId = randomUUID();
  const qrisPath = `destinations/${suffix}/qris.jpg`;
  const users: string[] = [];
  const coachApplicationIds: string[] = [];
  const orderIds: string[] = [];
  const objectPaths: string[] = [];

  try {
    const [adminA, adminB, participantA, participantB, coachA, coachB] = await Promise.all([
      createIdentity(service, `w05-admin-a-${suffix}@test.invalid`, `W05-A-${suffix}!`, users),
      createIdentity(service, `w05-admin-b-${suffix}@test.invalid`, `W05-B-${suffix}!`, users),
      createIdentity(service, `w05-participant-a-${suffix}@test.invalid`, `W05-C-${suffix}!`, users),
      createIdentity(service, `w05-participant-b-${suffix}@test.invalid`, `W05-D-${suffix}!`, users),
      createIdentity(service, `w05-coach-a-${suffix}@test.invalid`, `W05-E-${suffix}!`, users),
      createIdentity(service, `w05-coach-b-${suffix}@test.invalid`, `W05-F-${suffix}!`, users),
    ]);
    expect((await service.from('profiles').update({ role: 'admin', display_name: 'Admin W05 A', onboarding_status: 'active', provisional_expires_at: null, finalized_at: new Date().toISOString() }).eq('user_id', adminA.id)).error).toBeNull();
    expect((await service.from('profiles').update({ role: 'admin', display_name: 'Admin W05 B', onboarding_status: 'active', provisional_expires_at: null, finalized_at: new Date().toISOString() }).eq('user_id', adminB.id)).error).toBeNull();
    for (const [participant, name] of [[participantA, 'Peserta W05 A'], [participantB, 'Peserta W05 B']] as const) {
      expect((await service.from('profiles').update({ role: 'participant', display_name: name, onboarding_status: 'active', provisional_expires_at: null, finalized_at: new Date().toISOString() }).eq('user_id', participant.id)).error).toBeNull();
    }

    const coachQr = `w05-coach-a-${suffix}`;
    const otherCoachQr = `w05-coach-b-${suffix}`;
    coachApplicationIds.push(
      await activateCoachFixture(service, coachA.id, adminA.id, 'Coach W05 A', coachQr),
      await activateCoachFixture(service, coachB.id, adminA.id, 'Coach W05 B', otherCoachQr),
    );
    const coachId = coachA.id;
    expect(coachId).toBeTruthy();
    expect(coachQr.length).toBeGreaterThanOrEqual(16);

    expect((await service.from('programs').insert([
      programFixture(paidProgramId, 'Program berbayar W05', 'paid', adminA.id),
      programFixture(freeProgramId, 'Program gratis W05', 'free', adminA.id),
      { ...programFixture(fullProgramId, 'Program penuh W05', 'paid', adminA.id), participant_limit: 1 },
      { ...programFixture(inactiveProgramId, 'Program nonaktif W05', 'paid', adminA.id), status: 'draft', published_at: null },
      programFixture(retentionProgramId, 'Program retensi W08', 'paid', adminA.id),
    ])).error).toBeNull();
    expect((await service.storage.from('payment-destination-assets').upload(qrisPath, jpeg, { contentType: 'image/jpeg', upsert: false })).error).toBeNull();

    const [adminClientA, adminClientB, clientA, clientB] = await Promise.all([
      signIn(localUrl as string, publishableKey as string, adminA.email, adminA.password),
      signIn(localUrl as string, publishableKey as string, adminB.email, adminB.password),
      signIn(localUrl as string, publishableKey as string, participantA.email, participantA.password),
      signIn(localUrl as string, publishableKey as string, participantB.email, participantB.password),
    ]);
    const destination = await adminClientA.rpc('create_payment_destination', {
      destination_bank_code: 'TST', destination_bank_name: 'Bank Uji Tidak Dapat Dibayar', destination_account_name: 'FIXTURE W05', destination_account_reference: '0000000000', destination_instructions: 'Jangan melakukan pembayaran nyata ke data pengujian ini.', effective_at: new Date().toISOString(), destination_qris_object_path: qrisPath,
    });
    expect(destination.error).toBeNull();

    expect((await clientA.rpc('resolve_coach_qr_for_enrollment', { scanned_coach_qr: 'tidak-valid' })).error?.message).toContain('coach_qr_invalid');
    expect((await clientA.rpc('resolve_coach_qr_for_enrollment', { scanned_coach_qr: coachQr })).error).toBeNull();

    const firstFree = await clientA.rpc('enroll_free_program', { target_program_id: freeProgramId, scanned_coach_qr: coachQr });
    const secondFree = await clientA.rpc('enroll_free_program', { target_program_id: freeProgramId, scanned_coach_qr: coachQr });
    expect(firstFree.error).toBeNull();
    expect(secondFree.error).toBeNull();
    expect((await service.from('program_enrollments').select('id', { count: 'exact' }).eq('program_id', freeProgramId).eq('participant_id', participantA.id)).count).toBe(1);
    expect((await clientA.rpc('resolve_coach_qr_for_enrollment', { scanned_coach_qr: otherCoachQr })).error?.message).toContain('coach_mismatch');
    expect((await service.from('program_enrollments').insert({ program_id: fullProgramId, participant_id: participantA.id, coach_id: coachId, status: 'active' })).error).toBeNull();
    expect((await clientB.rpc('create_program_payment_order', { target_program_id: fullProgramId, coach_qr_payload: coachQr, payment_method: 'bank_transfer', request_idempotency_key: `w05-full-${suffix}` })).error?.message).toContain('program_full');
    expect((await clientB.rpc('create_program_payment_order', { target_program_id: inactiveProgramId, coach_qr_payload: coachQr, payment_method: 'bank_transfer', request_idempotency_key: `w05-inactive-${suffix}` })).error?.message).toContain('program_unavailable');

    const idempotency = `w05-order-${suffix}`;
    const firstOrder = await clientA.rpc('create_program_payment_order', { target_program_id: paidProgramId, coach_qr_payload: coachQr, payment_method: 'bank_transfer', request_idempotency_key: idempotency });
    const secondOrder = await clientA.rpc('create_program_payment_order', { target_program_id: paidProgramId, coach_qr_payload: coachQr, payment_method: 'bank_transfer', request_idempotency_key: idempotency });
    expect(firstOrder.error).toBeNull();
    expect(secondOrder.error).toBeNull();
    const orderA = row(firstOrder.data) as { id: string; pending_enrollment_id: string; version: number; amount_minor: number; status: string };
    orderIds.push(orderA.id);
    expect(row(secondOrder.data).id).toBe(orderA.id);
    expect(orderA.status).toBe('awaiting_evidence');
    expect((await service.from('program_enrollments').select('status').eq('id', orderA.pending_enrollment_id).single()).data?.status).toBe('waiting_for_payment');
    expect((await clientB.from('payment_orders').select('id').eq('id', orderA.id)).data).toEqual([]);

    const submittedA = await prepareUploadSubmit(clientA, orderA.id, `w05-upload-a-${suffix}`, jpeg, objectPaths);
    expect(submittedA.status).toBe('under_review');
    expect((await clientB.from('payment_evidence_attempts').select('id').eq('order_id', orderA.id)).data).toEqual([]);
    expect((await clientB.storage.from('payment-evidence').download(objectPaths[0] as string)).error).not.toBeNull();
    expect((await adminClientA.storage.from('payment-evidence').download(objectPaths[0] as string)).error).toBeNull();
    const adminQueue = await adminClientA.from('payment_orders').select('id,owner_user_id,purpose,program_id,pending_enrollment_id,coach_user_id_snapshot,amount_minor,currency,declared_method,destination_version,bank_code_snapshot,bank_name_snapshot,account_name_snapshot,account_reference_snapshot,qris_object_path_snapshot,instructions_snapshot,reservation_expires_at,evidence_submitted_at,correction_expires_at,status,latest_rejection_reason,version,created_at,updated_at').eq('purpose', 'program_enrollment');
    expect(adminQueue.error).toBeNull();
    expect(paymentOrderSchema.safeParse(adminQueue.data?.find((value) => value.id === orderA.id)).success).toBe(true);

    const approved = await adminClientA.rpc('approve_payment_order', { target_order_id: orderA.id, expected_version: submittedA.version, reconciled_amount_minor: orderA.amount_minor, reconciliation_reference: `REC-${suffix.slice(0, 8)}`, destination_matches: true });
    expect(approved.error).toBeNull();
    expect(row(approved.data).status).toBe('approved');
    const [enrollment, entitlement, transaction, ledger, audit] = await Promise.all([
      service.from('program_enrollments').select('status').eq('id', orderA.pending_enrollment_id).single(),
      service.from('program_entitlements').select('id').eq('program_id', paidProgramId).eq('participant_id', participantA.id),
      service.from('commerce_transactions').select('id,platform,provider,status').eq('program_id', paidProgramId).eq('participant_id', participantA.id),
      service.from('payment_ledger').select('id').eq('order_id', orderA.id),
      service.from('audit_events').select('id').eq('subject_id', orderA.id).eq('kind', 'manual_payment_approved'),
    ]);
    expect(enrollment.data?.status).toBe('active');
    expect(entitlement.data).toHaveLength(1);
    expect(transaction.data).toEqual([expect.objectContaining({ platform: 'web', provider: 'manual_transfer', status: 'verified' })]);
    expect(ledger.data).toHaveLength(1);
    expect(audit.data).toHaveLength(1);

    expect((await clientA.rpc('create_program_payment_order', { target_program_id: paidProgramId, coach_qr_payload: coachQr, payment_method: 'bank_transfer', request_idempotency_key: `w05-duplicate-${suffix}` })).error?.message).toContain('already_enrolled');

    const retentionOrderResponse = await clientB.rpc('create_program_payment_order', {
      target_program_id: retentionProgramId,
      coach_qr_payload: coachQr,
      payment_method: 'bank_transfer',
      request_idempotency_key: `w08-retention-${suffix}`,
    });
    expect(retentionOrderResponse.error).toBeNull();
    const retentionOrder = row(retentionOrderResponse.data) as { id: string };
    orderIds.push(retentionOrder.id);
    const retentionPrepare = await clientB.rpc('prepare_payment_evidence_attempt', {
      target_order_id: retentionOrder.id,
      request_idempotency_key: `w08-retention-upload-${suffix}`,
    });
    expect(retentionPrepare.error).toBeNull();
    const retentionAttempt = row(retentionPrepare.data) as { id: string; object_path: string };
    objectPaths.push(retentionAttempt.object_path);
    expect((await clientB.storage.from('payment-evidence').upload(
      retentionAttempt.object_path,
      jpeg,
      { contentType: 'image/jpeg', upsert: false },
    )).error).toBeNull();
    const oldSubmittedAt = new Date(Date.now() - 31 * 86_400_000).toISOString();
    expect((await service.from('payment_evidence_attempts').update({
      status: 'approved',
      submitted_at: oldSubmittedAt,
      reviewed_at: oldSubmittedAt,
      reviewed_by: adminA.id,
      mime_type: 'image/jpeg',
      byte_size: jpeg.byteLength,
      pixel_width: 1,
      pixel_height: 1,
      sha256_hex: createHash('sha256').update(jpeg).digest('hex'),
    }).eq('id', retentionAttempt.id)).error).toBeNull();
    expect((await service.from('payment_orders').update({ status: 'approved' })
      .eq('id', retentionOrder.id)).error).toBeNull();

    const retentionCandidates = await service.rpc('list_payment_evidence_retention_candidates', {
      batch_size: 100,
      dry_run: true,
    });
    expect(retentionCandidates.error).toBeNull();
    expect(retentionCandidates.data).toContainEqual(expect.objectContaining({
      attempt_id: retentionAttempt.id,
      object_name: retentionAttempt.object_path,
      is_dry_run: true,
    }));
    expect((await service.from('payment_orders').update({ status: 'under_review' })
      .eq('id', retentionOrder.id)).error).toBeNull();
    expect((await service.rpc('list_payment_evidence_retention_candidates', {
      batch_size: 100,
      dry_run: true,
    })).data).not.toContainEqual(expect.objectContaining({ attempt_id: retentionAttempt.id }));
    expect((await service.from('payment_orders').update({ status: 'approved' })
      .eq('id', retentionOrder.id)).error).toBeNull();

    const firstRetentionClaim = await service.rpc('claim_payment_evidence_retention', {
      target_attempt_id: retentionAttempt.id,
    });
    expect(firstRetentionClaim.error).toBeNull();
    expect(firstRetentionClaim.data).toBe(true);
    const releasedRetentionClaim = await service.rpc('release_payment_evidence_retention', {
      target_attempt_id: retentionAttempt.id,
    });
    expect(releasedRetentionClaim.error).toBeNull();
    expect(releasedRetentionClaim.data).toBe(true);
    const finalRetentionClaim = await service.rpc('claim_payment_evidence_retention', {
      target_attempt_id: retentionAttempt.id,
    });
    expect(finalRetentionClaim.error).toBeNull();
    expect(finalRetentionClaim.data).toBe(true);
    expect((await service.storage.from('payment-evidence').remove([
      retentionAttempt.object_path,
    ])).error).toBeNull();
    const completedRetention = await service.rpc('complete_payment_evidence_retention', {
      target_attempt_id: retentionAttempt.id,
    });
    expect(completedRetention.error).toBeNull();
    expect(completedRetention.data).toBe(true);
    expect((await service.from('payment_evidence_attempts').select('status,deleted_at')
      .eq('id', retentionAttempt.id).single()).data).toEqual(
        expect.objectContaining({ status: 'deleted', deleted_at: expect.any(String) }),
      );

    const raceOrderResponse = await clientB.rpc('create_program_payment_order', { target_program_id: paidProgramId, coach_qr_payload: coachQr, payment_method: 'static_qris', request_idempotency_key: `w05-race-${suffix}` });
    expect(raceOrderResponse.error).toBeNull();
    const raceOrder = row(raceOrderResponse.data) as { id: string; version: number; amount_minor: number };
    orderIds.push(raceOrder.id);
    const submittedRace = await prepareUploadSubmit(clientB, raceOrder.id, `w05-upload-b-${suffix}`, jpeg, objectPaths);
    const race = await Promise.all([
      adminClientA.rpc('approve_payment_order', { target_order_id: raceOrder.id, expected_version: submittedRace.version, reconciled_amount_minor: raceOrder.amount_minor, reconciliation_reference: `RACE-${suffix.slice(0, 8)}`, destination_matches: true }),
      adminClientB.rpc('reject_payment_evidence', { target_order_id: raceOrder.id, expected_version: submittedRace.version, rejection_reason: 'Bukti tidak cocok dengan catatan uji.' }),
    ]);
    expect(race.filter((result) => result.error === null)).toHaveLength(1);
    expect(race.filter((result) => result.error !== null)).toHaveLength(1);
    const raceState = await service.from('payment_orders').select('status,version').eq('id', raceOrder.id).single();
    expect(['approved', 'correction_required']).toContain(raceState.data?.status);
    expect(raceState.data?.version).toBe(submittedRace.version + 1);
  } finally {
    if (orderIds.length) {
      await service.from('audit_events').delete().in('subject_id', orderIds);
      await service.from('payment_ledger').delete().in('order_id', orderIds);
      await service.from('payment_events').delete().in('order_id', orderIds);
      await service.from('payment_evidence_attempts').delete().in('order_id', orderIds);
      await service.from('program_entitlements').delete().in('program_id', [paidProgramId, freeProgramId, fullProgramId, inactiveProgramId, retentionProgramId]);
      await service.from('commerce_transactions').delete().in('program_id', [paidProgramId, freeProgramId, fullProgramId, inactiveProgramId, retentionProgramId]);
      await service.from('payment_orders').delete().in('id', orderIds);
    }
    if (objectPaths.length) await service.storage.from('payment-evidence').remove(objectPaths);
    await service.from('program_enrollments').delete().in('program_id', [paidProgramId, freeProgramId, fullProgramId, inactiveProgramId, retentionProgramId]);
    await service.from('programs').delete().in('id', [paidProgramId, freeProgramId, fullProgramId, inactiveProgramId, retentionProgramId]);
    await service.from('payment_destinations').delete().eq('account_name', 'FIXTURE W05');
    await service.storage.from('payment-destination-assets').remove([qrisPath]);
    if (coachApplicationIds.length) {
      await service.from('coach_access_entitlements').delete().in('application_id', coachApplicationIds);
      await service.from('coach_payment_records').delete().in('application_id', coachApplicationIds);
      await service.from('coach_applications').delete().in('id', coachApplicationIds);
    }
    for (const userId of users) await service.auth.admin.deleteUser(userId);
  }
});

async function createIdentity(service: SupabaseClient, email: string, password: string, users: string[]) {
  const response = await service.auth.admin.createUser({ email, password, email_confirm: true });
  expect(response.error).toBeNull();
  expect(response.data.user).not.toBeNull();
  users.push(response.data.user?.id as string);
  return { id: response.data.user?.id as string, email, password };
}

async function signIn(url: string, key: string, email: string, password: string) {
  const client = createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } });
  expect((await client.auth.signInWithPassword({ email, password })).error).toBeNull();
  return client;
}

async function activateCoachFixture(
  service: SupabaseClient,
  coachId: string,
  adminId: string,
  displayName: string,
  coachQr: string,
) {
  const applicationId = randomUUID();
  const paymentRecordId = randomUUID();
  expect((await service.from('profiles').update({
    role: 'coach',
    display_name: displayName,
    coach_qr_identifier: coachQr,
    coach_is_approved: true,
    coach_is_public: true,
    onboarding_status: 'active',
    provisional_expires_at: null,
    finalized_at: new Date().toISOString(),
  }).eq('user_id', coachId)).error).toBeNull();
  expect((await service.from('coach_applications').insert({
    id: applicationId,
    applicant_user_id: coachId,
    participant_profile_id: coachId,
    display_name_snapshot: displayName,
    phone_number_snapshot: '+6281200000505',
    member_level_snapshot: 'sc',
    has_completed_hom_sts: true,
    has_completed_ict: true,
    terms_version: 'w05-test-v1',
    status: 'active',
    draft_idempotency_key: `w05-coach-${applicationId}`,
    submitted_at: new Date().toISOString(),
    decided_at: new Date().toISOString(),
    decided_by: adminId,
  })).error).toBeNull();
  expect((await service.from('coach_payment_records').insert({
    id: paymentRecordId,
    application_id: applicationId,
    state: 'verified',
    price_band: 'entry',
    amount_minor_units: 100_000,
    provider_reference: `w05-payment-${paymentRecordId}`,
    verified_at: new Date().toISOString(),
  })).error).toBeNull();
  expect((await service.from('coach_access_entitlements').insert({
    application_id: applicationId,
    payment_record_id: paymentRecordId,
    coach_user_id: coachId,
    status: 'active',
    starts_at: new Date(Date.now() - 60_000).toISOString(),
    ends_at: new Date(Date.now() + 30 * 86_400_000).toISOString(),
  })).error).toBeNull();
  return applicationId;
}

async function prepareUploadSubmit(client: SupabaseClient, orderId: string, idempotencyKey: string, body: Buffer, paths: string[]) {
  const prepare = await client.rpc('prepare_payment_evidence_attempt', { target_order_id: orderId, request_idempotency_key: idempotencyKey });
  expect(prepare.error).toBeNull();
  const attempt = row(prepare.data) as { id: string; object_path: string };
  paths.push(attempt.object_path);
  expect((await client.storage.from('payment-evidence').upload(attempt.object_path, body, { contentType: 'image/jpeg', upsert: false })).error).toBeNull();
  const hash = createHash('sha256').update(body).digest('hex');
  const submit = await client.rpc('submit_payment_evidence', { target_attempt_id: attempt.id, content_sha256_hex: hash, content_byte_size: body.byteLength, content_pixel_width: 1, content_pixel_height: 1 });
  expect(submit.error).toBeNull();
  return row(submit.data) as { status: string; version: number };
}

function row(value: unknown): Record<string, unknown> {
  return (Array.isArray(value) ? value[0] : value) as Record<string, unknown>;
}

function programFixture(id: string, title: string, pricing: 'free' | 'paid', adminId: string) {
  return { id, title, summary: 'Fixture lokal W05 yang tidak dapat dibayar.', status: 'active', pace: 'scheduled', duration_mode: 'specific_dates', starts_on: localDate(-1), ends_on: localDate(5), timezone: 'Asia/Makassar', past_step_policy: 'read_only', future_step_policy: 'locked', wellness_disclaimer: 'Program wellness non-diagnostik.', points_per_activity: 10, points_per_weight_kg: 100, quiz_passing_percentage: 70, pricing_mode: pricing, desired_price: pricing === 'paid' ? 125_000 : null, participant_limit: 20, published_at: new Date().toISOString(), created_by: adminId };
}

function localDate(offset: number) {
  return new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Makassar', year: 'numeric', month: '2-digit', day: '2-digit' }).format(new Date(Date.now() + offset * 86_400_000));
}
