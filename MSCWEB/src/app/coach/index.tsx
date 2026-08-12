import { Link } from 'expo-router';
import { ScrollView, StyleSheet, Text, View } from 'react-native';

import { useAuth } from '@/shared/auth/AuthProvider';
import { primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { AppShell } from '@/shared/navigation/AppShell';
import { Card, StateView } from '@/shared/ui/primitives';

export default function CoachDashboardRoute() {
  const { state } = useAuth();
  const { colors } = useAppTheme();
  if (state.status !== 'authenticated' || state.account.role !== 'coach') {
    return <AppShell role="coach" activeRoute="dashboard" title="Dashboard"><StateView kind="forbidden" /></AppShell>;
  }
  return (
    <AppShell role="coach" activeRoute="dashboard" title="Dashboard">
      <ScrollView contentContainerStyle={styles.content}>
        <Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>Aksi cepat</Text>
        <Link href="/coach/reviews" style={{ textDecorationLine: 'none' }}>
          <Card>
            <View style={styles.row}>
              <View style={styles.flex}>
                <Text style={[styles.cardTitle, { color: colors.primaryText }]}>Periksa bukti</Text>
                <Text style={[styles.body, { color: colors.secondaryText }]}>{state.account.pendingSubmissionCount} bukti menunggu keputusan Anda.</Text>
              </View>
              <Text style={[styles.chevron, { color: colors.primaryAction }]}>›</Text>
            </View>
          </Card>
        </Link>
      </ScrollView>
    </AppShell>
  );
}

const styles = StyleSheet.create({
  content: { width: '100%', maxWidth: 900, alignSelf: 'center', padding: primitiveTokens.space.large, gap: primitiveTokens.space.medium },
  heading: typographyTokens.title,
  cardTitle: typographyTokens.headline,
  body: typographyTokens.body,
  row: { flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.medium },
  flex: { flex: 1, minWidth: 0, gap: primitiveTokens.space.xxSmall },
  chevron: { fontSize: 34, lineHeight: 38 },
});
