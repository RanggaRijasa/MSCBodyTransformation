import type { AdminAuditItem } from "@/domain/admin/admin-operations";
import { createProgramDateTimeFormatter } from "@/shared/formatting/indonesian-formatters";
import { ListRow, SectionHeading, StatusBadge, Surface } from "@/shared/ui";

export function AdminSettings({
  audit,
  environment,
  siteUrl,
}: Readonly<{ audit: readonly AdminAuditItem[]; environment: string; siteUrl: string }>) {
  const formatter = createProgramDateTimeFormatter("Asia/Jakarta");
  return (
    <div className="admin-page">
      <header className="admin-page__header">
        <p className="admin-eyebrow">Konfigurasi aktual</p>
        <h1>Pengaturan</h1>
        <p>
          Nilai berikut dibaca dari runtime aman dan tidak dapat diedit menjadi konfigurasi fiktif.
        </p>
      </header>
      <div className="admin-settings-grid">
        <Surface>
          <h2>Lingkungan aplikasi</h2>
          <dl>
            <div>
              <dt>Lingkungan</dt>
              <dd>
                <StatusBadge tone={environment === "production" ? "success" : "warning"}>
                  {environment}
                </StatusBadge>
              </dd>
            </div>
            <div>
              <dt>Alamat situs</dt>
              <dd>{siteUrl}</dd>
            </div>
            <div>
              <dt>Locale produk</dt>
              <dd>Bahasa Indonesia (id-ID)</dd>
            </div>
            <div>
              <dt>Zona operasional default</dt>
              <dd>Asia/Makassar (WITA)</dd>
            </div>
          </dl>
        </Surface>
        <Surface>
          <h2>Kebijakan operasional</h2>
          <ul>
            <li>Pembayaran diverifikasi manual oleh Admin.</li>
            <li>Persetujuan Coach terpisah dari verifikasi pembayaran.</li>
            <li>Bukti pembayaran disimpan privat dan tidak masuk cache publik.</li>
            <li>Pengaturan rahasia tidak ditampilkan pada halaman ini.</li>
          </ul>
        </Surface>
      </div>
      <div id="audit">
        <Surface className="admin-audit-list">
          <SectionHeading title="Audit terbaru" />
          {audit.length ? (
            audit.map((item) => (
              <ListRow
                detail={`${item.actorLabel} • ${formatter.format(new Date(item.occurredAt))} • ${item.reason}`}
                key={item.id}
                title={item.kind}
              />
            ))
          ) : (
            <p>Belum ada audit yang dapat ditampilkan.</p>
          )}
        </Surface>
      </div>
    </div>
  );
}
