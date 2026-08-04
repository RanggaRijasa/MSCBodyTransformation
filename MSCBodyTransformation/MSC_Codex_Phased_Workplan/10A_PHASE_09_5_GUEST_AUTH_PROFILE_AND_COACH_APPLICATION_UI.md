# Phase 09.5: Guest, Auth UI, Profile, and Coach Application Preview

> Status: siap dikerjakan setelah Phase 09 dan sebelum Phase 10.
>
> Phase ini membangun guest experience, Login/Register UI, onboarding profil,
> pengajuan Coach, preview pembayaran manual tiga bulan, dan pemeriksaan
> pengajuan pada Admin menggunakan repository lokal serta deterministic mock.
> Phase ini tidak mengaktifkan Supabase Auth production, Google OAuth,
> Sign in with Apple production, StoreKit transaction, atau perubahan schema
> hosted Supabase.
>
> Guest harus tersedia pada pemilih peran demo agar seluruh area guest,
> Login, Register, onboarding, pengajuan Coach, dan state Admin dapat diperiksa
> sebelum integrasi Auth nyata pada Phase 10.

## Otoritas dan batas dokumen

Sumber keputusan:

- `00_START_HERE.md`.
- `UI_REFERENCE_SHEET.md`.
- `PROGRAM_END_TO_END_REMEDIATION_WORKPLAN.md`.
- `PROGRAM_END_TO_END_CONTRACT_MATRIX.md`.
- `PROGRAM_END_TO_END_IMPLEMENTATION_STATUS.md`.
- `10_PHASE_09_SUPABASE_FOUNDATION.md`.
- `11_PHASE_10_AUTH_EMAIL_GOOGLE_APPLE.md`.
- `13_PHASE_12_STOREKIT_PROGRAM_PAYMENTS.md`.
- `AGENTS.md`.

Jika terdapat konflik dengan phase lama, keputusan pada dokumen ini berlaku
untuk guest, auth presentation, onboarding profil, level member, dan
pengajuan Coach sampai dokumen authoritative lain direkonsiliasi.

Phase ini hanya mengimplementasikan local UI/domain/mock contract. Phase ini
tidak:

- Membuat user pada Supabase Auth.
- Mengirim email verification atau reset password sebenarnya.
- Membuka browser Google OAuth sebenarnya.
- Mengaktifkan capability Sign in with Apple.
- Menambahkan Google Sign-In SDK atau dependency lain.
- Menjalankan StoreKit transaction sebenarnya.
- Mencatat pembayaran nyata.
- Mengubah role pada hosted atau local Supabase.
- Membuat migration Supabase.
- Mendeploy ke hosted `main`.
- Menyimpan password, token, provider credential, data pembayaran, atau
  private key.
- Menggunakan guest sebagai role database.

## Keputusan produk yang sudah dikonfirmasi

### Guest

- User boleh memakai aplikasi tanpa login.
- Guest masuk ke shell dan tab Peserta.
- Seluruh tab Peserta dapat dibuka.
- Konten publik dapat dijelajahi.
- Area personal menampilkan logged-out state, bukan profil atau data Peserta
  palsu.
- Aksi `Gabung program` dan aksi personal lain membuka auth gate.
- Card user pada Home guest diganti CTA `Masuk / Daftar`.

### Auth presentation

- Login adalah halaman auth default.
- Login menyediakan:
  - Sign in with Apple.
  - Google.
  - Email dan password.
  - `Lupa password`.
  - CTA `Belum punya akun? Daftar sekarang`.
- Register berada pada halaman terpisah.
- Register menyediakan Apple, Google, dan email/password.
- Phase 09.5 hanya mensimulasikan hasil auth secara lokal.
- Phase 10 menghubungkan UI yang sama ke Supabase Auth.

### Profil setelah registrasi pertama

Semua metode registrasi mengarah ke onboarding profil:

1. Nama.
2. Nomor HP.
3. Level Member.
4. Pilihan tujuan akun:
   - Lanjut sebagai Peserta.
   - Ajukan menjadi Coach.

### Level Member

Gunakan enum stabil dengan display value:

1. Member.
2. SC.
3. SB.
4. Supervisor.
5. World Team.
6. TAB Team.
7. GET Team.
8. Millionaire Team.
9. President’s Team.

Raw value harus machine-readable, stabil, dan portable ke backend/Android.
Display value tetap dapat dilokalkan.

### Pengajuan Coach

- User yang mendaftar selalu mempunyai role Participant pada awalnya.
- Pilihan Coach berarti membuat pengajuan Coach, bukan memberikan role Coach.
- Member tidak memenuhi level minimum dan tidak dapat melanjutkan pengajuan.
- SC ke atas memenuhi syarat level secara otomatis berdasarkan pilihan level.
- Applicant wajib menyatakan:
  - Sudah mengikuti HOM STS.
  - Sudah mengikuti ICT.
- Pembayaran tidak dapat dimulai sebelum seluruh syarat lengkap.
- Setelah pembayaran terverifikasi, pengajuan tetap menunggu persetujuan
  Admin.
- Hanya operasi server/Admin terpercaya yang boleh mengaktifkan role dan akses
  Coach.

### Harga akses Coach

Pembayaran berlaku tiga bulan dan tidak diperpanjang otomatis:

| Level | Dapat mengajukan Coach | Harga preview / 3 bulan |
|---|---:|---:|
| Member | Tidak | — |
| SC | Ya | Rp100.000 |
| SB | Ya | Rp100.000 |
| Supervisor | Ya | Rp150.000 |
| World Team | Ya | Rp150.000 |
| TAB Team | Ya | Rp200.000 |
| GET Team | Ya | Rp200.000 |
| Millionaire Team | Ya | Rp200.000 |
| President’s Team | Ya | Rp200.000 |

Harga pada Phase 09.5 adalah deterministic mock untuk preview. Pada production:

- Client tidak authoritative atas harga atau masa aktif.
- Product mapping dan harga aktual berasal dari store/server.
- Transaksi harus diverifikasi server-side.
- Akses Coach memerlukan eligibility lengkap, pembayaran verified, dan
  approval Admin.
- Masa tiga bulan dihitung dari timestamp server yang authoritative.
- Tidak ada auto-renew.

## Temuan keamanan pada implementation saat ini

### Guest belum benar-benar tersedia

- `DemoRole` hanya memiliki Participant, Coach, dan Admin.
- `ParticipantJourneyStore.load()` mengganti session logged-out menjadi
  Participant demo secara otomatis.
- Snapshot Peserta saat ini mewajibkan user/profile sehingga guest berisiko
  dibuat sebagai profil palsu.
- Root Release saat ini membuka shell Participant tanpa session nyata.

Perbaikan Phase 09.5:

- Guest menjadi access/session presentation state, bukan `UserRole`.
- Guest tidak mempunyai UUID user, profile, role, Coach, enrollment, atau
  token palsu.
- Public browsing data dipisahkan dari personal Participant snapshot.
- Auto-login demo hanya boleh terjadi pada skenario Participant yang dipilih
  eksplisit, tidak pada Guest.

### Pending Coach saat ini memperoleh role terlalu awal

- Fixture pending approval saat ini sudah mempunyai `role=coach`.
- `AppUser.isCoachApprovalPending` berada pada user yang sudah dianggap Coach.
- Admin approval hanya membalik flag dan tidak memeriksa level, syarat, atau
  pembayaran.

Perbaikan Phase 09.5:

- Applicant tetap `role=participant`.
- Buat `CoachApplication` terpisah dari `AppUser`.
- Admin membaca application state, eligibility, dan payment preview.
- Approval mengubah role hanya melalui repository operation yang memvalidasi
  seluruh precondition.
- Pending applicant tidak dapat membuka Coach shell, QR Coach, roster,
  submission review, atau private Participant data.

### Backend Phase 09 belum mencakup kontrak baru

Schema saat ini sudah mempunyai:

- `profiles.display_name`.
- `profiles.phone_number`.
- `profiles.role`.
- `profiles.coach_is_approved`.
- `profiles.coach_is_public`.
- RLS dan role hardening dasar.

Schema belum mempunyai:

- Level Member.
- Coach application.
- HOM STS/ICT attestations.
- Eligibility status/version.
- Coach price band.
- Payment verification untuk akses Coach.
- Masa aktif Coach.
- Admin decision dan rejection reason khusus application.

Phase 09.5 tidak mengubah schema. Gap tersebut menjadi explicit handoff ke
Phase 10/11/12.

## Access matrix Guest

Guest memakai tab Peserta yang sama, tetapi capability berbeda.

| Area | Guest dapat melihat | Aksi yang wajib login |
|---|---|---|
| Home | CTA auth, program publik, highlight publik, leaderboard aman, Coach publik | Gabung program, membuka aktivitas personal |
| Program | Katalog dan detail penawaran program publik | Gabung program, akses enrollment/aktivitas |
| Leaderboard | Ranking dengan public-safe fields | Highlight current user atau data personal |
| Coach | Direktori Coach approved/public | Memilih/mengganti Coach atau melihat data privat |
| Profil | Logged-out account screen, privacy, terms | Edit profil, account settings personal |

Aturan:

- [ ] Semua tab dapat dinavigasi tanpa membuat fake Participant session.
- [ ] Guest tidak melihat `Diikuti` atau `Riwayat` seolah mempunyai enrollment.
- [ ] State `Diikuti` dan `Riwayat` menjelaskan bahwa login diperlukan untuk
  melihat data akun.
- [ ] Guest tidak melihat focus activity, progress, streak, current Coach,
  current-user leaderboard highlight, private winner data, atau submission.
- [ ] Home guest tidak menampilkan nama/avatar fixture Participant.
- [ ] Profile guest tidak menampilkan email atau data fixture.
- [ ] Public leaderboard tidak memuat email, nomor HP, berat, private media,
  raw QR, atau identifier sensitif.
- [ ] Direktori Coach guest hanya memuat Coach approved dan public.
- [ ] Semua mutation menggunakan centralized auth gate.
- [ ] Guest browsing tidak membuat anonymous Supabase user.

## Domain contract

### Guest state

Tambahkan presentation/access state tanpa menambah case `.guest` pada
`UserRole`.

Model yang disarankan:

- `AppAccessState`:
  - `guest`.
  - `authenticated(AppSession)`.
- `GuestBrowsingSnapshot` untuk data yang memang publik.
- `AuthenticationDestination` untuk Login/Register/Forgot Password.
- `AuthGateReason` agar prompt dapat menjelaskan tindakan yang memerlukan
  login.

Checklist:

- [ ] `UserRole` tetap hanya Participant, Coach, dan Admin.
- [ ] `DemoRole.guest` hanya memilih guest presentation pada Debug.
- [ ] `DemoRole.guest` tidak mempunyai `userRole` palsu.
- [ ] Refactor mapping `DemoRole → shell/access` agar guest dapat memakai
  Participant tabs tanpa Participant session.
- [ ] `SessionState.loggedOut` menjadi sumber guest access.
- [ ] Hilangkan auto-switch logged-out ke Participant pada Guest flow.
- [ ] Public snapshot tidak menyimpan personal profile/enrollment.

### Membership

Tambahkan model domain portable:

- `MemberLevel`.
- `CoachPriceBand`.
- `AccountPurpose`:
  - `participant`.
  - `coachApplicant`.
- `CoachEligibility`.
- `CoachApplication`.
- `CoachApplicationStatus`.
- `CoachPaymentPreview`.

Raw value yang disarankan:

```text
member
sc
sb
supervisor
world_team
tab_team
get_team
millionaire_team
presidents_team
```

Status application minimum:

```text
draft
ineligible
ready_for_payment
payment_processing
payment_verified
pending_admin_approval
approved
rejected
expired
```

Aturan:

- [ ] Eligibility merupakan computed domain rule, bukan kondisi tersebar di
  View.
- [ ] Member selalu ineligible untuk Coach.
- [ ] SC ke atas memenuhi syarat level.
- [ ] HOM STS dan ICT wajib `true`.
- [ ] Price band berasal dari `MemberLevel` melalui domain service.
- [ ] Gunakan `Decimal` atau integer minor unit untuk nilai harga; jangan
  gunakan binary floating point.
- [ ] UI memformat harga menggunakan locale `id-ID`.
- [ ] View tidak dapat menulis `paymentVerified`, `approved`, atau role.
- [ ] Application menyimpan snapshot level dan terms/version agar review
  tidak berubah diam-diam ketika profile diedit.
- [ ] Admin decision menyimpan actor, timestamp, dan reason bila ditolak.

## Guest demo pada Root

Tambahkan pilihan `Guest` pada pemilih peran Debug.

Behavior:

- [ ] `Guest` muncul bersama Peserta, Coach, dan Admin.
- [ ] Guest menjadi default yang direkomendasikan untuk menguji auth entry.
- [ ] Memilih Guest membuka Participant shell dalam logged-out state.
- [ ] Sediakan skenario:
  - Guest Home.
  - Guest katalog Program.
  - Login.
  - Register.
  - Forgot password.
  - Onboarding profil.
  - Pengajuan Coach eligible.
  - Pengajuan Coach Member/ineligible.
  - Pembayaran preview berhasil.
  - Menunggu persetujuan Admin.
- [ ] Launch argument `-DemoRole guest` membuka Guest deterministically.
- [ ] Launch argument skenario invalid jatuh ke Guest Home, bukan membuat
  Participant session.
- [ ] Participant/Coach/Admin demo lama tetap tersedia dan tidak berubah
  menjadi guest.

## Home Guest

Ganti `HomeProfileCard` dengan auth CTA ketika session logged-out.

Konten:

- Judul singkat yang menjelaskan manfaat akun.
- Primary action `Masuk`.
- Secondary action `Daftar`.
- Tidak menampilkan avatar, nama, badge role, poin, atau Coach fixture.

Checklist:

- [ ] CTA memakai semantic button styles dan minimum touch target.
- [ ] Card dapat diakses pada light/dark mode dan Dynamic Type.
- [ ] `Masuk` membuka Login.
- [ ] `Daftar` membuka Register.
- [ ] Kembali dari auth mempertahankan tab dan scroll context yang wajar.
- [ ] Program publik tetap berada setelah auth CTA sesuai hierarchy Home.
- [ ] Focus section personal diganti logged-out explanation, bukan data kosong
  yang seolah error.
- [ ] Home guest tidak melakukan network/auth request langsung dari `body`.

## Centralized auth gate

Gunakan satu auth gate untuk mutation/personal destination.

Trigger minimum:

- `Gabung program`.
- Membuka aktivitas enrollment.
- Menyelesaikan langkah.
- Mengunggah jawaban.
- Mengisi timbang.
- Mengubah profil.
- Mengganti Coach.
- Mengakses setting akun personal.

Behavior:

- [ ] Simpan destination/intention yang aman sebelum auth.
- [ ] Untuk `Gabung program`, simpan program ID; QR Coach baru dipertahankan
  jika memang sudah dipindai.
- [ ] Jangan simpan raw QR pada UserDefaults, clipboard, log, analytics, atau
  callback URL.
- [ ] Tampilkan Login sebagai default.
- [ ] Sediakan CTA Register.
- [ ] Setelah fake auth berhasil, lanjutkan ke onboarding bila profile belum
  lengkap.
- [ ] Setelah onboarding selesai, kembali ke destination yang valid.
- [ ] Callback/destination lama ditolak bila user membatalkan atau context
  kedaluwarsa.
- [ ] Auth gate idempoten dan tidak menumpuk sheet berulang.

## Login UI

Halaman default:

1. Logo/brand header yang ringkas.
2. Sign in with Apple.
3. Google.
4. Divider.
5. Email.
6. Password dengan show/hide yang accessible.
7. `Lupa password`.
8. Primary action `Masuk`.
9. CTA `Belum punya akun? Daftar sekarang`.

Checklist:

- [ ] Gunakan `Form` atau scrollable form native yang aman untuk keyboard.
- [ ] `textContentType(.username)`/email dan `.password` disiapkan.
- [ ] Password tidak disalin ke state global, analytics, log, atau fixture.
- [ ] Apple dan Google memakai presentation adapter fake pada Phase 09.5.
- [ ] Loading, success, cancel, validation, offline, provider error, dan
  unknown state tersedia.
- [ ] Duplicate submit dicegah.
- [ ] Error field berhubungan dengan field untuk VoiceOver.
- [ ] Tidak mengungkap apakah email terdaftar.
- [ ] Phase 09.5 tidak menampilkan token atau credential demo.
- [ ] Banner Debug menjelaskan bahwa tidak ada akun nyata dibuat, tanpa muncul
  pada production UI.

## Register UI

Register adalah halaman terpisah, bukan perluasan inline Login.

Urutan:

1. Sign in with Apple.
2. Google.
3. Divider.
4. Email.
5. Password.
6. Konfirmasi password.
7. Primary action `Daftar`.
8. CTA `Sudah punya akun? Masuk`.

Checklist:

- [ ] Tidak ada pemilih role pada credential form.
- [ ] Apple/Google registration dan login memakai tombol/provider yang sama;
  onboarding ditentukan setelah session/profile load.
- [ ] Email validation dan password requirement tampil sebagai UX guidance.
- [ ] Password dan confirmation dibandingkan hanya di feature state.
- [ ] Password dihapus dari memory state ketika flow selesai/dibatalkan
  sejauh practical.
- [ ] Fake register menghasilkan session Participant yang onboarding-nya belum
  lengkap.
- [ ] Semua metode fake register masuk ke onboarding profil yang sama.
- [ ] Existing fake user melewati onboarding bila profile sudah lengkap.

## Forgot Password UI

- [ ] Halaman email recovery terpisah.
- [ ] Response selalu generik.
- [ ] State sent, rate-limited, offline, dan retry tersedia.
- [ ] Phase 09.5 tidak mengirim email.
- [ ] Fake result memungkinkan UI success diperiksa.
- [ ] Reset-password callback UI sebenarnya tetap Phase 10.

## Onboarding Profil

Form wajib:

- Nama.
- Nomor HP.
- Level Member.
- Pilihan `Lanjut sebagai Peserta` atau `Ajukan menjadi Coach`.

Aturan:

- [ ] Nama wajib, trimmed, dan mempunyai batas panjang yang konsisten.
- [ ] Nomor HP wajib untuk onboarding baru dan divalidasi tanpa mengirim OTP
  pada Phase 09.5.
- [ ] Nomor HP tidak dicatat pada log atau analytics.
- [ ] `MemberLevel` memakai Picker native.
- [ ] Level member bukan role dan bukan authorization claim.
- [ ] City tidak lagi menjadi field wajib onboarding baru; field lama dapat
  tetap tersedia sebagai data profil opsional sampai keputusan migrasi dibuat.
- [ ] Pilihan Peserta menyelesaikan onboarding dan membuka Participant shell.
- [ ] Pilihan Coach membuka eligibility flow.
- [ ] Memilih Member menonaktifkan pilihan Coach dengan penjelasan yang jelas.
- [ ] Mengubah level setelah mengisi form merekonsiliasi eligibility dan harga.
- [ ] Onboarding state bertahan melalui navigation dan interruption pada local
  repository, bukan UserDefaults tersebar.

## Coach Eligibility UI

Tampilkan:

- Level yang dipilih.
- Status level minimum.
- Checkbox `Sudah mengikuti HOM STS`.
- Checkbox `Sudah mengikuti ICT`.
- Ringkasan harga untuk tiga bulan.
- Penjelasan `Tidak diperpanjang otomatis`.
- CTA `Lanjut ke pembayaran`.

Checklist:

- [ ] Member melihat state tidak memenuhi syarat dan CTA pembayaran disabled.
- [ ] SC ke atas melihat syarat level terpenuhi otomatis.
- [ ] Checkbox tidak dicentang otomatis.
- [ ] CTA pembayaran disabled sampai HOM STS dan ICT dicentang.
- [ ] Disabled state menjelaskan syarat yang belum lengkap.
- [ ] Harga tidak dihitung di View.
- [ ] User dapat kembali mengubah level tanpa kehilangan data non-sensitif.
- [ ] Copy tidak menyatakan Coach aktif sebelum pembayaran dan Admin approval.
- [ ] Sediakan link Syarat & Ketentuan placeholder hanya jika destination
  dokumen tersedia; jangan membuat dead link.

## Preview Pembayaran Manual Tiga Bulan

Phase 09.5 hanya menggunakan `FakeCoachPurchaseService`.

UI preview:

- Level dan band harga.
- Durasi tiga bulan.
- Tidak diperpanjang otomatis.
- Fake purchase sheet/state untuk Debug.
- Success state `Pembayaran demo terverifikasi`.
- Next state `Menunggu persetujuan Admin`.

Checklist:

- [ ] Tidak memanggil StoreKit production.
- [ ] Tidak meminta kartu, rekening, OTP, atau data pembayaran.
- [ ] Tidak membuat fake receipt yang menyerupai credential production.
- [ ] Fake outcome deterministic: success, cancelled, pending, failed,
  interrupted.
- [ ] Success hanya mengubah payment preview state, bukan role Coach.
- [ ] Duplicate fake callback tidak membuat payment/application kedua.
- [ ] Harga mock diberi label Debug-only pada tooling, tidak pada production
  product UI.
- [ ] Production UI kemudian memakai localized price dari StoreKit.

Catatan Phase 12:

- Akses Coach membuka capability digital dalam aplikasi sehingga pilihan
  payment production harus diperiksa terhadap App Review Guideline 3.1.1.
- Pembayaran manual untuk akses terbatas tiga bulan mempunyai kandidat mapping
  StoreKit `Non-Renewing Subscription`.
- Product type, product IDs per price band, entitlement, restore, refund,
  approval ordering, dan expiry wajib difinalkan pada Phase 12 berdasarkan
  dokumentasi Apple yang berlaku saat implementasi.
- Phase 09.5 tidak menyediakan external payment link atau metode pembayaran
  di luar StoreKit.

## Coach Application State

Alur:

```text
Participant account
    ↓
Profile + Member Level
    ↓
Coach eligibility complete
    ↓
Manual 3-month payment verified
    ↓
Pending Admin approval
    ↓
Admin approves
    ↓
Coach role/access active
```

Aturan:

- [ ] User tetap Participant pada draft, payment, dan pending approval.
- [ ] Satu user hanya mempunyai satu active application.
- [ ] Repeated submit mengembalikan application yang sama.
- [ ] Payment verified tidak sama dengan Coach approved.
- [ ] Admin approved tidak boleh true tanpa payment verified dan eligibility
  complete.
- [ ] QR Coach baru dibuat setelah activation server-side pada phase backend.
- [ ] Rejection memerlukan alasan.
- [ ] Rejected application tidak otomatis menghapus payment record.
- [ ] Refund/credit policy untuk rejection harus diputuskan sebelum transaksi
  production diaktifkan.
- [ ] Access expiry dan renewal manual menjadi entitlement state terpisah dari
  profile display.
- [ ] Policy apakah renewal memerlukan approval ulang harus diputuskan sebelum
  Phase 12 production exit.

## Admin Coach Approval

Gunakan Admin Dashboard/People yang sudah ada, tetapi tampilkan application,
bukan Coach role prematur.

Dashboard:

- [ ] Pending count berasal dari `CoachApplication.pendingAdminApproval`.
- [ ] Quick action membuka daftar Pengajuan Coach.

Daftar:

- [ ] Pending applicant tetap dapat ditemukan walaupun role-nya Participant.
- [ ] Jangan bergantung pada filter `UserRole.coach`.
- [ ] Tambahkan scope/segment `Pengajuan Coach` atau destination khusus yang
  tetap mengikuti hierarchy People.
- [ ] Row menampilkan nama, level, payment status, dan application status.
- [ ] Jangan menampilkan nomor HP penuh pada row bila tidak diperlukan.

Detail application:

- Nama.
- Nomor HP.
- Level Member.
- Syarat level.
- HOM STS.
- ICT.
- Harga band.
- Status pembayaran.
- Periode akses bila verified.
- Tanggal pengajuan.
- Status keputusan.

Admin action:

- [ ] `Setujui Coach` disabled kecuali level eligible, HOM STS, ICT, dan
  payment verified.
- [ ] Approval memakai confirmation.
- [ ] Reject memerlukan reason.
- [ ] Admin tidak dapat mengedit attestation menjadi true atas nama applicant.
- [ ] Admin dapat melihat field mana yang belum memenuhi syarat.
- [ ] Approval local mock membuat CoachProfile dan role Coach secara atomik.
- [ ] Approval mencatat audit local.
- [ ] Repeated approval idempoten.
- [ ] Applicant approved muncul pada daftar Coach dan dapat membuka Coach
  demo setelah session reload.
- [ ] Applicant pending/rejected tetap tidak dapat membuka Coach shell.

## Frontend safety

- [ ] Guest tidak direpresentasikan sebagai authenticated Participant.
- [ ] Views tidak menentukan authorization atau payment verification.
- [ ] Views tidak mengubah role.
- [ ] Harga tidak tersebar sebagai magic number pada Views.
- [ ] Password hanya hidup pada auth feature state sesingkat practical.
- [ ] Nomor HP tidak masuk log, analytics, atau test failure output.
- [ ] Tidak ada provider token/secret pada fake adapter.
- [ ] Tidak ada raw QR Coach pada auth callback.
- [ ] Semua error production-facing dipetakan ke Bahasa Indonesia.
- [ ] Semua `String(localized:)` mempunyai `defaultValue` Bahasa Indonesia.
- [ ] User-facing price memakai `FormatStyle.currency(code: "IDR")` dengan
  locale `id-ID`.
- [ ] Personal state dibersihkan saat logout/account switch.
- [ ] Navigation ke Coach/Admin selalu melewati capability guard.
- [ ] Local demo tetap dapat berjalan tanpa Colima.

## Backend handoff safety

Phase 10/11/12 harus menyediakan migration/operation terpisah. Jangan mengedit
migration Phase 09 yang sudah ada.

Schema candidate:

- `profiles.member_level`.
- `coach_applications`.
- `coach_application_decisions` atau audit event yang setara.
- `coach_access_products`.
- `coach_access_transactions`.
- `coach_access_entitlements`.

Server-controlled fields:

- Application status.
- Price band dan authoritative product mapping.
- Payment verification.
- Paid period.
- Admin actor/decision.
- Coach approval.
- Role.
- Coach QR identifier.
- Entitlement start/end.

Client-writable fields dengan validation:

- Display name.
- Phone number.
- Member level.
- HOM STS attestation.
- ICT attestation.
- Application submit request.

RLS/API rules:

- [ ] Guest/`anon` hanya mendapat explicit grant untuk public-safe read model
  yang memang diperlukan.
- [ ] Public tables/views memakai RLS atau `security_invoker` sesuai desain.
- [ ] Guest tidak dapat membaca `profiles` application/payment rows.
- [ ] Applicant hanya membaca application dan payment status miliknya.
- [ ] Applicant tidak dapat menulis approval/payment verified/role/QR.
- [ ] Admin dapat membaca application dan mengambil keputusan melalui atomic
  operation.
- [ ] Coach access memerlukan approved role dan active entitlement.
- [ ] Expired entitlement menolak Coach operation di server meskipun client
  cache belum diperbarui.
- [ ] Price/product mapping berasal dari server/store.
- [ ] Store verification idempoten dan transaction ID unique.
- [ ] Audit tidak memuat password, token, nomor HP penuh, atau payment secret.
- [ ] Data API grants tetap explicit karena automatic exposure dimatikan.
- [ ] Semua privileged function memakai explicit `search_path`, caller check,
  revoke default execute, dan least-privilege grant.

Auth rules:

- [ ] Auth signup selalu membuat Participant profile.
- [ ] Metadata `role=coach` atau `role=admin` diabaikan.
- [ ] Level Member dan application bukan JWT authorization dari
  `raw_user_meta_data`.
- [ ] Profile/application load dilakukan setelah session tervalidasi.
- [ ] Password dikelola Supabase Auth; aplikasi tidak menyimpan password.

## Mock scenarios dan fixtures

Tambahkan deterministic fixture:

- Guest tanpa session.
- Participant onboarding incomplete.
- Member memilih Coach dan ditolak eligibility.
- SC siap mengisi syarat.
- Supervisor belum centang ICT.
- TAB Team siap pembayaran.
- GET Team payment pending.
- Millionaire Team payment verified menunggu Admin.
- President’s Team approved.
- Rejected application dengan alasan.
- Expired three-month access.

Aturan:

- [ ] Tidak memakai email/nomor HP orang nyata.
- [ ] Password tidak disimpan pada fixture.
- [ ] Fake purchase tidak menyerupai receipt production.
- [ ] ID deterministic.
- [ ] Clock injected untuk expiry tiga bulan.
- [ ] Harga berada pada domain pricing fixture/service, bukan per-view.

## Accessibility dan UI verification

- [ ] Login/Register dapat discroll ketika keyboard dan Dynamic Type besar.
- [ ] Secure field show/hide mempunyai label, value, dan touch target.
- [ ] Picker level dapat digunakan VoiceOver.
- [ ] Checkbox HOM STS/ICT mempunyai state yang terbaca.
- [ ] Disabled Coach/payment CTA menjelaskan penyebab.
- [ ] Status paid/pending/approved/rejected tidak hanya memakai warna.
- [ ] Admin dapat membaca seluruh eligibility pada Dynamic Type besar.
- [ ] Light/dark mode.
- [ ] Increase Contrast.
- [ ] Reduce Transparency.
- [ ] Reduce Motion.
- [ ] Differentiate Without Color.
- [ ] Device locale `en_US` tetap menampilkan Bahasa Indonesia dan tidak
  menampilkan localization key.
- [ ] iPad layout tidak menjadi form terlalu lebar.

## Urutan implementasi

### Gate A — Domain dan repository lokal

1. Tambahkan member level, price band, eligibility, application, dan payment
   preview models.
2. Tambahkan domain services dan repository protocol.
3. Refactor pending Coach agar applicant tetap Participant.
4. Tambahkan deterministic fixtures serta tests.
5. Build dan jalankan focused unit tests.

### Gate B — Guest shell

1. Tambahkan Guest pada Debug role selector.
2. Pisahkan Guest access dari `UserRole`.
3. Hentikan auto-login pada Guest.
4. Tambahkan public browsing snapshot.
5. Render seluruh Participant tabs dengan guest-safe state.
6. Tambahkan auth CTA pada Home dan Profile.
7. Build dan jalankan guest navigation tests.

### Gate C — Auth presentation

1. Tambahkan Login default.
2. Tambahkan Register terpisah.
3. Tambahkan Forgot Password.
4. Tambahkan fake Apple/Google/email adapters.
5. Tambahkan centralized auth gate.
6. Verifikasi `Gabung program → Login/Register`.

### Gate D — Profile dan Coach application

1. Ganti onboarding menjadi nama, nomor HP, level, dan account purpose.
2. Tambahkan Coach eligibility form.
3. Tambahkan price preview.
4. Tambahkan fake manual-payment state.
5. Tampilkan pending Admin approval.
6. Verifikasi role tetap Participant.

### Gate E — Admin approval

1. Tampilkan application pada Admin.
2. Tampilkan seluruh syarat dan payment state.
3. Disable approval bila belum eligible/paid.
4. Tambahkan approve/reject idempoten dan audit local.
5. Verifikasi approved user baru memperoleh Coach access.

### Gate F — Regression, accessibility, dan documentation

1. Jalankan seluruh Swift tests.
2. Jalankan focused Guest/Auth/Coach application UI tests.
3. Jalankan simulator build.
4. Verifikasi locale `en_US`, dark mode, dan Dynamic Type.
5. Perbarui seluruh dokumentasi pada bagian Documentation Updates.

## Test matrix

### Domain

- [ ] Sembilan level decode/encode dan display mapping.
- [ ] Member ineligible.
- [ ] SC/SB = Rp100.000.
- [ ] Supervisor/World Team = Rp150.000.
- [ ] TAB/GET/Millionaire/President’s Team = Rp200.000.
- [ ] HOM STS false memblokir.
- [ ] ICT false memblokir.
- [ ] Price uses Decimal/integer minor unit.
- [ ] Payment verified tidak mengubah role.
- [ ] Approval tanpa payment ditolak.
- [ ] Approval tanpa eligibility ditolak.
- [ ] Duplicate application/approval idempoten.
- [ ] Three-month expiry memakai injected clock.

### Guest

- [ ] Guest tidak mempunyai AppUser/profile.
- [ ] Semua Participant tabs dapat dibuka.
- [ ] Personal data tidak muncul.
- [ ] Home menampilkan `Masuk / Daftar`.
- [ ] Profile menampilkan logged-out state.
- [ ] Catalog public dapat dibaca.
- [ ] Join membuka Login.
- [ ] Cancel auth kembali ke program.
- [ ] Guest tidak dapat submit/upload/weigh/edit profile.

### Auth UI

- [ ] Login adalah default.
- [ ] Register CTA membuka Register.
- [ ] Existing-account CTA kembali ke Login.
- [ ] Apple fake success/cancel/error.
- [ ] Google fake success/cancel/error.
- [ ] Email fake login validation.
- [ ] Email fake register validation.
- [ ] Forgot Password generic success.
- [ ] Duplicate submit dicegah.
- [ ] Tidak ada password/token pada logs.

### Onboarding

- [ ] Semua auth methods membuka form yang sama.
- [ ] Nama wajib.
- [ ] Nomor HP wajib dan tervalidasi.
- [ ] Level wajib.
- [ ] Peserta langsung masuk Participant shell.
- [ ] Member tidak dapat memilih Coach.
- [ ] SC ke atas dapat membuka eligibility.
- [ ] Harga berubah sesuai level.

### Admin

- [ ] Pending applicant terlihat walaupun role Participant.
- [ ] Detail menampilkan level/HOM STS/ICT/payment.
- [ ] Approval disabled bila belum lengkap.
- [ ] Rejection memerlukan alasan.
- [ ] Approval atomik membuat Coach access local.
- [ ] Dashboard count berubah.
- [ ] Audit tercatat.
- [ ] Applicant tidak dapat self-approve.

### UI regression

- [ ] Participant demo lama.
- [ ] Coach demo lama.
- [ ] Admin CMS lama.
- [ ] Program catalog/join.
- [ ] QR same-Coach guard.
- [ ] Leaderboard public/private fields.
- [ ] Localization.
- [ ] Accessibility.

## Dokumentasi yang wajib diperbarui

Checklist ini merupakan bagian exit criteria, bukan pekerjaan opsional.

- [x] `00_START_HERE.md`
  - Tambahkan Phase 09.5 pada urutan.
  - Dokumentasikan Guest sebagai access state.
- [ ] `UI_REFERENCE_SHEET.md`
  - Guest Home CTA.
  - Login/Register hierarchy.
  - Profile onboarding.
  - Coach eligibility/payment preview.
  - Admin application review.
- [ ] `AGENTS.md`
  - Guest bukan authenticated role.
  - Self-registration tetap Participant.
  - Coach selection berarti application.
  - Coach role memerlukan verified payment dan Admin approval.
- [x] `11_PHASE_10_AUTH_EMAIL_GOOGLE_APPLE.md`
  - Tandai Phase 09.5 sebagai prerequisite.
  - Gunakan UI yang sudah dibuat.
  - Tambahkan profile/member/application persistence handoff.
- [ ] `12_PHASE_11_REAL_DATA_AND_SERVER_OPERATIONS.md`
  - Tulis ulang kontrak lama invite/wallet.
  - Tambahkan public-safe Guest reads dan Coach application operation.
- [ ] `13_PHASE_12_STOREKIT_PROGRAM_PAYMENTS.md`
  - Tambahkan manual three-month Coach access payment.
  - Evaluasi StoreKit non-renewing subscription.
  - Tambahkan server verification, entitlement, expiry, restore/refund.
- [ ] `14_PHASE_13_SECURITY_RELEASE_AND_TESTFLIGHT.md`
  - Tambahkan Guest privacy, Coach application, payment, expiry, dan reviewer
    scenarios.
- [ ] `PROGRAM_END_TO_END_REMEDIATION_WORKPLAN.md`
  - Tambahkan guest/auth/onboarding/Coach access lifecycle.
- [ ] `PROGRAM_END_TO_END_CONTRACT_MATRIX.md`
  - Tambahkan owner dan authority untuk member level, eligibility,
    application, payment, approval, role, dan entitlement.
- [ ] `PROGRAM_END_TO_END_IMPLEMENTATION_STATUS.md`
  - Catat local UI selesai vs backend/external gate.
- [ ] `Contracts/program-api-v1.openapi.yaml`
  - Tambahkan contract pada phase backend, bukan ketika baru UI mock.
- [ ] `supabase/README.md`
  - Dokumentasikan migration/test baru pada Phase 10/11/12.
- [ ] `Localizable.xcstrings`
  - Tambahkan seluruh copy guest/auth/Coach application Bahasa Indonesia.

## File implementation yang diperkirakan

Daftar ini adalah routing awal, bukan izin mengubah `project.pbxproj`.

Potentially edited:

- `App/AppRouter.swift`.
- `App/AppTab.swift`.
- `App/RootView.swift`.
- `App/DebugLaunchConfiguration.swift`.
- `Features/AppShell/RoleAppShellView.swift`.
- `Features/Participant/ParticipantJourneyStore.swift`.
- `Features/Participant/ParticipantHomeView.swift`.
- `Features/Participant/ParticipantProgramCatalogView.swift`.
- `Features/Participant/ParticipantProfileView.swift`.
- `Features/Admin/AdminFeatureContainer.swift`.
- `Features/Admin/AdminTabRootView.swift`.
- `Features/Admin/AdminPersonDetailSheet.swift`.
- `Domain/Models/PeopleModels.swift`.
- `Domain/Repositories/RepositoryProtocols.swift`.
- `LocalData/Mock/InMemoryAppRepository.swift`.
- `LocalData/Mock/MockSeedData.swift`.
- `Resources/Fixtures/users.json`.
- `Resources/Localizable.xcstrings`.

Potentially new synchronized-group files:

- `Domain/Models/MembershipModels.swift`.
- `Domain/Services/CoachEligibilityService.swift`.
- `Domain/Services/CoachPricingService.swift`.
- `Features/Auth/AuthFlowState.swift`.
- `Features/Auth/LoginView.swift`.
- `Features/Auth/RegisterView.swift`.
- `Features/Auth/ForgotPasswordView.swift`.
- `Features/Auth/ProfileOnboardingView.swift`.
- `Features/Auth/CoachApplicationView.swift`.
- `Infrastructure/Auth/FakeAuthPresentationAdapter.swift`.
- `Infrastructure/Commerce/FakeCoachPurchaseService.swift`.
- Focused Swift Testing dan UI test files.

Jika file baru tidak otomatis masuk target, buat file pada folder yang benar
lalu laporkan manual Xcode target-membership step. Jangan edit
`project.pbxproj` tanpa instruksi eksplisit.

## Command verifikasi

Focused Swift tests:

```bash
xcodebuild test \
  -project MSCBodyTransformation.xcodeproj \
  -scheme MSCBodyTransformation \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=<SIMULATOR_ID>' \
  -parallel-testing-enabled NO \
  -only-testing:MSCBodyTransformationTests
```

Simulator build:

```bash
xcodebuild \
  -project MSCBodyTransformation.xcodeproj \
  -scheme MSCBodyTransformation \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Focused UI tests harus mencakup launch argument:

```text
-DemoRole guest
-DemoScenario guest_home
```

Gunakan simulator ID yang benar-benar tersedia saat eksekusi. Jalankan flow
dengan `-AppleLanguages (en) -AppleLocale en_US` untuk memastikan copy tetap
Bahasa Indonesia.

Phase 09.5 tidak membutuhkan Colima untuk UI/mock. Jangan menghidupkan
Supabase lokal hanya untuk preview atau test yang sepenuhnya local.

## Exit criteria

- [ ] Guest tersedia pada pemilih peran demo.
- [ ] Guest membuka seluruh Participant tabs tanpa authenticated user palsu.
- [ ] Home Guest menampilkan `Masuk / Daftar`.
- [ ] Join program membuka Login default.
- [ ] Login, Register, Forgot Password, Apple, Google, dan email/password UI
  dapat didemokan dengan fake adapters.
- [ ] Semua fake registration methods membuka onboarding profil yang sama.
- [ ] Onboarding berisi nama, nomor HP, sembilan level, dan account purpose.
- [ ] Member tidak dapat mengajukan Coach.
- [ ] SC ke atas harus mencentang HOM STS dan ICT.
- [ ] Harga preview sesuai level dan berformat IDR.
- [ ] Pembayaran preview bersifat manual untuk tiga bulan dan tidak
  auto-renew.
- [ ] Payment preview success tidak langsung memberikan role Coach.
- [ ] Admin melihat seluruh eligibility dan payment state.
- [ ] Admin tidak dapat approve sebelum seluruh precondition lengkap.
- [ ] Pending applicant tetap Participant dan tidak mempunyai Coach access.
- [ ] Approval/rejection local idempoten dan teraudit.
- [ ] Existing Participant, Coach, Admin, program, QR, scoring, dan CMS
  regression tests tetap lulus.
- [ ] Local demo tetap berjalan tanpa internet dan Colima.
- [ ] Tidak ada Supabase/OAuth/StoreKit production call atau secret baru.
- [ ] Dokumentasi pada checklist sudah diperbarui.
- [ ] Full Swift tests dan simulator build lulus.
- [ ] Focused Guest/Auth/Admin UI tests lulus.
- [ ] Tidak ada localization key terlihat pada device locale `en_US`.

## External gate dan keputusan lanjutan

Tidak memblokir Phase 09.5 local UI:

- Google Cloud credential.
- Apple Developer capability.
- Supabase Auth profile/application migration.
- Public-safe Guest Data API contract.
- StoreKit product creation.
- Server-side purchase verification.
- Admin approval server operation.
- Physical-device OAuth/purchase tests.

Harus diputuskan sebelum payment production:

- Refund/credit ketika payment verified tetapi Admin menolak application.
- Apakah renewal manual memerlukan Admin approval ulang.
- Behavior Coach ketika masa tiga bulan berakhir.
- Product ID dan StoreKit non-renewing subscription structure per price band.
- Cross-platform entitlement behavior untuk Android.

## Referensi resmi yang wajib diperiksa saat implementasi terkait

- Supabase Auth:
  `https://supabase.com/docs/guides/auth`
- Supabase RLS:
  `https://supabase.com/docs/guides/database/postgres/row-level-security`
- Supabase API security:
  `https://supabase.com/docs/guides/api/securing-your-api`
- Apple App Review Guidelines:
  `https://developer.apple.com/app-store/review/guidelines/`
- Apple non-renewing subscriptions:
  `https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/create-non-renewing-subscriptions/`
- Apple In-App Purchase types:
  `https://developer.apple.com/help/app-store-connect/reference/in-app-purchases-and-subscriptions/in-app-purchase-types/`

## Progress log

### 4 Agustus 2026 — Workplan Phase 09.5 dibuat

- Files changed:
  - `MSCBodyTransformation/MSC_Codex_Phased_Workplan/10A_PHASE_09_5_GUEST_AUTH_PROFILE_AND_COACH_APPLICATION_UI.md`.
  - `MSCBodyTransformation/MSC_Codex_Phased_Workplan/00_START_HERE.md`.
  - `MSCBodyTransformation/MSC_Codex_Phased_Workplan/11_PHASE_10_AUTH_EMAIL_GOOGLE_APPLE.md`.
- Product decisions:
  - Guest dapat menjelajahi seluruh menu Peserta.
  - Login adalah auth page default.
  - Register mempunyai Apple, Google, dan email/password presentation.
  - Onboarding berisi nama, nomor HP, sembilan level, dan account purpose.
  - Member tidak dapat mengajukan Coach.
  - HOM STS dan ICT wajib.
  - Coach access dibayar manual untuk tiga bulan.
  - Harga preview: Rp100.000, Rp150.000, atau Rp200.000 sesuai level.
  - Admin approval wajib sebelum Coach access aktif.
- Safety decisions:
  - Guest bukan role atau anonymous Auth user.
  - New registration tetap Participant.
  - Coach application terpisah dari role.
  - Payment/approval/role tetap server-authoritative.
  - Phase 09.5 tidak membuat network/Auth/StoreKit production call.
- Verification:
  - Workplan dibandingkan dengan guest/session, Participant Home,
    Participant join, profile onboarding, Admin approval, Phase 09 database
    profile/RLS, dan Phase 10 Auth plan saat ini.
  - App Review Guideline serta tipe non-renewing subscription diperiksa dari
    dokumentasi Apple resmi.
- Build:
  - Tidak dijalankan; perubahan hanya dokumentasi workplan.
- Test:
  - Tidak dijalankan; tidak ada perubahan source, fixture, schema,
    configuration, atau Xcode project.
- Remaining blockers:
  - Implementasi seluruh Gate A–F.
  - Keputusan refund/rejection dan renewal approval.
  - Supabase/Auth/StoreKit production integration pada phase berikutnya.
