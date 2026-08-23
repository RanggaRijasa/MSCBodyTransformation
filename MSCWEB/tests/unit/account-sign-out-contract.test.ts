import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

const authProvider = readFileSync('src/shared/auth/AuthProvider.tsx', 'utf8');
const participantProfile = readFileSync('src/app/app/profile.tsx', 'utf8');
const coachProfile = readFileSync('src/features/coach/CoachProfileComponents.tsx', 'utf8');
const adminSettings = readFileSync('src/features/admin/AdminSettingsComponents.tsx', 'utf8');
const oauthAdapter = readFileSync('src/shared/auth/supabase-google-oauth-adapter.ts', 'utf8');

describe('account sign-out contract', () => {
  it('removes the current browser session and returns to login', () => {
    expect(authProvider).toContain("client.auth.signOut({ scope: 'local' })");
    expect(authProvider).toContain("router.replace('/login')");
  });

  it('uses the same sign-out control for Participant, Coach, and Admin', () => {
    expect(participantProfile).toContain('<AccountSignOutButton />');
    expect(coachProfile).toContain('<AccountSignOutButton />');
    expect(adminSettings).toContain('<AccountSignOutButton />');
  });

  it('always asks Google to choose an account for a new login', () => {
    expect(oauthAdapter).toContain("queryParams: { prompt: 'select_account' }");
  });
});
