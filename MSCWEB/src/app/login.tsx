import { router, useLocalSearchParams } from 'expo-router';
import { useState } from 'react';
import { ScrollView, StyleSheet, Text, View } from 'react-native';

import { useAuth } from '@/shared/auth/AuthProvider';
import { sanitizeInternalReturnRoute } from '@/shared/auth/internal-return-route';
import { OAuthAdapterError } from '@/shared/auth/supabase-google-oauth-adapter';
import { PublicEnvironmentError } from '@/shared/config/public-environment';
import { componentTokens, primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { MSCIcon } from '@/shared/icons/MSCIcon';
import { Button, Card, InlineMessage } from '@/shared/ui/primitives';

export default function LoginRoute() {
  const params = useLocalSearchParams<{ returnTo?: string }>();
  const returnTo = sanitizeInternalReturnRoute(typeof params.returnTo === 'string' ? params.returnTo : '/app');
  const { signInWithGoogle } = useAuth();
  const { colors } = useAppTheme();
  const [isStarting, setIsStarting] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  async function startGoogleLogin() {
    setIsStarting(true);
    setErrorMessage(null);
    try {
      await signInWithGoogle(returnTo);
    } catch (error) {
      setIsStarting(false);
      setErrorMessage(
        error instanceof OAuthAdapterError || error instanceof PublicEnvironmentError
          ? error.message
          : 'Google tidak dapat dihubungi. Periksa koneksi lalu coba lagi.',
      );
    }
  }

  return (
    <ScrollView style={{ backgroundColor: colors.background }} contentContainerStyle={styles.page}>
      <Card>
        <Button label="Kembali" tone="secondary" onPress={() => router.back()} />
        <View style={[styles.brand, { backgroundColor: colors.primaryText }]}>
          <Text style={[styles.brandText, { color: colors.accent }]}>MSC</Text>
        </View>
        <View style={styles.copy}>
          <Text accessibilityRole="header" style={[styles.title, { color: colors.primaryText }]}>Masuk ke MSC</Text>
          <Text style={[styles.body, { color: colors.secondaryText }]}>Gunakan akun Google untuk melanjutkan. Kamu akan kembali ke halaman yang tadi dipilih.</Text>
        </View>
        {errorMessage ? <InlineMessage title="Tidak dapat masuk" message={errorMessage} tone="destructive" /> : null}
        <Button label="Lanjutkan dengan Google" loading={isStarting} onPress={() => void startGoogleLogin()} testID="google-login" />
        <View style={styles.assuranceRow}>
          <MSCIcon name="forbidden" color={colors.secondaryText} />
          <Text style={[styles.assurance, { color: colors.secondaryText }]}>Akun baru selalu dimulai sebagai Peserta. Role Coach atau Admin hanya berasal dari data yang dilindungi server.</Text>
        </View>
      </Card>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  page: { flexGrow: 1, justifyContent: 'center', width: '100%', maxWidth: componentTokens.readingMaxWidth, alignSelf: 'center', padding: primitiveTokens.space.large },
  brand: { width: 72, height: 72, borderRadius: primitiveTokens.radius.large, alignItems: 'center', justifyContent: 'center', alignSelf: 'center' },
  brandText: { fontSize: 24, lineHeight: 30, fontWeight: '900', fontStyle: 'italic' },
  copy: { gap: primitiveTokens.space.xSmall, alignItems: 'center' },
  title: typographyTokens.titleLarge,
  body: { ...typographyTokens.body, textAlign: 'center' },
  assuranceRow: { flexDirection: 'row', alignItems: 'flex-start', gap: primitiveTokens.space.small },
  assurance: { ...typographyTokens.caption, flex: 1 },
});
