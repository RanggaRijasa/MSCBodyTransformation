import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { randomUUID } from 'node:crypto';
import { expect, it } from 'vitest';

const localUrl = process.env.API_URL;
const publishableKey = process.env.PUBLISHABLE_KEY ?? process.env.ANON_KEY;
const secretKey = process.env.SECRET_KEY ?? process.env.SERVICE_ROLE_KEY;
const canRun = Boolean(localUrl && publishableKey && secretKey);

it.runIf(canRun)('persists prompt video and accepts a private Participant video answer', async () => {
  expect(['127.0.0.1', 'localhost']).toContain(new URL(localUrl as string).hostname);
  const service = createClient(localUrl as string, secretKey as string, { auth: { persistSession: false, autoRefreshToken: false } });
  const adminIdentity = await createIdentity(service, 'admin-video');
  const participantIdentity = await createIdentity(service, 'participant-video');
  const coachIdentity = await createIdentity(service, 'coach-video');
  const programId = randomUUID();
  const dayId = randomUUID();
  const stepId = randomUUID();
  const questionId = randomUUID();
  const enrollmentId = randomUUID();
  const promptMediaPath = `questions/${randomUUID()}.mp4`;
  let privateVideoPath: string | undefined;

  try {
    await activateProfile(service, adminIdentity.id, 'admin');
    await activateProfile(service, participantIdentity.id, 'participant');
    await activateProfile(service, coachIdentity.id, 'coach');
    const admin = await signIn(adminIdentity.email, adminIdentity.password);
    const participant = await signIn(participantIdentity.email, participantIdentity.password);

    expect((await admin.storage.from('program-question-media').upload(
      promptMediaPath,
      new Blob([new Uint8Array([0, 0, 0, 24])], { type: 'video/mp4' }),
      { contentType: 'video/mp4', upsert: false },
    )).error).toBeNull();

    const saved = await admin.rpc('save_admin_program_draft', {
      program_payload: programPayload({ programId, dayId, stepId, questionId, promptMediaPath }),
      request_idempotency_key: `video-program-${randomUUID()}`,
    });
    expect(saved.error).toBeNull();
    expect((await service.from('program_questions').select('kind,media_kind,media_path,media_alt_text').eq('id', questionId).single()).data).toEqual({
      kind: 'video_upload',
      media_kind: 'video',
      media_path: promptMediaPath,
      media_alt_text: 'Contoh posisi tubuh untuk video timbang awal.',
    });

    expect((await admin.rpc('publish_program', { target_program_id: programId, request_idempotency_key: `video-publish-${randomUUID()}` })).error).toBeNull();
    expect((await service.from('programs').update({ status: 'active' }).eq('id', programId)).error).toBeNull();
    const publicMedia = await participant.rpc('list_public_question_media', { target_question_ids: [questionId] });
    expect(publicMedia.error).toBeNull();
    expect(publicMedia.data).toEqual([expect.objectContaining({ id: questionId, media_kind: 'video', media_path: promptMediaPath })]);

    expect((await service.from('program_enrollments').insert({
      id: enrollmentId,
      program_id: programId,
      participant_id: participantIdentity.id,
      coach_id: coachIdentity.id,
      status: 'active',
    })).error).toBeNull();
    const prepared = await participant.rpc('prepare_step_submission', {
      target_enrollment_id: enrollmentId,
      target_step_id: stepId,
      request_idempotency_key: `video-submit-${randomUUID()}`,
    });
    expect(prepared.error).toBeNull();
    const preparedRow = Array.isArray(prepared.data) ? prepared.data[0] : prepared.data;
    const submissionId = (preparedRow as { id: string }).id;
    privateVideoPath = `${participantIdentity.id}/${enrollmentId}/${submissionId}/${questionId}/${randomUUID()}.mp4`;
    expect((await participant.storage.from('question-videos').upload(
      privateVideoPath,
      new Blob([new Uint8Array([0, 0, 0, 24])], { type: 'video/mp4' }),
      { contentType: 'video/mp4', upsert: false },
    )).error).toBeNull();

    const submitted = await participant.rpc('submit_step_answers', {
      target_submission_id: submissionId,
      submitted_answers: [{ question_id: questionId, selected_option_ids: [], private_video_path: privateVideoPath }],
      request_idempotency_key: (preparedRow as { idempotency_key: string }).idempotency_key,
    });
    expect(submitted.error).toBeNull();
    expect((await service.from('step_submission_answers').select('text_value,private_photo_path,private_video_path').eq('submission_id', submissionId).single()).data).toEqual({
      text_value: null,
      private_photo_path: null,
      private_video_path: privateVideoPath,
    });
    expect((await service.from('food_insight_jobs').select('id').eq('submission_id', submissionId)).data).toHaveLength(0);
  } finally {
    if (privateVideoPath) await service.storage.from('question-videos').remove([privateVideoPath]);
    await service.storage.from('program-question-media').remove([promptMediaPath]);
    await service.from('programs').delete().eq('id', programId);
    for (const identity of [participantIdentity, coachIdentity, adminIdentity]) await service.auth.admin.deleteUser(identity.id);
  }

  async function signIn(email: string, password: string) {
    const client = createClient(localUrl as string, publishableKey as string, { auth: { persistSession: false, autoRefreshToken: false } });
    expect((await client.auth.signInWithPassword({ email, password })).error).toBeNull();
    return client;
  }
});

async function createIdentity(service: SupabaseClient, label: string) {
  const suffix = randomUUID();
  const email = `${label}-${suffix}@test.invalid`;
  const password = `Video-${suffix}!`;
  const response = await service.auth.admin.createUser({ email, password, email_confirm: true });
  expect(response.error).toBeNull();
  return { id: response.data.user!.id, email, password };
}

async function activateProfile(service: SupabaseClient, id: string, role: 'participant' | 'coach' | 'admin') {
  expect((await service.from('profiles').update({
    role,
    display_name: `${role} video test`,
    onboarding_status: 'active',
    provisional_expires_at: null,
    finalized_at: new Date().toISOString(),
  }).eq('user_id', id)).error).toBeNull();
}

function programPayload({ programId, dayId, stepId, questionId, promptMediaPath }: Record<string, string>) {
  const today = new Date().toISOString().slice(0, 10);
  return {
    id: programId,
    title: 'Program video lokal',
    summary: 'Program untuk menguji jawaban video privat.',
    category: 'Transformasi',
    cover_path: 'programs/video-test.jpg',
    cover_alt_text: 'Cover program video lokal.',
    pace: 'scheduled',
    duration_mode: 'specific_dates',
    starts_on: today,
    ends_on: today,
    timezone: 'Asia/Makassar',
    participant_limit: 10,
    registration_closes_at: null,
    past_step_policy: 'available',
    future_step_policy: 'available',
    wellness_disclaimer: 'Program wellness non-diagnostik.',
    points_per_activity: 10,
    points_per_weight_kg: 0,
    quiz_passing_percentage: 70,
    default_verification_mode: 'coach_review',
    pricing_mode: 'free',
    desired_price: null,
    days: [{
      id: dayId,
      day_number: 1,
      title: 'Hari video',
      summary: 'Kirim bukti video.',
      scheduled_on: today,
      steps: [{
        id: stepId,
        step_order: 1,
        title: 'Video timbang awal',
        instructions: 'Rekam video sesuai panduan.',
        content_kind: 'form',
        completion_policy: 'answer_all_questions',
        verification_mode: 'coach_review',
        questions: [{
          id: questionId,
          question_order: 1,
          kind: 'video_upload',
          prompt: 'Unggah video timbang awal.',
          analysis_mode: 'none',
          analysis_rubric: null,
          analysis_rubric_version: null,
          media_kind: 'video',
          media_path: promptMediaPath,
          media_alt_text: 'Contoh posisi tubuh untuk video timbang awal.',
          options: [],
          answer_key: null,
        }],
      }],
    }],
  };
}
