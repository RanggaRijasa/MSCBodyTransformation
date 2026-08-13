import { z } from 'zod';

const publicEnvironmentSchema = z.object({
  EXPO_PUBLIC_SUPABASE_URL: z.string().url(),
  EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY: z.string().min(1),
  EXPO_PUBLIC_AUTH_REDIRECT_URL: z.string().url(),
});

export type PublicEnvironment = Readonly<{
  supabaseUrl: string;
  supabasePublishableKey: string;
  authRedirectUrl: string;
}>;

export class PublicEnvironmentError extends Error {
  constructor() {
    super('Konfigurasi aplikasi tidak valid. Hubungi pengelola aplikasi.');
    this.name = 'PublicEnvironmentError';
  }
}

export function parsePublicEnvironment(
  source: Record<string, string | undefined>,
): PublicEnvironment {
  const parsed = publicEnvironmentSchema.safeParse(source);
  if (!parsed.success) throw new PublicEnvironmentError();

  const { EXPO_PUBLIC_SUPABASE_URL, EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY, EXPO_PUBLIC_AUTH_REDIRECT_URL } = parsed.data;
  if (
    !isBrowserPublicKey(EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY) ||
    !isSafeHttpUrl(EXPO_PUBLIC_SUPABASE_URL) ||
    !isValidCallback(EXPO_PUBLIC_AUTH_REDIRECT_URL)
  ) {
    throw new PublicEnvironmentError();
  }

  return {
    supabaseUrl: EXPO_PUBLIC_SUPABASE_URL,
    supabasePublishableKey: EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
    authRedirectUrl: EXPO_PUBLIC_AUTH_REDIRECT_URL,
  };
}

function isBrowserPublicKey(key: string): boolean {
  if (key.startsWith('sb_publishable_')) return true;
  if (key.startsWith('sb_secret_')) return false;

  const payload = key.split('.')[1];
  if (payload === undefined) return false;
  try {
    const padded = payload.replace(/-/g, '+').replace(/_/g, '/').padEnd(
      Math.ceil(payload.length / 4) * 4,
      '=',
    );
    const claims = JSON.parse(globalThis.atob(padded)) as { role?: unknown };
    return claims.role === 'anon';
  } catch {
    return false;
  }
}

function isSafeHttpUrl(value: string): boolean {
  const url = new URL(value);
  return ['http:', 'https:'].includes(url.protocol) && url.username === '' && url.password === '';
}

function isValidCallback(value: string): boolean {
  const url = new URL(value);
  return isSafeHttpUrl(value) && url.pathname === '/auth/callback' && url.search === '' && url.hash === '';
}

export function readPublicEnvironment(): PublicEnvironment {
  const environment = parsePublicEnvironment({
    EXPO_PUBLIC_SUPABASE_URL: process.env.EXPO_PUBLIC_SUPABASE_URL,
    EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY: process.env.EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
    EXPO_PUBLIC_AUTH_REDIRECT_URL:
      process.env.EXPO_PUBLIC_AUTH_REDIRECT_URL ??
      (typeof window === 'undefined' ? undefined : `${window.location.origin}/auth/callback`),
  });

  return {
    ...environment,
    authRedirectUrl: resolveBrowserAuthRedirectUrl(
      environment.authRedirectUrl,
      environment.supabaseUrl,
      typeof window === 'undefined' ? undefined : window.location.origin,
    ),
  };
}

export function resolveBrowserAuthRedirectUrl(
  configuredCallback: string,
  supabaseUrl: string,
  browserOrigin?: string,
): string {
  if (!browserOrigin) return configuredCallback;

  try {
    const configured = new URL(configuredCallback);
    const supabase = new URL(supabaseUrl);
    const browser = new URL(browserOrigin);
    const shouldUsePhysicalDeviceOrigin = isLoopbackHost(configured.hostname)
      && isLocalNetworkHost(supabase.hostname)
      && isPrivateLanHost(browser.hostname)
      && ['http:', 'https:'].includes(browser.protocol)
      && browser.username === ''
      && browser.password === '';

    return shouldUsePhysicalDeviceOrigin
      ? new URL('/auth/callback', browser.origin).toString()
      : configuredCallback;
  } catch {
    return configuredCallback;
  }
}

export function isLocalDevelopmentEnvironment(environment = readPublicEnvironment()): boolean {
  try {
    const url = new URL(environment.supabaseUrl);
    return url.protocol === 'http:' && isLocalNetworkHost(url.hostname);
  } catch {
    return false;
  }
}

function isLoopbackHost(hostname: string): boolean {
  return hostname === 'localhost' || hostname === '127.0.0.1' || hostname === '[::1]' || hostname === '::1';
}

function isPrivateLanHost(hostname: string): boolean {
  if (/^10\./u.test(hostname) || /^192\.168\./u.test(hostname)) return true;
  const match = /^172\.(\d{1,2})\./u.exec(hostname);
  return match !== null && Number(match[1]) >= 16 && Number(match[1]) <= 31;
}

function isLocalNetworkHost(hostname: string): boolean {
  return isLoopbackHost(hostname) || isPrivateLanHost(hostname);
}
