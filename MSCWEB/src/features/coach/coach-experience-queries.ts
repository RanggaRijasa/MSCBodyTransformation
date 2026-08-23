import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { participantQueryKeys } from '@/features/participant/participant-queries';
import { publicQueryKeys } from '@/features/public/public-queries';
import { getCoachExperienceRepository, type CoachApplicationDraftCommand, type CoachProfileDraftCommand } from './coach-experience-repository';

export const coachExperienceQueryKeys = {
  application: ['private', 'coach-application', 'mine'] as const,
  orders: ['private', 'coach-application', 'orders'] as const,
  adminApplications: ['private', 'admin', 'coach-applications'] as const,
  workspace: ['private', 'coach', 'workspace'] as const,
  activity: ['private', 'coach', 'activity'] as const,
  leaderboard: (programId: string) => ['private', 'coach', 'leaderboard', programId] as const,
  participantDirectory: ['private', 'coach', 'participants'] as const,
  participantDetail: (participantId: string, enrollmentId?: string) => [
    'private', 'coach', 'participant', participantId, enrollmentId ?? 'current',
  ] as const,
  profileDraft: ['private', 'coach', 'public-profile-draft'] as const,
  publicProfile: (handle: string) => ['public', 'coach-profile', handle] as const,
};

export function useMyCoachApplication(enabled: boolean) {
  return useQuery({ queryKey: coachExperienceQueryKeys.application, queryFn: () => getCoachExperienceRepository().getMyApplication(), enabled });
}

export function useCoachApplicationMutation() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: async (command: CoachApplicationDraftCommand) => {
      const repository = getCoachExperienceRepository();
      await repository.saveApplicationDraft(command);
      const aggregate = await repository.getMyApplication();
      if (!aggregate) throw new Error('Pendaftaran Coach belum tersimpan.');
      await repository.submitApplication(aggregate.application.id, `submit-${crypto.randomUUID()}`);
      return repository.createCoachPaymentOrder(aggregate.application.id, `coach-pay-${crypto.randomUUID()}`);
    },
    onSuccess: async () => Promise.all([
      client.invalidateQueries({ queryKey: coachExperienceQueryKeys.application }),
      client.invalidateQueries({ queryKey: coachExperienceQueryKeys.orders }),
    ]),
  });
}

export function useMyCoachPaymentOrders(enabled: boolean) {
  return useQuery({ queryKey: coachExperienceQueryKeys.orders, queryFn: () => getCoachExperienceRepository().listMyCoachPaymentOrders(), enabled });
}

export function useSubmitCoachPaymentEvidence() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (command: { orderId: string; file: Blob; idempotencyKey: string; onProgress?: (value: number, message: string) => void; onboarding?: boolean }) => getCoachExperienceRepository().submitPaymentEvidence(command.orderId, command.file, command.idempotencyKey, command.onProgress, command.onboarding),
    onSuccess: async () => Promise.all([
      client.invalidateQueries({ queryKey: coachExperienceQueryKeys.orders }),
      client.invalidateQueries({ queryKey: coachExperienceQueryKeys.adminApplications }),
    ]),
  });
}

export function useAdminCoachApplications(enabled: boolean) {
  return useQuery({ queryKey: coachExperienceQueryKeys.adminApplications, queryFn: () => getCoachExperienceRepository().listAdminApplications(), enabled });
}

export function useAdminCoachDecision() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (command: { kind: 'approve'; order: Parameters<ReturnType<typeof getCoachExperienceRepository>['approveCoach']>[0]; reference: string; destinationMatches: boolean } | { kind: 'correction' | 'reject'; order: Parameters<ReturnType<typeof getCoachExperienceRepository>['rejectCoach']>[0]; reason: string }) => command.kind === 'approve'
      ? getCoachExperienceRepository().approveCoach(command.order, command.reference, command.destinationMatches, `coach-approve-${crypto.randomUUID()}`)
      : command.kind === 'correction'
        ? getCoachExperienceRepository().requestCoachCorrection(command.order, command.reason, `coach-correction-${crypto.randomUUID()}`)
        : getCoachExperienceRepository().rejectCoach(command.order, command.reason, `coach-reject-${crypto.randomUUID()}`),
    onSettled: async () => client.invalidateQueries({ queryKey: coachExperienceQueryKeys.adminApplications }),
  });
}

export function useCoachWorkspace(enabled: boolean) {
  return useQuery({ queryKey: coachExperienceQueryKeys.workspace, queryFn: () => getCoachExperienceRepository().getWorkspace(), enabled, staleTime: 15_000 });
}

export function useCoachActivityFeed(enabled: boolean) {
  return useQuery({
    queryKey: coachExperienceQueryKeys.activity,
    queryFn: () => getCoachExperienceRepository().getActivityFeed(),
    enabled,
    staleTime: 15_000,
  });
}

export function useCoachLeaderboard(programId: string | undefined, enabled: boolean) {
  return useQuery({
    queryKey: coachExperienceQueryKeys.leaderboard(programId ?? 'none'),
    queryFn: () => getCoachExperienceRepository().getLeaderboard(programId ?? ''),
    enabled: enabled && programId !== undefined,
    staleTime: 15_000,
  });
}

export function useCoachParticipantDirectory(enabled: boolean) {
  return useQuery({
    queryKey: coachExperienceQueryKeys.participantDirectory,
    queryFn: () => getCoachExperienceRepository().getParticipantDirectory(),
    enabled,
    staleTime: 15_000,
  });
}

export function useCoachParticipantDetail(
  participantId: string,
  enrollmentId: string | undefined,
  enabled: boolean,
) {
  return useQuery({
    queryKey: coachExperienceQueryKeys.participantDetail(participantId, enrollmentId),
    queryFn: () => getCoachExperienceRepository().getParticipantDetail(participantId, enrollmentId),
    enabled: enabled && participantId.length > 0,
    staleTime: 15_000,
  });
}

export function useCoachProfileDraft(enabled: boolean) {
  return useQuery({ queryKey: coachExperienceQueryKeys.profileDraft, queryFn: () => getCoachExperienceRepository().getMyPublicProfileDraft(), enabled });
}

export function useSaveCoachProfileDraft() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (command: CoachProfileDraftCommand) => getCoachExperienceRepository().savePublicProfileDraft(command),
    onSuccess: async () => client.invalidateQueries({ queryKey: coachExperienceQueryKeys.profileDraft }),
  });
}

export function usePublishCoachProfile() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: () => getCoachExperienceRepository().publishPublicProfile(),
    onSuccess: async (profile) => Promise.all([
      client.invalidateQueries({ queryKey: coachExperienceQueryKeys.profileDraft }),
      client.invalidateQueries({ queryKey: coachExperienceQueryKeys.workspace }),
      client.invalidateQueries({ queryKey: coachExperienceQueryKeys.publicProfile(profile.handle) }),
      client.invalidateQueries({ queryKey: publicQueryKeys.coaches }),
      client.invalidateQueries({ queryKey: ['public', 'coach'] }),
      client.invalidateQueries({ queryKey: participantQueryKeys.coach }),
    ]),
  });
}

export function usePublicCoachProfile(handle: string) {
  return useQuery({ queryKey: coachExperienceQueryKeys.publicProfile(handle), queryFn: () => getCoachExperienceRepository().getPublicProfile(handle), enabled: handle.length > 0 });
}
