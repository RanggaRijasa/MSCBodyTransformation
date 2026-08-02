# UI Reference Sheet
## Bahasa, Warna, Tipografi, dan Tampilan Adaptif

Dokumen ini adalah referensi visual utama untuk seluruh layar aplikasi MSC Body Transformation.

Codex dan coding agent lain wajib membaca dokumen ini sebelum membuat atau mengubah UI.

## 1. Bahasa Utama

Bahasa utama aplikasi adalah **Bahasa Indonesia**.

Aturan:

- Semua teks production-facing menggunakan Bahasa Indonesia.
- Gunakan gaya bahasa yang jelas, ramah, singkat, dan tidak menghakimi.
- Gunakan sentence case, bukan Title Case pada setiap kata.
- Hindari campuran Bahasa Indonesia dan Inggris kecuali:
  - Nama produk.
  - Nama framework atau teknologi.
  - Istilah yang memang menjadi nama fitur resmi.
- Gunakan istilah yang konsisten pada semua layar.
- Jangan memakai kata-kata yang memberi diagnosis medis.
- Jangan menjanjikan hasil penurunan berat badan tertentu.
- Gunakan `Localizable.xcstrings` sejak awal meskipun MVP baru memiliki satu bahasa.
- Jangan menulis copy reusable langsung berulang kali di dalam View.
- Seluruh UI yang dimiliki aplikasi tetap memakai locale `id-ID` walaupun
  bahasa perangkat bukan Bahasa Indonesia. UI yang sepenuhnya dimiliki sistem,
  seperti pemilih Foto atau dialog izin, boleh mengikuti bahasa perangkat.
- Istilah Inggris hanya dipakai untuk nama produk, teknologi, atau istilah
  fitur yang memang disetujui; jangan membiarkan bahasa perangkat mengubah
  copy aplikasi menjadi bahasa lain atau menampilkan localization key.

### Istilah utama

| Konsep | Istilah UI |
|---|---|
| Participant | Peserta |
| Coach | Coach |
| Admin | Admin |
| Program | Program |
| Program day | Hari program |
| Step | Langkah |
| Evidence | Bukti |
| Upload evidence | Unggah bukti |
| Initial weight | Berat badan awal |
| Final weight | Berat badan akhir |
| Weight loss points | Poin penurunan berat badan |
| Step points | Poin langkah |
| Total points | Total poin |
| Leaderboard | Papan peringkat |
| Rank | Peringkat |
| Complete step | Selesaikan langkah |
| Pending review | Menunggu pemeriksaan |
| Approved | Disetujui |
| Rejected | Ditolak |
| Locked | Terkunci |
| Current program | Program aktif |
| Join program | Gabung program |
| Coach enrollment QR | QR pendaftaran coach |
| Purchase history | Riwayat pembelian |
| Managed content | Konten aplikasi |

`Leaderboard` boleh dipertahankan sebagai istilah sekunder bila diperlukan, tetapi label utama UI sebaiknya **Papan peringkat**.

### Format lokal

Gunakan locale `id-ID` untuk:

- Angka.
- Persentase.
- Berat badan.
- Mata uang.
- Tanggal.
- Waktu.

Contoh:

```text
Berat badan: 78,5 kg
Poin: 12.350
Tanggal: 5 Agustus 2026
Waktu: 17.00 WITA
Harga: Rp149.000
```

Jangan membentuk format angka, tanggal, atau mata uang dengan string manual. Gunakan `FormatStyle` native.

Program tetap menyimpan timezone IANA. Default product saat ini dapat menggunakan `Asia/Makassar` sesuai kebutuhan operasional, tetapi formatter tetap harus menjelaskan zona waktu kepada pengguna bila relevan.

## 2. Identitas Visual

Warna utama:

1. Hitam
2. Merah
3. Kuning

Karakter visual:

- Tegas.
- Aktif.
- Sporty.
- Mudah dibaca.
- Tidak terlalu ramai.
- Tetap terasa native iOS.
- Tidak menyerupai poster promosi yang padat di seluruh layar.

Warna brand digunakan sebagai aksen dan hierarchy. Jangan menjadikan setiap permukaan merah, kuning, atau hitam sekaligus.

## 3. Prinsip Warna

Gunakan warna semantic melalui Asset Catalog.

Jangan memakai nilai hex langsung di feature Views.

Contoh nama asset:

```text
BrandPrimary
BrandSecondary
BrandAccent
AppBackground
AppSecondaryBackground
AppSurface
AppElevatedSurface
AppPrimaryText
AppSecondaryText
AppBorder
AppDestructive
AppSuccess
AppWarning
AppInfo
```

### Brand roles

- `BrandPrimary`: merah.
- `BrandSecondary`: hitam atau near-black.
- `BrandAccent`: kuning.
- Hitam menjadi warna identitas, teks kuat, atau surface tertentu.
- Merah menjadi warna CTA utama dan highlight aktif.
- Kuning menjadi aksen, peringatan ringan, pencapaian, atau rank.
- Jangan memakai kuning sebagai body text pada background terang.
- Jangan memakai merah untuk semua status karena merah juga berarti error/destructive.

## 4. Palet Referensi

Nilai berikut menjadi titik awal. Implementasikan sebagai color assets dengan Any Appearance dan Dark Appearance.

### Light mode

| Token | Nilai referensi | Penggunaan |
|---|---:|---|
| BrandPrimary | `#D92D20` | CTA utama, tab aktif, highlight |
| BrandPrimaryPressed | `#B42318` | Pressed state |
| BrandSecondary | `#111111` | Teks kuat, dark surface |
| BrandAccent | `#F5C542` | Rank, pencapaian, aksen |
| AppBackground | `#F7F7F8` | Background utama |
| AppSecondaryBackground | `#FFFFFF` | List dan form |
| AppSurface | `#FFFFFF` | Card dan grouped surface |
| AppElevatedSurface | `#FFFFFF` | Sheet atau elevated card |
| AppPrimaryText | `#111111` | Teks utama |
| AppSecondaryText | `#5F6368` | Teks sekunder |
| AppBorder | `#DADCE0` | Divider dan border |
| AppDestructive | `#C62828` | Hapus, gagal, ditolak |
| AppSuccess | `#18794E` | Berhasil, disetujui |
| AppWarning | `#8A5A00` | Peringatan pada surface kuning muda |
| AppInfo | `#2457A6` | Informasi netral |

### Dark mode

| Token | Nilai referensi | Penggunaan |
|---|---:|---|
| BrandPrimary | `#D92D20` | CTA utama, tab aktif, highlight |
| BrandPrimaryPressed | `#B42318` | Pressed state |
| BrandSecondary | `#F5F5F5` | Teks kuat pada dark background |
| BrandAccent | `#F5C542` | Rank, pencapaian, aksen |
| AppBackground | `#0D0D0F` | Background utama |
| AppSecondaryBackground | `#151517` | List dan form |
| AppSurface | `#1C1C1E` | Card dan grouped surface |
| AppElevatedSurface | `#242426` | Sheet atau elevated card |
| AppPrimaryText | `#F5F5F5` | Teks utama |
| AppSecondaryText | `#B0B0B5` | Teks sekunder |
| AppBorder | `#3A3A3C` | Divider dan border |
| AppDestructive | `#FF6961` | Hapus, gagal, ditolak |
| AppSuccess | `#5ED39A` | Berhasil, disetujui |
| AppWarning | `#FFD166` | Peringatan |
| AppInfo | `#78A9FF` | Informasi netral |

Nilai dapat disesuaikan setelah contrast audit, tetapi peran semantic dan hubungan visualnya tidak boleh berubah tanpa keputusan desain yang terdokumentasi.

Warna identitas `BrandPrimary`, `BrandPrimaryPressed`, dan `BrandAccent`
mempertahankan nilai yang sama pada light dan dark mode agar karakter brand
tidak berubah menjadi coral atau pastel. Background, surface, border, text, dan
warna status tetap adaptif terhadap appearance.

Poster program menggunakan token khusus yang stabil pada light dan dark mode:

| Token | Nilai | Penggunaan |
|---|---:|---|
| ProgramPosterBase | `#111111` | Pangkal gradient poster |
| ProgramPosterPrimary | `#D92D20` | Poster program aktif |
| ProgramPosterInfo | `#2457A6` | Poster program terjadwal |
| ProgramPosterAccent | `#F5C542` | Poster program selesai |

Podium menggunakan warna identitas yang tidak berubah antar-appearance:

| Token | Nilai | Penggunaan |
|---|---:|---|
| BrandAccent | `#F5C542` | Peringkat 1, emas |
| AppSecondaryText | adaptif | Peringkat 2, perak netral |
| PodiumBronze | `#CD7F32` | Peringkat 3, perunggu |

## 5. Aturan Kontras

- Semua teks harus memenuhi kontras yang layak terhadap background.
- Body text tidak boleh menggunakan `BrandAccent` langsung pada putih.
- Kuning digunakan sebagai:
  - Background badge dengan teks hitam.
  - Border atau icon.
  - Rank badge.
  - Highlight kecil.
- Merah digunakan untuk:
  - Primary action.
  - Active selection.
  - Brand emphasis.
- Destructive action tetap memakai semantic destructive color, bukan otomatis `BrandPrimary`.
- Gunakan warna dan icon atau label bersama. Jangan mengandalkan warna saja.
- Uji Increase Contrast dan Differentiate Without Color.
- Pada button merah, gunakan teks putih bila contrast terpenuhi.
- Pada button kuning, gunakan teks near-black.
- Pada dark mode, hindari pure white luas dan pure black absolut bila mengurangi hierarchy.

## 6. Komposisi Warna per Layar

### Participant

- Background netral.
- Merah untuk CTA utama seperti `Selesaikan langkah`.
- Kuning untuk poin, streak, rank, atau pencapaian.
- Hitam atau dark surface untuk program hero secara terbatas.
- Setelah header profil, urutan section konten Home adalah Program, Fokus,
  `Leaderboard Top 5`, Pemenang, lalu Coach. Leaderboard menjadi section
  konten ketiga, bukan ditempatkan paling bawah.
- Katalog Program memakai tiga segmented control: `Diikuti` untuk enrollment
  aktif atau menunggu mulai, `Tersedia` untuk program yang dapat didaftarkan,
  dan `Riwayat` untuk program yang pernah diikuti dan sudah selesai.
- Sorotan pemenang di Home memakai maksimal dua poster vertikal rasio 9:16
  dalam carousel horizontal. Poster ditampilkan sebagai gambar apa adanya:
  tanpa overlay judul, nama, tombol, CTA, atau aksi tap. Sisakan sebagian
  poster berikutnya sebagai petunjuk swipe.
- Direktori coach di Home memakai avatar lingkaran dengan center crop dari
  foto profil biasa, termasuk foto vertikal dari ponsel. Jangan mensyaratkan
  background transparan atau membuat cutout tubuh.
- Semua avatar tanpa foto memakai satu fallback systemwide berupa ikon orang
  kosong native `person.crop.circle.fill` pada surface netral. Jangan memakai
  inisial nama atau lingkaran warna brand sebagai foto profil default.
- Tampilkan beberapa coach, lalu bedakan coach pendamping peserta dengan
  badge `Coach-mu`; jangan mengandalkan warna atau posisi saja.
- Status memakai semantic colors.
- Layar program yang sudah diikuti memprioritaskan aktivitas: gunakan header
  progres yang ringkas, lalu daftar hari berbentuk accordion dengan status
  langkah di dalamnya.
- Buka hari yang paling relevan secara default dan biarkan hari lain tetap
  ringkas agar peserta dapat langsung fokus pada aktivitas.
- Hari fokus harus ditentukan dari tanggal aktif dalam timezone program.
  Auto-open, label `Hari ini`, posisi scroll awal, dan border highlight harus
  memakai hasil tanggal yang sama; jangan fallback ke hari pertama.
- Kebijakan akses hari harus dipetakan konsisten dari `ProgramDayAccess`:
  hari standar yang tanggalnya sudah tiba menampilkan langkah dan dapat
  dikerjakan, sedangkan hari standar mendatang terkunci. Status read-only
  hanya digunakan jika ditetapkan secara eksplisit pada konten.
- Gunakan status hidden hanya untuk konten yang memang belum dipublikasikan.
  Jangan menyembunyikan hari yang sudah lewat jika langkahnya sudah
  dipublikasikan.
- Hari yang terkunci atau disembunyikan memakai satu copy konsisten:
  `Aktivitas belum tersedia.` Perbedaannya tetap berada pada kebijakan akses,
  bukan pada pesan yang membingungkan peserta.
- Jangan menaruh deskripsi panjang, aturan poin, atau profil coach di atas
  daftar aktivitas. Informasi penawaran program tetap berada pada layar
  detail sebelum pendaftaran.
- Profil peserta menampilkan semua data yang dapat diubah secara eksplisit:
  foto profil, nama tampilan, nomor HP, dan coach pendamping. Email akun
  tetap ditampilkan sebagai data read-only.
- Edit foto, nama, dan nomor HP memakai sheet form native. Foto dipilih
  melalui `PhotosPicker`, diproses sebagai media lokal, dan ditampilkan dengan
  crop lingkaran.
- Jangan menyediakan aksi `Gunakan foto demo`, `Gunakan poster demo`, atau
  media contoh yang dibuat dari layar upload, termasuk pada build Debug.
  Upload harus melalui pemilih Foto atau kamera native yang sebenarnya.
- Pergantian coach hanya dimulai dari aksi `Ganti coach`, dilanjutkan dengan
  scan QR unik coach dan konfirmasi nama coach. Jangan menyediakan input kode
  manual atau menampilkan identifier mentah.
- Riwayat program tetap berada di tab Program, bukan diduplikasi di Profil,
  agar Profil berfokus pada identitas, coach, pengaturan, privasi, dan akun.

### Coach

- Dashboard tetap netral.
- Merah untuk quick actions utama.
- Kuning untuk pending review dan highlight penting.
- Evidence viewer tidak diberi overlay warna yang mengganggu foto.
- Kartu `Perlu perhatian` harus membedakan `Belum terdaftar` untuk peserta
  tanpa enrollment, `Belum mulai` untuk peserta yang sudah terdaftar tetapi
  belum menyelesaikan langkah, dan `Tertinggal` untuk peserta yang sudah
  memiliki progres di bawah batas tindak lanjut.
- Badge jumlah `Perlu perhatian` berada pada aksi `Peserta saya`, karena
  daftar prioritas merupakan bagian dari direktori peserta. Jangan
  menduplikasiasinya sebagai aksi cepat Dashboard tersendiri.
- `Aktivitas terbaru` hanya menampilkan aktivitas hari ini secara default.
  Aktivitas lama baru ditampilkan setelah Coach memilih rentang 7 atau 30
  hari, atau menekan `Lihat aktivitas sebelumnya`, agar feed tidak tumbuh
  tanpa batas pada kunjungan sehari-hari.
- Feed aktivitas tidak menampilkan foto bukti atau data berat. Gunakan avatar
  profil netral, ringkasan aktivitas, waktu, status yang relevan, dan satu
  target navigasi pada seluruh baris.
- Filter aktivitas memakai pola filter systemwide: satu kartu ringkasan,
  `Form` native berisi Program, Jenis aktivitas, dan Waktu, serta footer
  bersama `Atur ulang` dan `Terapkan filter`.

### Admin

- Admin membuka `Dashboard` sebagai tab awal. Pemilih demo menyediakan
  skenario `Dashboard Admin`; skenario yang secara khusus menguji draft atau
  program aktif boleh langsung membuka tab Program.
- Form dan CMS memakai background system/netral.
- Direktori Orang memakai segmented control native `Peserta`, `Coach`, dan
  `Admin` seperti katalog Program peserta. Judul serta segmented control
  tetap terlihat dan hanya daftar orang yang digulir. Segmen menggantikan
  pengelompokan atau label peran yang berulang pada setiap baris. Pintasan
  persetujuan Coach dari Dashboard langsung membuka segmen `Coach`.
- Detail Orang mengikuti struktur profil asli setiap peran. Peserta
  menampilkan identitas, data profil, dan Coach pendamping; Coach menampilkan
  identitas publik, data profil, bio, persetujuan, serta visibilitas; Admin
  hanya menampilkan data akun yang benar-benar tersedia. Tindakan
  administratif ditempatkan setelah informasi profil dan tidak boleh
  menggantikan atau mengarang field profil.
- Layar Konten memakai area aksi tambah yang dapat diperluas untuk jenis
  konten berikutnya. Pada fase ini hanya ada `Poster pemenang`.
- Poster pemenang dikelola sebagai galeri gambar vertikal dua kolom berbasis
  `LazyVGrid` pada ponsel. Sel hanya menampilkan poster, nomor urutan, dan
  menu tindakan; jangan mengubahnya menjadi daftar metadata.
- Editor poster pemenang memakai `PhotosPicker` native, pratinjau 9:16,
  serta aksi ganti dan hapus. Poster wajib dipilih sebelum konten dapat
  disimpan.
- Jangan menampilkan editor atau tombol `Kelola pemenang` di Konten.
  Peringkat pemenang berasal dari leaderboard dan snapshot pemenang tetap
  dihitung otomatis; galeri hanya mengelola gambar poster.
- Merah hanya untuk primary publish action atau destructive action sesuai konteks.
- Kuning untuk draft warning dan validation attention.
- Jangan menggunakan full-red background pada form panjang.

### Leaderboard

- Peringkat 1: kuning/gold accent dengan teks hitam.
- Peringkat 2: neutral cool surface.
- Peringkat 3: warm neutral surface.
- Peringkat 4 sampai 5: standard elevated surface.
- Current user row diberi border atau tint, bukan hanya perubahan warna teks.
- Final winners harus tetap terbaca dalam light dan dark mode.

## 7. Tipografi

Gunakan font sistem Apple San Francisco melalui semantic text styles.

Jangan menambahkan custom font pada MVP kecuali diminta secara eksplisit.

### Hierarchy

| Kegunaan | SwiftUI style | Weight yang disarankan |
|---|---|---|
| Judul layar utama | `.largeTitle` | Bold |
| Judul section besar | `.title2` atau `.title3` | Semibold |
| Judul card | `.headline` | Semibold |
| Isi utama | `.body` | Regular |
| Isi sekunder | `.subheadline` | Regular |
| Label kecil | `.caption` | Medium |
| Angka poin utama | `.title` atau `.largeTitle` | Bold |
| Tombol | `.headline` | Semibold |

Contoh:

```swift
Text("Hari ke-3")
    .font(.title2.weight(.bold))

Text("Lengkapi semua langkah hari ini.")
    .font(.body)
    .foregroundStyle(Color.appSecondaryText)

Text(score, format: .number.locale(Locale(identifier: "id-ID")))
    .font(.title.monospacedDigit().weight(.bold))
```

### Aturan tipografi

- Gunakan Dynamic Type.
- Hindari fixed font size untuk text production.
- Fixed size hanya diperbolehkan untuk elemen dekoratif yang tidak membawa informasi utama.
- Gunakan `.monospacedDigit()` untuk:
  - Poin.
  - Peringkat.
  - Berat.
  - Timer atau countdown.
- Gunakan line limit hanya bila kehilangan teks tidak mengganggu pemahaman.
- Jangan mengecilkan text agar muat.
- Biarkan text wrap.
- Hindari all caps untuk paragraf.
- Gunakan bold untuk hierarchy, bukan seluruh layar.
- Jangan menggunakan lebih dari tiga tingkat emphasis dalam satu card.

## 8. Spacing dan Shape

Referensi semantic spacing:

```text
xxSmall = 4
xSmall = 8
small = 12
medium = 16
large = 24
xLarge = 32
xxLarge = 48
```

Referensi radius:

```text
small = 8
medium = 12
large = 16
prominent = 24
capsule = system capsule
```

Aturan:

- Gunakan spacing token, bukan angka acak.
- Primary screen horizontal padding umumnya 16 sampai 20 points.
- Touch target minimum 44 x 44 points.
- Card radius konsisten.
- Dense CMS forms lebih baik memakai native `Form` daripada custom card bertumpuk.
- Divider harus subtle dan tidak selalu diperlukan bila spacing sudah jelas.

## 9. Buttons

### Primary button

- Background `BrandPrimary`.
- Foreground putih.
- Label `.headline`.
- Minimum height 50 points.
- Full-width pada form completion bila sesuai.
- Disabled state menggunakan opacity dan semantic disabled behavior, bukan hanya warna lebih muda.

### Secondary button

- Native bordered atau tinted style.
- Dapat menggunakan outline merah.
- Jangan bersaing visual dengan primary action.
- Kartu navigasi yang seluruh permukaannya dapat diketuk dan sudah memakai
  chevron tidak boleh menambahkan CTA duplikat seperti `Lihat peserta`.
  Pertahankan satu target tap yang jelas untuk menghindari hierarki aksi
  palsu dan ruang kosong yang tidak perlu.

### Filter

- Tombol pembuka filter daftar memakai komponen ringkasan bersama: ikon
  filter, judul, ringkasan pilihan aktif, dan chevron pada surface netral.
- Filter kompleks dibuka sebagai bottom sheet dengan `Form`, `Section`, dan
  `Picker` inline native. Jangan membuat kartu pilihan atau indikator radio
  khusus per fitur.
- Footer filter selalu memakai dua tombol bersama dengan tinggi dan radius
  yang sama: `Atur ulang` sebagai secondary outline dan `Terapkan filter`
  sebagai primary merah.
- Perbedaan fitur hanya pada isi section dan pilihan filter, bukan pada
  styling sheet, surface, spacing, header, atau action bar.

### Yellow accent button

Gunakan sangat terbatas untuk:

- Claim reward.
- Lihat peringkat.
- Highlight achievement.

Foreground harus near-black.

### Destructive button

- Gunakan role `.destructive`.
- Jangan menggunakan brand red hanya karena warnanya sama.
- Confirmation diperlukan untuk irreversible action.

## 10. Icons dan Images

- Gunakan SF Symbols untuk icon system.
- Pilih symbol yang jelas dan umum.
- Jangan mengandalkan icon tanpa label untuk aksi penting.
- Coach photo memakai aspect fill dan accessible name.
- Evidence photo tidak boleh dipotong secara menyesatkan pada full viewer.
- Program cover dapat memakai gradient overlay agar teks tetap terbaca.
- Decorative image harus hidden dari VoiceOver.

## 11. Liquid Glass iOS 26+

Gunakan secara selektif.

Cocok untuk:

- Floating primary action.
- Compact filter.
- QR action panel.
- Media overlay controls.
- Rank badge atau small achievement cluster.

Tidak cocok untuk:

- Semua step rows.
- Dense admin forms.
- Long text cards.
- Full-screen content background.
- Evidence image utama.

Aturan:

- Gunakan native API.
- Gate dengan `#available(iOS 26, *)`.
- Gunakan `GlassEffectContainer` bila beberapa glass elements berkelompok.
- Interactive glass hanya untuk interactive element.
- Respect Reduce Transparency.
- Jangan meniru Liquid Glass pada iOS lama.

## 12. Fallback iOS 17 sampai 25

Gunakan:

- `NavigationStack`.
- `TabView`.
- `List`.
- `Form`.
- System grouped backgrounds.
- Semantic color assets.
- Material hanya bila benar-benar membantu hierarchy.
- Rounded surface dengan `AppSurface`.

### Navigasi kembali

- Destination di dalam `NavigationStack` harus mempertahankan gesture native
  swipe dari leading edge untuk kembali.
- Jangan menambahkan `DragGesture` layar penuh sebagai pengganti gesture
  kembali karena dapat bertabrakan dengan scroll horizontal, carousel,
  sheet, dan gesture sistem.
- Jika tombol back native disembunyikan untuk kebutuhan produk, kontrol
  bersama wajib mengaktifkan kembali `interactivePopGestureRecognizer` dan
  hanya mengizinkannya ketika stack memiliki destination yang dapat di-pop.
- Root tab dan root navigation stack tidak boleh bereaksi terhadap gesture
  kembali.

Fallback harus mempertahankan:

- Layout hierarchy.
- Action priority.
- Accessibility.
- Content order.
- State behavior.

## 13. Copy Reference

Contoh copy:

### Empty state

```text
Belum ada program aktif
Gabung melalui kode undangan dari coach untuk mulai mengikuti program.
```

### Missing evidence

```text
Bukti foto belum ditambahkan
Unggah foto sesuai petunjuk sebelum menyelesaikan langkah ini.
```

### Pending review

```text
Menunggu pemeriksaan coach
Bukti sudah dikirim. Poin akan diperbarui setelah disetujui.
```

### Rejected

```text
Bukti perlu diperbaiki
Baca alasan dari coach, lalu unggah bukti baru.
```

### Locked future day

```text
Hari ini belum tersedia
Langkah akan terbuka sesuai jadwal program.
```

### Wellness disclaimer

```text
Program ini mendukung kebiasaan hidup sehat dan bukan pengganti diagnosis atau perawatan medis.
```

## 14. Accessibility Checklist

Setiap screen harus diperiksa untuk:

- Dynamic Type sampai accessibility sizes.
- VoiceOver label, value, hint, dan order.
- Minimum touch target.
- Light mode.
- Dark mode.
- Increase Contrast.
- Reduce Transparency.
- Reduce Motion.
- Differentiate Without Color.
- Error text yang terhubung dengan field.
- Status yang tetap jelas tanpa warna.

## 15. Preview Matrix

Untuk primary screen, sediakan preview:

- Light mode.
- Dark mode.
- Bahasa Indonesia.
- Standard Dynamic Type.
- Largest accessibility Dynamic Type.
- Loading.
- Empty.
- Error.
- Populated.
- iOS 26 glass branch bila SDK tersedia.
- iOS 17 sampai 25 fallback branch.

## 16. Definition of Done UI

UI dianggap selesai bila:

- Seluruh copy production-facing berbahasa Indonesia.
- Semua angka, tanggal, berat, dan harga menggunakan locale `id-ID`.
- Warna menggunakan semantic asset.
- Light dan dark mode diuji.
- Text tetap terbaca dengan Dynamic Type terbesar yang relevan.
- Status tidak disampaikan dengan warna saja.
- Liquid Glass memiliki fallback native.
- Tidak ada fixed font size untuk informasi utama.
- Tidak ada hard-coded hex di feature View.
- Tidak ada reusable copy yang tersebar tanpa localization key.
