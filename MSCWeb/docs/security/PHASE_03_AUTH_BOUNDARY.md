# Phase 03 auth boundary

## Trust boundary

- Guest tidak memiliki row Auth dan hanya menerima DTO public-safe.
- Identitas diverifikasi lewat `getClaims()`, lalu role/status dibaca dari tabel
  `profiles` yang dilindungi RLS. Metadata klien tidak menentukan role.
- Callback Google menukar authorization code melalui Supabase PKCE setelah
  transaksi HttpOnly bertanda tangan lolos pemeriksaan state, environment,
  TTL, dan allowlist `returnTo`.
- Pending program intent hanya memuat UUID program publik dan kedaluwarsa dalam
  30 menit. QR Coach tidak pernah ditaruh pada URL, Web Storage, atau cookie
  intent.
- Apple tidak menjadi provider Web. Edge Function penghapusan akun existing
  hanya akan menemukan credential Apple untuk identitas legacy yang memang
  memilikinya; akun Google Web tidak membuat credential tersebut.

## Lifecycle

- Registrasi provider membuat profil provisional dengan role Peserta melalui
  trigger backend existing.
- Draft form tetap di memori browser sampai pengguna mengirimkannya. Operasi
  profile dan finalisasi tetap berada di RPC backend existing.
- Participant menunggu browser QR scanner adapter Phase 04. Tidak ada fallback
  kode manual.
- Pengajuan Coach membutuhkan SC atau lebih tinggi serta attestations HOM STS
  dan ICT. Role tetap Peserta sampai keputusan Admin otoritatif.
- Logout menghapus cookie transaksi/intensi dan mengirim `Clear-Site-Data` untuk
  cache/storage lokal yang relevan.
- Penghapusan akun memanggil Edge Function existing, mempertahankan recent
  reauthentication, assignment-transfer guard, cleanup media, dan anonymization.

## External gates

- Google web client/callback hosted dan domain production: Phase 12.
- SMTP/email production tetap nonaktif sampai keputusan eksplisit.
- Pemindai QR kamera production: Phase 04.

## Asset provenance

- Tombol Google memakai icon square light/dark dari paket resmi
  `signin-assets.zip` pada Google Identity Branding Guidelines, diunduh
  10 Agustus 2026. File disimpan tanpa perubahan di
  `public/brand/google-g-*-square.svg`; teks Bahasa Indonesia dirender sebagai
  HTML terpisah sesuai izin lokalisasi pada pedoman Google.
