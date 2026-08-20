import { expect, test } from '@playwright/test';
import { createClient, type Session, type SupabaseClient } from '@supabase/supabase-js';
import { randomUUID } from 'node:crypto';
import { readFileSync } from 'node:fs';

const localUrl = process.env.API_URL;
const publishableKey = process.env.PUBLISHABLE_KEY ?? process.env.ANON_KEY;
const secretKey = process.env.SECRET_KEY ?? process.env.SERVICE_ROLE_KEY;
const canRun = Boolean(localUrl && publishableKey && secretKey);

let service: SupabaseClient; let adminClient: SupabaseClient; let adminSession: Session;
let adminId = ''; let participantId = ''; let coachId = ''; let draftProgramId = ''; let activeProgramId = ''; let moderationItemId = '';
let completedProgramId = ''; let winnerSnapshotId = ''; let draftTitle = ''; let activeTitle = ''; let completedTitle = '';

test.describe('W07 Admin experience', () => {
  test.beforeAll(async () => {
    if (!canRun) return;
    expect(['127.0.0.1', 'localhost']).toContain(new URL(localUrl as string).hostname);
    service = createClient(localUrl as string, secretKey as string, { auth: { persistSession: false, autoRefreshToken: false } });
    const admin = await createIdentity('admin-e2e'); const participant = await createIdentity('participant-e2e'); const coach = await createIdentity('coach-e2e');
    adminId = admin.id; participantId = participant.id; coachId = coach.id;
    await Promise.all([activateProfile(adminId, 'admin', 'Admin E2E W07'), activateProfile(participantId, 'participant', 'Peserta E2E W07'), activateProfile(coachId, 'coach', 'Coach E2E W07')]);
    expect((await service.from('profiles').update({ coach_is_approved: true, coach_is_public: true }).eq('user_id', coachId)).error).toBeNull();
    await activateCoach(); expect((await service.from('profiles').update({ current_coach_id: coachId, city: 'Denpasar' }).eq('user_id', participantId)).error).toBeNull();
    adminClient = await signInClient(admin.email, admin.password); adminSession = (await adminClient.auth.getSession()).data.session as Session;
    draftProgramId = randomUUID(); activeProgramId = randomUUID();
    completedProgramId = randomUUID(); winnerSnapshotId = randomUUID();
    draftTitle = `Program Draft ${draftProgramId.slice(0, 8)}`; activeTitle = `Program Aktif ${activeProgramId.slice(0, 8)}`;
    expect((await adminClient.rpc('save_admin_program_draft', { program_payload: programPayload(draftProgramId, draftTitle, date(1)), request_idempotency_key: `w07-e2e-draft-${randomUUID()}` })).error).toBeNull();
    expect((await adminClient.rpc('save_admin_program_draft', { program_payload: programPayload(activeProgramId, activeTitle, date(0)), request_idempotency_key: `w07-e2e-active-${randomUUID()}` })).error).toBeNull();
    expect((await adminClient.rpc('publish_program', { target_program_id: activeProgramId, request_idempotency_key: `w07-e2e-publish-${randomUUID()}` })).error).toBeNull();
    completedTitle = `Program Selesai ${completedProgramId.slice(0, 8)}`;
    expect((await service.from('programs').insert({ id: completedProgramId, title: completedTitle, summary: 'Program selesai untuk poster W07.', status: 'completed', pace: 'scheduled', duration_mode: 'specific_dates', starts_on: date(-2), ends_on: date(-1), timezone: 'Asia/Makassar', past_step_policy: 'available', future_step_policy: 'locked', wellness_disclaimer: 'Program wellness non-diagnostik.', points_per_activity: 10, points_per_weight_kg: 0, quiz_passing_percentage: 70, pricing_mode: 'free', created_by: adminId, published_at: new Date().toISOString() })).error).toBeNull();
    expect((await service.from('winner_snapshots').insert({ id: winnerSnapshotId, program_id: completedProgramId, locked_by: adminId, idempotency_key: `w07-e2e-snapshot-${randomUUID()}` })).error).toBeNull();
    moderationItemId = randomUUID();
    expect((await service.from('coach_public_profile_items').insert({ id: moderationItemId, coach_user_id: coachId, item_kind: 'testimonial', title: 'Testimoni E2E W07', body: 'Konten testimoni untuk pemeriksaan Admin.', includes_third_party: false, permission_attested: false, moderation_status: 'pending' })).error).toBeNull();
  });

  test.afterAll(async () => {
    if (!canRun || !service) return;
    const posterRows = await service.from('winner_posters').select('media_path').eq('program_id', completedProgramId);
    if (posterRows.data?.length) await service.storage.from('public-media').remove(posterRows.data.map((poster) => poster.media_path));
    await service.from('winner_posters').delete().eq('program_id', completedProgramId);
    await service.from('winner_snapshots').delete().eq('program_id', completedProgramId);
    await service.from('programs').delete().eq('source_program_id', draftProgramId);
    await service.from('program_enrollments').delete().in('program_id', [draftProgramId, activeProgramId]);
    await service.from('programs').delete().in('id', [draftProgramId, activeProgramId, completedProgramId]);
    for (const id of [participantId, coachId, adminId]) if (id) await service.auth.admin.deleteUser(id);
  });

  test('Dashboard and five destinations match the Admin iOS hierarchy', async ({ page }, testInfo) => {
    test.skip(!canRun || !adminSession, 'Memerlukan Supabase lokal.'); await installSession(page, adminSession); await page.goto('/admin');
    await expect(page.getByRole('heading', { name: 'Dashboard' }).first()).toBeVisible();
    await expect(page.getByText('Kendali operasional hari ini')).toBeVisible();
    for (const label of ['Dashboard', 'Program', 'Orang', 'Konten', 'Pengaturan']) await expect(page.getByRole('link', { name: label })).toBeVisible();
    const createAction = page.getByRole('button', { name: 'Buat program' }); const posterAction = page.getByRole('button', { name: 'Tambah poster' }); await expect(createAction).toBeVisible(); await expect(posterAction).toBeVisible();
    const [createBox, posterBox] = await Promise.all([createAction.boundingBox(), posterAction.boundingBox()]); expect(createBox).not.toBeNull(); expect(posterBox).not.toBeNull(); expect(Math.abs(createBox!.y - posterBox!.y)).toBeLessThanOrEqual(2); expect(Math.abs(createBox!.width - posterBox!.width)).toBeLessThanOrEqual(4);
    const metricIds = ['activePrograms', 'activeParticipants', 'scheduled']; const metricBoxes = await Promise.all(metricIds.map(async (id) => { const metric = page.getByTestId(`admin.dashboard.metric.${id}`); await expect(metric).toBeVisible(); return metric.boundingBox(); })); expect(metricBoxes.every(Boolean)).toBe(true); expect(Math.max(...metricBoxes.map((box) => box!.y)) - Math.min(...metricBoxes.map((box) => box!.y))).toBeLessThanOrEqual(2);
    await page.getByRole('heading', { name: 'Aktivitas terbaru' }).scrollIntoViewIfNeeded(); await expect(page.getByRole('heading', { name: 'Aktivitas terbaru' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Kelola program' })).toHaveCount(0); await expect(page.getByRole('button', { name: 'Kelola orang' })).toHaveCount(0);
    await page.screenshot({ path: `/tmp/w07-admin-dashboard-${testInfo.project.name}.png`, fullPage: true });
    await page.getByRole('link', { name: 'Program' }).click(); await expect(page).toHaveURL(/\/admin\/programs$/); await expect(page.getByRole('button', { name: 'Buat program baru' })).toBeVisible();
    await page.screenshot({ path: `/tmp/w07-admin-programs-${testInfo.project.name}.png`, fullPage: true });
    await page.getByLabel('Cari program').press('Tab'); await expect(page.getByRole('button', { name: 'Buat program baru' })).toBeFocused();
    await page.getByRole('link', { name: 'Orang' }).click(); await expect(page.getByRole('tab', { name: 'Peserta' })).toBeVisible(); await expect(page.getByRole('tab', { name: 'Coach' })).toBeVisible(); await expect(page.getByRole('tab', { name: 'Admin' })).toBeVisible(); await page.getByRole('tab', { name: 'Coach' }).click(); await expect(page.getByRole('tab', { name: 'Daftar Coach' })).toBeVisible(); await expect(page.getByRole('tab', { name: 'Aplikasi Coach' })).toBeVisible(); await expect(page.getByRole('heading', { name: 'Coach' })).toBeVisible(); await expect(page.getByTestId('admin.coach-applications')).toHaveCount(0); await page.getByRole('tab', { name: 'Aplikasi Coach' }).click(); await expect(page.getByTestId('admin.coach-applications')).toBeVisible(); await expect(page.getByText('Tidak ada aplikasi yang perlu ditindak')).toBeVisible(); await expect(page.getByRole('heading', { name: 'Terjadi kendala' })).toHaveCount(0); await page.getByRole('tab', { name: 'Semua aplikasi' }).click(); await expect(page.getByText(/Menampilkan \d+ dari \d+ aplikasi/u)).toBeVisible(); await page.goto('/admin/people?scope=coach&pending=1'); await expect(page.getByRole('tab', { name: 'Aplikasi Coach' })).toHaveAttribute('aria-selected', 'true'); await expect(page.getByRole('tab', { name: /Perlu tindakan/u })).toHaveAttribute('aria-selected', 'true');
    await page.screenshot({ path: `/tmp/w07-admin-people-${testInfo.project.name}.png`, fullPage: true });
    await page.getByRole('link', { name: 'Konten' }).click(); await expect(page.getByRole('tab', { name: 'Poster' })).toBeVisible(); await expect(page.getByRole('tab', { name: 'Moderasi' })).toBeVisible(); await expect(page.getByRole('tab', { name: 'Insight AI' })).toBeVisible();
    await page.screenshot({ path: `/tmp/w07-admin-content-${testInfo.project.name}.png`, fullPage: true });
    await page.getByRole('link', { name: 'Pengaturan' }).click(); await expect(page.getByText('Credential', { exact: true })).toBeVisible(); expect(await page.locator('body').innerText()).not.toMatch(/SERVICE_ROLE|FOOD_AI_API_KEY|JWT_SECRET/u);
    if (testInfo.project.name === 'chromium-compact') { await page.emulateMedia({ colorScheme: 'dark' }); await page.goto('/admin'); await expect(page.getByText('Kendali operasional hari ini')).toBeVisible(); await page.screenshot({ path: '/tmp/w07-admin-dashboard-compact-dark.png', fullPage: true }); }
  });

  test('Draft preview uses the shared Participant renderer and publishes end-to-end', async ({ page }) => {
    test.skip(!canRun || !adminSession, 'Memerlukan Supabase lokal.'); await installSession(page, adminSession); await page.goto(`/admin/programs/${draftProgramId}`);
    await expect(page.getByText('Selesaikan 3 tahap')).toBeVisible(); await expect(page.getByRole('button', { name: /Pengaturan program/ })).toBeVisible(); await expect(page.getByRole('button', { name: /Konten program/ })).toBeVisible();
    await page.getByRole('button', { name: /Pengaturan program/ }).click(); await expect(page.getByRole('button', { name: /Info program/ })).toBeVisible(); await expect(page.getByRole('button', { name: /Jadwal dan peserta/ })).toBeVisible(); await expect(page.getByRole('button', { name: /Aturan dan poin/ })).toBeVisible();
    await page.getByRole('button', { name: /Info program/ }).click(); await expect(page.getByRole('tab', { name: 'Gratis' })).toBeVisible(); await expect(page.getByRole('tab', { name: 'Berbayar' })).toBeVisible(); await page.getByRole('tab', { name: 'Berbayar' }).click(); await expect(page.getByLabel('Harga yang diinginkan')).toBeVisible(); await page.goBack();
    await page.getByRole('button', { name: /Jadwal dan peserta/ }).click(); await expect(page.getByLabel('Jenis durasi')).toHaveValue('specific_dates'); await expect(page.locator('input[aria-label="Mulai"]')).toHaveAttribute('type', 'date'); await expect(page.locator('input[aria-label="Selesai"]')).toHaveAttribute('type', 'date'); await page.getByLabel('Jenis durasi').selectOption('fixed_duration'); await expect(page.locator('input[aria-label="Tanggal acuan"]')).toHaveAttribute('type', 'date'); await expect(page.getByRole('button', { name: 'Tambah durasi' })).toBeVisible(); await page.getByLabel('Zona waktu').selectOption('Asia/Jakarta'); await page.getByRole('button', { name: 'Simpan' }).click(); await expect.poll(async () => (await service.from('programs').select('duration_mode,timezone').eq('id', draftProgramId).single()).data).toMatchObject({ duration_mode: 'fixed_duration', timezone: 'Asia/Jakarta' });
    await page.getByRole('button', { name: /Aturan dan poin/ }).click(); await expect(page.getByText('Nilai lulus kuis: 70%')).toBeVisible(); await page.getByRole('button', { name: 'Tambah nilai lulus kuis' }).click(); await expect(page.getByText('Nilai lulus kuis: 71%')).toBeVisible(); await page.getByLabel('Pemeriksaan default').selectOption('automatic'); await page.getByLabel('Langkah lampau').selectOption('read_only'); await page.getByLabel('Langkah mendatang').selectOption('available'); await page.getByRole('button', { name: 'Simpan' }).click(); await expect.poll(async () => (await service.from('programs').select('quiz_passing_percentage,default_verification_mode,past_step_policy,future_step_policy').eq('id', draftProgramId).single()).data).toMatchObject({ quiz_passing_percentage: 71, default_verification_mode: 'automatic', past_step_policy: 'read_only', future_step_policy: 'available' }); await page.goBack();
    await page.getByRole('button', { name: /Konten program/ }).click(); await expect(page.getByText('Rentang jadwal', { exact: true })).toBeVisible(); await page.getByRole('button', { name: /Hari ke-1 · Hari pertama/ }).click(); await page.getByRole('button', { name: 'Tambah langkah' }).click(); await expect(page.getByRole('button', { name: 'Artikel', exact: true })).toBeVisible(); await expect(page.getByRole('button', { name: 'Timbang harian', exact: true })).toBeVisible(); await page.getByRole('button', { name: 'Video', exact: true }).click(); await expect(page.getByTestId('admin.step.editor')).toBeVisible(); await expect.poll(async () => { const days = await service.from('program_days').select('program_steps(content_kind,verification_mode)').eq('program_id', draftProgramId); return days.data?.flatMap((day) => day.program_steps).find((step) => step.content_kind === 'video')?.verification_mode; }).toBe('automatic'); await page.goBack(); await page.goBack(); await page.goBack();
    await page.getByRole('button', { name: /Tinjau & terbitkan/ }).click(); await page.getByRole('button', { name: /Pratinjau program/ }).click(); await expect(page.getByRole('tab', { name: 'Peserta' })).toBeVisible(); await expect(page.getByText('Tampilan ini sama dengan yang dilihat Peserta.')).toBeVisible();
    await expect(page.getByTestId('admin.program.preview.shared-renderer')).toBeVisible(); await page.getByRole('tab', { name: 'Coach' }).click(); await expect(page.getByText('Tampilan ini sama dengan yang dilihat Coach.')).toBeVisible(); await page.goBack();
    await page.getByRole('button', { name: 'Terbitkan program' }).click(); await expect(page).toHaveURL(new RegExp(`/admin/programs/${draftProgramId}$`)); await expect(page.getByRole('heading', { name: 'Program sudah diterbitkan' }).first()).toBeVisible();
    expect((await service.from('programs').select('status').eq('id', draftProgramId).single()).data?.status).toBe('scheduled');
    await page.getByRole('button', { name: 'Duplikasikan sebagai draft' }).click(); await expect(page.getByText('Selesaikan 3 tahap')).toBeVisible(); await expect(page.getByText(/Salinan/).first()).toBeVisible();
  });

  test('People fallback and score operations work through protected server actions', async ({ page }) => {
    test.skip(!canRun || !adminSession, 'Memerlukan Supabase lokal.'); await installSession(page, adminSession); await page.goto('/admin/people');
    const person = page.getByTestId(`admin.people.open.${participantId}`); await expect(person).toBeVisible(); await person.click(); await expect(page.getByText('Profil Peserta')).toBeVisible();
    await page.getByRole('radio', { name: new RegExp(activeTitle) }).click(); await page.getByLabel('Alasan enrollment').fill('Pendaftaran manual setelah pemeriksaan Admin W07.'); await page.getByRole('button', { name: 'Daftarkan peserta' }).click();
    await expect.poll(async () => (await service.from('program_enrollments').select('id').eq('participant_id', participantId).eq('program_id', activeProgramId)).data?.length).toBe(1);
    await page.reload(); await page.getByRole('radio', { name: new RegExp(activeTitle) }).last().click(); await page.getByLabel('Jumlah poin').fill('7'); await page.getByLabel('Alasan penyesuaian').fill('Koreksi poin end-to-end W07.'); await page.getByRole('button', { name: 'Simpan penyesuaian' }).click();
    const enrollmentId = (await service.from('program_enrollments').select('id').eq('participant_id', participantId).eq('program_id', activeProgramId).single()).data!.id;
    await expect.poll(async () => (await service.from('program_scores').select('adjustment_points').eq('enrollment_id', enrollmentId).single()).data?.adjustment_points).toBe(7);
  });

  test('Profile moderation rejects with a reason and AI operations stay redacted', async ({ page }) => {
    test.skip(!canRun || !adminSession, 'Memerlukan Supabase lokal.'); await installSession(page, adminSession); await page.goto('/admin/content?scope=moderation');
    const moderation = page.getByTestId(`admin.moderation.item.${moderationItemId}`); await expect(moderation.getByText('Testimoni E2E W07')).toBeVisible(); await moderation.getByRole('button', { name: 'Tolak' }).click(); const submit = moderation.getByRole('button', { name: 'Tolak konten' }); await expect(submit).toBeDisabled(); await moderation.getByLabel('Alasan penolakan').fill('Identitas subjek perlu disamarkan sebelum publikasi.'); await submit.click();
    await expect.poll(async () => (await service.from('coach_public_profile_items').select('moderation_status').eq('id', moderationItemId).single()).data?.moderation_status).toBe('rejected');
    await page.getByRole('tab', { name: 'Insight AI' }).click(); await expect(page.getByText('Data sensitif disamarkan')).toBeVisible(); const body = await page.locator('body').innerText(); expect(body).not.toMatch(/private_photo_path|lease_token|FOOD_AI_API_KEY|signed_url/u);
    await page.getByRole('tab', { name: 'Poster' }).click(); await page.getByRole('button', { name: /Poster pemenang, tambahkan gambar/ }).click(); await page.getByRole('radio', { name: new RegExp(completedTitle) }).click(); await page.getByLabel('Pilih poster pemenang').setInputFiles({ name: 'poster.png', mimeType: 'image/png', buffer: readFileSync('tests/e2e/feasibility.spec.ts-snapshots/landing-390-chromium-compact-darwin.png') }); await page.getByLabel('Teks alternatif').fill('Poster pemenang pengujian W07.'); await page.getByRole('button', { name: 'Simpan poster' }).click();
    await expect.poll(async () => (await service.from('winner_posters').select('id').eq('program_id', completedProgramId)).data?.length).toBe(1);
  });
});

async function createIdentity(label: string) { const suffix = randomUUID(); const email = `${label}-${suffix}@test.invalid`; const password = `W07-${suffix}!`; const response = await service.auth.admin.createUser({ email, password, email_confirm: true }); expect(response.error).toBeNull(); return { id: response.data.user!.id, email, password }; }
async function activateProfile(id: string, role: 'participant' | 'coach' | 'admin', displayName: string) { expect((await service.from('profiles').update({ role, display_name: displayName, onboarding_status: 'active', provisional_expires_at: null, finalized_at: new Date().toISOString() }).eq('user_id', id)).error).toBeNull(); }
async function activateCoach() { const applicationId = randomUUID(); const paymentId = randomUUID(); expect((await service.from('coach_applications').insert({ id: applicationId, applicant_user_id: coachId, participant_profile_id: coachId, display_name_snapshot: 'Coach E2E W07', phone_number_snapshot: '+6281200000711', member_level_snapshot: 'sc', has_completed_hom_sts: true, has_completed_ict: true, terms_version: 'w07-e2e', status: 'active', draft_idempotency_key: `w07-${randomUUID()}`, submitted_at: new Date().toISOString(), decided_at: new Date().toISOString(), decided_by: adminId })).error).toBeNull(); expect((await service.from('coach_payment_records').insert({ id: paymentId, application_id: applicationId, state: 'verified', price_band: 'entry', amount_minor_units: 100_000, duration_months: 3, provider_reference: `w07-${randomUUID()}`, verified_at: new Date().toISOString() })).error).toBeNull(); expect((await service.from('coach_access_entitlements').insert({ application_id: applicationId, payment_record_id: paymentId, coach_user_id: coachId, status: 'active', starts_at: new Date(Date.now() - 60_000).toISOString(), ends_at: new Date(Date.now() + 90 * 86_400_000).toISOString() })).error).toBeNull(); }
async function signInClient(email: string, password: string) { const client = createClient(localUrl as string, publishableKey as string, { auth: { persistSession: false, autoRefreshToken: false } }); expect((await client.auth.signInWithPassword({ email, password })).error).toBeNull(); return client; }
async function installSession(page: import('@playwright/test').Page, session: Session) { const key = `sb-${new URL(localUrl as string).hostname.split('.')[0]}-auth-token`; const value = JSON.stringify(session); await page.addInitScript(({ key, value }) => globalThis.localStorage.setItem(key, value), { key, value }); }
function date(offset: number) { return new Date(Date.now() + offset * 86_400_000).toISOString().slice(0, 10); }
function programPayload(id: string, title: string, start: string) { const dayId = randomUUID(); return { id, title, summary: 'Program valid untuk perjalanan Admin W07.', category: 'Transformasi', cover_path: `programs/${id}.jpg`, cover_alt_text: `Cover ${title}`, pace: 'scheduled', duration_mode: 'specific_dates', starts_on: start, ends_on: date(start === date(0) ? 1 : 2), timezone: 'Asia/Makassar', participant_limit: 20, registration_closes_at: start === date(0) ? new Date(Date.now() - 60_000).toISOString() : null, past_step_policy: 'available', future_step_policy: 'locked', wellness_disclaimer: 'Program wellness non-diagnostik.', points_per_activity: 10, points_per_weight_kg: 0, quiz_passing_percentage: 70, pricing_mode: 'free', desired_price: null, days: [{ id: dayId, day_number: 1, title: 'Hari pertama', summary: 'Mulai', scheduled_on: start, steps: [{ id: randomUUID(), step_order: 1, title: 'Bacaan pembuka', instructions: 'Baca materi.', content_kind: 'article', completion_policy: 'mark_complete', verification_mode: 'automatic', questions: [] }] }] }; }
