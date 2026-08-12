import type { AdminDashboardSnapshot } from "@/domain/admin/admin-operations";
import {
  createProgramDateTimeFormatter,
  formatNumber,
} from "@/shared/formatting/indonesian-formatters";
import { AppIcon } from "@/shared/ui/icons/app-icon";
import { AppLink } from "@/shared/ui/controls/actions";
import { Metric } from "@/shared/ui/status/status";
import { ListRow, SectionHeading, Surface } from "@/shared/ui/surfaces/surfaces";

export function AdminDashboard({ snapshot }: Readonly<{ snapshot: AdminDashboardSnapshot }>) {
  const dateTime = createProgramDateTimeFormatter("Asia/Jakarta");
  return (
    <div className="admin-page admin-dashboard">
      <header className="admin-page__header">
        <h1>Dashboard</h1>
        <p>Kendali operasional hari ini tanpa membuka data privat yang tidak diperlukan.</p>
      </header>

      <div className="admin-dashboard__grid">
        <div className="admin-dashboard__primary">
          <section aria-label="Perlu tindakan">
            <SectionHeading title="Perlu tindakan" />
            <Surface className="admin-action-list" elevated>
              <article className="admin-action-row">
                <span className="admin-action-row__icon">
                  <AppIcon name="warning" />
                </span>
                <div>
                  <h3>Program perlu ditutup</h3>
                  <p>Periksa hambatan sebelum mengunci hasil.</p>
                </div>
                <strong className="admin-action-row__count monospaced-numeric">
                  {formatNumber.format(snapshot.closureBlockers)}
                </strong>
                <AppLink
                  className="admin-action-row__link"
                  href="/admin/program?status=completed"
                  variant="secondary"
                >
                  Buka program <AppIcon name="chevron" />
                </AppLink>
              </article>
              <article className="admin-action-row">
                <span className="admin-action-row__icon">
                  <AppIcon name="coach" />
                </span>
                <div>
                  <h3>Pengajuan Coach</h3>
                  <p>Kelayakan akun baru perlu ditinjau.</p>
                </div>
                <strong className="admin-action-row__count monospaced-numeric">
                  {formatNumber.format(snapshot.coachApplications)}
                </strong>
                <AppLink
                  className="admin-action-row__link"
                  href="/admin/orang?bagian=pengajuan"
                  variant="secondary"
                >
                  Tinjau pengajuan <AppIcon name="chevron" />
                </AppLink>
              </article>
              <article className="admin-action-row">
                <span className="admin-action-row__icon admin-action-row__icon--payment">
                  <AppIcon name="payment" />
                </span>
                <div>
                  <h3>Pembayaran menunggu</h3>
                  <p>Bukti transfer perlu diperiksa.</p>
                </div>
                <strong className="admin-action-row__count monospaced-numeric">
                  {formatNumber.format(snapshot.paymentReviews)}
                </strong>
                <AppLink
                  className="admin-action-row__link"
                  href="/admin/pembayaran"
                  variant="secondary"
                >
                  Buka antrean <AppIcon name="chevron" />
                </AppLink>
              </article>
            </Surface>
          </section>

          <section>
            <SectionHeading title="Akses cepat" />
            <div className="admin-quick-actions">
              <AppLink href="/admin/program/baru" icon="program">
                Buat program
              </AppLink>
              <AppLink href="/admin/konten#tambah-poster" icon="content" variant="secondary">
                Tambah poster
              </AppLink>
            </div>
          </section>
        </div>

        <div className="admin-dashboard__secondary">
          <section aria-label="Gambaran hari ini">
            <SectionHeading title="Gambaran hari ini" />
            <Surface className="admin-overview">
              <Metric label="Program aktif" value={formatNumber.format(snapshot.activePrograms)} />
              <Metric
                label="Perlu ditinjau"
                value={formatNumber.format(snapshot.systemAttention)}
              />
              <Metric label="Belum dikunci" value={formatNumber.format(snapshot.closureBlockers)} />
              <p className="admin-overview__note">
                <AppIcon name="info" />
                Ringkasan tidak menampilkan data privat peserta.
              </p>
            </Surface>
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
                    icon="program"
                    key={item.id}
                    title={item.kind}
                  />
                ))
            ) : (
              <p className="admin-empty-copy">Belum ada aktivitas Admin yang dapat ditampilkan.</p>
            )}
          </Surface>
        </div>
      </div>
    </div>
  );
}
