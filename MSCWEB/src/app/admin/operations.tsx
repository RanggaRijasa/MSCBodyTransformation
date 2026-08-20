import { AdminEvidenceOperations } from '@/features/admin/AdminOperationsComponents';
import { useAuth } from '@/shared/auth/AuthProvider';
import { AppShell } from '@/shared/navigation/AppShell';

export default function AdminOperationsRoute() {
  const { state } = useAuth();
  const authorized = state.status === 'authenticated' && state.account.role === 'admin';
  return <AppShell role="admin" activeRoute="dashboard" title="Operasi"><AdminEvidenceOperations authorized={authorized} /></AppShell>;
}
