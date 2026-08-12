import { RoleShellScreen } from '@/shared/navigation/RoleShellScreen';

export default function PublicLeaderboardRoute() {
  return <RoleShellScreen role="guest" activeRoute="leaderboard" title="Peringkat" description="Papan peringkat publik tidak akan menampilkan berat badan atau data privat Peserta." />;
}
