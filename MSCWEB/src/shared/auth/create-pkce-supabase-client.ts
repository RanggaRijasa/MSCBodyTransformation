import { createClient, type SupabaseClient, type SupabaseClientOptions } from '@supabase/supabase-js';

declare const pkceClientBrand: unique symbol;

export type PkceSupabaseClient = SupabaseClient & {
  readonly [pkceClientBrand]: true;
};

export type SupabaseBrowserConfiguration = Readonly<{
  url: string;
  publishableKey: string;
}>;

export class SupabaseBrowserConfigurationError extends Error {
  constructor() {
    super('Konfigurasi layanan masuk tidak valid.');
    this.name = 'SupabaseBrowserConfigurationError';
  }
}

export const PKCE_AUTH_OPTIONS = {
  flowType: 'pkce',
  persistSession: true,
  autoRefreshToken: true,
  detectSessionInUrl: false,
} as const satisfies NonNullable<SupabaseClientOptions<'public'>['auth']>;

export function createPkceSupabaseClient(
  configuration: SupabaseBrowserConfiguration,
): PkceSupabaseClient {
  validateBrowserConfiguration(configuration);

  return createClient(configuration.url, configuration.publishableKey, {
    auth: PKCE_AUTH_OPTIONS,
  }) as PkceSupabaseClient;
}

function validateBrowserConfiguration(configuration: SupabaseBrowserConfiguration): void {
  let url: URL;
  try {
    url = new URL(configuration.url);
  } catch {
    throw new SupabaseBrowserConfigurationError();
  }

  if (
    !['http:', 'https:'].includes(url.protocol) ||
    url.username !== '' ||
    url.password !== '' ||
    configuration.publishableKey.trim() === '' ||
    !isPublicBrowserKey(configuration.publishableKey)
  ) {
    throw new SupabaseBrowserConfigurationError();
  }
}

function isPublicBrowserKey(key: string): boolean {
  if (key.startsWith('sb_publishable_')) {
    return true;
  }

  const payload = key.split('.')[1];
  if (payload === undefined) {
    return false;
  }

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
