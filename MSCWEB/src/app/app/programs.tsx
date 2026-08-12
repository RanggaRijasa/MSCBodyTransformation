import { RoleShellScreen } from '@/shared/navigation/RoleShellScreen';

export default function PublicProgramsRoute() {
  return <RoleShellScreen role="guest" activeRoute="programs" title="Program" description="Program publik akan ditampilkan melalui read model yang aman pada W02." />;
}
