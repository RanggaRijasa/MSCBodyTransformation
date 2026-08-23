# Supabase Auth production

Status diverifikasi pada 21 Agustus 2026.

## Hosted URL configuration

- Site URL: `https://msc-body-transformation.com`
- Redirect allow-list:
  - `https://msc-body-transformation.com/auth/callback`
  - `mscbodytransformation://auth/callback`
- Google provider: aktif.
- Email/password provider: tidak aktif.

`supabase/config.toml` tetap merupakan konfigurasi Supabase lokal. Nilai
`site_url` localhost di file itu tidak boleh dianggap sebagai Hosted Auth
production dan tidak boleh didorong ke hosted project tanpa review terpisah.

OAuth web memakai PKCE. Aplikasi mengirim callback apex exact dengan return
intent internal yang sudah disanitasi. Hosted Auth harus mempertahankan callback
apex dalam allow-list; jika callback ditolak, Supabase kembali ke Site URL.

## Bootstrap Admin pertama

Semua identity Google baru selalu dibuat sebagai `participant` provisional.
Role tidak pernah diambil dari `user_metadata`, email domain, query string, atau
pilihan UI.

Bootstrap Admin production dilakukan hanya setelah:

1. identity Google exact sudah terbentuk;
2. email cocok dengan `BOOTSTRAP_ADMIN_EMAIL` dari file production-local ignored;
3. owner memberi authorization eksplisit untuk promosi production;
4. operator mencocokkan tepat satu `auth.users.id` dan profile provisional;
5. transaction server-side mengaktifkan profile dan menulis audit bootstrap
   tanpa memasukkan email ke payload audit.

Sesudah promosi, pengguna logout/login ulang dan akses `/admin` diverifikasi.
Tidak boleh ada endpoint browser untuk self-promote atau mengubah role Admin.

### Status bootstrap 21 Agustus 2026

- Identity exact dari `BOOTSTRAP_ADMIN_EMAIL` sudah dipromosikan menjadi
  `admin` dengan `onboarding_status=active` melalui transaksi server-side.
- Audit `production_admin_bootstrap` tercatat satu kali tanpa email di payload.
- Identity untuk `BOOTSTRAP_COACH_EMAIL` sudah dibuat melalui login Google oleh
  owner. Profil, level member, serta pernyataan HOM STS/ICT dan ketentuan Coach
  diisi melalui onboarding; aplikasi Coach tersimpan sebagai `submitted`.
- Pembuatan order berhenti aman karena belum ada tujuan pembayaran production
  aktif. Sesuai waiver owner, tidak dibuat tujuan pembayaran, bukti, transfer,
  commerce transaction, atau ledger.
- Bootstrap Coach kemudian dijalankan server-side: profile menjadi
  `coach/active`, approved dan public; QR acak diterbitkan; aplikasi menjadi
  `active`; entitlement tiga bulan diterbitkan; payment record referensial tetap
  `not_started`; dan satu audit `production_first_coach_bootstrap` dicatat tanpa
  email. Verifikasi membuktikan QR diterima oleh lookup onboarding Peserta,
  sementara payment order dan ledger tetap nol.
