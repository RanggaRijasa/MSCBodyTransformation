import type { AdminWinnerPoster, AdminWinnerSnapshot } from "@/domain/admin/admin-operations";
import { managePosterAction } from "@/application/admin/admin-mutations";
import { AdminPosterUploader } from "@/features/admin/components/admin-poster-uploader";
import { AppButton, StatusBadge, Surface } from "@/shared/ui";

export function AdminContent({
  posters,
  snapshots,
}: Readonly<{
  posters: readonly AdminWinnerPoster[];
  snapshots: readonly AdminWinnerSnapshot[];
}>) {
  return (
    <div className="admin-page">
      <header className="admin-page__header">
        <p className="admin-eyebrow">Konten terkelola</p>
        <h1>Poster pemenang</h1>
        <p>
          Poster selalu merujuk snapshot pemenang yang dikunci; galeri tidak dapat mengubah
          peringkat.
        </p>
      </header>
      <div className="admin-poster-grid">
        {posters.length ? (
          posters.map((poster) => (
            <Surface className="admin-poster-card" key={poster.id}>
              <div className="admin-poster-preview">
                <span>9:16</span>
                <p>{poster.alternativeText}</p>
              </div>
              <StatusBadge tone={poster.isPublished ? "success" : "neutral"}>
                {poster.isPublished ? "Diterbitkan" : "Draft"}
              </StatusBadge>
              <h2>{poster.programTitle}</h2>
              <p className="admin-path">{poster.mediaPath}</p>
              <form action={managePosterAction}>
                <input name="posterId" type="hidden" value={poster.id} />
                <input
                  name="reason"
                  type="hidden"
                  value={
                    poster.isPublished
                      ? "Poster dihapus dari publikasi."
                      : "Poster diterbitkan setelah pratinjau."
                  }
                />
                <AppButton
                  name="operation"
                  type="submit"
                  value={poster.isPublished ? "delete" : "publish"}
                  variant={poster.isPublished ? "destructive" : "primary"}
                >
                  {poster.isPublished ? "Hapus poster" : "Terbitkan poster"}
                </AppButton>
              </form>
              <details>
                <summary>Ganti media poster</summary>
                <AdminPosterUploader mode="replace" posterId={poster.id} />
              </details>
            </Surface>
          ))
        ) : (
          <Surface>
            <h2>Belum ada poster</h2>
            <p>Tambahkan poster setelah snapshot pemenang dikunci.</p>
          </Surface>
        )}
      </div>
      <div id="tambah-poster">
        <Surface className="admin-poster-form">
          <h2>Tambah poster</h2>
          <AdminPosterUploader mode="add" snapshots={snapshots} />
        </Surface>
      </div>
    </div>
  );
}
