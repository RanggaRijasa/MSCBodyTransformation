# Phase 04 Browser Media Compatibility

## Keputusan adapter

| Capability | Jalur utama | Fallback aman | Catatan target |
|---|---|---|---|
| Galeri | `<input type="file">` dengan allowlist MIME | Pesan validasi dan pilih ulang | `capture` hanya hint; tidak dijadikan syarat |
| Kamera foto | `getUserMedia` setelah tombol ditekan | Galeri atau tutup dialog | Memerlukan secure context; track selalu dihentikan |
| Pemindaian QR | `qr-scanner@1.4.2` dari kamera | Decode file gambar QR | Tidak ada input/copy kode mentah |
| Tampilan QR | `uqr@0.1.3` menghasilkan SVG di server | Download visual yang sama | Route privat `no-store`; identifier tidak masuk UI |
| Proses foto | worker, `createImageBitmap`, `OffscreenCanvas` | Canvas/HTML image dengan yield `requestAnimationFrame` | Orientasi dinormalisasi dan metadata dibuang lewat re-encode JPEG |
| Video | HTML `<video controls playsInline>` dan caption Bahasa Indonesia | Alternatif teks dan retry | Resume lokal hanya kenyamanan; keputusan selesai milik server |
| Berbagi | Web Share Level 2 dengan file | Download object URL sementara | Tidak memakai clipboard atau membagikan raw QR |

Target audit adalah Safari iOS/installed PWA, Chrome Android, Chromium desktop,
dan WebKit desktop automation. `getUserMedia` hanya dipanggil dari deliberate
user action. Seluruh akses kamera memiliki state ditolak, tidak tersedia,
tidak ditemukan, error, dan tutup; file picker tetap dapat dibatalkan tanpa
mengubah state yang sudah valid.

## Alasan dan posture dependency QR

`BarcodeDetector` tidak dipilih karena masih limited/experimental dan tidak
memberi baseline yang konsisten pada Safari. Dependency yang disetujui user:

| Package | Version | License | Installed size | Penggunaan |
|---|---:|---|---:|---|
| `qr-scanner` | 1.4.2 | MIT | 536 KB | Decode kamera/file; dimuat dinamis hanya saat scanner dibuka |
| `uqr` | 0.1.3 | MIT | 92 KB | Render SVG QR di server; tidak masuk alur kamera |

Audit production dependency pada 10 Agustus 2026 melaporkan tidak ada
kerentanan diketahui. `qr-scanner` memiliki worker bawaan dan membatasi scan
MSC menjadi 10 kali per detik; callback tetap memvalidasi exact same-origin,
path canonical, panjang, dan karakter token opaque. `uqr` tidak memiliki
runtime dependency. Versi dipin di lockfile. Posture ini harus ditinjau ulang
pada Phase 11 sebelum release karena umur rilis bukan jaminan keamanan.

Referensi capability:

- [MDN: MediaDevices.getUserMedia](https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia)
- [MDN: HTML capture attribute](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Attributes/capture)
- [MDN: BarcodeDetector](https://developer.mozilla.org/en-US/docs/Web/API/BarcodeDetector)
- [WebKit: getUserMedia](https://webkit.org/blog/7763/a-closer-look-into-webrtc/)
- [qr-scanner source and license](https://github.com/nimiq/qr-scanner)
- [uqr source and license](https://github.com/unjs/uqr)

## Image and upload authority

Browser memeriksa ukuran, MIME, magic bytes, kemampuan decode, dimensi,
orientasi, dan hasil JPEG sebelum upload. Hasil full dan thumbnail adalah Blob
di application/infrastructure boundary; domain hanya menerima descriptor
portable.

Setiap adapter upload wajib:

1. meneruskan hasil ke server operation, bukan menulis path pilihan client;
2. menjalankan `sanitizeServerImageUpload` atas bytes aktual sebelum write,
   memvalidasi ulang JPEG hasilnya, lalu memakai byte hasil sanitasi untuk
   object, hash, ukuran, dan receipt;
3. menyelesaikan ownership/RLS dan purpose allowlist di server;
4. mengembalikan receipt dengan `serverValidation: "passed"`;
5. memakai idempotency key, progress monotonik, `AbortSignal`, retry typed,
   dan cleanup orphan;
6. tidak mencatat object path, signed URL, Blob, foto, atau QR mentah.

Supabase lokal membuktikan bucket privat, RLS actor/role, finalize ownership,
MIME/size limit, dan operasi cleanup orphan yang fail-closed. Test cleanup
memakai retention 100 tahun dan menghapus nol object. Implementasi vertical
slice Phase 05–09 wajib memakai port ini; client check tidak pernah disebut
authoritative.

## Video authority

Player menyimpan posisi per enrollment/step di local storage dan merangkum
interval tontonan unik untuk feedback. Lompatan mundur, advance di atas lima
detik per sample, dan event spam tidak menambah interval. Nilai UI selalu
berlabel pratinjau. Completion, threshold, dan poin hanya sah dari protected
server operation sesuai contract backend; browser tidak mengirim status selesai
sebagai kebenaran.

## Budget Phase 04

- QR decoder hanya dynamic import; tidak boleh masuk initial landing bundle.
- Worker image processing dan QR worker berada di luar main interaction path.
- Foto output maksimum 1.600 piksel pada sisi terpanjang, JPEG 8 MiB, dan
  thumbnail maksimum 320 piksel.
- Thumbnail bukti pembayaran hanya dipakai sebagai object URL preview lokal,
  tidak diunggah atau disimpan. Server menyimpan satu JPEG normalized yang
  marker EXIF/IPTC/vendor/comment-nya sudah dibuang ulang.
- Synthetic 640×480 wajib selesai dan tampil dalam 2 detik di Chromium dan
  WebKit automation lokal.
- QR/media lazy chunk masing-masing ditargetkan maksimum 100 KB raw minified;
  budget release Brotli dan Core Web Vitals final diukur ulang Phase 11.
- Tidak ada service-worker/media dependency tambahan pada Phase 04.

## Checklist perangkat fisik untuk Phase 11/13

Checklist ini dicatat sekarang dan tetap menjadi final device gate Phase 11/13:

- iPhone Safari: galeri, kamera depan/belakang, rotasi EXIF, deny lalu retry,
  scan Coach QR, scan dari Photos, caption, background/resume, Share Sheet.
- iPhone installed PWA: secure camera, lifecycle suspend/resume, offline/video
  interruption, object URL setelah reopen, update/logout cache isolation.
- Android Chrome: galeri/capture intent, kamera environment, deny/retry, QR
  kamera/file, caption, Web Share/download.
- Desktop Chromium/Safari: no-camera state, file fallback, keyboard video,
  unsupported media, download visual QR.
- Semua target: QR salah origin/path ditolak, tidak ada input kode manual,
  private response `no-store`, zoom 200%, focus restore, dark mode, Reduce
  Motion, dan tidak ada data sensitif di log/cache.

Automation Phase 04 memberi proof Chromium dan WebKit untuk QR synthetic nyata,
image processing worker/fallback, permission/fallback component states, video,
share/download, route privacy, dan Supabase lokal. Checklist fisik tidak boleh
dianggap lulus sebelum dijalankan pada release candidate Phase 11/13.
