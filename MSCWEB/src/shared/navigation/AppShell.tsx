import { Link } from 'expo-router';
import type { PropsWithChildren } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { componentTokens, primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { useResponsiveLayout } from '@/shared/design/useResponsiveLayout';
import { MSCIcon } from '@/shared/icons/MSCIcon';
import { type AppRole, navigationByRole } from '@/shared/navigation/navigation-model';

type AppShellProps = PropsWithChildren<{
  activeRoute: string;
  role?: AppRole;
  title: string;
  subtitle?: string;
}>;

export function AppShell({ activeRoute, role = 'guest', title, subtitle, children }: AppShellProps) {
  const layout = useResponsiveLayout();
  const { colors } = useAppTheme();
  const insets = useSafeAreaInsets();
  const isCompact = layout === 'compact';
  const isMedium = layout === 'medium';
  const routes = navigationByRole[role];

  const navigation = (
    <View
      role="navigation"
      aria-label="Navigasi utama"
      style={[
        isCompact ? styles.bottomNavigation : styles.navigationRail,
        isMedium && styles.mediumRail,
        {
          backgroundColor: colors.surface,
          borderColor: colors.primaryAction,
          paddingBottom: isCompact ? Math.max(insets.bottom, primitiveTokens.space.xSmall) : 0,
        },
      ]}
    >
      {!isCompact ? (
        <View style={[styles.brandMark, { backgroundColor: colors.primaryText }]} accessibilityLabel="MSC Body Transformation">
          <Text style={[styles.brandInitials, { color: colors.accent }]}>MSC</Text>
        </View>
      ) : null}
      {routes.map((route) => {
        const isActive = route.id === activeRoute;
        return (
          <Link
            key={route.id}
            href={route.href}
            aria-current={isActive ? 'page' : undefined}
            style={[
              styles.navigationItem,
              isCompact && styles.compactNavigationItem,
              !isCompact && styles.railItem,
              isActive && { backgroundColor: colors.primaryAction },
            ]}
          >
            <MSCIcon
              name={route.icon}
              color={isActive ? primitiveTokens.color.white : colors.secondaryText}
              weight={isActive ? 'fill' : 'regular'}
            />
            <Text
              numberOfLines={1}
              style={[
                styles.navigationLabel,
                { color: isActive ? primitiveTokens.color.white : colors.secondaryText },
                isActive && styles.navigationLabelActive,
              ]}
            >
              {route.label}
            </Text>
          </Link>
        );
      })}
    </View>
  );

  return (
    <View style={[styles.root, { backgroundColor: colors.background, paddingTop: insets.top }]}>
      {!isCompact ? navigation : null}
      <View style={styles.contentColumn}>
        <View style={[styles.header, { backgroundColor: colors.background, borderColor: colors.primaryAction }]}>
          <Text accessibilityRole="header" style={[styles.headerTitle, { color: colors.primaryText }]}>{title}</Text>
          {subtitle ? <Text style={[styles.headerSubtitle, { color: colors.secondaryText }]}>{subtitle}</Text> : null}
        </View>
        <View style={[styles.content, isCompact && { paddingBottom: componentTokens.compactTabBarHeight + Math.max(insets.bottom, primitiveTokens.space.xSmall) }]}>{children}</View>
        {isCompact ? navigation : null}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, flexDirection: 'row', minWidth: 0 },
  contentColumn: { flex: 1, minWidth: 0 },
  header: { minHeight: componentTokens.compactHeaderHeight, justifyContent: 'center', borderBottomWidth: 3, paddingHorizontal: primitiveTokens.space.large, paddingVertical: primitiveTokens.space.small },
  headerTitle: typographyTokens.title,
  headerSubtitle: typographyTokens.callout,
  content: { flex: 1, minHeight: 0 },
  navigationRail: { width: componentTokens.navigationWidth, borderRightWidth: 3, paddingTop: primitiveTokens.space.large, paddingHorizontal: primitiveTokens.space.small, gap: primitiveTokens.space.xSmall },
  mediumRail: { width: 112, paddingHorizontal: primitiveTokens.space.xSmall },
  brandMark: { width: 56, height: 56, borderRadius: primitiveTokens.radius.large, alignItems: 'center', justifyContent: 'center', alignSelf: 'center', marginBottom: primitiveTokens.space.large },
  brandInitials: { fontSize: 18, lineHeight: 22, fontWeight: '900', fontStyle: 'italic' },
  bottomNavigation: { position: 'absolute', left: 0, right: 0, bottom: 0, zIndex: 10, minHeight: componentTokens.compactTabBarHeight, flexDirection: 'row', borderTopWidth: 3, paddingTop: primitiveTokens.space.xSmall, paddingHorizontal: primitiveTokens.space.xxSmall },
  navigationItem: { minHeight: componentTokens.minimumTouchTarget, alignItems: 'center', justifyContent: 'center', gap: primitiveTokens.space.xxSmall, borderRadius: primitiveTokens.radius.medium },
  compactNavigationItem: {
    flex: 1,
    minWidth: 0,
    flexDirection: 'column',
    paddingHorizontal: primitiveTokens.space.xxSmall,
    paddingVertical: primitiveTokens.space.xxSmall,
  },
  railItem: { minHeight: 54, flexDirection: 'row', justifyContent: 'flex-start', paddingHorizontal: primitiveTokens.space.medium, gap: primitiveTokens.space.small },
  navigationLabel: { ...typographyTokens.caption, textAlign: 'center' },
  navigationLabelActive: { fontWeight: '800' },
});
