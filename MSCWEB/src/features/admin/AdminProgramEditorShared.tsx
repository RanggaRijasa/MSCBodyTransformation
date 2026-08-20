import type { PropsWithChildren, ReactNode } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, TextInput, type TextInputProps, View } from 'react-native';

import { componentTokens, primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { MSCIcon, type MSCIconName } from '@/shared/icons/MSCIcon';

export function ProgramEditorScaffold({ title, onBack, action, children, testID }: PropsWithChildren<{ title: string; onBack: () => void; action?: ReactNode; testID?: string }>) {
  const { colors } = useAppTheme();
  return <View style={[styles.screen, { backgroundColor: colors.secondaryBackground }]} testID={testID}>
    <View style={[styles.topBar, { backgroundColor: colors.secondaryBackground }]}>
      <CircleAction label="Kembali" icon="back" onPress={onBack} />
      <Text accessibilityRole="header" numberOfLines={1} style={[styles.topTitle, { color: colors.primaryText }]}>{title}</Text>
      <View style={styles.topAction}>{action ?? <View style={styles.actionPlaceholder} />}</View>
    </View>
    <ScrollView contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled">{children}</ScrollView>
  </View>;
}

export function TopTextAction({ label, onPress, disabled = false }: { label: string; onPress: () => void; disabled?: boolean }) {
  const { colors } = useAppTheme();
  return <Pressable accessibilityRole="button" accessibilityLabel={label} accessibilityState={{ disabled }} disabled={disabled} onPress={onPress} style={({ pressed }) => [styles.textAction, { backgroundColor: colors.surface, opacity: disabled ? 0.45 : pressed ? 0.62 : 1 }]}><Text style={[styles.textActionLabel, { color: colors.primaryAction }]}>{label}</Text></Pressable>;
}

export function CircleAction({ label, icon, onPress }: { label: string; icon: MSCIconName; onPress: () => void }) {
  const { colors } = useAppTheme();
  return <Pressable accessibilityRole="button" accessibilityLabel={label} onPress={onPress} style={({ pressed }) => [styles.circleAction, { backgroundColor: pressed ? colors.secondaryBackground : colors.surface }]}><MSCIcon name={icon} color={colors.primaryText} /></Pressable>;
}

export function FormSection({ title, footer, children }: PropsWithChildren<{ title?: string; footer?: string }>) {
  const { colors } = useAppTheme();
  return <View style={styles.section}>{title ? <Text style={[styles.sectionLabel, { color: colors.secondaryText }]}>{title}</Text> : null}<View style={[styles.group, { backgroundColor: colors.surface, borderColor: colors.border }]}>{children}</View>{footer ? <Text style={[styles.footer, { color: colors.secondaryText }]}>{footer}</Text> : null}</View>;
}

export function GroupDivider() {
  const { colors } = useAppTheme();
  return <View style={[styles.divider, { backgroundColor: colors.border }]} />;
}

export function NavigationRow({ title, subtitle, icon, onPress, destructive = false, testID }: { title: string; subtitle?: string; icon: MSCIconName; onPress: () => void; destructive?: boolean; testID?: string }) {
  const { colors } = useAppTheme();
  const accent = destructive ? colors.destructive : colors.primaryAction;
  return <Pressable accessibilityRole="button" accessibilityLabel={`${title}${subtitle ? `, ${subtitle}` : ''}`} onPress={onPress} testID={testID} style={({ pressed }) => [styles.navigationRow, { opacity: pressed ? 0.62 : 1 }]}>
    <MSCIcon name={icon} color={accent} />
    <View style={styles.flex}><Text style={[styles.rowTitle, { color: destructive ? colors.destructive : colors.primaryText }]}>{title}</Text>{subtitle ? <Text style={[styles.rowSubtitle, { color: colors.secondaryText }]}>{subtitle}</Text> : null}</View>
    <MSCIcon name="chevron" color={colors.secondaryText} size="small" />
  </Pressable>;
}

export function FormTextInput({ label, multiline = false, ...props }: TextInputProps & { label: string; multiline?: boolean }) {
  const { colors } = useAppTheme();
  return <TextInput accessibilityLabel={label} placeholder={label} placeholderTextColor={colors.secondaryText} multiline={multiline} {...props} style={[styles.formInput, multiline && styles.multilineInput, { color: colors.primaryText }, props.style]} />;
}

export function LabeledValueRow({ label, value, icon }: { label: string; value: string; icon?: MSCIconName }) {
  const { colors } = useAppTheme();
  return <View style={styles.valueRow}>{icon ? <MSCIcon name={icon} color={colors.primaryAction} size="small" /> : null}<Text style={[styles.valueLabel, { color: colors.primaryText }]}>{label}</Text><Text style={[styles.value, { color: colors.secondaryText }]}>{value}</Text></View>;
}

export function ToggleRow({ label, value, onChange }: { label: string; value: boolean; onChange: (value: boolean) => void }) {
  const { colors } = useAppTheme();
  return <Pressable accessibilityRole="switch" accessibilityLabel={label} accessibilityState={{ checked: value }} onPress={() => onChange(!value)} style={styles.toggleRow}><Text style={[styles.rowTitle, styles.flex, { color: colors.primaryText }]}>{label}</Text><View style={[styles.switchTrack, { backgroundColor: value ? colors.primaryAction : colors.border }]}><View style={[styles.switchThumb, { backgroundColor: primitiveTokens.color.white, transform: [{ translateX: value ? 20 : 0 }] }]} /></View></Pressable>;
}

export function StatusLine({ label, tone = 'success' }: { label: string; tone?: 'success' | 'warning' | 'neutral' }) {
  const { colors } = useAppTheme();
  const color = tone === 'success' ? colors.success : tone === 'warning' ? colors.warning : colors.secondaryText;
  return <View style={styles.statusLine}><MSCIcon name={tone === 'success' ? 'approved' : tone === 'warning' ? 'warning' : 'info'} color={color} size="small" /><Text style={[styles.statusLabel, { color }]}>{label}</Text></View>;
}

export const editorStyles = StyleSheet.create({
  stack: { gap: primitiveTokens.space.medium },
  compactStack: { gap: primitiveTokens.space.small },
  row: { flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.small },
  rowBetween: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: primitiveTokens.space.small },
  flex: { flex: 1, minWidth: 0 },
  body: typographyTokens.body,
  bodyStrong: typographyTokens.bodyStrong,
  caption: typographyTokens.caption,
  headline: typographyTokens.headline,
  title: typographyTokens.title,
  numeric: { ...typographyTokens.bodyStrong, fontVariant: ['tabular-nums'] },
});

const styles = StyleSheet.create({
  screen: { flex: 1, minHeight: 0 },
  topBar: { minHeight: 76, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: primitiveTokens.space.medium, gap: primitiveTokens.space.small },
  topTitle: { ...typographyTokens.headline, flex: 1, textAlign: 'center' },
  topAction: { width: 92, alignItems: 'flex-end' },
  actionPlaceholder: { width: componentTokens.minimumTouchTarget, height: componentTokens.minimumTouchTarget },
  circleAction: { width: componentTokens.minimumTouchTarget, height: componentTokens.minimumTouchTarget, borderRadius: primitiveTokens.radius.capsule, alignItems: 'center', justifyContent: 'center' },
  textAction: { minHeight: componentTokens.minimumTouchTarget, borderRadius: primitiveTokens.radius.capsule, paddingHorizontal: primitiveTokens.space.medium, alignItems: 'center', justifyContent: 'center' },
  textActionLabel: typographyTokens.bodyStrong,
  content: { width: '100%', maxWidth: componentTokens.contentMaxWidth, alignSelf: 'center', paddingHorizontal: primitiveTokens.space.medium, paddingBottom: 140, gap: primitiveTokens.space.large },
  section: { gap: primitiveTokens.space.xSmall },
  sectionLabel: { ...typographyTokens.headline, paddingHorizontal: primitiveTokens.space.small },
  group: { overflow: 'hidden', borderWidth: StyleSheet.hairlineWidth, borderRadius: primitiveTokens.radius.large },
  divider: { height: StyleSheet.hairlineWidth, marginLeft: 60 },
  footer: { ...typographyTokens.caption, paddingHorizontal: primitiveTokens.space.small },
  navigationRow: { minHeight: 84, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.medium, paddingHorizontal: primitiveTokens.space.medium, paddingVertical: primitiveTokens.space.small },
  flex: { flex: 1, minWidth: 0 },
  rowTitle: typographyTokens.bodyStrong,
  rowSubtitle: typographyTokens.body,
  formInput: { minHeight: 58, paddingHorizontal: primitiveTokens.space.medium, ...typographyTokens.body },
  multilineInput: { minHeight: 100, paddingTop: primitiveTokens.space.medium, textAlignVertical: 'top' },
  valueRow: { minHeight: 58, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.small, paddingHorizontal: primitiveTokens.space.medium },
  valueLabel: { ...typographyTokens.body, flex: 1 },
  value: { ...typographyTokens.body, textAlign: 'right', fontVariant: ['tabular-nums'] },
  toggleRow: { minHeight: 58, flexDirection: 'row', alignItems: 'center', paddingHorizontal: primitiveTokens.space.medium, gap: primitiveTokens.space.medium },
  switchTrack: { width: 52, height: 32, borderRadius: 16, padding: 3 },
  switchThumb: { width: 26, height: 26, borderRadius: 13 },
  statusLine: { flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.xSmall, paddingHorizontal: primitiveTokens.space.medium, paddingVertical: primitiveTokens.space.small },
  statusLabel: typographyTokens.label,
});
