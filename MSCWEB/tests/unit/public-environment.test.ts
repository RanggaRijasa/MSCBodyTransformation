import { describe, expect, it } from 'vitest';

import { parsePublicEnvironment, PublicEnvironmentError } from '../../src/shared/config/public-environment';

const baseline = {
  EXPO_PUBLIC_SUPABASE_URL: 'http://127.0.0.1:54321',
  EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY: 'sb_publishable_browser-safe',
  EXPO_PUBLIC_AUTH_REDIRECT_URL: 'http://127.0.0.1:4173/auth/callback',
};

describe('public browser environment', () => {
  it('accepts local and HTTPS production public configuration', () => {
    expect(parsePublicEnvironment(baseline)).toMatchObject({ supabaseUrl: baseline.EXPO_PUBLIC_SUPABASE_URL });
    expect(parsePublicEnvironment({
      ...baseline,
      EXPO_PUBLIC_SUPABASE_URL: 'https://project.supabase.co',
      EXPO_PUBLIC_AUTH_REDIRECT_URL: 'https://app.example/auth/callback',
    })).toMatchObject({ authRedirectUrl: 'https://app.example/auth/callback' });
  });

  it.each([
    'sb_secret_server-only',
    'service-role-key',
    '',
  ])('rejects server or malformed browser key %s', (key) => {
    expect(() => parsePublicEnvironment({ ...baseline, EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY: key })).toThrow(PublicEnvironmentError);
  });

  it('rejects callback query state and embedded credentials', () => {
    expect(() => parsePublicEnvironment({ ...baseline, EXPO_PUBLIC_AUTH_REDIRECT_URL: 'https://app.example/auth/callback?next=evil' })).toThrow(PublicEnvironmentError);
    expect(() => parsePublicEnvironment({ ...baseline, EXPO_PUBLIC_SUPABASE_URL: 'https://user:password@app.example' })).toThrow(PublicEnvironmentError);
  });
});
