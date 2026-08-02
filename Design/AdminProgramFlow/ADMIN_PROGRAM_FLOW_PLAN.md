# Rencana alur Program Admin

## Keputusan utama

Jangan menampilkan `Tambah program`, `Atur program`, dan `Kelola program`
sebagai menu yang sejajar.

Gunakan satu model mental:

```text
Tab Program
├── Buat program baru
│   └── Membuat draft lalu membuka hub program
└── Ketuk kartu program
    └── Membuka hub program yang sama sesuai statusnya
```

Perbedaan antara membuat dan mengelola hanya terletak pada status program,
bukan pada struktur navigasi.

## Layar 1 — Daftar program

Mockup:

- `Design/AdminProgramFlow/admin-program-list-v1.png`

Aturan:

- Hanya ada satu aksi pembuatan: `Buat program baru`.
- Jangan menambahkan tombol plus kedua di toolbar.
- Seluruh kartu program menjadi satu target tap.
- Jangan menambahkan tombol `Kelola`, `Atur`, atau `Edit` di dalam kartu.
- Kartu menampilkan judul, status, konteks singkat, dan chevron.
- Draft menampilkan progres penyelesaian tiga tahap.
- Search dan filter tetap tersedia tanpa mengubah kartu menjadi tabel padat.

## Layar 2 — Hub draft

Mockup:

- `Design/AdminProgramFlow/admin-program-draft-hub-v1.png`

Draft memakai tiga tahap tingkat atas:

1. `Pengaturan program`
   - Info program.
   - Jadwal dan peserta.
   - Aturan dan poin.
2. `Konten program`
   - Hari program.
   - Langkah.
   - Pertanyaan.
   - Media.
3. `Tinjau & terbitkan`
   - Pratinjau peserta.
   - Ringkasan validasi.
   - Simulasi publikasi lokal.

Setiap tahap:

- Memiliki satu kartu navigasi.
- Memiliki status teks dan ikon.
- Dapat dibuka untuk memahami bagian yang belum lengkap.
- Tidak diduplikasi oleh tombol `Lanjutkan` atau CTA kedua pada hub.

Toolbar `Simpan` hanya muncul ketika draft dapat diedit.

## Layar 3 — Hub program diterbitkan

Mockup:

- `Design/AdminProgramFlow/admin-program-published-hub-v1.png`

Program `Terjadwal`, `Aktif`, atau `Selesai` mempertahankan struktur tiga
bagian yang sama:

1. `Pengaturan program`.
2. `Konten program`.
3. `Status publikasi`.

Perbedaannya:

- Pengaturan dan konten dibuka dalam mode baca.
- Lock dijelaskan dengan ikon dan copy, bukan hanya opacity.
- Aturan, jadwal, konten, dan scoring yang sudah diterbitkan tidak dapat
  diubah langsung.
- `Duplikasikan sebagai draft` menjadi satu-satunya jalur untuk menyiapkan
  versi baru.
- `Arsipkan program` tetap terpisah sebagai tindakan destructive dan meminta
  konfirmasi.

## Pemetaan status

| Status | Mode hub | Aksi utama |
|---|---|---|
| Draft | Dapat diedit | Lengkapi tiga tahap dan terbitkan |
| Terjadwal | Baca | Duplikasikan sebagai draft |
| Aktif | Baca | Duplikasikan sebagai draft |
| Selesai | Baca | Duplikasikan sebagai draft atau arsipkan |
| Diarsipkan | Baca | Duplikasikan sebagai draft |

## Terminologi

- Gunakan `Buat program baru` untuk aksi pembuatan.
- Gunakan nama program sebagai judul hub.
- Gunakan `Pengaturan program`, bukan menu umum `Atur program`.
- Gunakan `Konten program`, bukan menu umum `Kelola konten`.
- Gunakan `Tinjau & terbitkan` hanya pada draft.
- Gunakan `Status publikasi` setelah program diterbitkan.
- Jangan memakai `Kelola program` sebagai label tombol.

## State penting

- Loading: tampilkan state native, bukan daftar kosong palsu.
- Empty: `Belum ada program` dan satu aksi `Buat program baru`.
- Draft belum lengkap: tampilkan tahap yang bermasalah dan jumlah isu.
- Draft valid: tahap ketiga menampilkan `Siap diterbitkan`.
- Program diterbitkan: tampilkan banner read-only dan aksi duplikasi.
- Offline: jelaskan bahwa perubahan tersimpan pada demo lokal.
- Error: tampilkan pesan actionable dan `Coba lagi`.

## Batas implementasi

- Struktur domain `Program → Hari → Langkah → Pertanyaan` tetap sama.
- Tidak mengubah scoring atau program yang sudah diterbitkan secara diam-diam.
- Tidak menambahkan Supabase, package, atau networking.
- Tidak mengubah `project.pbxproj`.
- Mockup adalah arah hierarki; komponen akhir tetap memakai SwiftUI native,
  semantic colors, Dynamic Type, dan localization catalog.

