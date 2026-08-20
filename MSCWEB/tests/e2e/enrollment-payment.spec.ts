import { expect, test } from '@playwright/test';
import { createClient, type Session, type SupabaseClient } from '@supabase/supabase-js';
import { randomUUID } from 'node:crypto';
import { readFileSync } from 'node:fs';

const localUrl = process.env.API_URL;
const publishableKey = process.env.PUBLISHABLE_KEY ?? process.env.ANON_KEY;
const secretKey = process.env.SECRET_KEY ?? process.env.SERVICE_ROLE_KEY;
const canRun = localUrl !== undefined && publishableKey !== undefined && secretKey !== undefined;

let service: SupabaseClient;
let adminSession: Session;
let participantSession: Session;
let adminId = '';
let participantId = '';
let programId = '';
let freeProgramId = '';
let orderId = '';
let destinationId = '';
let previousDestination: {
  bank_code: string;
  bank_name: string;
  account_name: string;
  account_reference: string;
  instructions: string;
  qris_object_path: string | null;
} | undefined;

test.describe('W05 enrollment and manual payment journey', () => {
  test.beforeAll(async () => {
    if (!canRun) return;
    expect(['127.0.0.1', 'localhost']).toContain(new URL(localUrl as string).hostname);
    service = createClient(localUrl as string, secretKey as string, { auth: { persistSession: false, autoRefreshToken: false } });
    const suffix = randomUUID();
    const admin = await createIdentity(`w05-browser-admin-${suffix}@test.invalid`, `W05-A-${suffix}!`);
    const participant = await createIdentity(`w05-browser-participant-${suffix}@test.invalid`, `W05-P-${suffix}!`);
    adminId = admin.id;
    participantId = participant.id;
    await updateProfile(adminId, { role: 'admin', display_name: 'Admin Browser W05' });
    await updateProfile(participantId, { role: 'participant', display_name: 'Peserta Browser W05' });
    const { data: coaches } = await service.from('profiles').select('user_id,coach_qr_identifier').eq('role', 'coach').eq('coach_is_approved', true).not('coach_qr_identifier', 'is', null).limit(1);
    const coachQr = coaches?.[0]?.coach_qr_identifier as string;
    expect(coachQr).toBeTruthy();
    programId = randomUUID();
    freeProgramId = randomUUID();
    expect((await service.from('programs').insert({
      id: programId, title: 'Program Pembayaran Browser W05', summary: 'Fixture lokal pembayaran manual.', category: 'Pengujian lokal berulang', status: 'active', pace: 'scheduled', duration_mode: 'specific_dates', starts_on: localDate(-1), ends_on: localDate(5), timezone: 'Asia/Makassar', past_step_policy: 'read_only', future_step_policy: 'locked', wellness_disclaimer: 'Program wellness non-diagnostik.', points_per_activity: 10, points_per_weight_kg: 100, quiz_passing_percentage: 70, pricing_mode: 'paid', desired_price: 125_000, participant_limit: 10, published_at: new Date().toISOString(), created_by: adminId,
    })).error).toBeNull();
    expect((await service.from('programs').insert({
      id: freeProgramId, title: 'Program Gratis Browser W05', summary: 'Fixture lokal program gratis.', status: 'active', pace: 'scheduled', duration_mode: 'specific_dates', starts_on: localDate(-1), ends_on: localDate(5), timezone: 'Asia/Makassar', past_step_policy: 'read_only', future_step_policy: 'locked', wellness_disclaimer: 'Program wellness non-diagnostik.', points_per_activity: 10, points_per_weight_kg: 100, quiz_passing_percentage: 70, pricing_mode: 'free', desired_price: null, participant_limit: 10, published_at: new Date().toISOString(), created_by: adminId,
    })).error).toBeNull();
    adminSession = await signIn(admin.email, admin.password);
    participantSession = await signIn(participant.email, participant.password);
    const adminClient = sessionClient(adminSession);
    const now = new Date().toISOString();
    const destinationBeforeTest = await service
      .from('payment_destinations')
      .select('bank_code,bank_name,account_name,account_reference,instructions,qris_object_path')
      .lte('effective_from', now)
      .or(`effective_until.is.null,effective_until.gt.${now}`)
      .in('status', ['active', 'scheduled'])
      .order('version', { ascending: false })
      .limit(1)
      .maybeSingle();
    expect(destinationBeforeTest.error).toBeNull();
    previousDestination = destinationBeforeTest.data ?? undefined;
    const destination = await adminClient.rpc('create_payment_destination', {
      destination_bank_code: 'TST', destination_bank_name: 'Bank Uji Tidak Dapat Dibayar', destination_account_name: 'FIXTURE BROWSER W05', destination_account_reference: '0000000000', destination_instructions: 'Jangan melakukan pembayaran nyata ke rekening fixture ini.', effective_at: new Date().toISOString(), destination_qris_object_path: null,
    });
    expect(destination.error).toBeNull();
    destinationId = row(destination.data).id as string;
    const participantClient = sessionClient(participantSession);
    const createdOrder = await participantClient.rpc('create_program_payment_order', { target_program_id: programId, coach_qr_payload: coachQr, payment_method: 'bank_transfer', request_idempotency_key: `w05-browser-${suffix}` });
    expect(createdOrder.error).toBeNull();
    orderId = row(createdOrder.data).id as string;
  });

  test.afterAll(async () => {
    if (!canRun || !service) return;
    // Payment events and ledger rows are intentionally immutable. Archive the paid
    // fixture first so an interrupted or partially clean teardown can never leave a
    // test program visible in the public Participant catalog.
    if (programId) {
      await service.from('programs').update({ status: 'archived', published_at: null }).eq('id', programId);
    }
    if (orderId) {
      const { data: attempts } = await service.from('payment_evidence_attempts').select('object_path').eq('order_id', orderId);
      if (attempts?.length) await service.storage.from('payment-evidence').remove(attempts.map((attempt) => attempt.object_path));
      await service.from('audit_events').delete().eq('subject_id', orderId);
      await service.from('payment_evidence_attempts').delete().eq('order_id', orderId);
      await service.from('program_entitlements').delete().eq('program_id', programId);
      await service.from('commerce_transactions').delete().eq('program_id', programId);
      await service.from('payment_orders').delete().eq('id', orderId);
    }
    if (programId) {
      const { data: enrollments } = await service.from('program_enrollments').select('id').eq('program_id', programId);
      if (enrollments?.length) await service.from('program_scores').delete().in('enrollment_id', enrollments.map(({ id }) => id));
      await service.from('program_enrollments').delete().eq('program_id', programId);
      await service.from('programs').delete().eq('id', programId);
    }
    if (freeProgramId) await service.from('programs').delete().eq('id', freeProgramId);
    if (destinationId) await service.from('payment_destinations').delete().eq('id', destinationId);
    if (previousDestination && adminSession) {
      let restorableQrisPath = previousDestination.qris_object_path;
      if (restorableQrisPath) {
        const object = await service.storage.from('payment-destination-assets').download(restorableQrisPath);
        if (object.error) restorableQrisPath = null;
      }
      const restored = await sessionClient(adminSession).rpc('create_payment_destination', {
        destination_bank_code: previousDestination.bank_code,
        destination_bank_name: previousDestination.bank_name,
        destination_account_name: previousDestination.account_name,
        destination_account_reference: previousDestination.account_reference,
        destination_instructions: previousDestination.instructions,
        effective_at: new Date().toISOString(),
        destination_qris_object_path: restorableQrisPath,
      });
      expect(restored.error).toBeNull();
    }
    for (const id of [participantId, adminId]) if (id) await service.auth.admin.deleteUser(id);
  });

  test('Participant resubmits a rejected proof and Admin atomically approves enrollment', async ({ page }, testInfo) => {
    test.skip(!canRun || !participantSession || !adminSession, 'Memerlukan Supabase lokal.');
    await installSession(page, participantSession);
    await page.goto(`/app/payments/${programId}`);
    await expect(page.getByTestId('participant.payment.order')).toBeVisible();
    await page.setViewportSize({ width: 390, height: 844 });
    const paymentScrollArea = page.getByTestId('participant.payment.order');
    await expect.poll(() => paymentScrollArea.evaluate((element) => element.scrollHeight > element.clientHeight)).toBe(true);
    await paymentScrollArea.evaluate((element) => { element.scrollTop = element.scrollHeight; });
    await expect.poll(() => paymentScrollArea.evaluate((element) => element.scrollTop)).toBeGreaterThan(0);
    await expect(page.getByText(/Rp\s*125\.000/).first()).toBeVisible();
    await expect(page.getByText('Atas nama')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Salin jumlah pembayaran' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Salin nomor rekening' })).toBeVisible();
    await expect(page.getByText('Anda belum terdaftar sampai pembayaran disetujui.')).not.toBeVisible();
    await page.screenshot({ path: testInfo.outputPath('participant-payment.png'), fullPage: true });
    await uploadProof(page, testInfo.outputPath('participant-direct-submit.png'));
    await expect(page.getByText('Sedang diperiksa').first()).toBeVisible();
    await expect(page.getByText('Upload dikunci sementara')).toBeVisible();
    await expect(page.getByText('Mode pengujian lokal')).toBeVisible();
    await repeatLocalUpload(page);

    await switchSession(page, adminSession);
    await page.goto('/admin/payments');
    await expect(page.getByRole('tab', { name: /Perlu tindakan \(\d+\)/ })).toBeVisible();
    await page.getByRole('button', { name: /Peserta Browser W05/ }).click();
    await expect(page.getByLabel('Bukti pembayaran pribadi')).toBeVisible();
    await page.getByRole('button', { name: 'Tolak', exact: true }).click();
    const reject = page.getByRole('button', { name: 'Tolak bukti' });
    await expect(reject).toBeDisabled();
    await page.getByLabel('Alasan penolakan').fill('Bukti kurang jelas. Kirim foto yang lebih tajam.');
    await reject.click();
    await expect(page).toHaveURL(/\/admin\/payments$/);

    await switchSession(page, participantSession);
    await page.goto(`/app/payments/${programId}`);
    await expect(page.getByText('Perlu perbaikan').first()).toBeVisible();
    await expect(page.getByText('Bukti kurang jelas. Kirim foto yang lebih tajam.').first()).toBeVisible();
    await uploadProof(page);
    await expect(page.getByText('Sedang diperiksa').first()).toBeVisible();

    await switchSession(page, adminSession);
    await page.goto(`/admin/payments/${orderId}`);
    await expect(page.getByLabel('Bukti pembayaran pribadi')).toBeVisible();
    await page.getByRole('button', { name: 'Setujui', exact: true }).click();
    await expect(page.getByText(/Program Pembayaran Browser W05.*Rp\s*125\.000/).last()).toBeVisible();
    await page.screenshot({ path: testInfo.outputPath('admin-payment-approval.png'), fullPage: true });
    await page.getByLabel('Referensi rekonsiliasi').fill('REK-W05-LOCAL');
    await page.getByRole('checkbox', { name: /Tujuan dan jumlah cocok/ }).click();
    await expect(page.getByRole('checkbox', { name: /Tujuan dan jumlah cocok/ })).toHaveAttribute('aria-checked', 'true');
    await page.getByRole('button', { name: 'Setujui pembayaran' }).click();
    await expect(page).toHaveURL(/\/admin\/payments$/);

    const [order, enrollment, entitlement, ledger] = await Promise.all([
      service.from('payment_orders').select('status').eq('id', orderId).single(),
      service.from('program_enrollments').select('status').eq('program_id', programId).eq('participant_id', participantId).single(),
      service.from('program_entitlements').select('id').eq('program_id', programId).eq('participant_id', participantId),
      service.from('payment_ledger').select('id').eq('order_id', orderId),
    ]);
    expect(order.data?.status).toBe('approved');
    expect(enrollment.data?.status).toBe('active');
    expect(entitlement.data).toHaveLength(1);
    expect(ledger.data).toHaveLength(1);
    const body = await page.locator('body').innerText();
    expect(body).not.toContain('payment-evidence');
    expect(body).not.toContain('/normalized.jpg');
  });

  test('Program gratis membuka alur pendaftaran tanpa loading tanpa batas', async ({ page }) => {
    test.skip(!canRun || !participantSession, 'Memerlukan Supabase lokal.');
    await installSession(page, participantSession);
    await page.goto(`/app/payments/${freeProgramId}`);
    await expect(page.getByTestId('participant.enrollment.flow')).toBeVisible();
    await expect(page.getByText('Tunggu sebentar.')).not.toBeVisible();
    await expect(page.getByRole('button', { name: 'Pindai QR Coach' })).toBeVisible();
    await expect(page.getByText('Konfirmasi Coach')).not.toBeVisible();
    await expect(page.getByText('Metode pembayaran')).not.toBeVisible();
    await expect(page.getByRole('button', { name: 'Buat permintaan pembayaran' })).not.toBeVisible();
  });
});

async function uploadProof(page: import('@playwright/test').Page, screenshotPath?: string) {
  const proofFile = { name: 'bukti.png', mimeType: 'image/png', buffer: readFileSync('tests/e2e/feasibility.spec.ts-snapshots/landing-390-chromium-compact-darwin.png') };
  const uploadButton = page.getByRole('button', { name: 'Upload bukti pembayaran' });
  const uploadSurface = page.locator('.payment-file-button');
  await uploadButton.scrollIntoViewIfNeeded();
  const uploadBounds = await uploadButton.boundingBox();
  expect(uploadBounds).not.toBeNull();
  const restingTransform = await uploadSurface.evaluate((element) => getComputedStyle(element).transform);
  const chooserPromise = page.waitForEvent('filechooser');
  await page.mouse.move((uploadBounds?.x ?? 0) + (uploadBounds?.width ?? 0) / 2, (uploadBounds?.y ?? 0) + (uploadBounds?.height ?? 0) / 2);
  await page.mouse.down();
  await expect.poll(() => uploadSurface.evaluate((element) => getComputedStyle(element).transform)).not.toBe(restingTransform);
  await page.mouse.up();
  const chooser = await chooserPromise;
  await chooser.setFiles(proofFile);
  await expect(page.getByText('bukti.png')).toBeVisible();
  await expect(page.getByLabel('Pratinjau bukti pembayaran')).toBeVisible();
  const replacementChooserPromise = page.waitForEvent('filechooser');
  await page.getByRole('button', { name: 'Ganti bukti pembayaran' }).click();
  const replacementChooser = await replacementChooserPromise;
  await replacementChooser.setFiles(proofFile);
  await expect(page.getByText('bukti.png')).toBeVisible();
  await expect(page.getByText('Kirim bukti sekarang?')).not.toBeVisible();
  await expect(page.getByRole('button', { name: 'Periksa lagi' })).not.toBeVisible();
  const submitButton = page.getByRole('button', { name: 'Kirim bukti pembayaran' });
  await submitButton.scrollIntoViewIfNeeded();
  if (screenshotPath) await page.screenshot({ path: screenshotPath });
  await submitButton.click();
  await expect(page.getByText('Sedang diperiksa').first()).toBeVisible({ timeout: 15_000 });
}

async function repeatLocalUpload(page: import('@playwright/test').Page) {
  const proofFile = { name: 'bukti-uji-lokal.png', mimeType: 'image/png', buffer: readFileSync('tests/e2e/feasibility.spec.ts-snapshots/landing-390-chromium-compact-darwin.png') };
  const uploadButton = page.getByRole('button', { name: 'Upload foto uji lokal' });
  await uploadButton.scrollIntoViewIfNeeded();
  const chooserPromise = page.waitForEvent('filechooser');
  await uploadButton.click();
  const chooser = await chooserPromise;
  await chooser.setFiles(proofFile);
  await expect(page.getByText('bukti-uji-lokal.png')).toBeVisible();
  await page.getByRole('button', { name: 'Selesaikan uji upload lokal' }).click();
  await expect(page.getByText('Uji upload selesai')).toBeVisible({ timeout: 15_000 });
  await expect(page.getByText('Bukti yang sedang diperiksa Admin tidak diubah.')).toBeVisible();
  await expect(page.getByRole('button', { name: 'Upload foto uji lokal' })).toBeVisible();
}

async function createIdentity(email: string, password: string) {
  const response = await service.auth.admin.createUser({ email, password, email_confirm: true });
  expect(response.error).toBeNull();
  return { id: response.data.user?.id as string, email, password };
}

async function updateProfile(userId: string, patch: Record<string, unknown>) {
  expect((await service.from('profiles').update({ ...patch, onboarding_status: 'active', provisional_expires_at: null, finalized_at: new Date().toISOString() }).eq('user_id', userId)).error).toBeNull();
}

async function signIn(email: string, password: string): Promise<Session> {
  const client = createClient(localUrl as string, publishableKey as string, { auth: { persistSession: false, autoRefreshToken: false } });
  const response = await client.auth.signInWithPassword({ email, password });
  expect(response.error).toBeNull();
  return response.data.session as Session;
}

function sessionClient(session: Session) {
  return createClient(localUrl as string, publishableKey as string, { auth: { persistSession: false, autoRefreshToken: false }, global: { headers: { Authorization: `Bearer ${session.access_token}` } } });
}

async function installSession(page: import('@playwright/test').Page, session: Session) {
  await page.goto('/login');
  await page.evaluate(({ key, value }) => globalThis.localStorage.setItem(key, value), { key: authKey(), value: JSON.stringify(session) });
}

async function switchSession(page: import('@playwright/test').Page, session: Session) {
  await page.evaluate(({ key, value }) => { globalThis.localStorage.clear(); globalThis.localStorage.setItem(key, value); }, { key: authKey(), value: JSON.stringify(session) });
}

function authKey() {
  return `sb-${new URL(localUrl as string).hostname.split('.')[0]}-auth-token`;
}

function row(value: unknown) {
  return (Array.isArray(value) ? value[0] : value) as Record<string, unknown>;
}

function localDate(offset: number) {
  return new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Makassar', year: 'numeric', month: '2-digit', day: '2-digit' }).format(new Date(Date.now() + offset * 86_400_000));
}
