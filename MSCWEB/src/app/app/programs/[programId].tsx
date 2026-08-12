import { useLocalSearchParams, router } from 'expo-router';
import { useState } from 'react';
import { ScrollView, StyleSheet, Text, View } from 'react-native';

import { publicScreenStyles, Section } from '@/features/public/PublicComponents';
import { useProgram } from '@/features/public/public-queries';
import { useAuth } from '@/shared/auth/AuthProvider';
import { dateFormatter } from '@/shared/design/formatters';
import { primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { AppShell } from '@/shared/navigation/AppShell';
import { Button, Card, InlineMessage, StateView, StatusBadge } from '@/shared/ui/primitives';

export default function ProgramDetailRoute() {
  const params = useLocalSearchParams<{ programId?: string }>();
  const programId = typeof params.programId === 'string' ? params.programId : '';
  const program = useProgram(programId);
  const { colors } = useAppTheme();
  const { state, requireAuthentication } = useAuth();
  const [joinNotice, setJoinNotice] = useState(false);
  const role = state.status === 'authenticated' ? state.account.role : 'guest';

  return (
    <AppShell role={role} activeRoute="programs" title={program.data?.title ?? 'Detail program'} subtitle="Informasi program publik">
      <ScrollView contentContainerStyle={publicScreenStyles.content}>
        <Button label="Kembali ke Program" tone="secondary" onPress={() => router.back()} />
        {program.isPending ? <StateView kind="loading" /> : program.isError ? <StateView kind="error" action={<Button label="Coba lagi" onPress={() => void program.refetch()} />} /> : !program.data ? <StateView kind="empty" /> : (
          <>
            <Card>
              <StatusBadge label={program.data.status === 'active' ? 'Aktif' : program.data.status === 'scheduled' ? 'Segera hadir' : 'Selesai'} tone={program.data.status === 'active' ? 'success' : 'info'} />
              <Text accessibilityRole="header" style={[styles.title, { color: colors.primaryText }]}>{program.data.title}</Text>
              <Text style={[styles.body, { color: colors.secondaryText }]}>{program.data.summary || 'Program transformasi dengan langkah harian yang terarah.'}</Text>
              <Text style={[styles.label, { color: colors.primaryText }]}>Mulai {dateFormatter.format(new Date(`${program.data.starts_on}T12:00:00Z`))} · Zona waktu {program.data.timezone}</Text>
              <Button label="Gabung program" onPress={() => {
                if (requireAuthentication(`/app/programs/${programId}`)) {
                  setJoinNotice(true);
                }
              }} />
              {joinNotice ? <InlineMessage title="Siap untuk tahap pendaftaran" message="Sesi dan pilihan program sudah aman. Pemindaian QR Coach dilanjutkan pada fase pendaftaran program." tone="success" /> : null}
            </Card>
            <InlineMessage title="Untuk kebugaran dan wellness" message={program.data.wellness_disclaimer || 'Program ini bukan diagnosis atau pengganti saran tenaga kesehatan.'} />
            <Section title="Rangkaian program" intro={`${program.data.program_days.length} hari yang disusun bertahap.`}>
              <View style={publicScreenStyles.stack}>{program.data.program_days.map((day) => <Card key={day.id}><Text style={[styles.cardTitle, { color: colors.primaryText }]}>Hari {day.day_number} · {day.title}</Text>{day.summary ? <Text style={[styles.body, { color: colors.secondaryText }]}>{day.summary}</Text> : null}<Text style={[styles.label, { color: colors.secondaryText }]}>{day.program_steps.length} langkah</Text></Card>)}</View>
            </Section>
          </>
        )}
      </ScrollView>
    </AppShell>
  );
}

const styles = StyleSheet.create({ title: typographyTokens.titleLarge, cardTitle: typographyTokens.headline, body: typographyTokens.body, label: typographyTokens.label, actionRow: { gap: primitiveTokens.space.small } });
