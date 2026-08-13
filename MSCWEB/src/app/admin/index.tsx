import { router } from 'expo-router';
import { StyleSheet, Text, View } from 'react-native';

import { useAdminPaymentQueue } from '@/features/payment/payment-queries';
import { useAuth } from '@/shared/auth/AuthProvider';
import { primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { AppShell } from '@/shared/navigation/AppShell';
import { Button, Card, StateView, StatusBadge } from '@/shared/ui/primitives';

export default function AdminDashboardRoute() {
  const { state } = useAuth();
  const { colors } = useAppTheme();
  const authorized = state.status === 'authenticated' && state.account.role === 'admin';
  const payments = useAdminPaymentQueue(authorized);
  const count = payments.data?.filter((item) => item.order.status === 'under_review').length ?? 0;
  return (
    <AppShell role="admin" activeRoute="dashboard" title="Dashboard">
      {!authorized ? <StateView kind="forbidden" /> : payments.isPending ? <StateView kind="loading" /> : payments.isError ? <StateView kind="error" action={<Button label="Coba lagi" onPress={() => void payments.refetch()} />} /> : (
        <View style={styles.content}>
          <Card>
            <View style={styles.row}>
              <View style={styles.flexCopy}>
                <Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>Pembayaran perlu tindakan</Text>
                <Text style={[styles.body, { color: colors.secondaryText }]}>Periksa bukti tertua terlebih dahulu. Persetujuan dan penolakan selalu dicatat oleh server.</Text>
              </View>
              <StatusBadge label={`${count} menunggu`} tone={count > 0 ? 'warning' : 'success'} />
            </View>
            <Button label="Buka antrean pembayaran" onPress={() => router.push('/admin/payments')} />
          </Card>
        </View>
      )}
    </AppShell>
  );
}

const styles = StyleSheet.create({
  content: { width: '100%', maxWidth: 900, alignSelf: 'center', padding: primitiveTokens.space.large },
  row: { flexDirection: 'row', flexWrap: 'wrap', gap: primitiveTokens.space.medium, alignItems: 'flex-start' },
  flexCopy: { flex: 1, minWidth: 240, gap: primitiveTokens.space.xSmall },
  heading: typographyTokens.headline,
  body: typographyTokens.body,
});
