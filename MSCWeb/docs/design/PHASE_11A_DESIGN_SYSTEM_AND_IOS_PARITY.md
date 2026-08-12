# Phase 11A Design System and iOS Parity Contract

## Prinsip utama

Redesign ini adalah visual reset penuh. Fungsi MSCWeb dipertahankan, tetapi
visual lama bukan constraint. Aplikasi iPhone aktual menjadi reference untuk
pengalaman mobile; Tailwind CSS dan shadcn/ui menjadi fondasi implementasi web.

`Sama dengan iPhone` berarti hierarchy, information architecture, terminology,
navigation model, component intent, spacing rhythm, prominence, state, dan
interaction outcome terasa sebagai produk yang sama. Ini bukan permintaan
menyalin pixel SwiftUI atau API Apple yang tidak tersedia di browser.

## Prioritas fidelity

| Prioritas | Harus sama | Boleh diadaptasi |
|---:|---|---|
| 1 | Fungsi, state, role, authorization, privacy | Tidak ada |
| 2 | Struktur layar, urutan informasi, action hierarchy | URL dan browser back |
| 3 | Mobile shell, tab, sheet, dialog, status, form | Native browser control bila lebih aman |
| 4 | Brand, type scale, spacing, radius, icon intent | Rendering font dan subpixel |
| 5 | Motion dan glass hierarchy | Capability, performance, accessibility |
| 6 | Desktop expansion | Kolom, sidebar, table, detail pane |

Setiap adaptasi dicatat pada parity ledger dengan alasan, bukti, dan approval.

## Mobile app contract

- Viewport ponsel adalah acceptance surface utama untuk semua role, termasuk
  Admin.
- Gunakan full-height application shell, safe-area top/bottom, sticky/native-
  feeling bars, bottom navigation sesuai role, dan content rail tanpa frame
  iPhone dekoratif.
- Browser mode dan installed PWA harus tetap usable. Standalone boleh terasa
  lebih imersif, tetapi fungsi tidak boleh berbeda.
- Route transition tidak boleh mengorbankan browser back, deep link, scroll
  restoration, focus, atau reduced motion.
- Modal intent iPhone dipetakan ke Dialog, Drawer, Sheet, Popover, atau page
  berdasarkan ruang dan aksesibilitas—bukan berdasarkan efek visual saja.
- Touch target minimum 44 x 44 CSS px dan primary action harus mudah dijangkau.

## Admin responsive contract

Mobile Admin mengikuti iPhone reference secara langsung. Pada ruang yang lebih
lebar, layout boleh berubah dari satu kolom menjadi sidebar, master-detail,
editor split view, atau data table bila manfaatnya jelas.

Responsive expansion tidak boleh:

- mengganti terminology, status, action order, atau business flow;
- menyembunyikan guard, reason, audit, atau confirmation;
- memperkenalkan dashboard template generik yang tidak berhubungan dengan
  desain mobile;
- membuat versi mobile dan desktop memakai token/component family berbeda.

## Liquid Glass adaptation

Glass dipakai hanya pada surface yang di iPhone berfungsi sebagai navigation,
compact floating control, transient overlay, atau grouped interactive chrome.

- Gunakan semantic token `glass-*`, bukan hard-coded blur per feature.
- `backdrop-filter` hanya enhancement; fallback harus opaque, kontras, dan
  tetap menunjukkan hierarchy.
- Hormati `prefers-reduced-motion`, forced colors, increased contrast, dan
  kebutuhan reduced transparency melalui fallback yang diuji.
- Jangan meletakkan glass pada semua card, long-form content, table row, atau
  form field.
- Teks, focus ring, status, dan disabled state harus terbaca tanpa bergantung
  pada background yang blur.
- Motion harus singkat, purposeful, cancellable, dan tidak menghalangi input.

## Fondasi Tailwind CSS

- Tailwind mengonsumsi semantic CSS variables; feature tidak memakai arbitrary
  brand hex atau magic spacing sebagai kebiasaan.
- Token minimum: background/surface/elevated, foreground/muted, primary,
  achievement, destructive, success/warning/info, border/input/ring, chart,
  overlay, dan glass.
- Dark mode adalah token mapping, bukan filter/inversion.
- Class dinamis harus statically discoverable atau dipetakan eksplisit agar
  production build tidak kehilangan style.
- Responsive utilities mengikuti content need dan acceptance viewport, bukan
  device name yang diasumsikan.
- Global CSS dibatasi untuk reset, tokens, base semantics, safe-area helpers,
  dan primitive yang benar-benar global.
- Tailwind Preflight tidak diaktifkan tanpa audit karena form Admin/Payments
  existing masih memiliki banyak raw `input`, `select`, dan `textarea`.
- Token bridge dari legacy ke semantic shadcn/Tailwind harus satu arah; jangan
  membuat variable alias yang saling merujuk.

## Fondasi shadcn/ui

shadcn adalah source component yang dimiliki project, bukan tema siap pakai.
Komponen harus disesuaikan ke MSC tokens dan iPhone interaction contract.

- Jalankan `shadcn info`, `search`, dan `docs` pada versi aktual sebelum add.
- `shadcn init` pertama dijalankan pada salinan disposable untuk menginspeksi
  config/CSS/dependency yang ditulis. Repo utama menerima patch yang sudah
  direview, bukan init eksperimen tanpa rollback.
- Setelah init gunakan CLI info JSON, add dry-run, dan diff sebelum add.
- Base UI adalah kandidat awal yang harus dibuktikan pada compatibility spike;
  ganti base hanya bila Dialog/Sheet, focus, history, WebKit, atau test gate
  menunjukkan alasan teknis yang terdokumentasi.
- Tambahkan hanya primitive yang dipakai dalam slice aktif.
- Pertahankan semantics, keyboard interaction, focus management, ARIA, dan
  composition pattern primitive.
- Feature menyusun shared primitives; jangan copy komponen registry ke setiap
  role.
- Jangan memodifikasi primitive menjadi API raksasa dengan puluhan prop role-
  specific.

Candidate families, bukan daftar instalasi otomatis:

```text
button, input, textarea, label, select, checkbox, radio-group
dialog, drawer/sheet, alert-dialog, popover, dropdown-menu
tabs, navigation-menu, breadcrumb, command, tooltip
card, badge, progress, skeleton, separator, avatar
table/data-list, pagination, toast, form message
```

Primitive final ditentukan oleh compatibility spike dan kebutuhan nyata.

## Component architecture

```text
src/shared/ui/primitives/     -> shadcn-owned low-level components
src/shared/ui/components/     -> MSC reusable composed components
src/shared/layout/            -> app shell, bars, rails, safe-area
src/styles/                   -> tokens, base, motion, glass
src/features/*/components/    -> feature composition only
src/features/*/styles/        -> exceptional scoped CSS only
```

Component families yang wajib konsisten:

- `AppTopBar`, `AppTabBar`, `AppPage`, `AppSection`, `AppActionBar`;
- `PrimaryAction`, `SecondaryAction`, `DestructiveAction`, `IconAction`;
- `StatusBadge`, `StatusPanel`, `MetricCard`, `ProgressSummary`;
- `FormField`, `ValidationSummary`, `SearchField`, `FilterSheet`;
- `LoadingState`, `EmptyState`, `ErrorState`, `OfflineState`, `DeniedState`;
- `UserAvatar`, `MediaPreview`, `UploadField`, `PrivateMediaGuard`;
- `ResponsiveDataList`, `AdminTable`, `DetailPanel`, `ConfirmationDialog`.

Nama final boleh berubah setelah audit existing component. Responsibility dan
boundary-nya tidak boleh digabung menjadi satu file raksasa.

## Typography, color, dan content

- Bahasa UI tetap Indonesia dan locale `id-ID`.
- Brand utama tetap hitam/near-black, merah, dan kuning; semantic state tidak
  boleh dipaksa memakai brand color yang salah makna.
- Red adalah primary action/active emphasis. Yellow untuk achievement dan
  perhatian terbatas dengan foreground yang cukup kontras.
- Gunakan type scale yang jelas untuk large title, screen title, section,
  card, body, callout, caption, dan numeric data.
- Angka poin, peringkat, berat, waktu, dan uang memakai tabular numerals.
- Copy tidak boleh ditulis ulang untuk terlihat modern jika maknanya berubah.

## Concept-first workflow

Sebelum coding visual:

1. Capture reference iPhone yang nyata dan deterministik.
2. Buat ImageGen concept terpisah untuk landing, mobile shell, web glass,
   component language, dan Admin desktop expansion.
3. Tampilkan satu surface/state per gambar yang masih dapat dibaca.
4. Catat apa yang exact parity dan apa yang deliberate adaptation.
5. Dapatkan approval owner; concept yang diterima menjadi production spec.

ImageGen tidak boleh membuat screenshot produk palsu, fitur baru, copy baru,
atau data privat. Production UI selalu code-native HTML/CSS/React.

## Screenshot landing

Screenshot aplikasi PWA pada landing tetap boleh berupa placeholder selama
redesign berjalan. Placeholder wajib berlabel `Pratinjau aplikasi`, memakai
aspect ratio tetap, data generik, dan tidak dipakai sebagai bukti produk final.

Replacement hanya dilakukan setelah layar PWA hasil redesign:

- lulus functional dan visual regression;
- dicapture dari browser/PWA aktual pada fixture aman;
- bebas PII, private URL, QR mentah, berat, evidence, dan metadata;
- dipilih owner untuk Peserta, Coach, dan Admin bila Admin ditampilkan.

## Performance dan React contract

- Server Component tetap default; jangan menambah `use client` hanya karena
  primitive tersedia.
- Direct import dan route-level splitting dijaga; hindari barrel besar pada
  code path browser.
- Data independen dimuat paralel dan tidak dibuat waterfall oleh redesign.
- Provider/context tidak membungkus seluruh produk bila hanya satu surface
  memerlukannya.
- Animation, icon set, chart, editor, dan command palette memiliki bundle
  review sebelum diterima.
- Budget Phase 11 hanya boleh berubah dengan bukti dan approval, bukan karena
  UI library otomatis menambah berat.
- Tambahkan regression budget maksimal +10 KiB gzip per representative route
  dan +5 KiB global CSS dari clean baseline tanpa approval.

## Fidelity review

Setiap surface dianggap selesai setelah reviewer membandingkan:

1. accepted concept;
2. screenshot iPhone reference yang relevan;
3. screenshot rendered PWA pada viewport target;
4. state/interaction test dan parity ledger.

Reviewer memberi nilai per hierarchy, spacing, typography, color, component,
interaction, responsive behavior, accessibility, dan polish. Closure target
adalah tidak ada selisih material yang tidak terdokumentasi dan quality bar
agency-grade, bukan sekadar snapshot test hijau.
