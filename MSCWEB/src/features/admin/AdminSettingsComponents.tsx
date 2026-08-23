import { router } from 'expo-router';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';

import { AccountSignOutButton } from '@/shared/auth/AccountSignOutButton';
import { componentTokens, primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { MSCIcon } from '@/shared/icons/MSCIcon';
import { Button, Card, StateView } from '@/shared/ui/primitives';
import { useAdminAudit } from './admin-queries';

export function AdminSettingsExperience({ authorized }: { authorized: boolean }) {
  const { colors } = useAppTheme(); const audit = useAdminAudit(authorized);
  if (!authorized) return <StateView kind="forbidden" />;
  if (audit.isPending) return <StateView kind="loading" />;
  if (audit.isError) return <StateView kind="error" action={<Button label="Coba lagi" onPress={() => void audit.refetch()} />} />;
  return <ScrollView contentContainerStyle={styles.content} testID="admin.settings"><Text accessibilityRole="header" style={[styles.sectionTitle, { color: colors.primaryText }]}>Konfigurasi lokal</Text><Card><Setting label="Zona waktu default" value="Asia/Makassar" /><Setting label="Locale aplikasi" value="id-ID" /><Setting label="Mode data" value="Supabase lokal" /><Setting label="Credential" value="Dikelola server · tidak ditampilkan" /></Card><Pressable accessibilityRole="button" onPress={() => router.push('/admin/audit' as never)} style={[styles.auditLink, { borderColor: colors.border, backgroundColor: colors.surface }]}><View style={styles.flex}><Text style={[styles.cardTitle, { color: colors.primaryText }]}>Jejak audit</Text><Text style={[styles.body, { color: colors.secondaryText }]}>{audit.data?.length ?? 0} aktivitas terbaru tersedia untuk Admin.</Text></View><MSCIcon name="chevron" color={colors.secondaryText} /></Pressable><Text style={[styles.caption, { color: colors.secondaryText }]}>Pengaturan browser tidak pernah menampilkan atau mengubah API key, service role, secret provider, atau credential deployment.</Text><AccountSignOutButton /></ScrollView>;
}

export function AdminAuditExperience({ authorized }: { authorized: boolean }) {
  const { colors } = useAppTheme(); const audit = useAdminAudit(authorized);
  if (!authorized) return <StateView kind="forbidden" />;
  if (audit.isPending) return <StateView kind="loading" />;
  if (audit.isError) return <StateView kind="error" action={<Button label="Coba lagi" onPress={() => void audit.refetch()} />} />;
  return <ScrollView contentContainerStyle={styles.content} testID="admin.audit"><Button label="Kembali ke Pengaturan" icon="back" tone="secondary" onPress={() => router.back()} /><Text accessibilityRole="header" style={[styles.sectionTitle, { color: colors.primaryText }]}>Jejak audit</Text>{audit.data?.length ? <Card>{audit.data.map((event, index) => <View key={event.id} style={[styles.auditRow, index > 0 && { borderColor: colors.border }]}><Text style={[styles.cardTitle, { color: colors.primaryText }]}>{event.summary}</Text><Text style={[styles.body, { color: colors.secondaryText }]}>{event.actor_name || 'Operasi sistem'} · {event.kind}</Text><Text style={[styles.caption, { color: colors.secondaryText }]}>{formatDateTime(event.created_at)}</Text></View>)}</Card> : <StateView kind="empty" />}</ScrollView>;
}

function Setting({ label, value }: { label: string; value: string }) { const { colors } = useAppTheme(); return <View style={[styles.settingRow, { borderColor: colors.border }]}><Text style={[styles.body, { color: colors.primaryText }]}>{label}</Text><Text style={[styles.body, { color: colors.secondaryText }]}>{value}</Text></View>; }
function formatDateTime(value: string) { return new Intl.DateTimeFormat('id-ID', { dateStyle: 'medium', timeStyle: 'short', timeZone: 'Asia/Makassar' }).format(new Date(value)); }
const styles = StyleSheet.create({ content: { width: '100%', maxWidth: componentTokens.contentMaxWidth, alignSelf: 'center', padding: primitiveTokens.space.medium, paddingBottom: 140, gap: primitiveTokens.space.medium }, settingRow: { minHeight: 48, flexDirection: 'row', flexWrap: 'wrap', alignItems: 'center', justifyContent: 'space-between', gap: primitiveTokens.space.small, borderTopWidth: StyleSheet.hairlineWidth, paddingVertical: primitiveTokens.space.small }, auditLink: { minHeight: 76, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.small, borderWidth: 1, borderRadius: primitiveTokens.radius.large, padding: primitiveTokens.space.medium }, auditRow: { borderTopWidth: StyleSheet.hairlineWidth, paddingVertical: primitiveTokens.space.small, gap: primitiveTokens.space.xxSmall }, flex: { flex: 1, minWidth: 0 }, sectionTitle: typographyTokens.title, cardTitle: typographyTokens.headline, body: typographyTokens.body, caption: typographyTokens.caption });
