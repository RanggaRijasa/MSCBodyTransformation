# Phase 13 Recurring Operations

Dokumen ini menjelaskan konfigurasi operator tanpa menyimpan nilai secret.

## Worker dan jadwal

| Job | Jadwal UTC | Tujuan |
|---|---:|---|
| `phase13-orphan-question-photo-cleanup` | `12 3 * * *` | Menghapus foto pertanyaan yatim yang lebih lama dari 24 jam melalui Storage API |
| `phase13-apple-identity-reconciliation` | `2-59/15 * * * *` | Memproses retry revoke token dan Apple account events |
| `phase13-apple-commerce-reconciliation` | `7-59/15 * * * *` | Memulihkan missed/refund/revoke commerce events melalui App Store Server API |

Jadwal lama tetap menangani provisional identity cleanup setiap jam dan
commerce reservation/entitlement expiry setiap lima menit.

## Vault input

Buat tepat dua secret melalui Supabase Dashboard **Vault** pada hosted `main`:

1. `phase13_project_url`
   - Nilai: URL HTTPS hosted project.
   - Jangan tambahkan trailing slash.
2. `phase13_edge_function_secret`
   - Nilai: modern project secret key dengan prefix `sb_secret_`.
   - Jangan memakai legacy `service_role` JWT.

Jangan memasukkan nilai tersebut ke migration, source, Git, URL, query string,
cron command, screenshot, chat, atau log. Dispatcher membaca decrypted value
di dalam database hanya saat job berjalan dan mengirim key melalui header
`apikey` ke Edge Function allowlist.

## Urutan deployment

1. Pastikan kedua Vault secret sudah ada.
2. Review migration history dan dry-run ke hosted `main`.
3. Push migration `phase13_recurring_operations`.
4. Redeploy `cleanup-orphan-question-photos` dengan `--no-verify-jwt` karena
   handler menjadi boundary Auth/service-key yang eksplisit.
5. Pastikan ketiga cron job aktif dan command tidak memuat credential.
6. Jalankan tiap job secara manual satu kali melalui
   `private.invoke_phase13_edge_worker(...)` dari SQL editor/operator role.
7. Verifikasi `cron.job_run_details` dan `net._http_response` tanpa mencetak
   request header atau secret.
8. Uji panggilan tanpa credential tetap `401`; Participant cleanup tetap
   `403`; service scheduler mendapat `2xx`.

## Fail-closed behavior

- Worker name di luar allowlist ditolak.
- URL selain hosted Supabase HTTPS ditolak.
- Key tanpa prefix modern `sb_secret_` ditolak.
- Vault input hilang membuat job gagal tanpa fallback ke key legacy.
- `anon`, `authenticated`, dan `service_role` tidak dapat mengeksekusi
  dispatcher private secara langsung melalui Data API.

## Status deployment 9 Agustus 2026

- Migration ke-19, forward fix ke-20, dan tiga cron sudah berada di hosted
  `main`.
- Cleanup function aktif sebagai versi 3 dengan `verify_jwt=false`.
- Kedua nama Vault ada dan validasi bentuk nilainya lulus tanpa menampilkan
  nilai.
- Run pertama menemukan escaping regex URL salah di migration ke-19; worker
  gagal tertutup sebelum mengirim request.
- Forward fix migration ke-20 sudah dideploy. Run identity reconciliation
  sesudah fix mencapai Edge Function dengan respons `200` tanpa timeout.
  Commerce reconciliation juga mencapai Edge Function tanpa timeout lalu
  gagal tertutup dengan `commerce_environment_missing`, sesuai konfigurasi
  App Store Server yang belum dipasang. Cleanup aktif tetapi run harian
  pertamanya masih menunggu jadwal 03:12 UTC berikutnya.
