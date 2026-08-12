import { router } from 'expo-router';
import { useEffect, useState } from 'react';
import { ActivityIndicator, StyleSheet, Text, View } from 'react-native';

import { useAuth } from '@/shared/auth/AuthProvider';
import { OAuthAdapterError } from '@/shared/auth/supabase-google-oauth-adapter';
import { PublicEnvironmentError } from '@/shared/config/public-environment';
import { primitiveTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { Button } from '@/shared/ui/primitives';

export default function AuthCallbackRoute() {
  const { colors } = useAppTheme();
  const { completeOAuth } = useAuth();
  const [message, setMessage] = useState('Menyelesaikan proses masuk…');
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    let isActive = true;
    void completeOAuth(window.location.href).then((destination) => {
      if (isActive) router.replace(destination as never);
    }).catch((error: unknown) => {
      if (!isActive) return;
      setFailed(true);
      setMessage(
        error instanceof OAuthAdapterError || error instanceof PublicEnvironmentError
          ? error.message
          : 'Sesi tidak dapat dibuat. Mulai proses masuk lagi.',
      );
    });
    return () => { isActive = false; };
  }, [completeOAuth]);

  return (
    <View style={[styles.page, { backgroundColor: colors.background }]}>
      {!failed ? <ActivityIndicator /> : null}
      <Text accessibilityLiveRegion="polite" style={[styles.message, { color: colors.primaryText }]}>{message}</Text>
      {failed ? <Button label="Kembali ke halaman masuk" onPress={() => router.replace('/login')} /> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  page: { flex: 1, alignItems: 'center', justifyContent: 'center', padding: primitiveTokens.space.large, gap: primitiveTokens.space.medium },
  message: { fontSize: 16, lineHeight: 24, textAlign: 'center' },
});
