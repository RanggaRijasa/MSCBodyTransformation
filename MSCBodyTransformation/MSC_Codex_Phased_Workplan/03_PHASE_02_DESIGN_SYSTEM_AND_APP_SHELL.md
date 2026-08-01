# Phase 02: Native Design System and Role-Adaptive App Shell

## Referensi wajib

Baca dan ikuti `UI_REFERENCE_SHEET.md`. Dokumen tersebut menjadi source of truth untuk Bahasa Indonesia, semantic colors hitam-merah-kuning, tipografi, light mode, dark mode, spacing, button hierarchy, dan copy state.

## Tujuan

Membangun bahasa visual native dan struktur navigasi untuk Participant, Coach, dan Admin menggunakan mock session.

## External dependency status

**Tidak ada integrasi eksternal.**

## Hasil akhir

- App shell untuk tiga role.
- Per-tab `NavigationStack`.
- Shared components.
- Liquid Glass iOS 26+.
- Native fallback iOS 17 sampai 25.
- Light dan dark mode.
- Preview utama.
- Baseline accessibility.

## Design principles

- Gunakan standard SwiftUI controls lebih dulu.
- Jangan membuat custom navigation bar bila system API cukup.
- Jangan menggunakan glass pada setiap card.
- Long-form content menggunakan system background.
- Dense admin forms menggunakan `Form`.
- Status tidak boleh hanya dibedakan oleh warna.
- Layout harus mendukung Dynamic Type.
- Interactive target minimum 44 x 44 points.

## Warna utama

- Hitam sebagai identitas, teks kuat, dan surface tertentu.
- Merah sebagai primary action dan active highlight.
- Kuning sebagai pencapaian, peringkat, dan aksen terbatas.
- Semua warna harus berupa semantic Asset Catalog colors dengan nilai light dan dark mode.
- Jangan menggunakan kuning sebagai body text pada background terang.
- Jangan menggunakan warna sebagai satu-satunya pembeda status.

## Semantic tokens

Buat:

- [x] `AppSpacing`
- [x] `AppRadius`
- [x] `AppTypography`
- [x] `AppMotion`
- [x] `AppStatusStyle`
- [x] Asset catalog colors dengan light/dark variants
- [x] Optional brand accent yang tidak merusak system contrast

Jangan membuat token untuk setiap pixel. Gunakan semantic grouping kecil.

## Shared components

- [x] `AsyncContentView`
- [x] `LoadingStateView`
- [x] `EmptyStateView`
- [x] `ErrorStateView`
- [x] `OfflineBanner`
- [x] `StatusBadge`
- [x] `ProgressRing`
- [x] `MetricCard`
- [x] `UserAvatar`
- [x] `ProgramCard`
- [x] `StepRow`
- [x] `SectionHeader`
- [x] `PrimaryActionBar`
- [x] `ConfirmationSheet`
- [x] `MediaThumbnail`
- [x] `LockedContentView`
- [x] `RankBadge`
- [x] `EvidenceStatusView`

Setiap component memiliki preview untuk state penting.

## Role-adaptive navigation

### Participant tabs

1. Today
2. Program
3. Leaderboard
4. Coaches
5. Profile

### Coach tabs

1. Dashboard
2. Participants
3. Invite
4. Leaderboard
5. Profile

### Admin tabs

1. Overview
2. Programs
3. People
4. Content
5. Settings

Checklist:

- [x] Buat `AppTab` role-aware.
- [x] Buat separate navigation path per tab.
- [x] Restore path saat pindah tab.
- [x] Jangan hanya menyembunyikan inaccessible tab dalam satu tab array statis.
- [x] Buat route enums per feature.
- [x] Gunakan `.sheet(item:)` untuk model-selected sheets.
- [x] Gunakan enum untuk mutually exclusive sheet atau alert.
- [x] Deep-link placeholder dapat diarahkan ke local invite route.

## Liquid Glass

### iOS 26+

- [x] Buat reusable availability-gated glass component.
- [x] Gunakan `GlassEffectContainer` untuk related compact controls.
- [x] Gunakan `.glassEffect` setelah layout dan visual modifiers.
- [x] Gunakan interactive glass hanya pada actionable element.
- [x] Gunakan glass button styles pada primary contextual action bila cocok.
- [x] Pastikan Reduce Transparency dan Increase Contrast tetap terbaca.

Good candidates:

- Floating primary action.
- QR action panel.
- Compact filters.
- Rank badge.
- Media viewer controls.

### iOS 17 sampai 25

- [x] Gunakan standard system background.
- [x] Gunakan material secara terbatas.
- [x] Gunakan native `List`, `Form`, `TabView`, dan `NavigationStack`.
- [x] Jangan meniru Liquid Glass dengan custom blur stack.
- [x] Pertahankan hierarchy dan interaction behavior yang sama.

Contoh boundary:

```swift
@ViewBuilder
func adaptiveSurface<Content: View>(
    @ViewBuilder content: () -> Content
) -> some View {
    if #available(iOS 26, *) {
        content()
            .padding()
            .glassEffect()
    } else {
        content()
            .padding()
            .background(
                Color(uiColor: .secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 16)
            )
    }
}
```

Sesuaikan implementasi dengan API yang benar pada Xcode yang tersedia. Jangan menebak signature.

## Debug shell

- [x] Tambahkan Debug-only role switcher.
- [x] Tambahkan Debug-only scenario picker.
- [x] Scenario: loading.
- [x] Scenario: error.
- [x] Scenario: empty.
- [x] Scenario: offline.
- [x] Scenario: participant active.
- [x] Scenario: coach review queue.
- [x] Scenario: admin draft editor.
- [x] Jangan compile role switcher ke Release.

## Accessibility baseline

- [x] VoiceOver label pada tab dan icon-only buttons.
- [x] Dynamic Type sampai accessibility sizes.
- [x] Text wrapping tanpa clipping.
- [x] Logical focus order.
- [x] Reduce Motion respected.
- [x] Reduce Transparency respected.
- [x] Accessibility identifiers untuk critical navigation.

## Test minimum

- [x] Role menghasilkan tab yang benar.
- [x] Participant tidak memiliki admin route.
- [x] Per-tab navigation path preserved.
- [x] iOS 26 availability branch compile.
- [x] Fallback branch compile.
- [x] Snapshot tidak wajib, gunakan previews dan UI assertions native.
- [x] UI test role switching pada Debug test launch argument.

## Exit criteria

- [x] Ketiga app shell dapat dibuka dari mock session.
- [x] Semua tabs render.
- [x] Primary shared components memiliki preview.
- [x] Light dan dark mode usable.
- [x] Largest Dynamic Type tidak memblokir navigation.
- [x] Liquid Glass hanya dipakai secara selektif.
- [x] Clean build dan test lulus.

## Progress log

### Log

#### 2026-08-01 — Gesture kembali dari tepi kiri

- Files changed: kontrol navigasi bersama, UI reference, UI test navigasi,
  dan progress log Phase 02.
- Assumptions: gesture kembali mengikuti perilaku native iOS dari leading
  edge dan hanya aktif jika navigation stack memiliki destination yang dapat
  di-pop. Aplikasi tidak menambahkan `DragGesture` layar penuh karena dapat
  bertabrakan dengan scroll, carousel, sheet, dan gesture sistem. Tombol back
  khusus tetap dipertahankan agar long-press tidak membuka menu riwayat.
- Build command: XcodeBuildMCP `build_run_sim(launchArgs:
  ["-AppleLanguages", "(id)", "-AppleLocale", "id_ID", "-DemoRole",
  "coach", "-DemoScenario", "coach_review_queue",
  "-SkipDemoLanding"])` untuk scheme `MSCBodyTransformation`, konfigurasi
  Debug, pada iPhone 17 iOS 26.5.
- Test command: XcodeBuildMCP `test_sim` untuk
  `Phase02NavigationTests`,
  `testLeadingEdgeSwipePopsCustomBackDestinations`, dan
  `testParticipantSelectsProgramBeforeOpeningDetail`.
- Result: build/run lulus tanpa warning; empat test navigasi dan dua UI test
  lulus. Edge swipe berhasil melakukan pop pada dua destination bertingkat,
  sedangkan tombol kembali singkat maupun long-press tetap menggunakan
  perilaku satu kali pop tanpa menu riwayat.
- Remaining blockers: tidak ada.

#### 2026-07-26 — Phase 02 selesai

- Files changed: semantic color assets; design tokens dan adaptive glass styles;
  18 shared components beserta previews; role-aware tabs, routes, per-tab
  navigation paths, sheets, alerts, dan local invite deep link; Debug landing
  dan scenario launch arguments; role app shells; localization; unit dan UI
  tests.
- Assumptions: target project belum diubah karena `project.pbxproj` berada di
  luar scope; verifikasi memakai override Swift 6, strict concurrency, dan
  deployment target iOS 17. Simulator runtime yang tersedia adalah iOS 26.3
  sampai 26.5, sehingga fallback iOS 17–25 diverifikasi lewat availability
  gating dan compile dengan deployment target 17, bukan screenshot runtime
  lama.
- Build command: XcodeBuildMCP
  `build_run_sim(launchArgs: ["-DemoRole", "participant", "-DemoScenario", "participantActive", "-SkipDemoLanding"])`
  pada iPhone 17 Pro iOS 26.5, lalu command yang sama untuk role Admin pada
  iPad Pro 13-inch iOS 26.5. Build Release diverifikasi dengan
  `build_sim()` pada iPhone 17 Pro.
- Test command: XcodeBuildMCP
  `test_sim(extraArgs: ["-only-testing:MSCBodyTransformationTests"])` dan
  `test_sim(extraArgs: ["-only-testing:MSCBodyTransformationUITests"])`.
- Result: build Debug iPhone dan iPad serta build Release lulus tanpa warning;
  23 unit/integration tests lulus; seluruh UI test lulus, termasuk role launch
  arguments dan semua tab utama. Light, dark, Increase Contrast, serta
  accessibility Dynamic Type terbesar diperiksa pada simulator.
- Remaining blockers: nilai Swift 6, strict concurrency, dan deployment target
  iOS 17 belum dipersist ke Xcode project karena task tidak mengizinkan
  perubahan `project.pbxproj`.

#### 2026-07-28 — tombol kembali tanpa menu riwayat

- Files changed: `SharedUI/Components/NavigationControls.swift`;
  `RoleAppShellView.swift`; destination bertingkat pada Profil Participant dan
  editor Program Admin; `Localizable.xcstrings`; serta UI test navigasi.
- Assumptions: tombol kembali pada destination yang didorong ke
  `NavigationStack` harus selalu melakukan satu kali pop. Sheet yang memang
  menggunakan aksi `Tutup` atau `Batal` tidak diubah karena tidak menampilkan
  menu riwayat navigasi.
- Build command: XcodeBuildMCP
  `build_run_sim(extraArgs: ["SWIFT_VERSION=6",
  "SWIFT_STRICT_CONCURRENCY=complete", "IPHONEOS_DEPLOYMENT_TARGET=17.0"],
  launchArgs: ["-DemoRole", "participant", "-DemoScenario",
  "participant_active", "-SkipDemoLanding"])` pada iPhone 17 iOS 26.5.
- Test command: XcodeBuildMCP `test_sim` dengan strict Swift 6 untuk
  `Phase02NavigationTests`,
  `testParticipantHomeProfileCardSelectsProfileTab`,
  `testParticipantSelectsProgramBeforeOpeningDetail`, dan
  `testAdminCreatesDraftAddsDayStepPreviewsAndPublishes`.
- Result: build dan 8 hasil test terfokus lulus tanpa warning. Pemeriksaan
  runtime pada detail Program mengonfirmasi tombol `navigation.back` dapat
  ditekan maupun ditahan tanpa menampilkan menu riwayat; keduanya kembali satu
  layar. Jalur destination utama, destination legal Profil, dan destination
  bertingkat editor Program Admin menggunakan kontrol yang sama.
- Remaining blockers: tidak ada untuk perubahan ini. Item berikutnya tetap
  profiling scrolling Participant Home pada Phase 08.

#### 2026-07-28 — responsivitas tombol kembali

- Files changed: `SharedUI/Components/NavigationControls.swift`,
  `SharedUI/Styles/AppLayout.swift`, dan UI test navigasi Participant.
- Assumptions: kegagalan pada tekanan singkat berasal dari kombinasi hit area
  icon yang sempit, pergerakan kecil jari, dan style toolbar iOS 26. Kontrol
  tetap berupa `Button` SwiftUI native, tetapi memakai hit target 44 × 44 dan
  plain button style agar tidak ada gesture visual toolbar yang bersaing.
- Build command: XcodeBuildMCP `build_run_sim` dengan Swift 6 strict,
  deployment target iOS 17, dan scenario `participant_active` pada iPhone 17
  iOS 26.5.
- Test command: XcodeBuildMCP `test_sim` untuk
  `Phase02NavigationTests` dan
  `testParticipantSelectsProgramBeforeOpeningDetail`.
- Result: build lulus tanpa warning; 6 hasil test lulus. UI test menekan tombol
  kembali selama 0,15, 0,35, dan 1 detik; seluruh durasi kembali satu layar
  tanpa membuka menu riwayat. Pemeriksaan runtime terpisah pada durasi 0,35
  detik juga lulus.
- Remaining blockers: sanity check rasa sentuhan pada iPhone fisik tetap
  direkomendasikan karena simulator tidak mereplikasi pergerakan jari secara
  penuh. Item berikutnya tetap profiling scrolling Participant Home pada
  Phase 08.
