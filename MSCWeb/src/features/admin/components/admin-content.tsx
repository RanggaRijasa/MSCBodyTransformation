import type { AdminWinnerPoster, AdminWinnerSnapshot } from "@/domain/admin/admin-operations";
import { managePosterAction } from "@/application/admin/admin-mutations";
import { AdminPosterUploader } from "@/features/admin/components/admin-poster-uploader";
import { AppButton } from "@/shared/ui/controls/actions";
import { StateMessage, StatusBadge } from "@/shared/ui/status/status";
import { Surface } from "@/shared/ui/surfaces/surfaces";
import { MediaSurface } from "@/shared/ui/media/media-surface";

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
      <section aria-labelledby="admin-posters-title">
        <div className="admin-section-intro">
          <div>
            <h2 id="admin-posters-title">Galeri poster</h2>
            <p>Media publik selalu terikat pada snapshot hasil yang sudah dikunci.</p>
          </div>
          <strong className="admin-result-count monospaced-numeric">{posters.length}</strong>
        </div>
        <div className="admin-poster-grid">
          {posters.length ? (
            posters.map((poster) => (
              <Surface className="admin-poster-card" key={poster.id}>
                <MediaSurface
                  alt={poster.alternativeText}
                  aspect="portrait"
                  src={poster.imageUrl}
                />
                <StatusBadge tone={poster.isPublished ? "success" : "neutral"}>
                  {poster.isPublished ? "Diterbitkan" : "Draft"}
                </StatusBadge>
                <h2>{poster.programTitle}</h2>
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
            <StateMessage
              description="Tambahkan poster setelah snapshot pemenang dikunci."
              title="Belum ada poster"
            />
          )}
        </div>
      </section>
      <div id="tambah-poster">
        <Surface className="admin-poster-form">
          <h2>Tambah poster</h2>
          <AdminPosterUploader mode="add" snapshots={snapshots} />
        </Surface>
      </div>
    </div>
  );
}
