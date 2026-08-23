import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { randomUUID } from 'node:crypto';
import { expect, it } from 'vitest';

const localUrl = process.env.API_URL;
const publishableKey = process.env.PUBLISHABLE_KEY ?? process.env.ANON_KEY;
const secretKey = process.env.SECRET_KEY ?? process.env.SERVICE_ROLE_KEY;
const canRun = Boolean(localUrl && publishableKey && secretKey);

it.runIf(canRun)('reconciles one durable job, enforces RLS, retries safely, and audits concurrent correction', async () => {
  expect(['127.0.0.1', 'localhost']).toContain(new URL(localUrl as string).hostname);
  const service = createClient(localUrl as string, secretKey as string, { auth: { persistSession: false, autoRefreshToken: false } });
  const identities: Array<{ id: string; email: string; password: string }> = [];
  const programId = randomUUID();
  const uploadedPaths: string[] = [];
  try {
    const [participantA, participantB, coachA, coachB, authorizedAdmin] = await Promise.all([
      createIdentity(service, 'food-participant-a'), createIdentity(service, 'food-participant-b'),
      createIdentity(service, 'food-coach-a'), createIdentity(service, 'food-coach-b'),
      createIdentity(service, 'food-admin'),
    ]);
    identities.push(participantA, participantB, coachA, coachB, authorizedAdmin);
    await Promise.all([
      activateProfile(service, participantA.id, 'participant', 'Peserta Insight A'),
      activateProfile(service, participantB.id, 'participant', 'Peserta Insight B'),
      activateProfile(service, coachA.id, 'coach', 'Coach Insight A'),
      activateProfile(service, coachB.id, 'coach', 'Coach Insight B'),
      activateProfile(service, authorizedAdmin.id, 'admin', 'Admin Insight'),
    ]);
    const admin = await service.from('profiles').select('user_id').eq('role', 'admin').limit(1).single();
    expect(admin.error).toBeNull();
    const adminId = admin.data?.user_id; expect(adminId).toBeTruthy();
    const dayId = randomUUID(); const stepId = randomUUID(); const questionId = randomUUID();
    const nonFoodStepId = randomUUID(); const nonFoodQuestionId = randomUUID();
    const enrollmentA = randomUUID(); const enrollmentB = randomUUID();
    const submissionA = randomUUID(); const submissionB = randomUUID(); const nonFoodSubmissionA = randomUUID();
    expect((await service.from('programs').insert({ id: programId, title: 'Program Insight W06.5', summary: 'Fixture lokal AI sekunder.', status: 'active', pace: 'scheduled', duration_mode: 'specific_dates', starts_on: date(-1), ends_on: date(1), timezone: 'Asia/Makassar', past_step_policy: 'read_only', future_step_policy: 'locked', wellness_disclaimer: 'Program wellness non-diagnostik.', points_per_activity: 10, points_per_weight_kg: 100, quiz_passing_percentage: 70, pricing_mode: 'free', published_at: new Date().toISOString(), created_by: adminId as string })).error).toBeNull();
    expect((await service.from('program_days').insert({ id: dayId, program_id: programId, day_number: 1, title: 'Foto makanan', scheduled_on: date(0) })).error).toBeNull();
    expect((await service.from('program_steps').insert([
      { id: stepId, program_day_id: dayId, step_order: 1, title: 'Catat pilihan makan', instructions: 'Unggah foto makanan.', content_kind: 'form', completion_policy: 'answer_all_questions', verification_mode: 'automatic' },
      { id: nonFoodStepId, program_day_id: dayId, step_order: 2, title: 'Unggah foto aktivitas', instructions: 'Unggah foto non-makanan.', content_kind: 'form', completion_policy: 'answer_all_questions', verification_mode: 'coach_review' },
    ])).error).toBeNull();
    expect((await service.from('program_questions').insert([
      { id: questionId, step_id: stepId, question_order: 1, kind: 'photo_upload', prompt: 'Foto pilihan makan', analysis_mode: 'food', analysis_rubric: 'Foto harus menampilkan makanan dengan sumber protein dan sayur.', analysis_rubric_version: 'rubric_food_v1' },
      { id: nonFoodQuestionId, step_id: nonFoodStepId, question_order: 1, kind: 'photo_upload', prompt: 'Foto aktivitas', analysis_mode: 'none' },
    ])).error).toBeNull();
    expect((await service.from('program_enrollments').insert([
      { id: enrollmentA, program_id: programId, participant_id: participantA.id, coach_id: coachA.id, status: 'active' },
      { id: enrollmentB, program_id: programId, participant_id: participantB.id, coach_id: coachB.id, status: 'active' },
    ])).error).toBeNull();
    expect((await service.from('program_scores').insert([{ enrollment_id: enrollmentA }, { enrollment_id: enrollmentB }])).error).toBeNull();
    expect((await service.from('step_submissions').insert([
      { id: submissionA, enrollment_id: enrollmentA, step_id: stepId, status: 'draft', idempotency_key: `food-${submissionA}` },
      { id: submissionB, enrollment_id: enrollmentB, step_id: stepId, status: 'draft', idempotency_key: `food-${submissionB}` },
      { id: nonFoodSubmissionA, enrollment_id: enrollmentA, step_id: nonFoodStepId, status: 'draft', idempotency_key: `photo-${nonFoodSubmissionA}` },
    ])).error).toBeNull();
    const photoA = `${participantA.id}/${enrollmentA}/${submissionA}/${questionId}/${randomUUID()}.jpg`;
    const photoB = `${participantB.id}/${enrollmentB}/${submissionB}/${questionId}/${randomUUID()}.jpg`;
    const nonFoodPhotoA = `${participantA.id}/${enrollmentA}/${nonFoodSubmissionA}/${nonFoodQuestionId}/${randomUUID()}.jpg`;
    uploadedPaths.push(photoA, photoB, nonFoodPhotoA);
    for (const path of uploadedPaths) expect((await service.storage.from('question-photos').upload(path, new Blob([new Uint8Array([0xff, 0xd8, 0xff, 0xd9])], { type: 'image/jpeg' }), { contentType: 'image/jpeg' })).error).toBeNull();
    const [participantClientA, participantClientB] = await Promise.all([signIn(participantA), signIn(participantB)]);
    expect((await participantClientA.rpc('submit_step_answers', { target_submission_id: submissionA, submitted_answers: [{ question_id: questionId, selected_option_ids: [], private_photo_path: photoA }], request_idempotency_key: `food-${submissionA}` })).error).toBeNull();
    expect((await participantClientB.rpc('submit_step_answers', { target_submission_id: submissionB, submitted_answers: [{ question_id: questionId, selected_option_ids: [], private_photo_path: photoB }], request_idempotency_key: `food-${submissionB}` })).error).toBeNull();
    expect((await participantClientA.rpc('submit_step_answers', { target_submission_id: nonFoodSubmissionA, submitted_answers: [{ question_id: nonFoodQuestionId, selected_option_ids: [], private_photo_path: nonFoodPhotoA }], request_idempotency_key: `photo-${nonFoodSubmissionA}` })).error).toBeNull();
    expect((await service.from('step_submissions').select('status').in('id', [submissionA, submissionB])).data?.every((submission) => submission.status === 'approved')).toBe(true);
    expect((await service.from('program_scores').select('activity_points').in('enrollment_id', [enrollmentA, enrollmentB])).data?.every((score) => score.activity_points === 10)).toBe(true);

    const firstReconcile = await service.rpc('reconcile_food_insight_jobs', { target_analysis_version: 'food_insight_v1' });
    expect(firstReconcile.error).toBeNull(); expect(firstReconcile.data).toBe(2);
    expect((await service.from('food_insight_jobs').select('id').eq('submission_id', nonFoodSubmissionA)).data).toHaveLength(0);
    expect((await service.rpc('reconcile_food_insight_jobs', { target_analysis_version: 'food_insight_v1' })).data).toBe(0);

    const claimed = await service.rpc('claim_food_insight_job', { lease_seconds: 90, target_submission_id: submissionA });
    expect(claimed.error).toBeNull();
    const job = claimed.data as { id: string; lease_token: string };
    for (const forbidden of ['submission_id', 'question_id', 'analysis_version', 'rubric', 'rubric_version']) {
      expect(claimed.data).not.toHaveProperty(forbidden);
    }
    const completed = await service.rpc('complete_food_insight_job', { target_job_id: job.id, target_lease_token: job.lease_token, provider_name: 'fake', model_alias: 'deterministic-food-fixture-v1', validated_result: { detected_kind: 'food', protein_grams: 25, carbohydrate_grams: 40, fat_grams: 12, calorie_kcal: 390, rating: 4, confidence: 0.84, reason_code: 'food_or_drink_detected', insight_sentences: ['Foto tampak menunjukkan satu porsi makanan.'] } });
    expect(completed.error).toBeNull();
    expect((await service.from('food_insight_results').select('id').eq('submission_id', submissionA)).data).toHaveLength(1);
    const completedSubmission = submissionA;
    const completedEnrollment = completedSubmission === submissionA ? enrollmentA : enrollmentB;
    const owner = completedSubmission === submissionA ? participantA : participantB;
    const assignedCoach = completedSubmission === submissionA ? coachA : coachB;
    const unrelatedParticipant = completedSubmission === submissionA ? participantB : participantA;
    const unrelatedCoach = completedSubmission === submissionA ? coachB : coachA;

    const [ownerClient, coachClient, otherParticipantClient, otherCoachClient, adminClient] = await Promise.all([
      signIn(owner), signIn(assignedCoach), signIn(unrelatedParticipant), signIn(unrelatedCoach), signIn(authorizedAdmin),
    ]);
    expect((await ownerClient.from('food_insight_results').select('id,effective_rating,version')).data).toHaveLength(1);
    expect((await coachClient.from('food_insight_results').select('id,effective_rating,version')).data).toHaveLength(1);
    expect((await otherParticipantClient.from('food_insight_results').select('id')).data).toHaveLength(0);
    expect((await otherCoachClient.from('food_insight_results').select('id')).data).toHaveLength(0);
    expect((await adminClient.from('food_insight_results').select('id').eq('submission_id', completedSubmission)).data).toHaveLength(1);
    const guest = createClient(localUrl as string, publishableKey as string, { auth: { persistSession: false, autoRefreshToken: false } });
    expect((await guest.from('food_insight_results').select('id')).error).not.toBeNull();

    const result = (await coachClient.from('food_insight_results').select('id,effective_rating,version').single()).data!;
    const correctionKey = `correction-${randomUUID()}`;
    const correction = await coachClient.rpc('correct_food_insight_rating', { target_result_id: result.id, expected_version: result.version, corrected_rating: 5, correction_reason: 'Komposisi sesuai rubric yang diterbitkan.', request_idempotency_key: correctionKey });
    expect(correction.error).toBeNull();
    const repeated = await coachClient.rpc('correct_food_insight_rating', { target_result_id: result.id, expected_version: result.version, corrected_rating: 5, correction_reason: 'Komposisi sesuai rubric yang diterbitkan.', request_idempotency_key: correctionKey });
    expect(repeated.error).toBeNull();
    const stale = await coachClient.rpc('correct_food_insight_rating', { target_result_id: result.id, expected_version: result.version, corrected_rating: 3, correction_reason: 'Simulasi perubahan dari perangkat lain.', request_idempotency_key: `correction-${randomUUID()}` });
    expect(stale.error?.message).toContain('correction_conflict');
    expect((await service.from('audit_events').select('id').eq('subject_id', result.id).eq('kind', 'food_insight_rating_corrected')).data).toHaveLength(1);
    const score = await service.from('program_scores').select('activity_points,quiz_points,weight_points,adjustment_points').eq('enrollment_id', completedEnrollment).single();
    expect(score.data).toEqual({ activity_points: 10, quiz_points: 0, weight_points: 0, adjustment_points: 0 });

    expect((await service.from('program_questions').update({ analysis_mode: 'none', analysis_rubric: null, analysis_rubric_version: null }).eq('id', questionId)).error).toBeNull();
    const disabledClaim = await service.rpc('claim_food_insight_job', { lease_seconds: 90, target_submission_id: submissionB });
    expect(disabledClaim.error).toBeNull();
    expect(disabledClaim.data).toBeNull();
    expect((await service.rpc('reconcile_food_insight_jobs', { target_analysis_version: 'food_insight_v1' })).data).toBe(0);
    expect((await service.from('food_insight_jobs').select('status,terminal_error_code').eq('submission_id', submissionB).single()).data).toEqual({ status: 'unavailable', terminal_error_code: 'configuration_invalid' });

    expect((await service.from('program_questions').update({ analysis_mode: 'food', analysis_rubric: 'Foto harus menampilkan makanan dengan sumber protein dan sayur.', analysis_rubric_version: 'rubric_food_v1' }).eq('id', questionId)).error).toBeNull();
    expect((await service.from('food_insight_jobs').update({ status: 'queued', terminal_error_code: null }).eq('submission_id', submissionB)).error).toBeNull();
    const second = await service.rpc('claim_food_insight_job', { lease_seconds: 90, target_submission_id: submissionB });
    const retryJob = second.data as { id: string; lease_token: string };
    expect((await service.rpc('fail_food_insight_job', { target_job_id: retryJob.id, target_lease_token: retryJob.lease_token, error_code: 'rate_limited', retryable: true })).data).toBe('retry_scheduled');
    expect((await service.from('food_insight_jobs').select('status').eq('id', retryJob.id).single()).data?.status).toBe('retry_scheduled');
  } finally {
    if (uploadedPaths.length) await service.storage.from('question-photos').remove(uploadedPaths);
    await service.from('program_enrollments').delete().eq('program_id', programId);
    await service.from('programs').delete().eq('id', programId);
    for (const identity of identities) await service.auth.admin.deleteUser(identity.id);
  }
});

async function createIdentity(service: SupabaseClient, label: string) {
  const suffix = randomUUID(); const email = `${label}-${suffix}@test.invalid`; const password = `Food-${suffix}!`;
  const response = await service.auth.admin.createUser({ email, password, email_confirm: true });
  expect(response.error).toBeNull(); return { id: response.data.user!.id, email, password };
}
async function activateProfile(service: SupabaseClient, id: string, role: 'participant' | 'coach' | 'admin', displayName: string) {
  const response = await service.from('profiles').update({ role, display_name: displayName, coach_is_approved: role === 'coach', onboarding_status: 'active', provisional_expires_at: null, finalized_at: new Date().toISOString() }).eq('user_id', id);
  expect(response.error).toBeNull();
}
async function signIn(identity: { email: string; password: string }) {
  const client = createClient(localUrl as string, publishableKey as string, { auth: { persistSession: false, autoRefreshToken: false } });
  expect((await client.auth.signInWithPassword({ email: identity.email, password: identity.password })).error).toBeNull(); return client;
}
function date(offset: number) {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Makassar',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(new Date(Date.now() + offset * 86_400_000));
}
