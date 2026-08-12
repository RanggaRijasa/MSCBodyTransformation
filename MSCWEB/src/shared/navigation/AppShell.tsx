import { Link, type Href } from 'expo-router';
import type { PropsWithChildren } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { componentTokens, primitiveTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { useResponsiveLayout } from '@/shared/design/useResponsiveLayout';
import { MSCIcon, type MSCIconName } from '@/shared/icons/MSCIcon';

type AppRoute = {
  key: MSCIconName;
  label: string;
  href: Href;
};

const routes: readonly AppRoute[] = [
  { key: 'home', label: 'Beranda', href: '/app' },
  { key: 'program', label: 'Uji', href: '/app/feasibility' },
  { key: 'profile', label: 'Profil', href: '/app/profile' },
];

type AppShellProps = PropsWithChildren<{
  activeRoute: MSCIconName;
  title: string;
}>;

export function AppShell({ activeRoute, title, children }: AppShellProps) {
  const layout = useResponsiveLayout();
  const { colors } = useAppTheme();
  const insets = useSafeAreaInsets();
  const isCompact = layout === 'compact';

  const navigation = (
    <View
      role="navigation"
      aria-label="Navigasi utama"
      style={[
        isCompact ? styles.bottomNavigation : styles.navigationRail,
        {
          backgroundColor: colors.surface,
          borderColor: colors.border,
          paddingBottom: isCompact ? Math.max(insets.bottom, primitiveTokens.space.xSmall) : 0,
        },
      ]}
    >
      {routes.map((route) => {
        const isActive = route.key === activeRoute;

        return (
          <Link
            key={route.key}
            href={route.href}
            aria-current={isActive ? 'page' : undefined}
            style={[
              styles.navigationItem,
              isCompact && styles.compactNavigationItem,
              !isCompact && styles.railItem,
              isActive && { backgroundColor: colors.secondaryBackground },
            ]}
          >
            <MSCIcon
              name={route.key}
              color={isActive ? colors.primaryAction : colors.secondaryText}
              weight={isActive ? 'fill' : 'regular'}
            />
            <Text
              style={[
                styles.navigationLabel,
                { color: isActive ? colors.primaryText : colors.secondaryText },
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
        <View style={[styles.header, { backgroundColor: colors.surface, borderColor: colors.border }]}>
          <Text accessibilityRole="header" style={[styles.headerTitle, { color: colors.primaryText }]}>
            {title}
          </Text>
        </View>
        <View style={styles.content}>{children}</View>
        {isCompact ? navigation : null}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    flexDirection: 'row',
    minWidth: 0,
  },
  contentColumn: {
    flex: 1,
    minWidth: 0,
  },
  header: {
    minHeight: 64,
    justifyContent: 'center',
    borderBottomWidth: StyleSheet.hairlineWidth,
    paddingHorizontal: primitiveTokens.space.large,
  },
  headerTitle: {
    fontSize: 24,
    lineHeight: 30,
    fontWeight: '700',
  },
  content: {
    flex: 1,
    minHeight: 0,
  },
  navigationRail: {
    width: componentTokens.navigationWidth,
    borderRightWidth: StyleSheet.hairlineWidth,
    paddingTop: primitiveTokens.space.large,
    paddingHorizontal: primitiveTokens.space.small,
    gap: primitiveTokens.space.xSmall,
  },
  bottomNavigation: {
    minHeight: 64,
    flexDirection: 'row',
    borderTopWidth: StyleSheet.hairlineWidth,
    paddingTop: primitiveTokens.space.xSmall,
    paddingHorizontal: primitiveTokens.space.xSmall,
  },
  navigationItem: {
    flex: 1,
    minHeight: componentTokens.minimumTouchTarget,
    alignItems: 'center',
    justifyContent: 'center',
    gap: primitiveTokens.space.xxSmall,
    borderRadius: primitiveTokens.radius.medium,
  },
  compactNavigationItem: {
    flex: 0,
    flexBasis: '33.333333%',
    minWidth: 0,
    width: '33.333333%',
  },
  railItem: {
    flex: 0,
    minHeight: 52,
    flexDirection: 'row',
    justifyContent: 'flex-start',
    paddingHorizontal: primitiveTokens.space.medium,
    gap: primitiveTokens.space.small,
  },
  navigationLabel: {
    fontSize: 12,
    lineHeight: 16,
    fontWeight: '500',
    textAlign: 'center',
  },
  navigationLabelActive: {
    fontWeight: '700',
  },
});
