# Phase 05: Admin CMS UI

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
5. Pratinjau peserta.
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

- [x] Preview participant Today.
- [x] Preview timeline.
- [x] Preview step detail.
- [x] Preview locked states.
- [x] Preview leaderboard scoring description.
- [x] Preview on small and large device sizes.

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
- [x] Role badges.
- [x] Pending coach approval.
- [x] Approve coach local action.
- [x] Public coach profile toggle.
- [x] Participant detail summary.
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
- [x] Participant preview mencerminkan draft.
- [x] People dan Content screens dapat didemokan.
- [x] Semua privileged local action membuat local audit entry.
- [x] Test lulus dan clean build.

## Progress log

### Log

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
