import { Skeleton, Surface } from "@/shared/ui";

export default function AdminLoading() {
  return (
    <div aria-busy="true" className="admin-page admin-loading">
      <header className="admin-page__header">
        <p className="admin-eyebrow">Memuat area Admin</p>
        <h1>Menyiapkan halaman</h1>
        <p>Data operasional sedang dimuat melalui akses yang terlindungi.</p>
      </header>
      <div className="admin-loading__grid">
        {Array.from({ length: 3 }, (_, index) => (
          <Surface key={index}>
            <Skeleton label={`Memuat bagian Admin ${index + 1}`} />
          </Surface>
        ))}
      </div>
    </div>
  );
}
