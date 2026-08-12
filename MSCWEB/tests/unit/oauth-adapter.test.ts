import { describe, expect, it, vi } from 'vitest';

import {
  createPkceSupabaseClient,
  PKCE_AUTH_OPTIONS,
  type PkceSupabaseClient,
  SupabaseBrowserConfigurationError,
} from '../../src/shared/auth/create-pkce-supabase-client';
import { sanitizeInternalReturnRoute } from '../../src/shared/auth/internal-return-route';
import {
  OAuthAdapterError,
  SessionOAuthReturnRouteStore,
  SupabaseGoogleOAuthAdapter,
  type OAuthReturnRouteStore,
} from '../../src/shared/auth/supabase-google-oauth-adapter';

function makeRouteStore(): OAuthReturnRouteStore & { saved: string | null } {
  return {
    saved: null,
    save(route) {
      this.saved = route;
    },
    consume() {
      const value = this.saved;
      this.saved = null;
      return value;
    },
  };
}

function makeClient(overrides: {
  signInWithOAuth?: ReturnType<typeof vi.fn>;
  exchangeCodeForSession?: ReturnType<typeof vi.fn>;
} = {}): PkceSupabaseClient {
  return {
    auth: {
      signInWithOAuth:
        overrides.signInWithOAuth ?? vi.fn(async () => ({ data: { provider: 'google', url: 'https://accounts.example' }, error: null })),
      exchangeCodeForSession:
        overrides.exchangeCodeForSession ??
        vi.fn(async () => ({
          data: {
            session: { access_token: 'not-observed-by-adapter' },
            user: { id: 'user-1', email: 'peserta@example.test' },
          },
          error: null,
        })),
    },
  } as unknown as PkceSupabaseClient;
}

describe('PKCE Supabase client configuration', () => {
  it('locks the browser auth flow to PKCE and manual callback exchange', () => {
    expect(PKCE_AUTH_OPTIONS).toEqual({
      flowType: 'pkce',
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: false,
    });
  });

  it('uses a typed Indonesian configuration error', () => {
    expect(new SupabaseBrowserConfigurationError()).toMatchObject({
      name: 'SupabaseBrowserConfigurationError',
      message: 'Konfigurasi layanan masuk tidak valid.',
    });
  });

  it('rejects invalid browser endpoints and non-public keys before creating a client', () => {
    expect(() =>
      createPkceSupabaseClient({ url: 'not-a-url', publishableKey: 'publishable' }),
    ).toThrowError(SupabaseBrowserConfigurationError);
    expect(() =>
      createPkceSupabaseClient({
        url: 'http://localhost:54321',
        publishableKey: 'not-a-browser-key',
      }),
    ).toThrowError(SupabaseBrowserConfigurationError);
  });
});

describe('safe OAuth return route', () => {
  it.each([
    'https://evil.example/app',
    '//evil.example/app',
    '/app\\evil',
    '/unknown',
    '/app/programs/id/../../admin',
  ])('rejects unsafe route %s', (route) => {
    expect(sanitizeInternalReturnRoute(route)).toBe('/app');
  });

  it('allows a declared internal entity route and removes query/hash state', () => {
    expect(sanitizeInternalReturnRoute('/app/programs/program-1?tab=hari#detail')).toBe(
      '/app/programs/program-1',
    );
  });
});

describe('session OAuth return-route storage', () => {
  it('falls back safely when browser storage is unavailable', () => {
    const originalDescriptor = Object.getOwnPropertyDescriptor(globalThis, 'sessionStorage');
    Object.defineProperty(globalThis, 'sessionStorage', {
      configurable: true,
      value: {
        getItem() {
          throw new DOMException('Storage is blocked');
        },
        removeItem() {
          throw new DOMException('Storage is blocked');
        },
        setItem() {
          throw new DOMException('Storage is blocked');
        },
      },
    });

    try {
      const store = new SessionOAuthReturnRouteStore();
      expect(() => store.save('/app/profile')).not.toThrow();
      expect(store.consume()).toBeNull();
    } finally {
      if (originalDescriptor === undefined) {
        Reflect.deleteProperty(globalThis, 'sessionStorage');
      } else {
        Object.defineProperty(globalThis, 'sessionStorage', originalDescriptor);
      }
    }
  });
});

describe('Supabase Google OAuth adapter', () => {
  it('starts Google OAuth with an exact PKCE callback and safe stored intent', async () => {
    const signInWithOAuth = vi.fn(async () => ({ data: { provider: 'google', url: 'https://accounts.example' }, error: null }));
    const store = makeRouteStore();
    const adapter = new SupabaseGoogleOAuthAdapter(
      makeClient({ signInWithOAuth }),
      'http://localhost:8081/auth/callback',
      store,
    );

    await adapter.signIn('https://evil.example/admin');

    expect(store.saved).toBe('/app');
    expect(signInWithOAuth).toHaveBeenCalledWith({
      provider: 'google',
      options: { redirectTo: 'http://localhost:8081/auth/callback' },
    });
  });

  it('exchanges a callback code and returns only mapped session identity', async () => {
    const exchangeCodeForSession = vi.fn(async () => ({
      data: {
        session: { access_token: 'not-observed-by-adapter' },
        user: { id: 'user-1', email: 'peserta@example.test' },
      },
      error: null,
    }));
    const store = makeRouteStore();
    store.save('/app/programs/program-1');
    const adapter = new SupabaseGoogleOAuthAdapter(
      makeClient({ exchangeCodeForSession }),
      'http://localhost:8081/auth/callback',
      store,
    );

    await expect(
      adapter.exchangeCallback('http://localhost:8081/auth/callback?code=authorization-code'),
    ).resolves.toEqual({
      userId: 'user-1',
      email: 'peserta@example.test',
      returnRoute: '/app/programs/program-1',
    });
    expect(exchangeCodeForSession).toHaveBeenCalledWith('authorization-code');
    expect(store.saved).toBeNull();
  });

  it('maps provider cancellation without exchanging a code', async () => {
    const exchangeCodeForSession = vi.fn();
    const adapter = new SupabaseGoogleOAuthAdapter(
      makeClient({ exchangeCodeForSession }),
      'http://localhost:8081/auth/callback',
      makeRouteStore(),
    );

    await expect(
      adapter.exchangeCallback('http://localhost:8081/auth/callback?error=access_denied'),
    ).rejects.toEqual(new OAuthAdapterError('cancelled'));
    expect(exchangeCodeForSession).not.toHaveBeenCalled();
  });

  it('rejects a callback from a different origin', async () => {
    const adapter = new SupabaseGoogleOAuthAdapter(
      makeClient(),
      'http://localhost:8081/auth/callback',
      makeRouteStore(),
    );

    await expect(
      adapter.exchangeCallback('https://evil.example/auth/callback?code=stolen'),
    ).rejects.toMatchObject({ code: 'invalidCallback' });
  });
});
