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
| Invite code | Kode undangan |
| Seat credit | Kuota peserta |
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
| BrandPrimary | `#FF5A52` | CTA utama, tab aktif, highlight |
| BrandPrimaryPressed | `#FF7A73` | Pressed state |
| BrandSecondary | `#F5F5F5` | Teks kuat pada dark background |
| BrandAccent | `#FFD95A` | Rank, pencapaian, aksen |
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
- Status memakai semantic colors.

### Coach

- Dashboard tetap netral.
- Merah untuk quick actions utama.
- Kuning untuk saldo kuota, pending review, dan highlight penting.
- Evidence viewer tidak diberi overlay warna yang mengganggu foto.

### Admin

- Form dan CMS memakai background system/netral.
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
