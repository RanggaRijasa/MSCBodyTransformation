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

- [ ] `AppSpacing`
- [ ] `AppRadius`
- [ ] `AppTypography`
- [ ] `AppMotion`
- [ ] `AppStatusStyle`
- [ ] Asset catalog colors dengan light/dark variants
- [ ] Optional brand accent yang tidak merusak system contrast

Jangan membuat token untuk setiap pixel. Gunakan semantic grouping kecil.

## Shared components

- [ ] `AsyncContentView`
- [ ] `LoadingStateView`
- [ ] `EmptyStateView`
- [ ] `ErrorStateView`
- [ ] `OfflineBanner`
- [ ] `StatusBadge`
- [ ] `ProgressRing`
- [ ] `MetricCard`
- [ ] `UserAvatar`
- [ ] `ProgramCard`
- [ ] `StepRow`
- [ ] `SectionHeader`
- [ ] `PrimaryActionBar`
- [ ] `ConfirmationSheet`
- [ ] `MediaThumbnail`
- [ ] `LockedContentView`
- [ ] `RankBadge`
- [ ] `EvidenceStatusView`

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

- [ ] Buat `AppTab` role-aware.
- [ ] Buat separate navigation path per tab.
- [ ] Restore path saat pindah tab.
- [ ] Jangan hanya menyembunyikan inaccessible tab dalam satu tab array statis.
- [ ] Buat route enums per feature.
- [ ] Gunakan `.sheet(item:)` untuk model-selected sheets.
- [ ] Gunakan enum untuk mutually exclusive sheet atau alert.
- [ ] Deep-link placeholder dapat diarahkan ke local invite route.

## Liquid Glass

### iOS 26+

- [ ] Buat reusable availability-gated glass component.
- [ ] Gunakan `GlassEffectContainer` untuk related compact controls.
- [ ] Gunakan `.glassEffect` setelah layout dan visual modifiers.
- [ ] Gunakan interactive glass hanya pada actionable element.
- [ ] Gunakan glass button styles pada primary contextual action bila cocok.
- [ ] Pastikan Reduce Transparency dan Increase Contrast tetap terbaca.

Good candidates:

- Floating primary action.
- QR action panel.
- Compact filters.
- Rank badge.
- Media viewer controls.

### iOS 17 sampai 25

- [ ] Gunakan standard system background.
- [ ] Gunakan material secara terbatas.
- [ ] Gunakan native `List`, `Form`, `TabView`, dan `NavigationStack`.
- [ ] Jangan meniru Liquid Glass dengan custom blur stack.
- [ ] Pertahankan hierarchy dan interaction behavior yang sama.

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

- [ ] Tambahkan Debug-only role switcher.
- [ ] Tambahkan Debug-only scenario picker.
- [ ] Scenario: loading.
- [ ] Scenario: error.
- [ ] Scenario: empty.
- [ ] Scenario: offline.
- [ ] Scenario: participant active.
- [ ] Scenario: coach review queue.
- [ ] Scenario: admin draft editor.
- [ ] Jangan compile role switcher ke Release.

## Accessibility baseline

- [ ] VoiceOver label pada tab dan icon-only buttons.
- [ ] Dynamic Type sampai accessibility sizes.
- [ ] Text wrapping tanpa clipping.
- [ ] Logical focus order.
- [ ] Reduce Motion respected.
- [ ] Reduce Transparency respected.
- [ ] Accessibility identifiers untuk critical navigation.

## Test minimum

- [ ] Role menghasilkan tab yang benar.
- [ ] Participant tidak memiliki admin route.
- [ ] Per-tab navigation path preserved.
- [ ] iOS 26 availability branch compile.
- [ ] Fallback branch compile.
- [ ] Snapshot tidak wajib, gunakan previews dan UI assertions native.
- [ ] UI test role switching pada Debug test launch argument.

## Exit criteria

- [ ] Ketiga app shell dapat dibuka dari mock session.
- [ ] Semua tabs render.
- [ ] Primary shared components memiliki preview.
- [ ] Light dan dark mode usable.
- [ ] Largest Dynamic Type tidak memblokir navigation.
- [ ] Liquid Glass hanya dipakai secara selektif.
- [ ] Clean build dan test lulus.

## Progress log

### Log
