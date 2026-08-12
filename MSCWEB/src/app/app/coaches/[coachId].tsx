import { router, useLocalSearchParams } from 'expo-router';
import { ScrollView, StyleSheet, Text, View } from 'react-native';

import { publicScreenStyles } from '@/features/public/PublicComponents';
import { useCoach } from '@/features/public/public-queries';
import { useAuth } from '@/shared/auth/AuthProvider';
import { primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { AppShell } from '@/shared/navigation/AppShell';
import { Button, Card, InlineMessage, StateView, UserAvatar } from '@/shared/ui/primitives';

export default function CoachDetailRoute() {
  const params = useLocalSearchParams<{ coachId?: string }>();
  const coachId = typeof params.coachId === 'string' ? params.coachId : '';
  const coach = useCoach(coachId);
  const { colors } = useAppTheme();
  const { state } = useAuth();
  const role = state.status === 'authenticated' ? state.account.role : 'guest';
  return (
    <AppShell role={role} activeRoute="coaches" title={coach.data?.display_name ?? 'Profil Coach'} subtitle="Profil publik Coach">
      <ScrollView contentContainerStyle={publicScreenStyles.content}>
        <Button label="Kembali ke Coach" tone="secondary" onPress={() => router.back()} />
        {coach.isPending ? <StateView kind="loading" /> : coach.isError ? <StateView kind="error" /> : !coach.data ? <StateView kind="empty" /> : (
          <Card>
            <View style={styles.identityRow}>
              <UserAvatar uri={coach.data.photo_reference ?? undefined} label={coach.data.display_name} size={88} />
              <View style={styles.copy}>
                <Text accessibilityRole="header" style={[styles.title, { color: colors.primaryText }]}>{coach.data.display_name}</Text>
                <Text style={[styles.body, { color: colors.secondaryText }]}>{coach.data.city || 'Lokasi belum dicantumkan'}</Text>
              </View>
            </View>
            <Text style={[styles.body, { color: colors.secondaryText }]}>{coach.data.biography || 'Coach ini belum menambahkan cerita profil.'}</Text>
            <InlineMessage title="Pilih Coach melalui alur program" message="Pendaftaran program menggunakan pemindaian QR. Kode mentah tidak ditampilkan atau dapat diketik." />
          </Card>
        )}
      </ScrollView>
    </AppShell>
  );
}

const styles = StyleSheet.create({ identityRow: { flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.medium }, copy: { flex: 1, gap: primitiveTokens.space.xxSmall }, title: typographyTokens.title, body: typographyTokens.body });
