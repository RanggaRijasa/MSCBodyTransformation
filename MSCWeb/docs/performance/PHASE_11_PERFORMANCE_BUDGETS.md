# Budget performa Phase 11

Baseline ini diukur dari build production lokal Node 24.19.0 dan Next.js 16.3.0. Gate artefak dijalankan oleh `scripts/check-phase11-performance.mjs`; Web Vitals diuji oleh `tests/e2e/phase11-pwa-quality.spec.ts` pada Chromium dengan viewport 390 × 844, CPU 4× lebih lambat, latensi 150 ms, unduh 200 KB/detik, dan unggah 80 KB/detik.

| Area | Budget | Hasil kandidat rilis |
| --- | ---: | ---: |
| Landing JS + CSS | ≤ 280 KiB gzip | 98,1 KiB |
| Peserta JS + CSS | ≤ 300 KiB gzip | 108,0 KiB |
| Coach JS + CSS | ≤ 300 KiB gzip | 99,8 KiB |
| Admin JS + CSS | ≤ 300 KiB gzip | 107,8 KiB |
| Screenshot Peserta | ≤ 100 KiB | 59 KiB |
| Screenshot Coach | ≤ 200 KiB | 155,1 KiB |
| LCP landing | ≤ 4,5 detik | Lulus gate otomatis |
| CLS landing | ≤ 0,1 | Lulus gate otomatis |
| INP interaksi FAQ | ≤ 300 ms | Lulus gate otomatis |
| Panggilan API landing | 0 | 0 |

Gambar produk memakai dimensi intrinsik, `sizes`, dan pemuatan lazy kecuali gambar LCP hero. Media privat tidak menggunakan CDN publik. Daftar program/Admin dibatasi server, leaderboard memakai pagination, dan uji volume database Phase 10 tetap menjadi bukti skala sumber data.

Regresi budget adalah blocker Phase 11. Perubahan material pada UI landing wajib menjalankan ulang build, gate performa, visual snapshot, serta capture kandidat rilis bila tampilan produk yang ditampilkan berubah.
