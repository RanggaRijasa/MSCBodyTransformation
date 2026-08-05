# Phase 10: Authentication and Session

> Status: siap dikerjakan setelah local UI Phase 09.5 selesai. Workplan telah
> direkonsiliasi ulang pada 5 Agustus 2026 terhadap batas pendaftaran program,
> override enrollment Admin, dan kontrak backend Phase 10–12. Integrasi Auth
> lokal dapat dikerjakan tanpa menulis ulang Guest,
> Login/Register, onboarding profil, atau pengajuan Coach.
>
> Email/password, profile bootstrap, session lifecycle, callback routing,
> pending enrollment intent, role protection, dan sebagian besar pengujian
> dikerjakan menggunakan Supabase lokal melalui Colima. Google OAuth,
> Sign in with Apple, callback hosted production, capability Apple, dan
> verifikasi perangkat fisik tetap menjadi external gate.
>
> Hosted Supabase `main` adalah production dan tidak digunakan untuk
> eksperimen Phase 10. Supabase Branching dan hosted development project
> tidak digunakan.

## Otoritas dan batas dokumen

Workplan ini menggantikan Phase 10 lama yang masih:

- Menganggap project Supabase belum tersedia sama sekali.
- Menggunakan istilah `pending invite`.
- Mengusulkan `AuthRepository` baru tanpa merekonsiliasi
  `SessionRepository` dan `AppSession` yang sudah ada.
- Belum membedakan local demo, Supabase lokal, dan hosted production.
- Belum mencakup profile bootstrap, Keychain, refresh-token rotation,
  identity linking, dan account-deletion boundary.

Sumber keputusan produk dan kontrak:

- `00_START_HERE.md`.
- `PROGRAM_END_TO_END_REMEDIATION_WORKPLAN.md`.
- `PROGRAM_END_TO_END_CONTRACT_MATRIX.md`.
- `PROGRAM_END_TO_END_IMPLEMENTATION_STATUS.md`.
- `10_PHASE_09_SUPABASE_FOUNDATION.md`.
- `10A_PHASE_09_5_GUEST_AUTH_PROFILE_AND_COACH_APPLICATION_UI.md`.
- `Contracts/program-api-v1.openapi.yaml`.
- `AGENTS.md`.

Jika terdapat konflik, remediation workplan dan contract matrix berlaku.

Phase ini hanya menangani identitas, session, profile bootstrap, field profil
yang dapat diedit user termasuk level member, role load, provisional identity,
dan pemulihan enrollment intent melewati autentikasi. Phase ini tidak:

- Menerapkan operasi server Phase 11 yang belum selesai.
- Menyimpan, menyetujui, menolak, atau mengaktifkan Coach application secara
  authoritative. Phase 10 hanya menyiapkan authenticated handoff dan state
  profile/onboarding; aggregate serta operasi Coach application tetap Phase 11.
- Mengaktifkan transaksi StoreKit production.
- Menyediakan Google atau Apple credential palsu.
- Mendeploy migration ke hosted Supabase `main`.
- Menghapus local demo mode.
- Mengizinkan client langsung memilih, mengirim, atau mengubah role
  Coach/Admin. User boleh mengajukan menjadi Coach melalui kontrak Phase 09.5,
  tetapi role tetap Participant sampai pembayaran verified dan keputusan
  Admin tervalidasi server.
- Mengubah QR Coach menjadi invite, program code, atau authorization token.
- Menyimpan `service_role`, database password, provider client secret,
  access token, refresh token, atau raw QR Coach pada log.

## Tujuan

Mengganti fake session dengan Supabase Auth pada real environment secara
bertahap, tanpa menghilangkan local demo mode dan tanpa membuat feature UI
bergantung langsung pada Supabase.

Hasil Phase 10 harus menyediakan:

- Registrasi email/password yang selalu menghasilkan profil Participant.
- Login, logout, email verification, forgot password, reset password, dan
  session restoration.
- Session state yang aman terhadap refresh race, expiry, logout, dan relaunch.
- Google OAuth dan Sign in with Apple setelah external gate tersedia.
- Role yang selalu dibaca dari data backend terlindungi.
- Persistensi nama, nomor HP, dan level member melalui operation dengan
  allowlist yang tidak dapat mengubah role.
- Authenticated handoff pengajuan Coach ke kontrak Phase 11 tanpa menyimpan
  payment verified, keputusan Admin, atau role dari state client.
- Program yang dipilih dan QR Coach opaque tetap tersedia setelah auth tanpa
  diperlakukan sebagai role atau izin akses.
- Provider chooser Phase 09.5 dipertahankan: Apple, Google, dan email tampil
  sebelum form email; Login tidak membuka keyboard otomatis.
- Production onboarding tidak boleh mengekspos account/profile parsial.
  Participant baru aktif setelah QR Coach tervalidasi server. Jalur pengajuan
  Coach berhenti pada authenticated handoff sampai operasi application
  Phase 11 dan payment verification Phase 12 benar-benar tersedia.
- Local demo yang tetap berjalan tanpa Colima dan tanpa internet.
- Pemisahan tegas antara local Supabase development dan hosted production.

## Baseline yang sudah tersedia

### Backend Phase 09

- [x] Supabase CLI `2.111.0`, Docker CLI, dan Colima tersedia.
- [x] Supabase lokal memakai PostgreSQL 17.
- [x] Auth service lokal diaktifkan pada `supabase/config.toml`.
- [x] Callback lokal
  `mscbodytransformation://auth/callback` sudah tercantum pada additional
  redirect URLs Supabase lokal.
- [x] Schema `public.profiles` mereferensikan primary key
  `auth.users(id)` dengan `on delete cascade`.
- [x] `public.profiles.role` dibatasi ke `participant`, `coach`, dan `admin`.
- [x] Client `authenticated` tidak mempunyai grant INSERT atau UPDATE langsung
  ke `public.profiles`.
- [x] Profile self-read melewati RLS.
- [x] Role, current Coach, Coach QR, dan approval state bersifat
  server-controlled.
- [x] RLS, explicit Data API grants, private Storage, dan operasi server
  vertical slice Phase 09 sudah diuji.
- [x] Adapter iOS Phase 09 menggunakan native Foundation `URLSession`.
- [x] Migration `20260805013707_program_registration_deadline.sql`
  menambahkan cutoff authoritative berbasis server clock, memperkeras
  self-enrollment, dan menyediakan `admin_enroll_participant`.
- [x] Self-enrollment ditolak tepat pada atau setelah cutoff; RPC Admin hanya
  mengecualikan deadline dan tetap memvalidasi role Admin, lifecycle,
  kapasitas, Coach approved, entitlement, serta alasan audit.
- [x] Fresh reset, lint, security advisors, 89 pgTAP assertions, dan 14 race
  assertions untuk baseline tersebut sudah lulus.
- [x] Hosted `main` belum menerima migration dan tetap diperlakukan sebagai
  production.

### iOS Phase 00–09

- [x] `AppSession` dan `SessionState` tersedia sebagai domain model.
- [x] `SessionRepository` tersedia sebagai domain-facing boundary.
- [x] `LoadCurrentSessionUseCase` tersedia.
- [x] `AppEnvironment` dan dependency container tersedia.
- [x] Root Debug dapat menjalankan local demo Participant, Coach, dan Admin.
- [x] Logged-out, onboarding-incomplete, dan expired session sudah mempunyai
  deterministic mock scenario.
- [x] Feature Views mengambil data melalui state/use case/repository, bukan
  query Supabase langsung.
- [x] Local demo tidak membutuhkan internet atau Colima.
- [x] Program selection, QR Coach scan, dan same-Coach guard sudah tersedia
  pada alur lokal.

Keberadaan baseline tersebut tidak berarti production auth sudah selesai.

### Handoff yang sudah diselesaikan Phase 09.5

- [x] Guest menjadi logged-out access state, bukan `UserRole`.
- [x] Guest dapat membuka seluruh Participant tabs dengan public-safe data.
- [x] Home Guest menampilkan satu CTA `Masuk`; Register berada pada Login.
- [x] Login default, Register, Forgot Password, serta fake Apple/Google/email
  presentation tersedia.
- [x] Provider chooser tampil sebelum form email dan tidak membuka keyboard.
- [x] Onboarding lokal memuat nama, nomor HP, sembilan level member, dan
  pilihan Peserta/pengajuan Coach.
- [x] Participant registration baru difinalisasi setelah QR Coach valid.
- [x] Coach application, eligibility HOM STS/ICT, price preview, payment
  preview, dan review Admin tersedia pada repository lokal.
- [x] Pending applicant tetap Participant sampai approval.
- [x] Pembatalan sebelum finalisasi membuang draft dan kembali ke Guest.

## Gap Phase 10 yang harus ditutup

- [ ] Belum ada migration idempoten untuk membuat profil Participant saat row
  baru dibuat pada `auth.users`.
- [ ] `public.profiles` belum mempunyai field level member dan operation
  allowlisted untuk menyimpan nama, nomor HP, serta level tanpa membuka
  perubahan role atau field privileged.
- [ ] Belum ada onboarding/provisional status dan expiry server-controlled
  yang dapat membedakan identity Auth dari application account aktif.
- [ ] Belum ada backfill aman untuk identity test yang sudah ada tanpa profil.
- [ ] Belum ada Auth API client dan token lifecycle pada aplikasi.
- [ ] `SessionRepository` belum mendukung registration, login, logout,
  refresh, password recovery, dan auth-state observation.
- [ ] `AppConfiguration.Mode` baru memiliki `localDemo`.
- [ ] Root Release masih membuka shell Participant tanpa session nyata.
- [ ] Token belum disimpan pada Keychain.
- [ ] Callback scheme belum didaftarkan pada target iOS.
- [ ] UI email/password sudah tersedia dari Phase 09.5, tetapi command-nya
  masih memakai fake adapter dan belum terhubung ke Supabase Auth.
- [ ] `PendingAuthenticatedIntent` source saat ini baru membawa program ID;
  belum membawa TTL, nonce, environment, dan QR Coach opaque pada secure
  storage.
- [ ] Belum ada revalidasi cutoff program setelah login, verification, OAuth
  callback, app relaunch, atau perubahan cutoff selama auth berlangsung.
- [ ] Belum ada lifecycle provisional identity yang membedakan login account
  lama dari identity baru yang belum menyelesaikan onboarding.
- [ ] Belum ada cleanup idempoten untuk identity baru yang dibatalkan sebelum
  QR Participant atau handoff Coach selesai.
- [ ] Belum ada provider Google/Apple yang dikonfigurasi.
- [ ] Belum ada account-deletion request yang dapat diakses dari aplikasi.
- [ ] Belum ada hosted production Auth configuration.

## Handoff yang tetap menjadi Phase 11 dan Phase 12

Item berikut adalah dependency produk setelah fondasi Auth lokal selesai,
bukan exit criteria Phase 10 lokal:

- [ ] Phase 11 menyediakan public-safe Guest views/grants tanpa membuat
  anonymous Auth user.
- [ ] Phase 11 menambahkan Coach application, attestation snapshot, RLS,
  applicant submit, Admin approve/reject, audit, dan role activation atomik.
- [ ] Phase 11 menghubungkan Admin enrollment override ke
  `admin_enroll_participant`; client Participant tidak pernah mendapat akses
  ke RPC tersebut.
- [ ] Phase 12 memverifikasi pembayaran Coach/Program dan entitlement secara
  server-authoritative.
- [ ] Phase 12 menentukan expiry, renewal, cancellation, refund, dan
  reconciliation pembayaran.

## Keputusan environment

Gunakan tiga mode eksplisit:

### `localDemo`

- Memakai fixture dan in-memory repository.
- Tidak membuat request jaringan tersembunyi.
- Tidak membutuhkan Colima.
- Debug role/scenario selector tetap tersedia hanya pada Debug.
- Tidak boleh diklaim sebagai server-authenticated.

### `debugLocalSupabase`

- Memakai Supabase lokal melalui Colima dan Docker.
- Hanya boleh tersedia pada Debug.
- Simulator dapat memakai loopback.
- Perangkat fisik memerlukan URL LAN Mac yang dapat dijangkau, jaringan yang
  sama, dan konfigurasi Debug-only yang tidak masuk Release.
- Hanya memakai local public/publishable credential dari `supabase status`.
- Harus gagal tertutup bila URL, key, callback, atau local stack tidak valid.

### `hostedProduction`

- Hanya memakai HTTPS hosted Supabase production dan publishable key.
- Tidak boleh menerima loopback, alamat LAN, HTTP, atau local credential.
- Tidak boleh memakai fallback otomatis ke `localDemo`.
- Belum diaktifkan sampai production deployment dan release gate disetujui
  eksplisit.

Checklist:

- [ ] Tambahkan mode `debugLocalSupabase` dan `hostedProduction`.
- [ ] Buat configuration loader yang memvalidasi kombinasi build dan endpoint.
- [ ] Pastikan Release menolak local/HTTP endpoint.
- [ ] Pastikan Debug local tidak dapat memakai hosted `main` tanpa pilihan
  eksplisit.
- [ ] Tambahkan test matriks build × mode × endpoint.
- [ ] Dokumentasikan cara Simulator dan perangkat fisik mencapai Auth lokal.
- [ ] Jangan menaruh token atau provider secret dalam `.xcconfig`, plist,
  source Swift, test fixture, atau repository.

## Keputusan dependency

- [x] `supabase-swift` sudah dievaluasi pada Phase 09 dan tidak ditambahkan.
- [x] Native Foundation `URLSession` sudah menjadi boundary Supabase Phase 09.
- [ ] Perluas boundary native tersebut untuk Auth hanya setelah endpoint,
  payload, PKCE, callback, dan refresh behavior diperiksa pada dokumentasi
  Supabase yang berlaku saat implementasi.
- [ ] Isolasi Auth transport di belakang `SupabaseAuthClientProviding`.
- [ ] Jangan memasukkan DTO Auth atau Supabase ke domain model.
- [ ] Jangan menambahkan package Google Sign-In atau package auth lain tanpa
  persetujuan eksplisit user.
- [ ] Jika kemudian `supabase-swift` disetujui, pin versi, dokumentasikan
  alasan native API tidak memadai, simpan di belakang adapter, dan jangan
  mengubah feature UI.

## Arsitektur session

Gunakan dependency direction:

```text
SwiftUI Auth View / RootView
    ↓
AuthenticationFlowState / SessionStore
    ↓
Authentication command use case / Session use case
    ↓
AuthenticationRepository façade / SessionRepository lifecycle owner
    ↓
Local Demo Adapter atau Supabase Session Adapter
    ↓
SupabaseAuthClientProviding
```

Keputusan:

- Pertahankan `AuthenticationRepository` Phase 09.5 sebagai façade command
  yang digunakan flow Login/Register/onboarding agar UI tidak ditulis ulang.
- Jadikan `SessionRepository` satu-satunya domain-facing owner untuk session,
  token, restore, refresh, logout, dan auth-state observation.
- Production `AuthenticationRepository` mendelegasikan identity command ke
  session use case dan profile operation; repository ini tidak boleh memiliki
  token store, refresh actor, atau auth-state stream kedua.
- Jangan membuat repository Auth ketiga atau memasang transport langsung pada
  `AuthenticationFlowState`.
- `SupabaseAuthClientProviding` adalah infrastructure transport, bukan domain
  repository.
- `SessionStore` mengorkestrasi auth state, profile load, onboarding, pending
  intent, dan root route.
- Feature View tidak membaca token, memanggil endpoint Auth, atau menentukan
  role.

Checklist:

- [ ] Tambahkan domain command/value yang tidak membawa tipe Supabase:
  email credential, registration request, auth provider, dan recovery state.
- [ ] Perluas `SessionRepository` untuk register, login, logout, restore,
  refresh, request reset, update password, dan auth-state updates.
- [ ] Ubah method `...ForDemo` pada `AuthenticationRepository` menjadi
  command environment-neutral atau adapter façade yang mendelegasikan ke
  local demo maupun Supabase tanpa mengubah navigation flow.
- [ ] Pastikan hanya satu Keychain store, refresh coordinator, dan session
  observation stream yang hidup untuk satu app environment.
- [ ] Pertahankan method Debug-only terisolasi dari production adapter.
- [ ] Tambahkan `SessionStore` berbasis Observation pada app layer.
- [ ] Gunakan `AsyncStream` atau mekanisme structured-concurrency yang
  ownership dan cancellation-nya jelas untuk perubahan auth state.
- [ ] Root route membedakan:
  - Bootstrapping.
  - Logged out.
  - Menunggu verifikasi email.
  - Password recovery.
  - Profile provisioning.
  - Provisional onboarding.
  - Provisional cleanup pending.
  - Onboarding Participant.
  - Authenticated role shell.
  - Session expired.
  - Recoverable error.
- [ ] Root route tidak pernah memilih shell hanya dari metadata provider.
- [ ] Token valid dan protected profile yang berhasil dimuat belum cukup untuk
  membuka role shell; onboarding/finalization status juga harus selesai.
- [ ] Role-load failure tidak boleh jatuh ke Participant secara diam-diam.
- [ ] Root Debug tetap dapat memilih local demo secara eksplisit.
- [ ] Root Release tidak boleh membuka shell Participant ketika tidak ada
  session.

## Profile bootstrap dan role hardening

Migration Phase 10 harus dibuat dengan
`supabase migration new <descriptive_name>` saat implementasi dimulai.
Jangan mengedit migration Phase 09 yang sudah ada.

Profile bootstrap:

- [ ] Buat trigger setelah INSERT pada `auth.users` yang membuat
  `public.profiles` secara idempoten.
- [ ] Set role secara literal menjadi `participant`; abaikan `role`,
  `current_coach_id`, Coach approval, dan Coach QR dari user metadata.
- [ ] Set onboarding/provisional status dan expiry secara server-controlled;
  abaikan field sejenis dari user metadata atau request client.
- [ ] Gunakan metadata hanya untuk field display/onboarding yang tidak
  authoritative setelah disanitasi.
- [ ] Sediakan fallback display name yang valid agar metadata kosong tidak
  menggagalkan signup.
- [ ] Simpan privileged helper di schema non-exposed `private`.
- [ ] Gunakan explicit empty `search_path`.
- [ ] Revoke EXECUTE dari `PUBLIC`, `anon`, dan `authenticated`.
- [ ] Berikan privilege minimum yang benar kepada role Auth/trigger sesuai
  dokumentasi dan local runtime yang benar-benar terpasang.
- [ ] Trigger failure harus terlihat sebagai signup failure yang terpetakan,
  bukan diabaikan.
- [ ] Tambahkan backfill idempoten untuk local test users yang sudah ada tanpa
  profile, bila diperlukan.
- [ ] Jangan memberi INSERT/UPDATE profile langsung kepada client untuk
  menyelesaikan bootstrap.

Role hardening:

- [ ] Verifikasi registration request dengan metadata `role=admin` tetap
  menghasilkan Participant.
- [ ] Verifikasi registration request dengan metadata `role=coach` tetap
  menghasilkan Participant.
- [ ] Verifikasi user tidak dapat self-promote melalui Data API, RPC, metadata,
  token refresh, identity link, atau profile update.
- [ ] Coach/Admin hanya dapat diprovisikan melalui server-controlled Admin
  operation yang terpisah dari registrasi umum. Coach operation wajib
  memvalidasi eligibility, verified payment, dan pending application.
- [ ] Authorization tetap membaca `public.profiles.role` dan hubungan
  server-controlled, bukan `raw_user_meta_data`.
- [ ] Jika role dimasukkan ke JWT/app metadata pada phase berikutnya, perlakukan
  claim sebagai cache yang dapat stale dan tetap verifikasi operasi sensitif
  di server.

## Session dan token security

- [ ] Simpan material session minimum yang dibutuhkan pada Keychain dengan
  accessibility device-only yang sesuai.
- [ ] Jangan simpan access token atau refresh token pada UserDefaults,
  `@AppStorage`, fixture, analytics, crash breadcrumb, atau log.
- [ ] Jangan aktifkan Keychain sync lintas perangkat.
- [ ] Isolasi mutable session/token state di dalam actor.
- [ ] Serialisasi refresh request agar satu refresh token tidak dipakai oleh
  beberapa task secara bersamaan.
- [ ] Ganti access dan refresh token secara atomik setelah refresh berhasil.
- [ ] Gunakan expiry dari server; jangan menganggap jam perangkat
  authoritative.
- [ ] Refresh proaktif dengan tolerance untuk clock skew.
- [ ] Untuk response unauthorized, lakukan paling banyak satu coordinated
  refresh dan satu retry bila operation aman diulang.
- [ ] Jangan retry registration, password reset, account deletion, atau
  mutation non-idempoten secara buta.
- [ ] Bedakan offline, timeout, invalid credential, unverified email,
  refresh revoked/reused, session expired, rate limit, conflict, dan unknown.
- [ ] Logout menghapus session lokal walaupun network revoke gagal, lalu
  memberi status yang jujur bila revoke server belum terkonfirmasi.
- [ ] Session expiry menghapus private in-memory state dan mengarahkan user ke
  auth tanpa membocorkan data role sebelumnya.
- [ ] App relaunch memulihkan session dari Keychain, refresh bila perlu, lalu
  memuat protected profile.
- [ ] Jangan log header Authorization, callback code, token hash, nonce,
  provider token, email lengkap, atau raw response Auth.
- [ ] Tentukan hosted session policy sebelum release: JWT expiry, inactivity,
  time-box, dan single-session behavior.

## Pending enrollment intent

Istilah yang digunakan adalah `PendingEnrollmentIntent`, bukan invite.

Source Phase 09.5 saat ini memakai `PendingAuthenticatedIntent` dengan
`.joinProgram(UUID)` dan `.openProfile`. Phase 10 harus memigrasikannya ke
model typed yang lebih lengkap atau membungkusnya di boundary yang sama;
jangan membuat dua intent store yang dapat berbeda state.

Intent minimum:

- Program ID yang dipilih.
- QR Coach opaque hasil scanner bila scan sudah dilakukan.
- Waktu pembuatan dan expiry.
- Nonce/identifier lokal untuk mencegah callback lama memakai intent baru.
- Environment asal agar callback local tidak dapat memakai intent production
  dan sebaliknya.

Aturan:

- [ ] Participant dapat memilih program dan memindai QR Coach sebelum auth
  apabila flow produk membutuhkannya.
- [ ] Pending intent bertahan melalui email verification, OAuth callback,
  password login, app background, dan relaunch.
- [ ] Raw QR Coach disimpan hanya pada secure device storage; jangan gunakan
  UserDefaults, clipboard, URL callback, analytics, atau log.
- [ ] Tetapkan TTL dan hapus intent yang kedaluwarsa.
- [ ] Hapus intent setelah enrollment berhasil, user membatalkan, program
  tidak lagi tersedia, atau QR ditolak secara final.
- [ ] Jangan mengubah QR menjadi role, entitlement, atau izin akses.
- [ ] Setelah auth, server RPC authoritative tetap memvalidasi Participant,
  program, current Coach, QR, lifecycle, kapasitas, cutoff pendaftaran,
  pricing mode, entitlement, dan idempotency.
- [ ] QR Coach pertama dapat menetapkan current Coach melalui operasi server.
- [ ] QR Coach berbeda ditolak sebelum payment flow.
- [ ] Program gratis dapat melanjutkan ke enrollment atomik Phase 09.
- [ ] Program berbayar hanya melanjutkan ke handoff Phase 12; auth success
  tidak memberikan entitlement.
- [ ] Uji callback lama, callback ganda, relaunch, logout, account switch,
  expired intent, wrong-Coach QR, dan duplicate enrollment.

### Batas pendaftaran selama Auth

- [ ] Tampilkan cutoff dari snapshot program hanya untuk informasi UI; hasil
  client tidak pernah menjadi keputusan authoritative.
- [ ] Setelah login, email verification, OAuth callback, session restoration,
  dan app relaunch, muat ulang program sebelum QR atau enrollment dilanjutkan.
- [ ] Self-enrollment menggunakan server clock dan ditolak tepat pada atau
  setelah `registration_closes_at`.
- [ ] Jika cutoff berubah atau terlewati ketika Auth sedang berlangsung,
  hapus/akhiri join intent secara aman, jangan membuka scanner, dan tampilkan
  pesan `Pendaftaran program sudah ditutup.`.
- [ ] Program yang ditutup tetap dapat dibaca pada katalog/detail Guest.
- [ ] Auth/Participant adapter hanya boleh memakai self-enrollment RPC dan
  tidak pernah memanggil `admin_enroll_participant`.
- [ ] `admin_enroll_participant` tetap berada pada Admin command repository,
  wajib role Admin serta alasan audit, dan hanya mengabaikan deadline.
- [ ] Uji cutoff sebelum login, saat verification menunggu, tepat pada batas,
  setelah callback, setelah relaunch, dan race antara perubahan cutoff dengan
  enrollment.

## Email dan password

### Registrasi

- [ ] Gunakan credential UI Phase 09.5: email, password, dan konfirmasi
  password menggunakan copy Bahasa Indonesia.
- [ ] Registrasi umum tidak menampilkan pemilih role.
- [ ] Validasi client hanya membantu UX; aturan server tetap authoritative.
- [ ] Password requirement UI mengikuti konfigurasi Auth server yang benar.
- [ ] Jangan memangkas atau mengubah password diam-diam.
- [ ] Gunakan generic response yang tidak mempermudah user enumeration.
- [ ] Signup sukses membuat `auth.users` dan tepat satu profil Participant.
- [ ] Signup dapat memasuki status menunggu verifikasi tanpa kehilangan
  pending enrollment intent.

### Email verification

- [ ] Samakan local Auth configuration dengan behavior hosted yang akan
  digunakan; local default dan hosted default tidak boleh diasumsikan sama.
- [ ] Periksa nama configuration key pada Supabase CLI/config sample versi
  yang sedang terpasang sebelum mengubah `supabase/config.toml`.
- [ ] Gunakan local email inbox dari Supabase CLI untuk E2E verification.
- [ ] Sediakan notice, open-email guidance, resend, rate-limit countdown, dan
  change-email/cancel action yang aman.
- [ ] Callback verification divalidasi sebelum session disimpan.
- [ ] Expired, used, malformed, dan wrong-environment links ditangani.

### Login dan logout

- [ ] Login email/password.
- [ ] Loading state mencegah duplicate submission.
- [ ] Invalid credential memakai pesan generik.
- [ ] Unverified email menawarkan resend tanpa membocorkan account existence.
- [ ] Login sukses memuat protected profile sebelum membuka role shell.
- [ ] Logout mempunyai confirmation yang sesuai dan membersihkan private
  screen state.
- [ ] Account switch tidak membawa pending intent atau cache private dari user
  sebelumnya tanpa validasi eksplisit.

### Forgot dan reset password

- [ ] Form forgot password dengan response generik.
- [ ] Reset email memakai callback allowlist per environment.
- [ ] Deep link membuka route reset, bukan role shell.
- [ ] Callback code/token hanya diproses sekali.
- [ ] Form password baru mengikuti requirement server.
- [ ] Password update sukses merekonsiliasi atau mencabut session sesuai
  behavior Auth yang telah diverifikasi.
- [ ] Expired, malformed, reused, dan wrong-environment reset link ditangani.

## Callback dan deep-link routing

- [x] Redirect URL lokal tercantum pada `supabase/config.toml`.
- [ ] Daftarkan custom URL scheme pada target iOS.
- [ ] Perubahan target, capability, entitlements, atau `project.pbxproj`
  memerlukan instruksi/persetujuan eksplisit sesuai `AGENTS.md`.
- [ ] Gunakan satu parser typed untuk email verification, password recovery,
  OAuth success, OAuth cancellation, dan provider error.
- [ ] Validasi scheme, host, path, state, nonce, PKCE verifier, environment,
  dan expected flow.
- [ ] Callback yang tidak cocok dengan flow aktif harus ditolak.
- [ ] Callback ganda harus idempoten.
- [ ] Callback tidak boleh memuat atau mencatat raw QR Coach.
- [ ] Simpan PKCE verifier dan OAuth state secara aman serta berumur pendek.
- [ ] Gunakan `ASWebAuthenticationSession` untuk browser OAuth.
- [ ] Gunakan ephemeral browser session hanya bila tradeoff UX sudah diputuskan.
- [ ] Selesaikan callback pada app lifecycle API yang benar tanpa networking
  langsung di SwiftUI `body`.
- [ ] Tambahkan universal link kemudian bila domain production tersedia;
  custom scheme tetap dibatasi dengan state/PKCE.

## Google OAuth

Pekerjaan lokal yang dapat disiapkan tanpa production credential:

- [ ] Tambahkan provider enum, use case, state machine, error mapping, dan
  callback parser.
- [ ] Implementasikan browser OAuth melalui `ASWebAuthenticationSession`
  dengan PKCE berdasarkan endpoint Supabase yang diverifikasi saat eksekusi.
- [ ] Handle start, cancel, callback mismatch, provider error, duplicate
  callback, dan app relaunch.
- [ ] Jangan meminta Google scope di luar `openid`, email, dan profile tanpa
  alasan produk eksplisit.
- [ ] Jangan menyimpan Google provider access/refresh token karena aplikasi
  tidak membutuhkan Google API.
- [ ] Jangan mengotorisasi role dari Google claims/profile.
- [ ] Tambahkan fake provider tests tanpa credential nyata.

External gate:

- [ ] Google Cloud project dan consent-screen audience tersedia.
- [ ] Branding, privacy URL, support email, dan approved scopes tersedia.
- [ ] OAuth Web client ID dan client secret tersedia untuk Supabase provider.
- [ ] Local callback Auth `http://127.0.0.1:54321/auth/v1/callback`
  dikonfigurasi untuk pengujian lokal sesuai dokumentasi terbaru.
- [ ] Secret Google lokal hanya masuk environment variable yang diabaikan Git.
- [ ] Hosted Supabase callback dan production redirect allowlist dikonfigurasi.
- [ ] Google login diverifikasi pada Simulator dan iPhone fisik.
- [ ] Google kemudian email serta email kemudian Google diuji dengan email
  terverifikasi.

## Sign in with Apple

Pekerjaan source yang dapat disiapkan tanpa production credential:

- [ ] Tambahkan native AuthenticationServices adapter.
- [ ] Buat nonce acak per attempt, kirim hash yang benar ke Apple, dan
  verifikasi nonce yang sama pada exchange Supabase.
- [ ] Exchange Apple identity token melalui Supabase Auth endpoint yang
  didokumentasikan saat implementasi.
- [ ] Tangani cancel, missing token, invalid nonce, revoked credential,
  duplicate callback, dan relay email.
- [ ] Ambil nama hanya dari first native authorization response bila tersedia.
- [ ] Sanitasi nama untuk display/onboarding; jangan gunakan nama/email Apple
  untuk authorization.
- [ ] Jangan menyimpan Apple identity token atau authorization code.
- [ ] Tambahkan fake credential tests tanpa key atau token nyata.

External gate:

- [ ] Apple Developer membership tersedia.
- [ ] Bundle ID final tersedia.
- [ ] Sign in with Apple capability diaktifkan.
- [ ] App ID/Services ID dan provider Supabase dikonfigurasi sesuai flow yang
  benar-benar dipilih.
- [ ] Private key/secret Apple disimpan di server configuration, bukan app
  atau repository.
- [ ] Jika OAuth web Apple digunakan, rotasi secret enam bulanan dicatat
  sebagai operational task; native-only flow tidak boleh diberi kewajiban
  rotasi yang tidak berlaku.
- [ ] Relay email configuration diuji.
- [ ] Sign in, hidden relay email, first-login name, repeat login, revoked
  credential, dan account deletion diuji pada iPhone fisik.

## Identity linking dan duplicate prevention

Keputusan awal:

- Automatic linking Supabase untuk identity dengan email terverifikasi dapat
  digunakan setelah behavior versi hosted/local yang sebenarnya diuji.
- Manual identity linking tidak menjadi default Phase 10 karena dapat berubah
  dan memerlukan keputusan produk tambahan.
- Apple relay email tetap identity terpisah kecuali user melakukan linking
  eksplisit melalui flow yang aman.

Checklist:

- [ ] Dokumentasikan behavior automatic linking yang benar-benar terpasang.
- [ ] Profile bootstrap idempoten berdasarkan `auth.users.id`, bukan email.
- [ ] Linking identity tidak membuat profil kedua untuk user yang sama.
- [ ] Unverified email tidak boleh ditautkan otomatis hanya karena string
  email sama.
- [ ] Test email → Google dan Google → email.
- [ ] Test Google account dengan email berbeda.
- [ ] Test Apple relay sebagai identity terpisah.
- [ ] Test provider callback yang menunjuk ke session user lain.
- [ ] Jangan menggabungkan dua user application secara manual melalui update
  foreign key client-side.
- [ ] Bila manual linking ditambahkan kemudian, wajib reauthentication,
  confirmation UI, audit, rollback/error recovery, dan perlindungan agar user
  tidak menghapus satu-satunya identity.

## Onboarding dan role routing

- [ ] Registrasi baru selalu membuat protected profile dengan role Participant.
- [ ] Setelah signup/session, gunakan onboarding Phase 09.5 untuk nama, nomor
  HP, level member, dan account purpose.
- [ ] User dapat memilih `Ajukan menjadi Coach`, tetapi tidak dapat memilih
  atau mengirim role Coach/Admin.
- [ ] Member tidak dapat melanjutkan ke handoff Coach application.
- [ ] SC ke atas wajib memenuhi HOM STS dan ICT sebelum handoff Phase 11/12.
- [ ] Phase 10 tidak menerima atau menyimpan flag `payment_verified` maupun
  keputusan Admin dari client.
- [ ] Pending/rejected applicant tetap memakai Participant shell.
- [ ] Onboarding hanya mengubah field profile yang memang user-editable melalui
  server operation dengan allowlist eksplisit.
- [ ] Role tetap dibaca dari protected profile.
- [ ] Applicant yang belum approved tetap memakai Participant shell dengan
  status pengajuan eksplisit dan tanpa capability Coach/Admin.
- [ ] Admin shell hanya terbuka untuk protected role Admin.
- [ ] Role berubah oleh trusted Admin operation memicu profile/session reload.
- [ ] Stale role cache tidak boleh mempertahankan akses ke shell privileged.
- [ ] SessionStore membersihkan navigation path dan private cache ketika role
  atau user berubah.
- [ ] Deep link ke route role tertentu tetap melewati session dan role guard.

## Provisional identity dan pembatalan registrasi

Kontrak produk tetap: menutup registrasi sebelum finalisasi membuang draft,
kembali ke Guest, dan tidak membuat application account aktif. Implementasi
harus jujur membedakan draft aplikasi, identity Supabase, protected profile,
dan enrollment.

- [ ] Untuk email/password, tunda request signup sampai nama, nomor HP, level,
  tujuan akun, dan prasyarat Participant/Coach yang termasuk Phase 10 sudah
  valid; password hanya hidup di memory selama flow dan tidak pernah
  dipersistenkan oleh aplikasi.
- [ ] Untuk OAuth yang dapat membuat `auth.users` saat callback, tandai
  identity baru sebagai provisional sampai profile provisioning dan
  finalization server berhasil.
- [ ] Status provisional dan expiry bersifat server-controlled; client tidak
  mendapat grant untuk mengubah atau memperpanjangnya.
- [ ] Identity milik account lama yang sedang login tidak pernah dianggap
  provisional dan tidak boleh dihapus ketika user menutup onboarding.
- [ ] Profile provisional selalu role Participant, tidak mempunyai enrollment,
  Coach capability, payment verified, atau application approval.
- [ ] Menutup flow menghapus draft, pending intent, PKCE/state, dan material
  session lokal lalu kembali ke Guest.
- [ ] Bila identity baru sudah dibuat, panggil authenticated trusted cleanup
  operation yang idempoten. Operation memverifikasi bahwa identity memang
  provisional, belum mempunyai enrollment/application/audit responsibility,
  lalu revoke session sebelum menghapus identity.
- [ ] Auth Admin API atau `service_role` tidak pernah berada di aplikasi;
  cleanup dijalankan server-side dengan privilege minimum.
- [ ] Server menjadwalkan expiry cleanup saat identity provisional dibuat,
  sehingga orphan tetap dibersihkan bila client hilang atau offline.
- [ ] Jika cleanup langsung gagal atau offline, aplikasi tetap membersihkan
  data lokal dan kembali ke Guest, tetapi tidak mengklaim penghapusan server
  telah terkonfirmasi; cleanup terjadwal server menjadi fallback.
- [ ] Relaunch dapat melanjutkan provisional onboarding yang sah atau
  menyelesaikan cleanup kedaluwarsa; jangan membuka Participant shell hanya
  karena token masih valid.
- [ ] Uji cancel sebelum signup, cancel setelah OAuth callback, callback ganda,
  offline cleanup, retry, relaunch, account lama, identity linked, dan cleanup
  yang sudah selesai.

## Account deletion dan privacy

Phase 10 menyediakan flow permintaan penghapusan yang dapat diakses dari
aplikasi. Kebijakan retensi dan purge production final tetap diverifikasi pada
Phase 13.

- [ ] Tambahkan entry “Hapus akun” pada area akun yang mudah ditemukan.
- [ ] Jelaskan dampak terhadap program, submission, skor, private media, dan
  akses akun dengan Bahasa Indonesia yang tidak menyesatkan.
- [ ] Minta reauthentication untuk tindakan sensitif.
- [ ] Client memanggil authenticated server operation; jangan memasukkan
  `service_role` atau Auth Admin API ke aplikasi.
- [ ] Tentukan apakah produk memakai immediate deletion atau
  request-and-retention sebelum implementation destructive dibuat.
- [ ] Jika memakai request, simpan status, requested-at, cancellation window,
  dan audit minimum tanpa data sensitif.
- [ ] Hentikan atau revoke session sebelum/finalisasi deletion; menghapus
  `auth.users` saja tidak langsung membuat JWT lama tidak valid.
- [ ] Bersihkan atau pindahkan ownership private Storage sebelum Auth user
  dihapus karena object ownership dapat memblokir deletion.
- [ ] Hapus pending enrollment intent dan local Keychain state.
- [ ] Tangani participant dengan enrollment aktif dan Coach/Admin dengan
  responsibility yang belum dialihkan melalui policy server yang eksplisit.
- [ ] Jangan menghapus audit/financial record yang wajib dipertahankan tanpa
  retention policy.
- [ ] Uji retry, partial cleanup, already requested, cancellation, expired
  session, dan network interruption.
- [ ] Phase 13 memverifikasi retention, privacy disclosure, hosted purge,
  session revocation, dan App Store review requirement.

## Error mapping dan UX

- [ ] Tambahkan typed auth errors pada domain boundary.
- [ ] Map pesan ke Bahasa Indonesia tanpa menampilkan raw Supabase/provider
  error.
- [ ] Bedakan validation, invalid credential, verification required,
  cancelled, rate limited, offline, timeout, callback mismatch, conflict,
  expired session, revoked session, profile provisioning, role load, dan
  unknown.
- [ ] Sediakan retry hanya untuk operasi yang aman.
- [ ] Tombol submit mempunyai loading state dan mencegah request ganda.
- [ ] Jangan mengungkap apakah email tertentu terdaftar pada login recovery.
- [ ] Pastikan semua runtime `String(localized:)` memiliki Bahasa Indonesia
  `defaultValue`.
- [ ] Uji copy dengan device locale `en_US` agar localization key tidak
  terlihat.
- [ ] Uji Dynamic Type, VoiceOver, Reduce Motion, light/dark mode, keyboard,
  password AutoFill, dan error focus.
- [ ] Provider chooser tetap tampil sebelum form email dan Login tidak
  autofocus atau membuka keyboard otomatis.
- [ ] Login/Register mempertahankan `.largeTitle.bold`, tidak memakai
  `minimumScaleFactor`, tidak mengecil saat destination berubah, dan membungkus
  secara alami pada Dynamic Type besar.
- [ ] Login menjadi root navigation; Register, form email, Forgot Password,
  profil, QR, eligibility, dan pembayaran mempertahankan typed back history.
- [ ] Native leading-edge swipe bekerja pada destination Auth. Edge swipe
  root Login menutup Auth tanpa bertabrakan dengan scroll/carousel.
- [ ] Membatalkan onboarding Participant atau Coach membuang draft dan kembali
  ke Guest tanpa membuka shell account parsial.

## Dokumentasi yang wajib diperbarui

- [ ] Perbarui phase checklist dan progress log setelah setiap gate yang
  benar-benar diverifikasi.
- [ ] Perbarui `PROGRAM_END_TO_END_IMPLEMENTATION_STATUS.md` untuk membedakan
  local Auth foundation, external provider gate, dan hosted production.
- [ ] Perbarui `PROGRAM_END_TO_END_CONTRACT_MATRIX.md` bila field profile,
  provisional identity, atau owner operation berubah.
- [ ] Perbarui `Contracts/program-api-v1.openapi.yaml` hanya untuk endpoint
  aplikasi/server yang memang menjadi kontrak; jangan mendokumentasikan
  endpoint internal Auth secara spekulatif.
- [ ] Perbarui `supabase/README.md` dengan migration, Auth test, local inbox,
  callback, reset, dan cleanup verification yang benar-benar tersedia.
- [ ] Perbarui `UI_REFERENCE_SHEET.md` hanya bila perilaku Auth production
  berbeda dari kontrak UI Phase 09.5 yang sudah disetujui.
- [ ] Catat manual Xcode step untuk URL scheme/capability tanpa mengedit
  `project.pbxproj`, entitlements, signing, atau capability tanpa persetujuan.

## Urutan implementasi

Kerjakan satu gate pada satu waktu.

### Gate A — Local Auth backend

1. Hidupkan Colima dan Supabase lokal bila diperlukan sesuai `AGENTS.md`.
2. Verifikasi CLI/config keys dan Auth endpoint dari dokumentasi versi aktif.
3. Buat migration profile bootstrap, field level member,
   onboarding/provisional status, allowlisted profile operation, role
   hardening, dan provisional identity cleanup baru.
4. Pertahankan migration deadline yang sudah ada; jangan mengubah history
   migration Phase 09 atau migration 5 Agustus.
5. Tambahkan pgTAP serta Auth API integration tests.
6. Jalankan fresh reset, lint, advisors, grants, RLS, signup, dan cleanup
   tests.

### Gate B — iOS session foundation

1. Tambahkan environment modes dan validation.
2. Tambahkan Supabase Auth transport boundary.
3. Perluas `SessionRepository` sebagai lifecycle owner dan ubah
   `AuthenticationRepository` menjadi façade command tanpa token state kedua.
4. Tambahkan Keychain store dan actor untuk refresh coordination.
5. Tambahkan `SessionStore` serta root state machine.
6. Pertahankan local demo dan seluruh mock tests.

### Gate C — Email/password dan enrollment intent

1. Registrasi, provisional identity, profile provisioning, dan cancellation.
2. Verification/resend.
3. Login/logout/session restoration.
4. Forgot/reset password callback.
5. Pending enrollment intent secure persistence dan resume.
6. Revalidasi registration cutoff dan pastikan Participant tidak dapat
   memanggil Admin override.
7. Local Auth E2E pada Simulator.

### Gate D — Provider-ready source

1. Typed callback router dan PKCE/state storage.
2. Google `ASWebAuthenticationSession` adapter dengan fake tests.
3. Native Sign in with Apple adapter dengan fake credential tests.
4. Identity-linking state dan duplicate-profile tests.

### Gate E — External provider validation

1. Konfigurasi Google Cloud dan Supabase provider.
2. Konfigurasi Apple capability/provider.
3. Verifikasi Google dan Apple pada iPhone fisik.
4. Selesaikan account collision, relay email, revocation, dan deletion tests.

### Gate F — Hosted production release gate

1. Selesaikan Phase 11/12 backend gate yang diperlukan.
2. Ulangi seluruh migration/security/auth tests.
3. Review migration diff sebelum hosted deployment.
4. Deploy hanya setelah persetujuan production eksplisit.
5. Konfigurasi SMTP, redirect allowlist, provider secrets, rate limits,
   session policy, dan production email templates.
6. Verifikasi hosted callbacks dan production build pada perangkat fisik.

## Test matrix

### Domain dan state

- [ ] Auth state machine.
- [ ] Root route untuk semua session/profile/onboarding state.
- [ ] Email normalization dan validation.
- [ ] Password requirement presentation.
- [ ] Typed error mapping.
- [ ] Callback parser dan state/nonce/PKCE validation.
- [ ] Pending enrollment intent TTL dan consumption.
- [ ] Provisional identity state, cancellation, cleanup terjadwal, dan expiry.
- [ ] Registration cutoff berubah selama Auth berlangsung.
- [ ] Session expiry dan role-load failure.
- [ ] Account switch membersihkan private state.

### Database dan Auth API lokal

- [ ] Signup membuat tepat satu Participant profile.
- [ ] Signup baru memulai status provisional dan tidak membuka role shell
  sampai finalization server selesai.
- [ ] Empty/malformed display metadata tidak memblokir signup.
- [ ] Client-supplied Coach/Admin role diabaikan.
- [ ] Member level tidak dapat dipakai sebagai authorization claim.
- [ ] Auth/profile operation tidak dapat membuat Coach application, menulis
  payment verified, atau mengirim keputusan Admin.
- [ ] Profile user hanya dapat mengubah nama, nomor HP, dan level member
  miliknya melalui allowlisted operation.
- [ ] Concurrent/repeated bootstrap tetap idempoten.
- [ ] Authenticated user hanya membaca profile yang diizinkan RLS.
- [ ] User tidak dapat INSERT/UPDATE role/current Coach/approval/QR.
- [ ] Email verification dan resend.
- [ ] Password login.
- [ ] Forgot/reset password.
- [ ] Logout dan revoked refresh.
- [ ] Refresh rotation, concurrent refresh, reuse, dan network-loss recovery.
- [ ] Expired access token menghasilkan satu refresh/retry.
- [ ] Profile trigger failure terdeteksi dan tidak menghasilkan partial state
  yang diklaim sukses.
- [ ] Provisional cleanup hanya dapat menghapus identity baru yang belum
  mempunyai protected relationship dan bersifat idempoten.
- [ ] Self-enrollment menolak cutoff memakai server clock; authenticated
  Participant tidak dapat EXECUTE `admin_enroll_participant`.
- [ ] Advisors tidak menemukan security blocker baru.

### iOS integration

- [ ] Keychain save/load/delete.
- [ ] Session restoration setelah relaunch.
- [ ] Offline launch dengan cached session yang expired.
- [ ] Local demo tetap berjalan saat Colima mati.
- [ ] Debug Supabase mode memberi error actionable saat Colima mati.
- [ ] Login success memuat protected role.
- [ ] Login identity provisional membuka resume/cleanup onboarding, bukan
  Participant shell.
- [ ] Pending intent bertahan melalui signup/login/callback.
- [ ] Program dan cutoff dimuat ulang sebelum scanner/enrollment dilanjutkan.
- [ ] Cutoff yang terlewati saat Auth menghasilkan pesan actionable dan
  mengakhiri join intent tanpa enrollment.
- [ ] Free enrollment melanjutkan melalui RPC Phase 09.
- [ ] Wrong-Coach QR ditolak sebelum enrollment/payment.
- [ ] Password reset membuka route yang benar.
- [ ] Callback ganda tidak membuat session/enrollment ganda.
- [ ] Token/QR/email/private data tidak muncul pada captured logs.

### UI

- [ ] Register.
- [ ] Email verification notice.
- [ ] Login.
- [ ] Forgot password.
- [ ] Reset password.
- [ ] Provider loading/cancel/error.
- [ ] Login/Register tidak mengecil, tidak autofocus, dan native swipe-back
  tetap bekerja setelah real Auth adapter dipasang.
- [ ] Cancel Participant/Coach kembali ke Guest tanpa draft lokal atau shell
  account parsial.
- [ ] Session expired.
- [ ] Profile provisioning failure.
- [ ] Account deletion request.
- [ ] Bahasa Indonesia ketika device locale `en_US`.
- [ ] Dynamic Type dan VoiceOver.

### External

- [ ] Google pada Simulator.
- [ ] Google pada iPhone fisik.
- [ ] Sign in with Apple pada iPhone fisik.
- [ ] Apple hidden relay email.
- [ ] Apple revoked credential.
- [ ] Email → Google dan Google → email.
- [ ] Apple relay tetap terpisah kecuali linked.
- [ ] Hosted email verification/reset callback.
- [ ] Hosted session restoration/revocation.
- [ ] Hosted account deletion/retention flow.

## Command verifikasi

Command exact harus diperiksa melalui `--help` pada CLI yang terpasang sebelum
dijalankan. Baseline local:

```bash
colima status
docker info
supabase status
supabase start
supabase db reset --local
supabase db lint --local --level warning --fail-on error
supabase db advisors --local --type all --level warn --fail-on error
supabase test db --local supabase/tests/database
```

Tambahkan script integration Phase 10 yang:

- Hanya menerima local Supabase URL.
- Menolak hosted hostname.
- Membuat identity test deterministic.
- Tidak mencetak email nyata, password, token, callback code, atau QR.
- Membersihkan identity/media test yang dibuat.
- Menguji signup, verification, login, refresh, reset, profile, dan role.

Verifikasi iOS minimum:

```bash
xcodebuild test \
  -project MSCBodyTransformation.xcodeproj \
  -scheme MSCBodyTransformation \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=<SIMULATOR_ID>' \
  -parallel-testing-enabled NO \
  -only-testing:MSCBodyTransformationTests
```

```bash
xcodebuild \
  -project MSCBodyTransformation.xcodeproj \
  -scheme MSCBodyTransformation \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Gunakan destination yang benar-benar tersedia saat eksekusi; jangan menyalin
simulator ID lama tanpa pemeriksaan.

## External gate dan manual configuration

Pekerjaan berikut tidak boleh ditandai selesai dari mock:

| Gate | Yang diperlukan |
|---|---|
| iOS callback scheme | Perubahan target/Xcode configuration yang disetujui |
| Google OAuth | Google Cloud project, client ID/secret, consent screen |
| Apple login | Apple Developer membership, capability, App/Services ID |
| Physical validation | iPhone fisik dan signing yang valid |
| Hosted Auth | Deployment production yang disetujui |
| Production email | SMTP, sender domain, templates, redirect allowlist |
| Production session | JWT/session policy dan revocation verification |
| Account purge | Retention policy, Storage cleanup, hosted server operation |

External gate tidak menghentikan Gate A sampai Gate D yang dapat dikerjakan
lokal.

## Exit criteria

### Local exit criteria

- [ ] Fresh local reset, lint, advisors, pgTAP, dan Auth integration tests
  lulus.
- [ ] Signup selalu membuat tepat satu Participant profile.
- [ ] Role self-promotion melalui metadata, Data API, atau callback mustahil.
- [ ] Nama, nomor HP, dan level member tersimpan melalui allowlisted operation
  tanpa memberi role Coach atau akses ke field privileged.
- [ ] Handoff Coach terautentikasi tersedia tanpa mengklaim operasi
  application/payment/approval Phase 11–12 sudah selesai.
- [ ] Provisional identity tidak membuka role shell; cancel membersihkan draft,
  intent, session lokal, dan menjalankan cleanup server idempoten bila perlu.
- [ ] Email/password registration, verification, login, logout, recovery, dan
  restoration berjalan pada Supabase lokal.
- [ ] Token tersimpan aman, refresh terkoordinasi, dan session expiry tertangani.
- [ ] Root route berasal dari session + protected profile + onboarding state.
- [ ] Pending enrollment intent bertahan melewati auth dan dikonsumsi aman.
- [ ] Cutoff pendaftaran divalidasi ulang dengan server clock setelah Auth;
  Participant tidak dapat memakai override Admin.
- [ ] Provider-first layout, ukuran teks, keyboard behavior, typed navigation,
  dan swipe-back Phase 09.5 tidak mengalami regresi.
- [ ] Local demo tetap berjalan tanpa Colima atau internet.
- [ ] Debug Supabase mode tidak dapat salah menyasar hosted production.
- [ ] Release tidak dapat memakai local endpoint atau Debug credential.
- [ ] Source Google/Apple adapter dan fake tests siap tanpa secret.
- [ ] Tidak ada token, raw QR Coach, password, provider secret, atau private
  data pada source, bundle, fixture, dan log.
- [ ] Full Swift tests dan simulator build lulus.
- [ ] Dokumentasi Phase 10, status implementasi, contract matrix, OpenAPI bila
  relevan, dan `supabase/README.md` konsisten dengan hasil yang benar-benar
  diverifikasi.

### External/production exit criteria

- [ ] Google OAuth membuat dan memulihkan Supabase session pada iPhone fisik.
- [ ] Sign in with Apple membuat dan memulihkan Supabase session pada iPhone
  fisik.
- [ ] Identity linking tidak membuat duplicate application profile.
- [ ] Hosted verification/reset/OAuth callback menggunakan allowlist yang
  benar.
- [ ] New hosted registration selalu menjadi Participant.
- [ ] Coach/Admin tidak dapat diperoleh melalui self-registration.
- [ ] Account deletion request dapat diakses dan hosted lifecycle diverifikasi.
- [ ] Production Auth secrets hanya berada pada provider/server configuration.
- [ ] Hosted security/advisors/Auth tests lulus setelah deployment yang
  disetujui.

Phase 10 tidak boleh diberi status selesai penuh hanya karena local/fake tests
lulus. Jika external provider belum tersedia, tandai “local foundation
selesai; external provider gate belum selesai”.

## Referensi resmi yang wajib diperiksa saat eksekusi

Supabase berubah cepat. Sebelum mengimplementasikan setiap gate, periksa
changelog `breaking-change`, dokumentasi versi aktif, dan CLI `--help`.

- Supabase changelog:
  `https://supabase.com/changelog?types=breaking-change`
- Auth overview:
  `https://supabase.com/docs/guides/auth`
- Password auth:
  `https://supabase.com/docs/guides/auth/passwords`
- Native mobile deep linking:
  `https://supabase.com/docs/guides/auth/native-mobile-deep-linking`
- User sessions:
  `https://supabase.com/docs/guides/auth/sessions`
- User/profile management:
  `https://supabase.com/docs/guides/auth/managing-user-data`
- Identity linking:
  `https://supabase.com/docs/guides/auth/auth-identity-linking`
- Google login:
  `https://supabase.com/docs/guides/auth/social-login/auth-google`
- Apple login:
  `https://supabase.com/docs/guides/auth/social-login/auth-apple`

Jangan menyalin endpoint, payload, callback parameter, config key, SDK method,
atau capability setting dari ingatan. Verifikasi terhadap versi yang
benar-benar digunakan.

## Progress log

### 5 Agustus 2026 — Direkonsiliasi dengan deadline dan Auth UI terbaru

- Files changed:
  - `MSCBodyTransformation/MSC_Codex_Phased_Workplan/11_PHASE_10_AUTH_EMAIL_GOOGLE_APPLE.md`.
- Source/contract baseline:
  - Migration `20260805013707_program_registration_deadline.sql`,
    `admin_enroll_participant`, DTO/repository iOS, 89 pgTAP assertions, dan
    14 race assertions sudah tersedia dan lulus lokal.
  - Guest/Auth UI Phase 09.5 sudah provider-first, tidak autofocus, memakai
    typed navigation, mendukung native swipe-back, dan membuang draft saat
    dibatalkan.
  - `PendingAuthenticatedIntent` source masih hanya membawa program ID atau
    tujuan profile dan harus dimigrasikan pada Phase 10.
- Decisions:
  - Session/token hanya dimiliki `SessionRepository`; existing
    `AuthenticationRepository` dipertahankan sebagai command façade.
  - Phase 10 menyimpan field profil dan menyiapkan authenticated handoff.
    Coach application/approval tetap Phase 11; payment/entitlement tetap
    Phase 12.
  - Cutoff selalu divalidasi ulang dengan server clock setelah Auth.
    Participant tidak pernah mendapat jalur Admin override.
  - Identity baru yang belum selesai diperlakukan provisional; pembatalan
    membersihkan state lokal dan memakai cleanup server idempoten bila
    identity Supabase sudah terbentuk.
- Verification:
  - Workplan dibandingkan dengan implementation status dan contract matrix
    tanggal 5 Agustus, Phase 09.5, source Auth/current intent, migration
    deadline, UI Reference Sheet, dan Supabase changelog breaking changes
    terkini.
- Build/Test:
  - Tidak dijalankan; perubahan hanya dokumentasi workplan.
- Remaining external gates:
  - Callback scheme target iOS.
  - Google Cloud credential dan consent screen.
  - Apple capability/provider configuration.
  - Hosted production deployment/configuration.
  - Verifikasi Google dan Apple pada iPhone fisik.

### 4 Agustus 2026 — Workplan direkonsiliasi setelah Phase 09

- Files changed:
  - `MSCBodyTransformation/MSC_Codex_Phased_Workplan/11_PHASE_10_AUTH_EMAIL_GOOGLE_APPLE.md`.
- Assumptions:
  - Development tetap memakai Supabase lokal melalui Colima.
  - Hosted `main` tetap production dan belum disentuh.
  - Native Foundation adapter Phase 09 dipertahankan.
  - Tidak ada dependency baru tanpa persetujuan eksplisit.
  - Google/Apple/hosted production/physical-device validation tetap external
    gate.
- Verification:
  - Workplan dibandingkan dengan Phase 09, app session architecture,
    migration/profile/RLS baseline, dan kontrak E2E terbaru.
  - Dokumentasi resmi Supabase untuk changelog, password auth, mobile deep
    link, session, user management, identity linking, Google, dan Apple
    diperiksa.
- Result:
  - Workplan lama diganti dengan gate lokal dan external yang dapat diverifikasi.
  - Istilah `pending invite` dihapus dari requirement aktif Phase 10.
- Build:
  - Tidak dijalankan; perubahan hanya dokumentasi workplan.
- Test:
  - Tidak dijalankan; tidak ada perubahan source, migration, configuration,
    atau Xcode project.
- Remaining blockers:
  - Callback scheme target iOS.
  - Google Cloud credential dan consent screen.
  - Apple capability/provider configuration.
  - Hosted production deployment/configuration.
  - Verifikasi Google dan Apple pada iPhone fisik.

### 4 Agustus 2026 — Handoff Phase 09.5 ditambahkan

- Files changed:
  - `MSCBodyTransformation/MSC_Codex_Phased_Workplan/11_PHASE_10_AUTH_EMAIL_GOOGLE_APPLE.md`.
- Result:
  - Phase 10 sekarang menunggu local UI Phase 09.5.
  - Guest tetap logged-out access state.
  - Self-registration tetap Participant.
  - Pilihan Coach diperlakukan sebagai application, bukan role assignment.
  - Persistensi level, eligibility, payment status, dan Admin decision
    ditambahkan sebagai backend handoff.
- Build/Test:
  - Tidak dijalankan; perubahan hanya dokumentasi workplan.
- Remaining blockers:
  - Migration/RLS/operation Coach application pada Phase 11.
  - StoreKit verification dan entitlement pada Phase 12.

### 4 Agustus 2026 — Phase 09.5 selesai sebagai local UI contract

- Guest logged-out shell, centralized auth gate, Login/Register/Forgot
  Password, provider presentation, onboarding profil, sembilan Member level,
  Coach application, fake payment tiga bulan, dan Admin review tersedia.
- Phase 10 harus mengganti fake auth adapter di boundary yang sama; jangan
  membuat `AuthRepository`/navigation flow duplikat.
- `AuthenticationRepository`, `SessionRepository`, `AppSession`,
  `ParticipantJourneyStore`, dan Keychain adapter Phase 10 harus
  direkonsiliasi sebagai satu session lifecycle.
- Profile bootstrap tetap selalu Participant. Member level/application
  persistence tidak boleh menjadi authorization claim.
- Backend Coach application approval tetap Phase 11 dan payment verification
  serta entitlement tetap Phase 12.
