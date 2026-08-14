import { ParticipantLeaderboardExperience } from '@/features/leaderboard/LeaderboardExperience';
import { useAuth } from '@/shared/auth/AuthProvider';
import { AppShell } from '@/shared/navigation/AppShell';

export default function PublicLeaderboardRoute() {
  const { state } = useAuth();
  const role = state.status === 'authenticated' ? state.account.role : 'guest';
  return (
    <AppShell role={role} activeRoute="leaderboard" title="Peringkat">
      <ParticipantLeaderboardExperience enabled={role === 'participant'} />
    </AppShell>
  );
}
