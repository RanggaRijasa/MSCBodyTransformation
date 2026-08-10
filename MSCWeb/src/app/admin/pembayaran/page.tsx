import type { Metadata } from "next";

import {
  listAdminPaymentQueueOperation,
  listPaymentDestinationsOperation,
} from "@/application/payments/payment-operations";
import {
  isPaymentOrderStatus,
  type AdminPaymentQueueFilters,
  type PaymentOrderStatus,
  type PaymentPurpose,
} from "@/domain/payments/payment";
import { requireRole } from "@/features/auth/server/session-routing";
import { AdminPaymentQueue } from "@/features/payments";
import { AdminPaymentDestinations } from "@/features/payments/components/admin-payment-destinations";
import { StateMessage } from "@/shared/ui";

export const metadata: Metadata = { title: "Pembayaran" };

function first(value: string | string[] | undefined) {
  return Array.isArray(value) ? value[0] : value;
}

function filtersFrom(
  search: Readonly<Record<string, string | string[] | undefined>>,
): AdminPaymentQueueFilters {
  const purposeValue = first(search.jenis);
  const statusValue = first(search.status);
  const from = first(search.dari);
  const to = first(search.sampai);
  const validDate = (value: string | undefined) =>
    value && /^\d{4}-\d{2}-\d{2}$/.test(value) ? value : undefined;
  const filters: {
    createdFrom?: string;
    createdTo?: string;
    purpose?: PaymentPurpose;
    search?: string;
    status?: PaymentOrderStatus;
  } = {};
  const createdFrom = validDate(from);
  const createdTo = validDate(to);
  if (createdFrom) filters.createdFrom = createdFrom;
  if (createdTo) filters.createdTo = createdTo;
  if (purposeValue === "program_enrollment" || purposeValue === "coach_access")
    filters.purpose = purposeValue;
  if (isPaymentOrderStatus(statusValue)) filters.status = statusValue;
  const searchTerm = first(search.q)?.trim().slice(0, 80);
  if (searchTerm) filters.search = searchTerm;
  return filters;
}

export default async function AdminPaymentsPage({
  searchParams,
}: Readonly<{
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}>) {
  await requireRole("admin", "/admin/pembayaran");
  const filters = filtersFrom(await searchParams);
  const [queue, destinations] = await Promise.all([
    listAdminPaymentQueueOperation(filters),
    listPaymentDestinationsOperation(),
  ]);
  return queue.isSuccess && destinations.isSuccess ? (
    <div className="payment-page">
      <AdminPaymentQueue filters={filters} items={queue.value} />
      <AdminPaymentDestinations destinations={destinations.value} />
    </div>
  ) : (
    <StateMessage
      description="Antrean belum dapat dimuat. Coba lagi."
      title="Antrean tidak tersedia"
      tone="error"
    />
  );
}
