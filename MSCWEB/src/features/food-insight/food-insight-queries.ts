import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { getFoodInsightRepository } from './food-insight-repository';
import type { FoodInsightResult } from './food-insight-models';

export const foodInsightQueryKey = (submissionId: string) => ['private', 'food-insight', submissionId] as const;

export function useFoodInsight(submissionId?: string) {
  return useQuery({
    queryKey: foodInsightQueryKey(submissionId ?? 'none'),
    queryFn: () => getFoodInsightRepository().getForSubmission(submissionId ?? ''),
    enabled: Boolean(submissionId),
    refetchInterval: (query) => {
      if (query.state.data === null) return 2_000;
      const status = query.state.data?.job.status;
      return status && ['queued', 'processing', 'retry_scheduled'].includes(status) ? 2_000 : false;
    },
  });
}

export function useCorrectFoodInsight() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (command: { result: FoodInsightResult; rating: number; reason: string; idempotencyKey: string }) => getFoodInsightRepository().correctRating(command),
    onSuccess: async (_, command) => queryClient.invalidateQueries({ queryKey: foodInsightQueryKey(command.result.submission_id) }),
  });
}
