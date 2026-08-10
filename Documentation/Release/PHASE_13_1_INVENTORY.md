# Phase 13.1 Release Inventory

Tanggal audit: 9 Agustus 2026

Dokumen ini tidak menyimpan nilai secret, token, credential, project URL
privat, atau identitas test user.

## Baseline yang dibekukan

- Branch saat audit: `features/phase_13`.
- Baseline Phase 12: 17 migration, 348 assertion pgTAP, 151 pemeriksaan
  integration, dan 190 Swift/StoreKit tests lulus.
- Bundle identifier: `com.ranggar.MSCBodyTransformation`.
- Minimum deployment target: iOS 17.
- Marketing version/build: `1.0` / `1`.
- App Icon default, dark, dan tinted sudah terpasang.

Setelah recurring operations serta forward fix diterapkan ulang ke Supabase
lokal, baseline verifikasi menjadi 20 migration, 400 assertion pgTAP, dan 152
pemeriksaan integration. Seluruhnya lulus dari database lokal yang dibangun
ulang.

## Dependency dan lisensi

- Aplikasi iOS tidak menautkan package pihak ketiga. Integrasi aplikasi
  memakai framework Apple dan HTTP API Supabase secara langsung.
- Edge Function commerce memakai library resmi
  `@apple/app-store-server-library` versi `3.1.0`, dipin di
  `supabase/functions/deno.json`.
- Tidak ada dependency baru yang ditambahkan pada hardening source ini.
- Lisensi Icon Composer telah diterima owner untuk membuat dokumen icon
  native; hal ini tidak menambah runtime dependency.

## Klasifikasi konfigurasi

### Public client configuration

Nilai berikut boleh berada di bundle Release, tetapi belum boleh diisi dengan
localhost atau credential server:

- `MSC_APP_MODE=hosted_production`.
- `MSC_SUPABASE_URL`: URL HTTPS hosted `main`.
- `MSC_SUPABASE_PUBLISHABLE_KEY`: publishable key hosted `main`.
- `MSC_PRIVACY_POLICY_URL`: endpoint HTTPS publik hosted `legal/privacy`.
- `MSC_TERMS_OF_USE_URL`: endpoint HTTPS publik hosted `legal/terms`.

Release membaca nilai tersebut dari `Info.plist`, bukan dari Run scheme.
Release gagal tertutup bila URL/key Supabase kosong, bukan HTTPS, loopback,
`.local`, atau alamat LAN privat.

### Server non-secret configuration

- Bundle identifier/App Store application identifier.
- Apple production/sandbox environment allowlist.
- Product ID allowlist dan pemetaan produk ke cohort/price band.
- Retry limit, body limit, timeout, dan jadwal recurring operation.

### Server secret

Nilai berikut hanya boleh dimasukkan melalui Edge Function secret management
setelah approval production dan tidak boleh ditaruh di aplikasi/repository:

- Supabase secret key modern. Legacy `service_role` tidak boleh dipakai untuk
  deployment baru.
- Google OAuth client secret.
- Apple Sign in private key/client secret dan Team/Key identifiers yang
  diperlukan untuk signing.
- App Store Connect `.p8`, issuer ID, dan key ID.
- Encryption key untuk refresh token Sign in with Apple.
- Apple root certificates/JWK cache material bila tidak diperoleh dari
  endpoint resmi pada runtime.

### Local-only values

- Local Supabase URL dan publishable/anon key.
- `Products.storekit`.
- Fixture JSON, asset demo, role/scenario selector, dan test identities.
- Local Google/Apple callback/provider secret.

## Audit artifact Release

Release simulator build yang dibersihkan pada 9 Agustus 2026 membuktikan:

- `PrivacyInfo.xcprivacy` berada di root bundle.
- `Products.storekit`, Markdown workplan, fixture JSON, dan asset demo tidak
  berada di bundle.
- Video fixture `video_placeholder_day_1.mp4` juga dikeluarkan dari Release.
- Binary tidak memuat pola `service_role`, local Supabase endpoint,
  `SUPABASE_AUTH_EXTERNAL`, demo asset name, atau email test yang diaudit.
- Hosted URL HTTPS, publishable key modern, Privacy Policy URL, dan Terms URL
  final sudah berada dalam konfigurasi Release. Build device Release terbaru
  berhasil dipasang dan diluncurkan pada iPhone fisik; bundled legal content
  tetap menjadi fallback bila endpoint publik tidak tersedia.
- Kontrol informasi skenario/role Debug kini dikompilasi hanya pada `DEBUG`.
  Clean Release simulator build tidak lagi menampilkan
  `shell.scenario-info` atau localization key `scenario.guest_home`.
- Binary Release tidak memuat `service_role`, `sb_secret_`, loopback,
  `.local`, local test identity, atau test domain yang diaudit. Lint
  `Info.plist`, `PrivacyInfo.xcprivacy`, localization catalog, dan
  `git diff --check` lulus.

## Hosted Guest dan OAuth launch smoke

- Guest berhasil membuka Beranda, Program, Peringkat, Coach, dan Profil
  terhadap hosted main tanpa membuat Supabase Auth identity.
- RPC public program, Coach, dan winner mengembalikan empty state aman.
  Direct Guest read terhadap profile, weigh-in, jawaban privat, commerce, dan
  audit ditolak `401`/RLS.
- Release UI hanya menampilkan Google dan Apple; email/password/reset tidak
  tersedia sesuai keputusan produk.
- Google memulai hosted authorization sampai `accounts.google.com`; Apple
  membuka lembar native Sign in with Apple. Login penuh dengan test identity
  tetap memerlukan iPhone fisik dan akun sandbox/test milik owner.

## Audit keamanan database lokal

- Seluruh tabel biasa pada schema `public` mengaktifkan RLS.
- Role `anon` dan `authenticated` tidak mempunyai grant tabel pada schema
  `private`.
- Tidak ada fungsi `SECURITY DEFINER` pada schema `public`/`private` yang
  kehilangan fixed `search_path`.
- Tidak ada fungsi `SECURITY DEFINER` yang memberikan `EXECUTE` kepada
  pseudo-role `PUBLIC`; akses RPC diberikan eksplisit kepada `anon`,
  `authenticated`, atau `service_role` sesuai kontrak.
- Seluruh view biasa yang diekspos memakai `security_invoker`; policy read
  global hanya ditemukan pada winner snapshot/row yang memang merupakan
  projection publik.
- Metadata OAuth yang dapat diedit hanya dipakai sebagai default profil saat
  onboarding dan tidak digunakan oleh policy/RPC untuk menentukan role atau
  authorization.
- RPC claim/complete rekonsiliasi commerce Apple tidak dapat dieksekusi oleh
  `anon` atau `authenticated`, dan hanya dapat dieksekusi `service_role`.
- Dispatcher recurring Edge worker bersifat private, memakai allowlist tiga
  worker, fixed empty `search_path`, dan tidak executable oleh client maupun
  `service_role`. Cron command tidak memuat URL, API key, Authorization, atau
  nama secret; nilai runtime diambil dari Vault.
- Forward-fix test membuktikan dispatcher menerima hosted HTTPS URL dan modern
  `sb_secret_` shape; fixture Vault dan queued request di-rollback bersama
  transaksi pgTAP.
- `supabase db lint --local --schema public,private --level warning
  --fail-on warning` lulus tanpa warning.
- `supabase db diff --local --schema public,private` tidak menghasilkan diff.

## Input eksternal yang masih diperlukan

- Approval mutation production berikutnya di luar 20 migration, sembilan
  Function aktif, tiga cron, dan SSL enforcement yang sudah selesai; project
  ref, URL, publishable key, organization, dan region sudah diverifikasi.
- Consumer production harus memakai publishable/secret key modern. Owner sudah
  mengonfirmasi legacy `anon`/`service_role` dinonaktifkan dan legacy signing
  key direvoke; JWKS publik membuktikan asymmetric signing ES256 tetap aktif.
- URL HTTPS publik Privacy Policy dan Terms of Use sudah aktif melalui
  Function `legal`.
- Google dan Apple hosted provider sudah aktif; Email provider nonaktif.
  Apple identity lifecycle secrets dan recurring Vault input sudah
  dikonfigurasi owner. App Store commerce credentials masih diperlukan
  melalui kanal secret.
- Paid Apps Agreement, tax/banking, numeric Apple app ID, production product
  records, App Store Connect server key, dan Sandbox Apple Account.
- iPhone fisik iOS 17+, test identities, dan QR Coach aktif.

## Hosted read-only preflight

- CLI dilink ke hosted `main` yang dikonfirmasi owner hanya untuk preflight.
- Hosted project aktif/sehat, Postgres 17.6, dan seluruh 20 migration
  application cocok dengan lokal.
- Enam backup fisik harian terakhir `COMPLETED`, WAL-G aktif, dan PITR belum
  aktif.
- Remote lint schema `public`/`private` bersih. Sembilan Functions aktif dan
  tiga cron recurring aktif tanpa credential pada command.
- Database SSL enforcement aktif. Koneksi database langsung masih
  mengizinkan IPv4/IPv6 umum sebagai risiko sementara selama testing.
- Output CLI pernah menampilkan legacy credentials. Nilainya tidak dicatat di
  dokumen atau source. Owner mengonfirmasi legacy API keys sudah dinonaktifkan
  dan legacy signing key direvoke. Endpoint JWKS publik tetap mengembalikan
  signing key asymmetric ES256.

## Batas mutasi

Hosted `main` sekarang mempunyai 20 migration application, sembilan Edge
Functions dengan handler-owned auth, tiga cron recurring, endpoint legal,
Google/Apple provider, Apple identity lifecycle configuration, dan database
SSL enforcement. Product mapping, App Store Server commerce credential,
Notification V2, network restriction, dan App Store Connect product mutation
belum selesai.
