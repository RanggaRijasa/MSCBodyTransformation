import { RoleShellScreen } from '@/shared/navigation/RoleShellScreen';

export default function PublicProfileRoute() {
  return <RoleShellScreen role="guest" activeRoute="profile" title="Profil" description="Masuk diperlukan sebelum informasi profil pribadi dapat dimuat." />;
}
