# MSCWEB archive handoff

Tanggal cutover: `24 Agustus 2026`

## Status

Repository ini dipertahankan sebagai arsip historis. Folder `MSCWEB/` dan
repository-root `supabase/` di sini bukan lagi sumber deployment dan tidak
boleh digunakan untuk perubahan produksi Cloudflare atau Supabase.

Deployment authority tunggal setelah W09 adalah:

- repository: <https://github.com/RanggaRijasa/MSCWEB>;
- branch: `main`;
- commit cutover terverifikasi: `9a70721229e06c24590afef771e7053b376b7765`;
- Supabase authority: satu folder `supabase/` pada root repository standalone.

## Aturan setelah cutover

- Kerjakan web, PWA, Worker, migration, Edge Function, dan W10 hanya di
  repository standalone.
- Jangan menjalankan deploy Cloudflare atau Supabase dari arsip ini.
- Jangan menambahkan workflow deployment atau production secret ke arsip ini.
- Source lama tetap disimpan untuk rollback historis dan audit; penghapusannya
  memerlukan otorisasi destruktif terpisah.
- Perubahan native lama, bila masih diperlukan untuk audit, tetap terpisah dan
  tidak mengembalikan authority web/backend ke repository ini.

## Bukti handoff

W09 memindahkan 48 migration secara utuh dan mempertahankan urutan serta isi
historisnya. Fresh clone repository standalone lulus build production,
typecheck, lint, 213 unit test, 423 pgTAP assertion, 9 integration test, dan 13
pemeriksaan runtime Edge Function. Linked migration dry-run menyatakan
production up to date. Hosted Supabase tidak di-reset atau dibuat ulang.

Fase berikutnya adalah W10 CI/CD di repository standalone.
