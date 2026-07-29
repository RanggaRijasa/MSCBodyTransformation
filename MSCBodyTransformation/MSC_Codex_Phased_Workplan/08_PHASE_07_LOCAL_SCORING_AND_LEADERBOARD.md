# Phase 07: Local Scoring, Progress, and Leaderboard Simulation

## Tujuan

Mengimplementasikan aturan domain scoring dan leaderboard secara lokal agar UI dapat diuji. Implementasi ini menjadi executable specification untuk backend, tetapi bukan authoritative production source.

## External dependency status

**Lokal sepenuhnya.**

## Formula MVP

```text
total_points =
    approved_step_points
    + weight_points
    + adjustment_points
```

```text
weight_loss_kg = max(initial_weight_kg - final_weight_kg, 0)
weight_points = rounded(weight_loss_kg × weight_points_per_kg)
```

Default:

```text
weight_points_per_kg = 800
```

Ini mewakili 80 poin per 0,1 kg dan harus dapat dikonfigurasi per program.

## Domain services

Buat pure services:

- [x] `StepScoreCalculator`
- [x] `WeightScoreCalculator`
- [x] `EnrollmentScoreCalculator`
- [x] `ProgressCalculator`
- [x] `ProgramDayResolver`
- [x] `VisibilityPolicyEvaluator`
- [x] `LeaderboardSorter`
- [x] `WinnerSelector`

Semua service harus deterministic dan mudah diuji.

## Step scoring rules

- [x] Approved submission mendapat published step points.
- [x] Pending submission mendapat zero authoritative points.
- [x] Rejected submission mendapat zero points.
- [x] Duplicate submission tidak menggandakan poin.
- [x] Optional step dapat memberi poin bila completed.
- [x] Inactive step tidak dihitung.
- [x] Client input points tidak pernah diterima sebagai source.
- [x] Local mock mengambil points dari fixture `ProgramStep`.

## Weight scoring rules

- [x] Initial dan final weight memakai `Decimal`.
- [x] Weight loss negatif menjadi zero points.
- [x] Multiplier harus positif.
- [x] Rounding rule didokumentasikan dan konsisten.
- [x] Missing final weight menghasilkan zero weight points dan incomplete state.
- [x] Weight values tidak ditampilkan pada public leaderboard.
- [x] Admin adjustment dipisahkan dari weight points.

## Progress rules

Definisikan dengan jelas:

- Required step count.
- Completed required step count.
- Pending review behavior.
- Rejected step behavior.
- Optional step behavior.
- Overall program completion.
- Current day completion.

Jangan menyamakan progress dengan total points.

## Tie-break order

1. Total points descending.
2. Approved step points descending.
3. Weight points descending.
4. Completion timestamp ascending.
5. Enrollment UUID stable order sebagai final deterministic fallback.

## Leaderboard behavior

- [x] Current user rank.
- [x] Top five emphasis.
- [x] Full ranking.
- [x] Provisional state while scoring open.
- [x] Final locked snapshot.
- [x] Participant display name privacy decision.
- [x] Placeholder avatar.
- [x] Equal score tie presentation.
- [x] Ranking remains deterministic.
- [x] Winner banner integration with local content.

## Winner lock local simulation

- [x] Admin can preview top five.
- [x] Confirmation required.
- [x] Create local immutable winner snapshot.
- [x] Later mock score changes do not silently alter locked winners.
- [x] Display warning when scores change after lock.
- [x] Reset available only in Debug fixture tooling.

## Time and visibility simulation

- [x] Store sample program timezone as IANA identifier.
- [x] Use injected clock.
- [x] Resolve active day using program timezone.
- [x] Past policy: hidden, read-only, open.
- [x] Future policy: hidden, read-only, open.
- [x] Device date override for Debug.
- [x] Do not hard-code Asia/Makassar in service; use program value.

## Test matrix

### Weight

- [x] 80.0 to 79.9.
- [x] 80.0 to 79.0.
- [x] No loss.
- [x] Weight gain.
- [x] Decimal precision.
- [x] Custom multiplier.
- [x] Missing final.

### Step

- [x] All approved.
- [x] Pending.
- [x] Rejected.
- [x] Mixed.
- [x] Duplicate completion.
- [x] Optional step.
- [x] Zero-point step.
- [x] Invalid negative point fixture rejected.

### Ranking

- [x] Different total points.
- [x] Same total, different step points.
- [x] Same step points, different weight points.
- [x] Same points, different completion time.
- [x] Fully equal values use deterministic UUID.
- [x] Top five with fewer than five participants.
- [x] Winner lock stability.

### Time

- [x] Program timezone differs from device.
- [x] Day boundary.
- [x] Daylight-saving timezone fixture.
- [x] Before start.
- [x] After end.
- [x] Hidden future day.
- [x] Read-only past day.

## UI integration

- [x] Participant score updates after local completion.
- [x] Coach review updates ranking.
- [x] Final weigh-in updates weight points.
- [x] Admin adjustment updates total but remains separate.
- [x] Leaderboard animates gently and respects Reduce Motion.
- [x] Do not show fake "server verified" label in local demo.
- [x] Peserta dapat memilih di antara program aktif yang diikutinya.
- [x] Hasil program selesai tersedia melalui arsip sekunder.

## Larangan scope

Jangan:

- Menyebut local score production-authoritative.
- Mengirim score ke backend.
- Menggunakan `Double` untuk canonical weight logic.
- Menampilkan private weight on leaderboard.
- Mengubah winner snapshot silently.
- Mengandalkan device clock tanpa injected program timezone logic.

## Exit criteria

- [x] Domain scoring tests lengkap dan lulus.
- [x] Leaderboard deterministic.
- [x] Participant, coach, dan admin UI menggunakan service yang sama.
- [x] Local winner lock bekerja.
- [x] Scoring specification siap diterjemahkan ke server operation.
- [x] Clean build.

## Progress log

### Log

#### 2026-07-28 — Warna podium Home dan Peringkat disatukan

- Files changed: shared rank style peserta, ringkasan leaderboard Home,
  komponen podium Peringkat, dan progress log Phase 07.
- Assumptions: tampilan Peringkat menjadi sumber visual; peringkat 1 memakai
  `BrandAccent`, peringkat 2 memakai `AppSecondaryText`, dan peringkat 3
  memakai `PodiumBronze`.
- Build command: XcodeBuildMCP `build_sim` dan `build_run_sim` pada iPhone 17
  Pro iOS 26.5.
- Test command: XcodeBuildMCP `test_sim` untuk
  `MSCBodyTransformationTests/Phase07LocalScoringTests`.
- Result: build/run lulus tanpa warning; 21/21 test Phase 07 lulus; inspeksi
  runtime memastikan ring dan badge Home identik dengan podium utama.
- Remaining blockers: tidak ada blocker untuk konsistensi warna ini.

#### 2026-07-28 — Warna perunggu konsisten dan poin podium berbeda

- Files changed: komponen podium peserta, asset `PodiumBronze`, fixture
  leaderboard, test Phase 07, UI reference, dan progress log.
- Assumptions: identitas peringkat 3 memakai perunggu `#CD7F32` yang sama pada
  light dan dark mode; surface tetap adaptif melalui opacity. Fixture aktif
  menampilkan 240, 210, dan 200 poin untuk tiga besar.
- Build command: XcodeBuildMCP `build_sim` dan `build_run_sim` pada iPhone 17
  Pro iOS 26.5 dengan Swift 6 strict concurrency dan deployment target iOS 17.
- Test command: XcodeBuildMCP `test_sim` untuk
  `MSCBodyTransformationTests/Phase07LocalScoringTests`.
- Result: build/run lulus tanpa warning; 21/21 test Phase 07 lulus; inspeksi
  runtime light dan dark memastikan perunggu konsisten serta poin podium
  berbeda.
- Remaining blockers: score authoritative tetap menunggu implementasi server
  pada fase backend.

#### 2026-07-26 — Scoring, progress, ranking, dan winner lock lokal

- Files changed: service scoring domain, adapter aturan program, repository
  in-memory, use case hari aktif, Participant store dan leaderboard, Admin
  winner management, fixture multiplier, test scoring, dan UI test.
- Assumptions: semua `ProgramStep` yang masuk ke program terbit dianggap
  langkah aktif; Admin draft menyaring `isActive == false` sebelum menjadi
  `Program`. Nama peserta pada leaderboard adalah nama tampilan publik.
- Build command:
  `xcodebuild -project MSCBodyTransformation.xcodeproj -scheme MSCBodyTransformation -configuration Debug -destination 'platform=iOS Simulator,id=C63135B7-AF6A-42C0-8993-DF4C72589FE1' SWIFT_VERSION=6 SWIFT_STRICT_CONCURRENCY=complete IPHONEOS_DEPLOYMENT_TARGET=17.0 build`.
- Test command: seluruh target Swift Testing, UI winner lock/adjustment, dan
  journey Coach.
- Result: 16/16 test fokus Phase 07 lulus; seluruh 76 unit test lulus; UI
  lock snapshot dan journey Coach lulus; build bersih tanpa warning.
- Remaining blockers: score lokal adalah executable specification dan belum
  authoritative sampai diterjemahkan ke operation server pada fase backend.

#### 2026-07-27 — redesign Papan peringkat Peserta

- Files changed: state pemilihan program Papan peringkat Peserta; layout
  selector program, podium tiga besar, posisi peserta, ranking lanjutan, dan
  sheet riwayat; localization catalog; unit/UI test; README serta inventaris
  layar.
- Assumptions: hanya program yang memiliki enrollment aktif yang muncul pada
  pilihan utama. Program berstatus selesai atau arsip dengan enrollment
  selesai ditempatkan pada Riwayat. Winner snapshot dipakai sebagai hasil
  final bila tersedia; data berat badan tetap tidak ditampilkan.
- Build command: XcodeBuildMCP `build_sim(extraArgs:
  ["SWIFT_VERSION=6", "SWIFT_STRICT_CONCURRENCY=complete",
  "IPHONEOS_DEPLOYMENT_TARGET=17.0"])` pada iPhone 17 iOS 26.5.
- Test command: XcodeBuildMCP `test_sim` untuk 19
  `Phase07LocalScoringTests`, seluruh target unit
  `MSCBodyTransformationTests`, serta UI test
  `testParticipantOpensArchivedLeaderboard`.
- Result: build lulus tanpa warning/error; 19 test Phase 07, seluruh 96 unit
  test, dan UI journey memilih hasil program selesai lulus. Runtime
  inspection mengonfirmasi selector, podium, posisi peserta, serta arsip
  dapat digunakan pada simulator.
- Remaining blockers: pagination dan data score authoritative tetap untuk
  fase backend. UI dan repository boundary sudah mendukung lebih dari satu
  program aktif tanpa menambahkan dependency eksternal.

#### 2026-07-27 — kapasitas tampilan poin lima digit

- Files changed: komponen podium dan baris Papan peringkat Peserta; formatter
  poin Indonesia; preview poin lima digit; unit test Phase 07.
- Assumptions: UI perlu menampilkan sedikitnya poin belasan ribu tanpa
  singkatan. Nilai tetap menggunakan angka lengkap dengan pemisah ribuan
  locale `id-ID`, bukan format compact seperti `12,3 rb`.
- Build command: XcodeBuildMCP `build_sim(extraArgs:
  ["SWIFT_VERSION=6", "SWIFT_STRICT_CONCURRENCY=complete",
  "IPHONEOS_DEPLOYMENT_TARGET=17.0"])` pada iPhone 17 iOS 26.5.
- Test command: XcodeBuildMCP `test_sim` untuk 20
  `Phase07LocalScoringTests`.
- Result: build lulus tanpa warning/error dan 20/20 test lulus. Preview
  memuat nilai `12.350`, `15.420`, dan `18.750`; formatter juga diverifikasi
  sampai `98.765`. Badge poin mempertahankan satu baris, sedangkan row
  berpindah ke susunan vertikal pada Dynamic Type aksesibilitas.
- Remaining blockers: pagination dan score authoritative tetap untuk fase
  backend. Tidak ada konfigurasi eksternal atau perubahan project.

#### 2026-07-27 — selector program Papan peringkat

- Files changed: tampilan Papan peringkat Peserta, komponen selector program,
  katalog lokalisasi, dan UI test arsip Papan peringkat.
- Assumptions: satu program aktif tidak membutuhkan control pemilihan; kartu
  hanya menjadi tombol `Ganti` ketika peserta mempunyai beberapa program aktif
  atau sedang melihat hasil program arsip.
- Build command: XcodeBuildMCP `build_run_sim` dengan Swift 6 strict
  concurrency pada iPhone 17 dan skenario `participant_active`.
- Test command: XcodeBuildMCP `test_sim` untuk
  `testParticipantOpensArchivedLeaderboard`.
- Result: build lulus tanpa warning atau error; satu program aktif tampil
  sebagai kartu informasi tanpa dropdown. UI test lulus dan memverifikasi
  perpindahan dari arsip ke sheet native `Pilih program`, lalu kembali ke
  program aktif.
- Remaining blockers: fixture peserta saat ini hanya mempunyai satu program
  aktif; dukungan beberapa program tetap diterapkan pada UI dan store. Data
  authoritative dan pagination tetap ditunda ke fase backend.

#### 2026-07-27 — fixture Papan peringkat multi-program

- Files changed: fixture program, enrollment, dan leaderboard; test kontrak
  fixture; test pemilihan program Papan peringkat; serta UI test alur arsip.
- Assumptions: peserta demo Ayu mengikuti dua program aktif agar control
  `Ganti` dan sheet native `Pilih program` dapat diuji langsung. Program demo
  kedua memiliki leaderboard sendiri dan poin lima digit tanpa mengubah aturan
  scoring.
- Build command: XcodeBuildMCP `build_run_sim` dengan
  `SWIFT_VERSION=6`, `SWIFT_STRICT_CONCURRENCY=complete`, dan
  `IPHONEOS_DEPLOYMENT_TARGET=17.0` pada iPhone 17 iOS 26.5.
- Test command: XcodeBuildMCP `test_sim` untuk `Phase01FixtureTests`,
  `Phase07LocalScoringTests`, dan
  `testParticipantOpensArchivedLeaderboard`.
- Result: build dan launch lulus tanpa warning atau error; 25/25 unit test
  fokus serta 1/1 UI test lulus. Runtime inspection mengonfirmasi sheet
  `Pilih program` menampilkan `Gerak konsisten 3 hari` dan
  `Transformasi 7 hari`, dengan checkmark pada program yang sedang dipilih.
- Remaining blockers: score authoritative, enrollment produksi, dan
  pagination tetap ditunda ke fase backend. Tidak ada konfigurasi eksternal
  atau perubahan project Xcode.

#### 2026-07-27 — keterbacaan sheet pemilihan program

- Files changed: presentation dan surface daftar pada sheet native
  `Pilih program`.
- Assumptions: detent `.medium` dan `.large` tetap diperlukan, tetapi
  background Liquid Glass transparan pada detent setengah tidak sesuai untuk
  daftar teks. Sheet memakai `AppBackground` yang opaque, sedangkan row tetap
  memakai tampilan `List` native.
- Build command: XcodeBuildMCP `build_run_sim` dengan
  `SWIFT_VERSION=6`, `SWIFT_STRICT_CONCURRENCY=complete`, dan
  `IPHONEOS_DEPLOYMENT_TARGET=17.0` pada iPhone 17 iOS 26.5.
- Test command: XcodeBuildMCP `test_sim` untuk
  `testParticipantOpensArchivedLeaderboard`.
- Result: build dan launch lulus tanpa warning atau error; 1/1 UI test lulus.
  Runtime inspection pada detent setengah mengonfirmasi judul, tanggal,
  checkmark, serta tombol dapat dibaca tanpa konten Papan peringkat terlihat
  menembus sheet. Light dan dark mode telah diperiksa.
- Remaining blockers: tidak ada untuk perbaikan UI lokal ini. Data
  authoritative dan pagination tetap ditunda ke fase backend.

#### 2026-07-27 — sinkronisasi Papan peringkat Home

- Files changed: strip Papan peringkat pada Home dan UI test perpindahan tab.
- Assumptions: pilihan program terakhir pada tab Peringkat menjadi satu-satunya
  sumber tampilan strip Home, termasuk bila pilihan tersebut merupakan program
  arsip. Nama program selalu ditampilkan agar lima peserta teratas tidak
  ambigu.
- Build command: XcodeBuildMCP `build_run_sim` dengan
  `SWIFT_VERSION=6`, `SWIFT_STRICT_CONCURRENCY=complete`, dan
  `IPHONEOS_DEPLOYMENT_TARGET=17.0` pada iPhone 17 iOS 26.5.
- Test command: XcodeBuildMCP `test_sim` untuk
  `Phase07LocalScoringTests` dan
  `testParticipantHomeViewAllSelectsLeaderboardTab`.
- Result: build dan launch lulus; 21/21 test fokus lulus. Runtime inspection
  mengonfirmasi Home berubah ke `Gerak konsisten 3 hari` setelah program itu
  dipilih, lalu `Lihat semua` membuka tab Peringkat dengan program yang sama
  tetap aktif.
- Remaining blockers: pilihan terakhir masih hidup selama session store
  lokal berjalan dan belum dipersistenkan lintas peluncuran aplikasi. Persisten
  akun serta data authoritative tetap ditunda ke fase backend.
