# Phase 08: Accessibility, Reliability, UI Tests, and Offline Demo

## Tujuan

Menjadikan Track A sebagai prototype native yang stabil, dapat didemokan end-to-end, mudah direview, dan siap menerima backend adapter tanpa perubahan UI besar.

## External dependency status

**Tidak ada external integration.**

Semua test menggunakan mock repositories, fixtures, local media, dan launch arguments.

## Offline demo scenarios

Buat Debug-only scenario launcher:

- [x] Logged out.
- [x] Participant onboarding.
- [x] Participant no program.
- [x] Participant day 1.
- [x] Participant mid-program.
- [x] Participant final weigh-in.
- [x] Participant final leaderboard.
- [x] Coach wallet zero.
- [x] Coach active participants.
- [x] Coach review queue.
- [x] Admin draft CMS.
- [x] Admin active program.
- [x] Admin winner lock.
- [x] Loading.
- [x] Offline.
- [x] Permission denied.
- [x] Generic repository error.

Setiap scenario harus deterministic.

## Bahasa dan localization audit

- [x] Seluruh copy production-facing berbahasa Indonesia.
- [x] Tidak ada English placeholder yang tertinggal.
- [x] Angka, berat, tanggal, waktu, dan harga menggunakan locale `id-ID`.
- [x] Text Bahasa Indonesia tidak terpotong pada Dynamic Type besar.
- [x] Istilah mengikuti `UI_REFERENCE_SHEET.md`.

## Accessibility audit

### Dynamic Type

- [x] Test standard sizes.
- [x] Test largest accessibility sizes.
- [x] No clipped primary action.
- [x] No horizontal text truncation for required content.
- [x] Forms remain navigable.
- [x] Leaderboard remains understandable without compressed columns.

### VoiceOver

- [x] Logical reading order.
- [x] Icon-only button labels.
- [x] Progress value and context.
- [x] Rank value.
- [x] Submission state.
- [x] Locked day explanation.
- [x] Evidence image accessible name.
- [x] Decorative images hidden.
- [x] QR has useful description without exposing token.
- [x] Validation associated with field.

### Visual accessibility

- [x] Light mode.
- [x] Dark mode.
- [x] Increase Contrast.
- [x] Reduce Transparency.
- [x] Differentiate Without Color.
- [x] Minimum target size.
- [x] System colors remain legible.

### Motion

- [x] Reduce Motion disables unnecessary celebration.
- [x] Leaderboard changes do not cause disorienting motion.
- [x] Navigation uses system behavior.
- [x] Loading indicators remain accessible.

## Reliability

- [x] Cancellation-safe async tasks.
- [x] Retry action for recoverable errors.
- [x] Debounce search where needed.
- [x] No duplicate repository loads caused by body recomputation.
- [x] Stable list identity.
- [x] No unbounded image memory.
- [x] Local temporary files cleaned.
- [x] Debug fixture reset works.
- [x] App survives background/foreground.
- [x] Fake session restoration.

## Performance

- [x] Use lazy containers.
- [x] Thumbnail instead of original image in lists.
- [x] Avoid expensive work on main actor.
- [ ] Profile participant Home scrolling.
- [ ] Profile coach participant list.
- [ ] Profile admin day/step editor.
- [ ] Profile Liquid Glass candidates on iOS 26 runtime.
- [x] Remove glass where it causes avoidable performance cost.

## Swift Testing completion

Required suites:

- [x] Domain models.
- [x] Fixture decoding.
- [x] Validation.
- [x] Scoring.
- [x] Ranking.
- [x] Timezone and visibility.
- [x] Participant feature states.
- [x] Coach feature states.
- [x] Admin editor.
- [x] QR parser.
- [x] Media decisions.
- [x] Role navigation.
- [x] Error mapping.

## XCTest UI flows

- [x] Participant full local flow.
- [x] Coach review flow.
- [x] Coach invite generation.
- [x] Admin draft creation.
- [x] Admin participant preview.
- [x] Admin manual enrollment local simulation.
- [x] Leaderboard and winner display.
- [x] Role switch test.
- [x] Dark mode launch.
- [x] Accessibility size launch.

Use launch arguments untuk fixture scenario, jangan menulis test yang bergantung pada test sebelumnya.

## Device matrix

- [ ] Small supported iPhone simulator iOS 17.
- [x] Standard current simulator.
- [x] iOS 26 simulator untuk Liquid Glass.
- [x] iPad simulator.
- [ ] Physical device untuk camera and scanning sanity.
- [x] Offline mode.

## Track A demo checklist

Participant:

- [x] Join local program.
- [x] Submit initial weight.
- [x] Complete step with local photo.
- [x] See points and progress.
- [x] Submit final weight.
- [x] See final rank.

Coach:

- [x] View dashboard.
- [x] View participant.
- [x] Review evidence.
- [x] Generate QR.
- [x] Open store preview.

Admin:

- [x] Create program draft.
- [x] Add days and steps.
- [x] Preview participant UI.
- [x] Simulate publish.
- [x] Manual enroll.
- [x] Lock winners.
- [x] Add winner banner.

## Documentation deliverables

- [x] `DEMO_GUIDE.md`.
- [x] `ARCHITECTURE.md`.
- [x] `DOMAIN_GLOSSARY.md`.
- [x] `MOCK_DATA_GUIDE.md`.
- [x] `UI_SCREEN_INVENTORY.md`.
- [x] `BACKEND_ADAPTER_CHECKLIST.md`.
- [x] Screenshots optional, but no snapshot test dependency required.

## Exit criteria

- [x] Semua Track A flows dapat digunakan tanpa jaringan.
- [x] No critical accessibility blockers.
- [x] Critical UI tests lulus.
- [x] Unit tests lulus.
- [x] No Supabase dependency.
- [x] No OAuth configuration.
- [x] No live StoreKit transaction.
- [x] UI siap menerima real repository adapters.

## Progress log

### Log

#### 2026-07-26 — implementasi dan verifikasi lokal

- Files changed: katalog dan launcher skenario Debug, persiapan state per peran,
  reset progres hari pertama, audit copy/lokalisasi, UI test aksesibilitas dan
  reliabilitas, test Phase 08, README, serta enam dokumen handoff di root.
- Assumptions: pencarian fixture kecil tidak memerlukan debounce; ETTrace tidak
  ditautkan karena project melarang perubahan `project.pbxproj`.
- Build command: XcodeBuildMCP `build_sim` dengan Swift 6 strict concurrency
  pada iPhone 17 Pro Debug/Release, iPhone 17e iOS 26.5, dan iPad Pro 13-inch
  iOS 26.5.
- Test command: XcodeBuildMCP `test_sim` untuk seluruh
  `MSCBodyTransformationTests` dan seluruh 15 UI test dalam tiga kelompok.
- Result: 83 unit test dan 15 UI test lulus; Debug, Release, small iPhone, dan
  iPad build lulus tanpa compiler error.
- Remaining blockers: runtime iOS 17 dan perangkat fisik tidak tersedia.
  Profil ETTrace memerlukan temporary framework linking ke app target, yang
  tidak dilakukan karena perubahan Xcode project dilarang.

#### 2026-07-27 — migrasi interpolasi SwiftUI Text

- Files changed: enam view Coach dan Participant yang sebelumnya menggabungkan
  `Text` dengan operator `+`.
- Assumptions: susunan dan style teks tetap sama; fragmen localization key dan
  angka berformat diinterpolasikan sebagai `Text` agar tetap lokalizable.
- Build command: XcodeBuildMCP `build_sim` untuk scheme
  `MSCBodyTransformation`, konfigurasi Debug, pada iPhone 17 Pro iOS 26.5.
- Test command: XcodeBuildMCP `test_sim` dengan
  `-only-testing:MSCBodyTransformationTests/Phase08AccessibilityReliabilityTests`.
- Result: build lulus tanpa warning atau error; 7 test Phase 08 lulus.
- Remaining blockers: tidak ada untuk migrasi ini. Item berikutnya yang belum
  dicentang adalah profiling scrolling Participant Home (pengganti Today).

#### 2026-07-27 — redesain Participant Home

- Files changed: `ParticipantTodayView.swift` diganti dengan
  `ParticipantHomeView.swift`; tab dan destination shell Participant; detail
  program; state onboarding demo; katalog lokalisasi; serta UI test Participant.
- Assumptions: poster program dibuat native SwiftUI dalam rasio 16:9 karena
  aset poster final belum tersedia; Fokus hari ini menampilkan satu kartu per
  enrollment aktif dan siap menjadi carousel saat fixture memiliki lebih dari
  satu program aktif.
- Build command: XcodeBuildMCP `build_run_sim` untuk scheme
  `MSCBodyTransformation`, konfigurasi Debug, pada iPhone 17 Pro iOS 26.5
  dengan skenario `participant_active`.
- Test command: XcodeBuildMCP `test_sim` untuk
  `Phase03ParticipantTests`, `Phase08AccessibilityReliabilityTests`, dan
  `MSCBodyTransformationUITests/testParticipantCompletesLocalJourneySlice`.
- Result: build lulus tanpa warning atau error; 15 unit test terfokus dan satu
  UI test alur Participant lengkap lulus. Runtime snapshot mengonfirmasi profil
  berlabel `MSC Peserta`, carousel Program, Fokus hari ini, dan Leaderboard.
- Remaining blockers: profiling scrolling Home belum dicentang. Template
  SwiftUI Instruments tidak didukung simulator; Time Profiler dapat attach dan
  merekam scroll, tetapi macet saat finalisasi sehingga trace tidak valid.
  Integrasi ETTrace juga memerlukan linking framework sementara ke app target,
  sedangkan perubahan `project.pbxproj` dilarang. Item berikutnya tetap
  profiling scrolling Participant Home.

#### 2026-07-27 — penyempurnaan carousel dan Leaderboard Home

- Files changed: `ParticipantHomeView.swift`.
- Assumptions: satu item carousel memakai seluruh lebar konten; dua item atau
  lebih tetap memperlihatkan sebagian kartu berikutnya sebagai petunjuk swipe.
- Build command: XcodeBuildMCP `build_run_sim` untuk scheme
  `MSCBodyTransformation`, konfigurasi Debug, pada iPhone 17 Pro iOS 26.5
  dengan skenario `participant_active`.
- Test command: XcodeBuildMCP `test_sim` dengan
  `-only-testing:MSCBodyTransformationUITests/MSCBodyTransformationUITests/testParticipantShellOpensAllTabs`.
- Result: build lulus tanpa warning atau error dan satu UI test lulus. Runtime
  screenshot mengonfirmasi kartu Fokus tunggal memenuhi lebar konten serta
  avatar, nomor peringkat, dan nama Leaderboard sejajar; crown juara 1 menjadi
  overlay dan tidak memengaruhi layout.
- Remaining blockers: tidak ada untuk penyempurnaan layout ini. Item berikutnya
  tetap profiling scrolling Participant Home.

#### 2026-07-27 — konsistensi warna brand dark mode

- Files changed: dark variants `BrandPrimary`, `BrandPrimaryPressed`, dan
  `BrandAccent`; empat color set poster program; `ParticipantHomeView.swift`;
  serta `UI_REFERENCE_SHEET.md`.
- Assumptions: warna identitas merah dan gold harus tetap sama kuat pada light
  dan dark mode; hanya background, surface, border, text, dan status semantic
  yang tetap menyesuaikan appearance.
- Build command: XcodeBuildMCP `build_run_sim` untuk scheme
  `MSCBodyTransformation`, konfigurasi Debug, pada iPhone 17 iOS 26.5 dalam
  dark mode dengan skenario `participant_active`.
- Test command: XcodeBuildMCP `test_sim` dengan
  `-only-testing:MSCBodyTransformationUITests/MSCBodyTransformationUITests/testDarkModeFinalLeaderboardLaunch`.
- Result: build lulus tanpa warning atau error dan satu UI test dark mode lulus.
  Runtime screenshot mengonfirmasi avatar, CTA, tab aktif, poster, dan gold
  Leaderboard tetap tegas tanpa gradient coral/pastel.
- Remaining blockers: tidak ada untuk konsistensi warna ini. Item berikutnya
  tetap profiling scrolling Participant Home.

#### 2026-07-27 — katalog Program Participant

- Files changed: katalog dan poster Program Participant; root dan destination
  navigation tab; detail Program; model durasi Program; katalog lokalisasi;
  navigation test; serta UI test alur katalog ke detail.
- Assumptions: filter `Aktif` memuat program aktif dan terjadwal, filter
  `Riwayat` memuat program selesai dan diarsipkan, sedangkan draft tidak
  ditampilkan kepada Participant. Poster lokal menggunakan native SwiftUI
  dengan rasio 16:9 sampai aset poster final tersedia.
- Build command: XcodeBuildMCP `build_run_sim` untuk scheme
  `MSCBodyTransformation`, konfigurasi Debug, pada iPhone 17 iOS 26.5 dengan
  skenario `participant_active`.
- Test command: XcodeBuildMCP `test_sim` dengan
  `-only-testing:MSCBodyTransformationTests/Phase02NavigationTests` dan
  `-only-testing:MSCBodyTransformationUITests/MSCBodyTransformationUITests/testParticipantSelectsProgramBeforeOpeningDetail`.
- Result: build lulus tanpa warning atau error; 5 navigation test dan satu UI
  test lulus. Runtime snapshot mengonfirmasi filter Aktif/Riwayat, durasi tujuh
  hari, dan pemilihan poster membuka detail di navigation stack tab Program.
- Remaining blockers: tidak ada untuk katalog Program. Item berikutnya tetap
  profiling scrolling Participant Home.

#### 2026-07-27 — penyederhanaan header katalog Program

- Files changed: `ParticipantProgramCatalogView.swift` dan
  `Localizable.xcstrings`.
- Assumptions: navigation title `Program` dan filter Aktif/Riwayat sudah cukup
  menjelaskan konteks sehingga section title dan subtitle tidak diperlukan.
- Build command: XcodeBuildMCP `build_run_sim` untuk scheme
  `MSCBodyTransformation`, konfigurasi Debug, pada iPhone 17 iOS 26.5 dengan
  skenario `participant_active`.
- Test command: XcodeBuildMCP `test_sim` dengan
  `-only-testing:MSCBodyTransformationUITests/MSCBodyTransformationUITests/testParticipantSelectsProgramBeforeOpeningDetail`.
- Result: build lulus tanpa warning atau error dan satu UI test lulus. Runtime
  screenshot mengonfirmasi poster langsung tampil setelah filter.
- Remaining blockers: tidak ada. Item berikutnya tetap profiling scrolling
  Participant Home.

#### 2026-07-27 — ukuran filter katalog Program

- Files changed: `ParticipantProgramCatalogView.swift`.
- Assumptions: segmented control tetap memakai `Picker` native SwiftUI dengan
  label headline dan tinggi sentuh minimum 44 poin; jarak ke poster memakai
  token spacing 16 poin.
- Build command: XcodeBuildMCP `build_run_sim` untuk scheme
  `MSCBodyTransformation`, konfigurasi Debug, pada iPhone 17 iOS 26.5 dengan
  skenario `participant_active`.
- Test command: XcodeBuildMCP `test_sim` dengan
  `-only-testing:MSCBodyTransformationUITests/MSCBodyTransformationUITests/testParticipantSelectsProgramBeforeOpeningDetail`.
- Result: build lulus tanpa warning atau error dan satu UI test lulus. Runtime
  screenshot mengonfirmasi control lebih tinggi dan poster tidak menempel.
- Remaining blockers: tidak ada. Item berikutnya tetap profiling scrolling
  Participant Home.

#### 2026-07-27 — katalog berdasarkan enrollment dan alur Gabung

- Files changed: katalog dan halaman Gabung Program Participant; route dan
  destination navigation; store Participant; model, protocol, use case, dan
  mock repository pratinjau undangan; katalog lokalisasi; Phase 06 unit test;
  serta UI test katalog Program.
- Assumptions: tab Program hanya menampilkan program yang memiliki enrollment
  milik Participant. Pemindaian QR, input kode, pratinjau undangan, dan
  konfirmasi lokal memakai fondasi Phase 06; validasi authoritative oleh server
  dan Universal Link tetap ditunda ke Phase 11 dan fase backend terkait.
- Build command: XcodeBuildMCP `build_run_sim` untuk scheme
  `MSCBodyTransformation`, konfigurasi Debug, pada iPhone 17 iOS 26.5 dengan
  skenario `participant_active`.
- Test command: XcodeBuildMCP `test_sim` dengan
  `-only-testing:MSCBodyTransformationTests/Phase06NativeMediaTests` dan
  `-only-testing:MSCBodyTransformationUITests/MSCBodyTransformationUITests/testParticipantSelectsProgramBeforeOpeningDetail`.
- Result: build lulus tanpa warning atau error; 11 unit test dan satu UI test
  lulus. Runtime snapshot mengonfirmasi tab Aktif hanya menampilkan program
  terdaftar, tab Riwayat menampilkan enrollment selesai, serta tombol Gabung
  membuka alur QR/kode dan pratinjau program native SwiftUI.
- Remaining blockers: pemindaian kamera fisik belum diverifikasi pada device;
  konfigurasi Universal Link dan redemption server ditunda. Item Phase 08
  berikutnya tetap profiling scrolling Participant Home.

#### 2026-07-27 — header tetap dan overlay pemindai QR

- Files changed: `ParticipantProgramCatalogView.swift`,
  `NativeQRScannerView.swift`, konfigurasi Info.plist generated pada
  `project.pbxproj`, dan UI test katalog Program.
- Assumptions: judul Program, tombol Gabung, dan segmented control tetap di
  luar area scroll; hanya daftar poster yang dapat digulir. Kamera memakai
  VisionKit dengan fallback AVFoundation dan overlay frame/scan line native
  SwiftUI yang menghormati Reduce Motion.
- Build command: XcodeBuildMCP `build_run_sim` untuk scheme
  `MSCBodyTransformation`, konfigurasi Debug, pada iPhone 17 iOS 26.5 dengan
  skenario `participant_active`.
- Test command: XcodeBuildMCP `test_sim` untuk
  `Phase06NativeMediaTests` serta
  `MSCBodyTransformationUITests/testParticipantSelectsProgramBeforeOpeningDetail`.
- Result: build lulus tanpa warning atau error; 11 unit test dan satu UI test
  lulus. Runtime screenshot mengonfirmasi tombol Gabung sejajar dengan judul
  Program dan hanya daftar poster yang menjadi scroll view.
- Remaining blockers: pemindaian fisik tetap perlu diverifikasi pada iPhone.
  Generated Info.plist Debug sudah diverifikasi memuat deskripsi penggunaan
  kamera; konfigurasi yang sama juga dipasang pada Release. Item Phase 08
  berikutnya tetap profiling scrolling Participant Home.
