import { useLocalSearchParams } from 'expo-router';

import { CoachReviewDetail } from '@/features/coach/CoachReviewComponents';
import { AppShell } from '@/shared/navigation/AppShell';

export default function CoachReviewDetailRoute() {
  const params = useLocalSearchParams<{ submissionId?: string }>();
  const submissionId = typeof params.submissionId === 'string' ? params.submissionId : '';
  return (
    <AppShell role="coach" activeRoute="dashboard" title="Periksa bukti">
      <CoachReviewDetail submissionId={submissionId} />
    </AppShell>
  );
}
