import { router } from 'expo-router';
import { useEffect, useState } from 'react';
import { ActivityIndicator, StyleSheet, Text, View } from 'react-native';

import {
  createPkceSupabaseClient,
  SupabaseBrowserConfigurationError,
} from '@/shared/auth/create-pkce-supabase-client';
import {
  OAuthAdapterError,
  SupabaseGoogleOAuthAdapter,
} from '@/shared/auth/supabase-google-oauth-adapter';
import { primitiveTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';

export default function AuthCallbackRoute() {
  const { colors } = useAppTheme();
  const [message, setMessage] = useState('Menyelesaikan proses masuk…');

  useEffect(() => {
    let isActive = true;

    async function exchangeSession() {
      try {
        const client = createPkceSupabaseClient({
          url: process.env.EXPO_PUBLIC_SUPABASE_URL ?? '',
          publishableKey: process.env.EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY ?? '',
        });
        const callbackUrl = process.env.EXPO_PUBLIC_AUTH_REDIRECT_URL ?? window.location.origin + '/auth/callback';
        const result = await new SupabaseGoogleOAuthAdapter(client, callbackUrl).exchangeCallback(window.location.href);
        if (isActive) {
          router.replace(result.returnRoute as never);
        }
      } catch (error) {
        if (isActive) {
          const isExpectedError =
            error instanceof OAuthAdapterError ||
            error instanceof SupabaseBrowserConfigurationError;
          setMessage(
            isExpectedError
              ? error.message
              : 'Sesi tidak dapat dibuat. Mulai proses masuk lagi.',
          );
        }
      }
    }

    void exchangeSession();
    return () => {
      isActive = false;
    };
  }, []);

  return (
    <View style={[styles.page, { backgroundColor: colors.background }]}>
      <ActivityIndicator />
      <Text accessibilityLiveRegion="polite" style={[styles.message, { color: colors.primaryText }]}>{message}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  page: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: primitiveTokens.space.large,
    gap: primitiveTokens.space.medium,
  },
  message: {
    fontSize: 16,
    lineHeight: 24,
    textAlign: 'center',
  },
});
