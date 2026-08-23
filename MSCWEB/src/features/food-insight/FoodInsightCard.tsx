import { useRef, useState } from 'react';
import { Pressable, StyleSheet, Text, TextInput, View } from 'react-native';

import { componentTokens, primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { MSCIcon } from '@/shared/icons/MSCIcon';
import { Button, Card, InlineMessage, StateView } from '@/shared/ui/primitives';
import { useCorrectFoodInsight, useFoodInsight } from './food-insight-queries';
import type { FoodInsightResult } from './food-insight-models';

export function FoodInsightCard({ submissionId, allowCorrection = false }: { submissionId?: string; allowCorrection?: boolean }) {
  const { colors } = useAppTheme();
  const insight = useFoodInsight(submissionId);
  if (!submissionId || (!insight.isPending && !insight.isError && !insight.data)) return null;
  return (
    <Card>
      <View style={styles.headerRow}>
        <MSCIcon name="star" color={colors.accent} />
        <View style={styles.flex}>
          <Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>Insight makanan</Text>
          <Text style={[styles.caption, { color: colors.secondaryText }]}>Perkiraan dari foto</Text>
        </View>
      </View>
      {insight.isPending ? <StateView kind="loading" /> : insight.isError ? (
        <InlineMessage title="Insight belum dapat dimuat" message="Pengiriman dan poin tetap tersimpan. Coba muat ulang insight." tone="warning" />
      ) : insight.data?.result ? (
        <ResultContent result={insight.data.result} allowCorrection={allowCorrection} />
      ) : insight.data && ['queued', 'processing', 'retry_scheduled'].includes(insight.data.job.status) ? (
        <InlineMessage title="Analisis sedang diproses" />
      ) : insight.data?.job.status === 'unavailable' ? (
        <InlineMessage title="Insight tidak tersedia" message="Layanan AI belum kompatibel atau belum dikonfigurasi. Pengiriman, persetujuan, dan poin tidak terpengaruh." tone="warning" />
      ) : (
        <InlineMessage title="Analisis belum berhasil" tone="warning" />
      )}
    </Card>
  );
}

function ResultContent({ result, allowCorrection }: { result: FoodInsightResult; allowCorrection: boolean }) {
  const { colors } = useAppTheme();
  return <View style={styles.stack}>
    <View accessibilityLabel={`${result.effective_rating} dari 5 bintang`} style={styles.stars}>
      {[1, 2, 3, 4, 5].map((value) => <MSCIcon key={value} name="star" size="small" color={value <= result.effective_rating ? colors.accent : colors.border} weight={value <= result.effective_rating ? 'fill' : 'regular'} />)}
    </View>
    {result.insight_sentences.map((sentence) => <Text key={sentence} style={[styles.body, { color: colors.primaryText }]}>{sentence}</Text>)}
    <View style={styles.macroGrid}>
      <Macro label="Protein" value={result.protein_grams} unit="g" />
      <Macro label="Karbohidrat" value={result.carbohydrate_grams} unit="g" />
      <Macro label="Lemak" value={result.fat_grams} unit="g" />
      <Macro label="Energi" value={result.calorie_kcal} unit="kkal" />
    </View>
    {allowCorrection ? <CorrectionForm result={result} /> : null}
  </View>;
}

function Macro({ label, value, unit }: { label: string; value: number | null; unit: string }) {
  const { colors } = useAppTheme();
  return <View style={[styles.macro, { backgroundColor: colors.secondaryBackground }]}><Text style={[styles.caption, { color: colors.secondaryText }]}>{label}</Text><Text style={[styles.bodyStrong, styles.numeric, { color: colors.primaryText }]}>{value === null ? '—' : `${Math.round(value)} ${unit}`}</Text></View>;
}

function CorrectionForm({ result }: { result: FoodInsightResult }) {
  const { colors } = useAppTheme();
  const mutation = useCorrectFoodInsight();
  const [open, setOpen] = useState(false); const [rating, setRating] = useState(result.effective_rating); const [reason, setReason] = useState('');
  const idempotencyKey = useRef(`food-correction-${result.id}-${crypto.randomUUID()}`);
  if (!open) return <Button label="Koreksi rating AI" tone="secondary" onPress={() => setOpen(true)} />;
  return <View style={styles.stack}>
    <Text style={[styles.bodyStrong, { color: colors.primaryText }]}>Rating yang benar</Text>
    <View style={styles.stars}>{[1, 2, 3, 4, 5].map((value) => <Pressable key={value} accessibilityRole="button" accessibilityLabel={`${value} dari 5 bintang`} onPress={() => setRating(value)} style={styles.starButton}><MSCIcon name="star" color={value <= rating ? colors.accent : colors.border} weight={value <= rating ? 'fill' : 'regular'} /></Pressable>)}</View>
    <TextInput accessibilityLabel="Alasan koreksi rating AI" multiline value={reason} onChangeText={setReason} placeholder="Jelaskan koreksi dengan singkat" placeholderTextColor={colors.secondaryText} style={[styles.input, { color: colors.primaryText, borderColor: colors.border, backgroundColor: colors.surface }]} />
    {mutation.isError ? <InlineMessage title="Koreksi belum disimpan" message="Muat ulang bila rating telah diubah Coach lain." tone="destructive" /> : null}
    <View style={styles.actions}><View style={styles.flex}><Button label="Batal" tone="secondary" onPress={() => setOpen(false)} /></View><View style={styles.flex}><Button label="Simpan koreksi" disabled={reason.trim().length < 8} loading={mutation.isPending} onPress={() => void mutation.mutateAsync({ result, rating, reason, idempotencyKey: idempotencyKey.current }).then(() => setOpen(false))} /></View></View>
  </View>;
}

const styles = StyleSheet.create({
  headerRow: { flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.small }, flex: { flex: 1, minWidth: 0 }, stack: { gap: primitiveTokens.space.small },
  stars: { flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.xxSmall }, starButton: { minWidth: componentTokens.minimumTouchTarget, minHeight: componentTokens.minimumTouchTarget, alignItems: 'center', justifyContent: 'center' },
  macroGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: primitiveTokens.space.small }, macro: { minWidth: 120, flex: 1, borderRadius: primitiveTokens.radius.medium, padding: primitiveTokens.space.small },
  input: { minHeight: 88, borderWidth: 1, borderRadius: primitiveTokens.radius.medium, padding: primitiveTokens.space.medium, textAlignVertical: 'top', ...typographyTokens.body }, actions: { flexDirection: 'row', flexWrap: 'wrap', gap: primitiveTokens.space.small },
  heading: typographyTokens.headline, body: typographyTokens.body, bodyStrong: typographyTokens.bodyStrong, caption: typographyTokens.caption, numeric: { fontVariant: ['tabular-nums'] },
});
