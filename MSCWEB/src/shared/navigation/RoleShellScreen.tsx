import type { AppRole } from './navigation-model';
import { ScrollView, StyleSheet, Text, View } from 'react-native';

import { componentTokens, primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { AppShell } from '@/shared/navigation/AppShell';
import { Card, InlineMessage, StateView, StatusBadge, UserAvatar } from '@/shared/ui/primitives';

type RoleShellScreenProps = {
  role: AppRole;
  activeRoute: string;
  title: string;
  description: string;
};

const roleLabels: Record<AppRole, string> = {
  guest: 'Area publik Peserta',
  participant: 'Peserta',
  coach: 'Coach',
  admin: 'Admin',
};

export function RoleShellScreen({ role, activeRoute, title, description }: RoleShellScreenProps) {
  const { colors } = useAppTheme();
  return (
    <AppShell role={role} activeRoute={activeRoute} title={title} subtitle={roleLabels[role]}>
      <ScrollView contentContainerStyle={styles.content}>
        <Card>
          <View style={styles.identityRow}>
            <UserAvatar label={roleLabels[role]} />
            <View style={styles.identityCopy}>
              <StatusBadge label="Shell siap" tone="success" />
              <Text accessibilityRole="header" style={[styles.cardTitle, { color: colors.primaryText }]}>{title}</Text>
              <Text style={[styles.body, { color: colors.secondaryText }]}>{description}</Text>
            </View>
          </View>
        </Card>
        {role === 'guest' ? (
          <InlineMessage
            title="Mode tamu"
            message="Halaman publik tidak memuat profil, program yang diikuti, berat badan, pembayaran, atau media privat."
          />
        ) : null}
        <StateView kind="empty" />
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
    gap: primitiveTokens.space.large,
  },
  identityRow: { flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.medium },
  identityCopy: { flex: 1, gap: primitiveTokens.space.xSmall },
  cardTitle: typographyTokens.headline,
  body: typographyTokens.body,
});
