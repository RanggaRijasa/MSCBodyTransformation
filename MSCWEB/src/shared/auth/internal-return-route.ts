const EXACT_ALLOWED_ROUTES = new Set([
  '/app',
  '/app/feasibility',
  '/app/home',
  '/app/programs',
  '/app/leaderboard',
  '/app/coach',
  '/app/profile',
  '/admin',
]);

const OPAQUE_IDENTIFIER = '[A-Za-z0-9_-]+';
const ALLOWED_ROUTE_PATTERNS = [
  new RegExp(`^/app/programs/${OPAQUE_IDENTIFIER}$`),
  new RegExp(`^/app/programs/${OPAQUE_IDENTIFIER}/activities/${OPAQUE_IDENTIFIER}$`),
  new RegExp(`^/app/payments/${OPAQUE_IDENTIFIER}$`),
  /^\/admin(?:\/[A-Za-z0-9_-]+)*$/,
];

export const DEFAULT_AUTH_RETURN_ROUTE = '/app';

export function sanitizeInternalReturnRoute(
  candidate: string | null | undefined,
  fallback = DEFAULT_AUTH_RETURN_ROUTE,
): string {
  if (candidate === null || candidate === undefined || !isAllowedInternalRoute(candidate)) {
    return isAllowedInternalRoute(fallback) ? fallback : DEFAULT_AUTH_RETURN_ROUTE;
  }

  return new URL(candidate, 'https://msc.invalid').pathname;
}

function isAllowedInternalRoute(candidate: string): boolean {
  if (
    !candidate.startsWith('/') ||
    candidate.startsWith('//') ||
    candidate.includes('\\') ||
    /[\u0000-\u001F\u007F]/u.test(candidate)
  ) {
    return false;
  }

  let parsed: URL;
  try {
    parsed = new URL(candidate, 'https://msc.invalid');
  } catch {
    return false;
  }

  if (parsed.origin !== 'https://msc.invalid' || parsed.username !== '' || parsed.password !== '') {
    return false;
  }

  const pathname = parsed.pathname;
  return (
    EXACT_ALLOWED_ROUTES.has(pathname) ||
    ALLOWED_ROUTE_PATTERNS.some((pattern) => pattern.test(pathname))
  );
}
