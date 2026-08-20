import { expect, test } from '@playwright/test';
import { createClient, type Session, type SupabaseClient } from '@supabase/supabase-js';
import { randomUUID } from 'node:crypto';

const localUrl = process.env.API_URL;
const publishableKey = process.env.PUBLISHABLE_KEY ?? process.env.ANON_KEY;
const secretKey = process.env.SECRET_KEY ?? process.env.SERVICE_ROLE_KEY;
const canRunAuthenticated = localUrl !== undefined && publishableKey !== undefined && secretKey !== undefined;

let service: SupabaseClient | undefined;
let userId: string | undefined;
let enrollmentId: string | undefined;
let programId: string | undefined;
let programDayId: string | undefined;
let programStepId: string | undefined;
let session: Session | undefined;

test.describe('W03 Participant program experience', () => {
  test.beforeAll(async () => {
    if (!canRunAuthenticated) return;
    expect(['127.0.0.1', 'localhost']).toContain(new URL(localUrl as string).hostname);
    service = createClient(localUrl as string, secretKey as string, { auth: { persistSession: false, autoRefreshToken: false } });
    const suffix = randomUUID();
    const email = `w03-browser-${suffix}@test.invalid`;
    const password = `W03-${suffix}!`;
    const created = await service.auth.admin.createUser({ email, password, email_confirm: true });
    expect(created.error).toBeNull();
    userId = created.data.user?.id;
    enrollmentId = randomUUID();

    const { data: coachRows } = await service.from('profiles').select('user_id').eq('role', 'coach').limit(1);
    const { data: adminRows } = await service.from('profiles').select('user_id').eq('role', 'admin').limit(1);
    const coachId = coachRows?.[0]?.user_id;
    const adminId = adminRows?.[0]?.user_id;
    programId = randomUUID();
    programDayId = randomUUID();
    programStepId = randomUUID();
    expect(coachId).toBeTruthy();
    expect(adminId).toBeTruthy();

    expect((await service.from('programs').insert({
      id: programId,
      title: 'Program Integration Storage',
      summary: 'Fixture deterministik browser W03.',
      status: 'active',
      pace: 'scheduled',
      duration_mode: 'specific_dates',
      starts_on: localDate(-1),
      ends_on: localDate(2),
      timezone: 'Asia/Makassar',
      past_step_policy: 'read_only',
      future_step_policy: 'locked',
      wellness_disclaimer: 'Program wellness non-diagnostik.',
      points_per_activity: 10,
      points_per_weight_kg: 100,
      quiz_passing_percentage: 70,
      pricing_mode: 'free',
      desired_price: null,
      participant_limit: 20,
      published_at: new Date().toISOString(),
      created_by: adminId as string,
    })).error).toBeNull();
    expect((await service.from('program_days').insert({ id: programDayId, program_id: programId, day_number: 1, title: 'Hari pertama', scheduled_on: localDate(0) })).error).toBeNull();
    expect((await service.from('program_steps').insert({ id: programStepId, program_day_id: programDayId, step_order: 1, title: 'Unggah Foto', instructions: 'Unggah foto jawaban.', content_kind: 'form', completion_policy: 'answer_all_questions', verification_mode: 'coach_review' })).error).toBeNull();
    expect((await service.from('program_questions').insert({ step_id: programStepId, question_order: 1, prompt: 'Unggah foto jawaban', kind: 'photo_upload' })).error).toBeNull();

    expect((await service.from('profiles').update({
      role: 'participant',
      display_name: 'Peserta Browser W03',
      current_coach_id: coachId,
      onboarding_status: 'active',
      provisional_expires_at: null,
      finalized_at: new Date().toISOString(),
    }).eq('user_id', userId as string)).error).toBeNull();
    expect((await service.from('program_enrollments').insert({
      id: enrollmentId,
      program_id: programId,
      participant_id: userId as string,
      coach_id: coachId as string,
      status: 'active',
    })).error).toBeNull();
    expect((await service.from('program_scores').insert({
      enrollment_id: enrollmentId,
      activity_points: 20,
      quiz_points: 0,
      weight_points: 0,
      adjustment_points: 0,
      progress_percentage: 25,
      rank: 3,
    })).error).toBeNull();

    const participant = createClient(localUrl as string, publishableKey as string, { auth: { persistSession: false, autoRefreshToken: false } });
    const signedIn = await participant.auth.signInWithPassword({ email, password });
    expect(signedIn.error).toBeNull();
    session = signedIn.data.session ?? undefined;
    expect(session).toBeTruthy();
  });

  test.afterAll(async () => {
    if (!service) return;
    if (enrollmentId) await service.from('program_scores').delete().eq('enrollment_id', enrollmentId);
    if (enrollmentId) await service.from('program_enrollments').delete().eq('id', enrollmentId);
    if (programStepId) await service.from('program_questions').delete().eq('step_id', programStepId);
    if (programStepId) await service.from('program_steps').delete().eq('id', programStepId);
    if (programDayId) await service.from('program_days').delete().eq('id', programDayId);
    if (programId) await service.from('programs').delete().eq('id', programId);
    if (userId) await service.auth.admin.deleteUser(userId);
  });

  test('Guest preserves catalog segment in the URL and browser Back', async ({ page }) => {
    await page.goto('/app/programs?segment=available');
    await expect(page.getByRole('tab', { name: 'Tersedia' })).toHaveAttribute('aria-selected', 'true');
    await page.getByRole('tab', { name: 'Diikuti' }).click();
    await expect(page).toHaveURL(/segment=joined/);
    await expect(page.getByText('Masuk diperlukan')).toBeVisible();
    await page.goBack();
    await expect(page).toHaveURL(/segment=available/);
    await expect(page.getByRole('tab', { name: 'Tersedia' })).toHaveAttribute('aria-selected', 'true');
  });

  test('offer stays readable at 320/390/430 in light and dark appearance', async ({ page }) => {
    await page.goto('/app/programs?segment=available');
    const programLink = page.getByRole('link').filter({ hasText: 'Program Integration Storage' }).first();
    await expect(programLink).toBeVisible();
    await programLink.click();

    for (const colorScheme of ['light', 'dark'] as const) {
      await page.emulateMedia({ colorScheme });
      for (const width of [320, 390, 430]) {
        await page.setViewportSize({ width, height: 844 });
        await expect(page.getByRole('button', { name: 'Gabung program' })).toBeVisible();
        const dimensions = await page.evaluate(() => ({
          viewport: globalThis.innerWidth,
          document: globalThis.document.documentElement.scrollWidth,
          background: globalThis.getComputedStyle(globalThis.document.body).backgroundColor,
        }));
        expect(dimensions.document).toBeLessThanOrEqual(dimensions.viewport);
        expect(dimensions.background).toBe(colorScheme === 'dark' ? 'rgb(0, 0, 0)' : 'rgb(255, 255, 255)');
      }
    }
  });

  test('Participant navigates Home, catalog, activity, step, and browser Back', async ({ page }) => {
    test.skip(!canRunAuthenticated || session === undefined || programId === undefined, 'Memerlukan Supabase lokal.');
    await page.addInitScript(({ key, value }) => globalThis.localStorage.setItem(key, value), {
      key: `sb-${new URL(localUrl as string).hostname.split('.')[0]}-auth-token`,
      value: JSON.stringify(session),
    });

    await page.goto('/app/home');
    await expect(page.getByTestId('participant.home')).toBeVisible();
    const headings = await page.getByRole('heading').allTextContents();
    const sectionOrder = ['Program', 'Fokus hari ini', 'Leaderboard Top 5', 'Pemenang terbaru', 'Coach'].map((label) => headings.indexOf(label));
    expect(sectionOrder.every((position) => position >= 0)).toBe(true);
    expect([...sectionOrder].sort((left, right) => left - right)).toEqual(sectionOrder);

    await page.getByRole('link', { name: 'Program', exact: true }).click();
    await expect(page).toHaveURL(/\/app\/programs/);
    await expect(page.getByRole('tab', { name: 'Diikuti' })).toHaveAttribute('aria-selected', 'true');
    const programLink = page.getByRole('link').filter({ hasText: 'Program Integration Storage' });
    await expect(programLink).toBeVisible();
    await programLink.click();
    await expect(page.getByTestId('participant.program.activity')).toBeVisible();
    await expect(page.getByRole('heading', { name: 'Aktivitas program' })).toBeVisible();

    const step = page.getByRole('button', { name: /Unggah Foto/ });
    await expect(step).toBeVisible();
    await step.click();
    await expect(page.getByTestId('participant.step.renderer')).toBeVisible();
    await expect(page.getByRole('heading', { name: 'Jawaban aktivitas' })).toBeVisible();
    await expect(page.getByTestId('participant.submission.form').getByText('Unggah foto jawaban')).toBeVisible();
    await expect(page.getByLabel('Ambil atau pilih foto')).toBeEnabled();
    expect(await page.locator('body').innerText()).not.toContain('coach_qr_identifier');
    expect(await page.locator('body').innerText()).not.toContain('Berat awal');

    await page.goBack();
    await expect(page.getByTestId('participant.program.activity')).toBeVisible();
    await page.goBack();
    await expect(page.getByTestId('participant.program.catalog')).toBeVisible();
  });
});

function localDate(offset: number) {
  return new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Makassar', year: 'numeric', month: '2-digit', day: '2-digit' })
    .format(new Date(Date.now() + offset * 86_400_000));
}
