import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { getCoachReviewRepository } from './coach-review-repository';

export const coachReviewQueryKey = ['private', 'coach', 'reviews'] as const;

export function useCoachReviews(enabled: boolean) {
  return useQuery({ queryKey: coachReviewQueryKey, queryFn: () => getCoachReviewRepository().listReviews(), enabled });
}

export function useCoachReviewDecision() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (command: { submissionId: string; decision: 'approved' | 'rejected'; reason?: string; idempotencyKey: string }) => getCoachReviewRepository().decide(command),
    onSettled: async () => {
      await queryClient.invalidateQueries({ queryKey: coachReviewQueryKey });
    },
  });
}

