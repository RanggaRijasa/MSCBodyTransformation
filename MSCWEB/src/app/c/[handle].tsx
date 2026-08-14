import { useLocalSearchParams } from 'expo-router';
import { StyleSheet, View } from 'react-native';

import { PublicCoachProfileView } from '@/features/coach/CoachProfileComponents';
import { usePublicCoachProfile } from '@/features/coach/coach-experience-queries';
import { primitiveTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { StateView } from '@/shared/ui/primitives';

export default function PublicCoachProfileRoute() {
  const { colors } = useAppTheme();
  const params = useLocalSearchParams<{ handle?: string }>();
  const handle = typeof params.handle === 'string' ? params.handle : '';
  const profile = usePublicCoachProfile(handle);
  return <View style={[styles.root, { backgroundColor: colors.background }]}>{profile.isPending ? <StateView kind="loading" /> : profile.isError ? <StateView kind="error" /> : profile.data ? <PublicCoachProfileView profile={profile.data} /> : <StateView kind="empty" />}</View>;
}

const styles = StyleSheet.create({ root: { flex: 1, minHeight: 0, paddingTop: primitiveTokens.space.large } });
