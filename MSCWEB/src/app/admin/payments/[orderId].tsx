import { useLocalSearchParams } from 'expo-router';

import { AdminPaymentDetail } from '@/features/payment/AdminPaymentComponents';
import { AppShell } from '@/shared/navigation/AppShell';

export default function AdminPaymentDetailRoute() {
  const params = useLocalSearchParams<{ orderId?: string }>();
  const orderId = typeof params.orderId === 'string' ? params.orderId : '';
  return <AppShell role="admin" activeRoute="dashboard" title="Detail pembayaran"><AdminPaymentDetail orderId={orderId} /></AppShell>;
}
