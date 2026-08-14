import { router, useLocalSearchParams } from 'expo-router';
import { useEffect, useMemo, useRef } from 'react';
import { Platform, ScrollView, View } from 'react-native';

import { ProgramCard, publicScreenStyles, Section } from '@/features/public/PublicComponents';
import { usePrograms } from '@/features/public/public-queries';
import { useParticipantEnrollments } from '@/features/participant/participant-queries';
import { programsForSegment, type ProgramSegment } from '@/features/participant/participant-program-policy';
import { useEnsureRepeatableLocalFixtures } from '@/features/payment/payment-queries';
import { useAuth } from '@/shared/auth/AuthProvider';
import { AppShell } from '@/shared/navigation/AppShell';
import { Button, InlineMessage, SegmentedControl, StateView } from '@/shared/ui/primitives';

const segments: readonly { label: string; value: ProgramSegment }[] = [
  { label: 'Diikuti', value: 'joined' },
  { label: 'Tersedia', value: 'available' },
  { label: 'Riwayat', value: 'history' },
];

export default function PublicProgramsRoute() {
  const params = useLocalSearchParams<{ segment?: string }>();
  const programs = usePrograms();
  const { state, requireAuthentication } = useAuth();
  const canJoinPrograms = state.status === 'authenticated'
    && (state.account.role === 'participant' || state.account.role === 'coach');
  const enrollments = useParticipantEnrollments(canJoinPrograms);
  const localFixtures = useEnsureRepeatableLocalFixtures(canJoinPrograms);
  const role = state.status === 'authenticated' ? state.account.role : 'guest';
  const catalogRoute = role === 'coach' ? '/coach/programs' : '/app/programs';
  const requestedSegment = parseSegment(params.segment);
  const segment = requestedSegment ?? (canJoinPrograms ? 'joined' : 'available');
  const scrollRef = useRef<ScrollView>(null);
  const storageKey = `msc-program-catalog-scroll:${segment}`;

  useEffect(() => {
    if (Platform.OS !== 'web') return;
    const saved = Number(globalThis.sessionStorage?.getItem(storageKey) ?? 0);
    if (Number.isFinite(saved) && saved > 0) {
      globalThis.setTimeout(() => scrollRef.current?.scrollTo({ y: saved, animated: false }), 0);
    }
  }, [storageKey]);

  const visiblePrograms = useMemo(() => programsForSegment(programs.data ?? [], enrollments.data ?? [], segment), [enrollments.data, programs.data, segment]);
  const privateSegment = segment !== 'available';

  return (
    <AppShell role={role} activeRoute="programs" title="Program" subtitle="Pilih program yang sesuai dengan tujuanmu">
      <ScrollView
        ref={scrollRef}
        contentContainerStyle={publicScreenStyles.content}
        onScroll={(event) => {
          if (Platform.OS === 'web') globalThis.sessionStorage?.setItem(storageKey, String(event.nativeEvent.contentOffset.y));
        }}
        scrollEventThrottle={100}
        testID="participant.program.catalog"
      >
        <SegmentedControl
          label="Daftar program"
          value={segment}
          onChange={(value) => router.replace(`${catalogRoute}?segment=${value}`)}
          options={segments}
        />

        {privateSegment && !canJoinPrograms ? (
          <>
            <InlineMessage title="Masuk diperlukan" message="Program yang diikuti dan riwayat hanya dimuat untuk akun Participant atau Coach." />
            <Button label="Masuk" onPress={() => requireAuthentication(`${catalogRoute}?segment=${segment}`)} />
          </>
        ) : programs.isPending || localFixtures.isPending || (privateSegment && enrollments.isPending) ? (
          <StateView kind="loading" />
        ) : programs.isError || localFixtures.isError || (privateSegment && enrollments.isError) ? (
          <StateView kind="error" action={<Button label="Coba lagi" onPress={() => void Promise.all([programs.refetch(), enrollments.refetch()])} />} />
        ) : (
          <Section
            title={segment === 'joined' ? 'Program yang diikuti' : segment === 'history' ? 'Riwayat program' : 'Program yang tersedia'}
            intro={segment === 'available' ? 'Pilih program untuk melihat tujuan, jadwal, biaya, dan status pendaftaran.' : undefined}
          >
            {visiblePrograms.length ? (
              <View style={publicScreenStyles.grid}>
                {visiblePrograms.map((program) => <View key={program.id} style={publicScreenStyles.gridItem}><ProgramCard program={program} /></View>)}
              </View>
            ) : <StateView kind="empty" />}
          </Section>
        )}
      </ScrollView>
    </AppShell>
  );
}

function parseSegment(value?: string): ProgramSegment | undefined {
  return value === 'joined' || value === 'available' || value === 'history' ? value : undefined;
}
