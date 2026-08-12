# 03 — Design system specification

## 1. Arah visual

MSCWEB memakai identitas hitam, merah, dan kuning dari aplikasi iOS. Hasil harus modern, tegas, hangat, dan fokus pada progres—bukan template dashboard generik. Tampilan premium datang dari hierarchy, spacing, type scale, motion, detail state, dan konsistensi; bukan dari glass/gradient berlebihan.

- `DS-001` Styling feature app MUST menggunakan React Native `StyleSheet.create` dan centralized design tokens.
- `DS-002` Tailwind, NativeWind, hardcoded utility string, dan styling ad hoc berulang MUST NOT digunakan.
- `DS-003` Feature component MUST NOT berisi nilai hex brand langsung.
- `DS-004` Landing web-only MAY memakai CSS Modules/platform stylesheet, tetapi warna/spacing/type tetap berasal dari generated/shared tokens.
- `DS-005` Sistem MUST mendukung light, dark, increased contrast, reduced transparency, reduced motion, keyboard focus, dan zoom browser.

## 2. Token architecture

Token dibagi menjadi tiga lapis:

1. `Primitive`: raw palette, spacing, radius, duration.
2. `Semantic`: background, surface, text, action, status, border, focus.
3. `Component`: button height, tab bar, card padding, input state, overlay.

Component hanya mengonsumsi semantic/component token. Primitive tidak diakses langsung dari feature.

### 2.1 Color baseline

| Semantic token | Light | Dark |
|---|---|---|
| `color.brand.primary` | `#D92D20` | `#D92D20` |
| `color.brand.primaryPressed` | `#B42318` | `#B42318` |
| `color.brand.secondary` | `#111111` | `#F5F5F5` |
| `color.brand.accent` | `#F5C542` | `#F5C542` |
| `color.background.primary` | `#F7F7F8` | `#0D0D0F` |
| `color.background.secondary` | system neutral | `#151517` |
| `color.surface.primary` | `#FFFFFF` | `#1C1C1E` |
| `color.surface.elevated` | `#FFFFFF` | `#242426` |
| `color.text.primary` | `#111111` | `#F5F5F5` |
| `color.text.secondary` | `#5F6368` | `#B0B0B5` |
| `color.border.default` | `#DADCE0` | `#3A3A3C` |
| `color.status.destructive` | `#C62828` | `#C62828` |
| `color.status.success` | `#18794E` | `#5ED39A` |
| `color.status.warning` | `#8A5A00` | `#FFD166` |
| `color.status.info` | `#2457A6` | `#78A9FF` |

Nilai system neutral light untuk secondary background harus ditentukan bersama renderer browser pada implementation spike, lalu di-snapshot sebagai token. Yellow tidak boleh menjadi body text kecil pada background terang.

### 2.2 Spacing, radius, and sizing

```text
space: 4, 8, 12, 16, 24, 32, 48
radius: 8, 12, 16, 24, capsule
minimum interactive target: 44 × 44 CSS px
content gutters compact: 16
content gutters medium: 24
content gutters wide: 32
```

- `DS-TKN-001` Feature MUST memakai spacing/radius token; pengecualian pixel-perfect harus diberi komentar dan test visual.
- `DS-TKN-002` Content wide MUST memiliki max-width per surface agar baris teks dan form tidak terlalu panjang.
- `DS-TKN-003` Safe area MUST menggunakan browser environment inset pada installed PWA dan fallback zero pada browser lain.

## 3. Typography

Gunakan system font stack agar dekat dengan San Francisco di perangkat Apple dan native system font di platform lain. Tidak ada custom font pada baseline.

Semantic styles minimal:

```text
display, titleLarge, title, headline, body, bodyStrong,
callout, label, caption, numericDisplay
```

- `DS-TYPE-001` Text produksi MUST dapat membesar hingga browser zoom 200% tanpa kehilangan fungsi.
- `DS-TYPE-002` Copy MUST NOT diperkecil secara dinamis agar muat.
- `DS-TYPE-003` Poin, rank, berat, timer, harga, dan angka berubah MUST memakai tabular numerals.
- `DS-TYPE-004` Format tanggal, waktu, persen, berat, dan Rupiah MUST menggunakan `Intl` locale `id-ID`, bukan string concatenation manual.
- `DS-TYPE-005` Heading hierarchy MUST semantic di web, meskipun visual style berbeda dari level HTML.

## 4. Icon system

Icon utama adalah Phosphor melalui SVG. Package baseline `phosphor-react-native` + `react-native-svg`, tetapi semua pemakaian harus melalui wrapper internal.

```tsx
<MSCIcon name="program" size="md" tone="primary" weight="regular" />
```

`MSCIcon` memetakan semantic name ke satu glyph Phosphor yang disetujui. Feature tidak mengimpor Phosphor langsung.

- `DS-ICO-001` Icon MUST berasal dari Phosphor atau asset brand resmi.
- `DS-ICO-002` Icon MUST NOT dibuat dari `div`, CSS borders, text character, emoji, atau arbitrary inline doodle.
- `DS-ICO-003` SF Symbols MUST NOT diekspor/disalin ke web. Setiap SF Symbol iOS dipetakan ke Phosphor equivalent berdasarkan makna, bukan kemiripan nama semata.
- `DS-ICO-004` Satu screen MUST NOT mencampur icon family.
- `DS-ICO-005` Icon-only button MUST memiliki accessible name/tooltip dan minimum target 44 × 44.
- `DS-ICO-006` Decorative icon MUST disembunyikan dari accessibility tree.
- `DS-ICO-007` Weight default `regular`; selected navigation MAY `fill`; status/brand emphasis MAY `bold` jika dicatat dalam semantic registry.

### 4.1 Semantic mapping baseline

| Semantic name | Phosphor glyph baseline |
|---|---|
| `home` | `House` |
| `program` | `CalendarDots` |
| `leaderboard` | `Ranking` |
| `coach` | `UsersThree` |
| `profile` | `UserCircle` |
| `dashboard` | `SquaresFour` |
| `reviewEvidence` | `Checks` |
| `participants` | `Users` |
| `activity` | `Pulse` |
| `qr` | `QrCode` |
| `content` | `FileText` |
| `settings` | `GearSix` |
| `camera` | `Camera` |
| `upload` | `UploadSimple` |
| `bank` | `Bank` |
| `copy` | `Copy` |
| `approved` | `CheckCircle` |
| `rejected` | `XCircle` |
| `pending` | `ClockCountdown` |
| `warning` | `Warning` |
| `back` | `ArrowLeft` |
| `more` | `DotsThree` |

Final mapping harus diaudit berdampingan dengan screen iOS pada implementation phase. Nama semantic tetap stabil walau glyph dituning.

## 5. Components

Shared primitives minimum:

- `Screen`, `AppHeader`, `SectionHeader`;
- `PrimaryButton`, `SecondaryButton`, `DestructiveButton`, `IconButton`;
- `TextField`, `SelectField`, `CheckboxField`, `RadioGroup`, `FileField`;
- `Card`, `StatusCard`, `EmptyState`, `ErrorState`, `Skeleton`;
- `SegmentedControl`, `BottomTabBar`, `NavigationRail`;
- `Sheet`, `Dialog`, `Toast`, `InlineMessage`;
- `UserAvatar` dengan neutral blank-person fallback, tanpa initials berwarna;
- `ProgramPoster`, `ProgressRing`, `StatusBadge`, `PointsLabel`;
- `EvidenceViewer`, `PaymentProofUploader`, `QRScanner`.

- `DS-CMP-001` Buttons MUST memiliki default, hover-capable, pressed, focus-visible, disabled, dan loading state.
- `DS-CMP-002` Status MUST selalu menggabungkan warna dengan label/icon/shape.
- `DS-CMP-003` Long content dan forms MUST berada pada neutral surfaces; glass tidak digunakan untuk setiap card.
- `DS-CMP-004` Avatar kosong MUST memakai neutral blank-person glyph; tidak membuat initials atau warna berdasarkan role.
- `DS-CMP-005` Skeleton MUST mengikuti layout final dan tidak dipakai sebagai pengganti explicit empty/error state.

## 6. Motion

Motion harus terasa responsif dan purposeful.

Token baseline:

```text
duration.instant: 0 ms
duration.fast: 120 ms
duration.normal: 200 ms
duration.slow: 320 ms
easing.standard: cubic-bezier(0.2, 0, 0, 1)
easing.emphasized: cubic-bezier(0.2, 0.8, 0.2, 1)
```

- `DS-MOT-001` Gunakan transform dan opacity untuk sebagian besar motion; hindari layout animation yang menyebabkan jank.
- `DS-MOT-002` Navigation transition tidak boleh menghambat browser back/forward.
- `DS-MOT-003` Progress, approval, dan error transition harus menjelaskan perubahan state, bukan sekadar dekorasi.
- `DS-MOT-004` Reduced Motion MUST menghilangkan parallax, spring besar, auto-scrolling animation, dan looping decoration.
- `DS-MOT-005` Tidak ada animation yang terus bergerak pada payment pending atau loading setelah state selesai.

## 7. Glass and elevation

Liquid Glass adalah referensi rasa untuk compact interactive chrome pada iOS 26, bukan API web yang harus ditiru.

- `DS-GLS-001` Backdrop blur MAY digunakan secara selektif pada bottom tab/header compact jika browser mendukung dan contrast tetap lulus.
- `DS-GLS-002` Fallback MUST berupa opaque semantic surface; tidak membuat tumpukan blur custom yang berat.
- `DS-GLS-003` Reduced Transparency MUST menggunakan surface opaque.
- `DS-GLS-004` Cards, list rows, forms, dan long text MUST tidak semuanya memakai glass.

## 8. PWA and brand icons

Source yang disetujui:

`../MSCBodyTransformation/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-Default.png`

Derivatives yang wajib dibuat saat implementasi:

| Asset | Ukuran | Purpose |
|---|---:|---|
| `icon-192.png` | 192×192 | manifest `any` |
| `icon-512.png` | 512×512 | manifest `any` |
| `icon-maskable-192.png` | 192×192 | manifest `maskable` |
| `icon-maskable-512.png` | 512×512 | manifest `maskable` |
| `apple-touch-icon.png` | 180×180 | Apple Home Screen |
| `favicon.ico`/PNG variants | 16–48 | browser tabs |

- `DS-APPICON-001` Derivative MUST berasal dari artwork iOS approved; tidak boleh redesign diam-diam.
- `DS-APPICON-002` Rounded corners MUST NOT dibakar ke image; platform menerapkan mask.
- `DS-APPICON-003` Maskable version MUST memberi padding sehingga semua elemen kritis berada dalam safe zone lingkaran radius 40% dari lebar.
- `DS-APPICON-004` Maskable icon MUST diuji di Chrome DevTools dengan minimum safe area dan beberapa mask shape.
- `DS-APPICON-005` Default icon menjadi baseline. Dark/tinted iOS variants tidak dimasukkan ke manifest tanpa ADR.

Referensi: [web.dev — Adaptive icon support with maskable icons](https://web.dev/articles/maskable-icon).

## 9. Visual quality gates

- Setiap core screen memiliki screenshot baseline compact light/dark, plus wide untuk Admin.
- Perbandingan iOS/web menilai hierarchy, alignment, density, state, dan interaction, bukan pixel diff lintas renderer.
- Tidak boleh ada placeholder icon generik, gradient default, excessive rounded cards, atau nested cards tanpa hierarchy.
- Copy Indonesia diuji untuk wrapping dan zoom besar.
- Semua interactive state diuji keyboard dan pointer/coarse touch.

