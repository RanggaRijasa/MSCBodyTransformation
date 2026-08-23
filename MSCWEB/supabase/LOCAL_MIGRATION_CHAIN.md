# Authority migrasi dan Function Supabase MSCWEB

Satu-satunya deployment authority adalah folder repository-root `supabase/`.
Migrasi web berada di `supabase/migrations/` dan Edge Function web berada di
`supabase/functions/`. Folder `MSCWEB/supabase/` hanya memuat dokumentasi,
konfigurasi lokal yang diabaikan Git, serta utilitas development non-deployment.

Gunakan perintah Supabase CLI hanya dari repository root:

```sh
supabase migration list --local
supabase db reset --local
supabase db push --linked --dry-run
```

`supabase db reset --local` bersifat destruktif untuk database lokal dan hanya
boleh dijalankan setelah target lokal diverifikasi serta owner mengizinkan reset.
Hosted `main` tidak boleh menerima file SQL melalui script ad-hoc atau `psql`;
semua deployment harus melalui history migration root yang telah direview.

## W09 standalone-repository cutover

Sesuai `decisions/0011-web-only-repository-and-supabase-authority.md`, iOS tidak
lagi menjadi release target. Pada W09, seluruh repository-root `supabase/`
dipindahkan sebagai satu unit ke root repository MSCWEB standalone. Pemindahan
mencakup seluruh migration history, Edge Functions dan shared modules, database
tests, `config.toml`, serta runbook operasional. Migration lama tidak boleh
di-squash, di-rebaseline, dinomori ulang, atau dipilih sebagian selama split.

Setelah cutover, hanya repository MSCWEB yang boleh menjalankan deployment
Supabase. Repository iOS menjadi arsip tanpa pipeline atau credential production
aktif. Salinan sementara selama validation window adalah backup non-deployable,
bukan migration authority kedua.

Sebelum W09 cutover, Worker receipt cancellation lokal dijalankan dari
monorepo dengan:

```sh
MSCWEB/scripts/run-local-provisional-cleanup.sh
```

Setelah cutover ke repository MSCWEB standalone, path-nya menjadi:

```sh
scripts/run-local-provisional-cleanup.sh
```

Script tersebut juga menolak target non-lokal, menghapus objek melalui Storage
API, mencabut seluruh session, menghapus Auth identity, dan menyelesaikan receipt.
Untuk development berkelanjutan, jalankan setelah test cancellation atau dari
supervisor lokal terjadwal. Aktivasi hosted scheduler/Edge Function tetap butuh
otorisasi production terpisah.

Untuk membuktikan schema bersih tanpa memengaruhi data pengembangan utama,
gunakan stack Supabase lokal terpisah. Tidak ada lagi script yang menerapkan
rantai migrasi web kedua.
