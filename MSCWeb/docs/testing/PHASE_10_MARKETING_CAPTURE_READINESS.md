# Kesiapan capture marketing Phase 10

## Surface release candidate

- Peserta: `Papan peringkat` dengan podium/top 5, posisi sendiri, dan program
  aktif. Surface menggunakan komponen produksi `ParticipantRanking`.
- Coach: `Dashboard Coach` dengan metrik, tindakan cepat, program, perhatian,
  aktivitas, dan papan peringkat publik. Surface menggunakan komponen produksi
  `CoachDashboard`.
- Admin tidak dipilih untuk landing karena pengalaman Peserta dan Coach lebih
  mewakili manfaat produk tanpa memerlukan konteks operasional internal.

## Fixture deterministic

- Versi: `phase10-marketing-v1`.
- Data hanya memakai alias `Peserta Demo`, `Peserta Satu`, `Peserta Dua`, dan
  `Coach Demo`.
- Tidak ada berat, QR mentah, bukti transfer, foto privat, signed URL, email,
  nomor HP, token, UUID produksi, atau identifier sensitif.
- Fixture berada di `src/development/marketing-capture-gallery.tsx` dan tidak
  menjadi source data runtime production.

## Parameter reproduksi

| Surface | Viewport | DPR target | Locale | Theme | Build identifier |
| --- | --- | ---: | --- | --- | --- |
| Peserta | 390 × 844 | 2 | `id-ID` | light | `0.1.0-phase10-local` |
| Coach | 1280 × 900 | 1 | `id-ID` | light | `0.1.0-phase10-local` |

Baseline gallery dijalankan pada Chromium dan WebKit dengan animasi
dinonaktifkan. Screenshot final untuk landing baru boleh diambil pada Phase 11
setelah PWA quality gate selesai; fixture dan parameter di atas tidak boleh
diubah tanpa menaikkan versi fixture.
