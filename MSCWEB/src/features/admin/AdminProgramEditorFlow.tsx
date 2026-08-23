import { router } from 'expo-router';
import { useState } from 'react';
import { Image, Platform, Pressable, StyleSheet, Text, View } from 'react-native';

import { ProgramDefinitionPreview, ProgramOffer } from '@/features/participant/ParticipantProgramComponents';
import type { PublicProgram } from '@/features/public/public-models';
import { dateFormatter, numberFormatter } from '@/shared/design/formatters';
import { primitiveTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { MSCIcon } from '@/shared/icons/MSCIcon';
import { Button, Dialog, InlineMessage, SegmentedControl, StateView } from '@/shared/ui/primitives';
import { AdminProgramContentFlow } from './AdminProgramContentFlow';
import { editorStyles, FormSection, FormTextInput, GroupDivider, LabeledValueRow, NavigationRow, ProgramEditorScaffold, StatusLine, ToggleRow, TopTextAction } from './AdminProgramEditorShared';
import type { AdminProgram, AdminProgramStatus } from './admin-models';
import { useAdminClosure, useAdminMutation, useAdminPaymentDestinationReadiness, useAdminProgram, useAdminWinnerPreview } from './admin-queries';
import { adminStatusLabel, completedAdminStages, validateAdminProgram, type AdminProgramStage } from './admin-policy';
import { getAdminRepository } from './admin-repository';
import { openWebNativePicker } from './web-native-picker';

export type AdminProgramSection = 'overview' | 'settings' | 'info' | 'schedule' | 'rules' | 'content' | 'day' | 'step' | 'questions' | 'question' | 'review' | 'preview' | 'publication';

type FlowParams = Readonly<{ section?: string; dayId?: string; stepId?: string; questionId?: string }>;

export function AdminProgramDetailExperience({ authorized, programId, params }: { authorized: boolean; programId: string; params: FlowParams }) {
  const query = useAdminProgram(programId);
  if (!authorized) return <StateView kind="forbidden" />;
  if (query.isPending || !query.data) return <StateView kind="loading" />;
  if (query.isError) return <StateView kind="error" action={<Button label="Coba lagi" onPress={() => void query.refetch()} />} />;
  const section = isSection(params.section) ? params.section : 'overview';
  if (isContentSection(section)) return <AdminProgramContentFlow key={`${query.data.id}:${query.data.updated_at}`} program={query.data} section={section} dayId={params.dayId} stepId={params.stepId} questionId={params.questionId} />;
  if (section === 'settings') return <SettingsHub program={query.data} />;
  if (section === 'info') return <ProgramInformation program={query.data} />;
  if (section === 'schedule') return <ProgramSchedule program={query.data} />;
  if (section === 'rules') return <ProgramRules program={query.data} />;
  if (section === 'review') return <ProgramReview program={query.data} />;
  if (section === 'preview') return <ProgramPreview program={query.data} />;
  if (section === 'publication') return <ProgramPublication program={query.data} />;
  return <ProgramOverview program={query.data} />;
}

function ProgramOverview({ program }: { program: AdminProgram }) {
  const { colors } = useAppTheme();
  const mutation = useAdminMutation();
  const [archiveOpen, setArchiveOpen] = useState(false);
  const [reason, setReason] = useState('Program diarsipkan setelah peninjauan Admin.');
  const stages = completedAdminStages(program);
  const go = (section: AdminProgramSection) => router.push(programHref(program.id, section) as never);
  const duplicate = async () => router.replace(`/admin/programs/${await mutation.mutateAsync({ kind: 'duplicateProgram', program })}` as never);
  return <ProgramEditorScaffold title={program.title || 'Program baru'} onBack={() => router.replace('/admin/programs')} testID="admin.program.editor.overview">
    <View style={[styles.hero, { backgroundColor: colors.surface, borderColor: colors.border }]}>
      <View style={editorStyles.rowBetween}><View style={editorStyles.flex}><Text accessibilityRole="header" style={[editorStyles.headline, { color: colors.primaryText }]}>{program.status === 'draft' ? 'Selesaikan 3 tahap' : 'Program sudah diterbitkan'}</Text><Text style={[editorStyles.body, { color: colors.secondaryText }]}>{program.status === 'draft' ? 'Lengkapi pengaturan, konten, lalu tinjau sebelum diterbitkan.' : 'Pengaturan dan konten dikunci agar program peserta tetap konsisten.'}</Text></View><ProgramStatusPill program={program} /></View>
      {program.status === 'draft' ? <AdminStageProgress completed={stages} /> : <Text style={[editorStyles.body, { color: colors.secondaryText }]}>{formatDate(program.starts_on)}–{formatDate(program.ends_on)}</Text>}
    </View>
    <View style={editorStyles.stack}>
      <StageCard number={1} icon="settings" title="Pengaturan program" subtitle="Info, jadwal, peserta, aturan, dan poin" status={stageStatus(program, 'settings')} readOnly={program.status !== 'draft'} onPress={() => go('settings')} />
      <StageCard number={2} icon="stack" title="Konten program" subtitle={contentSummary(program)} status={stageStatus(program, 'content')} readOnly={program.status !== 'draft'} onPress={() => go('content')} />
      <StageCard number={3} icon="approved" title={program.status === 'draft' ? 'Tinjau & terbitkan' : 'Status publikasi'} subtitle={program.status === 'draft' ? 'Pratinjau, validasi, dan publikasi' : publicationSummary(program.status)} status={stageStatus(program, 'review')} readOnly={program.status !== 'draft'} onPress={() => go(program.status === 'draft' ? 'review' : 'publication')} />
    </View>
    {program.status !== 'draft' ? <View style={editorStyles.stack}><InlineMessage title="Program tidak dapat diubah langsung" message="Buat salinan draft untuk menyiapkan versi baru tanpa mengubah pengalaman peserta." tone="warning" /><Button label="Duplikasikan sebagai draft" icon="copy" loading={mutation.isPending} onPress={() => void duplicate()} /><Button label="Arsipkan program" icon="archive" tone="destructive" disabled={program.status === 'archived'} onPress={() => setArchiveOpen(true)} /></View> : null}
    <Dialog visible={archiveOpen} title="Arsipkan program?" onClose={() => setArchiveOpen(false)}><FormTextInput label="Alasan arsip" value={reason} multiline onChangeText={setReason} /><Button label="Batal" tone="secondary" onPress={() => setArchiveOpen(false)} /><Button label="Arsipkan program" tone="destructive" disabled={reason.trim().length < 8} loading={mutation.isPending} onPress={() => void mutation.mutateAsync({ kind: 'archiveProgram', programId: program.id, reason }).then(() => router.replace('/admin/programs'))} /></Dialog>
  </ProgramEditorScaffold>;
}

function StageCard({ number, icon, title, subtitle, status, readOnly, onPress }: { number: number; icon: 'settings' | 'stack' | 'approved'; title: string; subtitle: string; status: string; readOnly: boolean; onPress: () => void }) {
  const { colors } = useAppTheme();
  const complete = status.includes('Selesai') || status.includes('Siap');
  return <Pressable accessibilityRole="button" accessibilityLabel={`${title}, ${status}`} onPress={onPress} style={({ pressed }) => [styles.stageCard, { backgroundColor: colors.surface, borderColor: colors.border, opacity: pressed ? 0.64 : 1 }]}>
    <View style={[styles.stageNumber, { backgroundColor: colors.primaryAction }]}><Text style={[editorStyles.headline, { color: primitiveTokens.color.white }]}>{number}</Text></View>
    <MSCIcon name={icon} color={colors.primaryText} />
    <View style={editorStyles.flex}><Text style={[editorStyles.headline, { color: colors.primaryText }]}>{title}</Text><Text style={[editorStyles.body, { color: colors.secondaryText }]}>{subtitle}</Text><StatusLine label={readOnly ? 'Terkunci · Hanya baca' : status} tone={readOnly ? 'neutral' : complete ? 'success' : 'warning'} /></View>
    <MSCIcon name="chevron" color={colors.secondaryText} size="small" />
  </Pressable>;
}

function ProgramStatusPill({ program }: { program: AdminProgram }) {
  const { colors } = useAppTheme();
  const draft = program.status === 'draft';
  return <View style={[styles.statusPill, { backgroundColor: draft ? colors.podiumGoldSurface : colors.navigationSelectedSurface }]}><MSCIcon name={draft ? 'warning' : 'approved'} color={draft ? colors.warning : colors.success} size="small" /><Text style={[editorStyles.caption, { color: draft ? colors.warning : colors.success }]}>{adminStatusLabel(program.status)}</Text></View>;
}

function AdminStageProgress({ completed }: { completed: number }) {
  const { colors } = useAppTheme(); const value = Math.max(0, Math.min(completed / 3, 1));
  return <View accessibilityRole="progressbar" accessibilityLabel={`${completed} dari 3 tahap siap`} accessibilityValue={{ min: 0, max: 3, now: completed }} style={editorStyles.compactStack}><View style={editorStyles.rowBetween}><Text style={[editorStyles.caption, { color: colors.secondaryText }]}>{completed} dari 3 tahap siap</Text><Text style={[editorStyles.caption, { color: colors.secondaryText }]}>{Math.round(value * 100)}%</Text></View><View style={[styles.progressTrack, { backgroundColor: colors.border }]}><View style={[styles.progressFill, { backgroundColor: colors.primaryAction, width: `${value * 100}%` }]} /></View></View>;
}

function SettingsHub({ program }: { program: AdminProgram }) {
  return <ProgramEditorScaffold title="Pengaturan program" onBack={() => router.back()} testID="admin.program.settings-hub">
    <FormSection footer="Ketiga bagian ini merupakan satu tahap. Kembali ke hub setelah pengaturan selesai.">
      <NavigationRow title="Info program" subtitle="Nama, deskripsi, kategori, pembayaran, dan cover" icon="content" onPress={() => router.push(programHref(program.id, 'info') as never)} testID="admin.program.editor.open.info" />
      <GroupDivider />
      <NavigationRow title="Jadwal dan peserta" subtitle={`${paceLabel(program.pace)} · ${durationDays(program)} hari · Publik`} icon="program" onPress={() => router.push(programHref(program.id, 'schedule') as never)} testID="admin.program.editor.open.schedule" />
      <GroupDivider />
      <NavigationRow title="Aturan dan poin" subtitle={`${numberFormatter.format(program.points_per_activity)} poin/langkah · ${numberFormatter.format(program.points_per_weight_kg)} poin/kg turun`} icon="settings" onPress={() => router.push(programHref(program.id, 'rules') as never)} testID="admin.program.editor.open.rules" />
    </FormSection>
  </ProgramEditorScaffold>;
}

function ProgramInformation({ program: initial }: { program: AdminProgram }) {
  const { colors } = useAppTheme(); const mutation = useAdminMutation(); const [program, setProgram] = useState(initial); const [uploading, setUploading] = useState(false);
  const editable = program.status === 'draft'; const mediaUrl = getAdminRepository().publicMediaUrl(program.cover_path);
  const patch = (values: Partial<AdminProgram>) => setProgram((current) => ({ ...current, ...values }));
  const save = () => void mutation.mutateAsync({ kind: 'saveProgram', program }).then(() => router.back());
  const pickCover = async (file?: File) => { if (!file) return; setUploading(true); try { patch({ cover_path: await getAdminRepository().uploadPublicImage(file, 'programs') }); } finally { setUploading(false); } };
  return <ProgramEditorScaffold title="Info program" onBack={() => router.back()} action={editable ? <TopTextAction label={mutation.isPending ? 'Menyimpan…' : 'Simpan'} disabled={mutation.isPending} onPress={save} /> : undefined} testID="admin.program.info">
    {!editable ? <InlineMessage title="Hanya baca" message="Program yang diterbitkan tidak dapat diubah langsung." tone="warning" /> : null}
    <FormSection title="Identitas program">
      <FormTextInput label="Nama" value={program.title} editable={editable} onChangeText={(title) => patch({ title })} />
      <GroupDivider />
      <FormTextInput label="Kategori" value={program.category ?? ''} editable={editable} onChangeText={(category) => patch({ category })} />
      <GroupDivider />
      <FormTextInput label="Deskripsi" value={program.summary ?? ''} editable={editable} multiline onChangeText={(summary) => patch({ summary })} />
    </FormSection>
    <View style={editorStyles.stack}><Text style={[styles.sectionHeading, { color: colors.secondaryText }]}>Pembayaran</Text><SegmentedControl label="Jenis program" value={program.pricing_mode} onChange={(pricing_mode) => patch({ pricing_mode, desired_price: pricing_mode === 'free' ? null : program.desired_price ?? 100_000 })} options={[{ label: 'Gratis', value: 'free' }, { label: 'Berbayar', value: 'paid' }]} />{program.pricing_mode === 'paid' ? <FormSection footer="Nominal ditampilkan dalam IDR dan diperiksa pada alur pembayaran program."><FormTextInput label="Harga yang diinginkan" value={program.desired_price?.toString() ?? ''} editable={editable} inputMode="numeric" onChangeText={(value) => patch({ desired_price: Number(value.replace(/\D/gu, '')) || null })} /></FormSection> : null}</View>
    <FormSection title="Cover program" footer="Cover selalu berupa gambar rasio lebar. Jelaskan isinya secara singkat untuk aksesibilitas.">
      {mediaUrl ? <Image accessibilityLabel={program.cover_alt_text ?? 'Cover program'} source={{ uri: mediaUrl }} style={styles.coverImage} /> : <View style={[styles.coverPlaceholder, { backgroundColor: colors.primaryAction }, Platform.OS === 'web' ? styles.coverGradientWeb : null]}><MSCIcon name="image" color={primitiveTokens.color.white} size="large" /></View>}
      <GroupDivider />
      {Platform.OS === 'web' && editable ? <label style={{ display: 'block', cursor: 'pointer' }}><span style={fileRowStyle(colors.primaryAction)}>{uploading ? 'Memproses cover…' : program.cover_path ? 'Ganti gambar cover ›' : 'Pilih gambar cover ›'}</span><input aria-label="Pilih gambar cover" type="file" accept="image/jpeg,image/png,image/webp,image/heic,image/heif" disabled={uploading} onChange={(event) => void pickCover(event.currentTarget.files?.[0])} style={hiddenFileInput} /></label> : null}
      {program.cover_path && editable ? <><GroupDivider /><NavigationRow title="Hapus gambar cover" icon="archive" destructive onPress={() => patch({ cover_path: null })} /></> : null}
      <GroupDivider />
      <FormTextInput label="Teks alternatif cover" value={program.cover_alt_text ?? ''} editable={editable} multiline onChangeText={(cover_alt_text) => patch({ cover_alt_text })} />
    </FormSection>
    {mutation.error instanceof Error ? <InlineMessage title="Belum dapat disimpan" message={mutation.error.message} tone="destructive" /> : null}
  </ProgramEditorScaffold>;
}

function ProgramSchedule({ program: initial }: { program: AdminProgram }) {
  const mutation = useAdminMutation(); const [program, setProgram] = useState(initial); const [fixedDays, setFixedDays] = useState(() => durationDays(initial)); const editable = program.status === 'draft'; const patch = (values: Partial<AdminProgram>) => setProgram((current) => ({ ...current, ...values }));
  const save = () => void mutation.mutateAsync({ kind: 'saveProgram', program }).then(() => router.back());
  const setDurationMode = (duration_mode: 'fixed_duration' | 'specific_dates') => {
    if (duration_mode === 'fixed_duration') patch({ duration_mode, ends_on: addDays(program.starts_on, fixedDays - 1) }); else patch({ duration_mode });
  };
  const setStartDate = (starts_on: string) => patch({ starts_on, ...(program.duration_mode === 'fixed_duration' ? { ends_on: addDays(starts_on, fixedDays - 1) } : {}) });
  const changeFixedDays = (offset: number) => { const value = Math.min(365, Math.max(1, fixedDays + offset)); setFixedDays(value); patch({ ends_on: addDays(program.starts_on, value - 1) }); };
  return <ProgramEditorScaffold title="Jadwal dan peserta" onBack={() => router.back()} action={editable ? <TopTextAction label={mutation.isPending ? 'Menyimpan…' : 'Simpan'} disabled={mutation.isPending} onPress={save} /> : undefined} testID="admin.program.schedule">
    <InlineMessage title="Jadwal dikunci setelah peserta bergabung" message="Pastikan tanggal, zona waktu, dan batas peserta sudah benar." />
    <FormSection title="Pola penyelesaian" footer={program.pace === 'scheduled' ? 'Langkah tersedia pada hari yang ditentukan.' : 'Peserta dapat memulai sesuai waktunya.'}><View style={styles.segmentInset}><SegmentedControl label="Pola program" value={program.pace} onChange={(pace) => patch({ pace })} options={[{ label: 'Mandiri', value: 'self_paced' }, { label: 'Terjadwal', value: 'scheduled' }]} /></View></FormSection>
    <FormSection title="Jadwal program">
      <WebSelectRow label="Jenis durasi" value={program.duration_mode === 'fixed_duration' ? 'fixed_duration' : 'specific_dates'} disabled={!editable} options={[{ label: 'Durasi tetap', value: 'fixed_duration' }, { label: 'Tanggal tertentu', value: 'specific_dates' }]} onChange={(value) => setDurationMode(value as 'fixed_duration' | 'specific_dates')} />
      <GroupDivider />
      {program.duration_mode === 'fixed_duration' ? <><WebDateRow label="Tanggal acuan" value={program.starts_on} disabled={!editable} onChange={setStartDate} /><GroupDivider /><DurationStepper days={fixedDays} disabled={!editable} onDecrease={() => changeFixedDays(-1)} onIncrease={() => changeFixedDays(1)} /></> : <><WebDateRow label="Mulai" value={program.starts_on} disabled={!editable} onChange={setStartDate} /><GroupDivider /><WebDateRow label="Selesai" value={program.ends_on} min={program.starts_on} disabled={!editable} onChange={(ends_on) => patch({ ends_on })} /></>}
      <GroupDivider /><WebSelectRow label="Zona waktu" value={program.timezone} disabled={!editable} options={timeZoneOptions} onChange={(timezone) => patch({ timezone })} />
    </FormSection>
    <FormSection title="Peserta">
      <LabeledValueRow label="Akses" value="Publik" />
      <GroupDivider /><ToggleRow label="Batasi jumlah peserta" value={program.participant_limit !== null} onChange={(enabled) => patch({ participant_limit: enabled ? 50 : null })} />
      {program.participant_limit !== null ? <><GroupDivider /><FormTextInput label="Maksimal peserta" value={program.participant_limit.toString()} editable={editable} inputMode="numeric" onChangeText={(value) => patch({ participant_limit: Math.max(1, Number(value) || 1) })} /></> : null}
      <GroupDivider /><ToggleRow label="Batasi waktu pendaftaran" value={program.registration_closes_at !== null && program.registration_closes_at !== undefined} onChange={(enabled) => patch({ registration_closes_at: enabled ? `${program.starts_on}T00:00:00+08:00` : null })} />
      {program.registration_closes_at ? <><GroupDivider /><WebDateTimeRow label="Batas pendaftaran" value={program.registration_closes_at} timeZone={program.timezone} disabled={!editable} onChange={(registration_closes_at) => patch({ registration_closes_at })} /></> : null}
    </FormSection>
    <InlineMessage title="Sinkronkan konten setelah jadwal berubah" message="Buka Konten program untuk menyelaraskan hari tanpa menghapus isi yang masih berada dalam rentang." />
  </ProgramEditorScaffold>;
}

function ProgramRules({ program: initial }: { program: AdminProgram }) {
  const mutation = useAdminMutation(); const [program, setProgram] = useState(initial); const editable = program.status === 'draft'; const patch = (values: Partial<AdminProgram>) => setProgram((current) => ({ ...current, ...values }));
  const save = () => void mutation.mutateAsync({ kind: 'saveProgram', program }).then(() => router.back());
  return <ProgramEditorScaffold title="Aturan dan poin" onBack={() => router.back()} action={editable ? <TopTextAction label={mutation.isPending ? 'Menyimpan…' : 'Simpan'} disabled={mutation.isPending} onPress={save} /> : undefined} testID="admin.program.rules">
    <FormSection title="Poin langkah" footer="Diberikan saat langkah non-kuis disetujui. Kuis memberikan poin ini untuk setiap jawaban benar."><FormTextInput label="Poin setiap langkah selesai" value={program.points_per_activity.toString()} editable={editable} inputMode="numeric" onChangeText={(value) => patch({ points_per_activity: Number(value) || 0 })} /></FormSection>
    <FormSection title="Poin penurunan berat badan" footer="Dihitung dari selisih timbang awal dan timbang akhir. Timbang harian hanya mencatat progres."><FormTextInput label="Poin setiap 1 kg turun" value={program.points_per_weight_kg.toString()} editable={editable} inputMode="decimal" onChangeText={(value) => patch({ points_per_weight_kg: Number(value.replace(',', '.')) || 0 })} /></FormSection>
    <FormSection title="Kuis dan pemeriksaan"><PercentageStepper value={program.quiz_passing_percentage} disabled={!editable} onChange={(quiz_passing_percentage) => patch({ quiz_passing_percentage })} /><GroupDivider /><WebSelectRow label="Pemeriksaan default" value={program.default_verification_mode} disabled={!editable} options={verificationModeOptions} onChange={(default_verification_mode) => patch({ default_verification_mode: default_verification_mode as AdminProgram['default_verification_mode'] })} /></FormSection>
    <FormSection title="Akses hari program" footer="Kebijakan ini menentukan apakah aktivitas di luar hari aktif dapat dibuka, hanya dibaca, dikunci, atau disembunyikan."><WebSelectRow label="Langkah lampau" value={program.past_step_policy} disabled={!editable} options={pastPolicyOptions} onChange={(past_step_policy) => patch({ past_step_policy })} /><GroupDivider /><WebSelectRow label="Langkah mendatang" value={program.future_step_policy} disabled={!editable} options={futurePolicyOptions} onChange={(future_step_policy) => patch({ future_step_policy })} /></FormSection>
    <FormSection title="Informasi wellness"><FormTextInput label="Informasi untuk peserta" value={program.wellness_disclaimer ?? ''} editable={editable} multiline onChangeText={(wellness_disclaimer) => patch({ wellness_disclaimer })} /></FormSection>
  </ProgramEditorScaffold>;
}

function ProgramReview({ program }: { program: AdminProgram }) {
  const { colors } = useAppTheme(); const mutation = useAdminMutation(); const issues = validateAdminProgram(program); const paymentReadiness = useAdminPaymentDestinationReadiness(program.pricing_mode === 'paid');
  const paymentChecking = program.pricing_mode === 'paid' && paymentReadiness.isPending;
  const paymentBlocked = program.pricing_mode === 'paid' && !paymentChecking && (!paymentReadiness.data || paymentReadiness.isError);
  const publish = async () => {
    try {
      await mutation.mutateAsync({ kind: 'publishProgram', programId: program.id });
      router.replace(`/admin/programs/${program.id}` as never);
    } catch {
      // React Query exposes the localized failure below and keeps this screen open.
    }
  };
  return <ProgramEditorScaffold title="Tinjau & terbitkan" onBack={() => router.back()} testID="admin.program.review-publish">
    <FormSection title="Pratinjau"><NavigationRow title="Pratinjau program" subtitle="Periksa tampilan Peserta dan Coach sebelum diterbitkan" icon="info" onPress={() => router.push(programHref(program.id, 'preview') as never)} testID="admin.program.editor.open.preview" /></FormSection>
    <FormSection title="Validasi">{issues.length === 0 ? <StatusLine label="Semua bagian siap diterbitkan." /> : issues.map((issue, index) => <View key={`${issue.stage}-${index}`}><StatusLine label={issue.message} tone="warning" />{index < issues.length - 1 ? <GroupDivider /> : null}</View>)}</FormSection>
    <FormSection title="Ringkasan"><LabeledValueRow label="Nama" value={program.title} /><GroupDivider /><LabeledValueRow label="Hari" value={numberFormatter.format(program.days.length)} /><GroupDivider /><LabeledValueRow label="Langkah" value={numberFormatter.format(program.days.flatMap((day) => day.steps).length)} /><GroupDivider /><LabeledValueRow label="Pertanyaan" value={numberFormatter.format(program.days.flatMap((day) => day.steps).flatMap((step) => step.questions).length)} /></FormSection>
    {program.pricing_mode === 'paid' && paymentReadiness.isPending ? <InlineMessage title="Memeriksa pembayaran" message="Tujuan pembayaran sedang diperiksa." /> : null}
    {program.pricing_mode === 'paid' && paymentReadiness.data === false ? <InlineMessage title="Tujuan pembayaran belum siap" message="Program berbayar baru dapat diterbitkan setelah rekening bank atau QRIS tujuan pembayaran dikonfigurasi oleh Admin." tone="warning" /> : null}
    {paymentReadiness.isError ? <InlineMessage title="Pemeriksaan pembayaran gagal" message="Tujuan pembayaran belum dapat diperiksa. Muat ulang lalu coba lagi." tone="destructive" /> : null}
    <Button label="Terbitkan program" disabled={issues.length > 0 || paymentBlocked || paymentChecking} loading={mutation.isPending} onPress={() => void publish()} testID="admin.editor.publish" />
    {mutation.error instanceof Error ? <InlineMessage title="Program belum diterbitkan" message={mutation.error.message} tone="destructive" /> : null}
    {issues.length > 0 ? <Text style={[editorStyles.caption, { color: colors.secondaryText, textAlign: 'center' }]}>Lengkapi bagian yang ditandai sebelum menerbitkan program.</Text> : null}
  </ProgramEditorScaffold>;
}

function ProgramPreview({ program }: { program: AdminProgram }) {
  const { colors } = useAppTheme(); const [role, setRole] = useState<'participant' | 'coach'>('participant'); const preview = toPublicProgram(program);
  return <ProgramEditorScaffold title="Pratinjau program" onBack={() => router.back()} testID="admin.program.preview">
    <SegmentedControl label="Peran pratinjau" value={role} onChange={setRole} options={[{ label: 'Peserta', value: 'participant' }, { label: 'Coach', value: 'coach' }]} />
    <InlineMessage title={`Tampilan ini sama dengan yang dilihat ${role === 'participant' ? 'Peserta' : 'Coach'}.`} message={role === 'participant' ? 'Pratinjau memakai renderer program Peserta tanpa mengaktifkan mutasi.' : 'Coach melihat definisi dan urutan aktivitas yang sama dalam mode pemantauan.'} />
    <View style={editorStyles.stack}><ProgramOffer program={preview} onPrimaryAction={() => undefined} /><ProgramDefinitionPreview program={preview} role={role} /></View>
    <Text style={[editorStyles.caption, { color: colors.secondaryText }]}>Pratinjau bersifat hanya baca.</Text>
  </ProgramEditorScaffold>;
}

function ProgramPublication({ program }: { program: AdminProgram }) {
  const mutation = useAdminMutation(); const closure = useAdminClosure(program.id); const winners = useAdminWinnerPreview(program.id); const [reason, setReason] = useState('Program selesai dan hasil akhir siap dikunci.');
  if (closure.isPending || winners.isPending) return <StateView kind="loading" />;
  if (closure.isError || winners.isError || !closure.data) return <StateView kind="error" action={<Button label="Coba lagi" onPress={() => void Promise.all([closure.refetch(), winners.refetch()])} />} />;
  const preflight = closure.data; const canLock = preflight.program_status === 'completed' && preflight.pending_reviews === 0 && preflight.missing_final_weigh_ins === 0 && !preflight.winners_locked;
  return <ProgramEditorScaffold title="Status publikasi" onBack={() => router.back()} testID="admin.program.publication-status">
    <FormSection title="Status"><LabeledValueRow label="Publikasi" value={adminStatusLabel(program.status)} /><GroupDivider /><LabeledValueRow label="Pembaruan terakhir" value={formatDateTime(program.updated_at)} /></FormSection>
    <InlineMessage title="Program ini tidak dapat diubah langsung" message="Buat salinan draft dari hub program untuk menyiapkan versi baru." tone="warning" />
    <FormSection title="Penutupan program"><LabeledValueRow label="Peserta" value={numberFormatter.format(preflight.enrollment_count)} /><GroupDivider /><LabeledValueRow label="Pemeriksaan tertunda" value={numberFormatter.format(preflight.pending_reviews)} /><GroupDivider /><LabeledValueRow label="Timbang akhir belum lengkap" value={numberFormatter.format(preflight.missing_final_weigh_ins)} /><GroupDivider /><LabeledValueRow label="Kuis tidak lulus" value={numberFormatter.format(preflight.failed_quizzes)} /></FormSection>
    {program.status !== 'completed' && program.status !== 'archived' ? <FormSection title="Tutup perhitungan"><FormTextInput label="Alasan penutupan" value={reason} multiline onChangeText={setReason} /><Button label="Tutup perhitungan" disabled={reason.trim().length < 8 || preflight.pending_reviews > 0 || preflight.missing_final_weigh_ins > 0} loading={mutation.isPending} onPress={() => void mutation.mutateAsync({ kind: 'completeProgram', programId: program.id, reason })} /></FormSection> : null}
    {preflight.winners_locked ? <InlineMessage title="Snapshot pemenang sudah dikunci" message="Hasil stabil dan tidak berubah ketika skor diedit kemudian." tone="success" /> : <Button label="Tutup perhitungan dan kunci pemenang" icon="trophy" disabled={!canLock} loading={mutation.isPending} onPress={() => void mutation.mutateAsync({ kind: 'lockWinners', programId: program.id })} />}
  </ProgramEditorScaffold>;
}

function WebDateRow({ label, value, min, disabled, onChange }: { label: string; value: string; min?: string; disabled: boolean; onChange: (value: string) => void }) {
  const { colors } = useAppTheme();
  if (Platform.OS !== 'web') return <FormTextInput label={label} value={value} editable={!disabled} onChangeText={onChange} />;
  return <View style={styles.controlRow}><Text style={[editorStyles.body, { color: colors.primaryText }]}>{label}</Text><label style={webPickerShellStyle(colors.secondaryBackground, colors.primaryText, colors.border)}><span>{formatDate(value)} ▾</span><input aria-label={label} type="date" value={value} min={min} disabled={disabled} onClick={(event) => openWebNativePicker(event.currentTarget)} onChange={(event) => onChange(event.currentTarget.value)} style={webInvisiblePickerStyle} /></label></View>;
}

function WebDateTimeRow({ label, value, timeZone, disabled, onChange }: { label: string; value: string; timeZone: string; disabled: boolean; onChange: (value: string) => void }) {
  const { colors } = useAppTheme(); const localValue = value.slice(0, 16);
  if (Platform.OS !== 'web') return <FormTextInput label={label} value={value} editable={!disabled} onChangeText={onChange} />;
  return <View style={styles.controlRow}><Text style={[editorStyles.body, { color: colors.primaryText }]}>{label}</Text><label style={webPickerShellStyle(colors.secondaryBackground, colors.primaryText, colors.border)}><span>{formatLocalDateTime(localValue)} ▾</span><input aria-label={label} type="datetime-local" value={localValue} disabled={disabled} onClick={(event) => openWebNativePicker(event.currentTarget)} onChange={(event) => onChange(`${event.currentTarget.value}:00${timeZoneOffset(timeZone)}`)} style={webInvisiblePickerStyle} /></label></View>;
}

function WebSelectRow({ label, value, options, disabled, onChange }: { label: string; value: string; options: readonly { label: string; value: string }[]; disabled: boolean; onChange: (value: string) => void }) {
  const { colors } = useAppTheme();
  if (Platform.OS !== 'web') return <FormTextInput label={label} value={options.find((option) => option.value === value)?.label ?? value} editable={false} />;
  return <View style={styles.controlRow}><Text style={[editorStyles.body, { color: colors.primaryText }]}>{label}</Text><select aria-label={label} value={value} disabled={disabled} onChange={(event) => onChange(event.currentTarget.value)} style={webSelectStyle(colors.surface, colors.primaryAction)}>{options.map((option) => <option key={option.value} value={option.value}>{option.label}</option>)}</select></View>;
}

function DurationStepper({ days, disabled, onDecrease, onIncrease }: { days: number; disabled: boolean; onDecrease: () => void; onIncrease: () => void }) {
  const { colors } = useAppTheme();
  return <View style={styles.controlRow}><Text style={[editorStyles.body, { color: colors.primaryText }]}>Durasi: {numberFormatter.format(days)} hari</Text><View style={[styles.stepper, { backgroundColor: colors.secondaryBackground }]}><Pressable accessibilityRole="button" accessibilityLabel="Kurangi durasi" accessibilityState={{ disabled: disabled || days <= 1 }} disabled={disabled || days <= 1} onPress={onDecrease} style={({ pressed }) => [styles.stepperButton, { opacity: disabled || days <= 1 ? 0.35 : pressed ? 0.55 : 1 }]}><Text style={[styles.stepperSymbol, { color: colors.primaryText }]}>−</Text></Pressable><View style={[styles.stepperDivider, { backgroundColor: colors.border }]} /><Pressable accessibilityRole="button" accessibilityLabel="Tambah durasi" accessibilityState={{ disabled: disabled || days >= 365 }} disabled={disabled || days >= 365} onPress={onIncrease} style={({ pressed }) => [styles.stepperButton, { opacity: disabled || days >= 365 ? 0.35 : pressed ? 0.55 : 1 }]}><Text style={[styles.stepperSymbol, { color: colors.primaryText }]}>+</Text></Pressable></View></View>;
}

function PercentageStepper({ value, disabled, onChange }: { value: number; disabled: boolean; onChange: (value: number) => void }) {
  const { colors } = useAppTheme();
  return <View style={styles.controlRow}><Text style={[editorStyles.body, { color: colors.primaryText }]}>Nilai lulus kuis: {numberFormatter.format(value)}%</Text><View style={[styles.stepper, { backgroundColor: colors.secondaryBackground }]}><Pressable accessibilityRole="button" accessibilityLabel="Kurangi nilai lulus kuis" accessibilityState={{ disabled: disabled || value <= 0 }} disabled={disabled || value <= 0} onPress={() => onChange(Math.max(0, value - 1))} style={({ pressed }) => [styles.stepperButton, { opacity: disabled || value <= 0 ? 0.35 : pressed ? 0.55 : 1 }]}><Text style={[styles.stepperSymbol, { color: colors.primaryText }]}>−</Text></Pressable><View style={[styles.stepperDivider, { backgroundColor: colors.border }]} /><Pressable accessibilityRole="button" accessibilityLabel="Tambah nilai lulus kuis" accessibilityState={{ disabled: disabled || value >= 100 }} disabled={disabled || value >= 100} onPress={() => onChange(Math.min(100, value + 1))} style={({ pressed }) => [styles.stepperButton, { opacity: disabled || value >= 100 ? 0.35 : pressed ? 0.55 : 1 }]}><Text style={[styles.stepperSymbol, { color: colors.primaryText }]}>+</Text></Pressable></View></View>;
}

function programHref(id: string, section: AdminProgramSection, extra: Record<string, string> = {}) { const search = new URLSearchParams({ section, ...extra }); return `/admin/programs/${id}?${search.toString()}`; }
function isSection(value?: string): value is AdminProgramSection { return ['overview', 'settings', 'info', 'schedule', 'rules', 'content', 'day', 'step', 'questions', 'question', 'review', 'preview', 'publication'].includes(value ?? ''); }
function isContentSection(value: AdminProgramSection): value is 'content' | 'day' | 'step' | 'questions' | 'question' { return ['content', 'day', 'step', 'questions', 'question'].includes(value); }
function contentSummary(program: AdminProgram) { return `${program.days.length} hari · ${program.days.flatMap((day) => day.steps).length} langkah · ${program.days.flatMap((day) => day.steps).flatMap((step) => step.questions).length} pertanyaan`; }
function stageStatus(program: AdminProgram, stage: AdminProgramStage) { const count = validateAdminProgram(program).filter((issue) => issue.stage === stage).length; return count === 0 ? (stage === 'review' ? 'Siap diterbitkan' : 'Selesai') : `${count} hal perlu dilengkapi`; }
function publicationSummary(status: AdminProgramStatus) { return ({ draft: 'Belum diterbitkan', scheduled: 'Terjadwal dan tidak dapat diubah langsung', active: 'Sedang berjalan dan tidak dapat diubah langsung', completed: 'Program telah selesai', archived: 'Program tersimpan di arsip' })[status]; }
function durationDays(program: AdminProgram) { const start = new Date(`${program.starts_on}T12:00:00Z`); const end = new Date(`${program.ends_on}T12:00:00Z`); return Math.max(1, Math.round((end.getTime() - start.getTime()) / 86_400_000) + 1); }
function addDays(value: string, offset: number) { const date = new Date(`${value}T12:00:00Z`); date.setUTCDate(date.getUTCDate() + offset); return date.toISOString().slice(0, 10); }
function paceLabel(pace: AdminProgram['pace']) { return pace === 'scheduled' ? 'Terjadwal' : 'Mandiri'; }
function toPublicProgram(program: AdminProgram): PublicProgram { return { ...program, status: program.status === 'draft' ? 'scheduled' : program.status, program_days: program.days.map((day) => ({ ...day, program_steps: day.steps.map((step) => ({ ...step, program_questions: step.questions.map((question) => ({ ...question, program_question_options: question.options })) })) })) } as PublicProgram; }
function formatDate(value: string) { return dateFormatter.format(new Date(`${value}T12:00:00Z`)); }
function formatDateTime(value: string) { return new Intl.DateTimeFormat('id-ID', { dateStyle: 'medium', timeStyle: 'short', timeZone: 'Asia/Makassar' }).format(new Date(value)); }
const hiddenFileInput = { position: 'absolute', width: 1, height: 1, overflow: 'hidden', clip: 'rect(0, 0, 0, 0)', whiteSpace: 'nowrap' } as const;
function fileRowStyle(color: string) { return { display: 'flex', alignItems: 'center', minHeight: 58, padding: '0 16px', color, fontSize: 16, fontWeight: 600 } as const; }
function webPickerShellStyle(backgroundColor: string, color: string, borderColor: string) { return { position: 'relative', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', minHeight: 42, border: `1px solid ${borderColor}`, borderRadius: 999, backgroundColor, color, padding: '6px 12px', font: 'inherit', fontWeight: 600, overflow: 'hidden', cursor: 'pointer' } as const; }
const webInvisiblePickerStyle = { position: 'absolute', inset: 0, width: '100%', height: '100%', opacity: 0, cursor: 'pointer' } as const;
function webSelectStyle(backgroundColor: string, color: string) { return { minHeight: 44, maxWidth: '58%', border: 0, outline: 0, backgroundColor, color, font: 'inherit', fontWeight: 600, textAlign: 'right', cursor: 'pointer' } as const; }
function timeZoneOffset(timeZone: string) { return timeZone === 'Asia/Jakarta' ? '+07:00' : timeZone === 'Asia/Jayapura' ? '+09:00' : '+08:00'; }
function formatLocalDateTime(value: string) { if (!value) return 'Pilih tanggal dan waktu'; return new Intl.DateTimeFormat('id-ID', { dateStyle: 'medium', timeStyle: 'short', timeZone: 'UTC' }).format(new Date(`${value}:00Z`)); }

const timeZoneOptions = [
  { label: 'WITA · Makassar', value: 'Asia/Makassar' },
  { label: 'WIB · Jakarta', value: 'Asia/Jakarta' },
  { label: 'WIT · Jayapura', value: 'Asia/Jayapura' },
] as const;
const verificationModeOptions = [
  { label: 'Otomatis', value: 'automatic' },
  { label: 'Pemeriksaan Coach', value: 'coach_review' },
] as const;
const pastPolicyOptions = [
  { label: 'Tetap tersedia', value: 'available' },
  { label: 'Hanya baca', value: 'read_only' },
  { label: 'Disembunyikan', value: 'hidden' },
] as const;
const futurePolicyOptions = [
  { label: 'Tersedia lebih awal', value: 'available' },
  { label: 'Terkunci', value: 'locked' },
  { label: 'Disembunyikan', value: 'hidden' },
] as const;

const styles = StyleSheet.create({
  hero: { borderWidth: StyleSheet.hairlineWidth, borderRadius: primitiveTokens.radius.large, padding: primitiveTokens.space.medium, gap: primitiveTokens.space.medium },
  stageCard: { minHeight: 132, borderWidth: StyleSheet.hairlineWidth, borderRadius: primitiveTokens.radius.large, padding: primitiveTokens.space.medium, flexDirection: 'row', alignItems: 'flex-start', gap: primitiveTokens.space.small },
  stageNumber: { width: 44, height: 44, borderRadius: 22, alignItems: 'center', justifyContent: 'center' },
  sectionHeading: { ...editorStyles.headline, paddingHorizontal: primitiveTokens.space.small },
  coverImage: { width: '100%', aspectRatio: 16 / 9, resizeMode: 'cover' },
  coverPlaceholder: { width: '100%', aspectRatio: 16 / 9, alignItems: 'center', justifyContent: 'center' },
  coverGradientWeb: { backgroundImage: 'linear-gradient(135deg, #271010 0%, #D71920 100%)' } as never,
  segmentInset: { padding: primitiveTokens.space.small },
  controlRow: { minHeight: 62, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: primitiveTokens.space.medium, paddingHorizontal: primitiveTokens.space.medium },
  stepper: { height: 44, flexDirection: 'row', alignItems: 'center', borderRadius: primitiveTokens.radius.capsule, overflow: 'hidden' },
  stepperButton: { width: 52, height: 44, alignItems: 'center', justifyContent: 'center' },
  stepperDivider: { width: StyleSheet.hairlineWidth, height: 30 },
  stepperSymbol: { fontSize: 28, lineHeight: 32, fontWeight: '500' },
  statusPill: { minHeight: 34, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.xxSmall, borderRadius: primitiveTokens.radius.capsule, paddingHorizontal: primitiveTokens.space.small },
  progressTrack: { height: 6, overflow: 'hidden', borderRadius: primitiveTokens.radius.capsule },
  progressFill: { height: '100%', borderRadius: primitiveTokens.radius.capsule },
});
