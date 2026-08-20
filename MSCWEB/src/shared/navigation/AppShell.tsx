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
  hideHeader?: boolean;
}>;

export function AppShell({ activeRoute, role = 'guest', title, subtitle, hideHeader = false, children }: AppShellProps) {
  const layout = useResponsiveLayout();
  const { colors } = useAppTheme();
  const insets = useSafeAreaInsets();
  const isCompact = layout === 'compact';
  const isMedium = layout === 'medium';
  const isAdminCompact = isCompact && role === 'admin';
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
          borderColor: isCompact ? colors.border : colors.primaryAction,
          bottom: isCompact
            ? Math.max(insets.bottom, componentTokens.compactTabBarBottomGap)
            : undefined,
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
        const foregroundColor = isActive
          ? isCompact
            ? colors.primaryAction
            : primitiveTokens.color.white
          : isCompact
            ? colors.primaryText
            : colors.secondaryText;
        return (
          <Link
            key={route.id}
            href={route.href}
            aria-current={isActive ? 'page' : undefined}
            style={[
              styles.navigationItem,
              isCompact && styles.compactNavigationItem,
              !isCompact && styles.railItem,
              isActive && {
                backgroundColor: isCompact
                  ? colors.navigationSelectedSurface
                  : colors.primaryAction,
              },
            ]}
          >
            <View
              style={[
                styles.navigationItemContent,
                isCompact
                  ? styles.compactNavigationItemContent
                  : styles.railItemContent,
              ]}
            >
              <MSCIcon
                name={route.icon}
                size={isCompact ? 'large' : 'medium'}
                color={foregroundColor}
                weight={isActive ? 'fill' : 'regular'}
              />
              <Text
                numberOfLines={1}
                style={[
                  styles.navigationLabel,
                  isAdminCompact && styles.adminCompactNavigationLabel,
                  { color: foregroundColor },
                  isActive && styles.navigationLabelActive,
                ]}
              >
                {route.label}
              </Text>
            </View>
          </Link>
        );
      })}
    </View>
  );

  return (
    <View style={[styles.root, { backgroundColor: colors.background, paddingTop: insets.top }]}>
      {!isCompact ? navigation : null}
      <View style={styles.contentColumn}>
        {!hideHeader ? <View style={[styles.header, isAdminCompact && styles.adminCompactHeader, { backgroundColor: colors.background, borderColor: isAdminCompact ? colors.background : colors.primaryAction }]}> 
          <Text accessibilityRole="header" style={[styles.headerTitle, isAdminCompact && styles.adminCompactHeaderTitle, { color: colors.primaryText }]}>{title}</Text>
          {subtitle ? <Text style={[styles.headerSubtitle, { color: colors.secondaryText }]}>{subtitle}</Text> : null}
        </View> : null}
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
  adminCompactHeader: { minHeight: 88, justifyContent: 'flex-end', borderBottomWidth: 0, paddingHorizontal: primitiveTokens.space.medium, paddingBottom: primitiveTokens.space.small },
  headerTitle: typographyTokens.title,
  adminCompactHeaderTitle: typographyTokens.titleLarge,
  headerSubtitle: typographyTokens.callout,
  content: { flex: 1, minHeight: 0 },
  navigationRail: { width: componentTokens.navigationWidth, borderRightWidth: 3, paddingTop: primitiveTokens.space.large, paddingHorizontal: primitiveTokens.space.small, gap: primitiveTokens.space.xSmall },
  mediumRail: { width: 112, paddingHorizontal: primitiveTokens.space.xSmall },
  brandMark: { width: 56, height: 56, borderRadius: primitiveTokens.radius.large, alignItems: 'center', justifyContent: 'center', alignSelf: 'center', marginBottom: primitiveTokens.space.large },
  brandInitials: { fontSize: 18, lineHeight: 22, fontWeight: '900', fontStyle: 'italic' },
  bottomNavigation: {
    position: 'absolute',
    left: componentTokens.compactTabBarHorizontalInset,
    right: componentTokens.compactTabBarHorizontalInset,
    zIndex: 10,
    height: componentTokens.compactTabBarHeight,
    flexDirection: 'row',
    borderWidth: 1,
    borderRadius: primitiveTokens.radius.capsule,
    padding: primitiveTokens.space.xxSmall,
    gap: primitiveTokens.space.xxSmall,
    shadowColor: primitiveTokens.color.black,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.18,
    shadowRadius: 12,
    elevation: 10,
  },
  navigationItem: {
    minHeight: componentTokens.minimumTouchTarget,
    borderRadius: primitiveTokens.radius.medium,
    textDecorationLine: 'none',
  },
  compactNavigationItem: {
    flex: 1,
    minWidth: 0,
    height: '100%',
    borderRadius: primitiveTokens.radius.capsule,
  },
  railItem: { minHeight: 54 },
  navigationItemContent: {
    flex: 1,
    width: '100%',
    alignItems: 'center',
    justifyContent: 'center',
  },
  compactNavigationItemContent: {
    flexDirection: 'column',
    paddingHorizontal: primitiveTokens.space.xxSmall,
    paddingVertical: primitiveTokens.space.xxSmall,
    gap: 0,
  },
  railItemContent: {
    flexDirection: 'row',
    justifyContent: 'flex-start',
    paddingHorizontal: primitiveTokens.space.medium,
    gap: primitiveTokens.space.small,
  },
  navigationLabel: {
    ...typographyTokens.caption,
    minHeight: typographyTokens.caption.lineHeight,
    textAlign: 'center',
  },
  adminCompactNavigationLabel: { fontSize: 10, lineHeight: 13 },
  navigationLabelActive: { fontWeight: '700' },
});
