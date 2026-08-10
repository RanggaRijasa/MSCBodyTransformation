import type { AdminProgramListItem, AdminProgramStatus } from "@/domain/admin/admin-program";
import {
  formatCurrencyIDR,
  formatNumber,
  formatProgramDate,
} from "@/shared/formatting/indonesian-formatters";
import { AppButton, AppLink, StatusBadge, Surface } from "@/shared/ui";

const statusLabels: Record<AdminProgramStatus, string> = {
  active: "Aktif",
  archived: "Diarsipkan",
  completed: "Selesai",
  draft: "Draft",
  scheduled: "Terjadwal",
};

export function AdminProgramList({
  items,
  page = 1,
  query,
  status,
}: Readonly<{
  items: readonly AdminProgramListItem[];
  page?: number;
  query: string;
  status: string;
}>) {
  const filtered = items.filter(
    (item) =>
      (!query ||
        item.title.toLocaleLowerCase("id-ID").includes(query.toLocaleLowerCase("id-ID"))) &&
      (!status || item.status === status),
  );
  const pageSize = 12;
  const start = (page - 1) * pageSize;
  const visible = filtered.slice(start, start + pageSize);
  const pageHref = (target: number) => {
    const values = new URLSearchParams();
    if (query) values.set("q", query);
    if (status) values.set("status", status);
    values.set("halaman", String(target));
    return `/admin/program?${values.toString()}`;
  };
  return (
    <div className="admin-page">
      <header className="admin-page__header admin-page__header--action">
        <div>
          <p className="admin-eyebrow">CMS program</p>
          <h1>Program</h1>
          <p>Kelola draft dan jalankan lifecycle melalui operasi terlindungi.</p>
        </div>
        <AppLink href="/admin/program/baru">Buat program baru</AppLink>
      </header>
      <Surface className="admin-filter-bar">
        <form action="/admin/program" method="get">
          <label>
            Cari program
            <input defaultValue={query} name="q" placeholder="Nama program" type="search" />
          </label>
          <label>
            Status
            <select defaultValue={status} name="status">
              <option value="">Semua status</option>
              {Object.entries(statusLabels).map(([value, label]) => (
                <option key={value} value={value}>
                  {label}
                </option>
              ))}
            </select>
          </label>
          <AppButton type="submit">Terapkan</AppButton>
          <AppLink href="/admin/program" variant="secondary">
            Hapus filter
          </AppLink>
        </form>
      </Surface>
      <div className="admin-program-grid" aria-label="Daftar program">
        {visible.length ? (
          visible.map((item) => (
            <Surface className="admin-program-card" key={item.id}>
              <div>
                <StatusBadge
                  tone={
                    item.status === "active"
                      ? "success"
                      : item.status === "draft"
                        ? "warning"
                        : "neutral"
                  }
                >
                  {statusLabels[item.status]}
                </StatusBadge>
                <h2>{item.title}</h2>
                <p>
                  {formatProgramDate(item.startsOn, "Asia/Makassar")}–
                  {formatProgramDate(item.endsOn, "Asia/Makassar")}
                </p>
              </div>
              <dl>
                <div>
                  <dt>Peserta</dt>
                  <dd className="monospaced-numeric">
                    {formatNumber.format(item.enrollmentCount)}
                    {item.participantLimit ? `/${formatNumber.format(item.participantLimit)}` : ""}
                  </dd>
                </div>
                <div>
                  <dt>Harga</dt>
                  <dd>
                    {item.pricingMode === "paid"
                      ? formatCurrencyIDR.format(Number(item.desiredPrice ?? 0))
                      : "Gratis"}
                  </dd>
                </div>
              </dl>
              <AppLink href={`/admin/program/${item.id}`} variant="secondary">
                Buka program
              </AppLink>
            </Surface>
          ))
        ) : (
          <Surface>
            <h2>Tidak ada program</h2>
            <p>Ubah filter atau buat draft program baru.</p>
          </Surface>
        )}
      </div>
      {filtered.length > pageSize ? (
        <nav aria-label="Halaman program" className="admin-pagination">
          {page > 1 ? (
            <AppLink href={pageHref(page - 1)} variant="secondary">
              Halaman sebelumnya
            </AppLink>
          ) : null}
          <span className="monospaced-numeric">Halaman {page}</span>
          {start + pageSize < filtered.length ? (
            <AppLink href={pageHref(page + 1)} variant="secondary">
              Halaman berikutnya
            </AppLink>
          ) : null}
        </nav>
      ) : null}
    </div>
  );
}
