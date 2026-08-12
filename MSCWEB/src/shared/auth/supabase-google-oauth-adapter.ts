import {
  DEFAULT_AUTH_RETURN_ROUTE,
  sanitizeInternalReturnRoute,
} from './internal-return-route';
import type { PkceSupabaseClient } from './create-pkce-supabase-client';

const RETURN_ROUTE_STORAGE_KEY = 'msc.oauth.return-route';

export type OAuthAdapterErrorCode =
  | 'cancelled'
  | 'invalidCallback'
  | 'providerUnavailable'
  | 'sessionExchangeFailed';

const OAUTH_ERROR_MESSAGES: Record<OAuthAdapterErrorCode, string> = {
  cancelled: 'Proses masuk dibatalkan.',
  invalidCallback: 'Tautan masuk tidak valid. Mulai proses masuk lagi.',
  providerUnavailable: 'Google tidak dapat dihubungi. Periksa koneksi lalu coba lagi.',
  sessionExchangeFailed: 'Sesi tidak dapat dibuat. Mulai proses masuk lagi.',
};

export class OAuthAdapterError extends Error {
  readonly code: OAuthAdapterErrorCode;

  constructor(code: OAuthAdapterErrorCode) {
    super(OAUTH_ERROR_MESSAGES[code]);
    this.name = 'OAuthAdapterError';
    this.code = code;
  }
}

export interface OAuthReturnRouteStore {
  save(route: string): void;
  consume(): string | null;
}

export class SessionOAuthReturnRouteStore implements OAuthReturnRouteStore {
  save(route: string): void {
    try {
      globalThis.sessionStorage?.setItem(RETURN_ROUTE_STORAGE_KEY, route);
    } catch {
      // OAuth can continue safely; the callback falls back to the app home route.
    }
  }

  consume(): string | null {
    try {
      const route = globalThis.sessionStorage?.getItem(RETURN_ROUTE_STORAGE_KEY) ?? null;
      globalThis.sessionStorage?.removeItem(RETURN_ROUTE_STORAGE_KEY);
      return route;
    } catch {
      return null;
    }
  }
}

export type CompletedOAuthSession = Readonly<{
  userId: string;
  email?: string;
  returnRoute: string;
}>;

export class SupabaseGoogleOAuthAdapter {
  private readonly callbackUrl: string;

  constructor(
    private readonly client: PkceSupabaseClient,
    callbackUrl: string,
    private readonly returnRouteStore: OAuthReturnRouteStore = new SessionOAuthReturnRouteStore(),
  ) {
    this.callbackUrl = validateCallbackUrl(callbackUrl);
  }

  async signIn(returnRoute: string = DEFAULT_AUTH_RETURN_ROUTE): Promise<void> {
    const safeReturnRoute = sanitizeInternalReturnRoute(returnRoute);
    this.returnRouteStore.save(safeReturnRoute);

    let error: unknown;
    try {
      ({ error } = await this.client.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: this.callbackUrl,
        },
      }));
    } catch {
      this.returnRouteStore.consume();
      throw new OAuthAdapterError('providerUnavailable');
    }

    if (error !== null) {
      this.returnRouteStore.consume();
      throw new OAuthAdapterError('providerUnavailable');
    }
  }

  async exchangeCallback(callbackUrl: string): Promise<CompletedOAuthSession> {
    const url = parseCallbackUrl(callbackUrl, this.callbackUrl);
    const providerError = url.searchParams.get('error');

    if (providerError !== null) {
      this.returnRouteStore.consume();
      if (providerError === 'access_denied') {
        throw new OAuthAdapterError('cancelled');
      }
      throw new OAuthAdapterError('sessionExchangeFailed');
    }

    const code = url.searchParams.get('code');
    if (code === null || code.trim() === '') {
      this.returnRouteStore.consume();
      throw new OAuthAdapterError('invalidCallback');
    }

    let response: Awaited<ReturnType<PkceSupabaseClient['auth']['exchangeCodeForSession']>>;
    try {
      response = await this.client.auth.exchangeCodeForSession(code);
    } catch {
      this.returnRouteStore.consume();
      throw new OAuthAdapterError('sessionExchangeFailed');
    }
    const safeReturnRoute = sanitizeInternalReturnRoute(this.returnRouteStore.consume());

    if (
      response.error !== null ||
      response.data.session === null ||
      response.data.user === null
    ) {
      throw new OAuthAdapterError('sessionExchangeFailed');
    }

    return {
      userId: response.data.user.id,
      ...(response.data.user.email === undefined ? {} : { email: response.data.user.email }),
      returnRoute: safeReturnRoute,
    };
  }
}

function validateCallbackUrl(callbackUrl: string): string {
  let url: URL;
  try {
    url = new URL(callbackUrl);
  } catch {
    throw new OAuthAdapterError('invalidCallback');
  }

  if (
    !['http:', 'https:'].includes(url.protocol) ||
    url.username !== '' ||
    url.password !== '' ||
    url.pathname !== '/auth/callback' ||
    url.search !== '' ||
    url.hash !== ''
  ) {
    throw new OAuthAdapterError('invalidCallback');
  }

  return url.toString();
}

function parseCallbackUrl(callbackUrl: string, expectedCallbackUrl: string): URL {
  let actual: URL;
  const expected = new URL(expectedCallbackUrl);
  try {
    actual = new URL(callbackUrl);
  } catch {
    throw new OAuthAdapterError('invalidCallback');
  }

  if (
    actual.origin !== expected.origin ||
    actual.pathname !== expected.pathname ||
    actual.username !== '' ||
    actual.password !== ''
  ) {
    throw new OAuthAdapterError('invalidCallback');
  }

  return actual;
}
