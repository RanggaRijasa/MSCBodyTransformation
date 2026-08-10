# Phase 00 Manual Commerce Decisions

> Dicatat: 10 Agustus 2026
>
> Owner keputusan: pengguna
>
> Status: FINAL — seluruh keputusan produk manual commerce ditutup

Dokumen ini merekam jawaban produk untuk transfer manual program dan akses
Coach. Dokumen tidak berisi nomor rekening, gambar QRIS asli, credential,
atau data privat.

## 1. Tujuan pembayaran

Keputusan:

- Satu tujuan pembayaran aktif atas nama pemilik atau badan usaha resmi.
- Hanya Admin yang ditunjuk yang boleh mengubah tujuan pembayaran.
- Setiap perubahan membuat versi baru dengan effective date.
- Payment order lama mempertahankan snapshot tujuan pembayaran lama.
- Instruksi dapat menampilkan detail rekening dan gambar QRIS statis.
- QRIS adalah gambar pembayaran biasa, bukan dynamic QR, payment gateway,
  callback otomatis, atau verifikasi otomatis.
- Pengguna tetap melakukan pembayaran manual lalu mengunggah bukti.

Implikasi contract:

- `payment_destination` memuat versi, effective window, nama bank/pemilik,
  reference aman, dan optional protected QRIS image reference.
- Perubahan QRIS membuat versi destination/asset baru; jangan menimpa asset
  yang masih direferensikan order lama.
- Client tidak boleh menentukan destination version sendiri.
- QRIS hanya ditampilkan pada order yang sah; jangan memasukkannya ke fixture,
  log, analytics, atau source repository.

## 2. Nominal

Keputusan:

- Mata uang IDR.
- Tidak memakai nominal unik pada MVP.
- Nominal sama dengan harga normal program atau akses Coach.
- Amount dan destination disnapshot pada saat payment order dibuat.
- Admin tetap mencocokkan nominal dan bukti secara manual.

## 3. Reservasi program

Keputusan:

- Paid payment order mereservasi satu kursi selama 24 jam.
- Jika tidak ada bukti yang disubmit sebelum expiry, reservation dilepas.
- Bukti yang disubmit sebelum expiry mempertahankan reservation selama review
  Admin, meskipun pemeriksaan terjadi setelah 24 jam.
- Approval tetap harus memeriksa capacity, order version, payment state, dan
  enrollment state secara atomik.

Keputusan late transfer:

- transfer setelah reservation expiry tidak mengaktifkan peserta otomatis;
- bila kursi masih tersedia, Admin boleh memulihkan order melalui protected
  operation lalu melanjutkan pemeriksaan;
- bila program sudah penuh, Admin menolak order;
- dana yang sudah masuk pada order yang ditolak dikembalikan melalui
  exceptional reversal maksimal tujuh hari kerja;
- seluruh pemulihan, penolakan, dan pengembalian dicatat dalam audit.

## 4. Koreksi dan penolakan pembayaran

Keputusan:

- Admin menentukan hasil pemeriksaan dan wajib memberi alasan saat menolak.
- Peserta tidak diminta memilih kategori masalah teknis yang membingungkan.
- Reason Admin harus menghasilkan instruksi yang jelas: unggah ulang, tambah
  pembayaran, hubungi bantuan, atau pembayaran tidak dapat diverifikasi.
- Kekurangan/kelebihan/salah tujuan tidak diselesaikan otomatis oleh client.
- Tidak ada approval otomatis hanya dari OCR, QRIS, nama file, atau gambar.

Keputusan retry yang mengikuti rekomendasi:

- maksimal tiga evidence attempts per payment order;
- satu unggahan awal dan dua perbaikan;
- setiap submitted attempt immutable;
- setelah penolakan, pengguna mendapat waktu 24 jam untuk attempt berikutnya.

## 5. Refund dan cancellation

Keputusan pengguna:

- Tidak ada participant-initiated refund setelah pembayaran disetujui.
- Pembayaran yang sudah disetujui bersifat final/off-limits.
- Tidak ada menu atau flow `Ajukan refund` bagi Peserta/Coach.
- Pengecualian hanya bila Admin menolak pembayaran karena masalah seperti
  nominal, tujuan, duplikasi, atau bukti yang tidak dapat diverifikasi.
- Koreksi/rejection selalu disertai alasan agar peserta memahami tindak lanjut.

Contract harus tetap menyimpan internal exceptional resolution/reversal state
untuk koreksi Admin, kewajiban hukum, duplicate payment, program yang tidak
dapat dipenuhi, atau kesalahan operasional. State tersebut bukan fitur refund
yang dapat dipicu client.

Exceptional reversal yang disetujui:

- bila Admin menolak tetapi dana terbukti sudah masuk, dana dikembalikan;
- transfer ganda: pembayaran tambahan dikembalikan;
- kelebihan transfer: selisih dikembalikan;
- program dibatalkan MSC atau tidak dapat disediakan: dana dikembalikan;
- program penuh setelah late transfer: dana dikembalikan;
- target penyelesaian maksimal tujuh hari kerja;
- hanya Admin/owner yang berwenang dapat mencatat proses dan penyelesaian;
- tidak ada transfer balik otomatis dari aplikasi.

Exceptional reversal bukan participant-initiated refund. Pembatalan oleh
peserta setelah payment approval tetap tidak memperoleh refund.

Kebijakan `no refund` wajib terlihat sebelum pengguna membayar dan harus
melalui review legal/consumer-protection sebelum production. Pencatatan ini
bukan penilaian bahwa setiap penerapan `no refund` pasti sah untuk semua
skenario.

Referensi legal resmi:

- UU Pelindungan Data Pribadi:
  https://peraturan.bpk.go.id/Details/229798/uu-no-27-tahun-2022
- UU Perlindungan Konsumen:
  https://peraturan.bpk.go.id/Home/Details/45288/uu-no8-tahun-1999

## 6. File bukti pembayaran

Keputusan yang mengikuti rekomendasi:

- input JPEG/JPG, PNG, WebP, atau HEIC/HEIF;
- maksimal 10 MB sebelum pemrosesan;
- hasil normalisasi maksimal sekitar 5 MB;
- metadata lokasi dan metadata yang tidak dibutuhkan dihapus;
- PDF tidak didukung pada MVP;
- bucket privat terpisah dari media program;
- bukti, thumbnail, dan signed URL tidak masuk service worker cache, public
  HTML, log, analytics, fixture, atau screenshot.

## 7. Retention

Keputusan:

- Bukti pembayaran program dihapus 30 hari setelah program selesai.
- Cleanup mencakup original, normalized image, thumbnail, dan orphan object.
- Minimal payment ledger/event tetap disimpan terpisah dari gambar untuk
  audit sesuai policy legal/accounting yang kemudian disetujui.
- Account deletion tidak boleh menghapus bukti yang masih memiliki order,
  review, sengketa, atau retention window aktif.

- Bukti pembayaran akses Coach dihapus 30 hari setelah masa akses Coach
  berakhir.
- Untuk renewal Coach, setiap order/evidence memakai retention anchor dari
  access period yang dihasilkan oleh order tersebut.

## 8. Pemeriksaan Admin

Keputusan:

- Tidak ada SLA berbasis jam/hari yang dijanjikan kepada pengguna.
- Admin dapat memeriksa kapan pun.
- Untuk program terjadwal, pembayaran harus diputuskan sebelum program mulai.
- UI tidak menampilkan estimasi `1 × 24 jam`.

Copy baseline:

```text
Menunggu pemeriksaan Admin

Bukti pembayaranmu sudah diterima. Status akan diperbarui setelah Admin
menyelesaikan pemeriksaan.
```

Untuk program terjadwal, system harus memberi prioritas/attention kepada order
yang mendekati waktu mulai. Jika bukti dikirim terlalu dekat dengan waktu
mulai, UI tidak boleh menjanjikan pemeriksaan tepat waktu.

## 9. Coach application dan access

Keputusan yang mengikuti rekomendasi:

- Admin menerima eligibility sebelum applicant diminta membayar.
- State setelah acceptance adalah `accepted_pending_payment` atau stable value
  setara yang disepakati contract.
- Bukti pembayaran yang ditolak tidak membatalkan accepted eligibility.
- Pembayaran terverifikasi dan approval Coach tetap dua state terpisah.
- Akses Coach berlaku tiga bulan kalender sejak aktivasi.
- Tidak ada auto-renew.
- Renewal sebelum expiry memperpanjang dari expiry yang ada.
- Renewal setelah expiry dimulai dari aktivasi baru.
- Setelah akses Coach berakhir, akun tetap memiliki akses Peserta.
- Tidak ada grace period Coach tanpa renewal terverifikasi.

## Product gate closure

Owner mengonfirmasi seluruh klarifikasi pada 10 Agustus 2026:

- late transfer dapat dipulihkan Admin hanya bila kursi tersedia;
- late transfer yang tidak dapat dipenuhi ditolak dan dananya dikembalikan;
- exceptional reversal selesai maksimal tujuh hari kerja;
- bukti pembayaran Coach dihapus 30 hari setelah access period berakhir.

Product decision gate manual commerce sudah ditutup. Phase 00 secara
keseluruhan tetap `BELUM DIMULAI` sampai inventory, parity, contract
reconciliation, migration plan, dan verification phase benar-benar dikerjakan.

## Dampak implementasi

- Tidak ada migration atau hosted mutation pada Phase 00.
- Phase 06 membuat schema additive dan menguji semuanya pada Supabase lokal.
- Hosted `main` hanya menerima forward migration setelah backup, approval
  production, security review, dan post-deploy verification.
- StoreKit/Apple objects tetap legacy selama transisi dan tidak dihapus oleh
  keputusan ini.
