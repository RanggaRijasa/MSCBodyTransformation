import type { AccountRole } from './account-role';
import { sanitizeInternalReturnRoute } from './internal-return-route';

const STORAGE_KEY = 'msc.onboarding.return-route.v1';
const MAX_AGE_MS = 24 * 60 * 60 * 1_000;

export function saveOnboardingReturnRoute(route: string) {
  try {
    globalThis.sessionStorage?.setItem(STORAGE_KEY, JSON.stringify({
      route: sanitizeInternalReturnRoute(route),
      savedAt: Date.now(),
    }));
  } catch {
    // A blocked browser store safely falls back to the role root.
  }
}

export function consumeOnboardingReturnRoute(role: AccountRole): string {
  let candidate: unknown;
  try {
    const stored = globalThis.sessionStorage?.getItem(STORAGE_KEY);
    globalThis.sessionStorage?.removeItem(STORAGE_KEY);
    candidate = stored ? JSON.parse(stored) : undefined;
  } catch {
    candidate = undefined;
  }
  if (role === 'admin') return '/admin';
  if (role === 'coach') return '/coach';
  if (!isStoredRoute(candidate) || Date.now() - candidate.savedAt > MAX_AGE_MS) return '/app';
  const route = sanitizeInternalReturnRoute(candidate.route);
  return route.startsWith('/app') ? route : '/app';
}

function isStoredRoute(value: unknown): value is { route: string; savedAt: number } {
  return typeof value === 'object' && value !== null
    && typeof (value as { route?: unknown }).route === 'string'
    && typeof (value as { savedAt?: unknown }).savedAt === 'number';
}

