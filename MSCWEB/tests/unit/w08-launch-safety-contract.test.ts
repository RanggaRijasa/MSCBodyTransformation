import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

const migration = readFileSync('../supabase/migrations/20260820231319_w08_minimum_media_launch_safety.sql', 'utf8');
const gateway = readFileSync('../supabase/functions/public-coach-media/index.ts', 'utf8');
const cleanup = readFileSync('../supabase/functions/cleanup-orphan-payment-evidence/index.ts', 'utf8');
const jobAuth = readFileSync('../supabase/functions/_shared/job_auth.ts', 'utf8');
const config = readFileSync('../supabase/config.toml', 'utf8');
const schedules = readFileSync('../supabase/migrations/20260821002617_w08_web_job_schedules.sql', 'utf8');
const productionBuild = readFileSync('scripts/build-production.mjs', 'utf8');
const productionEnvironmentVerification = readFileSync('scripts/verify-production-environment.mjs', 'utf8');
const productionSmoke = readFileSync('scripts/run-production-synthetic-smoke.mjs', 'utf8');
const coachWorkspaceRepair = readFileSync('../supabase/migrations/20260821022337_w08_coach_workspace_profile_avatar_fix.sql', 'utf8');
const publicCoachSync = readFileSync('../supabase/migrations/20260823050937_sync_public_coach_profile_reads.sql', 'utf8');
const allRoleCoachSync = readFileSync('../supabase/migrations/20260823084711_sync_coach_profile_all_role_reads.sql', 'utf8');
const coachProfile = readFileSync('src/features/coach/CoachProfileComponents.tsx', 'utf8');
const coachWorkspace = readFileSync('src/features/coach/CoachWorkspaceComponents.tsx', 'utf8');
const adminPeople = readFileSync('src/features/admin/AdminPeopleComponents.tsx', 'utf8');
const performanceBudget = readFileSync('scripts/verify-performance-budget.mjs', 'utf8');

describe('W08 minimum launch safety contract', () => {
  it('makes Coach media private and exposes only opaque public asset identifiers', () => {
    expect(migration).toContain("set public = false");
    expect(migration).toContain('private.coach_public_media_assets');
    expect(migration).toContain("'photo_reference', avatar_asset.id");
    expect(migration).toContain('resolve_public_coach_media_asset');
    expect(migration).toContain('profile.coach_is_public');
    expect(migration).toContain('private.has_active_coach_access');
    expect(migration).toContain('drop policy if exists "Public reads published Coach media"');
  });

  it('membaca direktori dan Coach pendamping dari snapshot publik yang sama', () => {
    expect(publicCoachSync).toContain('from public.coach_public_profiles published');
    expect(publicCoachSync).toContain("'professional_headline', published.professional_headline");
    expect(publicCoachSync).toContain("'biography', published.biography");
    expect(publicCoachSync).toContain("'photo_reference', avatar_asset.id");
    expect(publicCoachSync).toContain('get_my_assigned_coach_profile');
    expect(publicCoachSync).toContain('to authenticated');
    expect(publicCoachSync).not.toContain("'instagram_url'");
    expect(publicCoachSync).not.toContain("'phone_number'");
  });

  it('menyatukan profil terbit ke dashboard Coach dan Admin tanpa membuka jalur media', () => {
    expect(allRoleCoachSync).toContain('private.get_my_coach_workspace_before_public_profile_sync()');
    expect(allRoleCoachSync).toContain("'photo_reference', avatar_asset.id");
    expect(allRoleCoachSync).toContain("'city', case");
    expect(allRoleCoachSync).toContain("published.service_area");
    expect(allRoleCoachSync).toContain("published.biography");
    expect(allRoleCoachSync).not.toContain("'photo_reference', published.photo_reference");
    expect(coachWorkspace).toContain('publicCoachMediaUrl(workspace.profile.photo_reference)');
    expect(adminPeople).toContain('publicCoachMediaUrl(person.photo_reference)');
  });

  it('memakai hero identitas yang stabil dan tautan share kanonis di kedua tema', () => {
    expect(coachProfile).toContain('backgroundColor: colors.identitySurface');
    expect(coachProfile).toContain('color: colors.onIdentitySurface');
    expect(coachProfile).toContain('`${window.location.origin}/c/${profile.handle}`');
    expect(coachProfile).not.toContain('backgroundColor: colors.primaryText');
  });

  it('serves public Coach media through a no-store gateway without logging paths', () => {
    expect(gateway).toContain("rpc('resolve_public_coach_media_asset'");
    expect(gateway).toContain("storage.from('coach-public-media').download");
    expect(gateway).toContain('no-store, max-age=0');
    expect(gateway).not.toContain('getPublicUrl');
    expect(gateway).not.toContain('console.log');
    expect(config).toContain('[functions.public-coach-media]');
  });

  it('retains evidence under review and claims final evidence before deletion', () => {
    expect(migration).toContain("interval '30 days'");
    expect(migration).toContain("'under_review', 'correction_required', 'reversal_pending'");
    expect(migration).toContain('claim_payment_evidence_retention');
    expect(migration).toContain("status = 'deleting'");
    expect(migration).toContain('complete_payment_evidence_retention');
    expect(migration).toContain("status = 'deleted'");
    expect(cleanup).toContain("dryRun = body.dryRun !== false");
    expect(cleanup).toContain("rpc('claim_payment_evidence_retention'");
    expect(cleanup).not.toContain('console.log');
  });

  it('uses digest comparison for each server-only job secret', () => {
    expect(jobAuth).toContain('crypto.subtle.digest');
    expect(jobAuth).toContain('difference |=');
    expect(cleanup).toContain("isAuthorizedJobRequest(request, 'PAYMENT_CLEANUP_JOB_SECRET')");
  });

  it('schedules reviewed jobs without embedding secrets in cron commands', () => {
    expect(schedules).toContain("'0 18 * * *'");
    expect(schedules).toContain("'1-59/5 * * * *'");
    expect(schedules).toContain("'3-59/5 * * * *'");
    expect(schedules).toContain("'{\"dryRun\":true");
    expect(schedules).toContain('vault.decrypted_secrets');
    expect(schedules).not.toContain('FOOD_AI_API_KEY');
  });

  it('builds production with an isolated ignored environment file', () => {
    expect(productionBuild).toContain("const environmentPath = '.env.production.local'");
    expect(productionBuild).toContain("EXPO_NO_DOTENV: '1'");
    expect(productionBuild).toContain("key.startsWith('EXPO_PUBLIC_')");
    expect(productionBuild).not.toContain('FOOD_AI_API_KEY');
    expect(productionEnvironmentVerification).toContain("readFileSync('.env.local'");
    expect(productionEnvironmentVerification).toContain('Secret server terdeteksi pada bundle');
  });

  it('keeps production smoke synthetic, non-billable, and cleanup-first', () => {
    expect(productionSmoke).toContain('@example.invalid');
    expect(productionSmoke).toContain('NON-BILLABLE');
    expect(productionSmoke).toContain("state.checks.realTransfer = 'NOT_PERFORMED'");
    expect(productionSmoke).toContain('finally {');
    expect(productionSmoke).toContain('await cleanup()');
    expect(productionSmoke).toContain('await verifyResiduals()');
    expect(productionSmoke).toContain("googleOAuth: 'DEFERRED'");
    expect(productionSmoke).not.toContain('state.created.password');
    expect(productionSmoke).not.toContain('state.created.secretKey');
  });

  it('keeps Coach workspace projections free of a nonexistent private avatar path column', () => {
    expect(coachWorkspaceRepair).toContain('public.get_my_coach_workspace()');
    expect(coachWorkspaceRepair).toContain('public.get_my_coach_public_profile_draft()');
    expect(coachWorkspaceRepair).toContain("'profile_avatar_path', null");
    expect(coachWorkspaceRepair).not.toContain('profile.profile_avatar_path');
  });

  it('menetapkan budget produksi yang dapat menggagalkan build saat membesar', () => {
    expect(performanceBudget).toContain('appBootstrapBytes: 2_750_000');
    expect(performanceBudget).toContain('totalJavaScriptBytes: 3_200_000');
    expect(performanceBudget).toContain('landingCriticalBytes: 64_000');
    expect(performanceBudget).toContain('heroImageBytes: 350_000');
    expect(performanceBudget).toContain('throw new Error');
  });
});
