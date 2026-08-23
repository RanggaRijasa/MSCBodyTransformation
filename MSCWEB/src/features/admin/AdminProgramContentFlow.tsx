import { router } from 'expo-router';
import { useMemo, useState } from 'react';
import { Image, Platform, Pressable, StyleSheet, Text, TextInput, View } from 'react-native';

import { dateFormatter, numberFormatter } from '@/shared/design/formatters';
import { primitiveTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { MSCIcon } from '@/shared/icons/MSCIcon';
import { Button, Dialog, InlineMessage, StateView } from '@/shared/ui/primitives';
import { editorStyles, FormSection, FormTextInput, GroupDivider, LabeledValueRow, NavigationRow, ProgramEditorScaffold, StatusLine, TopTextAction } from './AdminProgramEditorShared';
import type { AdminDay, AdminProgram, AdminQuestion, AdminStep } from './admin-models';
import { defaultQuestionPromptMediaAltText } from './admin-question-media';
import { useAdminMutation } from './admin-queries';
import { getAdminRepository } from './admin-repository';

type ContentSection = 'content' | 'day' | 'step' | 'questions' | 'question';

export function AdminProgramContentFlow({ program, section, dayId, stepId, questionId }: { program: AdminProgram; section: ContentSection; dayId?: string; stepId?: string; questionId?: string }) {
  if (section === 'day' && dayId) return <ProgramDayEditor initial={program} dayId={dayId} />;
  if (section === 'step' && dayId && stepId) return <ProgramStepEditor initial={program} dayId={dayId} stepId={stepId} />;
  if (section === 'questions' && dayId && stepId) return <ProgramQuestions initial={program} dayId={dayId} stepId={stepId} />;
  if (section === 'question' && dayId && stepId && questionId) return <ProgramQuestionEditor initial={program} dayId={dayId} stepId={stepId} questionId={questionId} />;
  return <ProgramContentHub initial={program} />;
}

function ProgramContentHub({ initial }: { initial: AdminProgram }) {
  const { colors } = useAppTheme(); const mutation = useAdminMutation(); const [program, setProgram] = useState(initial); const [syncWarning, setSyncWarning] = useState(false); const [editing, setEditing] = useState(false); const editable = program.status === 'draft';
  const expectedDates = useMemo(() => datesBetween(program.starts_on, program.ends_on), [program.ends_on, program.starts_on]);
  const synchronized = expectedDates.length === program.days.length && expectedDates.every((date, index) => program.days[index]?.scheduled_on === date);
  const persist = (next: AdminProgram) => { setProgram(next); void mutation.mutateAsync({ kind: 'saveProgram', program: next }); };
  const sync = () => {
    const days = expectedDates.map((date, index) => program.days[index] ? { ...program.days[index]!, day_number: index + 1, scheduled_on: date } : makeDay(index + 1, date));
    persist({ ...program, days }); setSyncWarning(false);
  };
  const requestSync = () => {
    const removed = program.days.slice(expectedDates.length).some((day) => day.steps.length > 0 || Boolean(day.summary?.trim()));
    if (removed) setSyncWarning(true); else sync();
  };
  const addDay = () => { const nextNumber = program.days.length + 1; const date = addDays(program.days.at(-1)?.scheduled_on ?? program.starts_on, 1); persist({ ...program, ends_on: date, days: [...program.days, makeDay(nextNumber, date)] }); };
  const moveDay = (index: number, offset: number) => { const target = index + offset; if (target < 0 || target >= program.days.length) return; const days = [...program.days]; const [day] = days.splice(index, 1); if (!day) return; days.splice(target, 0, day); persist({ ...program, days: days.map((value, dayIndex) => ({ ...value, day_number: dayIndex + 1 })) }); };
  const removeDay = (id: string) => { const days = program.days.filter((day) => day.id !== id).map((day, index) => ({ ...day, day_number: index + 1 })); persist({ ...program, days, ends_on: days.at(-1)?.scheduled_on ?? program.starts_on }); };
  return <ProgramEditorScaffold title="Konten" onBack={() => router.back()} action={editable ? <TopTextAction label={editing ? 'Selesai' : 'Edit'} disabled={mutation.isPending} onPress={() => setEditing((value) => !value)} /> : undefined} testID="admin.program.content">
    {!editable ? <InlineMessage title="Konten terkunci" message="Program yang diterbitkan hanya dapat dibaca." tone="warning" /> : null}
    <FormSection title="Jadwal" footer="Sinkronisasi mempertahankan isi hari yang masih berada dalam rentang jadwal.">
      <LabeledValueRow label="Rentang jadwal" value={`${formatDate(program.starts_on)}\n${formatDate(program.ends_on)}`} icon="program" />
      <GroupDivider /><View style={styles.paddedStatus}><StatusLine label={synchronized ? 'Hari sudah sesuai dengan jadwal.' : 'Perubahan jadwal belum diterapkan ke hari.'} tone={synchronized ? 'success' : 'warning'} /></View>
      <GroupDivider /><NavigationRow title="Sinkronkan hari dengan jadwal" icon="history" onPress={requestSync} />
    </FormSection>
    <FormSection title="Hari program">
      {program.days.length === 0 ? <EmptyBlock title="Belum ada hari" message="Sinkronkan jadwal atau tambahkan hari baru." icon="program" /> : program.days.map((day, index) => <View key={day.id}><NavigationRow title={`Hari ke-${day.day_number} · ${day.title}`} subtitle={`${numberFormatter.format(day.steps.length)} langkah · ${numberFormatter.format(questionCount(day))} pertanyaan`} icon="program" onPress={() => router.push(href(program.id, 'day', { dayId: day.id }) as never)} testID={`admin.program.day.open.${day.id}`} />{editing ? <View style={styles.editControls}><SmallEditorAction label="Naik" disabled={index === 0} onPress={() => moveDay(index, -1)} /><SmallEditorAction label="Turun" disabled={index === program.days.length - 1} onPress={() => moveDay(index, 1)} /><SmallEditorAction label="Hapus" destructive onPress={() => removeDay(day.id)} /></View> : null}{index < program.days.length - 1 ? <GroupDivider /> : null}</View>)}
    </FormSection>
    {editable ? <FormSection footer="Menambah hari juga memperpanjang tanggal selesai program satu hari."><NavigationRow title="Tambah hari" icon="plus" onPress={addDay} testID="admin.program.day.add" /></FormSection> : null}
    <Dialog visible={syncWarning} title="Sinkronkan dan pangkas hari?" onClose={() => setSyncWarning(false)}><Text style={[editorStyles.body, { color: colors.secondaryText }]}>Hari di luar jadwal beserta langkah dan pertanyaannya akan dihapus dari draft.</Text><Button label="Batal" tone="secondary" onPress={() => setSyncWarning(false)} /><Button label="Sinkronkan" tone="destructive" onPress={sync} /></Dialog>
  </ProgramEditorScaffold>;
}

function ProgramDayEditor({ initial, dayId }: { initial: AdminProgram; dayId: string }) {
  const { colors } = useAppTheme(); const mutation = useAdminMutation(); const [program, setProgram] = useState(initial); const [addOpen, setAddOpen] = useState(false); const [copyOpen, setCopyOpen] = useState(false); const [deleteOpen, setDeleteOpen] = useState(false); const day = program.days.find((candidate) => candidate.id === dayId); const editable = program.status === 'draft';
  if (!day) return <StateView kind="error" />;
  const patchDay = (values: Partial<AdminDay>) => setProgram((current) => updateDay(current, dayId, (value) => ({ ...value, ...values })));
  const save = () => void mutation.mutateAsync({ kind: 'saveProgram', program }).then(() => router.back());
  const addStep = (kind: AdminStep['content_kind']) => {
    const step = makeStep(kind, day.steps.length + 1, program.default_verification_mode); const next = updateDay(program, dayId, (value) => ({ ...value, steps: [...value.steps, step] })); setProgram(next); setAddOpen(false);
    void mutation.mutateAsync({ kind: 'saveProgram', program: next }).then(() => router.push(href(program.id, 'step', { dayId, stepId: step.id }) as never));
  };
  const removeDay = () => { const days = program.days.filter((candidate) => candidate.id !== dayId).map((candidate, index) => ({ ...candidate, day_number: index + 1 })); const next = { ...program, days, ends_on: days.at(-1)?.scheduled_on ?? program.starts_on }; void mutation.mutateAsync({ kind: 'saveProgram', program: next }).then(() => router.back()); };
  return <ProgramEditorScaffold title={`Hari ke-${day.day_number}`} onBack={() => router.back()} action={editable ? <TopTextAction label={mutation.isPending ? 'Menyimpan…' : 'Simpan'} disabled={mutation.isPending} onPress={save} /> : undefined} testID="admin.program.day.editor">
    <FormSection title="Hari program"><FormTextInput label="Nama hari" value={day.title} editable={editable} onChangeText={(title) => patchDay({ title })} /><GroupDivider /><FormTextInput label="Deskripsi" value={day.summary ?? ''} editable={editable} multiline style={styles.dayDescription} onChangeText={(summary) => patchDay({ summary })} /><GroupDivider /><LabeledValueRow label="Tanggal" value={formatLongDate(day.scheduled_on)} icon="program" /></FormSection>
    <FormSection title="Salin isi" footer={program.days.length < 2 ? 'Tambahkan hari lain untuk menggunakan kembali isi hari ini.' : 'Deskripsi dan seluruh langkah dapat disalin ke beberapa hari tujuan.'}><NavigationRow title="Salin isi ke hari lain" icon="copy" onPress={() => setCopyOpen(true)} testID="admin.program.day.copy-content" /></FormSection>
    <FormSection title="Langkah">
      {day.steps.length === 0 ? <EmptyBlock title="Belum ada langkah" message="Tambahkan artikel, video, form, kuis, atau timbang." icon="clipboard" /> : day.steps.map((step, index) => <View key={step.id}><NavigationRow title={`${step.step_order}. ${step.title}`} subtitle={`${stepKindLabel(step.content_kind)} · ${numberFormatter.format(step.questions.length)} pertanyaan`} icon={stepIcon(step.content_kind)} onPress={() => router.push(href(program.id, 'step', { dayId, stepId: step.id }) as never)} />{index < day.steps.length - 1 ? <GroupDivider /> : null}</View>)}
      {editable ? <><GroupDivider /><NavigationRow title="Tambah langkah" icon="plus" onPress={() => setAddOpen(true)} testID={`admin.editor.add-step.${day.id}`} /></> : null}
    </FormSection>
    {editable ? <Button label="Hapus hari" icon="archive" tone="destructive" onPress={() => setDeleteOpen(true)} /> : null}
    <Dialog visible={addOpen} title="Pilih jenis langkah" onClose={() => setAddOpen(false)}><Text style={[editorStyles.body, { color: colors.secondaryText }]}>Langkah ditambahkan ke hari program ini.</Text>{stepKinds.map((kind) => <Button key={kind.value} label={kind.label} tone="secondary" onPress={() => addStep(kind.value)} />)}</Dialog>
    <CopyDayDialog program={program} source={day} visible={copyOpen} onClose={() => setCopyOpen(false)} onSave={setProgram} />
    <Dialog visible={deleteOpen} title="Hapus hari ini?" onClose={() => setDeleteOpen(false)}><Text style={[editorStyles.body, { color: colors.secondaryText }]}>Seluruh langkah dan pertanyaan pada hari ini ikut dihapus.</Text><Button label="Batal" tone="secondary" onPress={() => setDeleteOpen(false)} /><Button label="Hapus hari" tone="destructive" loading={mutation.isPending} onPress={removeDay} /></Dialog>
  </ProgramEditorScaffold>;
}

function ProgramStepEditor({ initial, dayId, stepId }: { initial: AdminProgram; dayId: string; stepId: string }) {
  const { colors } = useAppTheme(); const mutation = useAdminMutation(); const [program, setProgram] = useState(initial); const [deleteOpen, setDeleteOpen] = useState(false); const day = program.days.find((candidate) => candidate.id === dayId); const step = day?.steps.find((candidate) => candidate.id === stepId); const editable = program.status === 'draft';
  if (!day || !step) return <StateView kind="error" />;
  const patch = (values: Partial<AdminStep>) => setProgram((current) => updateStep(current, dayId, stepId, (value) => ({ ...value, ...values })));
  const save = () => void mutation.mutateAsync({ kind: 'saveProgram', program }).then(() => router.back());
  const remove = () => { const next = updateDay(program, dayId, (value) => ({ ...value, steps: value.steps.filter((candidate) => candidate.id !== stepId).map((candidate, index) => ({ ...candidate, step_order: index + 1 })) })); void mutation.mutateAsync({ kind: 'saveProgram', program: next }).then(() => router.back()); };
  return <ProgramEditorScaffold title={step.title || 'Langkah'} onBack={() => router.back()} action={editable ? <TopTextAction label={mutation.isPending ? 'Menyimpan…' : 'Simpan'} disabled={mutation.isPending} onPress={save} /> : undefined} testID="admin.step.editor">
    <FormSection title="Informasi langkah"><FormTextInput label="Nama langkah" value={step.title} editable={editable} onChangeText={(title) => patch({ title })} /><GroupDivider /><LabeledValueRow label="Tanggal" value={formatLongDate(day.scheduled_on)} icon="program" /><GroupDivider /><View style={styles.pickerGrid}>{stepKinds.map((kind) => <ChoiceChip key={kind.value} label={kind.label} selected={step.content_kind === kind.value} onPress={() => editable && patch(normalizeKind(step, kind.value))} />)}</View></FormSection>
    <FormSection title={stepKindLabel(step.content_kind)} footer={stepHelp(step.content_kind)}><FormTextInput label={instructionLabel(step.content_kind)} value={step.instructions ?? ''} editable={editable} multiline onChangeText={(instructions) => patch({ instructions })} />{step.content_kind === 'video' ? <><GroupDivider /><FormTextInput label="Referensi video" value={step.media_path ?? ''} editable={editable} onChangeText={(media_path) => patch({ media_path })} /><GroupDivider /><ToggleChoice label="Wajib ditonton sampai selesai" value={step.video_required} onChange={(video_required) => patch({ video_required })} /><GroupDivider /><ToggleChoice label="Putar otomatis" value={step.video_autoplay} onChange={(video_autoplay) => patch({ video_autoplay })} /></> : null}</FormSection>
    {['form', 'quiz'].includes(step.content_kind) ? <FormSection title="Pertanyaan peserta" footer={step.content_kind === 'quiz' ? 'Kuis memerlukan pertanyaan objektif dan jawaban benar.' : 'Semua pertanyaan interaktif wajib dijawab.'}><NavigationRow title="Pertanyaan" subtitle={`${numberFormatter.format(step.questions.length)} pertanyaan`} icon="info" onPress={() => router.push(href(program.id, 'questions', { dayId, stepId }) as never)} testID="admin.step.questions.open" /></FormSection> : null}
    <FormSection title="Penyelesaian"><ToggleChoice label="Langkah aktif" value={true} onChange={() => undefined} /><GroupDivider /><LabeledValueRow label="Mode pemeriksaan" value={step.verification_mode === 'automatic' ? 'Otomatis' : 'Pemeriksaan Coach'} /></FormSection>
    {editable ? <Button label="Hapus langkah" tone="destructive" onPress={() => setDeleteOpen(true)} /> : null}
    <Dialog visible={deleteOpen} title="Hapus langkah ini?" onClose={() => setDeleteOpen(false)}><Text style={[editorStyles.body, { color: colors.secondaryText }]}>Semua pertanyaan di dalam langkah ini juga akan dihapus.</Text><Button label="Batal" tone="secondary" onPress={() => setDeleteOpen(false)} /><Button label="Hapus langkah" tone="destructive" loading={mutation.isPending} onPress={remove} /></Dialog>
  </ProgramEditorScaffold>;
}

function ProgramQuestions({ initial, dayId, stepId }: { initial: AdminProgram; dayId: string; stepId: string }) {
  const { colors } = useAppTheme(); const mutation = useAdminMutation(); const [program, setProgram] = useState(initial); const [addOpen, setAddOpen] = useState(false); const step = findStep(program, dayId, stepId); const editable = program.status === 'draft';
  if (!step) return <StateView kind="error" />;
  const save = () => void mutation.mutateAsync({ kind: 'saveProgram', program }).then(() => router.back());
  const addQuestion = (kind: string) => { const question = makeQuestion(kind, step.questions.length + 1, step.content_kind === 'quiz'); const next = updateStep(program, dayId, stepId, (value) => ({ ...value, questions: [...value.questions, question] })); setProgram(next); setAddOpen(false); void mutation.mutateAsync({ kind: 'saveProgram', program: next }).then(() => router.push(href(program.id, 'question', { dayId, stepId, questionId: question.id }) as never)); };
  return <ProgramEditorScaffold title="Pertanyaan" onBack={() => router.back()} action={editable ? <TopTextAction label={mutation.isPending ? 'Menyimpan…' : 'Simpan'} disabled={mutation.isPending} onPress={save} /> : undefined} testID="admin.step.questions">
    <FormSection>{step.questions.length === 0 ? <EmptyBlock title="Belum ada pertanyaan" message="Tambahkan pertanyaan atau teks penjelas." icon="info" /> : step.questions.map((question, index) => <View key={question.id}><NavigationRow title={question.prompt || `Pertanyaan ${question.question_order}`} subtitle={questionKindLabel(question.kind)} icon="info" onPress={() => router.push(href(program.id, 'question', { dayId, stepId, questionId: question.id }) as never)} />{index < step.questions.length - 1 ? <GroupDivider /> : null}</View>)}</FormSection>
    {editable ? <FormSection><NavigationRow title="Tambah pertanyaan" icon="plus" onPress={() => setAddOpen(true)} /></FormSection> : null}
    <Dialog visible={addOpen} title="Pilih jenis pertanyaan" onClose={() => setAddOpen(false)}><Text style={[editorStyles.body, { color: colors.secondaryText }]}>Pertanyaan ditambahkan ke langkah ini.</Text>{questionKinds.map((kind) => <Button key={kind.value} label={kind.label} tone="secondary" onPress={() => addQuestion(kind.value)} />)}</Dialog>
  </ProgramEditorScaffold>;
}

function ProgramQuestionEditor({ initial, dayId, stepId, questionId }: { initial: AdminProgram; dayId: string; stepId: string; questionId: string }) {
  const { colors } = useAppTheme(); const mutation = useAdminMutation(); const [program, setProgram] = useState(initial); const step = findStep(program, dayId, stepId); const question = step?.questions.find((candidate) => candidate.id === questionId); const editable = program.status === 'draft';
  if (!step || !question) return <StateView kind="error" />;
  const patch = (values: Partial<AdminQuestion>) => setProgram((current) => updateQuestion(current, dayId, stepId, questionId, (value) => ({ ...value, ...values })));
  const save = async () => {
    try {
      await mutation.mutateAsync({ kind: 'saveProgram', program });
      router.back();
    } catch {
      // Mutation state renders the actionable error below.
    }
  };
  const remove = () => { const next = updateStep(program, dayId, stepId, (value) => ({ ...value, questions: value.questions.filter((candidate) => candidate.id !== questionId).map((candidate, index) => ({ ...candidate, question_order: index + 1 })) })); void mutation.mutateAsync({ kind: 'saveProgram', program: next }).then(() => router.back()); };
  const choice = ['single_choice', 'multiple_choice', 'image_choice'].includes(question.kind); const selected = question.answer_key?.selected_option_ids ?? [];
  const patchOption = (id: string, title: string) => patch({ options: question.options.map((option) => option.id === id ? { ...option, title } : option) });
  return <ProgramEditorScaffold title={`Pertanyaan ${question.question_order}`} onBack={() => router.back()} action={editable ? <TopTextAction label={mutation.isPending ? 'Menyimpan…' : 'Simpan'} disabled={mutation.isPending} onPress={save} /> : undefined} testID="admin.question.editor">
    <FormSection title="Pertanyaan"><View style={styles.pickerGrid}>{questionKinds.map((kind) => <ChoiceChip key={kind.value} label={kind.label} selected={question.kind === kind.value} onPress={() => editable && patch(normalizeQuestionKind(question, kind.value, step.content_kind === 'quiz'))} />)}</View><GroupDivider /><FormTextInput label={['heading', 'text'].includes(question.kind) ? 'Isi elemen' : 'Isi pertanyaan'} value={question.prompt} editable={editable} multiline onChangeText={(prompt) => patch({ prompt })} />{!['heading', 'text'].includes(question.kind) ? <><GroupDivider /><StatusLine label="Wajib dijawab" /></> : null}</FormSection>
    <QuestionPromptMediaEditor question={question} editable={editable} onChange={patch} />
    {mutation.error instanceof Error ? <InlineMessage title="Belum dapat disimpan" message={mutation.error.message} tone="destructive" /> : null}
    {choice ? <FormSection title="Pilihan jawaban">{question.options.map((option, index) => <View key={option.id} style={styles.optionBlock}><View style={styles.optionRow}><TextInput accessibilityLabel={`Pilihan ${index + 1}`} value={option.title} editable={editable} onChangeText={(title) => patchOption(option.id, title)} style={[styles.optionInput, { color: colors.primaryText, borderColor: colors.border }]} />{step.content_kind === 'quiz' ? <ChoiceChip label={selected.includes(option.id) ? 'Benar' : 'Pilih'} selected={selected.includes(option.id)} onPress={() => patch({ answer_key: { question_id: question.id, accepted_text_values: [], number_value: null, matching_mode: 'exact', selected_option_ids: question.kind === 'multiple_choice' ? selected.includes(option.id) ? selected.filter((id) => id !== option.id) : [...selected, option.id] : [option.id] } })} /> : null}</View>{question.kind === 'image_choice' ? <OptionImagePicker program={program} question={question} optionId={option.id} onProgramChange={setProgram} dayId={dayId} stepId={stepId} /> : null}</View>)}{editable ? <NavigationRow title="Tambah pilihan" icon="plus" onPress={() => patch({ options: [...question.options, { id: crypto.randomUUID(), option_order: question.options.length + 1, title: '', media_path: null, media_alt_text: null }] })} /> : null}</FormSection> : null}
    {step.content_kind === 'quiz' && question.kind === 'number' ? <FormSection title="Jawaban benar"><FormTextInput label="Nilai yang benar" value={question.answer_key?.number_value?.toString() ?? ''} editable={editable} inputMode="decimal" onChangeText={(value) => patch({ answer_key: { question_id: question.id, accepted_text_values: [], selected_option_ids: [], matching_mode: 'exact', number_value: Number(value.replace(',', '.')) || null } })} /></FormSection> : null}
    {question.kind === 'photo_upload' ? <FormSection title="Insight makanan" footer="Jika aktif, AI menganalisis foto makanan setelah jawaban berhasil dikirim. Analisis tidak mengubah poin atau status persetujuan."><ToggleChoice label="Aktifkan analisis AI makanan" value={question.analysis_mode === 'food'} disabled={!editable} onChange={(enabled) => patch({ analysis_mode: enabled ? 'food' : 'none', analysis_rubric: enabled ? 'Foto menampilkan pilihan makanan sesuai petunjuk program.' : null, analysis_rubric_version: enabled ? 'rubric_food_v1' : null })} /></FormSection> : null}
    {editable ? <Button label="Hapus pertanyaan" tone="destructive" onPress={remove} /> : null}
  </ProgramEditorScaffold>;
}

function CopyDayDialog({ program, source, visible, onClose, onSave }: { program: AdminProgram; source: AdminDay; visible: boolean; onClose: () => void; onSave: (program: AdminProgram) => void }) {
  const { colors } = useAppTheme(); const [selected, setSelected] = useState<string[]>([]);
  return <Dialog visible={visible} title="Salin isi ke hari lain" onClose={onClose}><Text style={[editorStyles.body, { color: colors.secondaryText }]}>Deskripsi dan seluruh langkah mengganti isi target. Nama, nomor, dan tanggal target tetap.</Text>{program.days.filter((day) => day.id !== source.id).map((day) => <Pressable key={day.id} accessibilityRole="checkbox" accessibilityState={{ checked: selected.includes(day.id) }} onPress={() => setSelected((current) => current.includes(day.id) ? current.filter((id) => id !== day.id) : [...current, day.id])} style={[styles.selectionRow, { borderColor: colors.border }]}><Text style={[editorStyles.body, { color: colors.primaryText }]}>{selected.includes(day.id) ? '✓ ' : ''}Hari ke-{day.day_number} · {day.steps.length ? 'Isi akan diganti' : 'Kosong'}</Text></Pressable>)}<Button label="Batal" tone="secondary" onPress={onClose} /><Button label="Salin isi" disabled={selected.length === 0} onPress={() => { onSave({ ...program, days: program.days.map((day) => selected.includes(day.id) ? { ...day, summary: source.summary, steps: source.steps.map((step, index) => cloneStep(step, index + 1)) } : day) }); setSelected([]); onClose(); }} testID="admin.program.copy-content.confirm" /></Dialog>;
}

function OptionImagePicker({ program, question, optionId, onProgramChange, dayId, stepId }: { program: AdminProgram; question: AdminQuestion; optionId: string; onProgramChange: (program: AdminProgram) => void; dayId: string; stepId: string }) {
  const option = question.options.find((candidate) => candidate.id === optionId); if (!option || Platform.OS !== 'web') return null;
  const pick = async (file?: File) => { if (!file) return; const media_path = await getAdminRepository().uploadPublicImage(file, 'programs'); onProgramChange(updateQuestion(program, dayId, stepId, question.id, (value) => ({ ...value, options: value.options.map((candidate) => candidate.id === optionId ? { ...candidate, media_path } : candidate) }))); };
  return <label style={{ display: 'block', cursor: 'pointer' }}><span style={imagePickerStyle}>{option.media_path ? 'Ganti gambar pilihan' : 'Pilih gambar'}</span><input aria-label={`Gambar ${option.title || 'pilihan'}`} type="file" accept="image/jpeg,image/png,image/webp,image/heic,image/heif" onChange={(event) => void pick(event.currentTarget.files?.[0])} style={hiddenFileInput} /></label>;
}

function QuestionPromptMediaEditor({ question, editable, onChange }: { question: AdminQuestion; editable: boolean; onChange: (values: Partial<AdminQuestion>) => void }) {
  const { colors } = useAppTheme();
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string>();
  if (Platform.OS !== 'web') return null;
  const url = getAdminRepository().questionPromptMediaUrl(question.media_path);
  const pick = async (file?: File) => {
    if (!file) return;
    setUploading(true); setError(undefined);
    try {
      const uploaded = await getAdminRepository().uploadQuestionPromptMedia(file);
      const mediaAltText = question.media_alt_text?.trim()
        || defaultQuestionPromptMediaAltText(uploaded.mediaKind, question.prompt, question.question_order);
      onChange({ media_kind: uploaded.mediaKind, media_path: uploaded.mediaPath, media_alt_text: mediaAltText });
    } catch (uploadError) {
      setError(uploadError instanceof Error ? uploadError.message : 'Media belum dapat diunggah.');
    } finally {
      setUploading(false);
    }
  };
  const picker = (kind: 'image' | 'video') => <label style={{ display: 'block', cursor: uploading ? 'wait' : 'pointer' }}><span style={promptMediaButtonStyle(colors.primaryAction, uploading)}>{question.media_kind === kind ? `Ganti ${kind === 'image' ? 'gambar' : 'video'}` : `Tambah ${kind === 'image' ? 'gambar' : 'video'}`}</span><input aria-label={`${question.media_kind === kind ? 'Ganti' : 'Tambah'} ${kind === 'image' ? 'gambar' : 'video'} pertanyaan`} type="file" accept={kind === 'image' ? 'image/jpeg,image/png,image/webp,image/heic,image/heif' : 'video/mp4,video/quicktime,video/webm'} disabled={!editable || uploading} onChange={(event) => void pick(event.currentTarget.files?.[0])} style={hiddenFileInput} /></label>;
  return <FormSection title="Media panduan (opsional)" footer="Gambar atau video tampil di bawah pertanyaan. Gunakan media tanpa data pribadi dan isi deskripsi aksesibilitas.">
    {url && question.media_kind === 'image' ? <Image accessibilityLabel={question.media_alt_text || 'Gambar panduan pertanyaan'} resizeMode="contain" source={{ uri: url }} style={[styles.promptImage, { backgroundColor: colors.secondaryBackground }]} /> : null}
    {url && question.media_kind === 'video' ? <video aria-label={question.media_alt_text || 'Video panduan pertanyaan'} controls preload="metadata" src={url} style={promptVideoStyle} /> : null}
    {editable ? <View style={styles.promptMediaActions}>{picker('image')}{picker('video')}{question.media_path ? <SmallEditorAction label="Hapus media" destructive onPress={() => onChange({ media_kind: null, media_path: null, media_alt_text: null })} /> : null}</View> : null}
    {question.media_path ? <><GroupDivider /><FormTextInput label="Deskripsi media untuk aksesibilitas" value={question.media_alt_text ?? ''} editable={editable} onChangeText={(media_alt_text) => onChange({ media_alt_text })} /></> : null}
    {error ? <InlineMessage title="Media belum dapat diunggah" message={error} tone="destructive" /> : null}
  </FormSection>;
}

function EmptyBlock({ title, message, icon }: { title: string; message: string; icon: 'program' | 'clipboard' | 'info' }) { const { colors } = useAppTheme(); return <View style={styles.emptyBlock}><MSCIcon name={icon} color={colors.secondaryText} size="large" /><Text style={[editorStyles.headline, { color: colors.primaryText }]}>{title}</Text><Text style={[editorStyles.body, { color: colors.secondaryText, textAlign: 'center' }]}>{message}</Text></View>; }
function ChoiceChip({ label, selected, onPress }: { label: string; selected: boolean; onPress: () => void }) { const { colors } = useAppTheme(); return <Pressable accessibilityRole="button" accessibilityState={{ selected }} onPress={onPress} style={({ pressed }) => [styles.choice, { borderColor: selected ? colors.primaryAction : colors.border, backgroundColor: selected ? colors.primaryTintSurface : colors.surface, opacity: pressed ? 0.65 : 1 }]}><Text style={[editorStyles.caption, { color: selected ? colors.primaryAction : colors.primaryText }]}>{label}</Text></Pressable>; }
function SmallEditorAction({ label, onPress, disabled = false, destructive = false }: { label: string; onPress: () => void; disabled?: boolean; destructive?: boolean }) { const { colors } = useAppTheme(); return <Pressable accessibilityRole="button" accessibilityLabel={label} accessibilityState={{ disabled }} disabled={disabled} onPress={onPress} style={({ pressed }) => [styles.smallAction, { borderColor: colors.border, opacity: disabled ? 0.35 : pressed ? 0.62 : 1 }]}><Text style={[editorStyles.caption, { color: destructive ? colors.destructive : colors.primaryText }]}>{label}</Text></Pressable>; }
function ToggleChoice({ label, value, disabled = false, onChange }: { label: string; value: boolean; disabled?: boolean; onChange: (value: boolean) => void }) { const { colors } = useAppTheme(); return <Pressable accessibilityRole="switch" accessibilityState={{ checked: value, disabled }} disabled={disabled} onPress={() => onChange(!value)} style={[styles.toggleChoice, disabled ? { opacity: 0.5 } : null]}><MSCIcon name={value ? 'approved' : 'info'} color={value ? colors.success : colors.secondaryText} size="small" /><Text style={[editorStyles.body, { color: colors.primaryText }]}>{label}</Text></Pressable>; }

const stepKinds: { value: AdminStep['content_kind']; label: string }[] = [{ value: 'article', label: 'Artikel' }, { value: 'video', label: 'Video' }, { value: 'form', label: 'Form' }, { value: 'quiz', label: 'Kuis' }, { value: 'initial_weigh_in', label: 'Timbang awal' }, { value: 'daily_weigh_in', label: 'Timbang harian' }, { value: 'final_weigh_in', label: 'Timbang akhir' }];
const questionKinds = [{ value: 'short_answer', label: 'Jawaban pendek' }, { value: 'long_answer', label: 'Jawaban panjang' }, { value: 'number', label: 'Angka' }, { value: 'single_choice', label: 'Pilihan tunggal' }, { value: 'multiple_choice', label: 'Pilihan ganda' }, { value: 'image_choice', label: 'Pilihan gambar' }, { value: 'photo_upload', label: 'Unggah foto' }, { value: 'video_upload', label: 'Unggah video' }, { value: 'heading', label: 'Heading' }, { value: 'text', label: 'Teks penjelas' }];
function makeDay(day_number: number, scheduled_on: string): AdminDay { return { id: crypto.randomUUID(), day_number, title: `Hari ke-${day_number}`, summary: '', scheduled_on, steps: [] }; }
function makeStep(kind: AdminStep['content_kind'], order: number, defaultVerificationMode: AdminProgram['default_verification_mode']): AdminStep { return { id: crypto.randomUUID(), step_order: order, title: stepKindLabel(kind), instructions: '', content_kind: kind, completion_policy: completionPolicy(kind), verification_mode: kind === 'quiz' || kind.includes('weigh_in') ? 'automatic' : defaultVerificationMode, media_path: null, media_alt_text: null, video_required: kind === 'video', video_threshold: 80, video_autoplay: false, questions: [] }; }
function makeQuestion(kind: string, order: number, quiz: boolean): AdminQuestion { const choice = ['single_choice', 'multiple_choice', 'image_choice'].includes(kind); const options = choice ? [1, 2].map((index) => ({ id: crypto.randomUUID(), option_order: index, title: '', media_path: null, media_alt_text: null })) : []; const objective = ['number', 'single_choice', 'multiple_choice', 'image_choice'].includes(kind); return { id: crypto.randomUUID(), question_order: order, kind, prompt: '', analysis_mode: 'none', analysis_rubric: null, analysis_rubric_version: null, media_kind: null, media_path: null, media_alt_text: null, options, answer_key: quiz && objective ? { question_id: '', accepted_text_values: [], number_value: null, selected_option_ids: [], matching_mode: 'exact' } : null }; }
function normalizeKind(step: AdminStep, kind: AdminStep['content_kind']): Partial<AdminStep> { return { content_kind: kind, completion_policy: completionPolicy(kind), verification_mode: kind === 'quiz' || kind.includes('weigh_in') ? 'automatic' : step.verification_mode, media_path: kind === 'video' ? step.media_path : null, video_required: kind === 'video', questions: ['form', 'quiz'].includes(kind) ? step.questions : [] }; }
function completionPolicy(kind: AdminStep['content_kind']) { if (kind === 'article') return 'mark_complete'; if (kind === 'video') return 'watch_video'; if (kind === 'quiz') return 'automatic_quiz'; if (kind.includes('weigh_in')) return 'submit_weigh_in'; return 'answer_all_questions'; }
function normalizeQuestionKind(question: AdminQuestion, kind: string, quiz: boolean): Partial<AdminQuestion> { const choice = ['single_choice', 'multiple_choice', 'image_choice'].includes(kind); const objective = ['number', 'single_choice', 'multiple_choice', 'image_choice'].includes(kind); const options = choice ? question.options.length >= 2 ? question.options : [1, 2].map((index) => ({ id: crypto.randomUUID(), option_order: index, title: '', media_path: null, media_alt_text: null })) : []; return { kind, options, answer_key: quiz && objective ? question.answer_key ?? { question_id: question.id, accepted_text_values: [], number_value: null, selected_option_ids: [], matching_mode: 'exact' } : null, analysis_mode: kind === 'photo_upload' ? question.analysis_mode : 'none', analysis_rubric: kind === 'photo_upload' ? question.analysis_rubric : null, analysis_rubric_version: kind === 'photo_upload' ? question.analysis_rubric_version : null }; }
function updateDay(program: AdminProgram, id: string, update: (day: AdminDay) => AdminDay) { return { ...program, days: program.days.map((day) => day.id === id ? update(day) : day) }; }
function updateStep(program: AdminProgram, dayId: string, stepId: string, update: (step: AdminStep) => AdminStep) { return updateDay(program, dayId, (day) => ({ ...day, steps: day.steps.map((step) => step.id === stepId ? update(step) : step) })); }
function updateQuestion(program: AdminProgram, dayId: string, stepId: string, questionId: string, update: (question: AdminQuestion) => AdminQuestion) { return updateStep(program, dayId, stepId, (step) => ({ ...step, questions: step.questions.map((question) => question.id === questionId ? update(question) : question) })); }
function findStep(program: AdminProgram, dayId: string, stepId: string) { return program.days.find((day) => day.id === dayId)?.steps.find((step) => step.id === stepId); }
function cloneStep(step: AdminStep, order: number): AdminStep { const optionMap = new Map<string, string>(); return { ...step, id: crypto.randomUUID(), step_order: order, questions: step.questions.map((question, questionIndex) => { const options = question.options.map((option, optionIndex) => { const id = crypto.randomUUID(); optionMap.set(option.id, id); return { ...option, id, option_order: optionIndex + 1 }; }); const id = crypto.randomUUID(); return { ...question, id, question_order: questionIndex + 1, options, answer_key: question.answer_key ? { ...question.answer_key, question_id: id, selected_option_ids: question.answer_key.selected_option_ids.map((old) => optionMap.get(old)).filter((value): value is string => Boolean(value)) } : null }; }) }; }
function questionCount(day: AdminDay) { return day.steps.flatMap((step) => step.questions).length; }
function datesBetween(start: string, end: string) { const dates: string[] = []; let current = start; while (current <= end && dates.length < 366) { dates.push(current); current = addDays(current, 1); } return dates; }
function addDays(value: string, offset: number) { const date = new Date(`${value}T12:00:00Z`); date.setUTCDate(date.getUTCDate() + offset); return date.toISOString().slice(0, 10); }
function href(id: string, section: ContentSection, extra: Record<string, string>) { return `/admin/programs/${id}?${new URLSearchParams({ section, ...extra }).toString()}`; }
function formatDate(value: string) { return dateFormatter.format(new Date(`${value}T12:00:00Z`)); }
function formatLongDate(value: string) { return new Intl.DateTimeFormat('id-ID', { dateStyle: 'full', timeZone: 'UTC' }).format(new Date(`${value}T12:00:00Z`)); }
function stepKindLabel(kind: AdminStep['content_kind']) { return ({ article: 'Artikel', video: 'Video', form: 'Form', quiz: 'Kuis', initial_weigh_in: 'Timbang awal', daily_weigh_in: 'Timbang harian', final_weigh_in: 'Timbang akhir' })[kind]; }
function stepIcon(kind: AdminStep['content_kind']): 'content' | 'activity' | 'clipboard' { return kind === 'article' || kind === 'video' ? 'content' : kind.includes('weigh_in') ? 'activity' : 'clipboard'; }
function instructionLabel(kind: AdminStep['content_kind']) { return ({ article: 'Tulis petunjuk atau isi artikel', video: 'Deskripsi video', form: 'Jelaskan informasi yang perlu diisi', quiz: 'Jelaskan cara mengisi kuis', initial_weigh_in: 'Petunjuk timbang awal', daily_weigh_in: 'Petunjuk timbang harian', final_weigh_in: 'Petunjuk timbang akhir' })[kind]; }
function stepHelp(kind: AdminStep['content_kind']) { if (kind === 'initial_weigh_in') return 'Berat disimpan khusus untuk enrollment ini.'; if (kind === 'daily_weigh_in') return 'Berat memantau progres dan tidak menambah poin penurunan berat secara terpisah.'; if (kind === 'final_weigh_in') return 'Timbang akhir baru dapat dikirim setelah timbang awal.'; return undefined; }
function questionKindLabel(kind: string) { return questionKinds.find((item) => item.value === kind)?.label ?? 'Pertanyaan'; }
const hiddenFileInput = { position: 'absolute', width: 1, height: 1, overflow: 'hidden', clip: 'rect(0, 0, 0, 0)', whiteSpace: 'nowrap' } as const;
const imagePickerStyle = { display: 'block', padding: '10px 12px', color: '#D92D20', fontSize: 14, fontWeight: 600 } as const;
const promptVideoStyle = { width: '100%', maxHeight: 420, borderRadius: 14, backgroundColor: '#000000' } as const;
function promptMediaButtonStyle(color: string, disabled: boolean) { return { display: 'block', padding: '10px 12px', color, fontSize: 14, fontWeight: 600, opacity: disabled ? 0.55 : 1 } as const; }

const styles = StyleSheet.create({
  paddedStatus: { paddingVertical: primitiveTokens.space.xSmall }, emptyBlock: { alignItems: 'center', padding: primitiveTokens.space.large, gap: primitiveTokens.space.xSmall }, dayDescription: { minHeight: 72 }, pickerGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: primitiveTokens.space.xSmall, padding: primitiveTokens.space.medium }, choice: { minHeight: 44, borderWidth: 1, borderRadius: primitiveTokens.radius.capsule, paddingHorizontal: primitiveTokens.space.small, alignItems: 'center', justifyContent: 'center' }, editControls: { flexDirection: 'row', justifyContent: 'flex-end', gap: primitiveTokens.space.xSmall, paddingHorizontal: primitiveTokens.space.medium, paddingBottom: primitiveTokens.space.small }, smallAction: { minHeight: 40, minWidth: 68, borderWidth: 1, borderRadius: primitiveTokens.radius.capsule, alignItems: 'center', justifyContent: 'center', paddingHorizontal: primitiveTokens.space.small }, toggleChoice: { minHeight: 58, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.small, paddingHorizontal: primitiveTokens.space.medium }, selectionRow: { minHeight: 52, borderWidth: 1, borderRadius: primitiveTokens.radius.medium, padding: primitiveTokens.space.small, justifyContent: 'center' }, optionBlock: { padding: primitiveTokens.space.small, gap: primitiveTokens.space.xSmall }, optionRow: { flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.xSmall }, optionInput: { flex: 1, minHeight: 44, borderWidth: 1, borderRadius: primitiveTokens.radius.small, paddingHorizontal: primitiveTokens.space.small, ...editorStyles.body }, promptImage: { width: '100%', height: 320, borderRadius: primitiveTokens.radius.large }, promptMediaActions: { flexDirection: 'row', flexWrap: 'wrap', alignItems: 'center', gap: primitiveTokens.space.xSmall, paddingHorizontal: primitiveTokens.space.small },
});
