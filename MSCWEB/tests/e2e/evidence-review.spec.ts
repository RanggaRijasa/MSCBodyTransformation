import { expect, test } from '@playwright/test';
import { createClient, type Session, type SupabaseClient } from '@supabase/supabase-js';
import { randomUUID } from 'node:crypto';
import { readFileSync } from 'node:fs';

const localUrl = process.env.API_URL;
const publishableKey = process.env.PUBLISHABLE_KEY ?? process.env.ANON_KEY;
const secretKey = process.env.SECRET_KEY ?? process.env.SERVICE_ROLE_KEY;
const canRun = localUrl !== undefined && publishableKey !== undefined && secretKey !== undefined;

let service: SupabaseClient;
let participantSession: Session;
let coachSession: Session;
let participantId = '';
let coachId = '';
let adminId = '';
let programId = '';
let stepId = '';
let enrollmentId = '';
let rejectStepId = '';

test.describe('W04 private evidence and Coach review', () => {
  test.beforeAll(async () => {
    if (!canRun) return;
    expect(['127.0.0.1', 'localhost']).toContain(new URL(localUrl as string).hostname);
    service = createClient(localUrl as string, secretKey as string, { auth: { persistSession: false, autoRefreshToken: false } });
    const admin = await createIdentity('w04-admin');
    const coach = await createIdentity('w04-coach');
    const participant = await createIdentity('w04-participant');
    adminId = admin.id;
    coachId = coach.id;
    participantId = participant.id;

    await updateProfile(adminId, { role: 'admin', display_name: 'Admin W04' });
    await updateProfile(coachId, { role: 'coach', display_name: 'Coach W04', coach_is_approved: true, coach_qr_identifier: `coach-${randomUUID()}` });
    await updateProfile(participantId, { role: 'participant', display_name: 'Peserta W04', current_coach_id: coachId });
    await activateCoach();

    programId = randomUUID();
    const dayId = randomUUID();
    stepId = randomUUID();
    rejectStepId = randomUUID();
    const questionId = randomUUID();
    const rejectQuestionId = randomUUID();
    enrollmentId = randomUUID();
    const today = localDate(0);
    expect((await service.from('programs').insert({
      id: programId,
      title: 'Program Bukti W04',
      summary: 'Program lokal untuk bukti pribadi dan review Coach.',
      category: 'Transformasi',
      status: 'active',
      pace: 'scheduled',
      duration_mode: 'specific_dates',
      starts_on: localDate(-1),
      ends_on: localDate(1),
      timezone: 'Asia/Makassar',
      past_step_policy: 'read_only',
      future_step_policy: 'locked',
      wellness_disclaimer: 'Program wellness non-diagnostik.',
      points_per_activity: 10,
      points_per_weight_kg: 100,
      quiz_passing_percentage: 70,
      pricing_mode: 'free',
      published_at: new Date().toISOString(),
      created_by: adminId,
    })).error).toBeNull();
    expect((await service.from('program_days').insert({ id: dayId, program_id: programId, day_number: 1, title: 'Bukti hari ini', scheduled_on: today })).error).toBeNull();
    expect((await service.from('program_steps').insert([
      { id: stepId, program_day_id: dayId, step_order: 1, title: 'Unggah bukti W04', instructions: 'Ambil foto yang jelas sesuai petunjuk.', content_kind: 'form', completion_policy: 'answer_all_questions', verification_mode: 'coach_review' },
      { id: rejectStepId, program_day_id: dayId, step_order: 2, title: 'Refleksi W04', instructions: 'Tuliskan refleksi singkat.', content_kind: 'form', completion_policy: 'answer_all_questions', verification_mode: 'coach_review' },
    ])).error).toBeNull();
    expect((await service.from('program_questions').insert([
      { id: questionId, step_id: stepId, question_order: 1, kind: 'photo_upload', prompt: 'Bukti foto aktivitas' },
      { id: rejectQuestionId, step_id: rejectStepId, question_order: 1, kind: 'long_answer', prompt: 'Apa yang sudah dilakukan?' },
    ])).error).toBeNull();
    expect((await service.from('program_enrollments').insert({ id: enrollmentId, program_id: programId, participant_id: participantId, coach_id: coachId, status: 'active' })).error).toBeNull();
    expect((await service.from('program_scores').insert({ enrollment_id: enrollmentId, activity_points: 0, quiz_points: 0, weight_points: 0, adjustment_points: 0, progress_percentage: 0 })).error).toBeNull();

    participantSession = await signIn(participant.email, participant.password);
    coachSession = await signIn(coach.email, coach.password);
  });

  test.afterAll(async () => {
    if (!canRun || !service) return;
    if (programId) await service.from('programs').delete().eq('id', programId);
    for (const id of [participantId, coachId, adminId]) if (id) await service.auth.admin.deleteUser(id);
  });

  test('Participant submits normalized private photo and Coach approves it once', async ({ page }) => {
    test.skip(!canRun || !participantSession || !coachSession, 'Memerlukan Supabase lokal.');
    await installSession(page, participantSession);
    await page.goto(`/app/programs/${programId}?step=${stepId}`);
    await expect(page.getByTestId('participant.submission.form')).toBeVisible();
    const input = page.getByLabel('Ambil atau pilih foto');
    await input.setInputFiles({ name: 'bukti.png', mimeType: 'image/png', buffer: onePixelPng() });
    await expect(page.getByLabel('Pratinjau bukti foto')).toBeVisible();
    await page.getByRole('button', { name: 'Kirim jawaban' }).click();
    await expect(page.getByRole('heading', { name: 'Kirim jawaban sekarang?' })).toBeVisible();
    await page.getByRole('button', { name: 'Kirim sekarang' }).click();
    await expect(page.getByText('Menunggu tinjauan')).toBeVisible();

    const { data: submissions } = await service.from('step_submissions').select('id,status').eq('enrollment_id', enrollmentId);
    expect(submissions).toHaveLength(1);
    expect(submissions?.[0]?.status).toBe('pending');
    const submissionId = submissions?.[0]?.id as string;
    const { data: answers } = await service.from('step_submission_answers').select('private_photo_path').eq('submission_id', submissionId);
    const objectPath = answers?.[0]?.private_photo_path as string;
    expect(objectPath).toContain(`${participantId}/${enrollmentId}/${submissionId}/`);

    await page.evaluate(() => globalThis.localStorage.clear());
    await installSession(page, coachSession);
    await page.goto('/coach/reviews');
    await expect(page.getByRole('heading', { name: 'Periksa bukti' })).toBeVisible();
    await page.getByRole('button', { name: 'Kembali ke dashboard' }).click();
    await expect(page).toHaveURL(/\/coach$/);
    await expect(page.getByTestId('coach.dashboard')).toBeVisible();
    await page.goto('/coach/reviews');
    await page.getByRole('button', { name: /Filter bukti/ }).click();
    await expect(page.getByRole('heading', { name: 'Filter bukti' })).toBeVisible();
    await expect(page.getByRole('radio', { name: 'Poin otomatis' })).toBeVisible();
    await expect(page.getByText('Penilaian Coach')).toHaveCount(0);
    await page.getByRole('button', { name: /Riwayat program/ }).click();
    await expect(page.getByRole('heading', { name: 'Riwayat program' })).toBeVisible();
    await page.getByRole('button', { name: 'Kembali ke filter bukti' }).click();
    await page.getByRole('button', { name: 'Terapkan filter' }).click();
    await expect(page.getByText('Peserta W04')).toBeVisible();
    await page.getByRole('button', { name: /Peserta W04/ }).click();
    await expect(page.getByText('Persetujuan Coach diperlukan')).toBeVisible();
    await expect(page.getByText('Ambil foto yang jelas sesuai petunjuk.')).toBeVisible();
    await expect(page.getByLabel('Bukti foto peserta')).toBeVisible();
    await page.getByRole('button', { name: 'Perbesar bukti foto' }).click();
    await expect(page.getByRole('button', { name: 'Perkecil bukti foto' })).toBeVisible();
    await page.getByRole('button', { name: 'Setujui • 10 poin' }).click();
    await expect(page.getByText(/10 poin aktivitas diberikan satu kali oleh server/)).toBeVisible();
    await page.getByRole('button', { name: 'Setujui bukti' }).click();
    await expect(page).toHaveURL(/\/coach\/reviews$/);
    await page.getByRole('tab', { name: 'Semua bukti' }).click();
    await expect(page.getByText('Disetujui')).toBeVisible();

    const { data: score } = await service.from('program_scores').select('activity_points,weight_points').eq('enrollment_id', enrollmentId).single();
    expect(score).toEqual({ activity_points: 10, weight_points: 0 });
    const { count } = await service.from('audit_events').select('id', { count: 'exact', head: true }).eq('subject_id', submissionId).eq('kind', 'submission_approved');
    expect(count).toBe(1);
    expect(await page.locator('body').innerText()).not.toContain(objectPath);
  });

  test('Coach rejection requires a reason and Participant can see actionable feedback', async ({ page }) => {
    test.skip(!canRun || !participantSession || !coachSession, 'Memerlukan Supabase lokal.');
    await installSession(page, participantSession);
    await page.goto(`/app/programs/${programId}?step=${rejectStepId}`);
    await page.getByLabel('Apa yang sudah dilakukan?').fill('Saya menyelesaikan aktivitas hari ini.');
    await page.getByRole('button', { name: 'Kirim jawaban' }).click();
    await page.getByRole('button', { name: 'Kirim sekarang' }).click();
    await expect(page.getByText('Menunggu tinjauan')).toBeVisible();

    await page.evaluate(() => globalThis.localStorage.clear());
    await installSession(page, coachSession);
    await page.goto('/coach/reviews');
    await page.getByRole('button', { name: /Peserta W04, Refleksi W04/ }).click();
    await page.getByRole('button', { name: 'Tolak bukti', exact: true }).click();
    const submitRejection = page.getByRole('button', { name: 'Tolak bukti' });
    await expect(submitRejection).toBeDisabled();
    await page.getByLabel('Alasan penolakan').fill('Jawaban perlu lebih spesifik sesuai petunjuk.');
    await expect(submitRejection).toBeEnabled();
    await submitRejection.click();
    await expect(page).toHaveURL(/\/coach\/reviews$/);

    await page.evaluate(() => globalThis.localStorage.clear());
    await installSession(page, participantSession);
    await page.goto(`/app/programs/${programId}?step=${rejectStepId}`);
    await expect(page.getByText('Perlu diperbaiki').first()).toBeVisible();
    await expect(page.getByText('Jawaban perlu lebih spesifik sesuai petunjuk.')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Kirim perbaikan' })).toBeDisabled();
  });
});

async function createIdentity(label: string) {
  const suffix = randomUUID();
  const email = `${label}-${suffix}@test.invalid`;
  const password = `W04-${suffix}!`;
  const response = await service.auth.admin.createUser({ email, password, email_confirm: true });
  expect(response.error).toBeNull();
  return { id: response.data.user?.id as string, email, password };
}

async function updateProfile(userId: string, patch: Record<string, unknown>) {
  expect((await service.from('profiles').update({ ...patch, onboarding_status: 'active', provisional_expires_at: null, finalized_at: new Date().toISOString() }).eq('user_id', userId)).error).toBeNull();
}

async function activateCoach() {
  const applicationId = randomUUID();
  const paymentId = randomUUID();
  expect((await service.from('coach_applications').insert({
    id: applicationId, applicant_user_id: coachId, participant_profile_id: coachId, display_name_snapshot: 'Coach W04', phone_number_snapshot: '+6281200000000', member_level_snapshot: 'sc', has_completed_hom_sts: true, has_completed_ict: true, terms_version: 'w04-v1', status: 'active', draft_idempotency_key: `w04-${randomUUID()}`, submitted_at: new Date().toISOString(), decided_at: new Date().toISOString(), decided_by: adminId,
  })).error).toBeNull();
  expect((await service.from('coach_payment_records').insert({ id: paymentId, application_id: applicationId, state: 'verified', price_band: 'entry', amount_minor_units: 100000, duration_months: 3, provider_reference: `w04-${randomUUID()}`, verified_at: new Date().toISOString() })).error).toBeNull();
  expect((await service.from('coach_access_entitlements').insert({ application_id: applicationId, payment_record_id: paymentId, coach_user_id: coachId, status: 'active', starts_at: new Date(Date.now() - 60_000).toISOString(), ends_at: new Date(Date.now() + 90 * 86_400_000).toISOString() })).error).toBeNull();
}

async function signIn(email: string, password: string): Promise<Session> {
  const client = createClient(localUrl as string, publishableKey as string, { auth: { persistSession: false, autoRefreshToken: false } });
  const response = await client.auth.signInWithPassword({ email, password });
  expect(response.error).toBeNull();
  return response.data.session as Session;
}

async function installSession(page: import('@playwright/test').Page, session: Session) {
  await page.addInitScript(({ key, value }) => globalThis.localStorage.setItem(key, value), {
    key: `sb-${new URL(localUrl as string).hostname.split('.')[0]}-auth-token`,
    value: JSON.stringify(session),
  });
  await page.evaluate(({ key, value }) => globalThis.localStorage.setItem(key, value), {
    key: `sb-${new URL(localUrl as string).hostname.split('.')[0]}-auth-token`,
    value: JSON.stringify(session),
  }).catch(() => undefined);
}

function localDate(offsetDays: number): string {
  const value = new Date(Date.now() + offsetDays * 86_400_000);
  const parts = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Makassar', year: 'numeric', month: '2-digit', day: '2-digit' }).formatToParts(value);
  const get = (type: Intl.DateTimeFormatPartTypes) => parts.find((part) => part.type === type)?.value;
  return `${get('year')}-${get('month')}-${get('day')}`;
}

function onePixelPng(): Buffer {
  return readFileSync('tests/e2e/feasibility.spec.ts-snapshots/landing-390-chromium-compact-darwin.png');
}
