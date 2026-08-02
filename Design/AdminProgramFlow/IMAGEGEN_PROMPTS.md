# Prompt GPT ImageGen

Semua mockup dibuat dengan built-in GPT ImageGen. Screenshot Dashboard Admin
yang sudah diimplementasikan dipakai sebagai referensi visual, bukan target
edit.

## Daftar program

```text
Use case: ui-mockup
Asset type: high-fidelity native iPhone screen for the Admin Program tab in MSC Body Transformation
Primary request: Design a clear, production-ready Program list screen that removes the confusing idea of separate “Tambah program” and “Atur program” menus. There is one Program tab, one primary creation action, and existing programs are opened by tapping their cards.
Input images: Image 1 is a visual style reference for the implemented Admin Dashboard: preserve its native iOS proportions, typography hierarchy, neutral surfaces, restrained black/red/yellow palette, Dynamic Island, top-right information button, and five-item bottom tab bar. Do not edit Image 1.
Style/medium: polished native SwiftUI iOS 26 light-mode interface, Apple San Francisco, neutral #F7F7F8 background, white cards, subtle gray borders, SF Symbols, selective Liquid Glass only on compact shell controls and bottom tab bar.
Composition/framing: full-height straight-on portrait iPhone screenshot. Navigation title “Program”. Top-right circular information button remains. Under the title, place one prominent full-width red button “Buat program baru” with plus icon. Below it, native search field “Cari program”. Then a compact segmented control with “Semua”, “Draft”, “Aktif”, “Riwayat”. Section title “Daftar program” with small count “3 program”. Show three large tappable program cards, each card is one navigation target with a chevron and no duplicate Kelola button:
1. “Transformasi 30 Hari”, green status badge “Aktif”, metadata “12 peserta • Berakhir 31 Agustus 2026”.
2. “Reset Kebiasaan 14 Hari”, yellow status badge “Draft”, progress copy “2 dari 3 tahap selesai” and a restrained progress bar.
3. “Kickstart Sehat”, blue-neutral status badge “Terjadwal”, metadata “Mulai 12 September 2026”.
Each card must make status and next context obvious. Do not split the list into separate Add and Manage menus.
Bottom navigation exact labels: “Dashboard”, “Program”, “Orang”, “Konten”, “Pengaturan”. Program is selected in brand red.
Text (verbatim): “Program”; “Buat program baru”; “Cari program”; “Semua”; “Draft”; “Aktif”; “Riwayat”; “Daftar program”; “3 program”; “Transformasi 30 Hari”; “12 peserta • Berakhir 31 Agustus 2026”; “Reset Kebiasaan 14 Hari”; “2 dari 3 tahap selesai”; “Kickstart Sehat”; “Terjadwal”; “Mulai 12 September 2026”; “Dashboard”; “Program”; “Orang”; “Konten”; “Pengaturan”.
Constraints: Bahasa Indonesia only; sentence case; accurate spelling; generous Dynamic Type-friendly spacing; minimum 44-point-looking touch targets; entire program card appears tappable; red only for primary creation and selected tab; yellow only for draft attention; no separate “Tambah program” menu; no “Atur program” button; no “Kelola program” button; no duplicate plus icons in toolbar and body.
Avoid: desktop dashboard styling, dense tables, tiny metadata, multiple create buttons, separate Add/Manage tiles, swipe-action callouts, full-red backgrounds, gradients, photos, custom fonts, English copy, excessive glass, watermarks, device frame outside the screenshot.
```

## Hub draft

```text
Use case: ui-mockup
Asset type: high-fidelity native iPhone Admin program setup hub for MSC Body Transformation
Primary request: Design the screen shown immediately after Admin creates a new program or taps an existing draft. It must make a single three-step setup flow unmistakable and straightforward: Step 1 program settings, Step 2 program content, Step 3 review and publish. This is a navigation hub, not a long form.
Input images: Image 1 is a visual style reference for the implemented Admin interface. Preserve its native iOS shell, typography, neutral cards, restrained red/yellow accents, and bottom tab bar. Do not edit Image 1.
Style/medium: polished native SwiftUI iOS 26 light-mode screen, Apple San Francisco, system grouped background, white cards with subtle gray borders, SF Symbols, semantic colors, Dynamic Type-friendly.
Composition/framing: full-height portrait iPhone screenshot, straight-on. Show native back button labeled “Program” and centered inline title “Reset Kebiasaan 14 Hari”. Top-right text button “Simpan”. Under navigation, show a compact header card with yellow status badge “Draft”, bold title “Selesaikan 3 tahap”, subtitle “Kamu dapat kembali kapan saja.”, progress “1 dari 3 tahap selesai”, and a thin progress bar.
Below, section title “Alur program”. Show exactly three large numbered navigation cards stacked vertically, each entire card tappable with chevron:
1. Number badge “1”; title “Pengaturan program”; subtitle “Nama, deskripsi, jadwal, peserta, aturan dan poin”; green status label with check icon “Selesai”.
2. Number badge “2”; title “Konten program”; subtitle “Hari, langkah, pertanyaan dan media”; yellow status label with warning icon “Belum lengkap”. Give this card a restrained red border or accent to indicate the next recommended step, but no duplicate CTA.
3. Number badge “3”; title “Tinjau & terbitkan”; subtitle “Pratinjau peserta dan validasi akhir”; gray status label “2 hal perlu diperbaiki”. It remains tappable so Admin can understand what is blocking publication.
Below the cards, show one neutral informational row: “Program belum terlihat oleh peserta sebelum diterbitkan.”
Bottom navigation labels: “Dashboard”, “Program”, “Orang”, “Konten”, “Pengaturan”. Program remains selected in red.
Text (verbatim): “Program”; “Reset Kebiasaan 14 Hari”; “Simpan”; “Draft”; “Selesaikan 3 tahap”; “Kamu dapat kembali kapan saja.”; “1 dari 3 tahap selesai”; “Alur program”; “1”; “Pengaturan program”; “Nama, deskripsi, jadwal, peserta, aturan dan poin”; “Selesai”; “2”; “Konten program”; “Hari, langkah, pertanyaan dan media”; “Belum lengkap”; “3”; “Tinjau & terbitkan”; “Pratinjau peserta dan validasi akhir”; “2 hal perlu diperbaiki”; “Program belum terlihat oleh peserta sebelum diterbitkan.”; “Dashboard”; “Program”; “Orang”; “Konten”; “Pengaturan”.
Constraints: Bahasa Indonesia only; sentence case; exact spelling; clearly numbered sequence; no separate “Tambah program” or “Atur program” menu; no additional editor categories on this hub; no bottom primary button duplicating a step card; each card has one target and one chevron; status uses text plus icon, not color alone; touch targets look at least 44 points.
Avoid: wizard pagination dots, dense forms, six or seven competing menu rows, separate preview menu outside Step 3, separate publish button on this hub, duplicate Continue buttons, desktop styling, full-red backgrounds, gradients, photos, custom fonts, English copy, excessive glass, watermarks, device frame outside screenshot.
```

## Hub program diterbitkan

```text
Use case: ui-mockup
Asset type: high-fidelity native iPhone Admin program management hub for an already-published program in MSC Body Transformation
Primary request: Design the state shown when Admin taps an active published program. Use the same three-part mental model as draft creation, but make published content explicitly read-only to prevent silent changes to schedule, content, rules, or scoring. There must be no separate “Atur program” menu.
Input images: Image 1 is a visual style reference for the implemented Admin interface. Preserve the native iOS shell, neutral surfaces, typography, restrained red/yellow palette, and bottom tab bar. Do not edit Image 1.
Style/medium: polished native SwiftUI iOS 26 light-mode interface, Apple San Francisco, system grouped background, white cards with subtle gray borders, SF Symbols, semantic status badges, Dynamic Type-friendly.
Composition/framing: full-height portrait iPhone screenshot, straight-on. Native back button labeled “Program”; centered inline title “Transformasi 30 Hari”; top-right ellipsis menu button. Header card shows green badge “Aktif”, bold title “Program sudah diterbitkan”, subtitle “Berakhir 31 Agustus 2026”, and a compact metric row “12 peserta” and “Hari ke-18 dari 30”.
Below, show a pale neutral information banner with lock icon and exact copy: “Program aktif tidak dapat diubah langsung. Buat salinan draft untuk menyiapkan versi baru.” Then one clearly secondary outlined button inside or immediately below the banner: “Duplikasikan sebagai draft”.
Section title “Detail program”. Show exactly three large navigation cards using the same structure as the draft hub, all tappable for read-only viewing:
1. Number badge “1”; title “Pengaturan program”; subtitle “Jadwal, peserta, aturan dan poin”; trailing status with lock icon “Diterbitkan”; chevron.
2. Number badge “2”; title “Konten program”; subtitle “30 hari • 84 langkah • 12 pertanyaan”; trailing status with lock icon “Diterbitkan”; chevron.
3. Number badge “3”; title “Status publikasi”; subtitle “Aktif dan terlihat oleh peserta”; green status “Aktif”; chevron.
Below, add a compact destructive-neutral text action “Arsipkan program” separated from the main cards. It must not compete with the duplicate-draft action.
Bottom navigation exact labels: “Dashboard”, “Program”, “Orang”, “Konten”, “Pengaturan”. Program selected red.
Text (verbatim): “Program”; “Transformasi 30 Hari”; “Aktif”; “Program sudah diterbitkan”; “Berakhir 31 Agustus 2026”; “12 peserta”; “Hari ke-18 dari 30”; “Program aktif tidak dapat diubah langsung. Buat salinan draft untuk menyiapkan versi baru.”; “Duplikasikan sebagai draft”; “Detail program”; “1”; “Pengaturan program”; “Jadwal, peserta, aturan dan poin”; “Diterbitkan”; “2”; “Konten program”; “30 hari • 84 langkah • 12 pertanyaan”; “3”; “Status publikasi”; “Aktif dan terlihat oleh peserta”; “Arsipkan program”; “Dashboard”; “Program”; “Orang”; “Konten”; “Pengaturan”.
Constraints: Bahasa Indonesia only; sentence case; exact spelling; same three-part structure as draft hub; read-only state must be obvious through lock icons and text, not disabled low-contrast rows; tapping cards opens readable detail; only one way to start changes, “Duplikasikan sebagai draft”; no “Tambah program”, “Atur program”, or “Kelola program” menu/button; no editing fields on this hub; minimum 44-point-looking targets.
Avoid: disabled gray illegible cards, direct editing of active scoring rules, separate Add/Manage menus, duplicate edit buttons, multiple primary CTAs, dense tables, desktop styling, full-red background, gradients, photos, custom fonts, English copy, excessive glass, watermark, device frame outside screenshot.
```

