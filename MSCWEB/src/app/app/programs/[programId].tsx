import { router, useLocalSearchParams } from 'expo-router';
import { ScrollView, StyleSheet, Text, View } from 'react-native';

import { publicScreenStyles } from '@/features/public/PublicComponents';
import { useProgram } from '@/features/public/public-queries';
import { ProgramActivity, ProgramOffer } from '@/features/participant/ParticipantProgramComponents';
import { isRepeatableLocalTestProgram } from '@/features/participant/participant-program-policy';
import {
  useParticipantAssignedCoach,
  useParticipantDayAccess,
  useParticipantEnrollments,
  useParticipantScores,
  useParticipantSubmissions,
} from '@/features/participant/participant-queries';
import { useAuth } from '@/shared/auth/AuthProvider';
import { primitiveTokens, typographyTokens } from '@/shared/design/tokens';
import { useAppTheme } from '@/shared/design/useAppTheme';
import { AppShell } from '@/shared/navigation/AppShell';
import { Button, Card, StateView, UserAvatar } from '@/shared/ui/primitives';

export default function ProgramDetailRoute() {
  const params = useLocalSearchParams<{ programId?: string; step?: string }>();
  const programId = typeof params.programId === 'string' ? params.programId : '';
  const selectedStepId = typeof params.step === 'string' ? params.step : undefined;
  const program = useProgram(programId);
  const { colors } = useAppTheme();
  const { state, requireAuthentication } = useAuth();
  const isParticipant = state.status === 'authenticated' && state.account.role === 'participant';
  const enrollments = useParticipantEnrollments(isParticipant);
  const dayAccess = useParticipantDayAccess(isParticipant);
  const submissions = useParticipantSubmissions(isParticipant);
  const scores = useParticipantScores(isParticipant);
  const assignedCoach = useParticipantAssignedCoach(isParticipant);
  const role = state.status === 'authenticated' ? state.account.role : 'guest';
  const enrollment = enrollments.data?.find((candidate) => candidate.program_id === programId);
  const isRepeatableFixture = program.data ? isRepeatableLocalTestProgram(program.data) : false;
  const visibleEnrollment = isRepeatableFixture ? undefined : enrollment;
  const activeExperience = visibleEnrollment?.status === 'active' || visibleEnrollment?.status === 'completed';
  const privatePending = isParticipant && [enrollments, dayAccess, submissions, scores].some((query) => query.isPending);
  const privateError = isParticipant && [enrollments, dayAccess, submissions, scores].some((query) => query.isError);

  return (
    <AppShell role={role} activeRoute="programs" title={selectedStepId ? 'Detail langkah' : program.data?.title ?? 'Detail program'}>
      <ScrollView contentContainerStyle={publicScreenStyles.content} keyboardShouldPersistTaps="handled">
        {!selectedStepId ? <Button label="Kembali ke Program" tone="secondary" icon="back" onPress={() => router.back()} /> : null}
        {program.isPending || privatePending ? <StateView kind="loading" /> : program.isError || privateError ? (
          <StateView kind="error" action={<Button label="Coba lagi" onPress={() => void Promise.all([program.refetch(), enrollments.refetch(), dayAccess.refetch(), submissions.refetch(), scores.refetch()])} />} />
        ) : !program.data ? <StateView kind="empty" /> : activeExperience && visibleEnrollment ? (
          <ProgramActivity
            program={program.data}
            enrollment={visibleEnrollment}
            accesses={dayAccess.data?.filter((access) => access.program_id === programId) ?? []}
            submissions={submissions.data?.filter((submission) => submission.enrollment_id === visibleEnrollment.id) ?? []}
            score={scores.data?.find((score) => score.enrollment_id === visibleEnrollment.id)}
            selectedStepId={selectedStepId}
            onOpenStep={(stepId) => router.push(`/app/programs/${programId}?step=${stepId}` as never)}
            onCloseStep={() => router.back()}
          />
        ) : (
          <>
            <ProgramOffer
              program={program.data}
              enrollment={visibleEnrollment}
              onPrimaryAction={() => {
                if (visibleEnrollment?.status === 'pending') return;
                if (requireAuthentication(`/app/programs/${programId}`)) {
                  router.push(`/app/payments/${programId}` as never);
                }
              }}
            />
            {isParticipant && assignedCoach.data ? (
              <Card>
                <Text accessibilityRole="header" style={[styles.heading, { color: colors.primaryText }]}>Coach pendamping</Text>
                <View style={styles.coachRow}>
                  <UserAvatar uri={assignedCoach.data.provider_avatar_url ?? undefined} label={assignedCoach.data.display_name} />
                  <View style={styles.flexCopy}>
                    <Text style={[styles.heading, { color: colors.primaryText }]}>{assignedCoach.data.display_name}</Text>
                    <Text style={[styles.body, { color: colors.secondaryText }]}>{assignedCoach.data.city || 'Lokasi belum dicantumkan'}</Text>
                  </View>
                </View>
              </Card>
            ) : null}
          </>
        )}
      </ScrollView>
    </AppShell>
  );
}

const styles = StyleSheet.create({
  heading: typographyTokens.headline,
  body: typographyTokens.body,
  coachRow: { flexDirection: 'row', alignItems: 'center', gap: primitiveTokens.space.medium },
  flexCopy: { flex: 1, minWidth: 0, gap: primitiveTokens.space.xxSmall },
});
