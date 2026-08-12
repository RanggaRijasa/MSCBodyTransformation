import { RoleShellScreen } from '@/shared/navigation/RoleShellScreen';

export default function AdminDashboardRoute() {
  return <RoleShellScreen role="admin" activeRoute="dashboard" title="Dashboard" description="Shell Admin menggunakan navigasi role-ready tanpa metrik atau data operasional palsu." />;
}
