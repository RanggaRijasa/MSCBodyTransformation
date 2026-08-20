import { router } from 'expo-router';
import { useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';

import { numberFormatter } from '@/shared/design/formatters';
import { componentTokens, primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { useResponsiveLayout } from '@/shared/design/useResponsiveLayout';
import { MSCIcon } from '@/shared/icons/MSCIcon';
import { Button, Card, ProgressBar, SegmentedControl, StateView, StatusBadge } from '@/shared/ui/primitives';
import type { AdminProgram } from './admin-models';
import { useAdminMutation, useAdminPrograms } from './admin-queries';
import { adminStatusLabel, adminStatusTone, completedAdminStages } from './admin-policy';

export { AdminProgramDetailExperience } from './AdminProgramEditorFlow';

type ProgramScope = 'all' | 'draft' | 'active' | 'history';

export function AdminProgramsExperience({ authorized }: { authorized: boolean }) {
  const { colors } = useAppTheme();
  const layout = useResponsiveLayout();
  const programs = useAdminPrograms(authorized);
  const mutation = useAdminMutation();
  const [search, setSearch] = useState('');
  const [scope, setScope] = useState<ProgramScope>('all');
  if (!authorized) return <StateView kind="forbidden" />;
  if (programs.isPending) return <StateView kind="loading" />;
  if (programs.isError) return <StateView kind="error" action={<Button label="Coba lagi" onPress={() => void programs.refetch()} />} />;
  const visible = (programs.data ?? []).filter((program) => {
    const matchesSearch = `${program.title} ${program.summary ?? ''}`.toLocaleLowerCase('id-ID').includes(search.trim().toLocaleLowerCase('id-ID'));
    const matchesScope = scope === 'all' || (scope === 'draft' && program.status === 'draft') || (scope === 'active' && ['scheduled', 'active'].includes(program.status)) || (scope === 'history' && ['completed', 'archived'].includes(program.status));
    return matchesSearch && matchesScope;
  });
  const create = async () => router.push(`/admin/programs/${await mutation.mutateAsync({ kind: 'createProgram' })}` as never);
  return <View style={styles.fixedScreen} testID="admin.programs">
    <View style={[styles.fixedControls, { backgroundColor: colors.background, borderColor: colors.border }]}>
      <View style={[styles.searchField, { borderColor: colors.border, backgroundColor: colors.surface }]}><MSCIcon name="search" color={colors.secondaryText} /><TextInput accessibilityLabel="Cari program" value={search} onChangeText={setSearch} placeholder="Cari program" placeholderTextColor={colors.secondaryText} style={[styles.searchInput, { color: colors.primaryText }]} /></View>
      <Button label="Buat program baru" icon="plus" loading={mutation.isPending} onPress={() => void create()} testID="admin.program.create" />
      <SegmentedControl label="Filter status program" value={scope} onChange={setScope} options={[{ label: 'Semua', value: 'all' }, { label: 'Draft', value: 'draft' }, { label: 'Aktif', value: 'active' }, { label: 'Riwayat', value: 'history' }]} />
    </View>
    <ScrollView contentContainerStyle={[styles.programList, layout === 'wide' && styles.programListWide]}>
      <View style={styles.listHeading}><Text accessibilityRole="header" style={[styles.sectionTitle, { color: colors.primaryText }]}>Daftar program</Text><Text style={[styles.body, { color: colors.secondaryText }]}>{numberFormatter.format(visible.length)} program</Text></View>
      {visible.length === 0 ? <StateView kind="empty" action={<Button label="Buat program baru" onPress={() => void create()} />} /> : visible.map((program) => <ProgramRow key={program.id} program={program} wide={layout === 'wide'} />)}
    </ScrollView>
  </View>;
}

function ProgramRow({ program, wide }: { program: AdminProgram; wide: boolean }) {
  const { colors } = useAppTheme();
  const stageCount = completedAdminStages(program);
  return <Pressable accessibilityRole="link" accessibilityLabel={`${program.title}, ${adminStatusLabel(program.status)}`} onPress={() => router.push(`/admin/programs/${program.id}` as never)} testID={`admin.program.open.${program.id}`} style={({ pressed }) => [{ opacity: pressed ? 0.72 : 1 }]}>
    <Card><View style={[styles.programRow, wide && styles.programRowWide]}>
      <View style={[styles.programIcon, { backgroundColor: program.status === 'draft' ? colors.podiumGoldSurface : colors.secondaryBackground }]}><MSCIcon name={program.status === 'draft' ? 'clipboard' : 'program'} color={program.status === 'draft' ? colors.warning : colors.primaryAction} /></View>
      <View style={styles.flex}><View style={styles.inlineWrap}><Text style={[styles.cardTitle, { color: colors.primaryText }]}>{program.title}</Text><StatusBadge label={adminStatusLabel(program.status)} tone={adminStatusTone(program.status)} /></View><Text style={[styles.body, { color: colors.secondaryText }]}>{program.status === 'draft' ? `${program.days.length} hari · ${program.days.reduce((total, day) => total + day.steps.length, 0)} langkah disusun` : statusSummary(program)}</Text>{program.status === 'draft' ? <ProgressBar label={`${stageCount} dari 3 tahap selesai`} value={stageCount / 3} /> : null}</View>
      <MSCIcon name="chevron" color={colors.secondaryText} />
    </View></Card>
  </Pressable>;
}

function statusSummary(program: AdminProgram) { if (program.status === 'active') return `Berakhir ${program.ends_on}`; if (program.status === 'scheduled') return `Mulai ${program.starts_on}`; return `Diperbarui ${new Intl.DateTimeFormat('id-ID', { dateStyle: 'medium' }).format(new Date(program.updated_at))}`; }

const styles = StyleSheet.create({
  fixedScreen: { flex: 1, minHeight: 0 }, fixedControls: { gap: primitiveTokens.space.small, borderBottomWidth: StyleSheet.hairlineWidth, padding: primitiveTokens.space.medium }, searchField: { minHeight: componentTokens.inputHeight, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.small, borderWidth: 1, borderRadius: primitiveTokens.radius.medium, paddingHorizontal: primitiveTokens.space.medium }, searchInput: { flex: 1, minWidth: 0, ...typographyTokens.body },
  programList: { width: '100%', maxWidth: componentTokens.contentMaxWidth, alignSelf: 'center', padding: primitiveTokens.space.medium, paddingBottom: 140, gap: primitiveTokens.space.medium }, programListWide: { maxWidth: 1_200, padding: primitiveTokens.space.xLarge }, listHeading: { gap: primitiveTokens.space.xxSmall }, sectionTitle: typographyTokens.title, body: typographyTokens.body, cardTitle: typographyTokens.headline,
  programRow: { flexDirection: 'row', alignItems: 'flex-start', gap: primitiveTokens.space.medium }, programRowWide: { alignItems: 'center' }, programIcon: { width: 52, height: 52, borderRadius: primitiveTokens.radius.medium, alignItems: 'center', justifyContent: 'center' }, flex: { flex: 1, minWidth: 0 }, inlineWrap: { flexDirection: 'row', flexWrap: 'wrap', alignItems: 'center', gap: primitiveTokens.space.xSmall },
});
