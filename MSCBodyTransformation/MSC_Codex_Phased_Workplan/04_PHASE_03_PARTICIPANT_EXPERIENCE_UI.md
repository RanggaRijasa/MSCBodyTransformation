# Phase 03: Participant Experience UI

> Status: arsip baseline Phase 03. Alur aktif adalah katalog publik → pindai
> QR Coach → pembayaran bila perlu → enrollment, dengan satu Coach aktif dan
> beberapa program per Peserta. Lihat workplan remediation dan matriks
> kontrak; invite program, timbang onboarding, dan snapshot satu program tidak
> lagi berlaku.

## Tujuan

Membangun seluruh participant journey dengan in-memory repository dan local fixtures. Pada akhir phase, participant dapat menjalankan sample program dari awal sampai selesai tanpa backend.

## External dependency status

**Lokal sepenuhnya.**

Authentication menggunakan fake session. Evidence disimpan sebagai local demo reference. Program dan leaderboard berasal dari mock repositories.

## Keputusan produk 2026-07-28

- Segment Aktif menampilkan semua program aktif dan terjadwal.
- Setiap card memberi status `Diikuti` atau `Belum mendaftar`.
- Program yang belum diikuti membuka detail deskripsi, durasi, harga, dan CTA.
- CTA mengarahkan peserta ke scan QR unik coach, konfirmasi coach, lalu
  placeholder pembayaran Apple.
- Pembayaran StoreKit nyata tetap ditunda ke Phase 12.
- Detail program yang sudah diikuti menjadi layar eksekusi: header progres
  ringkas diikuti accordion hari dan langkah. Deskripsi panjang, aturan poin,
  serta profil coach tidak mendominasi layar aktivitas.

## Screen inventory

### Entry dan onboarding

- [x] Local demo login screen.
- [x] Participant profile completion.
- [x] Privacy and wellness disclaimer screen.
- [x] Pending invite preview.
- [x] Join confirmation.
- [x] Initial weigh-in prompt.

### Today

- [x] Current program header.
- [x] Current day information.
- [x] Progress summary.
- [x] Initial/final weight callout.
- [x] Required step list.
- [x] Completed, pending, rejected, missing, dan locked states.
- [x] Empty state ketika tidak ada active enrollment.
- [x] All-complete celebration yang menghormati Reduce Motion.

### Program

- [x] Program overview.
- [x] Dates dan duration.
- [x] Assigned coach.
- [x] Rules and scoring summary.
- [x] Day timeline.
- [x] Past day state.
- [x] Current day state.
- [x] Future hidden state.
- [x] Future locked but visible state.
- [x] Overall progress.

### Step detail

- [x] Title dan points.
- [x] Instruction body.
- [x] Image instruction.
- [x] Local video placeholder atau bundled sample video.
- [x] Required items checklist.
- [x] Required text answer.
- [x] Evidence section.
- [x] Upload or replace photo action.
- [x] Complete step button.
- [x] Validation message.
- [x] Submission status.
- [x] Rejection reason.
- [x] Retry state.

### Weigh-in

- [x] Initial weigh-in form.
- [x] Final weigh-in form.
- [x] Decimal input.
- [x] Unit display kg.
- [x] Optional evidence photo UI bila product decision mengaktifkannya.
- [x] Window closed state.
- [x] Confirmation before submit.
- [x] Weight data privacy explanation.

### Leaderboard

- [x] Current user rank card.
- [x] Top five emphasized.
- [x] Full ranking.
- [x] Step points.
- [x] Weight points.
- [x] Total points.
- [x] Tie state presentation.
- [x] Provisional label.
- [x] Final locked label.
- [x] Winner banner from local managed content.

### Coaches

- [x] Coach directory.
- [x] Coach profile detail.
- [x] Assigned coach emphasis.
- [x] Accessible photo and bio.

### Profile

- [x] User information.
- [x] Editable profile photo, display name, and phone number.
- [x] Assigned coach display and QR-only coach change flow.
- [x] Current and previous enrollments remain in the Program tab.
- [x] App settings.
- [x] Privacy and terms placeholders.
- [x] Logout local demo.
- [x] Delete-account informational placeholder, no live deletion.

## Local participant workflow

Implement state changes against `InMemory...Repository`:

1. Participant enters a valid local invite.
2. Participant confirms join.
3. Enrollment appears.
4. Initial weight is submitted.
5. Today steps become available.
6. Participant attaches local image.
7. Participant completes a step.
8. Progress and local score update.
9. Participant continues to final day using Debug date override.
10. Participant submits final weight.
11. Leaderboard recalculates locally.

## Debug tools

- [x] Program date override.
- [x] Current day selector.
- [x] Reset demo participant.
- [x] Mark all previous days complete.
- [x] Simulate rejected submission.
- [x] Simulate offline.
- [x] Simulate repository error.
- [x] Simulate final program state.

Debug tools must not compile into Release.

## State architecture

Setiap feature harus memiliki:

- Focused screen state.
- Explicit loading, loaded, empty, error states.
- Async actions.
- Cancellation-safe `.task`.
- Repository injected via initializer atau environment.
- No business logic in view body.
- No giant participant view model for every tab.

## Validation

- [x] Evidence required sebelum completion.
- [x] Text answer required when configured.
- [x] Cannot complete locked step.
- [x] Duplicate completion idempotent.
- [x] Weight range validation.
- [x] Decimal separator works untuk Indonesian locale.
- [x] Final weight not accepted before allowed local window.
- [x] Error message associated with relevant field.

## Previews

Buat preview untuk:

- [x] Today loading.
- [x] Today active with partial completion.
- [x] Today complete.
- [x] No enrollment.
- [x] Step missing evidence.
- [x] Step pending review.
- [x] Step rejected.
- [x] Timeline with hidden days.
- [x] Leaderboard current user outside top five.
- [x] Leaderboard final winners.
- [x] Largest Dynamic Type.
- [x] Dark mode.

## Tests

### Swift Testing

- [x] Today state mapping.
- [x] Step validation.
- [x] Weigh-in validation.
- [x] Progress calculation.
- [x] Locked step behavior.
- [x] Local participant completion.
- [x] Final weight flow.
- [x] Error mapping.

### UI tests

- [x] Launch as participant.
- [x] Join sample program.
- [x] Submit initial weight.
- [x] Select bundled/local test image.
- [x] Complete one step.
- [x] Verify progress changes.
- [x] Open leaderboard.
- [x] Navigate coach directory.

## Larangan scope

Jangan:

- Menghubungkan kamera production bila native wrapper belum dibuat pada Phase 06.
- Mengunggah file ke network.
- Mengimplementasikan Google login.
- Mengimplementasikan database authorization.
- Menganggap local score sebagai final server truth.
- Menambahkan HealthKit.

## Exit criteria

- [x] Participant journey dapat didemokan tanpa internet.
- [x] Semua primary screens memiliki meaningful mock states.
- [x] Required evidence mencegah premature completion.
- [x] Progress dan local leaderboard berubah setelah action.
- [x] Dynamic Type dan VoiceOver baseline terpenuhi.
- [x] Test lulus dan clean build.

## Progress log

### Log

#### 2026-07-29 — Avatar kosong diseragamkan systemwide

- Files changed: shared avatar, UI test Profil peserta, coding guidelines, UI
  reference, dan progress log Phase 03.
- Assumptions: foto asli tetap ditampilkan jika tersedia; hanya fallback
  tanpa foto yang berubah dari inisial menjadi ikon orang kosong native.
- Build command: XcodeBuildMCP `build_run_sim` pada iPhone 17 iOS 26.5.
- Test command: XcodeBuildMCP `test_sim` untuk focused UI test
  `testParticipantHomeProfileCardSelectsProfileTab`.
- Result: fallback pada peserta, coach, leaderboard, dan Admin menggunakan
  satu `UserAvatar` netral; inisial tidak lagi muncul sebagai foto default.
- Remaining blockers: tidak ada.

#### 2026-07-29 — Aksi media demo dihapus dari layar upload

- Files changed: CTA Profil peserta, editor foto profil, bukti langkah,
  timbang berat, profil coach, editor poster Admin, pipeline media lokal,
  lokalisasi, coding guidelines, UI reference, focused UI tests, dan progress
  log.
- Assumptions: fixture poster lokal tetap dipakai untuk mengisi Home selama
  fase offline, tetapi tidak dapat dipilih dari layar upload. Area yang belum
  mempunyai upload native tidak menampilkan tombol palsu.
- Build command: XcodeBuildMCP `build_run_sim` pada iPhone 17 iOS 26.5.
- Test command: XcodeBuildMCP `test_sim` untuk Phase 03–06 serta focused UI
  test `testParticipantEditsProfileAndChangesCoachByQR` dan
  `testAdminPosterEditorRequiresPhotoSelection`.
- Result: build lulus tanpa warning; 51/51 focused test dan 2/2 UI test
  lulus. Tombol Edit profil kini berupa teks murni dan seluruh pembuat media
  demo sudah tidak tersedia dari UI.
- Remaining blockers: upload media remote tetap ditunda ke fase adapter
  Supabase.

#### 2026-07-29 — Profil peserta dapat diedit dan coach diganti via QR

- Files changed: model dan fixture profil peserta, repository enrollment mock,
  journey store, shared avatar dan pipeline media, QR scanner lokal, tampilan
  profil, editor profil, Home avatar, lokalisasi, focused tests, UI reference,
  dan progress log Phase 03.
- Assumptions: foto profil disimpan sebagai referensi media lokal selama fase
  offline; email akun dan kota tetap read-only; pergantian coach memperbarui
  enrollment pending/aktif lokal dan hanya dapat dimulai dari hasil scan QR.
- Build command: XcodeBuildMCP `build_run_sim` pada iPhone 17 iOS 26.5 dengan
  skenario `participant_active`.
- Test command: XcodeBuildMCP `test_sim` untuk
  `Phase03ParticipantTests`,
  `testParticipantEditsProfileAndChangesCoachByQR`, dan
  `testParticipantHomeProfileCardSelectsProfileTab`.
- Result: build lulus tanpa warning; 13/13 test Phase 03 dan 2/2 focused UI
  test lulus. Edit nama, nomor HP, pemilih Foto native, dan pergantian coach
  dari QR hingga konfirmasi terverifikasi.
- Remaining blockers: penyimpanan media remote dan sinkronisasi profil/coach
  ke Supabase tetap ditunda ke fase backend yang sudah ditentukan.

#### 2026-07-29 — Katalog Program dipisah menjadi tiga segment

- Files changed: filter katalog Program peserta, localization catalog,
  focused UI test, UI reference, dan progress log Phase 03.
- Assumptions: `Diikuti` mencakup enrollment pending atau aktif pada program
  aktif/terjadwal; `Tersedia` hanya menampilkan program aktif/terjadwal tanpa
  enrollment berjalan; `Riwayat` hanya berisi program yang pernah diikuti
  dan sudah selesai atau diarsipkan.
- Build command: XcodeBuildMCP `build_run_sim` pada iPhone 17 iOS 26.5.
- Test command: XcodeBuildMCP `test_sim` untuk focused UI test
  `testParticipantSelectsProgramBeforeOpeningDetail`.
- Result: ketiga segment menampilkan kelompok program yang berbeda dan alur
  membuka penawaran program dari `Tersedia` tetap berfungsi.
- Remaining blockers: tidak ada.

#### 2026-07-29 — Leaderboard Top 5 menjadi section ketiga di Home

- Files changed: komposisi Home peserta, localization catalog, UI test,
  UI reference, dan progress log Phase 03.
- Assumptions: kartu profil merupakan header; urutan section konten dihitung
  mulai dari Program, lalu Fokus, kemudian Leaderboard Top 5.
- Build command: XcodeBuildMCP `build_run_sim` pada iPhone 17 Pro iOS 26.5.
- Test command: XcodeBuildMCP `test_sim` untuk focused UI test
  `testParticipantHomeShowsWinnersAndCoachDiscovery`.
- Result: leaderboard tampil sebelum poster pemenang sebagai section konten
  ketiga dan judulnya menjadi `Leaderboard Top 5`.
- Remaining blockers: tidak ada.

#### 2026-07-29 — Poster pemenang menjadi gambar noninteraktif

- Files changed: snapshot Home peserta, renderer poster shared, komposisi
  carousel, dua aset poster fixture 9:16, unit test, UI test, dan UI
  reference.
- Assumptions: maksimal dua `winnerBanner` aktif dengan referensi media
  ditampilkan berdasarkan `sortOrder`; semua informasi visual sudah menjadi
  bagian dari file poster dan tidak dibentuk ulang oleh View.
- Build command: XcodeBuildMCP `build_run_sim` pada iPhone 17 Pro iOS 26.5.
- Test command: XcodeBuildMCP `test_sim` untuk seluruh
  `MSCBodyTransformationTests` serta UI test
  `testParticipantHomeShowsWinnersAndCoachDiscovery`.
- Result: build lulus tanpa warning; 100/100 unit test lulus dan UI test
  memastikan dua poster tampil sebagai image, bukan button.
- Remaining blockers: file poster production menunggu adapter media/storage;
  kontrak UI dan referensi file lokal sudah siap.

#### 2026-07-29 — Sorotan dua pemenang dan direktori coach di Home

- Files changed: snapshot Home peserta, komponen poster pemenang dan avatar
  coach, komposisi Home, lokalisasi, unit test, UI test, dan UI reference.
- Assumptions: Home menampilkan dua peringkat teratas dari program selesai
  terbaru yang dipublikasikan; direktori menampilkan semua coach publik yang
  disetujui dan mengurutkan coach peserta lebih dahulu. Fixture lokal belum
  memiliki aset foto coach, sehingga `UserAvatar` menampilkan inisial sampai
  adapter media memasok nama aset atau referensi gambar.
- Build command: XcodeBuildMCP `build_run_sim` dan `build_sim` pada iPhone
  17 Pro iOS 26.5.
- Test command: XcodeBuildMCP `test_sim` untuk seluruh
  `MSCBodyTransformationTests` dan UI test
  `testParticipantHomeShowsWinnersAndCoachDiscovery`.
- Result: build lulus tanpa warning; 100/100 unit test dan 1/1 UI test lulus.
  Inspeksi runtime light mode serta dark mode dengan ukuran teks
  aksesibilitas terbesar memastikan dua poster 9:16, petunjuk swipe, avatar
  lingkaran, badge `Coach-mu`, dan navigasi direktori tetap terbaca.
- Remaining blockers: tidak ada blocker UI. Foto coach nyata tetap menunggu
  sumber media pada fase adapter; crop lingkaran sudah ditangani oleh
  komponen `UserAvatar` tanpa kebutuhan background transparan.

#### 2026-07-28 — Audit akses aktivitas sebelum adapter Supabase

- Files changed: fixture program aktif, kontrak presentasi akses hari,
  accordion aktivitas, unit test, UI test, UI reference, dan checklist
  adapter backend.
- Assumptions: langkah yang sudah dipublikasikan dapat dikerjakan sejak
  tanggalnya tiba, termasuk pada hari lampau; read-only hanya berasal dari
  visibility mode eksplisit; hari mendatang dan konten hidden tidak
  menampilkan langkah.
- Build command: XcodeBuildMCP `build_sim` pada iPhone 17 Pro iOS 26.5.
- Test command: XcodeBuildMCP `test_sim` untuk seluruh
  `MSCBodyTransformationTests` dan UI test
  `testParticipantSelectsProgramBeforeOpeningDetail`.
- Result: build lulus tanpa warning; 99/99 unit test dan 1/1 UI test lulus.
  UI test membuktikan 27 Juli menampilkan langkah yang dapat dikerjakan, 28
  Juli menjadi hari aktif, dan 29 Juli menampilkan status belum tersedia.
- Remaining blockers: tidak ada blocker UI untuk kontrak akses ini; adapter
  Supabase tetap harus mempertahankan tanggal, timezone, dan visibility mode
  tanpa menebak status dari sisi View.

#### 2026-07-28 — Hari fokus mengikuti tanggal program

- Files changed: skenario peserta aktif, perhitungan hari fokus, accordion
  aktivitas, fixture judul hari, lokalisasi, UI reference, UI test, dan
  progress log Phase 03.
- Assumptions: tanggal aktif berasal dari injected clock/debug override dan
  dibandingkan dalam timezone program; hari tersembunyi tetap tidak
  menampilkan langkahnya.
- Build command: XcodeBuildMCP `build_sim` dan `build_run_sim` pada iPhone 17
  Pro iOS 26.5 dengan skenario `participant_active`.
- Test command: XcodeBuildMCP `test_sim` untuk Phase 03, Phase 08, dan
  `testParticipantSelectsProgramBeforeOpeningDetail`.
- Result: build/run lulus tanpa warning; 16 focused test dan UI test lulus;
  28 Juli otomatis membuka serta menyorot hari ke-5, memberi label `Hari
  ini`, dan menggulir layar ke aktivitas tersebut. Hari locked dan hidden
  sama-sama menampilkan `Aktivitas belum tersedia.`
- Remaining blockers: tidak ada blocker untuk perubahan ini.

#### 2026-07-28 — Detail program berfokus pada aktivitas

- Files changed: router view program peserta, layar aktivitas program,
  accordion hari, baris langkah, lokalisasi, UI reference, UI test, dan
  progress log Phase 03.
- Assumptions: detail penawaran program yang belum diikuti tetap terpisah;
  program yang sudah diikuti menampilkan progres ringkas dan membuka hari
  paling relevan secara default.
- Build command: XcodeBuildMCP `build_sim` dan `build_run_sim` pada iPhone 17
  Pro iOS 26.5.
- Test command: XcodeBuildMCP `test_sim` untuk
  `MSCBodyTransformationTests/Phase03ParticipantTests` dan UI test
  `testParticipantSelectsProgramBeforeOpeningDetail`.
- Result: build/run lulus tanpa warning; 9/9 test Phase 03 dan 1/1 UI test
  lulus; inspeksi runtime memastikan aturan, poin, dan profil coach tidak lagi
  mendahului daftar aktivitas.
- Remaining blockers: tidak ada blocker untuk perubahan layout ini.

#### 2026-07-28 — Enrollment peserta hanya melalui QR coach

- Files changed: alur gabung peserta, entry flow dan journey store, route dan
  sheet app shell, tampilan QR coach, lokalisasi, UI test, README, serta
  coding guidelines `AGENTS.md`.
- Assumptions: identifier coach tetap menjadi payload internal QR untuk
  pencocokan lokal, tetapi tidak ditampilkan, disalin, diketik, atau diterima
  melalui jalur kode manual.
- Build command: XcodeBuildMCP `build_sim` pada iPhone 17 Pro iOS 26.5.
- Test command: XcodeBuildMCP `test_sim` untuk Phase 02, Phase 03, dan Phase
  06; serta UI test
  `testParticipantSelectsProgramBeforeOpeningDetail` dan
  `testCoachCompletesCriticalLocalJourney`.
- Result: input dan fallback kode manual dihapus; route kode lama dihapus;
  build lulus tanpa warning; 24/24 focused test dan 2/2 UI test lulus.
- Remaining blockers: pembayaran StoreKit dan verifikasi enrollment server
  tetap ditunda ke fase yang sudah ditentukan.

#### 2026-07-28 — Hapus deprecation `Text + Text` iOS 26

- Files changed: detail penawaran program, coding guidelines `AGENTS.md`, dan
  progress log Phase 03.
- Assumptions: label durasi dan jumlah langkah tetap memakai localization key
  serta `FormatStyle` Indonesia melalui localized interpolation pada satu
  `Text`.
- Build command: XcodeBuildMCP `build_sim` pada iPhone 17 Pro iOS 26.5 dengan
  Swift 6 strict concurrency dan deployment target iOS 17.
- Test command: XcodeBuildMCP `test_sim` untuk
  `MSCBodyTransformationUITests/MSCBodyTransformationUITests/
  testParticipantSelectsProgramBeforeOpeningDetail`.
- Result: empat warning deprecation hilang; tidak ada pola `Text + Text` lain
  di source Swift; build diagnostics bersih dan 1/1 UI test lulus.
- Remaining blockers: tidak ada blocker untuk perubahan ini.

#### 2026-07-28 — Katalog publik dan alur gabung melalui QR coach

- Files changed: katalog dan poster program, detail penawaran program, alur
  scan/konfirmasi/pembayaran placeholder, journey store, model harga,
  identifier coach, fixture, lokalisasi, serta test peserta.
- Assumptions: program berstatus aktif atau terjadwal tampil pada segment
  Aktif; placeholder pembayaran menyelesaikan enrollment demo lokal tanpa
  prompt App Store.
- Build command: XcodeBuildMCP `build_run_sim(launchArgs:
  ["-DemoRole", "participant", "-DemoScenario", "participant_day_1",
  "-SkipDemoLanding"])`.
- Test command: XcodeBuildMCP `test_sim(extraArgs:
  ["-only-testing:MSCBodyTransformationTests"])` serta UI test fokus
  `testParticipantCompletesLocalJourneySlice`.
- Result: build simulator lulus tanpa warning; 97 unit/integration test dan UI
  test fokus lulus; alur peserta diverifikasi dari card `Belum mendaftar`
  sampai enrollment.
- Remaining blockers: StoreKit dan verifikasi pembayaran server tetap ditunda
  ke Phase 12.

#### 2026-07-26 — Phase 03 selesai

- Files changed: participant journey store dan focused screen state; entry,
  onboarding, Today, Program, step detail, weigh-in, leaderboard, coach
  directory/detail, profile, dan Debug tools; repository mock untuk reset,
  retry, progres, poin langkah, dan poin berat; fixture riwayat enrollment;
  localization; Swift Testing dan XCTest UI.
- Assumptions: evidence memakai referensi foto contoh lokal dan video memakai
  placeholder bundled karena camera/photo integration baru dikerjakan pada
  Phase 06. Poin ditandai jelas sebagai demo lokal, bukan hasil terverifikasi
  server. Build tetap memakai override Swift 6, strict concurrency, dan
  deployment target iOS 17 karena `project.pbxproj` tidak termasuk scope.
- Build command: XcodeBuildMCP
  `build_run_sim(launchArgs: ["-DemoRole", "participant", "-DemoScenario", "participant_active", "-SkipDemoLanding"])`
  pada iPhone 17 Pro dan iPad Pro 13-inch; Release diverifikasi dengan
  `build_sim()`.
- Test command: XcodeBuildMCP
  `test_sim(extraArgs: ["-only-testing:MSCBodyTransformationTests"])` dan
  `test_sim(extraArgs: ["-only-testing:MSCBodyTransformationUITests"])`.
- Result: Debug build iPhone/iPad serta Release build lulus tanpa warning;
  31 unit/integration tests lulus; 4 UI test methods dan seluruh launch
  configuration invocations lulus. End-to-end UI test mencakup login lokal,
  profil, disclaimer, invite, join, timbang awal, bukti contoh, penyelesaian
  langkah, perubahan progres, papan peringkat, dan direktori coach.
- Accessibility verification: VoiceOver labels/identifiers diperiksa melalui
  runtime accessibility tree; light, dark, iPad, dan accessibility Dynamic
  Type terbesar diverifikasi, termasuk scroll dan akses lima tab.
- Remaining blockers: nilai Swift 6, strict concurrency, dan deployment target
  iOS 17 belum dipersist ke Xcode project karena perubahan `project.pbxproj`
  tidak diizinkan. Tidak ada integrasi eksternal yang dibutuhkan.
