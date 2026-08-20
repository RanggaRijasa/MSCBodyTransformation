import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { randomUUID } from 'node:crypto';
import { expect, it } from 'vitest';

const localUrl = process.env.API_URL;
const publishableKey = process.env.PUBLISHABLE_KEY ?? process.env.ANON_KEY;
const secretKey = process.env.SECRET_KEY ?? process.env.SERVICE_ROLE_KEY;
const canRun = Boolean(localUrl && publishableKey && secretKey);

it.runIf(canRun)('runs W07 Admin authority end-to-end with RLS, audit, winners, moderation, and AI redaction', async () => {
  expect(['127.0.0.1', 'localhost']).toContain(new URL(localUrl as string).hostname);
  const service = createClient(localUrl as string, secretKey as string, { auth: { persistSession: false, autoRefreshToken: false } });
  const identities: Array<{ id: string; email: string; password: string }> = [];
  const programId = randomUUID(); const duplicateId = randomUUID(); const dayId = randomUUID(); const articleStepId = randomUUID(); const foodStepId = randomUUID(); const questionId = randomUUID();
  const articleSubmissionId = randomUUID(); const foodSubmissionId = randomUUID();
  const foodSubmissionKey = `w07-food-${randomUUID()}`;
  const mediaPath = `programs/${randomUUID()}.jpg`; const createdPrograms = [programId, duplicateId]; let privatePath = '';
  try {
    const [admin, participant, coach, unrelated] = await Promise.all([
      createIdentity(service, 'w07-admin'), createIdentity(service, 'w07-participant'), createIdentity(service, 'w07-coach'), createIdentity(service, 'w07-unrelated'),
    ]);
    identities.push(admin, participant, coach, unrelated);
    await Promise.all([
      activateProfile(service, admin.id, 'admin', 'Admin W07'), activateProfile(service, participant.id, 'participant', 'Peserta W07'),
      activateProfile(service, coach.id, 'coach', 'Coach W07'), activateProfile(service, unrelated.id, 'participant', 'Peserta Lain W07'),
    ]);
    expect((await service.from('profiles').update({ coach_is_approved: true, coach_is_public: true }).eq('user_id', coach.id)).error).toBeNull();
    await activateCoach(service, coach.id, admin.id);
    expect((await service.from('profiles').update({ current_coach_id: coach.id }).eq('user_id', participant.id)).error).toBeNull();
    expect((await service.from('profiles').update({ current_coach_id: coach.id }).eq('user_id', unrelated.id)).error).toBeNull();
    expect((await service.from('profiles').update({ phone_number: '+6281234567007' }).eq('user_id', participant.id)).error).toBeNull();
    expect((await service.storage.from('public-media').upload(mediaPath, new Blob([new Uint8Array([0xff, 0xd8, 0xff, 0xd9])], { type: 'image/jpeg' }), { contentType: 'image/jpeg' })).error).toBeNull();
    const [adminClient, participantClient] = await Promise.all([signIn(admin), signIn(participant)]);

    const payload = programPayload({ programId, dayId, articleStepId, foodStepId, questionId, adminId: admin.id, mediaPath });
    const saved = await adminClient.rpc('save_admin_program_draft', { program_payload: payload, request_idempotency_key: `w07-save-${randomUUID()}` });
    expect(saved.error).toBeNull();
    expect((await service.from('programs').select('default_verification_mode').eq('id', programId).single()).data?.default_verification_mode).toBe('automatic');
    expect((await service.from('program_questions').select('analysis_mode,analysis_rubric_version').eq('id', questionId).single()).data).toEqual({ analysis_mode: 'food', analysis_rubric_version: 'rubric_food_v1' });
    expect((await participantClient.rpc('save_admin_program_draft', { program_payload: payload, request_idempotency_key: `w07-forged-${randomUUID()}` })).error?.message).toContain('permission_denied');
    expect((await adminClient.from('programs').update({ title: 'Direct unsafe write' }).eq('id', programId)).error).not.toBeNull();

    const publishKey = `w07-publish-${randomUUID()}`;
    expect((await adminClient.rpc('publish_program', { target_program_id: programId, request_idempotency_key: publishKey })).error).toBeNull();
    expect((await adminClient.rpc('publish_program', { target_program_id: programId, request_idempotency_key: publishKey })).error).toBeNull();
    expect((await service.from('programs').select('status').eq('id', programId).single()).data?.status).toBe('active');

    const duplicateKey = `w07-duplicate-${randomUUID()}`;
    expect((await adminClient.rpc('duplicate_admin_program_as_draft', { target_program_id: duplicateId, source_program_id: programId, target_title: 'Program W07 Salinan', target_start_date: date(7), request_idempotency_key: duplicateKey })).error).toBeNull();
    expect((await adminClient.rpc('duplicate_admin_program_as_draft', { target_program_id: duplicateId, source_program_id: programId, target_title: 'Program W07 Salinan', target_start_date: date(7), request_idempotency_key: duplicateKey })).error).toBeNull();
    const duplicatedQuestion = await service.from('program_questions').select('id,analysis_mode,analysis_rubric_version,program_steps!inner(program_days!inner(program_id))').eq('program_steps.program_days.program_id', duplicateId);
    expect(duplicatedQuestion.error).toBeNull(); expect(duplicatedQuestion.data).toHaveLength(1);
    expect(duplicatedQuestion.data?.[0]).toMatchObject({ analysis_mode: 'food', analysis_rubric_version: 'rubric_food_v1' });
    expect(duplicatedQuestion.data?.[0]?.id).not.toBe(questionId);
    expect((await service.from('programs').select('default_verification_mode').eq('id', duplicateId).single()).data?.default_verification_mode).toBe('automatic');

    expect((await adminClient.rpc('admin_enroll_participant', { target_participant_id: participant.id, target_program_id: programId, reason: 'Enrollment setelah cutoff untuk verifikasi pembayaran lokal.' })).error).toBeNull();
    const enrollment = (await service.from('program_enrollments').select('id,status').eq('program_id', programId).eq('participant_id', participant.id).single()).data!;
    expect(enrollment.status).toBe('active');
    expect((await participantClient.from('program_scores').update({ adjustment_points: 999 }).eq('enrollment_id', enrollment.id)).error).not.toBeNull();
    expect((await adminClient.rpc('admin_adjust_score', { target_enrollment_id: enrollment.id, points: 5, reason: 'Koreksi poin operasional W07.', request_idempotency_key: `w07-score-${randomUUID()}` })).error).toBeNull();
    expect((await service.from('program_scores').select('adjustment_points').eq('enrollment_id', enrollment.id).single()).data?.adjustment_points).toBe(5);

    expect((await service.from('step_submissions').insert([
      { id: articleSubmissionId, enrollment_id: enrollment.id, step_id: articleStepId, status: 'approved', idempotency_key: `w07-article-${randomUUID()}`, finalized_at: new Date().toISOString() },
      { id: foodSubmissionId, enrollment_id: enrollment.id, step_id: foodStepId, status: 'draft', idempotency_key: foodSubmissionKey },
    ])).error).toBeNull();
    privatePath = `${participant.id}/${enrollment.id}/${foodSubmissionId}/${questionId}/${randomUUID()}.jpg`;
    expect((await participantClient.storage.from('question-photos').upload(privatePath, new Blob([new Uint8Array([0xff, 0xd8, 0xff, 0xd9])], { type: 'image/jpeg' }), { contentType: 'image/jpeg' })).error).toBeNull();
    expect((await participantClient.rpc('submit_step_answers', { target_submission_id: foodSubmissionId, submitted_answers: [{ question_id: questionId, selected_option_ids: [], private_photo_path: privatePath }], request_idempotency_key: foodSubmissionKey })).error).toBeNull();

    expect((await adminClient.rpc('admin_enroll_participant', { target_participant_id: unrelated.id, target_program_id: programId, reason: 'Enrollment kedua untuk pengujian skor seri W07.' })).error).toBeNull();
    const secondEnrollment = (await service.from('program_enrollments').select('id').eq('program_id', programId).eq('participant_id', unrelated.id).single()).data!;
    expect((await adminClient.rpc('admin_adjust_score', { target_enrollment_id: secondEnrollment.id, points: 5, reason: 'Samakan skor untuk pengujian tie-break W07.', request_idempotency_key: `w07-score-tie-${randomUUID()}` })).error).toBeNull();
    expect((await service.from('step_submissions').insert([
      { enrollment_id: secondEnrollment.id, step_id: articleStepId, status: 'approved', idempotency_key: `w07-tie-article-${randomUUID()}`, finalized_at: new Date().toISOString() },
      { enrollment_id: secondEnrollment.id, step_id: foodStepId, status: 'approved', idempotency_key: `w07-tie-food-${randomUUID()}`, finalized_at: new Date().toISOString() },
    ])).error).toBeNull();

    expect((await adminClient.rpc('complete_program', { target_program_id: programId, reason: 'Program selesai untuk pengujian snapshot pemenang.', request_idempotency_key: `w07-complete-${randomUUID()}` })).error).toBeNull();
    const lockKey = `w07-lock-${randomUUID()}`;
    const locked = await adminClient.rpc('lock_program_winners', { target_program_id: programId, request_idempotency_key: lockKey });
    expect(locked.error).toBeNull(); expect(locked.data).toHaveLength(2);
    expect(locked.data?.[0]?.total_points).toBe(locked.data?.[1]?.total_points);
    const lockedTotal = locked.data?.[0]?.total_points;
    expect((await service.from('program_scores').update({ adjustment_points: 500 }).eq('enrollment_id', enrollment.id)).error).toBeNull();
    const repeatedLock = await adminClient.rpc('lock_program_winners', { target_program_id: programId, request_idempotency_key: lockKey });
    expect(repeatedLock.error).toBeNull(); expect(repeatedLock.data?.[0]?.total_points).toBe(lockedTotal);

    const itemId = randomUUID();
    expect((await service.from('coach_public_profile_items').insert({ id: itemId, coach_user_id: coach.id, item_kind: 'testimonial', title: 'Testimoni W07', body: 'Cerita lokal untuk moderasi.', includes_third_party: true, permission_attested: true, moderation_status: 'pending' })).error).toBeNull();
    expect((await participantClient.rpc('list_admin_profile_moderation_items')).error?.message).toContain('permission_denied');
    expect((await adminClient.rpc('moderate_coach_public_profile_item', { target_item_id: itemId, decision: 'approved', note: '' })).error).not.toBeNull();
    expect((await adminClient.rpc('moderate_admin_coach_profile_item', { target_item_id: itemId, expected_version: 1, decision: 'rejected', note: '', request_idempotency_key: `w07-moderate-empty-${randomUUID()}` })).error?.message).toContain('reason_required');
    const moderationKey = `w07-moderate-${randomUUID()}`;
    expect((await adminClient.rpc('moderate_admin_coach_profile_item', { target_item_id: itemId, expected_version: 1, decision: 'rejected', note: 'Identitas subjek perlu disamarkan sebelum publikasi.', request_idempotency_key: moderationKey })).error).toBeNull();
    expect((await adminClient.rpc('moderate_admin_coach_profile_item', { target_item_id: itemId, expected_version: 1, decision: 'rejected', note: 'Identitas subjek perlu disamarkan sebelum publikasi.', request_idempotency_key: moderationKey })).error).toBeNull();

    const submissionId = foodSubmissionId; const answerId = (await service.from('step_submission_answers').select('id').eq('submission_id', submissionId).single()).data!.id; const jobId = randomUUID(); const resultId = randomUUID();
    expect((await service.from('food_insight_jobs').insert({ id: jobId, submission_id: submissionId, answer_id: answerId, question_id: questionId, analysis_version: 'food_insight_v1', rubric: 'Rubrik privat tidak boleh tampil.', rubric_version: 'rubric_food_v1', status: 'completed', attempt_count: 1, completed_at: new Date().toISOString() })).error).toBeNull();
    expect((await service.from('food_insight_results').insert({ id: resultId, job_id: jobId, submission_id: submissionId, question_id: questionId, analysis_version: 'food_insight_v1', policy_version: 'food_rating_policy_v1', output_policy_version: 'food_insight_output_v1', provider_name: 'fake', model_alias: 'fixture-admin-w07', detected_kind: 'food', ai_rating: 4, effective_rating: 4, confidence: 0.8, reason_code: 'plausible_food', insight_sentences: ['Pilihan tampak cukup sesuai dengan panduan program.'] })).error).toBeNull();
    const aiProjection = await adminClient.rpc('list_admin_food_insight_operations');
    expect(aiProjection.error).toBeNull();
    const targetProjection = (aiProjection.data as Array<Record<string, unknown>>).find((row) => row.job_id === jobId);
    const projectionText = JSON.stringify(targetProjection);
    expect(projectionText).not.toContain(privatePath); expect(projectionText).not.toContain('Rubrik privat'); expect(projectionText).not.toContain('private_photo_path');
    const scoreBeforeCorrection = (await service.from('program_scores').select('activity_points,quiz_points,weight_points,adjustment_points').eq('enrollment_id', enrollment.id).single()).data;
    expect((await adminClient.rpc('correct_food_insight_rating', { target_result_id: resultId, expected_version: 1, corrected_rating: 5, correction_reason: 'Komposisi sesuai rubric yang diterbitkan.', request_idempotency_key: `w07-ai-correction-${randomUUID()}` })).error).toBeNull();
    expect((await service.from('program_scores').select('activity_points,quiz_points,weight_points,adjustment_points').eq('enrollment_id', enrollment.id).single()).data).toEqual(scoreBeforeCorrection);

    const dashboard = await adminClient.rpc('get_admin_dashboard'); expect(dashboard.error).toBeNull(); expect(dashboard.data).toHaveProperty('program_counts');
    expect((await participantClient.rpc('get_admin_dashboard')).error?.message).toContain('permission_denied');
    const peopleProjection = await adminClient.rpc('list_admin_people');
    expect(peopleProjection.data?.some((row: unknown) => (row as { user_id?: string }).user_id === participant.id)).toBe(true);
    expect(JSON.stringify(peopleProjection.data)).not.toContain('+6281234567007');
    expect(JSON.stringify((await adminClient.rpc('get_admin_person_detail', { target_user_id: participant.id })).data)).toContain('+6281234567007');
    const archiveKey = `w07-archive-${randomUUID()}`;
    expect((await adminClient.rpc('archive_admin_program', { target_program_id: programId, reason: 'Program selesai dan disimpan pada arsip operasional.', request_idempotency_key: archiveKey })).error).toBeNull();
    expect((await adminClient.rpc('archive_admin_program', { target_program_id: programId, reason: 'Program selesai dan disimpan pada arsip operasional.', request_idempotency_key: archiveKey })).error).toBeNull();
    const auditKinds = (await service.from('audit_events').select('kind').eq('actor_id', admin.id)).data?.map((event) => event.kind) ?? [];
    for (const kind of ['program_published', 'program_completed', 'winners_locked', 'score_adjusted', 'coach_profile_item_moderated', 'food_insight_rating_corrected', 'program_archived']) expect(auditKinds).toContain(kind);
  } finally {
    await service.storage.from('public-media').remove([mediaPath]);
    if (privatePath) await service.storage.from('question-photos').remove([privatePath]);
    await service.from('program_enrollments').delete().in('program_id', createdPrograms);
    await service.from('programs').delete().in('id', createdPrograms);
    for (const identity of identities) await service.auth.admin.deleteUser(identity.id);
  }
});

async function createIdentity(service: SupabaseClient, label: string) {
  const suffix = randomUUID(); const email = `${label}-${suffix}@test.invalid`; const password = `W07-${suffix}!`;
  const response = await service.auth.admin.createUser({ email, password, email_confirm: true });
  expect(response.error).toBeNull(); return { id: response.data.user!.id, email, password };
}
async function activateProfile(service: SupabaseClient, id: string, role: 'participant' | 'coach' | 'admin', displayName: string) { expect((await service.from('profiles').update({ role, display_name: displayName, onboarding_status: 'active', provisional_expires_at: null, finalized_at: new Date().toISOString() }).eq('user_id', id)).error).toBeNull(); }
async function activateCoach(service: SupabaseClient, coachId: string, adminId: string) {
  const applicationId = randomUUID(); const paymentId = randomUUID();
  expect((await service.from('coach_applications').insert({ id: applicationId, applicant_user_id: coachId, participant_profile_id: coachId, display_name_snapshot: 'Coach W07', phone_number_snapshot: '+6281200000700', member_level_snapshot: 'sc', has_completed_hom_sts: true, has_completed_ict: true, terms_version: 'w07-v1', status: 'active', draft_idempotency_key: `w07-coach-${randomUUID()}`, submitted_at: new Date().toISOString(), decided_at: new Date().toISOString(), decided_by: adminId })).error).toBeNull();
  expect((await service.from('coach_payment_records').insert({ id: paymentId, application_id: applicationId, state: 'verified', price_band: 'entry', amount_minor_units: 100_000, duration_months: 3, provider_reference: `w07-${randomUUID()}`, verified_at: new Date().toISOString() })).error).toBeNull();
  expect((await service.from('coach_access_entitlements').insert({ application_id: applicationId, payment_record_id: paymentId, coach_user_id: coachId, status: 'active', starts_at: new Date(Date.now() - 60_000).toISOString(), ends_at: new Date(Date.now() + 90 * 86_400_000).toISOString() })).error).toBeNull();
}
async function signIn(identity: { email: string; password: string }) { const client = createClient(localUrl as string, publishableKey as string, { auth: { persistSession: false, autoRefreshToken: false } }); expect((await client.auth.signInWithPassword({ email: identity.email, password: identity.password })).error).toBeNull(); return client; }
function date(offset: number) { return new Date(Date.now() + offset * 86_400_000).toISOString().slice(0, 10); }
function programPayload({ programId, dayId, articleStepId, foodStepId, questionId, adminId, mediaPath }: Record<string, string>) { return { id: programId, title: 'Program Admin W07', summary: 'Program lokal lengkap untuk authority Admin.', category: 'Transformasi', cover_path: mediaPath, cover_alt_text: 'Cover Program Admin W07', pace: 'scheduled', duration_mode: 'specific_dates', starts_on: date(0), ends_on: date(1), timezone: 'Asia/Makassar', participant_limit: 20, registration_closes_at: new Date(Date.now() - 60_000).toISOString(), past_step_policy: 'available', future_step_policy: 'locked', wellness_disclaimer: 'Program wellness non-diagnostik.', points_per_activity: 10, points_per_weight_kg: 0, quiz_passing_percentage: 70, default_verification_mode: 'automatic', pricing_mode: 'free', desired_price: null, created_by: adminId, days: [{ id: dayId, day_number: 1, title: 'Hari pertama', summary: 'Mulai', scheduled_on: date(0), steps: [{ id: articleStepId, step_order: 1, title: 'Bacaan W07', instructions: 'Baca materi.', content_kind: 'article', completion_policy: 'mark_complete', verification_mode: 'automatic', questions: [] }, { id: foodStepId, step_order: 2, title: 'Foto makanan W07', instructions: 'Unggah foto.', content_kind: 'form', completion_policy: 'answer_all_questions', verification_mode: 'automatic', questions: [{ id: questionId, question_order: 1, kind: 'photo_upload', prompt: 'Foto makanan', analysis_mode: 'food', analysis_rubric: 'Tampilkan sumber protein dan sayur.', analysis_rubric_version: 'rubric_food_v1', options: [] }] }] }] }; }
