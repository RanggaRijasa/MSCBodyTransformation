import { AppShell } from '@/shared/navigation/AppShell';
import { useAuth } from '@/shared/auth/AuthProvider';
import { useCoachReviews } from '@/features/coach/coach-review-queries';
import { CoachReviewQueue } from '@/features/coach/CoachReviewComponents';
import { Button, StateView } from '@/shared/ui/primitives';

export default function CoachReviewsRoute() {
  const { state } = useAuth();
  const authorized = state.status === 'authenticated' && state.account.role === 'coach';
  const reviews = useCoachReviews(authorized);
  return (
    <AppShell role="coach" activeRoute="dashboard" title="Periksa bukti">
      {!authorized ? <StateView kind="forbidden" /> : reviews.isPending ? <StateView kind="loading" /> : reviews.isError ? <StateView kind="error" action={<Button label="Coba lagi" onPress={() => void reviews.refetch()} />} /> : <CoachReviewQueue items={reviews.data ?? []} onRetry={() => void reviews.refetch()} />}
    </AppShell>
  );
}
