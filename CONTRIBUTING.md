# Panduan kontribusi

## Ruang lingkup

- Kerjakan satu file fase workplan pada satu waktu.
- Baca `AGENTS.md`, `00_START_HERE.md`, dan `UI_REFERENCE_SHEET.md` sebelum
  mengubah kode atau UI.
- Jangan mengerjakan item fase berikutnya tanpa perluasan scope yang eksplisit.

## Format dan penamaan

- Gunakan Swift API Design Guidelines dan nama yang menjelaskan intent.
- Gunakan empat spasi untuk indentasi Swift.
- Pisahkan View, state, service, repository, dan model berdasarkan tanggung
  jawabnya.
- Gunakan `UpperCamelCase` untuk tipe dan `lowerCamelCase` untuk property,
  fungsi, serta test.
- Nama test harus menjelaskan perilaku yang diverifikasi.
- Gunakan nilai raw enum yang stabil dan machine-readable.
- Gunakan `Decimal` untuk kalkulasi berat kanonis dan `Int` untuk poin atau
  kuota peserta.

## Bahasa dan UI

- Semua copy production-facing menggunakan Bahasa Indonesia.
- Tambahkan copy reusable ke `Resources/Localizable.xcstrings`.
- Gunakan locale `id-ID` dan native `FormatStyle`.
- Gunakan semantic colors dari Asset Catalog; jangan menulis nilai hex di View.
- Pertahankan Dynamic Type, light/dark mode, dan touch target minimal 44 poin.

## Dependency dan privasi

- Utamakan framework native Apple.
- Jangan menambah package pihak ketiga tanpa persetujuan eksplisit.
- Jangan menyimpan password, token, API key, URL privat, data berat badan,
  atau path media pribadi di source, log, fixture, screenshot, maupun contoh.
- File lokal berisi secret harus menggunakan pola yang sudah diabaikan oleh
  `.gitignore`.
- Jangan mencatat data pribadi melalui `OSLog`.

## Verifikasi perubahan

Jalankan build simulator terkecil yang relevan, unit test terfokus, dan UI test
bila alur tampilan berubah. Catat command serta hasilnya pada progress log fase
sebelum mencentang checklist.
