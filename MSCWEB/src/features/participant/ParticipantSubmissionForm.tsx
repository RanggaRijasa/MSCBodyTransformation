import { useEffect, useMemo, useRef, useState } from 'react';
import { Image, Platform, Pressable, StyleSheet, Text, TextInput, View } from 'react-native';

import type { PublicProgramQuestion, PublicProgramStep } from '@/features/public/public-models';
import type { ParticipantEnrollment, ParticipantSubmission } from './participant-models';
import { useSubmitParticipantAnswers, useSubmitParticipantWeighIn } from './participant-queries';
import type { ParticipantQuestionAnswer } from './participant-repository';
import { registerPrivateObjectUrl } from '@/shared/auth/private-cache';
import { componentTokens, primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { Button, Card, InlineMessage, ProgressBar } from '@/shared/ui/primitives';
import { FoodInsightCard } from '@/features/food-insight/FoodInsightCard';

type DraftAnswer = ParticipantQuestionAnswer & { previewUrl?: string };

export function ParticipantSubmissionForm({
  step,
  enrollment,
  submission,
  disabled,
}: {
  step: PublicProgramStep;
  enrollment: ParticipantEnrollment;
  submission?: ParticipantSubmission;
  disabled: boolean;
}) {
  const { colors } = useAppTheme();
  const submitAnswers = useSubmitParticipantAnswers();
  const submitWeight = useSubmitParticipantWeighIn();
  const [answers, setAnswers] = useState<Record<string, DraftAnswer>>({});
  const [weight, setWeight] = useState('');
  const [confirmationVisible, setConfirmationVisible] = useState(false);
  const [progress, setProgress] = useState({ value: 0, message: '' });
  const objectUrlCleanups = useRef(new Map<string, () => void>());
  const idempotencyKey = useRef(`web-${step.id}-${crypto.randomUUID()}`);
  const isWeight = ['initial_weigh_in', 'daily_weigh_in', 'final_weigh_in'].includes(step.content_kind);
  const mutation = isWeight ? submitWeight : submitAnswers;
  const error = mutation.error instanceof Error ? mutation.error.message : undefined;

  useEffect(() => () => {
    objectUrlCleanups.current.forEach((cleanup) => cleanup());
    objectUrlCleanups.current.clear();
  }, []);

  const complete = useMemo(() => {
    if (isWeight) return /^\d+(?:[,.]\d)?$/u.test(weight.trim());
    return interactiveQuestions(step).every((question) => answerIsComplete(question, answers[question.id]));
  }, [answers, isWeight, step, weight]);

  const setAnswer = (question: PublicProgramQuestion, patch: Partial<DraftAnswer>) => {
    setAnswers((current) => ({
      ...current,
      [question.id]: { questionId: question.id, ...current[question.id], ...patch },
    }));
  };

  const selectPhoto = (question: PublicProgramQuestion, file?: File) => {
    if (!file) return;
    objectUrlCleanups.current.get(question.id)?.();
    const previewUrl = URL.createObjectURL(file);
    const unregister = registerPrivateObjectUrl(previewUrl);
    objectUrlCleanups.current.set(question.id, () => {
      URL.revokeObjectURL(previewUrl);
      unregister();
    });
    setAnswer(question, { photo: file, previewUrl });
  };

  const submit = async () => {
    setConfirmationVisible(false);
    try {
      if (isWeight) {
        await submitWeight.mutateAsync({
          enrollmentId: enrollment.id,
          stepId: step.id,
          kind: step.content_kind === 'initial_weigh_in' ? 'initial' : step.content_kind === 'final_weigh_in' ? 'final' : 'daily',
          kilograms: weight,
          idempotencyKey: idempotencyKey.current,
        });
      } else {
        await submitAnswers.mutateAsync({
          enrollmentId: enrollment.id,
          step,
          answers: Object.values(answers),
          idempotencyKey: idempotencyKey.current,
          onProgress: (value, message) => setProgress({ value, message }),
        });
      }
    } catch {
      setProgress({ value: 0, message: '' });
    }
  };

  return (
    <View style={styles.stack} testID="participant.submission.form">
      {isWeight ? (
        <Card>
          <Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>Catat berat badan</Text>
          <TextInput
            accessibilityLabel="Berat dalam kilogram"
            editable={!disabled && !mutation.isPending}
            inputMode="decimal"
            value={weight}
            onChangeText={setWeight}
            placeholder="Berat (kg)"
            placeholderTextColor={colors.secondaryText}
            style={[styles.answerField, { color: colors.primaryText, backgroundColor: colors.surface, borderColor: colors.border }]}
          />
          <Text style={[styles.caption, { color: colors.secondaryText }]}>Gunakan kilogram, misalnya 72,5. Nilai ini bersifat pribadi dan tidak tampil di leaderboard.</Text>
        </Card>
      ) : (
        <Card>
          <Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>{step.content_kind === 'quiz' ? 'Kuis' : 'Jawaban aktivitas'}</Text>
          {step.content_kind === 'quiz' ? <InlineMessage title="Satu kesempatan" message="Periksa semua jawaban sebelum mengirim." tone="warning" /> : null}
          {interactiveQuestions(step).map((question) => (
            <QuestionInput
              key={question.id}
              question={question}
              answer={answers[question.id]}
              disabled={disabled || mutation.isPending}
              onChange={(patch) => setAnswer(question, patch)}
              onPhoto={(file) => selectPhoto(question, file)}
            />
          ))}
        </Card>
      )}

      {interactiveQuestions(step).some((question) => question.analysis_mode === 'food') ? (
        <>
          {!submission ? <InlineMessage title="Analisis foto dengan AI" message="Foto makanan ini akan dianalisis otomatis oleh layanan AI. Hindari wajah dan dokumen pribadi di dalam foto." tone="warning" /> : null}
          <FoodInsightCard submissionId={submission?.id} />
        </>
      ) : null}

      {progress.value > 0 && progress.value < 1 ? (
        <View accessibilityLiveRegion="polite">
          <ProgressBar label={progress.message} value={progress.value} />
        </View>
      ) : null}
      {error ? <InlineMessage title="Belum dapat dikirim" message={error} tone="destructive" /> : null}
      {confirmationVisible ? (
        <Card>
          <Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>Kirim jawaban sekarang?</Text>
          <Text style={[styles.body, { color: colors.secondaryText }]}>Pastikan jawaban dan foto sudah sesuai petunjuk program.</Text>
          <View style={styles.actionRow}>
            <View style={styles.flex}><Button label="Periksa lagi" tone="secondary" onPress={() => setConfirmationVisible(false)} /></View>
            <View style={styles.flex}><Button label="Kirim sekarang" loading={mutation.isPending} onPress={() => void submit()} /></View>
          </View>
        </Card>
      ) : (
        <Button
          label={submission?.status === 'rejected' ? 'Kirim perbaikan' : 'Kirim jawaban'}
          icon="upload"
          disabled={disabled || !complete}
          loading={mutation.isPending}
          onPress={() => setConfirmationVisible(true)}
          testID="participant.submission.confirm"
        />
      )}
    </View>
  );
}

function QuestionInput({
  question,
  answer,
  disabled,
  onChange,
  onPhoto,
}: {
  question: PublicProgramQuestion;
  answer?: DraftAnswer;
  disabled: boolean;
  onChange: (patch: Partial<DraftAnswer>) => void;
  onPhoto: (file?: File) => void;
}) {
  const { colors } = useAppTheme();
  if (question.kind === 'photo_upload') {
    return (
      <View style={styles.questionGroup}>
        <Text style={[styles.cardTitle, { color: colors.primaryText }]}>{question.prompt}</Text>
        {answer?.previewUrl ? (
          <Image accessibilityLabel="Pratinjau bukti foto" resizeMode="contain" source={{ uri: answer.previewUrl }} style={[styles.preview, { backgroundColor: colors.secondaryBackground }]} />
        ) : <InlineMessage title="Bukti foto diperlukan" message="Ambil foto dengan kamera atau pilih dari perangkat. Lokasi dan metadata lain akan dihapus." />}
        {Platform.OS === 'web' ? (
          <label style={{ display: 'block' }}>
            <span style={fileButtonStyle(colors.primaryAction, disabled)}>Ambil atau pilih foto</span>
            <input
              aria-label="Ambil atau pilih foto"
              accept="image/jpeg,image/png,image/webp,image/heic,image/heif"
              capture="environment"
              disabled={disabled}
              onChange={(event) => onPhoto(event.currentTarget.files?.[0])}
              style={visuallyHiddenInputStyle}
              type="file"
            />
          </label>
        ) : null}
      </View>
    );
  }
  if (question.program_question_options.length > 0) {
    const selected = answer?.selectedOptionIds ?? [];
    const isSingle = question.kind === 'single_choice' || question.kind === 'image_choice';
    return (
      <View style={styles.questionGroup}>
        <Text style={[styles.cardTitle, { color: colors.primaryText }]}>{question.prompt}</Text>
        {question.program_question_options.map((option) => {
          const checked = selected.includes(option.id);
          return (
            <Pressable
              key={option.id}
              accessibilityRole={isSingle ? 'radio' : 'checkbox'}
              accessibilityState={{ checked, disabled }}
              disabled={disabled}
              onPress={() => onChange({ selectedOptionIds: isSingle ? [option.id] : checked ? selected.filter((id) => id !== option.id) : [...selected, option.id] })}
              style={[styles.option, { borderColor: checked ? colors.primaryAction : colors.border, backgroundColor: checked ? colors.secondaryBackground : colors.surface }]}
            >
              <Text style={[styles.body, { color: colors.primaryText }]}>{option.title}</Text>
            </Pressable>
          );
        })}
      </View>
    );
  }
  return (
    <View style={styles.questionGroup}>
      <Text style={[styles.cardTitle, { color: colors.primaryText }]}>{question.prompt}</Text>
      <TextInput
        accessibilityLabel={question.prompt}
        editable={!disabled}
        inputMode={question.kind === 'number' ? 'decimal' : 'text'}
        multiline={question.kind !== 'number'}
        value={question.kind === 'number' ? answer?.numberValue?.toString() ?? '' : answer?.textValue ?? ''}
        onChangeText={(value) => onChange(question.kind === 'number' ? { numberValue: value.trim() === '' ? undefined : Number(value.replace(',', '.')) } : { textValue: value })}
        placeholder="Tulis jawaban"
        placeholderTextColor={colors.secondaryText}
        style={[styles.answerField, { color: colors.primaryText, backgroundColor: colors.surface, borderColor: colors.border }]}
      />
    </View>
  );
}

function interactiveQuestions(step: PublicProgramStep): PublicProgramQuestion[] {
  return step.program_questions.filter((question) => question.kind !== 'heading' && question.kind !== 'text');
}

function answerIsComplete(question: PublicProgramQuestion, answer?: DraftAnswer): boolean {
  if (!answer) return false;
  if (question.kind === 'photo_upload') return answer.photo !== undefined;
  if (question.kind === 'number') return answer.numberValue !== undefined && Number.isFinite(answer.numberValue);
  if (question.program_question_options.length > 0) return (answer.selectedOptionIds?.length ?? 0) > 0;
  return (answer.textValue?.trim().length ?? 0) > 0;
}

const visuallyHiddenInputStyle = { position: 'absolute', width: 1, height: 1, overflow: 'hidden', clip: 'rect(0, 0, 0, 0)', whiteSpace: 'nowrap' } as const;

function fileButtonStyle(backgroundColor: string, disabled: boolean) {
  return {
    alignItems: 'center',
    backgroundColor,
    borderRadius: 12,
    color: '#FFFFFF',
    cursor: disabled ? 'not-allowed' : 'pointer',
    display: 'flex',
    fontSize: 16,
    fontWeight: 700,
    justifyContent: 'center',
    minHeight: 48,
    opacity: disabled ? 0.55 : 1,
    padding: '12px 16px',
  } as const;
}

const styles = StyleSheet.create({
  stack: { gap: primitiveTokens.space.medium },
  questionGroup: { gap: primitiveTokens.space.small },
  heading: typographyTokens.headline,
  cardTitle: typographyTokens.bodyStrong,
  body: typographyTokens.body,
  caption: typographyTokens.caption,
  option: { minHeight: componentTokens.minimumTouchTarget, borderWidth: 2, borderRadius: primitiveTokens.radius.medium, padding: primitiveTokens.space.medium, justifyContent: 'center' },
  answerField: { minHeight: 72, borderWidth: 1, borderRadius: primitiveTokens.radius.medium, padding: primitiveTokens.space.medium, ...typographyTokens.body, textAlignVertical: 'top' },
  preview: { width: '100%', height: 260, borderRadius: primitiveTokens.radius.large },
  actionRow: { flexDirection: 'row', flexWrap: 'wrap', gap: primitiveTokens.space.small },
  flex: { flex: 1, minWidth: 180 },
});
