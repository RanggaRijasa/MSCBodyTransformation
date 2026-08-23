import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { createHash, randomUUID } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { expect, it } from 'vitest';

const localUrl = process.env.API_URL;
const publishableKey = process.env.PUBLISHABLE_KEY ?? process.env.ANON_KEY;
const secretKey = process.env.SECRET_KEY ?? process.env.SERVICE_ROLE_KEY;
const canRun = localUrl !== undefined && publishableKey !== undefined && secretKey !== undefined;
const jpeg = Buffer.from(
  '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////2wBDAf//////////////////////////////////////////////////////////////////////////////////////wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAX/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIQAxAAAAF//8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABBQJ//8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAgBAwEBPwF//8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAgBAgEBPwF//8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQAGPwJ//8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPyF//9oADAMBAAIAAwAAABD/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oACAEDAQE/EB//xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oACAECAQE/EB//xAAUEAEAAAAAAAAAAAAAAAAAAAAA/9oACAEBAAE/EB//2Q==',
  'base64',
);

it.runIf(canRun)(
  'enforces W07.4 provisional onboarding, Coach proof activation, correction history, and cancellation locally',
  async () => {
    expect(['127.0.0.1', 'localhost']).toContain(new URL(localUrl as string).hostname);
    const service = createClient(localUrl as string, secretKey as string, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const suffix = randomUUID();
    const identities: Identity[] = [];
    const applicationIds: string[] = [];
    const orderIds: string[] = [];
    const objectPaths: string[] = [];
    const destinationId = randomUUID();

    try {
      const [admin, coach, participant, coachApplicant, cancellationApplicant, expiredRelationship] = await Promise.all([
        createIdentity(service, `w074-admin-${suffix}`, identities),
        createIdentity(service, `w074-coach-${suffix}`, identities),
        createIdentity(service, `w074-participant-${suffix}`, identities, {
          full_name: 'Peserta Bootstrap W074',
          avatar_url: 'https://example.invalid/avatar-w074.jpg',
          role: 'admin',
          onboarding_status: 'active',
        }),
        createIdentity(service, `w074-applicant-${suffix}`, identities),
        createIdentity(service, `w074-cancel-${suffix}`, identities),
        createIdentity(service, `w074-expired-related-${suffix}`, identities),
      ]);
      const coachQr = `w074-${randomUUID()}`;
      await activateAdmin(service, admin.id);
      await activateCoach(service, coach.id, admin.id, coachQr, applicationIds);
      expect((await service.from('payment_destinations').insert({
        id: destinationId,
        version: 704,
        bank_code: 'TST',
        bank_name: 'Bank Uji Tidak Dapat Dibayar',
        account_name: 'FIXTURE W07.4',
        account_reference: '0000000000',
        effective_from: new Date(Date.now() - 60_000).toISOString(),
        status: 'active',
        created_by: admin.id,
        instructions: 'Jangan melakukan pembayaran nyata ke data pengujian ini.',
      })).error).toBeNull();
      const [adminClient, participantClient, coachApplicantClient, cancellationClient] = await Promise.all([
        signIn(admin),
        signIn(participant),
        signIn(coachApplicant),
        signIn(cancellationApplicant),
      ]);

      const bootstrap = await service
        .from('profiles')
        .select('role,display_name,provider_avatar_url,account_purpose,onboarding_status,provisional_expires_at,finalized_at,onboarding_version')
        .eq('user_id', participant.id)
        .single();
      expect(bootstrap.error).toBeNull();
      expect(bootstrap.data).toEqual(expect.objectContaining({
        role: 'participant',
        display_name: 'Peserta Bootstrap W074',
        provider_avatar_url: 'https://example.invalid/avatar-w074.jpg',
        account_purpose: 'participant',
        onboarding_status: 'provisional',
        finalized_at: null,
        onboarding_version: 1,
      }));
      expect(new Date(bootstrap.data!.provisional_expires_at as string).getTime()).toBeGreaterThan(Date.now());

      const initialContext = await participantClient.rpc('get_my_session_context');
      expect(initialContext.error).toBeNull();
      expect(row(initialContext.data)).toEqual(expect.objectContaining({
        user_id: participant.id,
        role: 'participant',
        onboarding_status: 'provisional',
        account_purpose: 'participant',
        profile_complete: false,
        onboarding_version: 1,
        resume_step: 'profile',
      }));
      expect(JSON.stringify(initialContext.data)).not.toMatch(/phone|avatar|coach_qr|payment/i);

      expect((await participantClient.from('profiles').select('user_id').eq('user_id', participant.id)).data).toEqual([]);
      await expectRpcError(participantClient.rpc('get_my_dashboard_summary'), 'active_account_required');
      await expectRpcError(participantClient.rpc('enroll_free_program', {
        target_program_id: randomUUID(),
        scanned_coach_qr: coachQr,
      }), 'active_account_required');
      await expectRpcError(participantClient.rpc('update_my_profile', {
        new_display_name: 'Tidak boleh aktif',
        new_phone_number: '+6281234567001',
        new_member_level: 'sc',
        new_account_purpose: 'participant',
      }), 'active_account_required');
      await expectRpcError(participantClient.rpc('resolve_coach_qr_for_enrollment', {
        scanned_coach_qr: coachQr,
      }), 'active_account_required');
      await expectRpcError(participantClient.rpc('prepare_my_account_deletion'), 'active_account_required');
      await expectRpcError(participantClient.rpc('finalize_my_account_deletion'), 'active_account_required');
      await expectRpcError(participantClient.rpc('cancel_payment_order', {
        target_order_id: randomUUID(),
      }), 'active_account_required');

      const savedParticipant = await saveProvisionalProfile(
        participantClient,
        '  Peserta W074  ',
        '+62 812-3456-7001',
        'sc',
        'participant',
        1,
      );
      expect(savedParticipant).toEqual(expect.objectContaining({
        display_name: 'Peserta W074',
        phone_number: '+6281234567001',
        member_level: 'sc',
        account_purpose: 'participant',
        onboarding_version: 2,
      }));
      await expectRpcError(participantClient.rpc('save_my_provisional_onboarding_profile', {
        new_display_name: 'Peserta konflik',
        new_phone_number: '+6281234567001',
        new_member_level: 'sc',
        new_account_purpose: 'participant',
        expected_version: 1,
      }), 'version_conflict');

      expect((await service.from('profiles').update({ coach_is_public: false }).eq('user_id', coach.id)).error).toBeNull();
      await expectRpcError(participantClient.rpc('validate_participant_onboarding_coach_qr', {
        coach_qr: coachQr,
      }), 'coach_qr_invalid');
      expect((await service.from('profiles').update({ coach_is_public: true }).eq('user_id', coach.id)).error).toBeNull();
      const validatedCoach = await participantClient.rpc('validate_participant_onboarding_coach_qr', {
        coach_qr: coachQr,
      });
      expect(validatedCoach.error).toBeNull();
      expect(row(validatedCoach.data)).toEqual(expect.objectContaining({
        coach_id: coach.id,
        display_name: 'Coach W074',
      }));
      expect(JSON.stringify(validatedCoach.data)).not.toContain(coachQr);

      const finalized = await participantClient.rpc('finalize_participant_onboarding', {
        coach_qr: coachQr,
        expected_version: 2,
      });
      expect(finalized.error).toBeNull();
      expect(row(finalized.data)).toEqual(expect.objectContaining({
        user_id: participant.id,
        role: 'participant',
        onboarding_status: 'active',
        current_coach_id: coach.id,
        provisional_expires_at: null,
      }));
      const repeatedFinalization = await participantClient.rpc('finalize_participant_onboarding', {
        coach_qr: coachQr,
        expected_version: 2,
      });
      expect(repeatedFinalization.error).toBeNull();
      expect(row(repeatedFinalization.data).user_id).toBe(participant.id);
      expect((await participantClient.rpc('get_my_dashboard_summary')).error).toBeNull();
      expect((await participantClient.rpc('update_my_profile', {
        new_display_name: 'Peserta W074 aktif',
        new_phone_number: '+6281234567002',
        new_member_level: 'sc',
        new_account_purpose: 'participant',
      })).error).toBeNull();

      const coachFlow = await prepareCoachOnboarding(
        coachApplicantClient,
        suffix,
        'applicant',
        applicationIds,
        orderIds,
      );
      expect(coachFlow.order.amount_minor).toBe(100_000);
      const firstProof = await prepareAndUploadProof(
        coachApplicantClient,
        coachFlow.order.id,
        `w074-proof-${suffix}`,
        objectPaths,
      );
      await expectRpcError(coachApplicantClient.rpc('submit_payment_evidence', proofPayload(firstProof.id)), 'provisional_generic_payment_submit_denied');
      expect((await service.from('profiles').select('onboarding_status').eq('user_id', coachApplicant.id).single()).data?.onboarding_status).toBe('coach_handoff_pending');

      const atomicSubmission = await coachApplicantClient.rpc(
        'submit_coach_onboarding_payment_evidence',
        proofPayload(firstProof.id),
      );
      expect(atomicSubmission.error).toBeNull();
      const firstSubmittedOrder = row(atomicSubmission.data);
      expect(firstSubmittedOrder).toEqual(expect.objectContaining({ id: coachFlow.order.id, status: 'under_review' }));
      expect((await coachApplicantClient.rpc('submit_coach_onboarding_payment_evidence', proofPayload(firstProof.id))).error).toBeNull();
      expect((await service.from('profiles').select('role,onboarding_status,finalized_at').eq('user_id', coachApplicant.id).single()).data)
        .toEqual(expect.objectContaining({ role: 'participant', onboarding_status: 'active' }));
      expect((await coachApplicantClient.rpc('request_my_provisional_cancellation', {
        request_idempotency_key: `w074-retain-${suffix}`,
      })).data).toEqual({ status: 'retained' });

      const correction = await adminClient.rpc('request_coach_payment_correction', {
        target_order_id: coachFlow.order.id,
        expected_version: firstSubmittedOrder.version,
        correction_reason: 'Foto bukti belum memperlihatkan tujuan transfer dengan jelas.',
        request_idempotency_key: `w074-correction-${suffix}`,
      });
      expect(correction.error).toBeNull();
      expect(row(correction.data)).toEqual(expect.objectContaining({
        id: coachFlow.order.id,
        coach_application_id: coachFlow.application.id,
        status: 'correction_required',
      }));
      const secondProof = await prepareAndUploadProof(
        coachApplicantClient,
        coachFlow.order.id,
        `w074-proof-correction-${suffix}`,
        objectPaths,
      );
      expect(secondProof.attempt_number).toBe(2);
      const correctedSubmission = await coachApplicantClient.rpc(
        'submit_coach_onboarding_payment_evidence',
        proofPayload(secondProof.id),
      );
      expect(correctedSubmission.error).toBeNull();
      const correctedOrder = row(correctedSubmission.data);
      expect(correctedOrder).toEqual(expect.objectContaining({
        id: coachFlow.order.id,
        coach_application_id: coachFlow.application.id,
        status: 'under_review',
      }));
      const attempts = await service.from('payment_evidence_attempts')
        .select('id,attempt_number,status')
        .eq('order_id', coachFlow.order.id)
        .order('attempt_number');
      expect(attempts.error).toBeNull();
      expect(attempts.data).toEqual([
        expect.objectContaining({ id: firstProof.id, attempt_number: 1, status: 'rejected' }),
        expect.objectContaining({ id: secondProof.id, attempt_number: 2, status: 'submitted' }),
      ]);

      const rejected = await adminClient.rpc('reject_coach_application_and_payment', {
        target_order_id: coachFlow.order.id,
        expected_version: correctedOrder.version,
        rejection_reason: 'Pengajuan tidak dapat dilanjutkan setelah pemeriksaan akhir.',
        request_idempotency_key: `w074-terminal-reject-${suffix}`,
      });
      expect(rejected.error).toBeNull();
      expect(row(rejected.data).order).toEqual(expect.objectContaining({ id: coachFlow.order.id, status: 'rejected' }));
      expect(row(rejected.data).application).toEqual(expect.objectContaining({ id: coachFlow.application.id, status: 'rejected' }));
      const reapplication = await createActiveParticipantReapplication(
        coachApplicantClient,
        suffix,
        applicationIds,
        orderIds,
      );
      expect(reapplication.application.id).not.toBe(coachFlow.application.id);
      expect(reapplication.order.id).not.toBe(coachFlow.order.id);

      expect((await service.from('profiles').update({ current_coach_id: expiredRelationship.id }).eq('user_id', participant.id)).error).toBeNull();
      expect((await service.from('profiles').update({ provisional_expires_at: new Date(Date.now() - 60_000).toISOString() }).eq('user_id', expiredRelationship.id)).error).toBeNull();
      const expiryReconciliation = await service.rpc('enqueue_expired_provisional_cancellations');
      expect(expiryReconciliation.error).toBeNull();
      expect((await service.from('profiles').select('onboarding_status,provisional_expires_at,finalized_at').eq('user_id', expiredRelationship.id).single()).data)
        .toEqual(expect.objectContaining({ onboarding_status: 'active', provisional_expires_at: null }));

      const cancellationFlow = await prepareCoachOnboarding(
        cancellationClient,
        suffix,
        'cancel',
        applicationIds,
        orderIds,
      );
      const cancellationProof = await prepareAndUploadProof(
        cancellationClient,
        cancellationFlow.order.id,
        `w074-cancel-proof-${suffix}`,
        objectPaths,
      );
      const cancellationKey = `w074-cancel-${suffix}`;
      const cancellationRequest = await cancellationClient.rpc('request_my_provisional_cancellation', {
        request_idempotency_key: cancellationKey,
      });
      expect(cancellationRequest.error).toBeNull();
      const receipt = row(cancellationRequest.data);
      expect(receipt).toEqual(expect.objectContaining({ status: 'queued' }));
      const repeatedCancellation = await cancellationClient.rpc('request_my_provisional_cancellation', {
        request_idempotency_key: cancellationKey,
      });
      expect(repeatedCancellation.error).toBeNull();
      expect(row(repeatedCancellation.data)).toEqual(expect.objectContaining({ id: receipt.id, status: 'queued' }));
      expect((await service.from('profiles').select('onboarding_status').eq('user_id', cancellationApplicant.id).single()).data?.onboarding_status).toBe('cleanup_pending');
      expect((await service.from('payment_orders').select('id,status').eq('id', cancellationFlow.order.id).single()).data)
        .toEqual(expect.objectContaining({ id: cancellationFlow.order.id, status: 'cancelled' }));
      expect((await service.from('payment_evidence_attempts').select('id,status').eq('id', cancellationProof.id).single()).data)
        .toEqual(expect.objectContaining({ id: cancellationProof.id, status: 'deleted' }));
      expect((await service.from('coach_applications').select('id').eq('id', cancellationFlow.application.id)).data).toEqual([]);

      execFileSync('node', ['scripts/process-local-provisional-cancellations.mjs'], {
        cwd: process.cwd(),
        env: {
          ...process.env,
          API_URL: localUrl as string,
          SECRET_KEY: secretKey as string,
          CLEANUP_RECEIPT_ID: receipt.id as string,
          CLEANUP_BATCH_SIZE: '1',
        },
        stdio: 'pipe',
      });
      expect((await service.auth.admin.getUserById(cancellationApplicant.id)).error).not.toBeNull();
      expect((await service.storage.from('payment-evidence').download(cancellationProof.object_path)).error).not.toBeNull();
      await expectRpcError(cancellationClient.rpc('get_my_session_context'), 'session_profile_missing');
    } finally {
      if (objectPaths.length > 0) {
        await service.storage.from('payment-evidence').remove([...new Set(objectPaths)]);
      }
      if (orderIds.length > 0) {
        await service.from('payment_events').delete().in('order_id', orderIds);
        await service.from('payment_evidence_attempts').delete().in('order_id', orderIds);
        await service.from('payment_orders').delete().in('id', orderIds);
      }
      if (applicationIds.length > 0) {
        await service.from('coach_access_entitlements').delete().in('application_id', applicationIds);
        await service.from('coach_payment_records').delete().in('application_id', applicationIds);
        await service.from('coach_applications').delete().in('id', applicationIds);
      }
      await service.from('payment_destinations').delete().eq('id', destinationId);
      for (const identity of identities) {
        await service.auth.admin.deleteUser(identity.id);
      }
    }
  },
  60_000,
);

type Identity = { id: string; email: string; password: string };

async function createIdentity(
  service: SupabaseClient,
  label: string,
  identities: Identity[],
  userMetadata?: Record<string, unknown>,
) {
  const email = `${label}@test.invalid`;
  const password = `W074-${randomUUID()}!`;
  const response = await service.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: userMetadata,
  });
  expect(response.error).toBeNull();
  const identity = { id: response.data.user!.id, email, password };
  identities.push(identity);
  return identity;
}

async function signIn(identity: Identity) {
  const client = createClient(localUrl as string, publishableKey as string, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  expect((await client.auth.signInWithPassword({ email: identity.email, password: identity.password })).error).toBeNull();
  return client;
}

async function activateAdmin(service: SupabaseClient, userId: string) {
  expect((await service.from('profiles').update({
    role: 'admin',
    display_name: 'Admin W074',
    onboarding_status: 'active',
    provisional_expires_at: null,
    finalized_at: new Date().toISOString(),
  }).eq('user_id', userId)).error).toBeNull();
}

async function activateCoach(
  service: SupabaseClient,
  userId: string,
  adminId: string,
  coachQr: string,
  applicationIds: string[],
) {
  expect((await service.from('profiles').update({
    role: 'coach',
    display_name: 'Coach W074',
    phone_number: '+6281234567099',
    member_level: 'sc',
    onboarding_status: 'active',
    provisional_expires_at: null,
    finalized_at: new Date().toISOString(),
    coach_is_approved: true,
    coach_is_public: true,
    coach_qr_identifier: coachQr,
  }).eq('user_id', userId)).error).toBeNull();
  const applicationId = randomUUID();
  const paymentId = randomUUID();
  applicationIds.push(applicationId);
  expect((await service.from('coach_applications').insert({
    id: applicationId,
    applicant_user_id: userId,
    participant_profile_id: userId,
    display_name_snapshot: 'Coach W074',
    phone_number_snapshot: '+6281234567099',
    member_level_snapshot: 'sc',
    has_completed_hom_sts: true,
    has_completed_ict: true,
    terms_version: 'coach-web-v1',
    status: 'active',
    draft_idempotency_key: `w074-active-coach-${randomUUID()}`,
    submitted_at: new Date().toISOString(),
    decided_at: new Date().toISOString(),
    decided_by: adminId,
  })).error).toBeNull();
  expect((await service.from('coach_payment_records').insert({
    id: paymentId,
    application_id: applicationId,
    state: 'verified',
    price_band: 'entry',
    amount_minor_units: 100_000,
    duration_months: 3,
    provider_reference: `w074-${randomUUID()}`,
    verified_at: new Date().toISOString(),
  })).error).toBeNull();
  expect((await service.from('coach_access_entitlements').insert({
    application_id: applicationId,
    payment_record_id: paymentId,
    coach_user_id: userId,
    status: 'active',
    starts_at: new Date(Date.now() - 60_000).toISOString(),
    ends_at: new Date(Date.now() + 90 * 86_400_000).toISOString(),
  })).error).toBeNull();
}

async function saveProvisionalProfile(
  client: SupabaseClient,
  displayName: string,
  phoneNumber: string,
  memberLevel: string,
  purpose: string,
  expectedVersion: number,
) {
  const response = await client.rpc('save_my_provisional_onboarding_profile', {
    new_display_name: displayName,
    new_phone_number: phoneNumber,
    new_member_level: memberLevel,
    new_account_purpose: purpose,
    expected_version: expectedVersion,
  });
  expect(response.error).toBeNull();
  return row(response.data);
}

async function prepareCoachOnboarding(
  client: SupabaseClient,
  suffix: string,
  label: string,
  applicationIds: string[],
  orderIds: string[],
) {
  const saved = await saveProvisionalProfile(
    client,
    `Calon Coach ${label}`,
    '+6281234567088',
    'sc',
    'coach_applicant',
    1,
  );
  const handoff = await client.rpc('prepare_coach_application_handoff', {
    expected_version: saved.onboarding_version,
  });
  expect(handoff.error).toBeNull();
  const repeatedHandoff = await client.rpc('prepare_coach_application_handoff', {
    expected_version: row(handoff.data).onboarding_version,
  });
  expect(repeatedHandoff.error).toBeNull();
  const applicationResponse = await client.rpc('save_my_coach_application_draft', {
    member_level: 'sc',
    applicant_has_completed_hom_sts: true,
    applicant_has_completed_ict: true,
    accepted_terms_version: 'coach-web-v1',
    request_idempotency_key: `w074-draft-${label}-${suffix}`,
  });
  expect(applicationResponse.error).toBeNull();
  const application = row(applicationResponse.data);
  applicationIds.push(application.id as string);
  expect((await client.rpc('submit_my_coach_application', {
    target_application_id: application.id,
    request_idempotency_key: `w074-submit-${label}-${suffix}`,
  })).error).toBeNull();
  const orderResponse = await client.rpc('create_coach_payment_order', {
    target_application_id: application.id,
    request_idempotency_key: `w074-order-${label}-${suffix}`,
  });
  expect(orderResponse.error).toBeNull();
  const order = row(orderResponse.data);
  orderIds.push(order.id as string);
  expect((await client.rpc('create_coach_payment_order', {
    target_application_id: application.id,
    request_idempotency_key: `w074-order-repeat-${label}-${suffix}`,
  })).data).toEqual(expect.objectContaining({ id: order.id }));
  return { application, order };
}

async function createActiveParticipantReapplication(
  client: SupabaseClient,
  suffix: string,
  applicationIds: string[],
  orderIds: string[],
) {
  const draft = await client.rpc('save_my_coach_application_draft', {
    member_level: 'sc',
    applicant_has_completed_hom_sts: true,
    applicant_has_completed_ict: true,
    accepted_terms_version: 'coach-web-v1',
    request_idempotency_key: `w074-reapply-draft-${suffix}`,
  });
  expect(draft.error).toBeNull();
  const application = row(draft.data);
  applicationIds.push(application.id as string);
  expect((await client.rpc('submit_my_coach_application', {
    target_application_id: application.id,
    request_idempotency_key: `w074-reapply-submit-${suffix}`,
  })).error).toBeNull();
  const createdOrder = await client.rpc('create_coach_payment_order', {
    target_application_id: application.id,
    request_idempotency_key: `w074-reapply-order-${suffix}`,
  });
  expect(createdOrder.error).toBeNull();
  const order = row(createdOrder.data);
  orderIds.push(order.id as string);
  return { application, order };
}

async function prepareAndUploadProof(
  client: SupabaseClient,
  orderId: string,
  idempotencyKey: string,
  objectPaths: string[],
) {
  const prepared = await client.rpc('prepare_payment_evidence_attempt', {
    target_order_id: orderId,
    request_idempotency_key: idempotencyKey,
  });
  expect(prepared.error).toBeNull();
  const attempt = row(prepared.data);
  objectPaths.push(attempt.object_path as string);
  expect((await client.storage.from('payment-evidence').upload(attempt.object_path, jpeg, {
    contentType: 'image/jpeg',
    upsert: false,
  })).error).toBeNull();
  return attempt;
}

function proofPayload(attemptId: string) {
  return {
    target_attempt_id: attemptId,
    content_sha256_hex: createHash('sha256').update(jpeg).digest('hex'),
    content_byte_size: jpeg.byteLength,
    content_pixel_width: 1,
    content_pixel_height: 1,
  };
}

async function expectRpcError(
  promise: PromiseLike<{ error: { message?: string } | null }>,
  expectedMessage: string,
) {
  const response = await promise;
  expect(response.error?.message).toContain(expectedMessage);
}

function row(value: unknown): Record<string, any> {
  return (Array.isArray(value) ? value[0] : value) as Record<string, any>;
}
