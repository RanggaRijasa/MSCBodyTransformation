# Phase 09.5: Guest, Auth UI, Profile, and Coach Application Preview

> Status: selesai untuk local UI/domain/mock pada 4 Agustus 2026. Backend
> Auth/RLS/StoreKit tetap handoff Phase 10–12.
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
- Card user pada Home guest diganti satu CTA `Masuk`.
- Pendaftaran hanya dibuka dari CTA `Belum punya akun? Daftar sekarang`
  pada halaman Login.

### Auth presentation

- Login adalah halaman auth default.
- Login pertama menampilkan pilihan Apple, Google, atau email tanpa membuka
  keyboard secara otomatis.
- Tombol email membuka halaman terpisah berisi email, password,
  `Lupa password`, dan CTA `Masuk`.
- Login menyediakan CTA `Belum punya akun? Daftar sekarang`.
- Register berada pada halaman terpisah.
- Register pertama menampilkan pilihan Apple, Google, atau email; tombol email
  baru membuka form email, password, konfirmasi password, dan CTA `Daftar`.
- Tombol Apple memakai tampilan native Sign in with Apple. Tombol Google
  memakai aset logo resmi Google; Phase 09.5 tetap mencegat aksinya dengan
  adapter fake dan tidak memulai OAuth sebenarnya.
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

- [x] Semua tab dapat dinavigasi tanpa membuat fake Participant session.
- [x] Guest tidak melihat `Diikuti` atau `Riwayat` seolah mempunyai enrollment.
- [x] State `Diikuti` dan `Riwayat` menjelaskan bahwa login diperlukan untuk
  melihat data akun.
- [x] Guest tidak melihat focus activity, progress, streak, current Coach,
  current-user leaderboard highlight, private winner data, atau submission.
- [x] Home guest tidak menampilkan nama/avatar fixture Participant.
- [x] Profile guest tidak menampilkan email atau data fixture.
- [x] Public leaderboard tidak memuat email, nomor HP, berat, private media,
  raw QR, atau identifier sensitif.
- [x] Direktori Coach guest hanya memuat Coach approved dan public.
- [x] Semua mutation menggunakan centralized auth gate.
- [x] Guest browsing tidak membuat anonymous Supabase user.

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

- [x] `UserRole` tetap hanya Participant, Coach, dan Admin.
- [x] `DemoRole.guest` hanya memilih guest presentation pada Debug.
- [x] `DemoRole.guest` tidak mempunyai `userRole` palsu.
- [x] Refactor mapping `DemoRole → shell/access` agar guest dapat memakai
  Participant tabs tanpa Participant session.
- [x] `SessionState.loggedOut` menjadi sumber guest access.
- [x] Hilangkan auto-switch logged-out ke Participant pada Guest flow.
- [x] Public snapshot tidak menyimpan personal profile/enrollment.

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

- [x] Eligibility merupakan computed domain rule, bukan kondisi tersebar di
  View.
- [x] Member selalu ineligible untuk Coach.
- [x] SC ke atas memenuhi syarat level.
- [x] HOM STS dan ICT wajib `true`.
- [x] Price band berasal dari `MemberLevel` melalui domain service.
- [x] Gunakan `Decimal` atau integer minor unit untuk nilai harga; jangan
  gunakan binary floating point.
- [x] UI memformat harga menggunakan locale `id-ID`.
- [x] View tidak dapat menulis `paymentVerified`, `approved`, atau role.
- [x] Application menyimpan snapshot level dan terms/version agar review
  tidak berubah diam-diam ketika profile diedit.
- [x] Admin decision menyimpan actor, timestamp, dan reason bila ditolak.

## Guest demo pada Root

Tambahkan pilihan `Guest` pada pemilih peran Debug.

Behavior:

- [x] `Guest` muncul bersama Peserta, Coach, dan Admin.
- [x] Guest menjadi default yang direkomendasikan untuk menguji auth entry.
- [x] Memilih Guest membuka Participant shell dalam logged-out state.
- [x] Sediakan skenario:
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
- [x] Launch argument `-DemoRole guest` membuka Guest deterministically.
- [x] Launch argument skenario invalid jatuh ke Guest Home, bukan membuat
  Participant session.
- [x] Participant/Coach/Admin demo lama tetap tersedia dan tidak berubah
  menjadi guest.

## Home Guest

Ganti `HomeProfileCard` dengan auth CTA ketika session logged-out.

Konten:

- Judul singkat yang menjelaskan manfaat akun.
- Primary action `Masuk`.
- Tidak menampilkan avatar, nama, badge role, poin, atau Coach fixture.

Checklist:

- [x] CTA memakai semantic button styles dan minimum touch target.
- [x] Card dapat diakses pada light/dark mode dan Dynamic Type.
- [x] `Masuk` membuka Login.
- [x] Home tidak menampilkan tombol `Daftar` kedua.
- [x] Register dibuka melalui CTA pada halaman Login.
- [x] Kembali dari auth mempertahankan tab dan scroll context yang wajar.
- [x] Program publik tetap berada setelah auth CTA sesuai hierarchy Home.
- [x] Focus section personal diganti logged-out explanation, bukan data kosong
  yang seolah error.
- [x] Home guest tidak melakukan network/auth request langsung dari `body`.

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

- [x] Simpan destination/intention yang aman sebelum auth.
- [x] Untuk `Gabung program`, simpan program ID; QR Coach baru dipertahankan
  jika memang sudah dipindai.
- [x] Jangan simpan raw QR pada UserDefaults, clipboard, log, analytics, atau
  callback URL.
- [x] Tampilkan Login sebagai default.
- [x] Sediakan CTA Register.
- [x] Setelah fake auth berhasil, lanjutkan ke onboarding bila profile belum
  lengkap.
- [x] Setelah onboarding selesai, kembali ke destination yang valid.
- [x] Callback/destination lama ditolak bila user membatalkan atau context
  kedaluwarsa.
- [x] Auth gate idempoten dan tidak menumpuk sheet berulang.

## Login UI

Halaman default:

1. Logo/brand header yang ringkas.
2. Sign in with Apple.
3. Google.
4. Email.
5. CTA `Belum punya akun? Daftar sekarang`.

Tombol email membuka halaman form terpisah:

1. Email.
2. Password dengan show/hide yang accessible.
3. `Lupa password`.
4. Primary action `Masuk`.

Checklist:

- [x] Gunakan `Form` atau scrollable form native yang aman untuk keyboard.
- [x] Halaman pilihan provider tidak mempunyai field terfokus dan tidak
  membuka keyboard otomatis.
- [x] `textContentType(.username)`/email dan `.password` disiapkan.
- [x] Password tidak disalin ke state global, analytics, log, atau fixture.
- [x] Apple dan Google memakai presentation adapter fake pada Phase 09.5.
- [x] Loading, success, cancel, validation, offline, provider error, dan
  unknown state tersedia.
- [x] Duplicate submit dicegah.
- [x] Error field berhubungan dengan field untuk VoiceOver.
- [x] Tidak mengungkap apakah email terdaftar.
- [x] Phase 09.5 tidak menampilkan token atau credential demo.
- [x] Banner Debug menjelaskan bahwa tidak ada akun nyata dibuat, tanpa muncul
  pada production UI.

## Register UI

Register adalah halaman terpisah dengan hierarchy yang sama seperti Login,
bukan perluasan inline Login.

Urutan:

1. Sign in with Apple.
2. Google.
3. Email.
4. CTA `Sudah punya akun? Masuk`.

Tombol email membuka halaman form terpisah:

1. Email.
2. Password.
3. Konfirmasi password.
4. Primary action `Daftar`.

Checklist:

- [x] Tidak ada pemilih role pada credential form.
- [x] Apple/Google registration dan login memakai tombol/provider yang sama;
  onboarding ditentukan setelah session/profile load.
- [x] Email validation dan password requirement tampil sebagai UX guidance.
- [x] Password dan confirmation dibandingkan hanya di feature state.
- [x] Password dihapus dari memory state ketika flow selesai/dibatalkan
  sejauh practical.
- [x] Fake register hanya membuat draft credential di memory dan belum
  menghasilkan user, profil, atau session Participant.
- [x] Semua metode fake register masuk ke onboarding profil yang sama.
- [x] Existing fake user melewati onboarding bila profile sudah lengkap.

## Forgot Password UI

- [x] Halaman email recovery terpisah.
- [x] Response selalu generik.
- [x] State sent, rate-limited, offline, dan retry tersedia.
- [x] Phase 09.5 tidak mengirim email.
- [x] Fake result memungkinkan UI success diperiksa.
- [x] Reset-password callback UI sebenarnya tetap Phase 10.

## Onboarding Profil

Form wajib:

- Nama.
- Nomor HP.
- Level Member.
- Pilihan `Lanjut sebagai Peserta` atau `Ajukan menjadi Coach`.

Aturan:

- [x] Nama wajib, trimmed, dan mempunyai batas panjang yang konsisten.
- [x] Nomor HP wajib untuk onboarding baru dan divalidasi tanpa mengirim OTP
  pada Phase 09.5.
- [x] Nomor HP tidak dicatat pada log atau analytics.
- [x] `MemberLevel` memakai Picker native.
- [x] Level member bukan role dan bukan authorization claim.
- [x] City tidak lagi menjadi field wajib onboarding baru; field lama dapat
  tetap tersedia sebagai data profil opsional sampai keputusan migrasi dibuat.
- [x] Pilihan Peserta membuka tahap pemindaian QR Coach dan belum membuat
  akun.
- [x] Pilihan Coach membuka eligibility flow.
- [x] Memilih Member menonaktifkan pilihan Coach dengan penjelasan yang jelas.
- [x] Mengubah level setelah mengisi form merekonsiliasi eligibility dan harga.
- [x] Draft onboarding bertahan selama flow aktif di feature state, tidak
  ditulis ke repository atau UserDefaults sebelum pendaftaran final.

## Finalisasi registrasi atomik dan pembatalan

Registration draft tidak boleh mengubah repository sebelum seluruh prasyarat
tujuan akun selesai:

- Peserta: credential draft → profil → QR Coach valid → finalisasi akun.
- Coach applicant: credential draft → profil → eligibility → pembayaran demo
  verified → finalisasi akun Participant dan pengajuan Coach.

Aturan:

- [x] Peserta wajib memindai QR Coach approved/public yang valid.
- [x] Tombol membuat akun Peserta disabled sebelum QR Coach tervalidasi.
- [x] Finalisasi Peserta membuat user, profil Participant, dan relasi Coach
  dalam satu operasi actor repository.
- [x] Finalisasi Coach membuat user, profil Participant, dan pengajuan Coach
  pending Admin dalam satu operasi actor repository setelah pembayaran
  verified.
- [x] Menutup flow sebelum titik finalisasi menghapus draft credential,
  profil, QR, eligibility, dan payment preview dari memory.
- [x] Pembatalan mengembalikan aplikasi ke Guest tanpa user, profil,
  enrollment, atau pengajuan parsial.
- [x] Validasi diulang di repository; View tidak menjadi otoritas QR,
  eligibility, harga, pembayaran, atau role.

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

- [x] Member melihat state tidak memenuhi syarat dan CTA pembayaran disabled.
- [x] SC ke atas melihat syarat level terpenuhi otomatis.
- [x] Checkbox tidak dicentang otomatis.
- [x] CTA pembayaran disabled sampai HOM STS dan ICT dicentang.
- [x] Disabled state menjelaskan syarat yang belum lengkap.
- [x] Harga tidak dihitung di View.
- [x] User dapat kembali mengubah level tanpa kehilangan data non-sensitif.
- [x] Copy tidak menyatakan Coach aktif sebelum pembayaran dan Admin approval.
- [x] Sediakan link Syarat & Ketentuan placeholder hanya jika destination
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

- [x] Tidak memanggil StoreKit production.
- [x] Tidak meminta kartu, rekening, OTP, atau data pembayaran.
- [x] Tidak membuat fake receipt yang menyerupai credential production.
- [x] Fake outcome deterministic: success, cancelled, pending, failed,
  interrupted.
- [x] Success membuat akun Participant dan application pending secara atomik,
  bukan role Coach.
- [x] Duplicate fake callback tidak membuat payment/application kedua.
- [x] Harga mock diberi label Debug-only pada tooling, tidak pada production
  product UI.
- [x] Production UI kemudian memakai localized price dari StoreKit.

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

- [x] User tetap Participant pada draft, payment, dan pending approval.
- [x] Satu user hanya mempunyai satu active application.
- [x] Repeated submit mengembalikan application yang sama.
- [x] Payment verified tidak sama dengan Coach approved.
- [x] Admin approved tidak boleh true tanpa payment verified dan eligibility
  complete.
- [x] QR Coach baru dibuat setelah activation server-side pada phase backend.
- [x] Rejection memerlukan alasan.
- [x] Rejected application tidak otomatis menghapus payment record.
- [ ] Refund/credit policy untuk rejection harus diputuskan sebelum transaksi
  production diaktifkan.
- [x] Access expiry dan renewal manual menjadi entitlement state terpisah dari
  profile display.
- [ ] Policy apakah renewal memerlukan approval ulang harus diputuskan sebelum
  Phase 12 production exit.

## Admin Coach Approval

Gunakan Admin Dashboard/People yang sudah ada, tetapi tampilkan application,
bukan Coach role prematur.

Dashboard:

- [x] Pending count berasal dari `CoachApplication.pendingAdminApproval`.
- [x] Quick action membuka daftar Pengajuan Coach.

Daftar:

- [x] Pending applicant tetap dapat ditemukan walaupun role-nya Participant.
- [x] Jangan bergantung pada filter `UserRole.coach`.
- [x] Tambahkan scope/segment `Pengajuan Coach` atau destination khusus yang
  tetap mengikuti hierarchy People.
- [x] Row menampilkan nama, level, payment status, dan application status.
- [x] Jangan menampilkan nomor HP penuh pada row bila tidak diperlukan.

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

- [x] `Setujui Coach` disabled kecuali level eligible, HOM STS, ICT, dan
  payment verified.
- [x] Approval memakai confirmation.
- [x] Reject memerlukan reason.
- [x] Admin tidak dapat mengedit attestation menjadi true atas nama applicant.
- [x] Admin dapat melihat field mana yang belum memenuhi syarat.
- [x] Approval local mock membuat CoachProfile dan role Coach secara atomik.
- [x] Approval mencatat audit local.
- [x] Repeated approval idempoten.
- [x] Applicant approved muncul pada daftar Coach dan dapat membuka Coach
  demo setelah session reload.
- [x] Applicant pending/rejected tetap tidak dapat membuka Coach shell.

## Frontend safety

- [x] Guest tidak direpresentasikan sebagai authenticated Participant.
- [x] Views tidak menentukan authorization atau payment verification.
- [x] Views tidak mengubah role.
- [x] Harga tidak tersebar sebagai magic number pada Views.
- [x] Password hanya hidup pada auth feature state sesingkat practical.
- [x] Nomor HP tidak masuk log, analytics, atau test failure output.
- [x] Tidak ada provider token/secret pada fake adapter.
- [x] Tidak ada raw QR Coach pada auth callback.
- [x] Semua error production-facing dipetakan ke Bahasa Indonesia.
- [x] Semua `String(localized:)` mempunyai `defaultValue` Bahasa Indonesia.
- [x] User-facing price memakai `FormatStyle.currency(code: "IDR")` dengan
  locale `id-ID`.
- [x] Personal state dibersihkan saat logout/account switch.
- [x] Navigation ke Coach/Admin selalu melewati capability guard.
- [x] Local demo tetap dapat berjalan tanpa Colima.

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

- [x] Tidak memakai email/nomor HP orang nyata.
- [x] Password tidak disimpan pada fixture.
- [x] Fake purchase tidak menyerupai receipt production.
- [x] ID deterministic.
- [x] Clock injected untuk expiry tiga bulan.
- [x] Harga berada pada domain pricing fixture/service, bukan per-view.

## Accessibility dan UI verification

- [x] Login/Register dapat discroll ketika keyboard dan Dynamic Type besar.
- [x] Secure field show/hide mempunyai label, value, dan touch target.
- [x] Picker level dapat digunakan VoiceOver.
- [x] Checkbox HOM STS/ICT mempunyai state yang terbaca.
- [x] Disabled Coach/payment CTA menjelaskan penyebab.
- [x] Status paid/pending/approved/rejected tidak hanya memakai warna.
- [x] Admin dapat membaca seluruh eligibility pada Dynamic Type besar.
- [x] Light/dark mode.
- [x] Increase Contrast.
- [x] Reduce Transparency.
- [x] Reduce Motion.
- [x] Differentiate Without Color.
- [x] Device locale `en_US` tetap menampilkan Bahasa Indonesia dan tidak
  menampilkan localization key.
- [x] iPad layout tidak menjadi form terlalu lebar.

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

- [x] Sembilan level decode/encode dan display mapping.
- [x] Member ineligible.
- [x] SC/SB = Rp100.000.
- [x] Supervisor/World Team = Rp150.000.
- [x] TAB/GET/Millionaire/President’s Team = Rp200.000.
- [x] HOM STS false memblokir.
- [x] ICT false memblokir.
- [x] Price uses Decimal/integer minor unit.
- [x] Payment verified tidak mengubah role.
- [x] Approval tanpa payment ditolak.
- [x] Approval tanpa eligibility ditolak.
- [x] Duplicate application/approval idempoten.
- [x] Three-month expiry memakai injected clock.

### Guest

- [x] Guest tidak mempunyai AppUser/profile.
- [x] Semua Participant tabs dapat dibuka.
- [x] Personal data tidak muncul.
- [x] Home hanya menampilkan `Masuk`.
- [x] Profile menampilkan logged-out state.
- [x] Catalog public dapat dibaca.
- [x] Join membuka Login.
- [x] Cancel auth kembali ke program.
- [x] Guest tidak dapat submit/upload/weigh/edit profile.

### Auth UI

- [x] Login adalah default.
- [x] Pilihan provider tampil sebelum form email dan tidak membuka keyboard.
- [x] Register CTA membuka Register.
- [x] Existing-account CTA kembali ke Login.
- [x] Apple fake success/cancel/error.
- [x] Google fake success/cancel/error.
- [x] Email fake login validation.
- [x] Email fake register validation.
- [x] Forgot Password generic success.
- [x] Duplicate submit dicegah.
- [x] Tidak ada password/token pada logs.

### Onboarding

- [x] Semua auth methods membuka form yang sama.
- [x] Nama wajib.
- [x] Nomor HP wajib dan tervalidasi.
- [x] Level wajib.
- [x] Peserta wajib memindai QR Coach sebelum akun dibuat.
- [x] Pembatalan sebelum QR valid tidak menyimpan user/profil.
- [x] Coach applicant baru disimpan setelah pembayaran demo verified.
- [x] Pembatalan sebelum pembayaran verified tidak menyimpan user/profil.
- [x] Member tidak dapat memilih Coach.
- [x] SC ke atas dapat membuka eligibility.
- [x] Harga berubah sesuai level.

### Admin

- [x] Pending applicant terlihat walaupun role Participant.
- [x] Detail menampilkan level/HOM STS/ICT/payment.
- [x] Approval disabled bila belum lengkap.
- [x] Rejection memerlukan alasan.
- [x] Approval atomik membuat Coach access local.
- [x] Dashboard count berubah.
- [x] Audit tercatat.
- [x] Applicant tidak dapat self-approve.

### UI regression

- [x] Participant demo lama.
- [x] Coach demo lama.
- [x] Admin CMS lama.
- [x] Program catalog/join.
- [x] QR same-Coach guard.
- [x] Leaderboard public/private fields.
- [x] Localization.
- [x] Accessibility.

## Dokumentasi yang wajib diperbarui

Checklist ini merupakan bagian exit criteria, bukan pekerjaan opsional.

- [x] `00_START_HERE.md`
  - Tambahkan Phase 09.5 pada urutan.
  - Dokumentasikan Guest sebagai access state.
- [x] `UI_REFERENCE_SHEET.md`
  - Guest Home CTA.
  - Login/Register hierarchy.
  - Profile onboarding.
  - Coach eligibility/payment preview.
  - Admin application review.
- [x] `AGENTS.md`
  - Guest bukan authenticated role.
  - Self-registration tetap Participant.
  - Coach selection berarti application.
  - Coach role memerlukan verified payment dan Admin approval.
- [x] `11_PHASE_10_AUTH_EMAIL_GOOGLE_APPLE.md`
  - Tandai Phase 09.5 sebagai prerequisite.
  - Gunakan UI yang sudah dibuat.
  - Tambahkan profile/member/application persistence handoff.
- [x] `12_PHASE_11_REAL_DATA_AND_SERVER_OPERATIONS.md`
  - Tulis ulang kontrak lama invite/wallet.
  - Tambahkan public-safe Guest reads dan Coach application operation.
- [x] `13_PHASE_12_STOREKIT_PROGRAM_PAYMENTS.md`
  - Tambahkan manual three-month Coach access payment.
  - Evaluasi StoreKit non-renewing subscription.
  - Tambahkan server verification, entitlement, expiry, restore/refund.
- [x] `14_PHASE_13_SECURITY_RELEASE_AND_TESTFLIGHT.md` dan
  `14A_PHASE_13_1_RELEASE_HARDENING_HOSTED_AND_PHYSICAL_TESTING.md`
  - Pertahankan Guest privacy, Coach application, payment, expiry, dan
    physical-device acceptance scenarios pada workplan Phase 13.1.
- [x] `PROGRAM_END_TO_END_REMEDIATION_WORKPLAN.md`
  - Tambahkan guest/auth/onboarding/Coach access lifecycle.
- [x] `PROGRAM_END_TO_END_CONTRACT_MATRIX.md`
  - Tambahkan owner dan authority untuk member level, eligibility,
    application, payment, approval, role, dan entitlement.
- [x] `PROGRAM_END_TO_END_IMPLEMENTATION_STATUS.md`
  - Catat local UI selesai vs backend/external gate.
- [x] `Contracts/program-api-v1.openapi.yaml`
  - Tambahkan contract pada phase backend, bukan ketika baru UI mock.
- [x] `supabase/README.md`
  - Dokumentasikan migration/test baru pada Phase 10/11/12.
- [x] `Localizable.xcstrings`
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

- [x] Guest tersedia pada pemilih peran demo.
- [x] Guest membuka seluruh Participant tabs tanpa authenticated user palsu.
- [x] Home Guest hanya menampilkan `Masuk`; Register dibuka dari Login.
- [x] Join program membuka Login default.
- [x] Login, Register, Forgot Password, Apple, Google, dan email/password UI
  dapat didemokan dengan fake adapters.
- [x] Semua fake registration methods membuka onboarding profil yang sama.
- [x] Tidak ada fake user/profile yang disimpan sebelum QR Peserta atau
  pembayaran Coach tervalidasi.
- [x] Onboarding berisi nama, nomor HP, sembilan level, dan account purpose.
- [x] Member tidak dapat mengajukan Coach.
- [x] SC ke atas harus mencentang HOM STS dan ICT.
- [x] Harga preview sesuai level dan berformat IDR.
- [x] Pembayaran preview bersifat manual untuk tiga bulan dan tidak
  auto-renew.
- [x] Payment preview success tidak langsung memberikan role Coach.
- [x] Admin melihat seluruh eligibility dan payment state.
- [x] Admin tidak dapat approve sebelum seluruh precondition lengkap.
- [x] Pending applicant tetap Participant dan tidak mempunyai Coach access.
- [x] Approval/rejection local idempoten dan teraudit.
- [x] Existing Participant, Coach, Admin, program, QR, scoring, dan CMS
  regression tests tetap lulus.
- [x] Local demo tetap berjalan tanpa internet dan Colima.
- [x] Tidak ada Supabase/OAuth/StoreKit production call atau secret baru.
- [x] Dokumentasi pada checklist sudah diperbarui.
- [x] Full Swift tests dan simulator build lulus.
- [x] Focused Guest/Auth/Admin UI tests lulus.
- [x] Tidak ada localization key terlihat pada device locale `en_US`.

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

### 5 Agustus 2026 — Heading auth diperbesar tanpa text shrinking

- Files changed:
  - `Features/Auth/AuthenticationFlowView.swift`.
  - `MSC_Codex_Phased_Workplan/UI_REFERENCE_SHEET.md`.
- Assumptions:
  - `Selamat datang kembali`, `Buat akun baru`, dan heading auth lanjutan
    merupakan judul layar, bukan judul section.
- Build:
  - XcodeBuildMCP `build_run_sim`, iPhone 17 iOS 26.5,
    `-AppleLanguages (en) -AppleLocale en_US -DemoRole guest
    -DemoScenario auth_login`: lulus tanpa warning.
- Test:
  - `testGuestHomeOpensProviderFirstLoginRegisterAndForgotPassword`: lulus.
  - `testLargestDynamicTypeKeepsGuestAndAuthActionsReachable`: lulus.
  - Localization catalog guard dan `git diff --check`: lulus.
- Result:
  - Heading auth memakai semantic `.largeTitle.bold`, Dynamic Type, dan
    wrapping tanpa pengecilan.
  - Login dan Register memakai leading edge penuh yang sama sehingga panjang
    judul tidak lagi menggeser posisi header.
- Remaining blockers:
  - Tidak ada blocker lokal yang diketahui.

### 5 Agustus 2026 — Auth native navigation dan tipografi stabil

- Files changed:
  - `Domain/Models/MembershipModels.swift`.
  - `Features/Auth/AuthenticationFlowState.swift`.
  - `Features/Auth/AuthenticationFlowView.swift`.
  - `Resources/Localizable.xcstrings`.
  - `MSCBodyTransformationUITests/Phase095GuestAuthUITests.swift`.
  - `MSC_Codex_Phased_Workplan/UI_REFERENCE_SHEET.md`.
- Assumptions:
  - Login adalah root auth; Register dan langkah lanjut merupakan typed
    destination.
  - Pending Coach approval adalah terminal state sehingga back navigation
    tetap dinonaktifkan pada halaman tersebut.
- Build:
  - XcodeBuildMCP `build_run_sim`, iPhone 17 iOS 26.5,
    `-AppleLanguages (en) -AppleLocale en_US -DemoRole guest
    -DemoScenario auth_login`: lulus tanpa warning.
- Test:
  - `Phase095GuestAuthCoachApplicationTests`: 16 passed, 0 failed.
  - `Phase095GuestAuthUITests`: 7 passed, 0 failed.
  - Gesture simulator `swipe-from-left-edge` dari Daftar kembali ke Masuk:
    lulus.
- Result:
  - Auth memakai `NavigationStack(path:)` dengan typed routes.
  - Native back button dan leading-edge swipe bekerja pada Register, email,
    Forgot Password, profile, QR, eligibility, dan payment.
  - Leading-edge swipe pada root Login menutup auth cover dan kembali ke
    aplikasi.
  - Judul navigasi menjadi `Masuk` dan `Daftar`.
  - CTA pergantian Masuk/Daftar memakai ukuran teks tetap dan beralih ke
    layout vertikal bila ruang horizontal tidak cukup.
- Remaining blockers:
  - Tidak ada blocker lokal Phase 09.5.

### 5 Agustus 2026 — Localization key leakage diperbaiki dan diberi guard

- Files changed:
  - `Features/Auth/ProfileAndCoachApplicationViews.swift`.
  - `Resources/Localizable.xcstrings`.
  - `MSCBodyTransformationUITests/Phase095GuestAuthUITests.swift`.
  - `scripts/check_localization_catalog.sh`.
  - `AGENTS.md`.
- Assumptions:
  - Copy aplikasi tetap selalu Bahasa Indonesia pada locale perangkat apa pun.
  - Machine-style localization key wajib memiliki nilai `id` dan copy kritis
    tetap mempunyai runtime `defaultValue`.
- Build:
  - XcodeBuildMCP `build_run_sim`, iPhone 17 iOS 26.5,
    `-AppleLanguages (en) -AppleLocale en_US -DemoRole guest
    -DemoScenario coach_pending_approval`: lulus tanpa warning.
- Test:
  - `scripts/check_localization_catalog.sh`: lulus; tidak ada machine key
    tanpa copy Bahasa Indonesia.
  - `Phase08AccessibilityReliabilityTests`: 10 passed, 0 failed.
  - `testCoachApplicationScenariosExposeEligibilityAndPendingStates`:
    1 passed, 0 failed.
- Result:
  - `coach.pending.payment_verified`,
    `coach.pending.participant_role`, dan `coach.pending.admin_review` tidak
    lagi terlihat sebagai key.
  - Delapan machine key lain yang belum mempunyai nilai `id` turut diperbaiki.
  - UI test locale `en_US` sekarang memeriksa copy status dan menolak raw key.
- Remaining blockers:
  - Tidak ada blocker lokal Phase 09.5.

### 4 Agustus 2026 — Revisi provider-first dan registrasi atomik selesai

- Files changed:
  - Guest Home, authentication flow/state, profile/Coach onboarding, dan
    repository finalization.
  - Aset logo Google resmi, localization catalog, Swift tests, dan UI tests.
  - Workplan Phase 09.5, UI Reference Sheet, serta handoff Phase 10.
- Assumptions:
  - Apple, Google, dan payment tetap fake adapter pada Phase 09.5.
  - Apple memakai tampilan kontrol native; Google memakai aset brand resmi.
  - Draft registrasi hanya hidup di memory sampai seluruh prasyarat tujuan
    akun selesai.
- Build:
  - XcodeBuildMCP `build_run_sim`, iPhone 17 iOS 26.5, Debug,
    `-DemoRole guest -DemoScenario auth_login -AppleLanguages (en)
    -AppleLocale en_US`: lulus tanpa warning.
- Test:
  - `MSCBodyTransformationTests`: 160 passed, 0 failed.
  - `Phase095GuestAuthCoachApplicationTests`: 16 passed, 0 failed sebagai
    bagian dari suite Swift.
  - `Phase095GuestAuthUITests`: 6 passed, 0 failed.
  - `testAdminApprovesCoachAndManuallyEnrollsParticipant`: 1 passed,
    0 failed.
- Result:
  - Beranda Guest hanya mempunyai satu CTA `Masuk`.
  - Login/Register provider-first dan tidak membuka keyboard otomatis.
  - Form email, Forgot Password, profile, checkbox eligibility, dan seluruh
    primary CTA mengikuti hierarchy yang konsisten.
  - Peserta baru dibuat setelah QR Coach valid.
  - Coach applicant baru dibuat setelah fake payment verified dan tetap
    Participant sampai Admin menyetujui.
  - Pembatalan sebelum finalisasi kembali ke Guest tanpa data parsial.
- Remaining external gates:
  - Phase 10 mengaktifkan Supabase Auth dan OAuth nyata.
  - Phase 11 menerapkan finalisasi profil, QR Coach, dan Coach application
    secara authoritative di server.
  - Phase 12 mengganti pembayaran demo dengan StoreKit terverifikasi.

### 4 Agustus 2026 — Implementasi local Phase 09.5 selesai

- Files changed:
  - App shell/launch configuration untuk `DemoRole.guest`.
  - Guest-safe Participant store dan Home/Program/Leaderboard/Coach/Profile.
  - Domain membership, pricing, eligibility, application, payment, dan
    decision.
  - Fake Auth/purchase repositories dan UI Login/Register/Forgot
    Password/profile/Coach application.
  - Admin People/application review, atomic approval/rejection, dan audit.
  - Fixture, localization, Swift tests, UI tests, serta seluruh documentation
    handoff Phase 10–13.
- Assumptions:
  - Phase 09.5 tetap local/mock dan tidak membutuhkan Colima.
  - Fake payment hanya preview; applicant tetap Participant sampai Admin
    approval.
  - Refund/rejection dan renewal-approval policy tetap keputusan Phase 12.
- Build:
  - XcodeBuildMCP `build_run_sim`, iPhone 17 iOS 26.5: lulus tanpa warning.
  - XcodeBuildMCP `build_run_sim`, iPad mini iOS 26.5, locale `en_US`:
    lulus; form Register terukur dan key localization tidak terlihat.
- Test:
  - `MSCBodyTransformationTests`: 157 passed, 0 failed.
  - `Phase095GuestAuthCoachApplicationTests`: 13 passed, 0 failed.
  - `Phase095GuestAuthUITests`: 5 passed, 0 failed.
  - Admin Coach approval regression: 1 passed, 0 failed.
  - Participant, Coach, dan Admin CMS critical journeys: masing-masing
    1 passed, 0 failed.
- Result:
  - Seluruh exit criteria local Phase 09.5 terpenuhi.
  - Simulator dikembalikan ke default iPhone 17, dark mode, standard content
    size, dan Increase Contrast off.
- Remaining external gates:
  - Phase 10 Supabase Auth/session/profile bootstrap dan provider setup.
  - Phase 11 public Guest reads, Coach application migration/RLS, dan atomic
    server approval.
  - Phase 12 StoreKit verification, entitlement, expiry/renewal/refund.

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
