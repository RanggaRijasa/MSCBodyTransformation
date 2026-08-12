import { ScrollView, StyleSheet, Text, View } from 'react-native';

import { componentTokens, primitiveTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { AppShell } from '@/shared/navigation/AppShell';

export default function AppHomeRoute() {
  const { colors } = useAppTheme();

  return (
    <AppShell activeRoute="home" title="Beranda">
      <ScrollView contentContainerStyle={styles.content}>
        <View style={[styles.panel, { backgroundColor: colors.surface, borderColor: colors.border }]}>
          <Text accessibilityRole="header" style={[styles.title, { color: colors.primaryText }]}>
            Shell aplikasi siap
          </Text>
          <Text style={[styles.body, { color: colors.secondaryText }]}>
            Navigasi berubah dari tab bawah pada layar ringkas menjadi rail pada layar lebar, dengan model route yang sama.
          </Text>
        </View>
      </ScrollView>
    </AppShell>
  );
}

const styles = StyleSheet.create({
  content: {
    flexGrow: 1,
    width: '100%',
    maxWidth: componentTokens.contentMaxWidth,
    alignSelf: 'center',
    padding: primitiveTokens.space.large,
  },
  panel: {
    borderWidth: StyleSheet.hairlineWidth,
    borderRadius: primitiveTokens.radius.large,
    padding: primitiveTokens.space.large,
    gap: primitiveTokens.space.small,
  },
  title: {
    fontSize: 24,
    lineHeight: 30,
    fontWeight: '700',
  },
  body: {
    fontSize: 16,
    lineHeight: 24,
  },
});
