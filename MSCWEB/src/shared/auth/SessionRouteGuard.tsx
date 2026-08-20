import { router, usePathname } from 'expo-router';
import { useEffect } from 'react';
import { StyleSheet, View } from 'react-native';

import { useAuth } from './AuthProvider';
import { guardedDestination } from './route-guard-policy';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { StateView } from '@/shared/ui/primitives';

export function SessionRouteGuard() {
  const pathname = usePathname();
  const { colors } = useAppTheme();
  const { state } = useAuth();
  const target = guardedDestination(pathname, state);
  const mustBlockLoading = state.status === 'loading'
    && (pathname.startsWith('/onboarding') || pathname.startsWith('/coach') || pathname.startsWith('/admin'));

  useEffect(() => {
    if (target !== null && target !== pathname) router.replace(target as never);
  }, [pathname, target]);

  if (!mustBlockLoading && (target === null || target === pathname)) return null;
  return (
    <View style={[styles.blocker, { backgroundColor: colors.background }]}>
      <StateView kind="loading" />
    </View>
  );
}

const styles = StyleSheet.create({
  blocker: {
    position: 'absolute',
    top: 0,
    right: 0,
    bottom: 0,
    left: 0,
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 10_000,
  },
});
