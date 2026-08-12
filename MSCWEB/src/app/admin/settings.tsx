import { RoleShellScreen } from '@/shared/navigation/RoleShellScreen';

export default function AdminSettingsRoute() {
  return <RoleShellScreen role="admin" activeRoute="settings" title="Pengaturan" description="Pengaturan web akan ditambahkan hanya bila relevan dan terotorisasi." />;
}
