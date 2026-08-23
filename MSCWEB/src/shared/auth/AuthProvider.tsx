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
import { consumeOnboardingReturnRoute, saveOnboardingReturnRoute } from './onboarding-return-route';
import { getOnboardingRepository, OnboardingError } from '@/features/onboarding/onboarding-repository';
import { onboardingPathForStep, type OnboardingSessionContext } from '@/features/onboarding/onboarding-models';

export type AccountSummary = Readonly<{
  userId: string;
  email?: string;
  role: AccountRole;
  activeEnrollmentCount: number;
  completedEnrollmentCount: number;
  pendingSubmissionCount: number;
  assignedParticipantCount: number;
}>;

export type AuthState =
  | { status: 'loading' }
  | { status: 'guest'; notice?: 'sessionExpired' }
  | {
      status: 'onboarding';
      context: OnboardingSessionContext;
      providerDefaults: { displayName: string; avatarUrl?: string };
    }
  | { status: 'authenticated'; account: AccountSummary }
  | { status: 'error'; message: string };

type AuthContextValue = Readonly<{
  state: AuthState;
  signInWithGoogle(returnRoute?: string): Promise<void>;
  completeOAuth(callbackUrl: string): Promise<string>;
  signOut(): Promise<void>;
  refreshSessionContext(): Promise<AuthState>;
  finishOnboarding(): Promise<string>;
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
      setState({ status: 'loading' });
    }

    let onboardingContext: OnboardingSessionContext;
    try {
      onboardingContext = await getOnboardingRepository().getSessionContext();
    } catch (contextError) {
      if (contextError instanceof OnboardingError && contextError.code === 'missingProfile') {
        accountIdRef.current = null;
        purgePrivateCaches(queryClient);
        await client.auth.signOut({ scope: 'local' }).catch(() => undefined);
        const nextState: AuthState = { status: 'guest' };
        if (generation === requestGeneration.current) setState(nextState);
        return nextState;
      }
      if (generation === requestGeneration.current) {
        purgePrivateCaches(queryClient);
        setState({ status: 'error', message: 'Status pendaftaran tidak dapat dimuat. Coba masuk kembali.' });
      }
      return null;
    }

    if (onboardingContext.onboarding_status !== 'active') {
      const displayName = safeProviderText(
        session.user.user_metadata?.display_name
          ?? session.user.user_metadata?.full_name
          ?? session.user.user_metadata?.name,
      ) ?? 'Peserta baru';
      const avatarCandidate = safeProviderText(
        session.user.user_metadata?.avatar_url ?? session.user.user_metadata?.picture,
        2_048,
      );
      const providerDefaults = {
        displayName,
        ...(avatarCandidate?.startsWith('https://') ? { avatarUrl: avatarCandidate } : {}),
      };
      accountIdRef.current = session.user.id;
      purgePrivateCaches(queryClient);
      const nextState: AuthState = { status: 'onboarding', context: onboardingContext, providerDefaults };
      if (generation === requestGeneration.current) setState(nextState);
      return nextState;
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
      const nextState: AuthState = { status: 'authenticated', account };
      if (generation === requestGeneration.current) setState(nextState);
      return nextState;
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
    const nextState = await applySession(data.session, 'SIGNED_IN');
    if (nextState?.status === 'onboarding') {
      saveOnboardingReturnRoute(result.returnRoute);
      return onboardingPathForStep[nextState.context.resume_step];
    }
    return nextState?.status === 'authenticated'
      ? destinationForRole(nextState.account.role, result.returnRoute)
      : '/app';
  }, [applySession, client]);

  const refreshSessionContext = useCallback(async (): Promise<AuthState> => {
    const { data } = await client.auth.getSession();
    const next = await applySession(data.session, 'TOKEN_REFRESHED');
    return next ?? { status: 'guest' };
  }, [applySession, client]);

  const finishOnboarding = useCallback(async (): Promise<string> => {
    const nextState = await refreshSessionContext();
    if (nextState.status === 'authenticated') {
      return consumeOnboardingReturnRoute(nextState.account.role);
    }
    if (nextState.status === 'onboarding') return onboardingPathForStep[nextState.context.resume_step];
    return '/app';
  }, [refreshSessionContext]);

  const signOut = useCallback(async () => {
    manualSignOutRef.current = true;
    purgePrivateCaches(queryClient);
    const { error } = await client.auth.signOut({ scope: 'local' });
    accountIdRef.current = null;
    setState({ status: 'guest' });
    router.replace('/login');
    if (error) throw new Error('Sesi lokal sudah ditutup, tetapi server belum dapat dihubungi.');
  }, [client, queryClient]);

  const requireAuthentication = useCallback((returnRoute: string) => {
    if (state.status === 'authenticated') return true;
    if (state.status === 'onboarding') {
      router.replace(onboardingPathForStep[state.context.resume_step] as never);
      return false;
    }
    const safeRoute = sanitizeInternalReturnRoute(returnRoute);
    router.push({ pathname: '/login', params: { returnTo: safeRoute } });
    return false;
  }, [state]);

  return (
    <AuthContext.Provider value={{ state, signInWithGoogle, completeOAuth, signOut, refreshSessionContext, finishOnboarding, requireAuthentication }}>
      {children}
    </AuthContext.Provider>
  );
}

function safeProviderText(value: unknown, maxLength = 80): string | undefined {
  if (typeof value !== 'string') return undefined;
  const normalized = value.replace(/[\u0000-\u001F\u007F]/gu, '').trim().slice(0, maxLength);
  return normalized.length > 0 ? normalized : undefined;
}

export function useAuth(): AuthContextValue {
  const value = useContext(AuthContext);
  if (value === null) throw new Error('AuthProvider belum tersedia.');
  return value;
}
