import { useState } from 'react';
import { ScrollView, View } from 'react-native';

import { ProgramCard, publicScreenStyles, Section } from '@/features/public/PublicComponents';
import { usePrograms } from '@/features/public/public-queries';
import { useAuth } from '@/shared/auth/AuthProvider';
import { AppShell } from '@/shared/navigation/AppShell';
import { Button, InlineMessage, SegmentedControl, StateView } from '@/shared/ui/primitives';

type ProgramTab = 'joined' | 'available' | 'history';

export default function PublicProgramsRoute() {
  const [tab, setTab] = useState<ProgramTab>('available');
  const programs = usePrograms();
  const { state, requireAuthentication } = useAuth();
  const role = state.status === 'authenticated' ? state.account.role : 'guest';

  return (
    <AppShell role={role} activeRoute="programs" title="Program" subtitle="Pilih program yang sesuai dengan tujuanmu">
      <ScrollView contentContainerStyle={publicScreenStyles.content}>
        <SegmentedControl label="Daftar program" value={tab} onChange={setTab} options={[
          { label: 'Diikuti', value: 'joined' },
          { label: 'Tersedia', value: 'available' },
          { label: 'Riwayat', value: 'history' },
        ]} />
        {tab !== 'available' ? (
          state.status === 'authenticated' ? <StateView kind="empty" /> : (
            <InlineMessage title="Masuk diperlukan" message="Program yang diikuti dan riwayat adalah data pribadi akunmu." />
          )
        ) : (
          <Section title="Program yang tersedia" intro="Detail publik menampilkan jadwal, tujuan, dan langkah program tanpa data peserta.">
            {programs.isPending ? <StateView kind="loading" /> : programs.isError ? <StateView kind="error" action={<Button label="Coba lagi" onPress={() => void programs.refetch()} />} /> : programs.data?.length ? (
              <View style={publicScreenStyles.grid}>{programs.data.map((program) => <View key={program.id} style={publicScreenStyles.gridItem}><ProgramCard program={program} /></View>)}</View>
            ) : <StateView kind="empty" />}
          </Section>
        )}
        {tab !== 'available' && state.status !== 'authenticated' ? <Button label="Masuk" onPress={() => requireAuthentication('/app/programs')} /> : null}
      </ScrollView>
    </AppShell>
  );
}
