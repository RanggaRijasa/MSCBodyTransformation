# 02 — UX parity, routes, and interaction specification

## 1. Definisi parity

Parity berarti kemampuan, state, prioritas informasi, dan outcome bisnis iPhone tersedia di web. Parity tidak berarti menyalin setiap pixel atau memaksa pola iOS pada desktop.

Label:

- `Exact`: capability dan urutan interaksi sama.
- `Adaptive`: outcome sama, layout/input mengikuti browser dan ukuran layar.
- `Web replacement`: capability iOS diganti sengaja oleh kontrak web.
- `New`: diperlukan khusus PWA/web.

- `UX-001` Tidak ada feature iPhone in-scope yang boleh hilang tanpa baris `Deferred` beserta alasan dan persetujuan eksplisit.
- `UX-002` Screenshot simulator pada [09_SIMULATOR_AUDIT.md](./09_SIMULATOR_AUDIT.md) adalah baseline visual, tetapi data fixture bukan production contract.
- `UX-003` Copy, spacing, hierarchy, enabled/disabled states, dan empty/error behavior dinilai lebih penting daripada efek dekoratif.

## 2. Navigation map

### Guest / Participant compact

Bottom navigation: `Beranda`, `Program`, `Peringkat`, `Coach`, `Profil`.

```text
Beranda
  ├─ program card → detail program
  ├─ fokus → aktivitas relevan
  ├─ top 5 → leaderboard
  ├─ pemenang → winner snapshot
  └─ coach → profil Coach
Program
  ├─ Diikuti → activity program
  ├─ Tersedia → offer → scan QR → pembayaran/enrollment
  └─ Riwayat → completed program
Peringkat
Coach
Profil
```

### Coach compact

Bottom navigation: `Dashboard`, `Program`, `Profil`.

Quick actions dashboard: `Periksa bukti`, `Peserta saya`, `Aktivitas terbaru`, `Peringkat`, `Program saya`, `QR pendaftaran`.

### Admin compact

Bottom navigation: `Dashboard`, `Program`, `Orang`, `Konten`, `Pengaturan`.

Pada wide screen, bottom navigation diganti navigation rail/sidebar. Nama destination dan authority tidak berubah.

- `UX-NAV-001` Bottom bar MUST berada di safe area, tetap terbaca di light/dark mode, dan tidak menutupi CTA/content terakhir.
- `UX-NAV-002` Selected destination MUST ditunjukkan dengan icon, label, dan visual state; tidak melalui warna saja.
- `UX-NAV-003` Header compact MUST mengutamakan title, back, dan maksimal dua primary contextual actions; tindakan lain masuk menu yang accessible.
- `UX-NAV-004` Admin wide MUST memakai layout tabel/list atau dua-pane bila data density membutuhkannya, bukan grid card berlebihan.

## 3. Parity matrix

| Area iPhone | Web route/surface | Parity | Catatan |
|---|---|---|---|
| Debug role picker | dev-only scenario tools | Adaptive | tidak masuk production bundle |
| Guest Home | `/app/home` tanpa session | Exact | tidak hydrate data privat |
| Login | `/login` | Web replacement | hanya Google |
| Participant Home | `/app/home` | Exact/Adaptive | urutan Program, Fokus, Top 5, Pemenang, Coach |
| Katalog Program | `/app/programs` | Exact | segment Diikuti/Tersedia/Riwayat |
| Detail/offer Program | `/app/programs/:id` | Exact | state/CTA mengikuti entitlement |
| Scan QR Coach | modal/screen nested program | Adaptive | camera browser, tanpa manual code |
| StoreKit purchase | `/app/payments/:id` | Web replacement | rekening + QRIS + proof upload |
| Day accordions | detail program/activity | Exact | hari relevan dibuka/di-scroll |
| Step detail | activity route | Exact | form/media/state |
| Photo picker/camera | browser picker/capture | Adaptive | normalisasi dan privacy sama |
| Leaderboard/winners | `/app/leaderboard` | Exact | tanpa berat privat |
| Coach dashboard | `/app/home` role Coach | Exact/Adaptive | quick actions sama |
| Review queue | Coach review routes | Exact/Adaptive | filter + action badge |
| Proof review sheet | detail/modal responsive | Exact | sticky Tolak/Setujui |
| Unique Coach QR | Coach QR route | Exact | raw identifier tidak ditampilkan |
| Admin dashboard | `/admin` | Exact/Adaptive | attention, quick actions, metrics |
| Admin Program | `/admin/programs` | Adaptive | search/list; wide table bila efektif |
| Admin People | `/admin/people` | Exact/Adaptive | Peserta/Coach/Admin |
| Coach application review | `/admin/coach-applications/:id` | Adaptive | payment + eligibility + audit |
| Admin Content | `/admin/content` | Exact/Adaptive | shared renderer untuk preview |
| Settings | `/admin/settings` | Adaptive | web/environment settings yang relevan |
| PWA installation | browser/landing affordance | New | platform-specific guidance |
| Offline shell | global | New | read-only cached shell/status, bukan fake success |

## 4. Screen contracts

### 4.1 Home Participant

- `UX-HOME-001` Urutan section MUST: program, fokus, leaderboard Top 5, pemenang, Coach.
- `UX-HOME-002` Program dapat menggunakan horizontal snap carousel pada compact; harus ada keyboard/assistive alternative untuk berpindah item.
- `UX-HOME-003` Fokus MUST memprioritaskan aktivitas yang actionable hari ini dan menjelaskan lock/pending state.
- `UX-HOME-004` Angka progress, poin, rank, dan berat MUST memakai tabular/monospaced digit equivalent.

### 4.2 Katalog dan aktivitas program

- `UX-PRG-001` Segment control MUST keyboard-operable dan memberi semantics tab/tablist yang benar di web.
- `UX-PRG-002` Poster/card MUST memiliki satu primary click target; nested actions tidak boleh menghasilkan ambiguous focus.
- `UX-PRG-003` Day accordion MUST mendukung Enter/Space, mengumumkan expanded state, dan mempertahankan scroll restoration.
- `UX-PRG-004` CTA sticky pada compact MUST memperhitungkan bottom nav, virtual keyboard, dan `env(safe-area-inset-bottom)`.

### 4.3 Review evidence

- `UX-REV-001` Queue MUST menampilkan siapa, program, hari/step, usia submission, dan status tanpa membuka media privat di thumbnail yang tidak perlu.
- `UX-REV-002` Detail MUST menampilkan konteks sebelum media, lalu action area yang tidak tertutup viewport.
- `UX-REV-003` Reject MUST meminta alasan sebelum mutation.
- `UX-REV-004` Double click, refresh, atau retry MUST NOT menghasilkan keputusan ganda.

### 4.4 Pembayaran

- `UX-PAY-001` Rekening dan QRIS MUST berasal dari active payment destination server, bukan hardcoded component.
- `UX-PAY-002` Nominal, order ID, subject pembelian, dan instruksi MUST terlihat sebelum pengguna memilih file.
- `UX-PAY-003` Copy nomor rekening MUST memakai tombol dengan feedback; informasi tetap selectable dan screen-reader friendly.
- `UX-PAY-004` QRIS static image MUST memiliki alternative text dan tombol download/open image bila ukuran layar kecil.
- `UX-PAY-005` Setelah upload, pengguna MUST melihat thumbnail aman, nama/ukuran file, pernyataan pemeriksaan manual, dan tombol kirim eksplisit.
- `UX-PAY-006` Pending screen MUST tidak menjanjikan waktu approval yang belum ditetapkan.

## 5. Responsive behavior

Breakpoint logical baseline:

| Mode | Lebar | Navigation | Content behavior |
|---|---:|---|---|
| Compact | `< 768 px` | bottom navigation | single column, mobile sheets/full-screen detail |
| Medium | `768–1199 px` | rail bila ruang cukup | centered content, split view selektif |
| Wide | `>= 1200 px` | sidebar | max content width, two-pane/table untuk operasi |

- `UX-RSP-001` Breakpoint adalah token dan MAY dituning setelah device testing; feature tidak boleh memiliki angka breakpoint acak.
- `UX-RSP-002` Participant/Coach content SHOULD tetap fokus dan tidak melebar tanpa batas.
- `UX-RSP-003` Admin wide SHOULD menampilkan list dan detail bersamaan jika ini mengurangi context switching.
- `UX-RSP-004` Orientation change dan browser resize MUST tidak kehilangan draft form atau selected entity.
- `UX-RSP-005` Minimum supported viewport adalah 320 CSS px, tanpa horizontal scrolling untuk core flow.

## 6. Gesture dan motion behavior

- `UX-GST-001` Swipe MAY dipakai untuk carousel, dismiss, atau contextual action hanya jika ada control alternatif yang terlihat/terjangkau keyboard.
- `UX-GST-002` Web MUST NOT membuat full-screen custom edge-swipe yang bersaing dengan gesture Back browser/iOS.
- `UX-GST-003` Pull-to-refresh MAY dipakai bila reliable; tombol retry/refresh tetap wajib pada error/empty state.
- `UX-GST-004` Dialog destructive atau approval tidak boleh dismiss karena swipe/escape ketika mutation sedang berjalan.
- `UX-GST-005` Reduced Motion MUST mengganti spring/slide besar dengan fade/instant state yang tetap menjelaskan perubahan.

## 7. Browser semantics

- Gunakan semantic heading berurutan, `button` untuk actions, `a` untuk navigation, dan actual form controls pada web output.
- Focus ring tidak boleh dihapus; token focus harus kontras pada semua surface.
- Modal/sheet harus mengunci focus, memiliki accessible name, dan mengembalikan focus ke trigger.
- Scroll restoration harus diuji pada tab switch, modal close, browser back, dan deep link.

