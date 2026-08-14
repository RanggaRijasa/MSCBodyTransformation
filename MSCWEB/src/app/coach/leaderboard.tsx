import { CoachLeaderboardExperience } from '@/features/leaderboard/LeaderboardExperience';
import { useAuth } from '@/shared/auth/AuthProvider';
import { AppShell } from '@/shared/navigation/AppShell';

export default function CoachLeaderboardRoute() {
  const { state } = useAuth();
  const authorized = state.status === 'authenticated' && state.account.role === 'coach';
  return <AppShell role="coach" activeRoute="dashboard" title="Peringkat"><CoachLeaderboardExperience authorized={authorized} /></AppShell>;
}
