# Phase 04: Coach Experience UI

## Tujuan

Membangun seluruh coach-facing experience dengan mock wallet, mock programs, mock participants, local invites, dan review queue.

## External dependency status

**Lokal sepenuhnya.**

Tidak ada StoreKit transaction, Supabase, atau external QR redemption.

## Keputusan produk 2026-07-28

Model kuota peserta dan undangan per program tidak lagi digunakan. Setiap
coach memiliki satu QR identifier unik yang tidak terikat program. Peserta
memindainya setelah memilih program. UI wallet, pembelian kuota, composer
undangan, masa berlaku, dan riwayat undangan tidak lagi menjadi alur produk.

## Screen inventory

### Dashboard

- [x] Public coach identity.
- [x] Mock wallet seat balance.
- [x] Active programs.
- [x] Total assigned participants.
- [x] Completion metrics.
- [x] Missing step count.
- [x] Pending review count.
- [x] Quick actions.
- [x] Offline and error states.

### Participants

- [x] Participant list.
- [x] Search.
- [x] Filter by program.
- [x] Filter by completion status.
- [x] Filter by review status.
- [x] Sort by progress, points, dan last activity.
- [x] Participant row with progress.
- [x] Empty filter state.

### Program participation

- [x] Program tab in the Coach app shell.
- [x] Shared Participant program catalog and filter flow.
- [x] Shared program offer and enrollment flow.
- [x] Shared Coach QR scan and confirmation flow.
- [x] Shared enrolled-program activity and step flow.
- [x] Coach session remains authorized as Coach while participating.

### Participant detail

- [x] Profile summary.
- [x] Program and enrollment summary.
- [x] Initial/final weight availability.
- [x] Daily completion timeline.
- [x] Step submissions.
- [x] Evidence thumbnails.
- [x] Text answers.
- [x] Score breakdown.
- [x] Missing-step indicators.
- [x] Private-data warning and access context.

### Review queue

- [x] Pending submissions list.
- [x] Evidence viewer.
- [x] Step instruction context.
- [x] Approve action.
- [x] Reject action.
- [x] Rejection reason required.
- [x] Confirmation.
- [x] Updated local score after decision.
- [x] Undo is not required. Use a new explicit review action if allowed.

### Invite

- [x] Available program selector.
- [x] Mock seat balance.
- [x] Invite capacity.
- [x] Expiry configuration.
- [x] Generate local opaque token.
- [x] Generate QR image locally.
- [x] Share sheet for local invite.
- [x] Invite history.
- [x] Revoke local invite.
- [x] Exhausted and expired states.
- [x] Explain that production seat consumption happens only after successful enrollment.

### Coach store preview

This phase only builds UI and local product fixtures.

- [x] Seat pack cards: 10, 25, and 50.
- [x] Local sample price text.
- [x] Purchase CTA disabled or routed to demo confirmation.
- [x] Purchase state previews: loading, available, purchasing, pending, success, cancelled, error.
- [x] Purchase history mock.
- [x] Clear label that Debug demo does not perform a real purchase.
- [x] Do not instantiate live StoreKit transaction flow.

### Leaderboard

- [x] Program selector.
- [x] Top five.
- [x] Current coach participants marker.
- [x] Provisional and final states.
- [x] Score detail.

### Profile

- [x] Public coach profile editor UI.
- [x] Photo picker placeholder or local picker.
- [x] Bio.
- [x] Visibility status.
- [x] Purchase history mock.
- [x] Settings.

## Local behavior

- [x] Coach can locally enroll in a program as a participant capability.
- [x] Approve submission updates local participant points.
- [x] Reject requires reason and removes local awarded points.
- [x] Generate invite decrements nothing.
- [x] Local mock redemption consumes seat only after successful enrollment.
- [x] Duplicate enrollment consumes no additional seat.
- [x] Insufficient seat state blocks local redemption.
- [x] Coach cannot navigate to unrelated participant fixture.
- [x] Coach store demo can simulate successful credit grant through Debug-only action.

## State architecture

Pisahkan:

- Dashboard feature state.
- Participant list state.
- Participant detail state.
- Review queue state.
- Invite composer state.
- Store preview state.
- Coach profile state.

Jangan membuat satu `CoachViewModel` besar.

## Previews

- [x] Coach dashboard normal.
- [x] Wallet zero.
- [x] Pending review.
- [x] No participants.
- [x] Participant complete.
- [x] Participant falling behind.
- [x] Evidence rejected.
- [x] Invite active.
- [x] Invite exhausted.
- [x] Purchase success preview.
- [x] Largest Dynamic Type.
- [x] Dark mode.

## Tests

### Swift Testing

- [x] Coach filters.
- [x] Review decision validation.
- [x] Rejection reason required.
- [x] Local score recalc.
- [x] Invite capacity.
- [x] Duplicate local enrollment.
- [x] Wallet cannot become negative in mock.
- [x] Unrelated participant access is blocked by mock repository contract.

### UI tests

- [x] Launch as coach.
- [x] Open participant detail.
- [x] Open evidence.
- [x] Approve submission.
- [x] Generate local invite QR.
- [x] Open store preview.
- [x] Verify no real purchase prompt occurs.

## Larangan scope

Jangan:

- Mengakses App Store Connect.
- Membuat live purchase.
- Menganggap mock access check sebagai pengganti RLS.
- Mengunggah coach profile ke server.
- Menyimpan transaction id palsu sebagai production model.
- Menambahkan service secrets.

## Exit criteria

- [x] Coach journey dapat didemokan tanpa internet.
- [x] Review action mengubah local score.
- [x] Invite dan QR dapat dibuat lokal.
- [x] Store UI lengkap tetapi tidak melakukan transaksi live.
- [x] Coach hanya melihat assigned participant fixtures.
- [x] Test lulus dan clean build.

## Progress log

### Log

#### 2026-07-31 — Ringkasan Peserta Coach lebih ringkas

- Files changed: `CoachParticipantsView.swift` dan progress log Phase 04.
- Assumptions: angka ringkasan dan ukuran teks semantic dipertahankan; kartu
  dipadatkan melalui spacing, padding, dan ukuran wadah ikon agar tetap aman
  untuk Dynamic Type.
- Build command: XcodeBuildMCP `build_sim` dan `build_run_sim` untuk scheme
  `MSCBodyTransformation`, konfigurasi Debug, pada iPhone 17 iOS 26.5.
- Test command: XcodeBuildMCP `test_sim` untuk
  `testCoachParticipantDynamicLabelsFallbackToIndonesian`.
- Result: build lulus tanpa warning dan satu UI test alur Peserta Coach lulus.
  Verifikasi runtime memastikan kartu mengikuti tinggi ideal konten tanpa
  ruang kosong vertikal.
- Remaining blockers: tidak ada.

#### 2026-07-31 — Fallback lokalisasi dinamis lintas locale

- Files changed: fallback string dinamis pada fitur Coach dan Participant,
  UI test Coach, aturan repository `AGENTS.md`, dan progress log Phase 04.
- Assumptions: Bahasa Indonesia tetap menjadi copy production utama meskipun
  aplikasi atau Simulator berjalan dengan locale selain `id`. Setiap
  `String(localized:)` wajib memiliki `defaultValue` Bahasa Indonesia karena
  development region project masih `en`; perubahan tidak menyentuh
  `project.pbxproj`.
- Build command: XcodeBuildMCP `build_run_sim(launchArgs:
  ["-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-DemoRole",
  "coach", "-DemoScenario", "coach_review_queue", "-SkipDemoLanding"])`,
  lalu Simulator diverifikasi kembali dalam dark appearance.
- Test command: XcodeBuildMCP `test_sim(extraArgs:
  ["-only-testing:MSCBodyTransformationUITests/MSCBodyTransformationUITests/testCoachParticipantDynamicLabelsFallbackToIndonesian",
  "-only-testing:MSCBodyTransformationUITests/MSCBodyTransformationUITests/testCoachDashboardAttentionAndProgramOpenFilteredParticipants"])`.
- Result: build dan launch lulus tanpa warning; dua UI test lulus. Runtime
  locale Inggris dan dark mode memverifikasi placeholder pencarian, ringkasan
  filter, aktivitas, jumlah peserta perhatian, serta alasan kartu seluruhnya
  memakai copy Bahasa Indonesia tanpa key `coach.*`.
- Remaining blockers: tidak ada blocker lokal Phase 04.

#### 2026-07-31 — Direktori dan prioritas peserta Coach

- Files changed: daftar peserta Coach, detail peserta, presenter Coach,
  destination shell, katalog lokalisasi, UI test Coach, dan progress log
  Phase 04.
- Assumptions: `Peserta saya` merupakan direktori seluruh peserta dengan
  pencarian, filter program/status, urutan, progres, dan aktivitas terakhir.
  `Perlu perhatian` merupakan daftar kerja otomatis yang hanya memuat peserta
  tertinggal atau belum mulai, tanpa mencampurkan status pemeriksaan bukti.
  Kedua alur memakai route dan detail peserta yang sama. Filter daftar umum
  memakai satu bottom sheet; hanya daftar kartu yang scroll pada layar utama.
- Build command: XcodeBuildMCP `build_run_sim(launchArgs:
  ["-AppleLanguages", "(id)", "-AppleLocale", "id_ID", "-DemoRole",
  "coach", "-DemoScenario", "coach_review_queue", "-SkipDemoLanding"])`.
- Test command: XcodeBuildMCP `test_sim(extraArgs:
  ["-only-testing:MSCBodyTransformationTests/Phase04CoachTests"])` dan
  `test_sim(extraArgs:
  ["-only-testing:MSCBodyTransformationUITests/MSCBodyTransformationUITests/testCoachDashboardAttentionAndProgramOpenFilteredParticipants"])`.
- Result: build dan launch iPhone 17 Simulator lulus tanpa warning; 15 test
  Phase 04 dan UI test rute perhatian/program lulus. Runtime memverifikasi
  semua label Bahasa Indonesia tampil tanpa localization key, filter sheet
  memakai tombol rounded rectangle yang konsisten, kartu peserta tidak
  menampilkan status review bukti, serta tombol detail menggulir ke bukti dan
  rincian progres yang sama.
- Remaining blockers: tidak ada blocker lokal Phase 04.

#### 2026-07-30 — Penolakan tanpa modal bertumpuk

- Files changed: detail dan form penolakan bukti Coach, UI test Coach, serta
  progress log Phase 04.
- Assumptions: penolakan merupakan langkah lanjutan dari pemeriksaan bukti,
  sehingga memakai push navigation di dalam sheet detail yang sama. Tidak ada
  sheet kedua. Tombol `Batal` dan `Kirim penolakan` memakai rounded rectangle
  dengan tinggi 50 dan radius yang sama; tombol sekunder menggunakan outline
  destructive, bukan kapsul native `.bordered`.
- Build command: XcodeBuildMCP `build_run_sim(launchArgs:
  ["-AppleLanguages", "(id)", "-AppleLocale", "id_ID", "-DemoRole",
  "coach", "-DemoScenario", "coach_review_queue", "-SkipDemoLanding"])`.
- Test command: XcodeBuildMCP `test_sim(extraArgs:
  ["-only-testing:MSCBodyTransformationUITests/MSCBodyTransformationUITests/testCoachRejectionUsesSingleSheetNavigationFlow",
  "-only-testing:MSCBodyTransformationUITests/MSCBodyTransformationUITests/testCoachViewsAutomaticEvidenceAndSavesOptionalRating"])`.
- Result: build dan launch iPhone 17 Simulator lulus tanpa warning; dua UI
  test terfokus lulus. Runtime memverifikasi jumlah sheet tidak bertambah
  ketika `Tolak bukti` dibuka, navigation back mengembalikan detail, kedua
  tombol footer memiliki lebar minimum dan tinggi yang sama, serta alur bukti
  otomatis/rating tidak mengalami regresi.
- Remaining blockers: tidak ada blocker lokal Phase 04.

#### 2026-07-30 — Header native pusat bukti

- Files changed: pusat bukti Coach dan progress log Phase 04.
- Assumptions: `Periksa bukti` menjadi satu-satunya judul layar dengan gaya
  navigation title besar seperti halaman Peserta. Section `Bukti peserta`
  beserta kalimat penjelas dihapus; konten langsung dimulai dari segmented
  control dan kartu filter.
- Build command: XcodeBuildMCP `build_run_sim(launchArgs:
  ["-AppleLanguages", "(id)", "-AppleLocale", "id_ID", "-DemoRole",
  "coach", "-DemoScenario", "coach_review_queue", "-SkipDemoLanding"])`.
- Test command: XcodeBuildMCP `test_sim(extraArgs:
  ["-only-testing:MSCBodyTransformationUITests/MSCBodyTransformationUITests/testCoachViewsAutomaticEvidenceAndSavesOptionalRating"])`.
- Result: build dan launch iPhone 17 Simulator lulus tanpa warning; UI test
  terfokus lulus. Runtime memverifikasi header besar native, tidak ada copy
  penjelas yang tersisa, kontrol/filter tetap diam, dan daftar bukti tetap
  menjadi satu-satunya area scroll vertikal.
- Remaining blockers: tidak ada blocker lokal Phase 04.

#### 2026-07-30 — Hilangkan poin menunggu dari kartu bukti

- Files changed: kartu daftar bukti Coach dan progress log Phase 04.
- Assumptions: hanya copy poin untuk bukti manual yang masih pending
  persetujuan yang dihilangkan. Poin otomatis dan hasil keputusan tetap dapat
  ditampilkan pada status lain, sedangkan nilai langkah lengkap tetap tersedia
  di detail bukti.
- Build command: XcodeBuildMCP `build_run_sim(launchArgs:
  ["-AppleLanguages", "(id)", "-AppleLocale", "id_ID", "-DemoRole",
  "coach", "-DemoScenario", "coach_review_queue", "-SkipDemoLanding"])`.
- Test command: XcodeBuildMCP `test_sim(extraArgs:
  ["-only-testing:MSCBodyTransformationUITests/MSCBodyTransformationUITests/testCoachViewsAutomaticEvidenceAndSavesOptionalRating"])`.
- Result: build dan launch iPhone 17 Simulator lulus tanpa warning; UI test
  terfokus lulus. Runtime dan accessibility snapshot memverifikasi copy
  `10 poin menunggu` tidak lagi dirender atau dibacakan pada kartu pending,
  tanpa meninggalkan jarak kosong.
- Remaining blockers: tidak ada blocker lokal Phase 04.

#### 2026-07-30 — Hierarki visual kartu bukti Coach

- Files changed: kartu daftar bukti Coach dan progress log Phase 04.
- Assumptions: referensi visual dipakai untuk seluruh status bukti, bukan
  hanya fixture pending. Kartu tetap memakai `UserAvatar` peserta; foto bukti
  hanya tampil setelah detail dibuka. Metadata berada pada blok atas, divider
  memenuhi lebar konten kartu, status dan poin berada di kiri, serta rating
  opsional memakai badge di kanan. Pada Dynamic Type accessibility, kedua
  badge boleh ditumpuk agar tidak terpotong.
- Build command: XcodeBuildMCP `build_run_sim(launchArgs:
  ["-AppleLanguages", "(id)", "-AppleLocale", "id_ID", "-DemoRole",
  "coach", "-DemoScenario", "coach_review_queue", "-SkipDemoLanding"])`.
- Test command: XcodeBuildMCP `test_sim(extraArgs:
  ["-only-testing:MSCBodyTransformationUITests/MSCBodyTransformationUITests/testCoachViewsAutomaticEvidenceAndSavesOptionalRating"])`.
- Result: build dan launch iPhone 17 Simulator lulus tanpa warning; UI test
  terfokus lulus. Runtime memverifikasi program/hari dan tanggal tetap satu
  baris pada fixture standar, badge status dan penilaian sejajar, kartu tetap
  dapat dibuka, filter bukti tetap berfungsi, serta rating opsional tersimpan.
- Remaining blockers: tidak ada blocker lokal Phase 04.

#### 2026-07-30 — Bottom sheet filter pusat bukti

- Files changed: pusat bukti Coach, lokalisasi, UI test bukti otomatis, dan
  progress log Phase 04.
- Assumptions: bar chip horizontal Program, Status, dan Penilaian diganti satu
  kartu `Filter bukti` selebar konten. Kartu menampilkan ringkasan filter
  aktif dan membuka bottom sheet dengan pilihan tunggal per bagian. Pilihan
  memakai state draft; `Tutup` membatalkan perubahan, `Atur ulang` mereset
  draft, dan daftar baru berubah setelah `Terapkan filter`. Header, segmented
  control, serta kartu filter menetap; hanya daftar kartu bukti yang scroll.
- Build command: XcodeBuildMCP `build_run_sim(launchArgs:
  ["-AppleLanguages", "(id)", "-AppleLocale", "id_ID", "-DemoRole",
  "coach", "-DemoScenario", "coach_review_queue", "-SkipDemoLanding"])`.
- Test command: XcodeBuildMCP `test_sim(extraArgs:
  ["-only-testing:MSCBodyTransformationTests/Phase04CoachTests",
  "-only-testing:MSCBodyTransformationUITests/MSCBodyTransformationUITests/testCoachViewsAutomaticEvidenceAndSavesOptionalRating"])`.
- Result: build dan launch iPhone 17 Simulator lulus tanpa warning; 15 test
  Phase 04 dan satu UI test terfokus lulus. Runtime memverifikasi kartu filter
  tanpa scroll horizontal, bottom sheet dan footer tetap, pemilihan status
  `Poin otomatis`, penerapan filter, daftar-only scroll, pembukaan detail, dan
  penyimpanan rating opsional. Ringkasan filter membungkus maksimal dua baris
  agar tidak terpotong pada lebar iPhone.
- Remaining blockers: tidak ada blocker lokal Phase 04.

#### 2026-07-30 — Ukuran kontrol dan isolasi scroll daftar bukti

- Files changed: pusat bukti Coach, UI test bukti otomatis, dan progress log
  Phase 04.
- Assumptions: permintaan ukuran mengacu pada segmented control `Perlu
  tindakan`/`Semua bukti`, yang kini memiliki tinggi visual setara dengan
  chip filter di bawahnya. Judul, deskripsi, segmented control, dan bar filter
  menetap. Hanya daftar kartu bukti yang menerima scroll vertikal; bar chip
  Program, Status, dan Penilaian tetap memiliki scroll horizontal tersendiri.
- Build command: XcodeBuildMCP `build_run_sim(launchArgs:
  ["-DemoRole", "coach", "-DemoScenario", "coach_review_queue",
  "-SkipDemoLanding"])`.
- Test command: XcodeBuildMCP `test_sim(extraArgs:
  ["-only-testing:MSCBodyTransformationUITests/MSCBodyTransformationUITests/testCoachViewsAutomaticEvidenceAndSavesOptionalRating"])`
  dan `test_sim(extraArgs:
  ["-only-testing:MSCBodyTransformationUITests/MSCBodyTransformationUITests/testCoachCompletesCriticalLocalJourney"])`.
- Result: build dan launch lulus tanpa warning; dua UI test lulus. Runtime
  memverifikasi segmented control dan chip filter memiliki tinggi yang sama,
  header/filter tetap pada frame yang sama setelah swipe vertikal daftar,
  bar filter dikenali sebagai scroll horizontal terpisah, serta alur
  persetujuan dan rating tetap berfungsi.
- Remaining blockers: tidak ada blocker lokal Phase 04.

#### 2026-07-30 — Fallback lokalisasi dan Picker skenario Debug

- Files changed: pusat/detail bukti Coach, formatter pesan Coach, landing
  Debug, UI test bukti otomatis, dan progress log Phase 04.
- Assumptions: Bahasa Indonesia tetap menjadi source language dan fallback
  production. Copy yang menerima nilai dinamis dipertahankan sebagai resource
  SwiftUI sampai dirender agar nama localization key tidak pernah menjadi
  label verbatim ketika bahasa perangkat bukan `id`. Selection skenario Debug
  selalu diproyeksikan ke skenario valid untuk role yang sedang dipilih.
- Build command: XcodeBuildMCP `build_run_sim(launchArgs:
  ["-DemoRole", "coach", "-DemoScenario", "coach_review_queue",
  "-SkipDemoLanding"])` tanpa override bahasa; `build_run_sim(launchArgs: [])`
  untuk landing Debug; dan `build_sim(extraArgs:
  ["IPHONEOS_DEPLOYMENT_TARGET=17.0", "SWIFT_VERSION=6",
  "SWIFT_STRICT_CONCURRENCY=complete"])`.
- Test command: XcodeBuildMCP `test_sim(extraArgs:
  ["-only-testing:MSCBodyTransformationTests/Phase02NavigationTests",
  "-only-testing:MSCBodyTransformationTests/Phase04CoachTests",
  "-only-testing:MSCBodyTransformationUITests/MSCBodyTransformationUITests/testCoachCompletesCriticalLocalJourney",
  "-only-testing:MSCBodyTransformationUITests/MSCBodyTransformationUITests/testCoachViewsAutomaticEvidenceAndSavesOptionalRating"])`.
- Result: build dan launch lulus. Empat test navigasi, 15 test Coach, dan dua
  UI test terfokus lulus. Pusat bukti, detail persetujuan, detail poin
  otomatis, hari, waktu kirim, dan CTA menampilkan copy Indonesia tanpa key
  mentah pada konfigurasi bahasa Simulator biasa. Perpindahan role Peserta ke
  Coach tidak lagi menghasilkan warning selection `participantActive`; log
  `Membuka app shell demo lokal.` juga dihapus. Strict build tetap hanya
  melaporkan dua warning concurrency lama di
  `AdminContentAndWinnerViews.swift`, di luar scope perubahan ini.
- Remaining blockers: pesan duplikasi
  `UIAccessibilityLoaderWebShared` masih berasal dari accessibility bundle
  WebKit/WebCore milik runtime iOS 26.5 Simulator, bukan class aplikasi.
  Tidak ada blocker lokal Phase 04.

#### 2026-07-30 — Pusat bukti, mode verifikasi, dan rating Coach

- Files changed: model submission, protocol dan mock repository submission,
  use case rating lokal, service/state/container/presentation review Coach,
  tampilan pusat bukti dan detail, lokalisasi, test Phase 04 dan UI test, serta
  progress log Phase 04.
- Assumptions: daftar bukti hanya memakai foto profil peserta melalui
  `UserAvatar`; foto atau jawaban bukti baru terlihat setelah detail dibuka.
  `Perlu tindakan` hanya berisi submission `coachReview` yang masih pending,
  sedangkan `Semua bukti` juga menampilkan submission otomatis dan riwayat
  keputusan. Rating 1–5 bersifat opsional, disimpan terpisah pada submission,
  dan tidak mengubah status maupun perhitungan poin.
- Build command: XcodeBuildMCP `build_run_sim(launchArgs:
  ["-AppleLanguages", "(id)", "-AppleLocale", "id_ID", "-DemoRole",
  "coach", "-DemoScenario", "coach_review_queue", "-SkipDemoLanding"])`;
  serta `build_sim(extraArgs: ["IPHONEOS_DEPLOYMENT_TARGET=17.0",
  "SWIFT_VERSION=6", "SWIFT_STRICT_CONCURRENCY=complete"])`.
- Test command: XcodeBuildMCP `test_sim` untuk `Phase04CoachTests`;
  `Phase01FixtureTests` dan `Phase07LocalScoringTests`; UI test
  `testCoachCompletesCriticalLocalJourney`; serta UI test baru
  `testCoachViewsAutomaticEvidenceAndSavesOptionalRating`.
- Result: build dan launch iPhone 17 Simulator lulus tanpa warning; 15 test
  Phase 04, 26 test fixture/scoring, dan dua UI test terfokus lulus. Runtime
  memverifikasi avatar profil pada daftar, detail persetujuan manual, detail
  poin otomatis tanpa tombol setuju/tolak, rating opsional, dan sheet alasan
  penolakan. Strict build lulus dengan dua warning concurrency lama di
  `AdminContentAndWinnerViews.swift`, di luar scope perubahan ini.
- Remaining blockers: media fixture tetap memakai placeholder aman karena
  tidak ada file bukti privat yang dibundel. Media produksi dan penyimpanan
  rating server tetap menunggu fase backend/media terkait.

#### 2026-07-30 — Ikon netral kartu Periksa bukti

- Files changed: `CoachDashboardView` dan progress log Phase 04.
- Assumptions: seluruh ikon quick action memakai warna teks utama yang adaptif.
  Badge kuning dan garis aksen merah tetap membedakan jumlah antrean tanpa
  memberi emphasis khusus pada ikon Periksa bukti.
- Build command: XcodeBuildMCP `build_run_sim(launchArgs:
  ["-AppleLanguages", "(id)", "-AppleLocale", "id_ID", "-DemoRole",
  "coach", "-DemoScenario", "coach_review_queue", "-SkipDemoLanding"])`.
- Test command: XcodeBuildMCP UI test terfokus
  `testCoachCompletesCriticalLocalJourney`.
- Result: build dan launch lulus tanpa warning; UI test lulus. Ikon Periksa
  bukti kini netral dan aksinya tetap berfungsi.
- Remaining blockers: tidak ada blocker lokal.

#### 2026-07-30 — Border netral kartu Periksa bukti

- Files changed: `CoachDashboardView` dan progress log Phase 04.
- Assumptions: urgensi antrean pemeriksaan tetap disampaikan melalui ikon
  merah dan badge jumlah berwarna kuning. Seluruh quick action memakai border
  netral yang sama agar hierarchy grid konsisten.
- Build command: XcodeBuildMCP `build_run_sim(launchArgs:
  ["-AppleLanguages", "(id)", "-AppleLocale", "id_ID", "-DemoRole",
  "coach", "-DemoScenario", "coach_review_queue", "-SkipDemoLanding"])`.
- Test command: XcodeBuildMCP UI test terfokus
  `testCoachCompletesCriticalLocalJourney`.
- Result: build dan launch lulus tanpa warning; UI test lulus. Kartu Periksa
  bukti tetap interaktif dan tidak lagi memakai outline merah.
- Remaining blockers: tidak ada blocker lokal.

#### 2026-07-30 — Dashboard Coach sebagai pusat aksi cepat

- Files changed: tab dan route Coach; app-shell destination dan fallback;
  Dashboard, state ringkasan, daftar Peserta, tab root, dan preview Coach;
  lokalisasi; test navigasi, Coach, aksesibilitas, dan UI; serta progress log
  Phase 04.
- Assumptions: mockup pilihan menjadi acuan pada iPhone dengan enam aksi dalam
  grid tiga kolom dan dua baris. Pada Dynamic Type accessibility, grid berubah
  menjadi satu kolom agar teks tidak dipotong. Bottom tab Coach dipadatkan
  menjadi Dashboard, Program, dan Profil; layar Peserta dan Peringkat yang
  sudah ada tetap digunakan sebagai destination dari Dashboard. Kartu program
  dampingan membuka daftar Peserta dengan filter program terkait.
- Build command: XcodeBuildMCP `build_run_sim(launchArgs:
  ["-AppleLanguages", "(id)", "-AppleLocale", "id_ID", "-DemoRole",
  "coach", "-DemoScenario", "coach_review_queue", "-SkipDemoLanding"])`;
  launch accessibility dengan
  `UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge`; dan
  `build_sim(extraArgs: ["IPHONEOS_DEPLOYMENT_TARGET=17.0",
  "SWIFT_VERSION=6", "SWIFT_STRICT_CONCURRENCY=complete"])`.
- Test command: XcodeBuildMCP `test_sim` untuk
  `Phase02NavigationTests`, `Phase04CoachTests`, dan
  `Phase08AccessibilityReliabilityTests`; UI test
  `testCoachLeaderboardAndProfileUseParticipantInformationArchitecture`,
  `testCoachDashboardProfileCardSelectsProfileTab`,
  `testCoachCanJoinProgramThroughSharedParticipantFlow`,
  `testCoachCompletesCriticalLocalJourney`, dan
  `testCoachDashboardAttentionAndProgramOpenFilteredParticipants`.
- Result: build dan launch iPhone 17 Simulator lulus tanpa warning; 27 unit
  dan integration-style test serta lima UI test terfokus lulus. Enam quick
  action, badge data-driven, tiga bottom tab, filter peserta, QR, review,
  Peringkat, Program, Profil, dan kartu program interaktif telah diverifikasi.
  Strict build lulus dengan dua warning concurrency lama di
  `AdminContentAndWinnerViews.swift`, di luar scope perubahan ini.
- Remaining blockers: tidak ada blocker lokal. Data dan otorisasi production
  tetap menunggu fase backend/auth terkait.

#### 2026-07-30 — Konsistensi kartu profil Dashboard

- Files changed: komponen identitas bersama, Dashboard Participant dan Coach,
  wiring pemilihan tab Coach, preview Coach, lokalisasi, UI test, dan progress
  log Phase 04.
- Assumptions: kartu Dashboard kedua role menggunakan hierarki visual dan
  interaksi yang sama: sapaan, avatar, nama, badge role, dan chevron. Tap
  memilih tab Profil tanpa membuat navigation push. Kota, status visibilitas,
  dan bio Coach tetap tersedia pada layar Profil, bukan di kartu Dashboard.
- Build command: XcodeBuildMCP `build_run_sim(launchArgs:
  ["-AppleLanguages", "(id)", "-AppleLocale", "id_ID", "-DemoRole",
  "coach", "-DemoScenario", "coach_review_queue", "-SkipDemoLanding"])`.
- Test command: XcodeBuildMCP `test_sim(extraArgs:
  ["-only-testing:MSCBodyTransformationUITests/MSCBodyTransformationUITests/testCoachDashboardProfileCardSelectsProfileTab",
  "-only-testing:MSCBodyTransformationUITests/MSCBodyTransformationUITests/testParticipantHomeProfileCardSelectsProfileTab"])`.
- Result: build dan launch lulus tanpa warning; dua UI test lulus. Visual kartu
  Coach serta perpindahan langsung ke tab Profil diverifikasi pada iPhone 17
  Simulator. Dashboard Participant tetap memakai perilaku yang sama.
- Remaining blockers: tidak ada blocker lokal untuk perubahan ini.

#### 2026-07-30 — Perbaikan lebar kartu penawaran program

- Files changed: `ParticipantProgramOfferView`, UI test alur Program Coach,
  dan progress log Phase 04.
- Assumptions: kartu ringkasan program harus memenuhi lebar container konten
  dengan margin horizontal standar, terlepas dari panjang judul atau jumlah
  metadata. Perubahan tetap menggunakan view bersama Participant dan Coach.
- Build command: XcodeBuildMCP `build_run_sim(launchArgs:
  ["-AppleLanguages", "(id)", "-AppleLocale", "id_ID", "-DemoRole",
  "coach", "-DemoScenario", "coach_review_queue", "-SkipDemoLanding"])`.
- Test command: XcodeBuildMCP `test_sim(extraArgs:
  ["-only-testing:MSCBodyTransformationUITests/MSCBodyTransformationUITests/testCoachCanJoinProgramThroughSharedParticipantFlow"])`.
- Result: build dan launch lulus tanpa warning; UI test lulus. Kartu untuk
  judul pendek `Transformasi 7 hari` diverifikasi memenuhi lebar container
  pada iPhone 17 Simulator. Test juga memastikan lebar kartu lebih dari 85%
  lebar window agar regresi intrinsic-width tidak kembali.
- Remaining blockers: tidak ada blocker lokal untuk perbaikan visual ini.

#### 2026-07-30 — Tab Program dan partisipasi program Coach

- Files changed: app tab dan route Coach; app-shell dependency wiring;
  `ParticipantJourneyStore`; view katalog, detail, enrollment, aktivitas, dan
  langkah Program Participant yang kini menerima konteks navigasi bersama;
  fixture profil partisipasi Coach; lokalisasi; test fixture, navigasi,
  Participant, Coach, reliabilitas, dan UI; serta workplan Phase 04.
- Assumptions: akun Coach tetap memiliki role otorisasi `coach`, tetapi dapat
  memiliki profil partisipasi terpisah untuk enrollment program. Seluruh UI
  dan alur Program memakai file Participant yang sama. Tab Coach tetap lima
  item agar tidak berubah menjadi menu `Lainnya`; QR Coach tetap dapat dibuka
  dari quick action Dashboard dan section QR di Profil.
- Build command: XcodeBuildMCP `build_run_sim(launchArgs:
  ["-AppleLanguages", "(id)", "-AppleLocale", "id_ID", "-DemoRole",
  "coach", "-DemoScenario", "coach_review_queue", "-SkipDemoLanding"])`
  dan `build_sim(extraArgs: ["IPHONEOS_DEPLOYMENT_TARGET=17.0",
  "SWIFT_VERSION=6", "SWIFT_STRICT_CONCURRENCY=complete"])`.
- Test command: XcodeBuildMCP `test_sim(extraArgs:
  ["-only-testing:MSCBodyTransformationTests/Phase04CoachTests",
  "-only-testing:MSCBodyTransformationTests/Phase02NavigationTests",
  "-only-testing:MSCBodyTransformationTests/Phase01FixtureTests",
  "-only-testing:MSCBodyTransformationTests/Phase08AccessibilityReliabilityTests"])`;
  `test_sim(extraArgs:
  ["-only-testing:MSCBodyTransformationTests/Phase03ParticipantTests"])`;
  dan UI test terfokus `testCoachCanJoinProgramThroughSharedParticipantFlow`,
  `testCoachCompletesCriticalLocalJourney`, serta
  `testParticipantSelectsProgramBeforeOpeningDetail`.
- Result: build dan launch lulus tanpa warning; 32 test lintas Phase 01, 02,
  04, dan 08 lulus; 13 test Participant lulus; ketiga UI test terfokus lulus.
  Katalog Coach, enrollment melalui QR, aktivitas setelah enrollment, alur
  Coach yang sudah ada, dan regresi Program Participant telah diverifikasi
  pada iPhone 17 Simulator. Strict build lulus dengan dua warning concurrency
  lama di `AdminContentAndWinnerViews.swift`, di luar scope.
- Remaining blockers: otorisasi dual-capability dan penyimpanan profil
  partisipasi Coach di backend tetap menunggu fase backend/auth terkait.

#### 2026-07-30 — Interaksi rincian poin pada kartu leaderboard

- Files changed: komponen podium bersama, layar dan snapshot Peringkat Coach,
  lokalisasi, test Phase 04, serta UI test Coach.
- Assumptions: tidak ada section `Rincian poin` terpisah. Pada akun Coach,
  hanya kartu bertanda `Pesertamu` yang dapat membuka modal rincian, termasuk
  podium peringkat 1–3 dan kartu peringkat lainnya. Akun Participant tetap
  memakai komponen yang sama tanpa interaksi rincian Coach. Tampilan visual
  kartu leaderboard tidak berubah.
- Build command: XcodeBuildMCP `build_run_sim(launchArgs:
  ["-DemoRole", "coach", "-DemoScenario", "coach_review_queue",
  "-SkipDemoLanding"])` dan `build_sim(extraArgs:
  ["IPHONEOS_DEPLOYMENT_TARGET=17.0", "SWIFT_VERSION=6",
  "SWIFT_STRICT_CONCURRENCY=complete"])`.
- Test command: XcodeBuildMCP `test_sim(extraArgs:
  ["-only-testing:MSCBodyTransformationTests/Phase04CoachTests"])` dan
  `test_sim(extraArgs:
  ["-only-testing:MSCBodyTransformationUITests/MSCBodyTransformationUITests/testCoachLeaderboardAndProfileUseParticipantInformationArchitecture"])`,
  serta `test_sim(extraArgs:
  ["-only-testing:MSCBodyTransformationUITests/MSCBodyTransformationUITests/testParticipantLeaderboardDoesNotExposeCoachScoreDetails"])`.
- Result: build dan run Simulator lulus tanpa warning pada file yang diubah;
  build minimum iOS 17/Swift 6 lulus; 11 test Coach dan dua UI test terfokus
  lulus. Interaksi modal pada podium dan kartu peringkat lainnya, kartu peserta
  yang bukan dampingan tetap noninteraktif, serta ketiadaan interaksi rincian
  Coach pada akun Participant diverifikasi pada iPhone 17 Simulator. Build
  ketat tetap melaporkan dua warning concurrency lama di
  `AdminContentAndWinnerViews.swift`, di luar scope.
- Remaining blockers: tidak ada blocker lokal.

#### 2026-07-30 — Penyelarasan Peringkat dan Profil Coach

- Files changed: komponen leaderboard Participant yang kini dapat menandai
  peserta dampingan; layar dan state Peringkat Coach; layar, editor foto,
  state, snapshot, dan model Profil Coach; lokalisasi; test Phase 04 dan UI
  test Coach.
- Assumptions: “sama seperti peserta” berarti memakai hierarchy, komponen,
  spacing, program selector, podium, Form, dan alur edit profil yang sama.
  Rincian poin, visibilitas profil, status persetujuan, pengingat review, dan
  akses QR tetap dipertahankan sebagai kebutuhan khusus Coach. Identifier
  pendaftaran mentah tidak ditampilkan.
- Build command: XcodeBuildMCP `build_run_sim(launchArgs:
  ["-DemoRole", "coach", "-DemoScenario", "coach_review_queue",
  "-SkipDemoLanding"])` dan `build_sim(extraArgs:
  ["IPHONEOS_DEPLOYMENT_TARGET=17.0", "SWIFT_VERSION=6",
  "SWIFT_STRICT_CONCURRENCY=complete"])`.
- Test command: XcodeBuildMCP `test_sim(extraArgs:
  ["-only-testing:MSCBodyTransformationTests/Phase04CoachTests"])`,
  `test_sim(extraArgs:
  ["-only-testing:MSCBodyTransformationTests/Phase03ParticipantTests"])`,
  dan `test_sim(extraArgs:
  ["-only-testing:MSCBodyTransformationUITests/MSCBodyTransformationUITests/testCoachLeaderboardAndProfileUseParticipantInformationArchitecture"])`.
- Result: build dan run Simulator lulus tanpa warning pada file yang diubah;
  build minimum iOS 17/Swift 6 lulus; 10 test Coach, 13 test Participant, dan
  satu UI test baru lulus. Peringkat dan Profil Coach diverifikasi secara
  visual pada iPhone 17 Simulator. Build ketat masih melaporkan dua warning
  concurrency lama di `AdminContentAndWinnerViews.swift`, di luar scope
  perubahan ini.
- Remaining blockers: tidak ada blocker lokal. Sinkronisasi foto profil,
  pengaturan notifikasi, session logout produksi, dan otorisasi Coach tetap
  menunggu fase backend/auth terkait.

#### 2026-07-28 — QR identifier permanen coach

- Files changed: model dan fixture Coach, state dan view QR Coach, dashboard,
  profil, repository enrollment lokal, lokalisasi, serta test Coach.
- Assumptions: identifier demo bersifat opaque dan unik; identifier produksi
  harus dibuat dan dilindungi server pada fase backend/auth terkait.
- Build command: XcodeBuildMCP `build_run_sim(launchArgs:
  ["-DemoRole", "coach", "-DemoScenario", "coach_review_queue",
  "-SkipDemoLanding"])`.
- Test command: XcodeBuildMCP focused Phase 03, 04, dan 06, lalu seluruh target
  `MSCBodyTransformationTests`.
- Result: layar `QR saya` dirender dan dipindai oleh alur peserta; 29 focused
  test, 97 seluruh unit/integration test, dan UI test Coach kritis lulus.
- Remaining blockers: provisioning identifier coach dari backend belum
  dikerjakan; StoreKit peserta tetap Phase 12.

#### 2026-07-26 — Phase 04 selesai

- Files changed: feature state terpisah untuk dashboard, peserta, detail,
  review queue, invite composer, store preview, leaderboard, dan profil;
  layar Coach lengkap; generator QR Core Image; app-shell routing; repository
  mock untuk save profil, revoke invite, access check, pemakaian dan grant
  kuota; localization; preview matrix; Swift Testing dan XCTest UI.
- Assumptions: bukti media tetap berupa placeholder lokal dan tidak
  menampilkan path privat; harga paket adalah fixture rupiah lokal; QR memuat
  deep link `mscbody://invite/` yang hanya digunakan demo; mock access check
  tidak dianggap sebagai pengganti RLS. Tidak ada StoreKit, Supabase, OAuth,
  networking, package baru, atau perubahan `project.pbxproj`.
- Build command: XcodeBuildMCP `build_run_sim(launchArgs:
  ["-DemoRole", "coach", "-DemoScenario", "coach_review_queue",
  "-SkipDemoLanding"])` pada iPhone 17 Pro dan iPad Pro 13-inch;
  `build_sim()` untuk konfigurasi Debug dan Release dengan
  `SWIFT_VERSION=6`, `SWIFT_STRICT_CONCURRENCY=complete`, dan
  `IPHONEOS_DEPLOYMENT_TARGET=17.0`.
- Test command: XcodeBuildMCP `test_sim(extraArgs:
  ["-only-testing:MSCBodyTransformationTests/Phase04CoachTests"])`,
  `test_sim(extraArgs:
  ["-only-testing:MSCBodyTransformationUITests/MSCBodyTransformationUITests/testCoachCompletesCriticalLocalJourney"])`,
  dan `test_sim()` untuk seluruh scheme.
- Result: sepuluh test Phase 04 serta UI journey Coach lulus; seluruh 46 test,
  build Debug iPhone/iPad, dan build Release lulus tanpa warning. Dashboard
  diverifikasi di dark mode dan accessibility Dynamic Type terbesar; grid
  berubah menjadi satu kolom agar teks tidak terpotong.
- Remaining blockers: tidak ada blocker lokal. Media production, backend/RLS,
  dan transaksi StoreKit tetap ditunda ke phase yang ditetapkan.
