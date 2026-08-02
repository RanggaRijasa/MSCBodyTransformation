# Rencana dashboard Admin

## Tujuan

Mengganti halaman `Ringkasan` dengan `Dashboard` yang membantu Admin:

1. Menemukan pekerjaan yang perlu ditindaklanjuti.
2. Membuka pekerjaan rutin dengan satu ketukan.
3. Memahami kondisi operasional tanpa membaca banyak kartu metrik.
4. Melihat jejak perubahan terbaru sebagai konteks.

Mockup terpilih:

- `Design/AdminDashboard/admin-dashboard-concept-v1.png`
- Dibuat dengan GPT ImageGen berdasarkan screenshot halaman `Ringkasan`
  saat ini sebagai referensi visual.

## Hierarki konten

### 1. Header

- Judul: `Dashboard`.
- Ringkasan: `Kendali operasional hari ini`.
- Penanda sumber data: `Data demo lokal` selama aplikasi masih memakai
  repository lokal.
- Tombol informasi mempertahankan pola shell yang sudah ada.

### 2. Perlu tindakan

Gunakan satu grouped card dengan baris yang dapat diketuk:

- `Pemeriksaan tertunda`
  - Menampilkan jumlah bukti peserta yang masih menunggu Coach.
  - Membuka tampilan pemantauan yang sudah difilter ke pemeriksaan tertunda.
  - Admin memantau antrean; keputusan pemeriksaan tetap menjadi tanggung
    jawab Coach kecuali aturan produk kemudian diperluas.
- `Persetujuan Coach`
  - Menampilkan jumlah akun Coach yang perlu ditinjau.
  - Membuka tab Orang dengan filter persetujuan tertunda.

Jika seluruh jumlah nol, ganti grouped card dengan status tenang:
`Tidak ada tindakan mendesak`.

### 3. Akses cepat

Gunakan grid dua kolom pada ukuran teks standar dan satu kolom pada Dynamic
Type aksesibilitas:

- `Buat program`
  - Membuat draft lalu membuka editor program.
  - Menjadi satu-satunya kartu dengan penekanan merah.
- `Tambah poster`
  - Membuka editor poster baru dari tab Konten.

Pintasan hanya berisi tindakan spesifik. `Kelola program`, `Kelola orang`,
`Konten`, dan `Pengaturan` tidak diulang karena tujuan tersebut sudah tersedia
di tab bar. `Pemeriksaan tertunda` dan `Persetujuan Coach` juga tidak diulang
karena sudah diprioritaskan di bagian `Perlu tindakan`.

### 4. Gambaran hari ini

Gunakan satu kartu ringkas, bukan kumpulan kartu status yang sama besar:

- Program aktif.
- Peserta aktif.
- Program terjadwal.

Status `Draft`, `Selesai`, dan `Diarsipkan` tetap tersedia di tab Program,
karena bukan informasi yang perlu selalu memenuhi bagian atas Dashboard.

### 5. Aktivitas terbaru

- Tampilkan maksimal tiga audit event terbaru.
- Setiap baris berisi jenis aktivitas, ringkasan pendek, dan waktu dengan
  locale `id-ID`.
- Sediakan `Lihat semua` hanya jika layar audit lengkap ditambahkan.
- Jangan memakai chevron pada baris bila belum ada destination yang nyata.

## Navigasi dan label

- Ubah label tab pertama Admin dari `Ringkasan` menjadi `Dashboard`.
- Pertahankan case internal `AdminTab.overview` bila menggantinya berisiko
  memengaruhi launch scenario atau state yang tersimpan.
- Label tab: `Dashboard`, `Program`, `Orang`, `Konten`, `Pengaturan`.
- Dashboard memakai simbol `chart.bar.fill` saat terpilih.

## Model data

`AdminDashboardSnapshot` saat ini sudah menyediakan dasar yang diperlukan:

- `programCounts`
- `activeParticipantCount`
- `pendingCoachApprovals`
- `pendingReviews`
- `auditEvents`

Tambahan state atau route hanya diperlukan untuk:

- Membuka Orang dengan filter persetujuan tertunda.
- Membuka pemantauan pemeriksaan tertunda tanpa mengambil alih wewenang
  Coach.
- Membuka editor poster baru langsung dari Dashboard.
- Membuka daftar audit lengkap jika fitur tersebut dipilih.

## State layar

- Loading: gunakan loading state native; jangan menampilkan angka nol palsu.
- Loaded: tampilkan urutan Perlu tindakan, Akses cepat, Gambaran hari ini,
  lalu Aktivitas terbaru.
- Empty: sembunyikan bagian yang tidak relevan dan tampilkan status
  operasional yang jelas.
- Offline: pertahankan banner offline dan jelaskan bahwa angka berasal dari
  data lokal terakhir.
- Error: tampilkan pesan yang dapat ditindaklanjuti dan aksi coba lagi.

## Aturan visual

- Background dan kartu tetap netral.
- Merah hanya untuk pilihan tab dan `Buat program`.
- Kuning hanya untuk perhatian tertunda, disertai ikon dan label.
- Angka menggunakan `.monospacedDigit()`.
- Gunakan SF Symbols dan semantic color assets.
- Liquid Glass hanya untuk kontrol compact dan tab bar pada iOS 26+.
- Pada iOS 17–25 gunakan surface SwiftUI native yang mempertahankan hierarki.
- Jangan mengembalikan grid berisi delapan kartu metrik yang sama penting.

## Rencana implementasi

1. Ubah copy tab dan navigation title menjadi `Dashboard`.
2. Pisahkan overview lama menjadi `AdminDashboardView` dan subview kecil
   berdasarkan section.
3. Susun `Perlu tindakan` dan route/filter tujuannya.
4. Tambahkan dua pintasan unik dengan target yang nyata.
5. Ringkas metrik ke satu kartu `Gambaran hari ini`.
6. Pertahankan audit terbaru dan hilangkan affordance yang belum memiliki
   destination.
7. Tambahkan localization key dengan `defaultValue` Bahasa Indonesia.
8. Tambahkan focused Swift Testing untuk pemetaan snapshot dan XCTest UI
   untuk pintasan utama.
9. Verifikasi light/dark mode, locale non-Indonesia, Dynamic Type terbesar,
   Reduce Transparency, dan simulator build iPhone/iPad.

## Batas desain

- Tidak menambahkan Supabase, networking, atau package.
- Tidak mengubah aturan scoring atau authorization.
- Tidak menjadikan Admin sebagai pemeriksa bukti tanpa keputusan produk
  eksplisit.
- Tidak mengubah `project.pbxproj`.
