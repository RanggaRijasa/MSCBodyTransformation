# Phase 10: Authentication and Session

> Status: **fondasi lokal dan immediate account deletion diterapkan; Google,
> Apple, hosted deployment, dan perangkat fisik tetap gate aktif**. Migration, profile
> bootstrap/hardening, session/Keychain, PKCE callback, email/password source,
> pending intent, callback scheme/capability, adapter source Google/Apple, serta
> Auth lifecycle E2E lokal tersedia. Hanya SMTP/domain serta aktivasi
> email/password production yang berstatus `SKIPPED SAAT INI`.
>
> Email/password, profile bootstrap, session lifecycle, callback routing,
> pending enrollment intent, role protection, dan sebagian besar pengujian
> dikerjakan menggunakan Supabase lokal melalui Colima. Google OAuth dan
> provider Apple native sudah aktif lokal. Validasi manual Sign in with Apple,
> callback hosted production, dan verifikasi perangkat fisik tetap menjadi
> external gate.
>
> Pilihan email/password dan Forgot Password disembunyikan dari UI aktif
> sampai domain pengirim dan SMTP production tersedia. Implementasi serta
> pengujian lokal tetap dikerjakan di Phase 10 di belakang configuration flag;
> pengaktifan UI menjadi external release gate.
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
- Provider chooser Phase 09.5 dipertahankan tanpa autofocus. Apple dan Google
  tampil sekarang; pilihan email baru ditampilkan setelah domain/SMTP gate
  selesai dan tetap membuka form terpisah.
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

- [x] Migration idempoten membuat profil Participant saat row
  baru dibuat pada `auth.users`.
- [x] `public.profiles` mempunyai field level member dan operation
  allowlisted untuk menyimpan nama, nomor HP, serta level tanpa membuka
  perubahan role atau field privileged.
- [x] Onboarding/provisional status dan expiry server-controlled
  yang dapat membedakan identity Auth dari application account aktif.
- [x] Backfill aman tersedia untuk identity yang sudah ada tanpa profil.
- [x] Auth API client dan token lifecycle tersedia pada aplikasi.
- [x] `SessionRepository` mendukung registration, login, logout,
  refresh, password recovery, dan auth-state observation.
- [x] `AppConfiguration.Mode` membedakan demo lokal, Supabase lokal, dan hosted.
- [x] Root non-demo tidak membuka shell role tanpa session dan protected profile.
- [x] Token disimpan pada Keychain device-only tanpa sinkronisasi.
- [x] Callback scheme didaftarkan pada target iOS.
- [x] UI email/password tersedia dari Phase 09.5 dan dipertahankan di source,
  tetapi entry point-nya disembunyikan melalui configuration flag.
- [x] Command email/password environment-neutral terhubung ke adapter
  Supabase Auth.
- [x] Pending enrollment intent membawa TTL, nonce, environment, dan QR Coach
  opaque pada secure storage.
- [x] Pending program intent direvalidasi melalui operasi server setelah login,
  verification, OAuth callback, dan app relaunch; status, cutoff server, serta
  kapasitas yang berubah selama auth membatalkan intent lokal.
- [x] Lifecycle provisional identity membedakan login account
  lama dari identity baru yang belum menyelesaikan onboarding.
- [x] Cleanup idempoten tersedia untuk identity baru yang dibatalkan sebelum
  QR Participant atau handoff Coach selesai.
- [ ] Provider Google/Apple production belum dikonfigurasi.
- [x] Immediate account deletion dapat diakses dari area akun setelah
  reauthentication.
- [ ] Hosted production Auth belum dikonfigurasi.

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

- [x] Tambahkan mode `debugLocalSupabase` dan `hostedProduction`.
- [x] Buat configuration loader yang memvalidasi kombinasi build dan endpoint.
- [x] Pastikan Release menolak local/HTTP endpoint.
- [x] Pastikan Debug local tidak dapat memakai hosted `main` tanpa pilihan
  eksplisit.
- [x] Tambahkan test matriks build × mode × endpoint.
- [x] Dokumentasikan cara Simulator dan perangkat fisik mencapai Auth lokal.
- [x] Jangan menaruh token atau provider secret dalam `.xcconfig`, plist,
  source Swift, test fixture, atau repository.

## Keputusan dependency

- [x] `supabase-swift` sudah dievaluasi pada Phase 09 dan tidak ditambahkan.
- [x] Native Foundation `URLSession` sudah menjadi boundary Supabase Phase 09.
- [x] Perluas boundary native tersebut untuk Auth setelah endpoint,
  payload, PKCE, callback, dan refresh behavior diperiksa pada dokumentasi
  Supabase yang berlaku saat implementasi.
- [x] Isolasi Auth transport di belakang `SupabaseAuthClientProviding`.
- [x] Jangan memasukkan DTO Auth atau Supabase ke domain model.
- [x] Jangan menambahkan package Google Sign-In atau package auth lain tanpa
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

- [x] Tambahkan domain command/value yang tidak membawa tipe Supabase:
  email credential, registration request, auth provider, dan recovery state.
- [x] Perluas `SessionRepository` untuk register, login, logout, restore,
  refresh, request reset, update password, dan auth-state updates.
- [x] Ubah method `...ForDemo` pada `AuthenticationRepository` menjadi
  command environment-neutral atau adapter façade yang mendelegasikan ke
  local demo maupun Supabase tanpa mengubah navigation flow.
- [x] Pastikan hanya satu Keychain store, refresh coordinator, dan session
  observation stream yang hidup untuk satu app environment.
- [x] Pertahankan method Debug-only terisolasi dari production adapter.
- [x] Tambahkan `SessionStore` berbasis Observation pada app layer.
- [x] Gunakan `AsyncStream` atau mekanisme structured-concurrency yang
  ownership dan cancellation-nya jelas untuk perubahan auth state.
- [x] Root route membedakan:
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
- [x] Root route tidak pernah memilih shell hanya dari metadata provider.
- [x] Token valid dan protected profile yang berhasil dimuat belum cukup untuk
  membuka role shell; onboarding/finalization status juga harus selesai.
- [x] Role-load failure tidak boleh jatuh ke Participant secara diam-diam.
- [x] Root Debug tetap dapat memilih local demo secara eksplisit.
- [x] Root Release tidak boleh membuka shell Participant ketika tidak ada
  session.

## Profile bootstrap dan role hardening

Migration Phase 10 harus dibuat dengan
`supabase migration new <descriptive_name>` saat implementasi dimulai.
Jangan mengedit migration Phase 09 yang sudah ada.

Profile bootstrap:

- [x] Buat trigger setelah INSERT pada `auth.users` yang membuat
  `public.profiles` secara idempoten.
- [x] Set role secara literal menjadi `participant`; abaikan `role`,
  `current_coach_id`, Coach approval, dan Coach QR dari user metadata.
- [x] Set onboarding/provisional status dan expiry secara server-controlled;
  abaikan field sejenis dari user metadata atau request client.
- [x] Gunakan metadata hanya untuk field display/onboarding yang tidak
  authoritative setelah disanitasi.
- [x] Sediakan fallback display name yang valid agar metadata kosong tidak
  menggagalkan signup.
- [x] Simpan privileged helper di schema non-exposed `private`.
- [x] Gunakan explicit empty `search_path`.
- [x] Revoke EXECUTE dari `PUBLIC`, `anon`, dan `authenticated`.
- [x] Berikan privilege minimum yang benar kepada role Auth/trigger sesuai
  dokumentasi dan local runtime yang benar-benar terpasang.
- [x] Trigger failure terlihat sebagai signup failure yang terpetakan,
  bukan diabaikan.
- [x] Tambahkan backfill idempoten untuk local test users yang sudah ada tanpa
  profile, bila diperlukan.
- [x] Jangan memberi INSERT/UPDATE profile langsung kepada client untuk
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

- [x] Simpan material session minimum yang dibutuhkan pada Keychain dengan
  accessibility device-only yang sesuai.
- [x] Jangan simpan access token atau refresh token pada UserDefaults,
  `@AppStorage`, fixture, analytics, crash breadcrumb, atau log.
- [x] Jangan aktifkan Keychain sync lintas perangkat.
- [x] Isolasi mutable session/token state di dalam actor.
- [x] Serialisasi refresh request agar satu refresh token tidak dipakai oleh
  beberapa task secara bersamaan.
- [x] Ganti access dan refresh token secara atomik setelah refresh berhasil.
- [x] Gunakan expiry dari server; jangan menganggap jam perangkat
  authoritative.
- [x] Refresh proaktif dengan tolerance untuk clock skew.
- [ ] Untuk response unauthorized, lakukan paling banyak satu coordinated
  refresh dan satu retry bila operation aman diulang.
- [x] Jangan retry registration, password reset, account deletion, atau
  mutation non-idempoten secara buta.
- [x] Bedakan offline, timeout, invalid credential, unverified email,
  refresh revoked/reused, session expired, rate limit, conflict, dan unknown.
- [x] Logout menghapus session lokal walaupun network revoke gagal, lalu
  memberi status yang jujur bila revoke server belum terkonfirmasi.
- [ ] Session expiry menghapus private in-memory state dan mengarahkan user ke
  auth tanpa membocorkan data role sebelumnya.
- [x] App relaunch memulihkan session dari Keychain, refresh bila perlu, lalu
  memuat protected profile.
- [x] Jangan log header Authorization, callback code, token hash, nonce,
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

- [ ] **SKIPPED SAAT INI** — Samakan local Auth configuration dengan behavior
  hosted yang akan digunakan; local default dan hosted default tidak boleh
  diasumsikan sama.
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
- [x] Daftarkan custom URL scheme pada target iOS.
- [x] Perubahan target, capability, entitlements, dan `project.pbxproj`
  dilakukan setelah instruksi/persetujuan eksplisit user.
- [x] Gunakan satu parser typed untuk email verification, password recovery,
  OAuth success, OAuth cancellation, dan provider error.
- [x] Validasi scheme, host, path, state, nonce, PKCE verifier, environment,
  dan expected flow.
- [x] Callback yang tidak cocok dengan flow aktif harus ditolak.
- [x] Callback ganda harus idempoten.
- [x] Callback tidak memuat atau mencatat raw QR Coach.
- [x] Simpan PKCE verifier dan OAuth state secara aman serta berumur pendek.
- [x] Gunakan `ASWebAuthenticationSession` untuk browser OAuth.
- [ ] Gunakan ephemeral browser session hanya bila tradeoff UX sudah diputuskan.
- [x] Selesaikan callback pada app lifecycle API yang benar tanpa networking
  langsung di SwiftUI `body`.
- [ ] **SKIPPED SAAT INI** — Tambahkan universal link bila domain production
  tersedia; custom scheme tetap dibatasi dengan state/PKCE.

## Google OAuth

Pekerjaan lokal yang dapat disiapkan tanpa production credential:

- [x] Tambahkan provider enum, use case, state machine, error mapping, dan
  callback parser.
- [x] Implementasikan browser OAuth melalui `ASWebAuthenticationSession`
  dengan PKCE berdasarkan endpoint Supabase yang diverifikasi saat eksekusi.
- [x] Handle start, cancel, callback mismatch, provider error, duplicate
  callback, dan app relaunch.
- [x] Jangan meminta Google scope di luar `openid`, email, dan profile tanpa
  alasan produk eksplisit.
- [x] Jangan menyimpan Google provider access/refresh token karena aplikasi
  tidak membutuhkan Google API.
- [x] Jangan mengotorisasi role dari Google claims/profile.
- [ ] Tambahkan fake provider tests tanpa credential nyata.

External gate — **AKTIF**:

- [ ] Google Cloud project dan consent-screen audience tersedia.
- [ ] Branding, privacy URL, support email, dan approved scopes tersedia.
- [ ] OAuth Web client ID dan client secret tersedia untuk Supabase provider.
- [ ] Local callback Auth
  `http://127.0.0.1:54321/auth/v1/callback`
  dikonfigurasi untuk pengujian lokal sesuai dokumentasi terbaru.
- [ ] Secret Google lokal hanya masuk environment variable yang diabaikan Git.
- [ ] Hosted Supabase callback dan production redirect allowlist
  dikonfigurasi.
- [ ] Google login diverifikasi pada Simulator dan iPhone fisik.
- [ ] **SKIPPED SAAT INI** — Google kemudian email serta email kemudian Google
  menunggu aktivasi email/password production.

## Sign in with Apple

Pekerjaan source yang dapat disiapkan tanpa production credential:

- [x] Tambahkan native AuthenticationServices adapter.
- [x] Buat nonce acak per attempt, kirim hash yang benar ke Apple, dan
  verifikasi nonce yang sama pada exchange Supabase.
- [x] Exchange Apple identity token melalui Supabase Auth endpoint yang
  didokumentasikan saat implementasi.
- [ ] Tangani cancel, missing token, invalid nonce, revoked credential,
  duplicate callback, dan relay email.
- [ ] Ambil nama hanya dari first native authorization response bila tersedia.
- [ ] Sanitasi nama untuk display/onboarding; jangan gunakan nama/email Apple
  untuk authorization.
- [x] Jangan menyimpan Apple identity token atau authorization code.
- [ ] Tambahkan fake credential tests tanpa key atau token nyata.

External gate — **AKTIF**:

- [x] Apple Developer membership tersedia.
- [x] Bundle ID final tersedia.
- [x] Sign in with Apple capability diaktifkan pada target iOS.
- [x] App ID `com.ranggar.MSCBodyTransformation` dikonfigurasi sebagai primary
  App ID dan provider Apple native diaktifkan pada Supabase lokal.
- [x] Flow yang dipilih adalah native-only, sehingga Services ID, private key,
  dan OAuth client secret Apple tidak diperlukan.
- [ ] Provider Apple hosted production belum dikonfigurasi.
- [ ] Jika OAuth web Apple digunakan, rotasi secret enam bulanan dicatat
  sebagai operational task; native-only flow tidak diberi kewajiban rotasi
  yang tidak berlaku.
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
- [ ] **SKIPPED SAAT INI** — Test email → Google dan Google → email.
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

- [x] Tambahkan entry “Hapus akun” pada area akun yang mudah ditemukan.
- [x] Jelaskan dampak terhadap program, submission, skor, private media, dan
  akses akun dengan Bahasa Indonesia yang tidak menyesatkan.
- [x] Minta reauthentication untuk tindakan sensitif.
- [x] Client memanggil authenticated server operation; jangan memasukkan
  `service_role` atau Auth Admin API ke aplikasi.
- [x] Produk memakai immediate deletion setelah reauthentication.
- [x] Request-and-retention tidak dipakai; cancellation window dan status
  request tidak diperlukan.
- [x] Hentikan atau revoke session sebelum/finalisasi deletion; menghapus
  `auth.users` saja tidak langsung membuat JWT lama tidak valid.
- [x] Bersihkan ownership private Storage melalui Storage API sebelum Auth user
  dihapus karena object ownership dapat memblokir deletion.
- [x] Hapus pending enrollment intent dan local Keychain state.
- [x] Tangani participant dengan enrollment aktif dan Coach/Admin dengan
  responsibility yang belum dialihkan melalui policy server yang eksplisit.
- [x] Jangan menghapus audit/financial record yang wajib dipertahankan tanpa
  retention policy.
- [ ] Uji retry, partial cleanup, already requested, cancellation, expired
  session, dan network interruption.
- [ ] Phase 13 memverifikasi retention, privacy disclosure, hosted purge,
  session revocation, dan App Store review requirement.

## Error mapping dan UX

- [x] Tambahkan typed auth errors pada domain boundary.
- [x] Map pesan ke Bahasa Indonesia tanpa menampilkan raw Supabase/provider
  error.
- [x] Bedakan validation, invalid credential, verification required,
  cancelled, rate limited, offline, timeout, callback mismatch, conflict,
  expired session, revoked session, profile provisioning, role load, dan
  unknown.
- [x] Sediakan retry hanya untuk operasi yang aman.
- [x] Tombol submit mempunyai loading state dan mencegah request ganda.
- [x] Jangan mengungkap apakah email tertentu terdaftar pada login recovery.
- [x] Pastikan semua runtime `String(localized:)` memiliki Bahasa Indonesia
  `defaultValue`.
- [ ] Uji copy dengan device locale `en_US` agar localization key tidak
  terlihat.
- [ ] Uji Dynamic Type, VoiceOver, Reduce Motion, light/dark mode, keyboard,
  password AutoFill, dan error focus.
- [x] Provider chooser tetap tampil sebelum form email dan Login tidak
  autofocus atau membuka keyboard otomatis.
- [x] Configuration default menyembunyikan email/password dan Forgot Password
  tanpa menghapus route, state, localization, atau focused tests.
- [ ] **SKIPPED SAAT INI** — UI email/password hanya diaktifkan setelah domain
  pengirim, SMTP,
  redirect allowlist, verification, dan reset-password delivery production
  berhasil diverifikasi.
- [x] Login/Register mempertahankan `.largeTitle.bold`, tidak memakai
  `minimumScaleFactor`, tidak mengecil saat destination berubah, dan membungkus
  secara alami pada Dynamic Type besar.
- [x] Login menjadi root navigation; Register, form email, Forgot Password,
  profil, QR, eligibility, dan pembayaran mempertahankan typed back history.
- [x] Native leading-edge swipe bekerja pada destination Auth. Edge swipe
  root Login menutup Auth tanpa bertabrakan dengan scroll/carousel.
- [x] Membatalkan onboarding Participant atau Coach membuang draft dan kembali
  ke Guest tanpa membuka shell account parsial.

## Dokumentasi yang wajib diperbarui

- [x] Perbarui phase checklist dan progress log setelah setiap gate yang
  benar-benar diverifikasi.
- [x] Perbarui `PROGRAM_END_TO_END_IMPLEMENTATION_STATUS.md` untuk membedakan
  local Auth foundation, external provider gate, dan hosted production.
- [x] Perbarui `PROGRAM_END_TO_END_CONTRACT_MATRIX.md` bila field profile,
  provisional identity, atau owner operation berubah.
- [x] Perbarui `Contracts/program-api-v1.openapi.yaml` untuk endpoint
  aplikasi/server yang memang menjadi kontrak; jangan mendokumentasikan
  endpoint internal Auth secara spekulatif.
- [x] Perbarui `supabase/README.md` dengan migration, Auth test, local inbox,
  callback, reset, dan cleanup verification yang benar-benar tersedia.
- [x] `UI_REFERENCE_SHEET.md` tetap berlaku; immediate deletion memakai area
  akun destruktif dan copy Bahasa Indonesia yang sudah disetujui.
- [x] Dengan persetujuan user, URL scheme/capability diterapkan langsung pada
  target, Info.plist, entitlements, dan `project.pbxproj`.

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
- [x] Email normalization dan validation.
- [ ] Password requirement presentation.
- [x] Typed error mapping.
- [x] Callback parser dan state/nonce/PKCE validation.
- [x] Pending enrollment intent TTL dan consumption.
- [ ] Provisional identity state, cancellation, cleanup terjadwal, dan expiry.
- [ ] Registration cutoff berubah selama Auth berlangsung.
- [ ] Session expiry dan role-load failure.
- [ ] Account switch membersihkan private state.

### Database dan Auth API lokal

- [x] Signup membuat tepat satu Participant profile.
- [x] Signup baru memulai status provisional dan tidak membuka role shell
  sampai finalization server selesai.
- [x] Empty/malformed display metadata tidak memblokir signup.
- [x] Client-supplied Coach/Admin role diabaikan.
- [x] Member level tidak dapat dipakai sebagai authorization claim.
- [x] Auth/profile operation tidak dapat membuat Coach application, menulis
  payment verified, atau mengirim keputusan Admin.
- [x] Profile user hanya dapat mengubah nama, nomor HP, dan level member
  miliknya melalui allowlisted operation.
- [ ] Concurrent/repeated bootstrap tetap idempoten.
- [x] Authenticated user hanya membaca profile yang diizinkan RLS.
- [x] User tidak dapat INSERT/UPDATE role/current Coach/approval/QR.
- [ ] Email verification dan resend.
- [x] Password login.
- [x] Forgot/reset password.
- [ ] Logout dan revoked refresh.
- [ ] Refresh rotation, concurrent refresh, reuse, dan network-loss recovery.
- [ ] Expired access token menghasilkan satu refresh/retry.
- [ ] Profile trigger failure terdeteksi dan tidak menghasilkan partial state
  yang diklaim sukses.
- [ ] Provisional cleanup hanya dapat menghapus identity baru yang belum
  mempunyai protected relationship dan bersifat idempoten.
- [x] Self-enrollment menolak cutoff memakai server clock; authenticated
  Participant tidak dapat EXECUTE `admin_enroll_participant`.
- [x] Immediate account deletion memerlukan session baru, membersihkan data
  dan media melalui boundary server, serta mempertahankan record audit/finansial
  dalam bentuk anonim.
- [x] Advisors tidak menemukan security blocker baru.

### iOS integration

- [x] Keychain save/load/delete.
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
- [x] Password reset membuka route yang benar.
- [x] Callback ganda tidak membuat session/enrollment ganda.
- [x] Token/QR/email/private data tidak muncul pada captured logs.

### UI

- [ ] Register.
- [ ] Email verification notice.
- [ ] Login.
- [ ] Forgot password.
- [ ] Reset password.
- [ ] Provider loading/cancel/error.
- [x] Login/Register tidak mengecil, tidak autofocus, dan native swipe-back
  tetap bekerja setelah real Auth adapter dipasang.
- [ ] Cancel Participant/Coach kembali ke Guest tanpa draft lokal atau shell
  account parsial.
- [ ] Session expired.
- [ ] Profile provisioning failure.
- [x] Account deletion request.
- [x] Bahasa Indonesia ketika device locale `en_US`.
- [ ] Dynamic Type dan VoiceOver.

### External

- [ ] Google pada Simulator.
- [ ] Google pada iPhone fisik.
- [ ] Sign in with Apple pada iPhone fisik.
- [ ] Apple hidden relay email.
- [ ] Apple revoked credential.
- [ ] **SKIPPED SAAT INI** — Email → Google dan Google → email.
- [ ] Apple relay tetap terpisah kecuali linked.
- [ ] **SKIPPED SAAT INI** — Hosted email verification/reset callback.
- [ ] Hosted OAuth callback.
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

Keputusan produk 5 Agustus 2026: Google OAuth, Sign in with Apple, hosted
deployment, dan validasi perangkat fisik tetap aktif dan akan dikerjakan.
Hanya SMTP/domain serta email/password production yang berstatus
`SKIPPED SAAT INI`.

| Gate | Status | Yang diperlukan |
|---|---|---|
| iOS callback scheme | Selesai lokal | Target dan custom scheme terpasang |
| Google OAuth | AKTIF | Google Cloud project, client ID/secret, consent screen |
| Apple login | AKTIF | Apple Developer membership, App ID/provider, device test |
| Physical validation | AKTIF | iPhone fisik dan signing yang valid |
| Hosted Auth | AKTIF | Deployment production yang disetujui |
| Email/password UI | SKIPPED SAAT INI | Domain pengirim, SMTP, verification/reset delivery |
| Production email | SKIPPED SAAT INI | SMTP, sender domain, templates, redirect allowlist |
| Production session | AKTIF | JWT/session policy dan revocation verification |
| Account purge | AKTIF | Hosted retention review dan server-operation validation |

### Urutan eksekusi gate aktif

1. Siapkan atau konfirmasi project hosted Supabase `main`, lalu review
   `supabase db push --linked --dry-run` sebelum migration diterapkan.
2. Deploy migration dan Edge Function `delete-account`, kemudian set
   `mscbodytransformation://auth/callback` sebagai redirect mobile exact.
3. Aktifkan Google provider memakai OAuth Web client dan callback hosted
   Supabase.
4. Aktifkan native Sign in with Apple untuk App ID
   `com.ranggar.MSCBodyTransformation`, lalu daftarkan Bundle ID tersebut
   sebagai Apple Client ID di Supabase. Services ID dan OAuth secret tidak
   diperlukan untuk flow native-only.
5. Pasang hosted URL dan publishable key pada konfigurasi iOS Release/Run
   tanpa menaruh secret server di app.
6. Jalankan matriks Google, Apple, session restoration, role bootstrap,
   identity duplication, dan immediate account deletion pada iPhone fisik.
7. Jalankan hosted Security/Performance Advisors dan review hasil sebelum gate
   ditutup.

SMTP/domain tidak termasuk urutan ini. Provider Email tetap tersembunyi atau
dinonaktifkan sampai keputusan produk berubah.

### Yang perlu disiapkan

#### Google OAuth

User perlu menyediakan akses Google Cloud project dan keputusan audience
internal/external, nama produk, support email, privacy policy URL, terms URL,
serta domain yang sudah diverifikasi. Buat OAuth Web client untuk Supabase,
daftarkan callback yang ditampilkan halaman provider Supabase, lalu simpan
client ID/secret hanya pada provider configuration atau secret environment.
Untuk pengujian lokal, callback Auth adalah
`http://127.0.0.1:54321/auth/v1/callback`. Setelah aktif, uji login baru,
login ulang, pembatalan, account collision, dan linking pada Simulator serta
iPhone fisik.

#### Sign in with Apple

User perlu Apple Developer membership dengan role Account Holder/Admin,
keputusan Bundle ID final, dan akses Certificates, Identifiers & Profiles.
Aktifkan Sign in with Apple pada App ID final sebagai primary atau grouped
sesuai keluarga aplikasi, pastikan signing profile memuat entitlement, lalu
konfigurasikan provider Apple pada hosted Supabase. Services ID dan private
key hanya diperlukan bila flow OAuth web dipilih; flow native-only tidak
boleh diberi kewajiban rotasi secret web. Uji first-login name, hidden relay
email, repeat login, revoked credential, reauthentication, dan account
deletion pada iPhone fisik.

#### SMTP dan domain

User perlu memiliki domain dan akses DNS, memilih provider SMTP production,
menentukan sender khusus Auth seperti `no-reply@auth.example.com`, dan
menyediakan host, port, username, serta password SMTP langsung ke Supabase
Dashboard/secret manager—jangan mengirim secret melalui chat atau commit.
Konfigurasikan SPF, DKIM, dan DMARC, pisahkan reputasi email Auth dari
marketing, matikan link tracking, siapkan template Bahasa Indonesia untuk
confirmation, recovery, reauthentication, dan security notification, lalu
uji delivery nyata beserta redirect allowlist dan rate limit sebelum
menampilkan kembali email/password pada UI.

#### Hosted Supabase production

User perlu memberi persetujuan deployment production yang eksplisit dan akses
project `main`. Sebelum deploy: ambil backup, review migration diff, tetapkan
Site URL/redirect allowlist, session/rate-limit policy, provider configuration,
dan secrets Edge Function. Email/password tetap dinonaktifkan selama
SMTP/domain di-skip. Setelah itu deploy migration dan
`delete-account` Edge Function, pasang publishable key/URL Release tanpa
server secret, lalu ulangi advisors, Auth E2E yang aman untuk hosted, RLS,
Storage, deletion/retention, dan rollback verification. Hosted `main` tidak
boleh dipakai untuk eksperimen.

#### Perangkat fisik

User perlu menyediakan iPhone yang terdaftar pada signing team. Verifikasi
Google/Apple callback, Keychain setelah relaunch, session expiry/revocation,
hidden relay, account deletion, offline/retry, permission, dan jaringan nyata.
Hasil Simulator tidak menggantikan gate ini.

SMTP/domain yang di-skip tidak menghalangi provider OAuth, hosted deployment,
atau validasi perangkat fisik. Email/password tetap tersembunyi dan tidak
menjadi exit criteria release saat keputusan skip masih berlaku.

## Exit criteria

### Local exit criteria

- [x] Fresh local reset, lint, advisors, pgTAP, dan Auth integration tests
  lulus.
- [x] Signup selalu membuat tepat satu Participant profile.
- [x] Role self-promotion melalui metadata, Data API, atau callback mustahil.
- [x] Nama, nomor HP, dan level member tersimpan melalui allowlisted operation
  tanpa memberi role Coach atau akses ke field privileged.
- [x] Handoff Coach terautentikasi tersedia tanpa mengklaim operasi
  application/payment/approval Phase 11–12 sudah selesai.
- [x] Provisional identity tidak membuka role shell; cancel membersihkan draft,
  intent, session lokal, dan menjalankan cleanup server idempoten bila perlu.
- [x] Email/password registration, verification, login, logout, recovery, dan
  restoration berjalan pada Supabase lokal.
- [x] Token tersimpan aman, refresh terkoordinasi, dan session expiry tertangani.
- [x] Root route berasal dari session + protected profile + onboarding state.
- [x] Pending enrollment intent bertahan melewati auth dan dikonsumsi aman.
- [x] Cutoff pendaftaran divalidasi ulang dengan server clock setelah Auth;
  Participant tidak dapat memakai override Admin.
- [x] Provider-first layout, ukuran teks, keyboard behavior, typed navigation,
  dan swipe-back Phase 09.5 tidak mengalami regresi.
- [x] Email/password tetap tersembunyi sampai external email gate lulus;
  aktivasi kembali cukup melalui configuration tanpa menulis ulang flow.
- [x] Local demo tetap berjalan tanpa Colima atau internet.
- [x] Debug Supabase mode tidak dapat salah menyasar hosted production.
- [x] Release tidak dapat memakai local endpoint atau Debug credential.
- [x] Source Google/Apple adapter dan fake tests siap tanpa secret.
- [x] Tidak ada token, raw QR Coach, password, provider secret, atau private
  data pada source, bundle, fixture, dan log.
- [x] Full Swift tests dan simulator build lulus.
- [x] Dokumentasi Phase 10, status implementasi, contract matrix, OpenAPI bila
  relevan, dan `supabase/README.md` konsisten dengan hasil yang benar-benar
  diverifikasi.

### External/production exit criteria

- [ ] Google OAuth membuat dan memulihkan Supabase session pada iPhone fisik.
- [ ] Sign in with Apple membuat dan memulihkan Supabase session pada iPhone
  fisik.
- [ ] Identity linking provider tidak membuat duplicate application profile.
- [ ] Hosted OAuth callback menggunakan allowlist yang benar.
- [ ] **SKIPPED SAAT INI** — Hosted email verification/reset callback.
- [ ] New hosted registration selalu menjadi Participant.
- [ ] Coach/Admin tidak dapat diperoleh melalui self-registration.
- [ ] Account deletion dapat diakses dan hosted lifecycle diverifikasi.
- [ ] Production Auth secrets hanya berada pada provider/server configuration.
- [ ] Hosted security/advisors/Auth tests lulus setelah deployment yang
  disetujui.

Status Phase 10 saat ini: fondasi lokal selesai; Google, Apple, hosted
deployment, dan perangkat fisik masih harus diselesaikan. SMTP/domain serta
email/password production di-skip berdasarkan keputusan produk.

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

### 5 Agustus 2026 — Redesign penghapusan akun berbasis identity

- Files changed:
  - `Domain/Models/PeopleModels.swift` dan repository Auth untuk membawa
    provider yang benar-benar terhubung serta memisahkan reauthentication
    dari operasi penghapusan.
  - `Infrastructure/Auth/SupabaseAuthClient.swift`,
    `SupabaseSessionRepository.swift`, dan
    `SupabaseAuthenticationRepository.swift`.
  - `Features/Auth/AccountDeletionView.swift`, tombol Google bersama, profil
    Participant/Coach, serta root preview Debug untuk UI test deterministik.
  - Catalog lokalisasi, `Phase10AuthenticationTests.swift`, dan
    `Phase095GuestAuthUITests.swift`.
- Assumptions/decisions:
  - Daftar metode berasal dari `user.identities`; `app_metadata.providers`
    hanya fallback ketika identity tidak tersedia.
  - Layar tidak menebak provider dari domain email dan tidak menawarkan
    metode yang tidak terhubung.
  - Reauthentication selesai terlebih dahulu. Dialog destructive terakhir
    baru memanggil server operation penghapusan.
  - Hook `-AccountDeletionPreview` hanya dikompilasi pada Debug untuk
    pemeriksaan UI; Release tidak berubah.
- Build:
  - XcodeBuildMCP `build_run_sim`, Debug, iPhone 17 iOS 26.5, dengan locale
    perangkat `en_US` dan flow penghapusan Debug: lulus tanpa warning.
- Test:
  - `scripts/check_localization_catalog.sh`: lulus.
  - XcodeBuildMCP `test_sim
    -only-testing:MSCBodyTransformationTests/Phase10AuthenticationTests`:
    13 passed, 0 failed.
  - XcodeBuildMCP `test_sim
    -only-testing:MSCBodyTransformationUITests/Phase095GuestAuthUITests/
    testAccountDeletionShowsOnlyConnectedGoogleProvider`: 1 passed, 0 failed.
  - XcodeBuildMCP `test_sim
    -only-testing:MSCBodyTransformationUITests/Phase095GuestAuthUITests/
    testAccountDeletionAppleButtonFillsContainerWidth`: 1 passed, 0 failed.
- Result:
  - Snapshot runtime locale `en_US` tetap menampilkan seluruh copy Bahasa
    Indonesia, hanya tombol Google untuk identity Google, tanpa Apple atau
    field password.
  - Tombol verifikasi Google dan Apple memakai lebar kontainer pada layar
    penghapusan, sementara batas lebar tombol Login/Register tetap
    dipertahankan.
- Remaining blockers:
  - Uji manual destructive dengan akun test Google dan Apple lokal masih
    diperlukan untuk mengonfirmasi reauthentication, dialog final, cleanup
    server, dan kembali ke Guest.
  - Hosted production dan perangkat fisik tetap external gate.
  - SMTP/domain tetap `SKIPPED SAAT INI`.

### 5 Agustus 2026 — Provider Apple native diaktifkan lokal

- Files changed:
  - `supabase/config.toml`.
  - `MSCBodyTransformation/MSC_Codex_Phased_Workplan/11_PHASE_10_AUTH_EMAIL_GOOGLE_APPLE.md`.
- Assumptions:
  - App memakai native `AuthenticationServices` dan pertukaran ID token,
    bukan OAuth web.
  - Bundle ID final adalah `com.ranggar.MSCBodyTransformation`.
  - Pemeriksaan nonce tetap aktif; Services ID, `.p8`, dan secret web tidak
    diperlukan untuk flow native-only.
- Build:
  - Tidak dijalankan; tidak ada source iOS atau target Xcode yang berubah.
- Test:
  - `supabase stop` lalu `supabase start`: lulus.
  - `GET /auth/v1/settings`: provider Apple dan Google aktif.
  - Environment non-secret container Auth mengonfirmasi Apple client ID
    `com.ranggar.MSCBodyTransformation` dan `skip_nonce_check=false`.
- Result:
  - App ID Apple, entitlement target, dan provider Apple Supabase lokal siap
    untuk verifikasi manual pada Simulator.
- Remaining blockers:
  - Satu login Apple lengkap, first-login name, repeat login, dan relay email
    perlu diverifikasi manual.
  - Hosted production dan perangkat fisik tetap gate aktif.
  - SMTP/domain tetap `SKIPPED SAAT INI`.

### 5 Agustus 2026 — Callback Google lokal diperbaiki

- Files changed:
  - `Infrastructure/Auth/SupabaseAuthClient.swift`.
  - `Infrastructure/Auth/NativeProviderAuthentication.swift`.
  - `Infrastructure/Auth/AuthenticationCallbackRouter.swift`.
  - `MSCBodyTransformationTests/Phase10AuthenticationTests.swift`.
- Assumption:
  - Social login memakai state provider yang dikelola Supabase Auth; client
    mengikat callback aplikasi dengan PKCE verifier, attempt TTL, dan
    environment.
- Result:
  - Parameter `state` milik aplikasi tidak lagi dikirim ke
    `/auth/v1/authorize`, sehingga tidak menimpa state internal GoTrue.
  - Callback aplikasi menerima authorization code tanpa mensyaratkan state
    provider internal.
  - Decoder profile memetakan `user_id` ke `userId` sesuai strategi
    `convertFromSnakeCase`; session Google tidak lagi gagal setelah profile
    response berhasil.
  - Badge `Mode demo lokal` hanya tampil saat configuration benar-benar
    memakai `local_demo`.
  - Pemilihan QR Coach mengambil directory repository ketika snapshot
    onboarding belum memuat Coach; finalisasi QR tetap diverifikasi oleh RPC
    Supabase sebelum profil Peserta menjadi aktif.
  - `ProfileRepository` Phase 10 mengambil profil Peserta authenticated dari
    Supabase dan mempertahankan fallback Phase 11 untuk data fitur lain,
    sehingga UUID Auth baru tidak lagi gagal dicari pada fixture lokal.
  - Profil baru memakai nama awal dari metadata Google/Apple dan avatar HTTPS
    Google jika tersedia. Default provider hanya mengisi placeholder
    provisional sehingga edit nama user tidak pernah ditimpa.
- Build:
  - XcodeBuildMCP `build_run_sim`, Debug, iPhone 17 iOS Simulator: lulus tanpa
    warning.
- Test:
  - XcodeBuildMCP `test_sim
    -only-testing:MSCBodyTransformationTests/Phase10AuthenticationTests`:
    10 passed, 0 failed.
  - Focused Phase 09.5 + Phase 10 setelah perbaikan QR: 26 passed, 0 failed.
  - Database lint lokal: tidak ada schema error.
  - Verifikasi transaksi rollback: prefill Google, prefill Apple, dan
    perlindungan nama yang sudah diedit lulus.
- Remaining blockers:
  - Google OAuth perlu satu verifikasi manual penuh pada Simulator.
  - Apple provider, hosted production, dan perangkat fisik tetap external
    gate.
  - SMTP/domain tetap `SKIPPED SAAT INI`.

### 5 Agustus 2026 — Fondasi lokal Gate A–D diterapkan

- Files changed:
  - Migration `20260805044617_phase10_auth_profile_and_session_foundation.sql`.
  - pgTAP `005_phase10_auth_profile_foundation.test.sql` dan penyesuaian
    fixture pgTAP Phase 09 agar kompatibel dengan trigger profile.
  - Auth domain, Keychain store, native Auth/Profile client, session actor,
    command façade, callback router, Google browser adapter, dan native Apple
    adapter di `Domain/Models`, `Domain/Repositories`, serta
    `Infrastructure/Auth`.
  - `AppConfiguration`, `AppEnvironment`, `AppRepositories`, `SessionStore`,
    dan `RootView` untuk fail-closed environment serta root session routing.
  - Flow Auth/Participant, catalog lokalisasi, dan
    `Phase10AuthenticationTests.swift`.
  - `supabase/config.toml`, `supabase/README.md`, contract/status docs, dan
    `supabase/tests/integration/auth_lifecycle.mjs`.
- Assumptions:
  - Auth transport tetap memakai native `URLSession`; tidak ada dependency
    baru.
  - Email/password tetap tersembunyi sampai SMTP/domain production siap.
  - Automatic identity linking mengikuti behavior Supabase Auth; manual
    linking tidak ditambahkan.
  - Data feature nyata di luar protected profile tetap handoff Phase 11.
- Build command:
  - `xcodebuild -project MSCBodyTransformation.xcodeproj -scheme
    MSCBodyTransformation -configuration Debug -destination
    'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`.
  - Result: lulus tanpa warning pada source yang diubah.
- Test commands:
  - `supabase test db --local supabase/tests/database`: lulus, 121 assertion.
  - `supabase db lint --local --level warning --fail-on error`: lulus.
  - `supabase db advisors --local --type all --level warn --fail-on error`:
    lulus tanpa issue.
  - `xcodebuild -project MSCBodyTransformation.xcodeproj -scheme
    MSCBodyTransformation -destination 'platform=iOS Simulator,name=iPhone
    17 Pro' -only-testing:MSCBodyTransformationTests
    -parallel-testing-enabled NO -quiet test`: lulus, 175 test cases dalam 16
    suite.
  - `scripts/check_localization_catalog.sh`: lulus.
- Remaining blockers:
  - `enable_confirmations` memerlukan restart Supabase lokal; `supabase stop`
    membutuhkan izin eksplisit user sebelum Auth lifecycle E2E dapat diulang.
  - Custom URL scheme dan Sign in with Apple capability membutuhkan perubahan
    target Xcode yang tidak diizinkan tanpa instruksi eksplisit.
  - Google/Apple credential, SMTP/domain, hosted deployment, dan perangkat
    fisik tetap external gate.
  - Kebijakan account deletion (immediate atau request dengan cancellation
    window) masih menunggu keputusan produk.

### 5 Agustus 2026 — Immediate deletion dan target Xcode selesai lokal

- Files changed:
  - Migration
    `20260805055830_phase10_immediate_account_deletion.sql` dan
    `20260805061953_phase10_account_deletion_retention_safety.sql`.
  - Edge Function `supabase/functions/delete-account/index.ts`, konfigurasi
    function, pgTAP `006_phase10_account_deletion.test.sql`, serta Auth
    lifecycle integration test.
  - Domain/repository/client Auth, `AccountDeletionView`, profil Participant
    dan Coach, serta catalog lokalisasi.
  - `Configuration/MSCBodyTransformation-Info.plist`,
    `Configuration/MSCBodyTransformation.entitlements`, dan target Xcode.
  - OpenAPI, contract matrix, implementation status, Supabase README, dan
    checklist Phase 10.
- Assumptions/decisions:
  - Penghapusan akun bersifat immediate setelah reauthentication.
  - Private Storage dibersihkan melalui Storage API sebelum Auth identity.
  - Admin self-delete ditolak; Coach dengan peserta aktif harus dialihkan.
  - Record transaksi dan audit dipertahankan tanpa identitas; entitlement dan
    data program pribadi dihapus.
  - Hosted `main` tidak disentuh.
- Build command:
  - XcodeBuildMCP `build_run_sim`, scheme `MSCBodyTransformation`, Debug,
    iPhone 17 iOS 26.5.
  - Result: lulus tanpa warning; app terpasang dan terbuka.
- Test commands:
  - `supabase db reset --local`: lulus; sembilan migration dan seed diterapkan
    ulang pada database lokal bersih.
  - XcodeBuildMCP `test_sim -only-testing:MSCBodyTransformationTests
    -parallel-testing-enabled NO`: lulus, 173 test.
  - XcodeBuildMCP `test_sim
    -only-testing:MSCBodyTransformationUITests/Phase095GuestAuthUITests
    -parallel-testing-enabled NO`: lulus, 7 test.
  - `node supabase/tests/integration/auth_lifecycle.mjs`: lulus, 22 checks.
  - `supabase test db --local supabase/tests/database`: lulus, 139 assertion.
  - `supabase db lint --local --level warning --fail-on error`: lulus.
  - `supabase db advisors --local --type all --level warn --fail-on error`:
    lulus tanpa issue.
  - `scripts/check_localization_catalog.sh`: lulus.
- Remaining blockers:
  - Google/Apple provider credential, SMTP/domain, hosted deployment/retention
    review, dan perangkat fisik tetap external gate.

### 5 Agustus 2026 — Status external gate dikoreksi

- Product decision:
  - Google/Apple production provider, hosted deployment, dan physical-device
    validation tetap gate aktif.
  - Hanya SMTP/domain dan aktivasi email/password production yang berstatus
    `SKIPPED SAAT INI`.
  - OAuth production tetap dapat diselesaikan tanpa mengaktifkan
    email/password.
- Files changed:
  - Workplan Phase 10.
  - `PROGRAM_END_TO_END_IMPLEMENTATION_STATUS.md`.
  - `UI_REFERENCE_SHEET.md`.
  - `supabase/README.md`.
- Future input:
  - Akses Google Cloud dan Apple Developer.
  - Persetujuan dan akses deployment hosted Supabase.
  - iPhone fisik dengan signing team yang valid.
- Build/Test:
  - Tidak dijalankan; perubahan hanya status dan panduan dokumentasi.

### 5 Agustus 2026 — Email/password disembunyikan sampai domain tersedia

- Product decision:
  - Login/Register aktif sementara hanya menampilkan Apple dan Google.
  - Email/password serta Forgot Password tetap berada di source dan test,
    tetapi entry point disembunyikan melalui configuration flag.
  - Pengaktifan kembali menunggu domain pengirim, SMTP production,
    verification/reset delivery, dan redirect allowlist yang terverifikasi.
- Files changed:
  - `App/AppConfiguration.swift`.
  - `Features/Auth/AuthenticationFlowState.swift`.
  - `Features/Auth/AuthenticationFlowView.swift`.
  - `MSCBodyTransformationTests/MSCBodyTransformationTests.swift`.
  - `MSCBodyTransformationUITests/Phase095GuestAuthUITests.swift`.
  - `MSC_Codex_Phased_Workplan/UI_REFERENCE_SHEET.md`.
  - `MSC_Codex_Phased_Workplan/11_PHASE_10_AUTH_EMAIL_GOOGLE_APPLE.md`.
- Verification:
  - XcodeBuildMCP `build_run_sim`, iPhone 17 iOS 26.5, Debug, Guest Login,
    locale perangkat `en_US`: lulus tanpa warning.
  - Runtime UI snapshot memverifikasi Login dan Register hanya menampilkan
    Apple serta Google; entry point email tidak ada dan keyboard tidak terbuka.
  - Focused Swift/UI tests: 5 passed, 0 failed. Cakupan meliputi configuration
    flag, OAuth-only provider choices, dan native navigation history/swipe-back.

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
