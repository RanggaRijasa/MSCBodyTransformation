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
| Profil onboarding pertama | `/onboarding/profile` | Exact/Adaptive | nama, HP, level, tujuan Peserta/Ajukan Coach |
| Finalisasi Peserta | `/onboarding/participant/coach` | Adaptive | scan QR browser; provisional account belum aktif |
| Eligibility/pembayaran Coach baru | `/onboarding/coach/*` | Adaptive/Web replacement | iOS hierarchy, manual bank/QRIS web |
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
| Katalog Program Coach | `/coach/programs` | Exact | memakai ulang katalog/flow Participant; bukan daftar program dampingan |
| Review queue | Coach review routes | Exact/Adaptive | filter + action badge |
| Proof review sheet | detail/modal responsive | Exact | sticky Tolak/Setujui |
| Unique Coach QR | Coach QR route | Exact | raw identifier tidak ditampilkan |
| Profil Coach publik | `/c/:handle` | New | public share page; tidak memakai raw QR/UUID |
| Edit profil Coach | `/app/profile` role Coach | Adaptive | field opsional dan kontrol publikasi |
| Bintang Coach manual | insight pada bukti makanan | Web replacement | AI memberi rating; Coach tidak mengisi pada alur normal |
| Macro foto makanan | detail submission/activity | New | hasil asynchronous dan sekunder dari poin |
| Admin dashboard | `/admin` | Exact/Adaptive | attention, quick actions, metrics |
| Sales overview | `/admin/sales` dari Akses cepat | New | internal manual-web analytics; bukan tab utama |
| Image storage | `/admin/image-storage` dari Akses cepat | New | inventory/Sampah/purge user images; bukan tab utama |
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

### 4.5 Profil Coach publik

- `UX-CPR-001` `/c/:handle` MUST dapat dibuka Guest dan menampilkan foto, nama, serta badge `Coach terverifikasi` sebagai identitas wajib.
- `UX-CPR-002` Headline, biografi, kota/area layanan, kontak/sosial, testimoni, dan galeri before–after hanya dirender ketika Coach mengisi dan memublikasikan field tersebut; section kosong MUST tidak meninggalkan card/heading kosong.
- `UX-CPR-003` Tombol `Bagikan profil` MUST memakai Web Share API bila tersedia dan fallback menyalin canonical URL dengan feedback yang dapat diakses.
- `UX-CPR-004` Nomor telepon, WhatsApp, Instagram, TikTok, dan website MUST menjadi link berlabel jelas. Tidak boleh ada icon-only contact row atau kontak yang belum diaktifkan publik.
- `UX-CPR-005` Halaman edit Coach MUST membedakan data otomatis/read-only (badge), data akun (nama), foto yang dapat diganti, field opsional, dan toggle publikasi per kontak.
- `UX-CPR-006` Before–after MUST memakai caption netral, alt text, urutan yang jelas, dan tidak menjanjikan hasil serupa. Testimoni MUST tidak menampilkan identitas subjek melebihi izin publikasinya.
- `UX-CPR-007` Profil tanpa field opsional tetap MUST terlihat lengkap dan profesional melalui identitas wajib, CTA bagikan, serta layout yang tidak terasa kosong.

### 4.6 Insight foto makanan

- `UX-AI-001` Tepat sebelum submit pada pertanyaan foto makanan, UI MUST menampilkan disclosure ringkas: `Foto makanan ini akan dianalisis otomatis oleh layanan AI.` Tidak ada checkbox consent terpisah pada baseline.
- `UX-AI-002` Setelah submission berhasil, status poin/approval tampil lebih dahulu. Card insight terpisah menampilkan `Menganalisis foto…` dan memperbarui hasil tanpa memblokir halaman.
- `UX-AI-003` Hasil MUST menampilkan rating 1–5 dengan icon `Star` Phosphor, estimasi kkal/protein/karbohidrat/lemak, confidence label yang manusiawi bila diperlukan, dan insight non-diagnostik.
- `UX-AI-004` Estimasi MUST dilabeli `Perkiraan dari foto` dan tidak boleh dipresentasikan sebagai pengukuran pasti atau saran medis.
- `UX-AI-005` Provider timeout/failure MUST menampilkan `Analisis belum tersedia` serta retry server-safe bila diizinkan; status submission dan poin yang sudah sah tidak berubah.
- `UX-AI-006` Rating 1–2 MUST disertai alasan rubric yang spesifik dan netral. Hasil ambigu MUST menggunakan 3 atau lebih, bukan menghukum Participant.
- `UX-AI-007` Coach tidak melihat input bintang manual pada alur normal. Aksi koreksi, bila tersedia bagi Coach/Admin, MUST berada di menu sekunder, meminta alasan, dan menjelaskan bahwa poin tidak berubah.
- `UX-AI-008` Insight dan alasan rating MUST ditampilkan dalam Bahasa Indonesia yang natural. Istilah teknis provider, raw JSON, atau kalimat bahasa Inggris MUST tidak terlihat pada UI Participant, Coach, maupun Admin.
- `UX-AI-009` Card insight MUST menampilkan paling banyak dua kalimat pendek. UI MUST tidak memotong kalimat dengan ellipsis; output yang melampaui kontrak diganti server dengan fallback valid sebelum dirender.

### 4.7 Akses cepat dan ringkasan penjualan Admin

- `UX-SLS-001` `Akses cepat` final MUST mempertahankan `Buat program` dan `Tambah poster`, lalu menambahkan `Ringkasan penjualan` dan `Penyimpanan gambar` sebagai intentional web-only extension.
- `UX-SLS-002` Compact final memakai grid 2 × 2 dengan card/action semantics yang sama; wide MAY memakai empat kolom. Kartu tidak boleh dipadatkan menjadi empat kolom sempit pada ponsel atau menggeser `Aktivitas terbaru` ke balik bottom navigation.
- `UX-SLS-003` `/admin/sales` membuka route detail dengan browser history/back dan `Dashboard` tetap menjadi active root; tidak menambah tab utama keenam.
- `UX-SLS-004` Default 30 hari menampilkan KPI penjualan bersih, bruto, pembalikan, order terverifikasi, dan rata-rata order; filter 7/30/90/rentang khusus serta jenis pembelian berada dalam filter surface yang accessible.
- `UX-SLS-005` Tren harian MUST memiliki chart ringkas dan equivalent table/list dengan tanggal serta nilai exact. Color, line/bar height, atau arah panah tidak boleh menjadi satu-satunya pembawa makna.
- `UX-SLS-006` Section minimum: `Ringkasan`, `Tren penjualan`, `Menurut jenis pembelian`, `Program terlaris`, `Pelanggan teratas`, dan `Pipeline order`. Empty/zero/reversal-only data MUST tetap menjelaskan hasil secara jujur.
- `UX-SLS-007` Pelanggan teratas menampilkan nama tampilan, nilai bersih, dan jumlah order; row menuju detail Orang yang sudah authorized. Jangan menampilkan email atau copy seperti `null, null`.
- `UX-SLS-008` Screenshot sales yang diberikan pengguna adalah referensi hierarchy/information density saja. Warna biru, gaya Wix, placeholder image, dan label Inggris MUST tidak disalin; UI mengikuti token hitam-merah-kuning MSC.
- `UX-SLS-009` Program dan pelanggan teratas masing-masing dibatasi lima item dengan tie-break stabil. Duplicate display name tetap menjadi row terpisah berdasarkan opaque ID; deleted/missing profile memakai label `Pengguna dihapus`.

### 4.8 Penyimpanan gambar Admin

- `UX-MED-001` `/admin/image-storage` menampilkan heading `Penyimpanan gambar`, ringkasan bytes/count, breakdown `Bukti program`, `Bukti pembayaran`, dan `Media profil Coach`, lalu segment `Gambar`/`Sampah`.
- `UX-MED-002` Ringkasan MUST dilabeli `Penggunaan gambar pengguna`. Jika quota server tidak tersedia, jangan tampilkan progress `digunakan dari X GB`; tampilkan total dan breakdown saja.
- `UX-MED-003` Wide memakai data table; compact memakai list/card. Keduanya menampilkan thumbnail aman, pemilik, kategori/lokasi manusiawi, ukuran, tanggal, reference/protection status, tanpa filename/object path privat.
- `UX-MED-004` Search menggunakan nama pemilik/program/order label yang aman. Filter minimum: kategori, lifecycle/protected status, rentang tanggal, dan ukuran. Pagination MUST keyset/cursor, bukan offset dalam daftar besar.
- `UX-MED-005` Detail image menunjukkan preview authorized, ringkasan reference/impact, alasan protected bila ada, retention state, dan satu primary contextual action. Private thumbnail/download tidak masuk shared/browser cache.
- `UX-MED-006` `Pindahkan ke Sampah` memerlukan reason dan impact confirmation. `Pulihkan` hanya tersedia sebelum purge. `Hapus permanen` memerlukan confirmation kedua, acknowledgment irreversible, reason, dan jumlah item/bytes.
- `UX-MED-007` Item di Sampah tetap dihitung sebagai `Dapat dibebaskan` sampai purge selesai. Failed job mempunyai status dan retry aman; UI MUST tidak mengklaim ruang bebas sebelum Storage API berhasil.
- `UX-MED-008` Protected/unknown item menonaktifkan deletion dengan alasan actionable. Media publik yang terdampak harus menjelaskan bahwa profil/item akan di-unpublish sebelum quarantine.
- `UX-MED-009` Bukti pembayaran selalu menampilkan label `Dikelola otomatis · retensi 30 hari` dan tidak memiliki tombol Trash/Pulihkan/Hapus permanen. Admin hanya melihat penggunaan, status retensi, dan hasil cleanup.
- `UX-MED-010` Bulk selection hanya muncul pada Sampah atau safe orphan/superseded filter, maksimum 100 item. Select-all page tidak boleh berarti seluruh dataset yang belum dimuat.
- `UX-MED-011` Screenshot Manage Storage yang diberikan pengguna adalah referensi hierarchy/tabs/table saja. Video, paket 50 GB, Wix location, warna biru, dan bulk delete bebas MUST tidak dianggap sebagai contract MSCWEB.
- `UX-MED-012` Public Coach image URL memakai opaque media ID/gateway. UI/API publik tidak merender raw `photo_reference`/`media_object_path`; known legacy direct Storage URL tidak menjadi fallback.

### 4.9 Pendaftaran pertama Peserta atau applicant Coach

- `UX-ONB-001` `/login` tetap satu halaman Google karena provider menentukan existing/new identity setelah callback. Jangan menambahkan role selector pada login; new provisional user baru diarahkan ke `Lengkapi profil`.
- `UX-ONB-002` `/onboarding/profile` MUST menampilkan Nama, Nomor HP, Level Member, dan section `Tujuan akun` dengan radio-card `Lanjut sebagai Peserta` serta `Ajukan menjadi Coach`, mengikuti hierarchy iOS yang diberikan.
- `UX-ONB-003` `Ajukan menjadi Coach` MUST menjelaskan `Lengkapi syarat, pembayaran, dan persetujuan Admin`; tidak boleh memakai copy `Daftar sebagai Coach` atau menyiratkan role langsung aktif.
- `UX-ONB-004` Member menonaktifkan Coach card dan CTA menjelaskan level minimum. Mengubah level merekonsiliasi selected purpose, eligibility, dan harga tanpa menghapus nama/HP.
- `UX-ONB-005` Onboarding memakai focused full-screen route tanpa bottom navigation/app dashboard. Header memiliki native/browser-safe Back dan `Tutup`/`Batalkan pendaftaran`; browser Back tidak boleh melewati route guard ke private app.
- `UX-ONB-006` Jalur Peserta menampilkan `Hubungkan dengan Coach`, penjelasan bahwa akun MSC belum aktif sampai QR dikonfirmasi, tombol `Pindai QR Coach`, confirmed Coach card, `Pindai ulang`, dan CTA `Aktifkan akun Peserta`.
- `UX-ONB-007` Camera denied/unsupported/invalid/expired/unapproved/mismatched QR MUST menampilkan state actionable dan tetap tidak menyediakan input kode manual.
- `UX-ONB-008` Jalur Coach memakai urutan `Syarat Coach` → `Pembayaran Coach` → `Status pengajuan`; reuse W06 eligibility/payment components tetapi mempertahankan onboarding Back/Cancel dan provisional state.
- `UX-ONB-009` Coach payment page MUST menampilkan level, harga server, tiga bulan, tidak auto-renew, rekening/QRIS, upload proof, dan bahwa payment tidak langsung mengaktifkan Coach.
- `UX-ONB-010` Setelah proof submitted, status menunjukkan `Menunggu persetujuan Admin`, `Akun tetap sebagai Peserta`, dan `Menunggu pemeriksaan Admin`; CTA masuk ke Participant app/status. Correction/rejection memberi reason serta resume yang aman.
- `UX-ONB-011` Explicit cancel sebelum proof meminta confirmation dan kembali Guest setelah cleanup. Menutup tab tanpa confirmation MAY melanjutkan draft sampai 24 jam; copy harus jujur dan menyediakan resume/cancel saat login kembali.
- `UX-ONB-012` Web adaptation MUST mengganti copy iOS `akun belum dibuat` menjadi `akun MSC belum aktif` karena Google telah membuat Auth identity provisional. Jangan mengklaim tidak ada account record sama sekali.
- `UX-ONB-013` Existing active account tidak melihat onboarding. Deep link provisional ke `/app`, `/coach`, atau `/admin` selalu replace ke step onboarding yang authoritative tanpa flash private content.

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
