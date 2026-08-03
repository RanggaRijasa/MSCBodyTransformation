# Phase 05: Admin CMS UI

> Status: arsip baseline Phase 05. CMS baru selalu publik, memakai scoring
> program-wide, content/pertanyaan typed, timbang sebagai content step,
> publish preflight, dan duplikasi cohort lossless. Workplan remediation dan
> matriks kontrak menggantikan kontrol lama yang bertentangan.

## Tujuan

Membangun CMS native di dalam aplikasi menggunakan local draft repository. Admin dapat membuat, mengedit, mem-preview, dan mensimulasikan publish program tanpa backend.

## External dependency status

**Lokal sepenuhnya.**

Media menggunakan local references. Publish hanya mengubah status mock.

## Admin tabs

1. Overview
2. Programs
3. People
4. Content
5. Settings

## Overview

- [x] Program counts by status.
- [x] Active participant count.
- [x] Pending coach approvals.
- [x] Pending reviews.
- [x] Scoring status.
- [x] Recent local audit events.
- [x] Quick actions.

## Program list

- [x] Draft, scheduled, active, completed, archived sections.
- [x] Search.
- [x] Status filter.
- [x] Duplicate draft action.
- [x] Archive local action.
- [x] Empty states.
- [x] Error and loading simulations.

## Program editor

Gunakan ringkasan non-linear berbasis `List` dan `NavigationLink`:

1. Info program.
2. Jadwal dan peserta.
3. Aturan dan poin.
4. Konten.
5. Pratinjau program untuk Peserta dan Coach.
6. Tinjau dan publikasi.

Susunan konten mengikuti hierarki:

```text
Program
└── Hari program (1...N)
    └── Langkah (0...N)
        └── Pertanyaan (0...N)
```

Identitas dan cover hanya diedit di Info program. Tanggal, zona waktu, akses,
dan kapasitas hanya diedit di Jadwal dan peserta. Pemeriksaan, wellness,
kebijakan hari, dan poin hanya diedit di Aturan dan poin. Pratinjau serta
publikasi bersifat read-only.

### Basics

- [x] Name.
- [x] Description.
- [x] Category.
- [x] Cover image local reference.
- [x] Cover image or video type.
- [x] Cover alternative text.
- [x] Verification mode.
- [x] Wellness disclaimer reference.

### Dates and timezone

- [x] Self-paced or scheduled pace.
- [x] Fixed duration or specific dates.
- [x] Fixed duration day count.
- [x] Start date.
- [x] End date.
- [x] IANA timezone selection.
- [x] Initial weigh-in window.
- [x] Final weigh-in window.
- [x] Date validation.
- [x] Duration derived safely.

### Scoring and visibility

- [x] Public, approval-required, or invite-only access.
- [x] Unlimited or limited participant capacity.
- [x] Weight points per kg.
- [x] Past step policy.
- [x] Future step policy.
- [x] Automatic or coach review.
- [x] Human-readable scoring preview.
- [x] Warning that server becomes authoritative later.

### Days

- [x] Generate days from date range.
- [x] Sinkronisasi jadwal mempertahankan hari dan konten yang sudah dibuat.
- [x] Pemangkasan hari berisi konten memerlukan konfirmasi.
- [x] Day list.
- [x] Add, remove, and reorder when allowed.
- [x] Day title and description.
- [x] Scheduled date.
- [x] Duplicate day.
- [x] Validation for unique day number and date.

### Steps

- [x] Ordered steps.
- [x] Add article, video, or quiz step.
- [x] Edit step.
- [x] Duplicate step.
- [x] Delete draft step.
- [x] Reorder.
- [x] Title.
- [x] Description.
- [x] Points.
- [x] Requires photo.
- [x] Requires text answer.
- [x] Required or optional.
- [x] Image/video local media.
- [x] Video required-to-watch and autoplay settings.
- [x] Judul langkah menjadi judul tunggal untuk Kuis dan pertanyaan terurut.
- [x] Setiap jenis langkah dapat memiliki pertanyaan pendamping terurut.
- [x] Short answer, long answer, number, single choice, multiple choice,
      image choice, and file upload question types.
- [x] Heading and text layout elements.
- [x] Participant-facing preview.
- [x] Validation for non-negative points.

### Preview

- [x] Renderer aktivitas yang sama dipakai Admin, Peserta, dan Coach.
- [x] Pemilih konteks Peserta/Coach hanya tampil pada wrapper Admin.
- [x] Preview timeline, progres, detail langkah, dan locked states.
- [x] Preview Coach tidak menampilkan angka berat atau foto privat pada daftar.
- [x] Preview leaderboard scoring description.
- [x] Layout adaptif mengikuti perangkat; tidak ada kontrol ukuran perangkat
      pada UI produksi.

### Local publish simulation

- [x] Validate at least one day.
- [x] Validate every day has an active step.
- [x] Validate dates.
- [x] Validate scoring.
- [x] Validate step ordering.
- [x] Validate required media reference when configured.
- [x] Show validation summary.
- [x] Publish changes mock status only.
- [x] Append local audit event.

## People

- [x] User list.
- [x] Segmented role filter for Peserta, Coach, and Admin.
- [x] Pending coach approval.
- [x] Approve coach local action.
- [x] Public coach profile toggle.
- [x] Role-specific profile details for Participant, Coach, and Admin.
- [x] Manual enrollment UI.
- [x] Manual enrollment reason required.
- [x] Local audit record.
- [x] Score adjustment UI with required reason.
- [x] No self-service role promotion outside admin demo.

## Content

- [x] Mobile winner-poster gallery using a two-column native grid.
- [x] Extensible add-content action area, currently containing only winner posters.
- [x] Pure winner-poster image editor without title, body, or winner fields.
- [x] Local media selection.
- [x] Automatic internal metadata for local persistence.
- [x] Visible gallery order.
- [x] Replace poster image.
- [x] Archive poster from the gallery with confirmation.
- [x] Loading, empty, offline, and error states.

## Automatic winner calculation

- [x] Leaderboard preview.
- [x] Lock top five local simulation.
- [x] Locked state prevents silent reorder.
- [x] New score adjustment after lock shows warning.
- [x] Winner order remains owned by leaderboard and winner snapshot logic.
- [x] No separate winner-management UI inside Content.
- [x] Upload local winner poster images with native PhotosPicker.

## Draft persistence

Gunakan salah satu pendekatan native lokal:

- JSON file in application support untuk Debug demo, atau
- In-memory repository dengan fixture reset.

Jangan menambahkan SwiftData hanya untuk sementara bila persistence tidak dibutuhkan. Bila dipilih, dokumentasikan alasan dan migration implications.

## Tests

### Swift Testing

- [x] Program editor validation.
- [x] Day generation.
- [x] Date range validation.
- [x] Step order validation.
- [x] Publish validation.
- [x] Manual enrollment reason.
- [x] Score adjustment reason.
- [x] Winner lock determinism.
- [x] Managed content visibility.
- [x] ID langkah unik pada program multi-hari.
- [x] Sinkronisasi jadwal mempertahankan langkah dan pertanyaan.
- [x] Pemendekan jadwal melaporkan konten yang akan dihapus.
- [x] Reorder hari, langkah, dan pertanyaan tersimpan.

### UI tests

- [x] Launch as admin.
- [x] Create draft.
- [x] Add day and step.
- [x] Preview participant screen.
- [x] Simulate publish.
- [x] Approve coach.
- [x] Manual enroll participant.
- [x] Add a winner poster to the Content gallery.

## Larangan scope

Jangan:

- Membuat SQL.
- Menyimpan live data.
- Menganggap client CMS validation cukup untuk production publish.
- Membolehkan scoring change silent setelah publish.
- Mengunggah media ke server.
- Membuat web admin panel.

## Exit criteria

- [x] Admin dapat membuat valid sample program tanpa perubahan kode.
- [x] Invalid draft tidak dapat dipublish dalam local simulation.
- [x] Preview Peserta dan Coach mencerminkan draft melalui renderer runtime
      yang sama.
- [x] People dan Content screens dapat didemokan.
- [x] Semua privileged local action membuat local audit entry.
- [x] Test lulus dan clean build.

## Progress log

### Log

#### 2026-08-03 — Pratinjau program memakai renderer runtime Peserta/Coach

- Files changed: renderer aktivitas program di `SharedUI`, layar aktivitas
  Peserta, detail progres Coach, wrapper pratinjau dan hub editor Admin,
  default scoring draft, localization catalog, unit/UI tests, inventaris
  layar, status implementasi end-to-end, dan spesifikasi desain pratinjau.
- Assumptions: Admin hanya memiliki pemilih peran, banner penjelasan, dan
  skenario submission deterministik. Program tetap berasal dari mapper
  draft-ke-published yang sama. Hari pertama menjadi hari fokus dan hari
  berikutnya terkunci. Konteks Coach bersifat read-only dan tidak dapat
  membuka layar pengerjaan Peserta. Poin timbang draft baru dimulai dari nol
  dan hanya diaktifkan Admin setelah langkah timbang awal/akhir tersedia.
- Build command: XcodeBuildMCP `build_run_sim` Debug pada iPhone 17 iOS 26.5
  dengan locale perangkat `en_US` dan skenario `admin_draft_program`.
- Test command: XcodeBuildMCP `test_sim` untuk seluruh
  `MSCBodyTransformationTests`, lalu focused XCTest UI
  `testAdminCreatesDraftAddsDayStepPreviewsAndPublishes`,
  `testParticipantCompletesLocalJourneySlice`, dan
  `testCoachCompletesCriticalLocalJourney`.
- Result: build/run lulus tanpa warning/error; 130 unit/integration tests dan
  tiga perjalanan UI end-to-end lulus tanpa failure. Pratinjau tidak lagi
  memiliki kontrol ukuran perangkat atau renderer khusus Admin.
- Remaining blockers: tidak ada blocker lokal. Data server, otorisasi, dan
  scoring authoritative tetap mengikuti phase backend yang ditetapkan.

#### 2026-08-02 — Dashboard menjadi halaman awal Admin

- Files changed: katalog skenario demo, pemetaan tab awal, app shell,
  localization catalog, Swift Testing, focused XCTest UI, preview Admin, dan
  progress log Phase 05.
- Assumptions: Admin umum selalu masuk ke Dashboard. Skenario khusus
  `Draft program admin` dan `Program aktif admin` tetap masuk langsung ke
  Program karena masing-masing memang ditujukan untuk menguji alur tersebut.
  Pemilih demo menyediakan opsi eksplisit `Dashboard Admin`.
- Build command: XcodeBuildMCP `build_run_sim(launchArgs:
  ["-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-DemoRole",
  "admin", "-SkipDemoLanding"])` pada iPhone 17 Pro Max iOS 26.5.
- Test command: XcodeBuildMCP `test_sim` untuk
  `Phase08AccessibilityReliabilityTests` dan focused XCTest UI
  `testRoleSwitchDefaultsAdminToDashboard`.
- Result: build lulus tanpa warning/error; 11 test reliabilitas dan satu
  focused UI test lulus. Runtime snapshot memastikan Dashboard tampil,
  tab Dashboard terpilih, tab Program tidak terpilih, serta tidak ada key
  localization yang terlihat pada locale aplikasi non-Indonesia.
- Remaining blockers: tidak ada blocker lokal. Integrasi backend tetap
  ditunda ke phase yang ditetapkan.

#### 2026-08-02 — Detail Orang konsisten dengan profil peran

- Files changed: sheet detail Orang berbasis peran, komposisi daftar Orang,
  focused UI test, UI reference, dan progress log Phase 05.
- Assumptions: detail memakai field dari model profil yang sama dengan menu
  tiap peran. Peserta memakai foto, nama tampilan, email, kota, nomor HP,
  dan Coach pendamping. Coach memakai foto, nama publik, email, kota, bio,
  status persetujuan, serta visibilitas. Admin tidak memiliki model profil
  terpisah sehingga hanya menampilkan nama dan email akun. Pendaftaran
  manual tetap menjadi alat Admin khusus Peserta.
- Build command: XcodeBuildMCP `build_run_sim` pada iPhone 17 Pro Max
  iOS 26.5, termasuk launch dengan `-AppleLanguages (en) -AppleLocale
  en_US -DemoRole admin -DemoScenario admin_draft_editor
  -SkipDemoLanding`.
- Test command: XcodeBuildMCP `test_sim` untuk
  `testAdminPersonDetailsMatchRoleProfiles` dan
  `testAdminApprovesCoachAndManuallyEnrollsParticipant`.
- Result: build lulus tanpa warning dan kedua UI test lulus. Profil ketiga
  peran terbuka dari bagian identitas dengan judul serta section yang sesuai;
  alur persetujuan Coach dan pendaftaran manual Peserta tetap berfungsi,
  serta tidak ada localization key pada locale perangkat Inggris.
- Remaining blockers: penyimpanan profil produksi tetap ditunda ke fase
  backend yang ditetapkan. Tidak ada blocker lokal.

#### 2026-08-02 — Perataan header dan jarak daftar Orang

- Files changed: layout layar Orang Admin, focused UI test, dan progress log
  Phase 05.
- Assumptions: padding atas header mengikuti header Konten Admin. Jarak
  setelah segmented control tetap berasal dari satu token
  `AppSpacing.medium`; margin atas bawaan `List(.insetGrouped)` tidak ikut
  ditambahkan.
- Build command: XcodeBuildMCP `build_run_sim` pada iPhone 17 Pro Max
  iOS 26.5 dengan skenario `admin_draft_editor`.
- Test command: XcodeBuildMCP `test_sim` untuk
  `testAdminApprovesCoachAndManuallyEnrollsParticipant`, termasuk assertion
  batas jarak segmented control ke baris pertama.
- Result: build lulus tanpa warning dan UI test lulus. Inspeksi runtime
  mengonfirmasi header lebih tinggi serta jarak selector ke kartu pertama
  sekitar 14 poin.
- Remaining blockers: tidak ada blocker lokal.

#### 2026-08-02 — Segmented control peran pada Orang

- Files changed: layar Orang Admin, presentasi judul shell, focused UI test,
  UI reference, dan progress log Phase 05.
- Assumptions: `Peserta` menjadi pilihan awal. Pintasan persetujuan Coach
  dari Dashboard memilih segmen `Coach` dan mempertahankan filter tertunda;
  berpindah ke peran lain mengembalikan scope ke semua akun. Karena peran
  sudah terlihat pada segmen, baris menampilkan kota atau email sebagai
  informasi sekunder dan tidak mengulang label peran.
- Build command: XcodeBuildMCP `build_run_sim` pada iPhone 17 Pro Max
  iOS 26.5, termasuk launch dengan `-AppleLanguages (en) -AppleLocale
  en_US -DemoRole admin -DemoScenario admin_draft_editor
  -SkipDemoLanding`.
- Test command: XcodeBuildMCP `test_sim` untuk
  `testAdminApprovesCoachAndManuallyEnrollsParticipant` dan
  `testAdminDashboardUsesUniqueQuickActions`.
- Result: build lulus tanpa warning; kedua UI test lulus. Inspeksi runtime
  memverifikasi tiga segmen, daftar per peran, judul dan selector tetap,
  serta tidak ada localization key pada locale perangkat Inggris.
- Remaining blockers: tidak ada blocker lokal dan tidak diperlukan perubahan
  Xcode.

#### 2026-08-02 — Kartu tambah poster memenuhi area konten

- Files changed: layout header Konten Admin dan progress log Phase 05.
- Assumptions: selama hanya ada satu jenis konten yang dapat ditambahkan,
  kartu aksi tidak memerlukan grid adaptif dan harus memakai seluruh lebar
  kolom konten. Target tap tetap lebih besar dari batas minimum melalui
  ikon 48 poin dan padding semantik.
- Build command: XcodeBuildMCP `build_run_sim` pada iPhone 17 Pro Max
  iOS 26.5.
- Test command: XcodeBuildMCP `test_sim` untuk
  `testAdminContentHeaderStaysFixedWhilePostersScroll` dan
  `testAdminPosterEditorRequiresPhotoSelection`.
- Result: build lulus tanpa warning; kedua UI test lulus. Inspeksi runtime
  mengonfirmasi kartu memenuhi lebar kolom, padding internal lebih ringkas,
  serta header tetap diam ketika grid poster digulir.
- Remaining blockers: tidak ada blocker lokal.

#### 2026-08-02 — Perbaikan lompatan scroll galeri poster

- Files changed: shell title presentation untuk tab Konten, header statis
  Konten Admin, dan focused UI test.
- Assumptions: judul besar `Konten` dimiliki header layar, bukan large
  navigation title, agar grid poster tidak memicu collapse/expand navigation
  bar. Hanya grid yang menjadi sumber offset scroll.
- Build command: XcodeBuildMCP `build_run_sim` pada iPhone 17 Pro Max
  iOS 26.5 dengan skenario `admin_winner_lock`.
- Test command: XcodeBuildMCP `test_sim` untuk
  `testAdminContentHeaderStaysFixedWhilePostersScroll` dengan tiga swipe
  naik dan tiga swipe turun, serta
  `testAdminPosterEditorRequiresPhotoSelection`.
- Result: build lulus tanpa warning dan kedua UI test lulus. Rekaman masalah
  menunjukkan large title sebelumnya mengubah tinggi layout di tengah
  gesture; setelah dipisahkan, overscroll tidak lagi memindahkan atau
  menumpuk judul dan header.
- Remaining blockers: tidak ada blocker lokal.

#### 2026-08-02 — Header galeri poster tetap terlihat

- Files changed: komposisi layar Konten Admin dan focused UI test.
- Assumptions: bagian `Tambah konten`, kartu tambah poster, judul galeri,
  dan petunjuk merupakan header tetap. Hanya grid poster pemenang yang
  dapat digulir vertikal.
- Build command: XcodeBuildMCP `build_run_sim` pada iPhone 17 Pro Max
  iOS 26.5 dengan skenario `admin_winner_lock`.
- Test command: XcodeBuildMCP `test_sim` untuk
  `testAdminContentHeaderStaysFixedWhilePostersScroll` dan
  `testAdminPosterEditorRequiresPhotoSelection`.
- Result: build lulus tanpa warning; kedua UI test lulus. Posisi header
  tetap setelah grid digulir dan sheet tambah poster tetap dapat dibuka.
- Remaining blockers: tidak ada blocker lokal.

#### 2026-08-02 — Header daftar Program tetap terlihat

- Files changed: komposisi daftar Program Admin dan focused UI test.
- Assumptions: search, filter toolbar, aksi `Buat program baru`, dan pesan
  status merupakan kontrol tetap. Hanya daftar kartu program di bawahnya
  yang dapat digulir.
- Build command: XcodeBuildMCP `build_run_sim` pada iPhone 17 Pro Max
  iOS 26.5 dengan skenario `admin_draft_editor`.
- Test command: XcodeBuildMCP `test_sim` untuk
  `testAdminProgramHeaderStaysFixedWhileCardsScroll` dan
  `testAdminCreatesDraftAddsDayStepPreviewsAndPublishes`.
- Result: build lulus tanpa warning; kedua UI test lulus. Search langsung
  terlihat saat layar dibuka dan posisi search serta tombol buat tidak
  berubah setelah kartu digulir.
- Remaining blockers: tidak ada blocker lokal.

#### 2026-08-02 — Satu alur Program Admin

- Files changed: daftar Program Admin; hub program draft dan terbit;
  pengelompokan progres validasi tiga tahap; navigasi editor; duplikasi
  draft; focused Swift Testing dan XCTest UI; serta artefak desain alur
  Program Admin.
- Assumptions: seluruh program dibuka dari kartu pada daftar yang sama.
  Status `Draft` membuka tiga tahap yang dapat diedit, sedangkan
  `Terjadwal`, `Aktif`, `Selesai`, dan `Diarsipkan` memakai struktur yang
  sama dalam mode baca. Perubahan program terbit hanya dibuat lewat
  `Duplikasikan sebagai draft`; arsip tetap menjadi tindakan terpisah
  dengan konfirmasi.
- Build command: XcodeBuildMCP `build_run_sim` pada iPhone 17 Pro Max
  iOS 26.5, termasuk launch dengan `-AppleLanguages (en) -AppleLocale
  en_US -DemoRole admin -DemoScenario admin_draft_editor
  -SkipDemoLanding`.
- Test command: XcodeBuildMCP `test_sim` untuk seluruh 21
  `Phase05AdminCMSTests`; focused UI
  `testAdminCreatesDraftAddsDayStepPreviewsAndPublishes`;
  `testPublishedAdminProgramIsReadOnlyAndDuplicatesAsDraft`; dan
  `testPublishedAdminProgramRequiresArchiveConfirmation`.
- Result: build lulus tanpa warning; 21 test Phase 05 dan ketiga
  perjalanan UI terkait lulus. Inspeksi runtime memverifikasi daftar
  memiliki satu aksi `Buat program baru`, draft memiliki tepat tiga tahap,
  program aktif tidak menampilkan aksi simpan, salinan membuka draft baru,
  dan tidak ada localization key pada locale perangkat Inggris.
- Remaining blockers: persistence backend, upload media, serta publikasi
  server-authoritative tetap ditunda ke Phase 11. Tidak ada blocker lokal
  dan tidak diperlukan perubahan Xcode.

#### 2026-08-02 — Dashboard Admin berorientasi tindakan

- Files changed: Dashboard Admin baru dan komponen section-nya; filter
  persetujuan Coach pada tab Orang; pintasan editor program dan poster;
  shell tab serta label `Dashboard`; localization catalog; focused unit/UI
  test; dan artefak rencana serta mockup ImageGen.
- Assumptions: Admin memantau jumlah pemeriksaan tertunda, tetapi keputusan
  bukti tetap milik Coach. Akses cepat hanya memuat `Buat program` dan
  `Tambah poster`; tujuan umum Program, Orang, Konten, dan Pengaturan tidak
  diduplikasi dari tab bar, sedangkan antrean tindakan tidak diduplikasi
  sebagai pintasan.
- Build command: XcodeBuildMCP `build_run_sim` dengan
  `SWIFT_VERSION=6`, `SWIFT_STRICT_CONCURRENCY=complete`,
  `IPHONEOS_DEPLOYMENT_TARGET=17.0`, serta launch arguments
  `-AppleLanguages (en) -AppleLocale en_US -DemoRole admin
  -DemoScenario admin_winner_lock -SkipDemoLanding` pada iPhone 17 Pro Max
  iOS 26.5.
- Test command: XcodeBuildMCP `test_sim` untuk seluruh
  `MSCBodyTransformationTests`, focused
  `Phase05AdminCMSTests`, UI test
  `testAdminDashboardUsesUniqueQuickActions`, dan UI test
  `testAppCopyStaysIndonesianWhenDeviceLanguageIsEnglish`.
- Result: build lulus tanpa warning; seluruh 117 unit test lulus, termasuk
  19 test Phase 05; kedua focused UI test lulus. Inspeksi runtime memastikan
  tab `Dashboard`, dua antrean prioritas, dua pintasan unik, tiga metrik
  operasional, status skor lokal, dan tab bar tampil tanpa localization key
  pada locale perangkat Inggris.
- Remaining blockers: pemantauan pemeriksaan per program memerlukan data dan
  destination server-authoritative pada Phase 11. Tidak ada blocker lokal.

#### 2026-07-29 — Konten Admin menjadi galeri poster

- Files changed: layar Konten dan editor poster Admin, navigasi dan quick
  action Admin, factory managed content, localization catalog, UI test, serta
  panduan UI dan phase.
- Assumptions: pemenang ditentukan otomatis oleh leaderboard dan snapshot
  domain. Konten hanya menyimpan gambar poster vertikal 9:16; tidak ada
  judul, deskripsi, status publikasi, atau editor pemenang yang perlu
  ditampilkan kepada Admin.
- Build command: XcodeBuildMCP `build_run_sim` pada iPhone 17 Pro iOS 26.5.
- Test command: XcodeBuildMCP `test_sim` untuk seluruh
  `MSCBodyTransformationTests` serta focused UI test
  `testAdminPosterEditorRequiresPhotoSelection` dan
  `testLegacyCoachAndAdminWinnerScenariosRemainNavigable`.
- Result: galeri dua kolom, area tambah konten, editor gambar murni, aksi
  ganti/arsip, dan penghapusan navigasi `Kelola pemenang` terverifikasi.
  Build lulus tanpa warning, 100/100 unit test lulus, dan kedua journey UI
  lulus.
- Remaining blockers: upload ke storage production dan URL media publik
  tetap ditunda ke fase adapter Supabase.

#### 2026-07-29 — Upload poster pemenang native

- Files changed: editor konten dan pengelolaan pemenang Admin, validator
  managed content, pipeline media lokal, renderer poster shared, fixture,
  unit test, UI test, dan UI reference.
- Assumptions: poster merupakan gambar vertikal 9:16 yang sudah selesai
  didesain; aplikasi tidak menambahkan overlay. File hasil pemilih Foto
  diproses oleh pipeline native dan disimpan sebagai referensi lokal selama
  Track A.
- Build command: XcodeBuildMCP `build_run_sim` pada iPhone 17 Pro iOS 26.5
  untuk skenario participant dan Admin.
- Test command: XcodeBuildMCP `test_sim` untuk seluruh
  `MSCBodyTransformationTests` serta focused UI test
  `testAdminPosterEditorRequiresPhotoSelection`.
- Result: build lulus tanpa warning; 100/100 unit test lulus. UI test
  membuktikan Simpan nonaktif tanpa poster dan gambar harus dipilih melalui
  pemilih Foto native.
- Remaining blockers: upload ke storage production dan URL media publik
  tetap ditunda ke fase adapter Supabase.

#### 2026-07-26 — Phase 05 selesai

- Files changed: model draft CMS lengkap beserta kebijakan visibilitas,
  metadata konten, status arsip, dan audit event; protocol serta actor
  repository lokal; validator dan use case publish/enrollment/skor/pemenang;
  lima layar tab Admin; editor program tujuh tahap; pratinjau peserta;
  pengelolaan orang, konten, dan snapshot pemenang; app-shell routing;
  fixture, localization catalog, Swift Testing, XCTest UI, dan README.
- Assumptions: persistence in-memory dipilih agar fixture dapat di-reset dan
  tidak memerlukan migrasi SwiftData; referensi gambar/video tetap berupa
  nama resource lokal; publish hanya mengubah status mock; snapshot pemenang
  sengaja tidak berubah setelah dikunci; scoring preview belum
  server-authoritative. Tidak ada Supabase, OAuth, StoreKit, networking,
  package baru, atau perubahan `project.pbxproj`.
- Build command: XcodeBuildMCP `build_run_sim(launchArgs:
  ["-DemoRole", "admin", "-DemoScenario", "admin_draft_editor",
  "-SkipDemoLanding"])` pada iPhone 17 Pro dan iPad Pro 13-inch, serta
  `build_sim()` pada konfigurasi Release; seluruh command memakai
  `SWIFT_VERSION=6`, `SWIFT_STRICT_CONCURRENCY=complete`, dan
  `IPHONEOS_DEPLOYMENT_TARGET=17.0`.
- Test command: XcodeBuildMCP `test_sim(extraArgs:
  ["-only-testing:MSCBodyTransformationTests/Phase05AdminCMSTests"])`,
  tiga focused XCTest UI untuk publish, People, dan banner, lalu
  `test_sim()` untuk seluruh scheme.
- Result: sembilan test Phase 05 dan tiga journey UI Admin lulus; seluruh 58
  test, build Debug iPhone/iPad, dan build Release lulus tanpa warning.
  Ringkasan Admin diverifikasi pada light mode serta dark mode dengan
  accessibility Dynamic Type terbesar; grid berubah menjadi satu kolom agar
  teks tetap terbaca.
- Remaining blockers: tidak ada blocker lokal. Upload media, backend/RLS,
  scoring server-authoritative, dan autentikasi production tetap ditunda ke
  phase yang ditetapkan.

#### 2026-07-27 — perluasan setting dan konten Program

- Files changed: model draft Admin; validator dan normalisasi jadwal;
  state/editor Program; editor konten langkah dan kuis; presentasi label Admin;
  unit/UI test; inventaris layar, glosarium, serta checklist backend.
- Assumptions: referensi cover dan video tetap lokal pada Track A; pola
  mandiri memakai tanggal acuan untuk demo; akses, kapasitas, serta pertanyaan
  kuis tersimpan di draft Admin dan harus dipetakan secara authoritative oleh
  adapter Phase 11 sebelum produksi.
- Build command: XcodeBuildMCP `build_run_sim` pada iPhone 17 iOS 26.5 dengan
  peran Admin dan skenario `admin_draft_editor`.
- Test command: XcodeBuildMCP `test_sim` untuk
  `Phase05AdminCMSTests` dan UI flow
  `testAdminCreatesDraftAddsDayStepPreviewsAndPublishes`.
- Result: build lulus tanpa warning atau error; 12 unit test Phase 05 dan satu
  UI test alur pembuatan draft sampai publish lulus. Runtime inspection
  mengonfirmasi form dasar, pola/durasi, akses/kapasitas, dan pemilihan konten
  tampil sebagai kontrol native yang sesuai untuk iPhone.
- Remaining blockers: upload cover/video server, approval akses, enforcement
  kapasitas, dan penyimpanan respons kuis tetap ditunda ke Phase 11. Item
  Phase 08 berikutnya tetap profiling scrolling Participant Home.

#### 2026-07-27 — penyederhanaan alur editor Program

- Files changed: ringkasan editor Program; form Info, Jadwal dan peserta,
  serta Aturan dan poin; perencana Konten; editor Hari, Langkah, daftar
  Pertanyaan, dan detail Pertanyaan; state editor; validator hierarki dan ID;
  localization catalog; unit/UI test; README, inventaris layar, glosarium,
  checklist adapter, serta master workplan.
- Assumptions: pertanyaan menjadi anak Langkah dan dapat dipakai oleh Artikel,
  Video, maupun Kuis; Kuis tetap mewajibkan minimal satu pertanyaan.
  Penyimpanan respons peserta dan model backend authoritative tetap ditunda
  ke fase integrasi yang ditetapkan. Tidak ada Supabase, networking, package,
  atau perubahan `project.pbxproj`.
- Build command: XcodeBuildMCP `build_sim(extraArgs:
  ["SWIFT_VERSION=6", "SWIFT_STRICT_CONCURRENCY=complete",
  "IPHONEOS_DEPLOYMENT_TARGET=17.0"])` pada iPhone 17 iOS 26.5.
- Test command: XcodeBuildMCP `test_sim` untuk 18
  `Phase05AdminCMSTests`, seluruh target `MSCBodyTransformationTests`
  (93 test), dan focused UI test
  `testAdminCreatesDraftAddsDayStepPreviewsAndPublishes`.
- Result: build lulus tanpa warning/error; 18 test Phase 05, seluruh 93 unit
  test, dan journey UI draft → Hari → Langkah → pratinjau → publikasi lulus.
  Test juga memverifikasi program 5 hari dengan 15 langkah dan 60 pertanyaan,
  ID unik antarhari, sinkronisasi non-destruktif, serta reorder. Percobaan
  seluruh scheme melewati timeout alat setelah test build karena simulator
  berulang kali melaporkan `DebuggerVersionStore` tanpa versi debugger;
  focused UI test terkait tetap lulus saat dijalankan terpisah.
- Remaining blockers: representasi respons pertanyaan pada Program peserta,
  upload media server, enforcement akses/kapasitas, dan persistence backend
  tetap untuk Phase 11. Item Phase 08 berikutnya tetap profiling scrolling
  Participant Home.
