import type { AdminDashboardSnapshot } from "@/domain/admin/admin-operations";
import type { AdminProgramListItem } from "@/domain/admin/admin-program";
import { AdminDashboard } from "@/features/admin/components/admin-dashboard";
import { AdminProgramList } from "@/features/admin/components/admin-program-list";

const dashboard: AdminDashboardSnapshot = {
  activePrograms: 3,
  closureBlockers: 1,
  coachApplications: 4,
  paymentReviews: 7,
  recentAudit: [
    {
      actorLabel: "Admin",
      id: "audit-gallery-1",
      kind: "Pembayaran diverifikasi",
      occurredAt: "2026-08-10T08:15:00Z",
      reason: "Nominal dan tujuan pembayaran sesuai.",
      subjectId: null,
    },
    {
      actorLabel: "Admin",
      id: "audit-gallery-2",
      kind: "Program diterbitkan",
      occurredAt: "2026-08-10T07:30:00Z",
      reason: "Validasi konten lengkap.",
      subjectId: null,
    },
  ],
  systemAttention: 5,
};

const programs: AdminProgramListItem[] = [
  {
    desiredPrice: "250000",
    endsOn: "2026-08-31",
    enrollmentCount: 42,
    id: "admin-gallery-program-1",
    participantLimit: 50,
    pricingMode: "paid",
    startsOn: "2026-08-01",
    status: "active",
    title: "MSC Agustus",
  },
  {
    desiredPrice: null,
    endsOn: "2026-09-30",
    enrollmentCount: 0,
    id: "admin-gallery-program-2",
    participantLimit: 60,
    pricingMode: "free",
    startsOn: "2026-09-01",
    status: "draft",
    title: "MSC September",
  },
  {
    desiredPrice: "200000",
    endsOn: "2026-07-31",
    enrollmentCount: 38,
    id: "admin-gallery-program-3",
    participantLimit: 40,
    pricingMode: "paid",
    startsOn: "2026-07-01",
    status: "completed",
    title: "MSC Juli",
  },
];

export function AdminGallery() {
  return (
    <div className="state-gallery__stack">
      <div data-testid="admin-dashboard-gallery">
        <AdminDashboard snapshot={dashboard} />
      </div>
      <div data-testid="admin-program-gallery">
        <AdminProgramList items={programs} query="" status="" />
      </div>
    </div>
  );
}
