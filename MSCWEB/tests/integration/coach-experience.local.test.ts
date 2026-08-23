import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { createHash, randomUUID } from 'node:crypto';
import { expect, it } from 'vitest';

const localUrl = process.env.API_URL;
const publishableKey = process.env.PUBLISHABLE_KEY ?? process.env.ANON_KEY;
const secretKey = process.env.SECRET_KEY ?? process.env.SERVICE_ROLE_KEY;
const canRun = localUrl !== undefined && publishableKey !== undefined && secretKey !== undefined;
const jpeg = Buffer.from('/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////2wBDAf//////////////////////////////////////////////////////////////////////////////////////wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAX/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIQAxAAAAF//8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABBQJ//8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAgBAwEBPwF//8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAgBAgEBPwF//8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQAGPwJ//8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPyF//9oADAMBAAIAAwAAABD/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oACAEDAQE/EB//xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oACAECAQE/EB//xAAUEAEAAAAAAAAAAAAAAAAAAAAA/9oACAEBAAE/EB//2Q==', 'base64');

it.runIf(canRun)('enforces W06 pricing, atomic Coach activation, scoped workspace, and public-profile privacy locally', async () => {
  expect(['127.0.0.1', 'localhost']).toContain(new URL(localUrl as string).hostname);
  const service = createClient(localUrl as string, secretKey as string, { auth: { persistSession: false, autoRefreshToken: false } });
  const suffix = randomUUID();
  const users: Identity[] = [];
  const applicationIds: string[] = [];
  const orderIds: string[] = [];
  const objectPaths: string[] = [];
  const publicObjectPaths: string[] = [];
  const programId = randomUUID();
  const paidProgramId = randomUUID();

  try {
    const [admin, sc, supervisor, leadership, member] = await Promise.all([
      getOrCreateAdmin(service),
      createIdentity(service, `w06-sc-${suffix}@test.invalid`, `W06-S-${suffix}!`, users),
      createIdentity(service, `w06-supervisor-${suffix}@test.invalid`, `W06-V-${suffix}!`, users),
      createIdentity(service, `w06-leadership-${suffix}@test.invalid`, `W06-L-${suffix}!`, users),
      createIdentity(service, `w06-member-${suffix}@test.invalid`, `W06-M-${suffix}!`, users),
    ]);
    await updateProfile(service, admin.id, { role: 'admin', display_name: 'Admin W06' });
    for (const [identity, name] of [[sc, 'Coach Sari'], [supervisor, 'Coach Surya'], [leadership, 'Peserta Leadership'], [member, 'Peserta Member']] as const) {
      await updateProfile(service, identity.id, { role: 'participant', display_name: name, phone_number: '+6281234567890', provider_avatar_url: 'https://example.com/avatar.jpg' });
    }

    const [adminClient, scClient, supervisorClient, leadershipClient, memberClient] = await Promise.all([
      signIn(admin), signIn(sc), signIn(supervisor), signIn(leadership), signIn(member),
    ]);
    const destination = await service.from('payment_destinations').select('id,bank_code,status')
      .eq('status', 'active').lte('effective_from', new Date().toISOString())
      .order('version', { ascending: false }).limit(1).maybeSingle();
    expect(destination.error).toBeNull();
    expect(destination.data?.id).toBeTruthy();

    const scFlow = await createApplicationAndOrder(scClient, 'sc', suffix, applicationIds, orderIds);
    const supervisorFlow = await createApplicationAndOrder(supervisorClient, 'supervisor', suffix, applicationIds, orderIds);
    const leadershipFlow = await createApplicationAndOrder(leadershipClient, 'tab_team', suffix, applicationIds, orderIds);
    expect(scFlow.order.amount_minor).toBe(100_000);
    expect(supervisorFlow.order.amount_minor).toBe(150_000);
    expect(leadershipFlow.order.amount_minor).toBe(200_000);

    const incompleteDraft = await memberClient.rpc('save_my_coach_application_draft', {
      member_level: 'sc', applicant_has_completed_hom_sts: false,
      applicant_has_completed_ict: true, accepted_terms_version: 'coach-web-v1',
      request_idempotency_key: `w06-incomplete-${suffix}`,
    });
    expect(incompleteDraft.error).toBeNull();
    expect(row(incompleteDraft.data).status).toBe('ineligible');
    expect((await memberClient.rpc('submit_my_coach_application', { target_application_id: row(incompleteDraft.data).id, request_idempotency_key: `w06-incomplete-submit-${suffix}` })).error?.message).toContain('coach_eligibility_incomplete');

    const memberDraft = await memberClient.rpc('save_my_coach_application_draft', {
      member_level: 'member', applicant_has_completed_hom_sts: true,
      applicant_has_completed_ict: true, accepted_terms_version: 'coach-web-v1',
      request_idempotency_key: `w06-member-${suffix}`,
    });
    expect(memberDraft.error).toBeNull();
    const memberApplication = row(memberDraft.data);
    applicationIds.push(memberApplication.id as string);
    expect(memberApplication.status).toBe('ineligible');
    expect((await memberClient.rpc('submit_my_coach_application', { target_application_id: memberApplication.id, request_idempotency_key: `w06-member-submit-${suffix}` })).error?.message).toContain('coach_eligibility_incomplete');

    const activatedSc = await submitEvidenceAndApprove(scClient, adminClient, scFlow.order, suffix, objectPaths);
    const activatedSupervisor = await submitEvidenceAndApprove(supervisorClient, adminClient, supervisorFlow.order, `${suffix}-other`, objectPaths);
    expect(activatedSc.application.status).toBe('active');
    expect(activatedSupervisor.application.status).toBe('active');
    expect((await service.from('profiles').select('role,coach_is_approved,coach_qr_identifier').eq('user_id', sc.id).single()).data).toEqual(expect.objectContaining({ role: 'coach', coach_is_approved: true }));
    expect((await scClient.rpc('save_my_coach_application_draft', { member_level: 'sc', applicant_has_completed_hom_sts: true, applicant_has_completed_ict: true, accepted_terms_version: 'coach-web-v1', request_idempotency_key: `w06-already-coach-${suffix}` })).error?.message).toContain('permission_denied');
    const entitlements = await service.from('coach_access_entitlements').select('coach_user_id,status,starts_at,ends_at').in('coach_user_id', [sc.id, supervisor.id]);
    expect(entitlements.data).toHaveLength(2);
    for (const entitlement of entitlements.data ?? []) {
      expect(entitlement.status).toBe('active');
      const months = (new Date(entitlement.ends_at).getTime() - new Date(entitlement.starts_at).getTime()) / 86_400_000;
      expect(months).toBeGreaterThan(89);
      expect(months).toBeLessThan(93);
    }

    const repeated = await adminClient.rpc('approve_coach_payment_and_activate', {
      target_order_id: scFlow.order.id, expected_version: activatedSc.order.version,
      reconciled_amount_minor: scFlow.order.amount_minor,
      reconciliation_reference: `W06-${suffix.slice(0, 8)}`, destination_matches: true,
      request_idempotency_key: `w06-approve-${suffix}`,
    });
    expect(repeated.error).toBeNull();
    expect(row(repeated.data).application).toEqual(expect.objectContaining({ status: 'active' }));

    const leadershipSubmitted = await submitEvidence(leadershipClient, leadershipFlow.order, `${suffix}-reject`, objectPaths);
    expect((await adminClient.rpc('reject_coach_application_and_payment', {
      target_order_id: leadershipFlow.order.id, expected_version: leadershipSubmitted.version,
      rejection_reason: '', request_idempotency_key: `w06-reject-empty-${suffix}`,
    })).error?.message).toContain('reason_required');
    const rejectKey = `w06-reject-${suffix}`;
    const rejected = await adminClient.rpc('reject_coach_application_and_payment', {
      target_order_id: leadershipFlow.order.id, expected_version: leadershipSubmitted.version,
      rejection_reason: 'Bukti pembayaran tidak sesuai tujuan.', request_idempotency_key: rejectKey,
    });
    expect(rejected.error).toBeNull();
    const rejectedOrder = row(rejected.data).order as { version: number };
    expect((await adminClient.rpc('reject_coach_application_and_payment', {
      target_order_id: leadershipFlow.order.id, expected_version: rejectedOrder.version,
      rejection_reason: 'Bukti pembayaran tidak sesuai tujuan.', request_idempotency_key: rejectKey,
    })).error).toBeNull();
    expect((await adminClient.rpc('approve_coach_payment_and_activate', {
      target_order_id: leadershipFlow.order.id, expected_version: leadershipSubmitted.version,
      reconciled_amount_minor: leadershipFlow.order.amount_minor,
      reconciliation_reference: `W06-RACE-${suffix.slice(0, 8)}`, destination_matches: true,
      request_idempotency_key: `w06-race-${suffix}`,
    })).error?.message).toContain('version_conflict');

    expect((await service.from('programs').insert({ id: programId, title: 'Program cakupan Coach W06', summary: 'Fixture W06.', status: 'active', pace: 'scheduled', duration_mode: 'specific_dates', starts_on: localDate(-1), ends_on: localDate(5), timezone: 'Asia/Makassar', past_step_policy: 'read_only', future_step_policy: 'locked', wellness_disclaimer: 'Program wellness non-diagnostik.', points_per_activity: 10, points_per_weight_kg: 100, quiz_passing_percentage: 70, pricing_mode: 'free', desired_price: null, participant_limit: 20, published_at: new Date().toISOString(), created_by: admin.id })).error).toBeNull();
    const enrollment = await service.from('program_enrollments').insert({ program_id: programId, participant_id: leadership.id, coach_id: sc.id, status: 'active' }).select('id').single();
    expect(enrollment.error).toBeNull();
    expect((await service.from('profiles').update({ current_coach_id: sc.id }).eq('user_id', leadership.id)).error).toBeNull();
    expect((await service.from('program_scores').insert({ enrollment_id: enrollment.data?.id, progress_percentage: 42, activity_points: 50, quiz_points: 5, weight_points: 20, adjustment_points: -2, rank: 1 })).error).toBeNull();
    const foreignEnrollment = await service.from('program_enrollments').insert({ program_id: programId, participant_id: member.id, coach_id: supervisor.id, status: 'active' }).select('id').single();
    expect(foreignEnrollment.error).toBeNull();
    expect((await service.from('program_scores').insert({ enrollment_id: foreignEnrollment.data?.id, progress_percentage: 30, activity_points: 35, quiz_points: 5, weight_points: 10, adjustment_points: 0, rank: 2 })).error).toBeNull();
    const programDay = await service.from('program_days').insert({ program_id: programId, day_number: 1, title: 'Mulai konsisten', scheduled_on: localDate(0) }).select('id').single();
    expect(programDay.error).toBeNull();
    const futureProgramDay = await service.from('program_days').insert({ program_id: programId, day_number: 2, title: 'Besok konsisten', scheduled_on: localDate(1) }).select('id').single();
    expect(futureProgramDay.error).toBeNull();
    const steps = await service.from('program_steps').insert([
      { program_day_id: programDay.data?.id, step_order: 1, title: 'Foto kebiasaan sehat', instructions: 'Kirim foto.', content_kind: 'form', completion_policy: 'answer_all_questions', verification_mode: 'coach_review' },
      { program_day_id: programDay.data?.id, step_order: 2, title: 'Gerak pagi', instructions: 'Tandai selesai.', content_kind: 'article', completion_policy: 'mark_complete', verification_mode: 'automatic' },
      { program_day_id: programDay.data?.id, step_order: 3, title: 'Timbang awal', instructions: 'Catat berat awal.', content_kind: 'initial_weigh_in', completion_policy: 'submit_weigh_in', verification_mode: 'automatic' },
    ]).select('id,step_order');
    expect(steps.error).toBeNull();
    expect((await service.from('program_steps').insert({
      program_day_id: futureProgramDay.data?.id,
      step_order: 1,
      title: 'Aktivitas besok',
      instructions: 'Selesaikan besok.',
      content_kind: 'article',
      completion_policy: 'mark_complete',
      verification_mode: 'automatic',
    })).error).toBeNull();
    const reviewStepId = steps.data?.find((step) => step.step_order === 1)?.id;
    const automaticStepId = steps.data?.find((step) => step.step_order === 2)?.id;
    const initialWeighInStepId = steps.data?.find((step) => step.step_order === 3)?.id;
    expect((await service.from('step_submissions').insert([
      { enrollment_id: enrollment.data?.id, step_id: reviewStepId, status: 'pending' },
      { enrollment_id: enrollment.data?.id, step_id: automaticStepId, status: 'approved', reviewed_at: new Date().toISOString(), reviewer_id: sc.id },
    ])).error).toBeNull();
    expect((await service.from('weigh_ins').insert({
      enrollment_id: enrollment.data?.id,
      step_id: initialWeighInStepId,
      kind: 'initial',
      weight_kg: 73,
    })).error).toBeNull();

    const coachIdentifiers = await service.from('profiles')
      .select('user_id,coach_qr_identifier')
      .in('user_id', [sc.id, supervisor.id]);
    expect(coachIdentifiers.error).toBeNull();
    const scQr = coachIdentifiers.data?.find((profile) => profile.user_id === sc.id)?.coach_qr_identifier as string;
    const supervisorQr = coachIdentifiers.data?.find((profile) => profile.user_id === supervisor.id)?.coach_qr_identifier as string;
    expect((await service.from('profiles').update({ current_coach_id: supervisor.id }).eq('user_id', sc.id)).error).toBeNull();
    expect((await scClient.rpc('enroll_free_program', {
      target_program_id: programId,
      scanned_coach_qr: supervisorQr,
    })).error?.message).toContain('coach_qr_invalid');
    const coachEnrollment = await scClient.rpc('enroll_free_program', {
      target_program_id: programId,
      scanned_coach_qr: scQr,
    });
    expect(coachEnrollment.error).toBeNull();
    expect(row(coachEnrollment.data)).toEqual(expect.objectContaining({
      program_id: programId,
      participant_id: sc.id,
      coach_id: sc.id,
      status: 'active',
    }));
    const repeatedCoachEnrollment = await scClient.rpc('enroll_free_program', {
      target_program_id: programId,
      scanned_coach_qr: scQr,
    });
    expect(repeatedCoachEnrollment.error).toBeNull();
    expect(row(repeatedCoachEnrollment.data).id).toBe(row(coachEnrollment.data).id);
    expect((await service.from('program_enrollments').update({ status: 'completed', completed_at: new Date().toISOString() }).eq('id', row(coachEnrollment.data).id)).error).toBeNull();
    const assignedCoach = await scClient.rpc('get_my_assigned_coach');
    expect(assignedCoach.error).toBeNull();
    expect(row(assignedCoach.data).user_id).toBe(sc.id);
    expect((await service.from('profiles').select('current_coach_id').eq('user_id', sc.id).single()).data?.current_coach_id).toBe(sc.id);

    expect((await service.from('programs').insert({
      id: paidProgramId,
      title: 'Program berbayar Coach W06',
      summary: 'Fixture parity pembayaran Coach.',
      status: 'active',
      pace: 'scheduled',
      duration_mode: 'specific_dates',
      starts_on: localDate(-1),
      ends_on: localDate(5),
      timezone: 'Asia/Makassar',
      past_step_policy: 'read_only',
      future_step_policy: 'locked',
      wellness_disclaimer: 'Program wellness non-diagnostik.',
      points_per_activity: 10,
      points_per_weight_kg: 100,
      quiz_passing_percentage: 70,
      pricing_mode: 'paid',
      desired_price: 125_000,
      participant_limit: 20,
      published_at: new Date().toISOString(),
      created_by: admin.id,
    })).error).toBeNull();
    const coachPaymentOrder = await scClient.rpc('create_program_payment_order', {
      target_program_id: paidProgramId,
      coach_qr_payload: scQr,
      payment_method: 'bank_transfer',
      request_idempotency_key: `w06-program-payment-${suffix}`,
    });
    expect(coachPaymentOrder.error).toBeNull();
    expect(row(coachPaymentOrder.data)).toEqual(expect.objectContaining({
      owner_user_id: sc.id,
      program_id: paidProgramId,
      coach_user_id_snapshot: sc.id,
      amount_minor: 125_000,
      status: 'awaiting_evidence',
    }));
    orderIds.push(row(coachPaymentOrder.data).id as string);

    const scWorkspace = await scClient.rpc('get_my_coach_workspace');
    const supervisorWorkspace = await supervisorClient.rpc('get_my_coach_workspace');
    expect(scWorkspace.error).toBeNull();
    expect((row(scWorkspace.data).participants as { participant_id: string }[]).map((participant) => participant.participant_id).sort()).toEqual([leadership.id, sc.id].sort());
    expect(supervisorWorkspace.error).toBeNull();
    expect((row(supervisorWorkspace.data).participants as { participant_id: string }[]).map((participant) => participant.participant_id)).toEqual([member.id]);
    expect((await supervisorClient.from('program_enrollments').select('id').eq('participant_id', leadership.id)).data).toEqual([]);
    expect(JSON.stringify(scWorkspace.data)).not.toContain((await service.from('profiles').select('coach_qr_identifier').eq('user_id', supervisor.id).single()).data?.coach_qr_identifier);
    const scLeaderboard = await scClient.rpc('get_my_coach_leaderboard', {
      target_program_id: programId, result_limit: 100, result_offset: 0,
    });
    const supervisorLeaderboard = await supervisorClient.rpc('get_my_coach_leaderboard', {
      target_program_id: programId, result_limit: 100, result_offset: 0,
    });
    expect(scLeaderboard.error).toBeNull();
    expect(supervisorLeaderboard.error).toBeNull();
    const scLeaderboardRows = scLeaderboard.data as Record<string, unknown>[];
    const publicProfiles = await service.from('profiles').select('user_id,public_profile_id').in('user_id', [leadership.id, member.id, sc.id]);
    expect(publicProfiles.error).toBeNull();
    const leadershipPublicId = publicProfiles.data?.find((profile) => profile.user_id === leadership.id)?.public_profile_id;
    const memberPublicId = publicProfiles.data?.find((profile) => profile.user_id === member.id)?.public_profile_id;
    const scPublicId = publicProfiles.data?.find((profile) => profile.user_id === sc.id)?.public_profile_id;
    const assignedScore = scLeaderboardRows.find((score) => score.participant_id === leadershipPublicId);
    const foreignScore = scLeaderboardRows.find((score) => score.participant_id === memberPublicId);
    expect(assignedScore).toEqual(expect.objectContaining({ is_assigned_to_coach: true, step_points: 55, weight_points: 20, adjustment_points: -2, avatar_url: 'https://example.com/avatar.jpg' }));
    expect(foreignScore).toEqual(expect.objectContaining({ is_assigned_to_coach: false, step_points: null, weight_points: null, adjustment_points: null, avatar_url: 'https://example.com/avatar.jpg' }));
    const supervisorRows = supervisorLeaderboard.data as Record<string, unknown>[];
    expect(supervisorRows.find((score) => score.participant_id === foreignScore?.participant_id)).toEqual(expect.objectContaining({ is_assigned_to_coach: true, step_points: 40 }));
    expect(supervisorRows.find((score) => score.participant_id === assignedScore?.participant_id)).toEqual(expect.objectContaining({ is_assigned_to_coach: false, step_points: null }));
    const publicLeaderboard = await scClient.rpc('list_public_leaderboard', {
      target_program_id: programId, result_limit: 100, result_offset: 0,
    });
    expect(publicLeaderboard.error).toBeNull();
    expect(publicLeaderboard.data).toEqual(expect.arrayContaining([
      expect.objectContaining({ participant_id: leadershipPublicId, avatar_url: 'https://example.com/avatar.jpg' }),
      expect.objectContaining({ participant_id: memberPublicId, avatar_url: 'https://example.com/avatar.jpg' }),
      expect.objectContaining({ participant_id: scPublicId, avatar_url: 'https://example.com/avatar.jpg' }),
    ]));
    const scDirectory = await scClient.rpc('get_my_coach_participant_directory');
    const supervisorDirectory = await supervisorClient.rpc('get_my_coach_participant_directory');
    expect(scDirectory.error).toBeNull();
    const directoryParticipants = row(scDirectory.data).participants as {
      participant_id: string;
      enrollments: {
        enrollment_id: string;
        completed_step_count: number;
        due_step_count: number;
        completed_due_step_count: number;
        total_step_count: number;
        active_day_count: number;
      }[];
    }[];
    expect(directoryParticipants.map((participant) => participant.participant_id).sort()).toEqual([leadership.id, sc.id].sort());
    expect(directoryParticipants
      .find((participant) => participant.participant_id === leadership.id)
      ?.enrollments.find((item) => item.enrollment_id === enrollment.data?.id))
      .toEqual(expect.objectContaining({
        completed_step_count: 3,
        due_step_count: 3,
        completed_due_step_count: 3,
        total_step_count: 4,
        active_day_count: 1,
      }));
    expect(supervisorDirectory.error).toBeNull();
    expect((row(supervisorDirectory.data).participants as { participant_id: string }[]).map((participant) => participant.participant_id)).toEqual([member.id]);
    const assignedDetail = await scClient.rpc('get_my_coach_participant_detail', {
      target_participant_id: leadership.id,
      target_enrollment_id: enrollment.data?.id,
    });
    expect(assignedDetail.error).toBeNull();
    expect(row(assignedDetail.data).participant).toEqual(expect.objectContaining({ participant_id: leadership.id }));
    expect(row(assignedDetail.data).summary).toEqual(expect.objectContaining({
      progress_percentage: 42,
      completed_step_count: 3,
      active_day_count: 1,
    }));
    const detailDays = row(assignedDetail.data).days as {
      steps: { id: string; status: string }[];
    }[];
    expect(detailDays.flatMap((day) => day.steps)
      .find((step) => step.id === initialWeighInStepId)?.status).toBe('approved');
    expect((await supervisorClient.rpc('get_my_coach_participant_detail', {
      target_participant_id: leadership.id,
      target_enrollment_id: enrollment.data?.id,
    })).error?.message).toContain('permission_denied');
    const scActivity = await scClient.rpc('get_my_coach_activity_feed');
    const supervisorActivity = await supervisorClient.rpc('get_my_coach_activity_feed');
    expect(scActivity.error).toBeNull();
    const activityItems = row(scActivity.data).items as { kind: string; participant_id: string; requires_review: boolean; points: number | null }[];
    expect(new Set(activityItems.map((item) => item.kind))).toEqual(new Set([
      'participant_joined', 'program_completed', 'evidence_submitted', 'step_completed',
    ]));
    expect(activityItems).toContainEqual(expect.objectContaining({ participant_id: leadership.id, kind: 'evidence_submitted', requires_review: true }));
    expect(activityItems).toContainEqual(expect.objectContaining({ participant_id: leadership.id, kind: 'step_completed', points: 10 }));
    expect(supervisorActivity.error).toBeNull();
    expect((row(supervisorActivity.data).items as { participant_id: string; kind: string }[])).toContainEqual(expect.objectContaining({ participant_id: member.id, kind: 'participant_joined' }));

    const handle = `coach-w06-${suffix.slice(0, 8)}`;
    const allocation = await scClient.rpc('allocate_my_coach_public_media_path', { media_folder: 'avatar' });
    expect(allocation.error).toBeNull();
    const publicPhotoPath = allocation.data as string;
    expect((await scClient.storage.from('coach-public-media').upload(publicPhotoPath, jpeg, { contentType: 'image/jpeg', upsert: false })).error).toBeNull();
    publicObjectPaths.push(publicPhotoPath);
    const foreignPath = publicPhotoPath.replace(/[^/]+\.jpg$/u, `${randomUUID()}.jpg`);
    expect((await supervisorClient.storage.from('coach-public-media').upload(foreignPath, jpeg, { contentType: 'image/jpeg', upsert: false })).error).not.toBeNull();
    const draft = await scClient.rpc('save_my_coach_public_profile_draft', {
      requested_handle: handle, photo_object_path: publicPhotoPath,
      professional_headline: 'Pendamping kebiasaan sehat', biography: 'Mendampingi perubahan kebiasaan secara bertahap.',
      service_area: 'Denpasar', instagram_url: 'https://instagram.com/rahasia-w06',
      tiktok_url: '', website_url: 'https://example.com/coach', whatsapp_number: '+628111111111',
      phone_number: '+628122222222', show_instagram: false, show_tiktok: false,
      show_website: true, show_whatsapp: false, show_phone: false,
    });
    expect(draft.error).toBeNull();
    const published = await scClient.rpc('publish_my_coach_public_profile');
    expect(published.error).toBeNull();
    const guest = createClient(localUrl as string, publishableKey as string, { auth: { persistSession: false } });
    const publicRead = await guest.rpc('get_public_coach_profile', { target_handle: handle });
    expect(publicRead.error).toBeNull();
    const publicJson = JSON.stringify(publicRead.data);
    expect(row(publicRead.data).photo_kind).toBe('storage');
    const publicPhotoAssetId = row(publicRead.data).photo_reference as string;
    expect(publicPhotoAssetId).toMatch(/^[0-9a-f-]{36}$/u);
    expect(publicPhotoAssetId).not.toBe(publicPhotoPath);
    expect(publicJson).not.toContain(publicPhotoPath);
    const resolvedAsset = await service.rpc('resolve_public_coach_media_asset', {
      target_asset_id: publicPhotoAssetId,
    });
    expect(resolvedAsset.error).toBeNull();
    expect(resolvedAsset.data).toBe(publicPhotoPath);
    expect((await guest.rpc('resolve_public_coach_media_asset', {
      target_asset_id: publicPhotoAssetId,
    })).error).not.toBeNull();
    const directStorageUrl = guest.storage.from('coach-public-media')
      .getPublicUrl(publicPhotoPath).data.publicUrl;
    expect((await fetch(directStorageUrl)).ok).toBe(false);
    const gatewayUrl = new URL(
      `/functions/v1/public-coach-media/${publicPhotoAssetId}`,
      localUrl as string,
    );
    const gatewayResponse = await fetch(gatewayUrl);
    expect(gatewayResponse.status).toBe(200);
    expect(gatewayResponse.headers.get('cache-control')).toBe('no-store, max-age=0');
    expect(gatewayResponse.headers.get('content-type')).toContain('image/jpeg');
    expect((await gatewayResponse.arrayBuffer()).byteLength).toBeGreaterThan(0);
    expect(publicJson).not.toContain('example.com/avatar.jpg');
    expect(publicJson).not.toContain(sc.id);
    expect(publicJson).toContain('Pendamping kebiasaan sehat');
    expect(publicJson).not.toContain('rahasia-w06');
    expect(publicJson).not.toContain('+628111111111');
    expect(publicJson).not.toContain('+628122222222');
    expect(publicJson).not.toContain(row(scWorkspace.data).qr_payload as string);
    expect((await guest.rpc('get_public_coach_profile', { target_handle: 'tidak-ada' })).data).toBeNull();

    const publicDirectory = await guest.rpc('list_public_coaches', {
      result_limit: 100,
      result_offset: 0,
    });
    expect(publicDirectory.error).toBeNull();
    const directoryCoach = (publicDirectory.data as Record<string, unknown>[])
      .find((coach) => coach.id === scPublicId);
    expect(directoryCoach).toEqual(expect.objectContaining({
      handle,
      professional_headline: 'Pendamping kebiasaan sehat',
      biography: 'Mendampingi perubahan kebiasaan secara bertahap.',
      city: 'Denpasar',
      photo_reference: publicPhotoAssetId,
      is_verified: true,
    }));
    expect(JSON.stringify(directoryCoach)).not.toContain(publicPhotoPath);
    expect(JSON.stringify(directoryCoach)).not.toContain('example.com/avatar.jpg');

    const assignedPublishedCoach = await leadershipClient.rpc('get_my_assigned_coach_profile');
    expect(assignedPublishedCoach.error).toBeNull();
    expect(row(assignedPublishedCoach.data)).toEqual(expect.objectContaining({
      user_id: sc.id,
      handle,
      professional_headline: 'Pendamping kebiasaan sehat',
      biography: 'Mendampingi perubahan kebiasaan secara bertahap.',
      city: 'Denpasar',
      photo_reference: publicPhotoAssetId,
      is_verified: true,
    }));
    expect((await guest.rpc('get_my_assigned_coach_profile')).error).not.toBeNull();

    const refreshedCoachWorkspace = await scClient.rpc('get_my_coach_workspace');
    expect(refreshedCoachWorkspace.error).toBeNull();
    expect(row(refreshedCoachWorkspace.data).profile).toEqual(expect.objectContaining({
      display_name: 'Coach Sari',
      city: 'Denpasar',
      professional_headline: 'Pendamping kebiasaan sehat',
      photo_reference: publicPhotoAssetId,
    }));
    expect(JSON.stringify(row(refreshedCoachWorkspace.data).profile)).not.toContain(publicPhotoPath);

    const adminDirectory = await adminClient.rpc('list_admin_people');
    expect(adminDirectory.error).toBeNull();
    const adminCoachRow = (adminDirectory.data as Record<string, unknown>[])
      .find((person) => person.user_id === sc.id);
    expect(adminCoachRow).toEqual(expect.objectContaining({
      display_name: 'Coach Sari',
      city: 'Denpasar',
      professional_headline: 'Pendamping kebiasaan sehat',
      photo_reference: publicPhotoAssetId,
      profile_published: true,
    }));
    expect(JSON.stringify(adminCoachRow)).not.toContain(publicPhotoPath);

    const adminCoachDetail = await adminClient.rpc('get_admin_person_detail', { target_user_id: sc.id });
    expect(adminCoachDetail.error).toBeNull();
    expect(row(adminCoachDetail.data)).toEqual(expect.objectContaining({
      city: 'Denpasar',
      professional_headline: 'Pendamping kebiasaan sehat',
      coach_biography: 'Mendampingi perubahan kebiasaan secara bertahap.',
      photo_reference: publicPhotoAssetId,
    }));
    expect(JSON.stringify(adminCoachDetail.data)).not.toContain(publicPhotoPath);

    const expiredUpdate = await service.from('coach_access_entitlements').update({
      starts_at: new Date(Date.now() - 100 * 86_400_000).toISOString(),
      ends_at: new Date(Date.now() - 1000).toISOString(),
    }).eq('coach_user_id', sc.id);
    expect(expiredUpdate.error).toBeNull();
    expect((await guest.rpc('get_public_coach_profile', { target_handle: handle })).data).toBeNull();
    expect((await service.rpc('resolve_public_coach_media_asset', {
      target_asset_id: publicPhotoAssetId,
    })).data).toBeNull();
    expect((await fetch(gatewayUrl)).status).toBe(404);
    expect((await scClient.rpc('get_my_coach_workspace')).error?.message).toContain('coach_entitlement_inactive');
  } finally {
    await service.from('program_scores').delete().in('enrollment_id', (await service.from('program_enrollments').select('id').eq('program_id', programId)).data?.map((row) => row.id) ?? []);
    await service.from('program_enrollments').delete().eq('program_id', programId);
    await service.from('programs').delete().eq('id', programId);
    await service.from('coach_public_profile_items').delete().in('coach_user_id', users.map((user) => user.id));
    await service.from('coach_public_profiles').delete().in('coach_user_id', users.map((user) => user.id));
    await service.from('coach_public_profile_drafts').delete().in('coach_user_id', users.map((user) => user.id));
    await service.from('coach_access_entitlements').delete().in('application_id', applicationIds);
    await service.from('coach_payment_records').delete().in('application_id', applicationIds);
    await service.from('payment_ledger').delete().in('order_id', orderIds);
    await service.from('payment_events').delete().in('order_id', orderIds);
    await service.from('payment_evidence_attempts').delete().in('order_id', orderIds);
    await service.from('payment_orders').delete().in('id', orderIds);
    await service.from('program_enrollments').delete().eq('program_id', paidProgramId);
    await service.from('programs').delete().eq('id', paidProgramId);
    await service.from('audit_events').delete().in('subject_id', [...applicationIds, ...orderIds]);
    await service.from('audit_events').delete().in('actor_id', users.map((user) => user.id));
    await service.from('commerce_transactions').delete().in('coach_application_id', applicationIds);
    await service.from('coach_applications').delete().in('id', applicationIds);
    if (objectPaths.length) await service.storage.from('payment-evidence').remove(objectPaths);
    if (publicObjectPaths.length) await service.storage.from('coach-public-media').remove(publicObjectPaths);
    for (const user of users) await service.auth.admin.deleteUser(user.id);
  }
});

type Identity = { id: string; email: string; password: string };

async function getOrCreateAdmin(service: SupabaseClient): Promise<Identity> {
  const email = 'w06-admin-local@test.invalid';
  const password = 'W06-Admin-Local-Only!';
  const listed = await service.auth.admin.listUsers({ page: 1, perPage: 1_000 });
  expect(listed.error).toBeNull();
  const existing = listed.data.users.find((user) => user.email === email);
  if (existing) {
    expect((await service.auth.admin.updateUserById(existing.id, { password, email_confirm: true })).error).toBeNull();
    return { id: existing.id, email, password };
  }
  const response = await service.auth.admin.createUser({ email, password, email_confirm: true });
  expect(response.error).toBeNull();
  return { id: response.data.user?.id as string, email, password };
}

async function createIdentity(service: SupabaseClient, email: string, password: string, users: Identity[]): Promise<Identity> {
  const response = await service.auth.admin.createUser({ email, password, email_confirm: true });
  expect(response.error).toBeNull();
  const identity = { id: response.data.user?.id as string, email, password };
  users.push(identity); return identity;
}

async function updateProfile(service: SupabaseClient, id: string, values: Record<string, unknown>) {
  expect((await service.from('profiles').update({ ...values, onboarding_status: 'active', provisional_expires_at: null, finalized_at: new Date().toISOString() }).eq('user_id', id)).error).toBeNull();
}

async function signIn(identity: Identity) {
  const client = createClient(localUrl as string, publishableKey as string, { auth: { persistSession: false, autoRefreshToken: false } });
  expect((await client.auth.signInWithPassword({ email: identity.email, password: identity.password })).error).toBeNull();
  return client;
}

async function createApplicationAndOrder(client: SupabaseClient, level: string, suffix: string, applications: string[], orders: string[]) {
  const draft = await client.rpc('save_my_coach_application_draft', { member_level: level, applicant_has_completed_hom_sts: true, applicant_has_completed_ict: true, accepted_terms_version: 'coach-web-v1', request_idempotency_key: `w06-draft-${level}-${suffix}` });
  expect(draft.error).toBeNull(); const application = row(draft.data); applications.push(application.id as string);
  expect((await client.rpc('submit_my_coach_application', { target_application_id: application.id, request_idempotency_key: `w06-submit-${level}-${suffix}` })).error).toBeNull();
  const orderResponse = await client.rpc('create_coach_payment_order', { target_application_id: application.id, request_idempotency_key: `w06-order-${level}-${suffix}` });
  expect(orderResponse.error).toBeNull(); const order = row(orderResponse.data) as { id: string; amount_minor: number; version: number }; orders.push(order.id);
  return { application, order };
}

async function submitEvidenceAndApprove(client: SupabaseClient, admin: SupabaseClient, order: { id: string; amount_minor: number; version: number }, suffix: string, paths: string[]) {
  const submittedOrder = await submitEvidence(client, order, suffix, paths);
  const approved = await admin.rpc('approve_coach_payment_and_activate', { target_order_id: order.id, expected_version: submittedOrder.version, reconciled_amount_minor: order.amount_minor, reconciliation_reference: `W06-${suffix.slice(0, 8)}`, destination_matches: true, request_idempotency_key: `w06-approve-${suffix}` });
  expect(approved.error).toBeNull(); return row(approved.data) as { application: { status: string }; order: { version: number } };
}

async function submitEvidence(client: SupabaseClient, order: { id: string }, suffix: string, paths: string[]) {
  const prepare = await client.rpc('prepare_payment_evidence_attempt', { target_order_id: order.id, request_idempotency_key: `w06-proof-${suffix}` });
  expect(prepare.error).toBeNull(); const attempt = row(prepare.data) as { id: string; object_path: string }; paths.push(attempt.object_path);
  expect((await client.storage.from('payment-evidence').upload(attempt.object_path, jpeg, { contentType: 'image/jpeg', upsert: false })).error).toBeNull();
  const submitted = await client.rpc('submit_payment_evidence', { target_attempt_id: attempt.id, content_sha256_hex: createHash('sha256').update(jpeg).digest('hex'), content_byte_size: jpeg.byteLength, content_pixel_width: 1, content_pixel_height: 1 });
  expect(submitted.error).toBeNull();
  return row(submitted.data) as { version: number };
}

function row(value: unknown): Record<string, any> { return (Array.isArray(value) ? value[0] : value) as Record<string, any>; }
function localDate(offset: number) { return new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Makassar', year: 'numeric', month: '2-digit', day: '2-digit' }).format(new Date(Date.now() + offset * 86_400_000)); }
