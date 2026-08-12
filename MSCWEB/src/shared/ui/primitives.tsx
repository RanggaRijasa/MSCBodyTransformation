import type { PropsWithChildren, ReactNode } from 'react';
import { useEffect, useRef } from 'react';
import {
  ActivityIndicator,
  Image,
  Modal,
  Platform,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  type TextInputProps,
  View,
} from 'react-native';

import { componentTokens, primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { MSCIcon, type MSCIconName } from '@/shared/icons/MSCIcon';

type ButtonTone = 'primary' | 'secondary' | 'destructive';

type ButtonProps = {
  label: string;
  onPress: () => void;
  tone?: ButtonTone;
  disabled?: boolean;
  loading?: boolean;
  icon?: MSCIconName;
  testID?: string;
};

export function Button({
  label,
  onPress,
  tone = 'primary',
  disabled = false,
  loading = false,
  icon,
  testID,
}: ButtonProps) {
  const { colors } = useAppTheme();
  const isDisabled = disabled || loading;
  const background = tone === 'primary'
    ? colors.primaryAction
    : tone === 'destructive'
      ? colors.destructive
      : colors.surface;
  const foreground = tone === 'secondary' ? colors.primaryText : primitiveTokens.color.white;

  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      accessibilityState={{ disabled: isDisabled, busy: loading }}
      disabled={isDisabled}
      onPress={onPress}
      testID={testID}
      style={({ hovered, pressed }) => [
        styles.button,
        {
          backgroundColor: pressed && tone === 'primary' ? colors.primaryActionPressed : background,
          borderColor: tone === 'secondary' ? colors.border : background,
          opacity: isDisabled ? 0.55 : hovered ? 0.9 : 1,
        },
      ]}
    >
      {loading ? <ActivityIndicator color={foreground} /> : null}
      {!loading && icon ? <MSCIcon name={icon} color={foreground} /> : null}
      <Text style={[styles.buttonLabel, { color: foreground }]}>{label}</Text>
    </Pressable>
  );
}

export function IconButton({
  label,
  icon,
  onPress,
}: {
  label: string;
  icon: MSCIconName;
  onPress: () => void;
}) {
  const { colors } = useAppTheme();
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      onPress={onPress}
      style={({ hovered, pressed }) => [
        styles.iconButton,
        {
          backgroundColor: pressed ? colors.secondaryBackground : colors.surface,
          borderColor: hovered ? colors.primaryAction : colors.border,
        },
      ]}
    >
      <MSCIcon name={icon} color={colors.primaryText} accessibilityLabel={label} />
    </Pressable>
  );
}

export function Field({
  label,
  message,
  error,
  ...props
}: TextInputProps & { label: string; message?: string; error?: string }) {
  const { colors } = useAppTheme();
  const supportingText = error ?? message;
  return (
    <View style={styles.fieldGroup}>
      <Text style={[styles.fieldLabel, { color: colors.primaryText }]}>{label}</Text>
      <TextInput
        accessibilityLabel={label}
        placeholderTextColor={colors.secondaryText}
        {...props}
        style={[
          styles.field,
          {
            backgroundColor: colors.surface,
            borderColor: error ? colors.destructive : colors.border,
            color: colors.primaryText,
          },
          props.style,
        ]}
      />
      {supportingText ? (
        <Text style={[styles.supportingText, { color: error ? colors.destructive : colors.secondaryText }]}>
          {supportingText}
        </Text>
      ) : null}
    </View>
  );
}

export function SegmentedControl<T extends string>({
  label,
  options,
  value,
  onChange,
}: {
  label: string;
  options: readonly { label: string; value: T }[];
  value: T;
  onChange: (value: T) => void;
}) {
  const { colors } = useAppTheme();
  return (
    <View accessibilityRole="tablist" accessibilityLabel={label} style={[styles.segmented, { backgroundColor: colors.secondaryBackground }]}>
      {options.map((option) => {
        const selected = option.value === value;
        return (
          <Pressable
            key={option.value}
            accessibilityRole="tab"
            accessibilityState={{ selected }}
            aria-selected={selected}
            onPress={() => onChange(option.value)}
            style={[styles.segment, selected && { backgroundColor: colors.surface, borderColor: colors.border }]}
          >
            <Text style={[styles.segmentLabel, { color: selected ? colors.primaryText : colors.secondaryText }]}>
              {option.label}
            </Text>
          </Pressable>
        );
      })}
    </View>
  );
}

export function Card({ children }: PropsWithChildren) {
  const { colors } = useAppTheme();
  return <View style={[styles.card, { backgroundColor: colors.surface, borderColor: colors.border }]}>{children}</View>;
}

type StatusTone = 'success' | 'warning' | 'destructive' | 'info';

const statusIcons: Record<StatusTone, MSCIconName> = {
  success: 'approved',
  warning: 'warning',
  destructive: 'rejected',
  info: 'info',
};

export function StatusBadge({ label, tone }: { label: string; tone: StatusTone }) {
  const { colors } = useAppTheme();
  const toneColor = colors[tone];
  return (
    <View style={[styles.badge, { borderColor: toneColor }]}>
      <MSCIcon name={statusIcons[tone]} color={toneColor} size="small" />
      <Text style={[styles.badgeLabel, { color: toneColor }]}>{label}</Text>
    </View>
  );
}

export function ProgressBar({ label, value }: { label: string; value: number }) {
  const { colors } = useAppTheme();
  const safeValue = Math.max(0, Math.min(value, 1));
  return (
    <View accessibilityRole="progressbar" accessibilityLabel={label} accessibilityValue={{ min: 0, max: 100, now: Math.round(safeValue * 100) }} style={styles.progressGroup}>
      <View style={styles.progressHeader}>
        <Text style={[styles.fieldLabel, { color: colors.primaryText }]}>{label}</Text>
        <Text style={[styles.numeric, { color: colors.primaryText }]}>{Math.round(safeValue * 100)}%</Text>
      </View>
      <View style={[styles.progressTrack, { backgroundColor: colors.border }]}>
        <View style={[styles.progressFill, { backgroundColor: colors.accent, width: `${safeValue * 100}%` }]} />
      </View>
    </View>
  );
}

export function UserAvatar({ uri, label, size = 64 }: { uri?: string; label: string; size?: number }) {
  const { colors } = useAppTheme();
  const avatarStyle = { width: size, height: size, borderRadius: size / 2 };
  if (uri) {
    return <Image accessibilityLabel={label} source={{ uri }} style={[avatarStyle, styles.avatar]} />;
  }
  return (
    <View accessibilityLabel={`${label}, tanpa foto`} style={[avatarStyle, styles.avatarFallback, { backgroundColor: colors.secondaryBackground, borderColor: colors.border }]}>
      <MSCIcon name="profile" color={colors.secondaryText} size="large" />
    </View>
  );
}

type StateKind = 'loading' | 'empty' | 'error' | 'offline' | 'forbidden' | 'sessionExpired';

const statePresentation: Record<StateKind, { icon: MSCIconName; title: string; message: string }> = {
  loading: { icon: 'pending', title: 'Memuat', message: 'Tunggu sebentar.' },
  empty: { icon: 'info', title: 'Belum ada konten', message: 'Konten akan tampil di sini saat tersedia.' },
  error: { icon: 'warning', title: 'Terjadi kendala', message: 'Muat ulang halaman atau coba lagi.' },
  offline: { icon: 'offline', title: 'Koneksi tidak tersedia', message: 'Sambungkan perangkat ke internet lalu coba lagi.' },
  forbidden: { icon: 'forbidden', title: 'Akses tidak tersedia', message: 'Akun ini tidak memiliki akses ke halaman tersebut.' },
  sessionExpired: { icon: 'warning', title: 'Sesi berakhir', message: 'Masuk kembali untuk melanjutkan dengan aman.' },
};

export function StateView({ kind, action }: { kind: StateKind; action?: ReactNode }) {
  const { colors } = useAppTheme();
  const presentation = statePresentation[kind];
  return (
    <View accessibilityRole="summary" style={styles.stateView}>
      {kind === 'loading' ? <ActivityIndicator color={colors.primaryAction} /> : <MSCIcon name={presentation.icon} color={colors.primaryAction} size="large" />}
      <Text accessibilityRole="header" style={[styles.stateTitle, { color: colors.primaryText }]}>{presentation.title}</Text>
      <Text style={[styles.stateMessage, { color: colors.secondaryText }]}>{presentation.message}</Text>
      {action}
    </View>
  );
}

export function InlineMessage({ title, message, tone = 'info' }: { title: string; message: string; tone?: StatusTone }) {
  const { colors } = useAppTheme();
  const toneColor = colors[tone];
  return (
    <View style={[styles.inlineMessage, { borderColor: toneColor, backgroundColor: colors.secondaryBackground }]}>
      <MSCIcon name={statusIcons[tone]} color={toneColor} />
      <View style={styles.inlineCopy}>
        <Text style={[styles.inlineTitle, { color: colors.primaryText }]}>{title}</Text>
        <Text style={[styles.supportingText, { color: colors.secondaryText }]}>{message}</Text>
      </View>
    </View>
  );
}

export function Dialog({
  visible,
  title,
  onClose,
  children,
}: PropsWithChildren<{ visible: boolean; title: string; onClose: () => void }>) {
  const { colors } = useAppTheme();
  const dialogRef = useRef<View>(null);
  const previousFocusRef = useRef<Element | null>(null);

  useEffect(() => {
    if (Platform.OS !== 'web' || !visible) return undefined;
    previousFocusRef.current = globalThis.document.activeElement;
    const focusTarget = dialogRef.current as unknown as { focus?: () => void };
    focusTarget.focus?.();
    const closeOnEscape = (event: KeyboardEvent) => {
      if (event.key === 'Escape') onClose();
    };
    globalThis.document.addEventListener('keydown', closeOnEscape);
    return () => {
      globalThis.document.removeEventListener('keydown', closeOnEscape);
      (previousFocusRef.current as HTMLElement | null)?.focus?.();
    };
  }, [onClose, visible]);

  return (
    <Modal transparent visible={visible} animationType="fade" onRequestClose={onClose}>
      <View style={[styles.overlay, { backgroundColor: colors.overlay }]}>
        <View
          ref={dialogRef}
          accessible
          accessibilityRole="alert"
          accessibilityViewIsModal
          focusable
          style={[styles.dialog, { backgroundColor: colors.elevatedSurface, borderColor: colors.border }]}
        >
          <View style={styles.dialogHeader}>
            <Text accessibilityRole="header" style={[styles.stateTitle, { color: colors.primaryText }]}>{title}</Text>
            <IconButton label="Tutup" icon="rejected" onPress={onClose} />
          </View>
          {children}
        </View>
      </View>
    </Modal>
  );
}

export function Sheet(props: Parameters<typeof Dialog>[0]) {
  return <Dialog {...props} />;
}

export function Toast({ message }: { message: string }) {
  const { colors } = useAppTheme();
  return (
    <View accessibilityRole="alert" accessibilityLiveRegion="polite" style={[styles.toast, { backgroundColor: colors.primaryText }]}>
      <Text style={[styles.toastText, { color: colors.background }]}>{message}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  button: {
    minHeight: componentTokens.primaryButtonHeight,
    borderRadius: primitiveTokens.radius.medium,
    borderWidth: 1,
    paddingHorizontal: primitiveTokens.space.large,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: primitiveTokens.space.xSmall,
  },
  buttonLabel: typographyTokens.bodyStrong,
  iconButton: {
    width: componentTokens.minimumTouchTarget,
    height: componentTokens.minimumTouchTarget,
    borderRadius: primitiveTokens.radius.capsule,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  fieldGroup: { gap: primitiveTokens.space.xSmall },
  fieldLabel: typographyTokens.label,
  field: {
    minHeight: componentTokens.inputHeight,
    borderWidth: 1,
    borderRadius: primitiveTokens.radius.medium,
    paddingHorizontal: primitiveTokens.space.medium,
    ...typographyTokens.body,
  },
  supportingText: typographyTokens.caption,
  segmented: { flexDirection: 'row', padding: primitiveTokens.space.xxSmall, borderRadius: primitiveTokens.radius.medium },
  segment: { flex: 1, minHeight: componentTokens.minimumTouchTarget, alignItems: 'center', justifyContent: 'center', borderRadius: primitiveTokens.radius.small, borderWidth: 1, borderColor: primitiveTokens.color.transparent, paddingHorizontal: primitiveTokens.space.small },
  segmentLabel: typographyTokens.label,
  card: { borderWidth: StyleSheet.hairlineWidth, borderRadius: primitiveTokens.radius.large, padding: componentTokens.cardPadding, gap: primitiveTokens.space.medium },
  badge: { alignSelf: 'flex-start', minHeight: 32, flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.xxSmall, borderWidth: 1, borderRadius: primitiveTokens.radius.capsule, paddingHorizontal: primitiveTokens.space.small },
  badgeLabel: typographyTokens.caption,
  progressGroup: { gap: primitiveTokens.space.xSmall },
  progressHeader: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  numeric: { ...typographyTokens.label, fontVariant: ['tabular-nums'] },
  progressTrack: { height: 8, overflow: 'hidden', borderRadius: primitiveTokens.radius.capsule },
  progressFill: { height: '100%', borderRadius: primitiveTokens.radius.capsule },
  avatar: { resizeMode: 'cover' },
  avatarFallback: { borderWidth: 1, alignItems: 'center', justifyContent: 'center' },
  stateView: { width: '100%', maxWidth: componentTokens.readingMaxWidth, alignSelf: 'center', alignItems: 'center', padding: primitiveTokens.space.xLarge, gap: primitiveTokens.space.small },
  stateTitle: typographyTokens.headline,
  stateMessage: { ...typographyTokens.body, textAlign: 'center' },
  inlineMessage: { flexDirection: 'row', gap: primitiveTokens.space.small, padding: primitiveTokens.space.medium, borderWidth: 1, borderRadius: primitiveTokens.radius.medium },
  inlineCopy: { flex: 1, gap: primitiveTokens.space.xxSmall },
  inlineTitle: typographyTokens.bodyStrong,
  overlay: { flex: 1, justifyContent: 'center', padding: primitiveTokens.space.large },
  dialog: { width: '100%', maxWidth: 560, alignSelf: 'center', borderWidth: 1, borderRadius: primitiveTokens.radius.prominent, padding: primitiveTokens.space.large, gap: primitiveTokens.space.large },
  dialogHeader: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: primitiveTokens.space.medium },
  toast: { position: 'absolute', left: primitiveTokens.space.medium, right: primitiveTokens.space.medium, bottom: primitiveTokens.space.xLarge, minHeight: componentTokens.minimumTouchTarget, borderRadius: primitiveTokens.radius.medium, paddingHorizontal: primitiveTokens.space.medium, alignItems: 'center', justifyContent: 'center' },
  toastText: typographyTokens.callout,
});
