import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import {
  getParticipantRepository,
  type ParticipantAnswerSubmissionCommand,
  type ParticipantWeighInCommand,
} from './participant-repository';

export const participantQueryKeys = {
  profile: ['private', 'participant', 'profile'] as const,
  enrollments: ['private', 'participant', 'enrollments'] as const,
  dayAccess: ['private', 'participant', 'day-access'] as const,
  submissions: ['private', 'participant', 'submissions'] as const,
  scores: ['private', 'participant', 'scores'] as const,
  coach: ['private', 'participant', 'assigned-coach'] as const,
};

export function useParticipantProfile(enabled: boolean) {
  return useQuery({ queryKey: participantQueryKeys.profile, queryFn: () => getParticipantRepository().getProfile(), enabled });
}

export function useParticipantEnrollments(enabled: boolean) {
  return useQuery({ queryKey: participantQueryKeys.enrollments, queryFn: () => getParticipantRepository().listEnrollments(), enabled });
}

export function useParticipantDayAccess(enabled: boolean) {
  return useQuery({ queryKey: participantQueryKeys.dayAccess, queryFn: () => getParticipantRepository().listDayAccess(), enabled });
}

export function useParticipantSubmissions(enabled: boolean) {
  return useQuery({ queryKey: participantQueryKeys.submissions, queryFn: () => getParticipantRepository().listSubmissions(), enabled });
}

export function useParticipantScores(enabled: boolean) {
  return useQuery({ queryKey: participantQueryKeys.scores, queryFn: () => getParticipantRepository().listScores(), enabled });
}

export function useParticipantAssignedCoach(enabled: boolean) {
  return useQuery({ queryKey: participantQueryKeys.coach, queryFn: () => getParticipantRepository().getAssignedCoach(), enabled });
}

export function useSubmitParticipantAnswers() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (command: ParticipantAnswerSubmissionCommand) => getParticipantRepository().submitAnswers(command),
    onSettled: async () => {
      await Promise.all([
        queryClient.invalidateQueries({ queryKey: participantQueryKeys.submissions }),
        queryClient.invalidateQueries({ queryKey: participantQueryKeys.scores }),
      ]);
    },
  });
}

export function useSubmitParticipantWeighIn() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (command: ParticipantWeighInCommand) => getParticipantRepository().submitWeighIn(command),
    onSettled: async () => {
      await Promise.all([
        queryClient.invalidateQueries({ queryKey: participantQueryKeys.submissions }),
        queryClient.invalidateQueries({ queryKey: participantQueryKeys.scores }),
      ]);
    },
  });
}
