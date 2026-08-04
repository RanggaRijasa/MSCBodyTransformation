# Phase 10: Authentication and Session

> Status: menunggu implementasi local UI Phase 09.5 selesai. Setelah itu,
> integrasi Auth lokal dapat dikerjakan tanpa menulis ulang Guest,
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

Phase ini hanya menangani identitas, session, profile bootstrap, role load,
dan pemulihan enrollment intent melewati autentikasi. Phase ini tidak:

- Menerapkan operasi server Phase 11 yang belum selesai.
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
- Persistensi nama, nomor HP, level member, dan Coach application dari UI
  Phase 09.5.
- Application Coach yang tidak pernah memberi role berdasarkan state client.
- Program yang dipilih dan QR Coach opaque tetap tersedia setelah auth tanpa
  diperlakukan sebagai role atau izin akses.
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

### Handoff yang harus diselesaikan Phase 09.5

- [ ] Guest menjadi logged-out access state, bukan `UserRole`.
- [ ] Guest dapat membuka seluruh Participant tabs dengan public-safe data.
- [ ] Home Guest menampilkan CTA `Masuk / Daftar`.
- [ ] Login default, Register, Forgot Password, serta fake Apple/Google/email
  presentation tersedia.
- [ ] Onboarding lokal memuat nama, nomor HP, sembilan level member, dan
  pilihan Peserta/pengajuan Coach.
- [ ] Coach application, eligibility HOM STS/ICT, price preview, payment
  preview, dan review Admin tersedia pada repository lokal.
- [ ] Pending applicant tetap Participant sampai approval.

## Gap yang harus ditutup

- [ ] Belum ada migration idempoten untuk membuat profil Participant saat row
  baru dibuat pada `auth.users`.
- [ ] Belum ada schema/member-level dan Coach application yang
  merepresentasikan kontrak Phase 09.5.
- [ ] Belum ada RLS/atomic operation untuk applicant submit, payment status,
  Admin decision, role activation, dan Coach access period.
- [ ] Belum ada public-safe Guest read contract untuk hosted Data API.
- [ ] Belum ada backfill aman untuk identity test yang sudah ada tanpa profil.
- [ ] Belum ada Auth API client dan token lifecycle pada aplikasi.
- [ ] `SessionRepository` belum mendukung registration, login, logout,
  refresh, password recovery, dan auth-state observation.
- [ ] `AppConfiguration.Mode` baru memiliki `localDemo`.
- [ ] Root Release masih membuka shell Participant tanpa session nyata.
- [ ] Token belum disimpan pada Keychain.
- [ ] Callback scheme belum didaftarkan pada target iOS.
- [ ] Belum ada UI email/password production.
- [ ] Belum ada provider Google/Apple yang dikonfigurasi.
- [ ] Belum ada account-deletion request yang dapat diakses dari aplikasi.
- [ ] Belum ada hosted production Auth configuration.

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
Auth Feature State / SessionStore
    ↓
Use Case
    ↓
SessionRepository
    ↓
Local Demo Adapter atau Supabase Session Adapter
    ↓
SupabaseAuthClientProviding
```

Keputusan:

- Pertahankan `SessionRepository` sebagai domain-facing boundary.
- Jangan membuat `AuthRepository` kedua dengan responsibility yang sama.
- Tambahkan method auth secara bertahap pada `SessionRepository` atau protocol
  turunan sempit hanya bila pemisahan benar-benar mengurangi tanggung jawab.
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
  - Onboarding Participant.
  - Authenticated role shell.
  - Session expired.
  - Recoverable error.
- [ ] Root route tidak pernah memilih shell hanya dari metadata provider.
- [ ] Session dianggap usable setelah token valid dan protected profile
  berhasil dimuat.
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

Intent minimum:

- Program ID yang dipilih.
- QR Coach opaque hasil scanner.
- Waktu pembuatan dan expiry.
- Nonce/identifier lokal untuk mencegah callback lama memakai intent baru.

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
  program, current Coach, QR, kapasitas, pricing mode, dan idempotency.
- [ ] QR Coach pertama dapat menetapkan current Coach melalui operasi server.
- [ ] QR Coach berbeda ditolak sebelum payment flow.
- [ ] Program gratis dapat melanjutkan ke enrollment atomik Phase 09.
- [ ] Program berbayar hanya melanjutkan ke handoff Phase 12; auth success
  tidak memberikan entitlement.
- [ ] Uji callback lama, callback ganda, relaunch, logout, account switch,
  expired intent, wrong-Coach QR, dan duplicate enrollment.

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
- [ ] Member tidak dapat submit Coach application.
- [ ] SC ke atas wajib memenuhi HOM STS dan ICT sebelum payment handoff.
- [ ] Payment verified dan Admin approval tetap server-controlled.
- [ ] Pending/rejected applicant tetap memakai Participant shell.
- [ ] Onboarding hanya mengubah field profile yang memang user-editable melalui
  server operation dengan allowlist eksplisit.
- [ ] Role tetap dibaca dari protected profile.
- [ ] Coach yang belum approved mendapat state terbatas yang eksplisit, bukan
  Participant shell atau Admin shell.
- [ ] Admin shell hanya terbuka untuk protected role Admin.
- [ ] Role berubah oleh trusted Admin operation memicu profile/session reload.
- [ ] Stale role cache tidak boleh mempertahankan akses ke shell privileged.
- [ ] SessionStore membersihkan navigation path dan private cache ketika role
  atau user berubah.
- [ ] Deep link ke route role tertentu tetap melewati session dan role guard.

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

## Urutan implementasi

Kerjakan satu gate pada satu waktu.

### Gate A — Local Auth backend

1. Hidupkan Colima dan Supabase lokal bila diperlukan sesuai `AGENTS.md`.
2. Verifikasi CLI/config keys dan Auth endpoint dari dokumentasi versi aktif.
3. Buat migration profile bootstrap dan role hardening baru.
4. Tambahkan pgTAP serta Auth API integration tests.
5. Jalankan fresh reset, lint, advisors, grants, RLS, dan signup tests.

### Gate B — iOS session foundation

1. Tambahkan environment modes dan validation.
2. Tambahkan Supabase Auth transport boundary.
3. Perluas `SessionRepository` tanpa membuat repository duplikat.
4. Tambahkan Keychain store dan actor untuk refresh coordination.
5. Tambahkan `SessionStore` serta root state machine.
6. Pertahankan local demo dan seluruh mock tests.

### Gate C — Email/password dan enrollment intent

1. Registrasi dan profile provisioning.
2. Verification/resend.
3. Login/logout/session restoration.
4. Forgot/reset password callback.
5. Pending enrollment intent secure persistence dan resume.
6. Local Auth E2E pada Simulator.

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
- [ ] Session expiry dan role-load failure.
- [ ] Account switch membersihkan private state.

### Database dan Auth API lokal

- [ ] Signup membuat tepat satu Participant profile.
- [ ] Empty/malformed display metadata tidak memblokir signup.
- [ ] Client-supplied Coach/Admin role diabaikan.
- [ ] Member level tidak dapat dipakai sebagai authorization claim.
- [ ] Coach application tidak dapat self-approve atau menulis payment verified.
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
- [ ] Advisors tidak menemukan security blocker baru.

### iOS integration

- [ ] Keychain save/load/delete.
- [ ] Session restoration setelah relaunch.
- [ ] Offline launch dengan cached session yang expired.
- [ ] Local demo tetap berjalan saat Colima mati.
- [ ] Debug Supabase mode memberi error actionable saat Colima mati.
- [ ] Login success memuat protected role.
- [ ] Pending intent bertahan melalui signup/login/callback.
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
- [ ] Profile/member level dan Coach application Phase 09.5 tersimpan melalui
  allowlisted operation tanpa memberi role Coach.
- [ ] Pending applicant tetap Participant sampai eligibility, payment
  verification, dan Admin approval lulus.
- [ ] Email/password registration, verification, login, logout, recovery, dan
  restoration berjalan pada Supabase lokal.
- [ ] Token tersimpan aman, refresh terkoordinasi, dan session expiry tertangani.
- [ ] Root route berasal dari session + protected profile + onboarding state.
- [ ] Pending enrollment intent bertahan melewati auth dan dikonsumsi aman.
- [ ] Local demo tetap berjalan tanpa Colima atau internet.
- [ ] Debug Supabase mode tidak dapat salah menyasar hosted production.
- [ ] Release tidak dapat memakai local endpoint atau Debug credential.
- [ ] Source Google/Apple adapter dan fake tests siap tanpa secret.
- [ ] Tidak ada token, raw QR Coach, password, provider secret, atau private
  data pada source, bundle, fixture, dan log.
- [ ] Full Swift tests dan simulator build lulus.

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
  - Implementasi Phase 09.5.
  - Migration/RLS/operation Coach application pada Phase 10/11.
  - StoreKit verification dan entitlement pada Phase 12.
