import { router } from 'expo-router';
import { ScrollView, StyleSheet, Text, View } from 'react-native';

import { componentTokens, primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { Button, Card, StateView, StatusBadge } from '@/shared/ui/primitives';
import { useAdminEvidence } from './admin-queries';

export function AdminEvidenceOperations({ authorized }: { authorized: boolean }) {
  const { colors } = useAppTheme(); const queue = useAdminEvidence(authorized);
  if (!authorized) return <StateView kind="forbidden" />;
  if (queue.isPending) return <StateView kind="loading" />;
  if (queue.isError) return <StateView kind="error" action={<Button label="Coba lagi" onPress={() => void queue.refetch()} />} />;
  return <ScrollView contentContainerStyle={styles.content} testID="admin.operations.evidence"><Button label="Kembali ke dashboard" icon="back" tone="secondary" onPress={() => router.replace('/admin')} /><View style={styles.intro}><Text accessibilityRole="header" style={[styles.title, { color: colors.primaryText }]}>Pemeriksaan tertunda</Text><Text style={[styles.body, { color: colors.secondaryText }]}>Admin memantau antrean. Keputusan bukti aktivitas tetap dilakukan Coach yang ditugaskan.</Text></View><Button label="Buka pembayaran manual" icon="bank" tone="secondary" onPress={() => router.push('/admin/payments')} />{queue.data?.length ? queue.data.map((item) => <Card key={item.submission_id}><View style={styles.rowBetween}><View style={styles.flex}><Text style={[styles.cardTitle, { color: colors.primaryText }]}>{item.participant_name}</Text><Text style={[styles.body, { color: colors.secondaryText }]}>{item.program_title} · {item.step_title}</Text><Text style={[styles.caption, { color: colors.secondaryText }]}>{item.submitted_at ? formatDateTime(item.submitted_at) : 'Waktu belum tersedia'}</Text></View><StatusBadge label="Menunggu Coach" tone="warning" /></View></Card>) : <StateView kind="empty" />}</ScrollView>;
}

function formatDateTime(value: string) { return new Intl.DateTimeFormat('id-ID', { dateStyle: 'medium', timeStyle: 'short', timeZone: 'Asia/Makassar' }).format(new Date(value)); }
const styles = StyleSheet.create({ content: { width: '100%', maxWidth: componentTokens.contentMaxWidth, alignSelf: 'center', padding: primitiveTokens.space.medium, paddingBottom: 140, gap: primitiveTokens.space.medium }, intro: { gap: primitiveTokens.space.xxSmall }, rowBetween: { flexDirection: 'row', flexWrap: 'wrap', alignItems: 'flex-start', justifyContent: 'space-between', gap: primitiveTokens.space.small }, flex: { flex: 1, minWidth: 0 }, title: typographyTokens.title, cardTitle: typographyTokens.headline, body: typographyTokens.body, caption: typographyTokens.caption });

