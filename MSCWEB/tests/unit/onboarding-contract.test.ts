import { afterEach, describe, expect, it, vi } from 'vitest';

import { onboardingSessionContextSchema, onboardingPathForStep } from '../../src/features/onboarding/onboarding-models';
import { mapOnboardingError } from '../../src/features/onboarding/onboarding-repository';
import { guardedDestination } from '../../src/shared/auth/route-guard-policy';
import { consumeOnboardingReturnRoute, saveOnboardingReturnRoute } from '../../src/shared/auth/onboarding-return-route';

const context = onboardingSessionContextSchema.parse({
  user_id: '00000000-0000-4000-8000-000000000001',
  role: 'participant',
  onboarding_status: 'provisional',
  account_purpose: 'participant',
  profile_complete: false,
  provisional_expires_at: '2026-08-21T00:00:00.000Z',
  onboarding_version: 1,
  resume_step: 'profile',
  phone_number: '+628123456789',
});

afterEach(() => {
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

describe('W07.4 onboarding contract', () => {
  it('parses only the fixed safe session projection', () => {
    expect(context).not.toHaveProperty('phone_number');
    expect(onboardingPathForStep.participant_coach).toBe('/onboarding/participant/coach');
  });

  it('maps typed server failures to actionable Indonesian errors', () => {
    expect(mapOnboardingError({ message: 'coach_qr_invalid' }).code).toBe('invalidCoach');
    expect(mapOnboardingError({ message: 'provisional_identity_expired' }).code).toBe('expired');
    expect(mapOnboardingError({ message: 'version_conflict' }).code).toBe('conflict');
  });

  it('prevents provisional deep links to private role roots', () => {
    const state = { status: 'onboarding' as const, context, providerDefaults: { displayName: 'Peserta Baru' } };
    expect(guardedDestination('/admin', state)).toBe('/onboarding/profile');
    expect(guardedDestination('/coach', state)).toBe('/onboarding/profile');
    expect(guardedDestination('/app', state)).toBe('/onboarding/profile');
    expect(guardedDestination('/onboarding/profile', state)).toBeNull();
  });

  it('keeps active role roots unchanged and blocks mismatched privileged roots', () => {
    const participant = { status: 'authenticated' as const, account: { userId: context.user_id, role: 'participant' as const, activeEnrollmentCount: 0, completedEnrollmentCount: 0, pendingSubmissionCount: 0, assignedParticipantCount: 0 } };
    expect(guardedDestination('/admin', participant)).toBe('/app');
    expect(guardedDestination('/coach', participant)).toBe('/app');
    expect(guardedDestination('/app/profile', participant)).toBeNull();
    expect(guardedDestination('/onboarding/coach/status', participant)).toBeNull();
  });

  it('stores one expiring internal intent and role-authorizes it on consumption', () => {
    const values = new Map<string, string>();
    vi.stubGlobal('sessionStorage', {
      setItem: (key: string, value: string) => values.set(key, value),
      getItem: (key: string) => values.get(key) ?? null,
      removeItem: (key: string) => values.delete(key),
    });
    saveOnboardingReturnRoute('/app/programs/program-1');
    expect(consumeOnboardingReturnRoute('participant')).toBe('/app/programs/program-1');
    expect(consumeOnboardingReturnRoute('participant')).toBe('/app');
    saveOnboardingReturnRoute('/admin');
    expect(consumeOnboardingReturnRoute('participant')).toBe('/app');
  });
});
