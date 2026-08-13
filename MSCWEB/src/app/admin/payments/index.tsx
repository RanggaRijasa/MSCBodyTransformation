import { AdminPaymentQueue } from '@/features/payment/AdminPaymentComponents';
import { useAdminPaymentQueue } from '@/features/payment/payment-queries';
import { useAuth } from '@/shared/auth/AuthProvider';
import { AppShell } from '@/shared/navigation/AppShell';
import { Button, StateView } from '@/shared/ui/primitives';

export default function AdminPaymentsRoute() {
  const { state } = useAuth();
  const authorized = state.status === 'authenticated' && state.account.role === 'admin';
  const payments = useAdminPaymentQueue(authorized);
  return (
    <AppShell role="admin" activeRoute="dashboard" title="Pembayaran">
      {!authorized ? <StateView kind="forbidden" /> : payments.isPending ? <StateView kind="loading" /> : payments.isError ? <StateView kind="error" action={<Button label="Coba lagi" onPress={() => void payments.refetch()} />} /> : <AdminPaymentQueue items={payments.data ?? []} onRetry={() => void payments.refetch()} />}
    </AppShell>
  );
}
