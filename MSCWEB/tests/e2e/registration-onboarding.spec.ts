import { expect, test } from '@playwright/test';
import { createClient, type Session, type SupabaseClient } from '@supabase/supabase-js';
import { randomUUID } from 'node:crypto';

const localUrl = process.env.API_URL;
const publishableKey = process.env.PUBLISHABLE_KEY ?? process.env.ANON_KEY;
const secretKey = process.env.SECRET_KEY ?? process.env.SERVICE_ROLE_KEY;
const canRun = localUrl !== undefined && publishableKey !== undefined && secretKey !== undefined;

test.describe.configure({ mode: 'serial' });
test.describe('W07.4 registration onboarding', () => {
  let service: SupabaseClient;
  let participantSession: Session;
  let coachIntentSession: Session;
  let backSession: Session;
  let backUserId = '';
  const userIds: string[] = [];

  test.beforeAll(async () => {
    if (!canRun) return;
    service = createClient(localUrl as string, secretKey as string, { auth: { persistSession: false, autoRefreshToken: false } });
    const suffix = randomUUID();
    const participant = await createIdentity(service, `w074-participant-${suffix}@test.invalid`, `W074-P-${suffix}!`);
    const coachIntent = await createIdentity(service, `w074-coach-${suffix}@test.invalid`, `W074-C-${suffix}!`);
    const backUser = await createIdentity(service, `w074-back-${suffix}@test.invalid`, `W074-B-${suffix}!`);
    backUserId = backUser.id;
    userIds.push(participant.id, coachIntent.id, backUser.id);
    participantSession = await signIn(participant.email, participant.password);
    coachIntentSession = await signIn(coachIntent.email, coachIntent.password);
    backSession = await signIn(backUser.email, backUser.password);
    for (const session of [participantSession, coachIntentSession, backSession]) {
      const response = await sessionClient(session).rpc('get_my_session_context');
      expect(response.error).toBeNull();
      expect(response.data).toEqual(expect.objectContaining({ onboarding_status: 'provisional', resume_step: 'profile' }));
    }
  });

  test.afterAll(async () => {
    if (!canRun || !service) return;
    const orders = await service.from('payment_orders').select('id').in('owner_user_id', userIds);
    const orderIds = (orders.data ?? []).map((row) => row.id);
    if (orderIds.length) {
      await service.from('payment_events').delete().in('order_id', orderIds);
      await service.from('payment_evidence_attempts').delete().in('order_id', orderIds);
      await service.from('payment_orders').delete().in('id', orderIds);
    }
    await service.from('coach_applications').delete().in('applicant_user_id', userIds);
    for (const id of userIds) await service.auth.admin.deleteUser(id);
  });

  test('new Participant completes profile purpose and reaches QR-only Coach confirmation', async ({ page }, testInfo) => {
    test.skip(!canRun || !participantSession, 'Memerlukan Supabase lokal.');
    await installSession(page, participantSession);
    await page.goto('/app');
    await expect(page).toHaveURL(/\/onboarding\/profile$/u);
    await expect(page.getByRole('heading', { name: 'Lengkapi profil' })).toBeVisible();
    await page.screenshot({ path: `/private/tmp/w074-${testInfo.project.name}-profile.png`, fullPage: true });
    await page.getByRole('textbox', { name: 'Nama' }).fill('Peserta Onboarding');
    await page.getByRole('textbox', { name: 'Nomor HP' }).fill('+6281234567890');
    await page.getByLabel('Level member').selectOption('sc');
    await page.getByRole('radio', { name: /Lanjut sebagai Peserta/ }).click();
    await page.getByRole('button', { name: 'Lanjut sebagai Peserta' }).click();
    await expect(page).toHaveURL(/\/onboarding\/participant\/coach$/u);
    await expect(page.getByText('Akun MSC belum aktif')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Pindai QR Coach' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Aktifkan akun Peserta' })).toBeDisabled();
    await expect(page.locator('body')).not.toContainText(/masukkan kode|kode Coach|salin kode/iu);
    await page.reload();
    await expect(page.getByText('Akun MSC belum aktif')).toBeVisible();
    await page.goBack();
    await expect(page).toHaveURL(/\/onboarding\/profile$/u);
    await page.goForward();
    await expect(page).toHaveURL(/\/onboarding\/participant\/coach$/u);
    await page.emulateMedia({ colorScheme: 'dark', reducedMotion: 'reduce' });
    await page.evaluate(() => { document.documentElement.style.fontSize = '200%'; });
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true);
    await page.screenshot({ path: `/private/tmp/w074-${testInfo.project.name}-participant-qr.png`, fullPage: true });
  });

  test('Member disables Coach intent, while SC reaches manual three-month payment', async ({ page }, testInfo) => {
    test.skip(!canRun || !coachIntentSession, 'Memerlukan Supabase lokal.');
    await installSession(page, coachIntentSession);
    await page.goto('/onboarding/profile');
    await expect(page).toHaveURL(/\/onboarding\/profile$/u);
    await expect(page.getByRole('heading', { name: 'Lengkapi profil' })).toBeVisible();
    await page.getByRole('textbox', { name: 'Nama' }).fill('Calon Coach Onboarding');
    await page.getByRole('textbox', { name: 'Nomor HP' }).fill('+6281234567891');
    await expect(page.getByRole('radio', { name: /Ajukan menjadi Coach/ })).toBeDisabled();
    await page.getByLabel('Level member').selectOption('sc');
    await page.getByRole('radio', { name: /Ajukan menjadi Coach/ }).click();
    await page.getByRole('button', { name: 'Lanjut ke syarat Coach' }).click();
    await expect(page).toHaveURL(/\/onboarding\/coach\/eligibility$/u);
    await expect(page.getByText(/Rp\s*100\.000/u)).toBeVisible();
    await expect(page.getByText('Tidak ada perpanjangan otomatis.')).toBeVisible();
    await page.screenshot({ path: `/private/tmp/w074-${testInfo.project.name}-coach-eligibility.png`, fullPage: true });
    const homSts = page.getByRole('checkbox', { name: 'Saya sudah menyelesaikan HOM STS' });
    const ict = page.getByRole('checkbox', { name: 'Saya sudah menyelesaikan ICT' });
    const terms = page.getByRole('checkbox', { name: /Saya menyatakan data benar/ });
    await homSts.click(); await expect(homSts).toBeChecked();
    await ict.click(); await expect(ict).toBeChecked();
    await terms.click(); await expect(terms).toBeChecked();
    await page.getByRole('button', { name: 'Lanjut ke pembayaran Coach' }).click();
    await expect(page).toHaveURL(/\/onboarding\/coach\/payment$/u);
    await expect(page.getByRole('heading', { name: 'Tujuan pembayaran' })).toBeVisible();
    await expect(page.getByText(/Akses berlaku tiga bulan/iu)).toBeVisible();
    await expect(page.getByRole('button', { name: 'Kirim bukti pembayaran' })).toBeDisabled();
    await page.screenshot({ path: `/private/tmp/w074-${testInfo.project.name}-coach-payment.png`, fullPage: true });
  });

  test('Back from first profile signs out but preserves the provisional draft', async ({ page }) => {
    test.skip(!canRun || !backSession, 'Memerlukan Supabase lokal.');
    await installSession(page, backSession);
    await page.goto('/onboarding/profile');
    await expect(page.getByRole('heading', { name: 'Lengkapi profil' })).toBeVisible();
    await page.getByRole('button', { name: 'Kembali' }).click();
    await expect(page).toHaveURL(/\/login$/u);
    await expect(page.getByRole('heading', { name: 'Masuk ke MSC' })).toBeVisible();
    expect((await service.from('profiles').select('onboarding_status').eq('user_id', backUserId).single()).data?.onboarding_status).toBe('provisional');
  });
});

async function createIdentity(service: SupabaseClient, email: string, password: string) {
  const response = await service.auth.admin.createUser({ email, password, email_confirm: true, user_metadata: { full_name: 'Nama Google' } });
  expect(response.error).toBeNull();
  return { id: response.data.user?.id as string, email, password };
}

async function signIn(email: string, password: string): Promise<Session> {
  const client = createClient(localUrl as string, publishableKey as string, { auth: { persistSession: false, autoRefreshToken: false } });
  const response = await client.auth.signInWithPassword({ email, password });
  expect(response.error).toBeNull();
  return response.data.session as Session;
}

function sessionClient(session: Session) {
  return createClient(localUrl as string, publishableKey as string, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { Authorization: `Bearer ${session.access_token}` } },
  });
}

async function installSession(page: import('@playwright/test').Page, session: Session) {
  await page.addInitScript(({ key, value }) => globalThis.localStorage.setItem(key, value), { key: authKey(), value: JSON.stringify(session) });
}

function authKey() { return `sb-${new URL(localUrl as string).hostname.split('.')[0]}-auth-token`; }
