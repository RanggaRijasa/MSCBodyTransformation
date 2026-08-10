import type { AdminDashboardSnapshot } from "@/domain/admin/admin-operations";
import {
  createProgramDateTimeFormatter,
  formatNumber,
} from "@/shared/formatting/indonesian-formatters";
import { AppLink, ListRow, Metric, SectionHeading, Surface } from "@/shared/ui";

export function AdminDashboard({ snapshot }: Readonly<{ snapshot: AdminDashboardSnapshot }>) {
  const dateTime = createProgramDateTimeFormatter("Asia/Jakarta");
  return (
    <div className="admin-page admin-dashboard">
      <header className="admin-page__header">
        <p className="admin-eyebrow">Ringkasan operasional</p>
        <h1>Dashboard Admin</h1>
        <p>Tinjau pekerjaan penting tanpa membuka data privat yang tidak diperlukan.</p>
      </header>

      <section aria-labelledby="admin-actions-title">
        <SectionHeading title="Perlu tindakan" />
        <div className="admin-metric-grid" id="admin-actions-title">
          <Surface>
            <Metric label="Pembayaran" value={formatNumber.format(snapshot.paymentReviews)} />
            <AppLink href="/admin/pembayaran" variant="secondary">
              Buka antrean
            </AppLink>
          </Surface>
          <Surface>
            <Metric
              label="Pengajuan Coach"
              value={formatNumber.format(snapshot.coachApplications)}
            />
            <AppLink href="/admin/orang?bagian=pengajuan" variant="secondary">
              Tinjau pengajuan
            </AppLink>
          </Surface>
          <Surface>
            <Metric label="Perlu perhatian" value={formatNumber.format(snapshot.systemAttention)} />
            <AppLink href="/admin/program?status=completed" variant="secondary">
              Buka penutupan
            </AppLink>
          </Surface>
          <Surface>
            <Metric label="Program aktif" value={formatNumber.format(snapshot.activePrograms)} />
            <span className="admin-metric-note">
              {formatNumber.format(snapshot.closureBlockers)} penutupan belum dikunci
            </span>
          </Surface>
        </div>
      </section>

      <section>
        <SectionHeading title="Tindakan cepat" />
        <div className="admin-quick-actions">
          <AppLink href="/admin/program/baru">Buat program</AppLink>
          <AppLink href="/admin/konten#tambah-poster" variant="secondary">
            Tambah poster
          </AppLink>
        </div>
      </section>

      <Surface className="admin-audit-preview">
        <SectionHeading
          action={
            <AppLink href="/admin/pengaturan#audit" variant="secondary">
              Lihat audit
            </AppLink>
          }
          title="Aktivitas terbaru"
        />
        {snapshot.recentAudit.length ? (
          snapshot.recentAudit
            .slice(0, 3)
            .map((item) => (
              <ListRow
                detail={`${item.reason} • ${dateTime.format(new Date(item.occurredAt))}`}
                key={item.id}
                title={item.kind}
              />
            ))
        ) : (
          <p>Belum ada aktivitas Admin yang dapat ditampilkan.</p>
        )}
      </Surface>
    </div>
  );
}
