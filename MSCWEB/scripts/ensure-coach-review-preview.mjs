import { readFile } from 'node:fs/promises';
import { randomUUID } from 'node:crypto';

import { createClient } from '@supabase/supabase-js';

const apiUrl = process.env.API_URL;
const publishableKey = process.env.PUBLISHABLE_KEY ?? process.env.ANON_KEY;
const secretKey = process.env.SECRET_KEY ?? process.env.SERVICE_ROLE_KEY;

if (!apiUrl || !publishableKey || !secretKey || !['127.0.0.1', 'localhost'].includes(new URL(apiUrl).hostname)) {
  throw new Error('Fixture Coach review hanya boleh dijalankan terhadap Supabase lokal.');
}

const service = createClient(apiUrl, secretKey, { auth: { persistSession: false, autoRefreshToken: false } });
const now = new Date();
const today = localDate(0);
const activeProgramId = '86060000-0000-4000-8000-000000000001';
const historyProgramId = '86060000-0000-4000-8000-000000000002';

const [{ data: entitlements, error: entitlementError }, { data: authUsers, error: authError }] = await Promise.all([
  service.from('coach_access_entitlements').select('coach_user_id').eq('status', 'active').lte('starts_at', now.toISOString()).gt('ends_at', now.toISOString()),
  service.auth.admin.listUsers({ page: 1, perPage: 1_000 }),
]);
assertNoError(entitlementError ?? authError);

const activeCoachIds = new Set((entitlements ?? []).map((row) => row.coach_user_id));
const signedInCoachIds = authUsers.users
  .filter((user) => activeCoachIds.has(user.id))
  .toSorted((left, right) => Date.parse(right.last_sign_in_at ?? right.created_at) - Date.parse(left.last_sign_in_at ?? left.created_at))
  .map((user) => user.id);
const requestedCoachId = process.env.COACH_PREVIEW_ID?.trim();
const coachId = requestedCoachId || signedInCoachIds[0];
if (!coachId) throw new Error('Coach lokal aktif yang pernah masuk tidak ditemukan.');
if (!activeCoachIds.has(coachId)) throw new Error('COACH_PREVIEW_ID bukan Coach lokal aktif.');

const photoParticipantEmail = 'mscweb-coach-review-photo@local.invalid';
const photoParticipantPassword = `W06-${randomUUID()}!`;
let photoParticipantId = authUsers.users.find((user) => user.email === photoParticipantEmail)?.id;
if (photoParticipantId) {
  assertNoError((await service.auth.admin.updateUserById(photoParticipantId, { password: photoParticipantPassword })).error);
} else {
  const created = await service.auth.admin.createUser({ email: photoParticipantEmail, password: photoParticipantPassword, email_confirm: true });
  assertNoError(created.error);
  photoParticipantId = created.data.user?.id;
}
if (!photoParticipantId) throw new Error('Participant foto lokal tidak dapat dibuat.');
await assertResponse(service.from('profiles').update({
  role: 'participant',
  display_name: 'Citra Dewi',
  city: 'Gianyar',
  current_coach_id: coachId,
  onboarding_status: 'active',
  provisional_expires_at: null,
  finalized_at: now.toISOString(),
}).eq('user_id', photoParticipantId));

const [{ data: admin }, { data: otherParticipants, error: participantError }] = await Promise.all([
  service.from('profiles').select('user_id').eq('role', 'admin').order('created_at').limit(1).maybeSingle(),
  service.from('profiles').select('user_id,display_name').eq('role', 'participant').neq('user_id', photoParticipantId).order('created_at').limit(2),
]);
assertNoError(participantError);
if (!admin?.user_id || !otherParticipants || otherParticipants.length < 2) throw new Error('Fixture memerlukan satu Admin dan tiga Participant lokal.');
const participants = [{ user_id: photoParticipantId, display_name: 'Citra Dewi' }, ...otherParticipants];

await upsert('programs', [
  {
    id: activeProgramId,
    title: 'Program uji periksa bukti',
    summary: 'Fixture lokal untuk antrean dan detail bukti Coach.',
    category: 'Pengujian lokal review',
    status: 'active',
    pace: 'scheduled',
    duration_mode: 'specific_dates',
    starts_on: localDate(-2),
    ends_on: localDate(20),
    timezone: 'Asia/Makassar',
    participant_limit: 100,
    past_step_policy: 'read_only',
    future_step_policy: 'locked',
    wellness_disclaimer: 'Fixture pengujian lokal.',
    points_per_activity: 10,
    points_per_weight_kg: 100,
    quiz_passing_percentage: 70,
    pricing_mode: 'free',
    desired_price: null,
    published_at: now.toISOString(),
    created_by: admin.user_id,
  },
  {
    id: historyProgramId,
    title: 'Program uji bukti selesai',
    summary: 'Fixture riwayat program Coach.',
    category: 'Pengujian lokal review',
    status: 'active',
    pace: 'scheduled',
    duration_mode: 'specific_dates',
    starts_on: localDate(-20),
    ends_on: localDate(-10),
    timezone: 'Asia/Makassar',
    participant_limit: 100,
    past_step_policy: 'read_only',
    future_step_policy: 'locked',
    wellness_disclaimer: 'Fixture pengujian lokal.',
    points_per_activity: 10,
    points_per_weight_kg: 100,
    quiz_passing_percentage: 70,
    pricing_mode: 'free',
    desired_price: null,
    published_at: now.toISOString(),
    created_by: admin.user_id,
  },
], 'id');

await upsert('program_days', [
  { id: '86060000-0000-4000-8000-000000000101', program_id: activeProgramId, day_number: 3, title: 'Kebiasaan sehat', scheduled_on: today },
  { id: '86060000-0000-4000-8000-000000000102', program_id: historyProgramId, day_number: 7, title: 'Penutup', scheduled_on: localDate(-10) },
], 'id');

await upsert('program_steps', [
  { id: '86060000-0000-4000-8000-000000000201', program_day_id: '86060000-0000-4000-8000-000000000101', step_order: 1, title: 'Pilihan makan seimbang', instructions: 'Pilih porsi makan yang beragam dan seimbang.', content_kind: 'form', completion_policy: 'answer_all_questions', verification_mode: 'coach_review' },
  { id: '86060000-0000-4000-8000-000000000202', program_day_id: '86060000-0000-4000-8000-000000000101', step_order: 2, title: 'Gerak pagi', instructions: 'Ceritakan aktivitas gerak yang sudah dilakukan pagi ini.', content_kind: 'form', completion_policy: 'answer_all_questions', verification_mode: 'coach_review' },
  { id: '86060000-0000-4000-8000-000000000203', program_day_id: '86060000-0000-4000-8000-000000000101', step_order: 3, title: 'Kuis hidrasi', instructions: 'Jawab kuis singkat tentang kebutuhan hidrasi.', content_kind: 'quiz', completion_policy: 'automatic_quiz', verification_mode: 'automatic' },
  { id: '86060000-0000-4000-8000-000000000204', program_day_id: '86060000-0000-4000-8000-000000000102', step_order: 1, title: 'Refleksi akhir', instructions: 'Tuliskan kebiasaan baik yang ingin dipertahankan.', content_kind: 'form', completion_policy: 'answer_all_questions', verification_mode: 'coach_review' },
], 'id');

await upsert('program_questions', [
  { id: '86060000-0000-4000-8000-000000000301', step_id: '86060000-0000-4000-8000-000000000201', question_order: 1, kind: 'photo_upload', prompt: 'Unggah foto pilihan makan Anda.' },
  { id: '86060000-0000-4000-8000-000000000302', step_id: '86060000-0000-4000-8000-000000000202', question_order: 1, kind: 'long_answer', prompt: 'Apa aktivitas gerak yang sudah dilakukan?' },
  { id: '86060000-0000-4000-8000-000000000303', step_id: '86060000-0000-4000-8000-000000000203', question_order: 1, kind: 'short_answer', prompt: 'Mengapa hidrasi penting?' },
  { id: '86060000-0000-4000-8000-000000000304', step_id: '86060000-0000-4000-8000-000000000204', question_order: 1, kind: 'long_answer', prompt: 'Kebiasaan apa yang ingin dipertahankan?' },
], 'id');

await assertResponse(service.from('profiles').update({ current_coach_id: coachId }).in('user_id', participants.map((participant) => participant.user_id)));

const enrollmentRows = [];
for (const [index, participant] of participants.entries()) {
  const programId = index === 2 ? historyProgramId : activeProgramId;
  const { data, error } = await service.from('program_enrollments').upsert({ program_id: programId, participant_id: participant.user_id, coach_id: coachId, status: programId === historyProgramId ? 'completed' : 'active', completed_at: programId === historyProgramId ? now.toISOString() : null }, { onConflict: 'program_id,participant_id' }).select('id').single();
  assertNoError(error);
  enrollmentRows.push({ ...data, participant });
  await upsert('program_scores', [{ enrollment_id: data.id, activity_points: index === 2 ? 10 : 0, quiz_points: 0, weight_points: 0, adjustment_points: 0, progress_percentage: index === 2 ? 100 : 35 }], 'enrollment_id');
}

const submissions = [
  await ensureSubmission(enrollmentRows[0].id, '86060000-0000-4000-8000-000000000201', 'draft', 9, null, 'w06-photo-preview'),
  await ensureSubmission(enrollmentRows[1].id, '86060000-0000-4000-8000-000000000202', 'pending', 15),
  await ensureSubmission(enrollmentRows[1].id, '86060000-0000-4000-8000-000000000203', 'approved', 30),
  await ensureSubmission(enrollmentRows[2].id, '86060000-0000-4000-8000-000000000204', 'rejected', 60, 'Jawaban perlu lebih spesifik sesuai petunjuk.'),
];

const photoQuestionId = '86060000-0000-4000-8000-000000000301';
const photoPath = `${enrollmentRows[0].participant.user_id}/${enrollmentRows[0].id}/${submissions[0].id}/${photoQuestionId}/86060000-0000-4000-8000-000000000401.jpg`;
const photo = await readFile(new URL('../public/images/coach-support.jpg', import.meta.url));
await assertResponse(service.from('step_submission_answers').delete().eq('submission_id', submissions[0].id).eq('question_id', photoQuestionId));
const photoParticipant = createClient(apiUrl, publishableKey, { auth: { persistSession: false, autoRefreshToken: false } });
assertNoError((await photoParticipant.auth.signInWithPassword({ email: photoParticipantEmail, password: photoParticipantPassword })).error);
assertNoError((await photoParticipant.storage.from('question-photos').upload(photoPath, photo, { contentType: 'image/jpeg', upsert: true })).error);
assertNoError((await photoParticipant.rpc('submit_step_answers', {
  target_submission_id: submissions[0].id,
  submitted_answers: [{ question_id: photoQuestionId, private_photo_path: photoPath, selected_option_ids: [] }],
  request_idempotency_key: 'w06-photo-preview',
})).error);

await upsert('step_submission_answers', [
  { submission_id: submissions[1].id, question_id: '86060000-0000-4000-8000-000000000302', text_value: 'Saya berjalan santai selama 20 menit sebelum memulai aktivitas.', selected_option_ids: [] },
  { submission_id: submissions[2].id, question_id: '86060000-0000-4000-8000-000000000303', text_value: 'Membantu tubuh menjaga fungsi normal selama beraktivitas.', selected_option_ids: [] },
  { submission_id: submissions[3].id, question_id: '86060000-0000-4000-8000-000000000304', text_value: 'Saya akan mempertahankan rutinitas sehat.', selected_option_ids: [] },
], 'submission_id,question_id');

await upsert('weigh_ins', [
  {
    id: '86060000-0000-4000-8000-000000000501',
    enrollment_id: enrollmentRows[0].id,
    step_id: '86060000-0000-4000-8000-000000000201',
    kind: 'initial',
    weight_kg: 70.25,
    recorded_at: new Date(now.getTime() - 3 * 86_400_000).toISOString(),
    idempotency_key: 'w06-participant-detail-initial',
  },
], 'id');

await upsert('quiz_attempt_results', [{ submission_id: submissions[2].id, correct_count: 1, total_count: 1, percentage: 100, passed: true, awarded_points: 10 }], 'submission_id');
await assertResponse(service.from('programs').update({ status: 'completed' }).eq('id', historyProgramId));

console.log(`Fixture periksa bukti siap untuk Coach ${coachId}: 2 perlu tindakan, 1 poin otomatis, 1 riwayat ditolak.`);

async function ensureSubmission(enrollmentId, stepId, status, minutesAgo, reviewNote = null, idempotencyKey = null) {
  const isReviewed = status === 'approved' || status === 'rejected';
  const reviewed = isReviewed ? new Date(now.getTime() - (minutesAgo - 1) * 60_000).toISOString() : null;
  const { data, error } = await service.from('step_submissions').upsert({
    enrollment_id: enrollmentId,
    step_id: stepId,
    attempt_sequence: 1,
    status,
    submitted_at: new Date(now.getTime() - minutesAgo * 60_000).toISOString(),
    reviewed_at: reviewed,
    reviewer_id: isReviewed ? coachId : null,
    review_note: reviewNote,
    idempotency_key: idempotencyKey,
  }, { onConflict: 'enrollment_id,step_id,attempt_sequence' }).select('id').single();
  assertNoError(error);
  return data;
}

async function upsert(table, rows, onConflict) {
  await assertResponse(service.from(table).upsert(rows, { onConflict }));
}

async function assertResponse(query) {
  const response = await query;
  assertNoError(response.error);
  return response;
}

function assertNoError(error) {
  if (error) throw error;
}

function localDate(offset) {
  const value = new Date(Date.now() + offset * 86_400_000);
  const parts = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Makassar', year: 'numeric', month: '2-digit', day: '2-digit' }).formatToParts(value);
  const get = (type) => parts.find((part) => part.type === type)?.value;
  return `${get('year')}-${get('month')}-${get('day')}`;
}
