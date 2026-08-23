import { expect, test } from '@playwright/test';
import { createClient, type Session, type SupabaseClient } from '@supabase/supabase-js';
import { randomUUID } from 'node:crypto';
import { readFileSync } from 'node:fs';

const localUrl = process.env.API_URL;
const publishableKey = process.env.PUBLISHABLE_KEY ?? process.env.ANON_KEY;
const secretKey = process.env.SECRET_KEY ?? process.env.SERVICE_ROLE_KEY;
const canRun = localUrl !== undefined && publishableKey !== undefined && secretKey !== undefined;

let service: SupabaseClient;
let coachSession: Session;
let coachId = '';
let adminId = '';
let participantId = '';
let applicationId = '';
let paymentRecordId = '';
let entitlementId = '';
let programId = '';
let enrollmentId = '';
let handle = '';
let rawQr = '';
let profileObjectPath = '';
let importedProfileObjectPath = '';
const jpeg = Buffer.from('/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////2wBDAf//////////////////////////////////////////////////////////////////////////////////////wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAX/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIQAxAAAAF//8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABBQJ//8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAgBAwEBPwF//8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAgBAgEBPwF//8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQAGPwJ//8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPyF//9oADAMBAAIAAwAAABD/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oACAEDAQE/EB//xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oACAECAQE/EB//xAAUEAEAAAAAAAAAAAAAAAAAAAAA/9oACAEBAAE/EB//2Q==', 'base64');
const providerJpeg = readFileSync('public/images/coach-support.jpg');

test.describe('W06 Coach experience', () => {
  test.beforeAll(async () => {
    if (!canRun) return;
    service = createClient(localUrl as string, secretKey as string, { auth: { persistSession: false, autoRefreshToken: false } });
    const suffix = randomUUID(); handle = `coach-browser-${suffix.slice(0, 8)}`; rawQr = `coach_${suffix.replaceAll('-', '')}${randomUUID().replaceAll('-', '')}`;
    const admin = await createIdentity(`w06-browser-admin-${suffix}@test.invalid`, `W06-A-${suffix}!`);
    const coach = await createIdentity(`w06-browser-coach-${suffix}@test.invalid`, `W06-C-${suffix}!`);
    const participant = await createIdentity(`w06-browser-participant-${suffix}@test.invalid`, `W06-P-${suffix}!`);
    adminId = admin.id; coachId = coach.id; participantId = participant.id;
    await updateProfile(adminId, { role: 'admin', display_name: 'Admin Browser W06' });
    await updateProfile(coachId, { role: 'coach', display_name: 'Coach Lestari', city: 'Denpasar', phone_number: '+628111111111', coach_is_approved: true, coach_qr_identifier: rawQr, provider_avatar_url: 'https://example.com/avatar.jpg' });
    await updateProfile(participantId, { role: 'participant', display_name: 'Peserta Binaan W06', city: 'Badung', provider_avatar_url: 'https://example.com/participant-avatar.jpg' });
    const application = await service.from('coach_applications').insert({ applicant_user_id: coachId, participant_profile_id: coachId, display_name_snapshot: 'Coach Lestari', phone_number_snapshot: '+628111111111', member_level_snapshot: 'sc', has_completed_hom_sts: true, has_completed_ict: true, terms_version: 'coach-web-v1', status: 'active', draft_idempotency_key: `fixture-${suffix}`, submit_idempotency_key: `submit-${suffix}`, decision_idempotency_key: `approve-${suffix}`, submitted_at: new Date().toISOString(), decided_at: new Date().toISOString(), decided_by: adminId }).select('id').single();
    expect(application.error).toBeNull(); applicationId = application.data?.id as string;
    const payment = await service.from('coach_payment_records').insert({ application_id: applicationId, state: 'verified', price_band: 'entry', amount_minor_units: 100000, duration_months: 3, provider_reference: `BROWSER-${suffix.slice(0, 8)}`, verified_at: new Date().toISOString(), period_sequence: 1 }).select('id').single();
    expect(payment.error).toBeNull(); paymentRecordId = payment.data?.id as string;
    const entitlement = await service.from('coach_access_entitlements').insert({ application_id: applicationId, payment_record_id: paymentRecordId, coach_user_id: coachId, status: 'active', starts_at: new Date(Date.now() - 86_400_000).toISOString(), ends_at: new Date(Date.now() + 89 * 86_400_000).toISOString(), period_sequence: 1 }).select('id').single();
    expect(entitlement.error).toBeNull(); entitlementId = entitlement.data?.id as string;
    programId = randomUUID();
    expect((await service.from('programs').insert({ id: programId, title: 'Transformasi Browser W06', summary: 'Fixture dashboard Coach.', status: 'active', pace: 'scheduled', duration_mode: 'specific_dates', starts_on: localDate(-2), ends_on: localDate(5), timezone: 'Asia/Makassar', past_step_policy: 'read_only', future_step_policy: 'locked', wellness_disclaimer: 'Program wellness non-diagnostik.', points_per_activity: 10, points_per_weight_kg: 100, quiz_passing_percentage: 70, pricing_mode: 'free', desired_price: null, participant_limit: 20, published_at: new Date().toISOString(), created_by: adminId })).error).toBeNull();
    const enrollment = await service.from('program_enrollments').insert({ program_id: programId, participant_id: participantId, coach_id: coachId, status: 'active' }).select('id').single();
    expect(enrollment.error).toBeNull(); enrollmentId = enrollment.data?.id as string;
    expect((await service.from('program_scores').insert({ enrollment_id: enrollmentId, activity_points: 90, progress_percentage: 45, rank: 1 })).error).toBeNull();
    const day = await service.from('program_days').insert({ program_id: programId, day_number: 1, title: 'Hari pertama', scheduled_on: localDate(0) }).select('id').single();
    expect(day.error).toBeNull();
    const steps = await service.from('program_steps').insert([
      { program_day_id: day.data?.id, step_order: 1, title: 'Pilihan makan seimbang', instructions: 'Kirim bukti pilihan makan.', content_kind: 'form', completion_policy: 'answer_all_questions', verification_mode: 'coach_review' },
      { program_day_id: day.data?.id, step_order: 2, title: 'Gerak pagi', instructions: 'Tandai selesai.', content_kind: 'article', completion_policy: 'mark_complete', verification_mode: 'automatic' },
    ]).select('id,step_order');
    expect(steps.error).toBeNull();
    expect((await service.from('step_submissions').insert([
      { enrollment_id: enrollmentId, step_id: steps.data?.find((step) => step.step_order === 1)?.id, status: 'pending' },
      { enrollment_id: enrollmentId, step_id: steps.data?.find((step) => step.step_order === 2)?.id, status: 'approved', reviewed_at: new Date().toISOString(), reviewer_id: coachId },
    ])).error).toBeNull();
    coachSession = await signIn(coach.email, coach.password);
    const coachClient = sessionClient(coachSession);
    const allocation = await coachClient.rpc('allocate_my_coach_public_media_path', { media_folder: 'avatar' });
    expect(allocation.error).toBeNull();
    profileObjectPath = allocation.data as string;
    expect((await coachClient.storage.from('coach-public-media').upload(profileObjectPath, jpeg, { contentType: 'image/jpeg', upsert: false })).error).toBeNull();
    expect((await coachClient.rpc('save_my_coach_public_profile_draft', { requested_handle: handle, photo_object_path: profileObjectPath, professional_headline: 'Pendamping perubahan kebiasaan', biography: 'Pendampingan yang jelas, konsisten, dan non-diagnostik.', service_area: 'Denpasar dan sekitarnya', instagram_url: 'https://instagram.com/tersembunyi', tiktok_url: '', website_url: 'https://example.com/coach-lestari', whatsapp_number: '+628111111111', phone_number: '+628122222222', show_instagram: false, show_tiktok: false, show_website: true, show_whatsapp: false, show_phone: false })).error).toBeNull();
    expect((await coachClient.rpc('publish_my_coach_public_profile')).error).toBeNull();
  });

  test.afterAll(async () => {
    if (!canRun || !service) return;
    if (importedProfileObjectPath) await service.storage.from('coach-public-media').remove([importedProfileObjectPath]);
    if (profileObjectPath) await service.storage.from('coach-public-media').remove([profileObjectPath]);
    if (enrollmentId) await service.from('program_scores').delete().eq('enrollment_id', enrollmentId);
    if (programId) { await service.from('program_enrollments').delete().eq('program_id', programId); await service.from('programs').delete().eq('id', programId); }
    if (coachId) { await service.from('coach_public_profiles').delete().eq('coach_user_id', coachId); await service.from('coach_public_profile_drafts').delete().eq('coach_user_id', coachId); }
    if (entitlementId) await service.from('coach_access_entitlements').delete().eq('id', entitlementId);
    if (paymentRecordId) await service.from('coach_payment_records').delete().eq('id', paymentRecordId);
    if (applicationId) await service.from('coach_applications').delete().eq('id', applicationId);
    for (const id of [participantId, coachId, adminId]) if (id) await service.auth.admin.deleteUser(id);
  });

  test('Coach uses all six parity actions and raw QR never enters visible HTML', async ({ page }) => {
    test.skip(!canRun || !coachSession, 'Memerlukan Supabase lokal.');
    await page.route('https://example.com/participant-avatar.jpg', (route) => route.fulfill({
      status: 200,
      contentType: 'image/jpeg',
      headers: { 'access-control-allow-origin': '*' },
      body: providerJpeg,
    }));
    await installSession(page, coachSession);
    await page.goto('/coach');
    await expect(page.getByTestId('coach.dashboard')).toBeVisible();
    const dashboardSummary = page.getByTestId('coach.dashboard-summary');
    await expect(page.getByRole('heading', { name: 'Ringkasan pendampingan' })).toBeVisible();
    await expect(dashboardSummary.getByLabel('1 peserta')).toBeVisible();
    await expect(dashboardSummary.getByLabel('45% progres')).toBeVisible();
    await expect(dashboardSummary.getByLabel('1 program aktif')).toBeVisible();
    const summaryBoxes = await page.getByTestId('coach.dashboard-summary-metric').evaluateAll((metrics) => metrics.map((metric) => {
      const box = metric.getBoundingClientRect();
      return { left: box.left, top: box.top, width: box.width, height: box.height };
    }));
    expect(summaryBoxes).toHaveLength(3);
    expect(Math.max(...summaryBoxes.map((box) => box.top)) - Math.min(...summaryBoxes.map((box) => box.top))).toBeLessThan(2);
    expect(summaryBoxes.every((box) => box.width >= 80 && box.height >= 88 && box.height <= 112)).toBe(true);
    const actionNames = ['Periksa bukti', 'Peserta saya', 'Aktivitas terbaru', 'Peringkat', 'Program saya', 'QR pendaftaran'];
    const actions = page.getByRole('button').filter({ hasText: /Periksa bukti|Peserta saya|Aktivitas terbaru|Peringkat|Program saya|QR pendaftaran/ });
    await expect(actions).toHaveCount(6);
    for (let index = 0; index < actionNames.length; index += 1) await expect(actions.nth(index)).toContainText(actionNames[index] as string);
    await page.getByRole('button', { name: /Peserta saya/ }).click();
    await expect(page.getByTestId('coach.participants')).toContainText('Peserta Binaan W06');
    await expect(page.getByPlaceholder('Cari nama atau kota')).toBeVisible();
    await expect(page.getByRole('button', { name: /Filter dan urutkan/ })).toBeVisible();
    await page.getByText('Peserta Binaan W06', { exact: true }).click();
    await expect(page.getByTestId('coach.participant.detail')).toContainText('Kemajuan program');
    await expect(page.getByTestId('coach.participant.detail')).toContainText('Riwayat berat badan');
    await expect(page.getByTestId('coach.participant.detail')).toContainText('Rincian progres');
    await page.getByRole('button', { name: 'Kembali ke peserta saya' }).click();
    await page.getByRole('button', { name: /Filter dan urutkan/ }).click();
    await expect(page.getByRole('heading', { name: 'Filter peserta' })).toBeVisible();
    await expect(page.getByText('Status penyelesaian')).toBeVisible();
    await expect(page.getByText('Urutkan menurut')).toBeVisible();
    await page.getByRole('button', { name: 'Tutup' }).click();
    await page.goto('/coach/activity');
    await expect(page.getByTestId('coach.activity')).toContainText('Hari ini');
    await expect(page.getByTestId('coach.activity')).toContainText('Mengirim bukti untuk Pilihan makan seimbang');
    await expect(page.getByTestId('coach.activity')).toContainText('Menyelesaikan langkah Gerak pagi');
    await page.getByRole('button', { name: /Filter aktivitas/ }).click();
    await expect(page.getByRole('heading', { name: 'Filter aktivitas' })).toBeVisible();
    await expect(page.getByText('Jenis aktivitas')).toBeVisible();
    await expect(page.getByText('Waktu')).toBeVisible();
    await page.getByRole('radio', { name: 'Bukti dikirim' }).click();
    await page.getByRole('button', { name: 'Terapkan filter' }).click();
    await expect(page.getByTestId('coach.activity')).toContainText('Perlu pemeriksaan');
    await page.getByRole('button', { name: /Peserta Binaan W06, Mengirim bukti/ }).click();
    await expect(page.getByTestId('coach.review.queue')).toBeVisible();
    await page.goto('/coach/activity');
    await page.getByRole('button', { name: /Filter aktivitas/ }).click();
    await page.getByRole('radio', { name: 'Langkah selesai' }).click();
    await page.getByRole('button', { name: 'Terapkan filter' }).click();
    await page.getByRole('button', { name: /Peserta Binaan W06, Menyelesaikan langkah/ }).click();
    await expect(page.getByTestId('coach.participant.detail')).toContainText('Peserta Binaan W06');
    await page.goto(`/coach/leaderboard?programId=${programId}`);
    await expect(page.getByTestId('leaderboard.podium')).toBeVisible();
    await expect(page.getByTestId('leaderboard.podium').getByRole('img', { name: 'Peserta Binaan W06' })).toBeVisible();
    await expect(page.getByTestId('coach.leaderboard')).toContainText('Pesertamu');
    await expect(page.getByTestId('coach.leaderboard')).toContainText('Berlangsung');
    await expect(page.getByTestId('coach.leaderboard')).not.toContainText('Nilai berat badan tetap privat.');
    await page.getByRole('button', { name: 'Rincian poin Peserta Binaan W06' }).click();
    await expect(page.getByRole('heading', { name: 'Rincian poin' }).first()).toBeVisible();
    await expect(page.getByText('Poin langkah')).toBeVisible();
    await expect(page.getByText('Poin penurunan berat badan')).toBeVisible();
    await expect(page.getByText('Rincian hanya menampilkan poin dan progres. Nilai berat badan tetap privat.', { exact: true })).toHaveCount(0);
    await page.getByRole('button', { name: 'Tutup' }).click();
    await page.goto('/coach/programs');
    await expect(page.getByTestId('participant.program.catalog')).toBeVisible();
    await expect(page.getByRole('heading', { name: 'Program yang diikuti' })).toBeVisible();
    await expect(page.getByTestId('participant.program.catalog')).not.toContainText('Transformasi Browser W06');
    await page.getByRole('tab', { name: 'Tersedia' }).click();
    await expect(page.getByRole('heading', { name: 'Program yang tersedia' })).toBeVisible();
    await expect(page.getByTestId('participant.program.catalog').getByRole('link').first()).toBeVisible();
    await page.goto('/coach/qr');
    await expect(page.getByLabel('QR pendaftaran Coach')).toBeVisible();
    expect(await page.locator('body').innerText()).not.toContain(rawQr);
    expect(await page.content()).not.toContain(rawQr);
    expect((await service.from('coach_public_profile_drafts').update({ profile_photo_object_path: null }).eq('coach_user_id', coachId)).error).toBeNull();
    await page.route('https://example.com/avatar.jpg', (route) => route.fulfill({
      status: 200,
      contentType: 'image/jpeg',
      headers: { 'access-control-allow-origin': '*' },
      body: providerJpeg,
    }));
    await page.goto('/coach/profile');
    await expect(page.getByTestId('coach.profile.editor')).toContainText('Coach terverifikasi');
    await expect(page.getByText('Nama dan tanda verifikasi berasal dari akun dan tidak dapat diedit di profil publik.')).toBeVisible();
    await page.getByRole('button', { name: 'Simpan draf' }).click();
    await expect(page.getByText('Draf profil tersimpan.')).toBeVisible();
    const importedDraft = await service.from('coach_public_profile_drafts').select('profile_photo_object_path').eq('coach_user_id', coachId).single();
    expect(importedDraft.error).toBeNull();
    importedProfileObjectPath = importedDraft.data?.profile_photo_object_path as string;
    expect(importedProfileObjectPath).toMatch(/^coaches\/[0-9a-f-]{36}\/avatar\/[0-9a-f-]{36}\.jpg$/u);
    expect(importedProfileObjectPath).not.toContain(coachId);
  });

  test('compact and wide layouts preserve Coach navigation and action reachability', async ({ page }) => {
    test.skip(!canRun || !coachSession, 'Memerlukan Supabase lokal.');
    await installSession(page, coachSession);
    for (const viewport of [{ width: 390, height: 844 }, { width: 1440, height: 900 }]) {
      await page.setViewportSize(viewport); await page.goto('/coach');
      await expect(page.getByRole('navigation', { name: 'Navigasi utama' })).toBeVisible();
      await expect(page.getByRole('link', { name: /Dashboard/ })).toHaveAttribute('aria-current', 'page');
      expect(await page.evaluate(() => document.documentElement.scrollWidth <= document.documentElement.clientWidth)).toBe(true);
      await expect(page.getByRole('button', { name: /QR pendaftaran/ })).toBeVisible();
      const actionBoxes = await page.getByTestId('coach.quick-action').evaluateAll((actions) => actions.map((action) => {
        const box = action.getBoundingClientRect();
        return { left: box.left, top: box.top, width: box.width, height: box.height };
      }));
      expect(actionBoxes).toHaveLength(6);
      expect(Math.max(...actionBoxes.slice(0, 3).map((box) => box.top)) - Math.min(...actionBoxes.slice(0, 3).map((box) => box.top))).toBeLessThan(2);
      expect(Math.max(...actionBoxes.slice(3).map((box) => box.top)) - Math.min(...actionBoxes.slice(3).map((box) => box.top))).toBeLessThan(2);
      expect(actionBoxes[3]?.top).toBeGreaterThan((actionBoxes[0]?.top ?? 0) + (actionBoxes[0]?.height ?? 0));
      expect(actionBoxes.every((box) => box.width >= 96 && box.height >= 120)).toBe(true);
    }
  });

  test('public handle renders only toggled fields and unknown handle is safe', async ({ page }) => {
    test.skip(!canRun, 'Memerlukan Supabase lokal.');
    await page.emulateMedia({ colorScheme: 'light' });
    await page.goto(`/c/${handle}`);
    await expect(page.getByTestId('public.coach.profile')).toContainText('Coach Lestari');
    await expect(page.getByText('Coach terverifikasi')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Situs web' })).toBeVisible();
    const body = await page.locator('body').innerText();
    expect(body).not.toContain('Instagram'); expect(body).not.toContain('+628111111111'); expect(body).not.toContain('+628122222222');
    expect(await page.content()).not.toContain(rawQr); expect(await page.content()).not.toContain(coachId);
    const lightHero = await page.getByTestId('public.coach.profile.hero').evaluate((element) => getComputedStyle(element).backgroundColor);
    await page.emulateMedia({ colorScheme: 'dark' });
    await expect(page.getByRole('heading', { name: 'Coach Lestari' })).toBeVisible();
    const darkHero = await page.getByTestId('public.coach.profile.hero').evaluate((element) => getComputedStyle(element).backgroundColor);
    expect(darkHero).toBe(lightHero);
    await page.goto('/c/tidak-ada-w06');
    await expect(page.getByText('Belum ada konten')).toBeVisible();
  });
});

async function createIdentity(email: string, password: string) { const response = await service.auth.admin.createUser({ email, password, email_confirm: true }); expect(response.error).toBeNull(); return { id: response.data.user?.id as string, email, password }; }
async function updateProfile(userId: string, patch: Record<string, unknown>) { expect((await service.from('profiles').update({ ...patch, onboarding_status: 'active', provisional_expires_at: null, finalized_at: new Date().toISOString() }).eq('user_id', userId)).error).toBeNull(); }
async function signIn(email: string, password: string): Promise<Session> { const client = createClient(localUrl as string, publishableKey as string, { auth: { persistSession: false, autoRefreshToken: false } }); const response = await client.auth.signInWithPassword({ email, password }); expect(response.error).toBeNull(); return response.data.session as Session; }
function sessionClient(session: Session) { return createClient(localUrl as string, publishableKey as string, { auth: { persistSession: false, autoRefreshToken: false }, global: { headers: { Authorization: `Bearer ${session.access_token}` } } }); }
async function installSession(page: import('@playwright/test').Page, session: Session) { await page.goto('/login'); await page.evaluate(({ key, value }) => globalThis.localStorage.setItem(key, value), { key: authKey(), value: JSON.stringify(session) }); }
function authKey() { return `sb-${new URL(localUrl as string).hostname.split('.')[0]}-auth-token`; }
function localDate(offset: number) { return new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Makassar', year: 'numeric', month: '2-digit', day: '2-digit' }).format(new Date(Date.now() + offset * 86_400_000)); }
