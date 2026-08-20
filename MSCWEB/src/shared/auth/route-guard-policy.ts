import { destinationForRole } from './account-role';
import type { AuthState } from './AuthProvider';
import { onboardingPathForStep } from '@/features/onboarding/onboarding-models';

export function guardedDestination(pathname: string, state: AuthState): string | null {
  const isOnboarding = pathname.startsWith('/onboarding');
  const isPrivileged = pathname.startsWith('/coach') || pathname.startsWith('/admin');
  if (state.status === 'loading' || state.status === 'error') return null;
  if (state.status === 'guest') {
    if (isOnboarding || isPrivileged) return `/login?returnTo=${encodeURIComponent(pathname)}`;
    return null;
  }
  if (state.status === 'onboarding') {
    const expected = onboardingPathForStep[state.context.resume_step];
    const allowed = onboardingAllowedPaths(state.context.resume_step, state.context.onboarding_status);
    return allowed.has(pathname) || pathname === '/auth/callback' ? null : expected;
  }
  if (isOnboarding) {
    if (state.account.role === 'participant' && pathname === '/onboarding/coach/status') return null;
    return destinationForRole(state.account.role, '/app');
  }
  if (pathname.startsWith('/admin') && state.account.role !== 'admin') return destinationForRole(state.account.role, '/app');
  if (pathname.startsWith('/coach') && state.account.role !== 'coach') return destinationForRole(state.account.role, '/app');
  return null;
}

function onboardingAllowedPaths(step: keyof typeof onboardingPathForStep, status: string): Set<string> {
  const paths = new Set([onboardingPathForStep[step]]);
  if (status === 'provisional' && step !== 'cleanup') paths.add('/onboarding/profile');
  if (step === 'coach_payment') paths.add('/onboarding/coach/eligibility');
  if (step === 'coach_status') {
    paths.add('/onboarding/coach/payment');
    paths.add('/onboarding/coach/status');
  }
  return paths;
}

