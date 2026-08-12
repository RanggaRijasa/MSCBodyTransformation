import { useQueryClient } from '@tanstack/react-query';
import type { AuthChangeEvent, Session } from '@supabase/supabase-js';
import { router } from 'expo-router';
import { createContext, type PropsWithChildren, useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react';

import { destinationForRole, parseAccountRole, type AccountRole } from './account-role';
import { purgePrivateCaches } from './private-cache';
import { sanitizeInternalReturnRoute } from './internal-return-route';
import { SupabaseGoogleOAuthAdapter } from './supabase-google-oauth-adapter';
import { readPublicEnvironment } from '@/shared/config/public-environment';
import { getSupabaseBrowserClient } from '@/shared/supabase/client';

export type AccountSummary = Readonly<{
  userId: string;
  email?: string;
  role: AccountRole;
  activeEnrollmentCount: number;
  completedEnrollmentCount: number;
  pendingSubmissionCount: number;
  assignedParticipantCount: number;
}>;

type AuthState =
  | { status: 'loading' }
  | { status: 'guest'; notice?: 'sessionExpired' }
  | { status: 'authenticated'; account: AccountSummary }
  | { status: 'error'; message: string };

type AuthContextValue = Readonly<{
  state: AuthState;
  signInWithGoogle(returnRoute?: string): Promise<void>;
  completeOAuth(callbackUrl: string): Promise<string>;
  signOut(): Promise<void>;
  requireAuthentication(returnRoute: string): boolean;
}>;

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: PropsWithChildren) {
  const queryClient = useQueryClient();
  const client = useMemo(() => getSupabaseBrowserClient(), []);
  const [state, setState] = useState<AuthState>({ status: 'loading' });
  const accountIdRef = useRef<string | null>(null);
  const manualSignOutRef = useRef(false);
  const requestGeneration = useRef(0);

  const applySession = useCallback(async (session: Session | null, event?: AuthChangeEvent) => {
    const generation = ++requestGeneration.current;
    if (session === null) {
      const hadAccount = accountIdRef.current !== null;
      accountIdRef.current = null;
      purgePrivateCaches(queryClient);
      setState({
        status: 'guest',
        ...(hadAccount && !manualSignOutRef.current && event === 'SIGNED_OUT'
          ? { notice: 'sessionExpired' as const }
          : {}),
      });
      manualSignOutRef.current = false;
      return null;
    }

    if (accountIdRef.current !== null && accountIdRef.current !== session.user.id) {
      purgePrivateCaches(queryClient);
    }

    const { data, error } = await client.rpc('get_my_dashboard_summary');
    const row = data?.[0];
    if (error || row === undefined) {
      if (generation === requestGeneration.current) {
        purgePrivateCaches(queryClient);
        setState({ status: 'error', message: 'Profil akun tidak dapat dimuat. Coba masuk kembali.' });
      }
      return null;
    }

    try {
      const account: AccountSummary = {
        userId: session.user.id,
        ...(session.user.email ? { email: session.user.email } : {}),
        role: parseAccountRole(row.account_role),
        activeEnrollmentCount: row.active_enrollment_count,
        completedEnrollmentCount: row.completed_enrollment_count,
        pendingSubmissionCount: row.pending_submission_count,
        assignedParticipantCount: row.assigned_participant_count,
      };
      accountIdRef.current = account.userId;
      if (generation === requestGeneration.current) setState({ status: 'authenticated', account });
      return account;
    } catch (error) {
      if (generation === requestGeneration.current) {
        purgePrivateCaches(queryClient);
        setState({ status: 'error', message: error instanceof Error ? error.message : 'Peran akun tidak dapat diverifikasi.' });
      }
      return null;
    }
  }, [client, queryClient]);

  useEffect(() => {
    let active = true;
    void client.auth.getSession().then(({ data }) => {
      if (active) void applySession(data.session, 'INITIAL_SESSION');
    });
    const { data: subscription } = client.auth.onAuthStateChange((event, session) => {
      globalThis.setTimeout(() => {
        if (active) void applySession(session, event);
      }, 0);
    });
    return () => {
      active = false;
      subscription.subscription.unsubscribe();
    };
  }, [applySession, client]);

  const signInWithGoogle = useCallback(async (returnRoute = '/app') => {
    const environment = readPublicEnvironment();
    await new SupabaseGoogleOAuthAdapter(client, environment.authRedirectUrl).signIn(returnRoute);
  }, [client]);

  const completeOAuth = useCallback(async (callbackUrl: string) => {
    const environment = readPublicEnvironment();
    const result = await new SupabaseGoogleOAuthAdapter(client, environment.authRedirectUrl).exchangeCallback(callbackUrl);
    const { data } = await client.auth.getSession();
    const account = await applySession(data.session, 'SIGNED_IN');
    return account === null ? '/app' : destinationForRole(account.role, result.returnRoute);
  }, [applySession, client]);

  const signOut = useCallback(async () => {
    manualSignOutRef.current = true;
    purgePrivateCaches(queryClient);
    const { error } = await client.auth.signOut();
    if (error) {
      manualSignOutRef.current = false;
      throw new Error('Tidak dapat keluar. Periksa koneksi lalu coba lagi.');
    }
    accountIdRef.current = null;
    setState({ status: 'guest' });
    router.replace('/app/home');
  }, [client, queryClient]);

  const requireAuthentication = useCallback((returnRoute: string) => {
    if (state.status === 'authenticated') return true;
    const safeRoute = sanitizeInternalReturnRoute(returnRoute);
    router.push({ pathname: '/login', params: { returnTo: safeRoute } });
    return false;
  }, [state.status]);

  return (
    <AuthContext.Provider value={{ state, signInWithGoogle, completeOAuth, signOut, requireAuthentication }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextValue {
  const value = useContext(AuthContext);
  if (value === null) throw new Error('AuthProvider belum tersedia.');
  return value;
}
