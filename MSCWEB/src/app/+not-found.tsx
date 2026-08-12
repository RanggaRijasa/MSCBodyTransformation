import { Link } from 'expo-router';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { componentTokens, primitiveTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';

export default function NotFoundRoute() {
  const { colors } = useAppTheme();

  return (
    <View style={[styles.page, { backgroundColor: colors.background }]}>
      <Text accessibilityRole="header" style={[styles.title, { color: colors.primaryText }]}>Halaman tidak ditemukan</Text>
      <Text style={[styles.body, { color: colors.secondaryText }]}>Periksa alamat halaman atau kembali ke beranda.</Text>
      <Link href="/" asChild>
        <Pressable style={[styles.button, { backgroundColor: colors.primaryAction }]}>
          <Text style={styles.buttonLabel}>Kembali ke beranda</Text>
        </Pressable>
      </Link>
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
  title: {
    fontSize: 30,
    lineHeight: 38,
    fontWeight: '800',
    textAlign: 'center',
  },
  body: {
    fontSize: 16,
    lineHeight: 24,
    textAlign: 'center',
  },
  button: {
    minHeight: componentTokens.primaryButtonHeight,
    justifyContent: 'center',
    paddingHorizontal: primitiveTokens.space.large,
    borderRadius: primitiveTokens.radius.medium,
  },
  buttonLabel: {
    color: primitiveTokens.color.white,
    fontSize: 16,
    fontWeight: '700',
  },
});
