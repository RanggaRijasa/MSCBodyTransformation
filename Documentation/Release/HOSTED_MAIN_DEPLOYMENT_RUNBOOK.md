# Hosted Main Deployment Runbook

Runbook ini digunakan hanya setelah owner memberi approval production yang
secara eksplisit menyebut hosted Supabase `main`.

## Preflight read-only

1. Catat project ref, organization, region, Postgres version, dan maintenance
   window tanpa menyalin secret ke log.
2. Jalankan `supabase --version` serta `supabase db push --help` untuk
   memverifikasi CLI/flag pada hari deployment.
3. Bandingkan migration history lokal dan hosted. Hentikan deployment bila
   terdapat migration hosted yang tidak dikenal.
4. Review diff untuk memastikan tidak ada seed, local product ID, fixture,
   test account, destructive rewrite, atau credential.
5. Konfirmasi backup/snapshot terakhir dan tulis forward-fix untuk setiap
   migration yang akan dikirim.
6. Pastikan asymmetric JWT signing aktif, publishable/secret key modern siap,
   dan legacy `anon`/`service_role` yang pernah terekspos sudah dinonaktifkan.
7. Periksa database SSL enforcement dan allowlist koneksi database langsung.
   Jangan membuka Data API dengan mematikan RLS.

## Deployment

1. Link ke project ref yang telah dikonfirmasi.
2. Push migration berurutan. Jangan memakai reset atau seed.
3. Deploy Edge Functions satu per satu dan pasang secret melalui approved
   secret management tanpa mencetak nilai. Gunakan Supabase secret key modern;
   jangan menyalin legacy `service_role` ke function secret baru.
4. Konfigurasi Auth provider, redirect allowlist, jobs, dan webhook hanya dari
   nilai yang telah diverifikasi.
5. Provision pemetaan produk production secara idempoten.
6. Aktifkan database SSL enforcement dan restriction yang disetujui owner
   setelah memastikan CLI/operational access tetap tersedia.

## Verification

1. Bandingkan migration history dan schema diff kembali.
2. Jalankan database lint, RLS/grant/storage smoke, dan Security Advisor.
3. Jalankan function health check serta cek cron/job observability.
4. Uji Guest projection, authenticated authorization, OAuth lifecycle,
   StoreKit sandbox, Notification V2 TEST, dan account deletion memakai akun
   test tanpa data pribadi nyata.
5. Jalankan redaction scan terhadap log dan artifact Release.

## Failure handling

- Jangan reset production.
- Hentikan langkah berikutnya bila satu verification gate gagal.
- Pulihkan dengan forward-fix yang telah direview; gunakan restore hanya
  sesuai backup plan yang disetujui owner.
- Rotasi credential bila ada indikasi secret tampil di log atau terminal.
- Bila legacy key tampil pada output, anggap terekspos, rotasi/nonaktifkan,
  pindahkan consumer ke publishable/secret key modern, lalu uji ulang Auth dan
  Functions sebelum membuka traffic.
- Catat waktu, migration/function terkait, dampak, dan hasil pemulihan tanpa
  menyalin payload sensitif.

## Baseline operasional 9 Agustus 2026

- Change window berlangsung secara attended pada 9 Agustus 2026. Setiap jenis
  mutation production mendapat approval owner sebelum dijalankan.
- Enam physical backup harian terakhir berstatus `COMPLETED`; backup paling
  dekat sebelum recurring-operation deployment dibuat pada 8 Agustus 2026
  20:44 UTC. WAL-G aktif dan PITR tidak aktif.
- Recovery utama untuk migration/function adalah forward fix, bukan rollback
  destruktif. Physical restore hanya digunakan bila forward fix tidak dapat
  memulihkan availability atau integritas data dan harus mendapat approval
  production baru.
- Failure drill nyata terjadi pada migration ke-19: validasi URL menolak semua
  dispatch sebelum HTTP request dikirim. Tidak ada data yang dimutasi oleh
  worker. Migration ke-20 memperbaiki regex secara forward-only, lalu cron
  identitas mencapai worker dengan `200`.
- Sebelum restore, hentikan mutation lanjutan, simpan migration/function
  evidence yang sudah direduksi, verifikasi timestamp backup target, lalu
  lakukan restore hanya melalui prosedur resmi Supabase. Jangan menjalankan
  `db reset`, seed, atau menghapus migration history hosted.
