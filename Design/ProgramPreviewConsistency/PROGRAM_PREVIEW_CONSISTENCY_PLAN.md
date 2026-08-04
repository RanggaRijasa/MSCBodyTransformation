# Rencana konsistensi pratinjau program

Tanggal: 3 Agustus 2026

## Tujuan

Pratinjau Admin bukan lagi representasi terpisah. Konten yang dilihat Admin
harus dirender oleh komponen dan aturan presentasi yang sama dengan layar
program Peserta dan Coach.

Pratinjau hanya menambahkan konteks berikut di luar renderer bersama:

- Pemilih peran `Peserta` dan `Coach`.
- Penjelasan bahwa tampilan sama dengan aplikasi peran terpilih.
- Data simulasi lokal yang deterministik untuk progres dan status.

## Perubahan utama

### Navigasi pratinjau

- Judul diubah menjadi `Pratinjau program`.
- Hapus segmented control `Perangkat kecil` dan `Perangkat besar`.
- Gunakan segmented control `Peserta` dan `Coach`.
- Ukuran layar mengikuti perangkat Admin secara adaptif. Validasi iPhone,
  iPad, Dynamic Type, dan orientasi dilakukan lewat preview matrix dan test,
  bukan melalui kontrol produk.

### Renderer bersama

Ketiga konteks memakai hierarchy yang sama:

1. Identitas program dan rentang tanggal.
2. Progres program.
3. Judul `Aktivitas program`.
4. Daftar hari berbentuk accordion.
5. Hari fokus dibuka otomatis.
6. Langkah memakai urutan, judul, icon jenis konten, dan status yang sama.
7. Hari mendatang memakai copy `Aktivitas belum tersedia.`

Tidak boleh ada implementasi card khusus Admin yang menduplikasi layout
Peserta.

## Perbedaan per peran

| Elemen | Peserta | Coach |
|---|---|---|
| Konteks orang | Tidak diperlukan | Baris `Peserta yang dipantau` |
| Progres | Progres enrollment Peserta | Progres Peserta yang dipilih |
| Langkah tersedia | Dapat dibuka dan dikerjakan | Read-only atau membuka konteks pemeriksaan |
| Timbang | Status pengiriman, nilai hanya di layar privat Peserta | Hanya `Tercatat`, tanpa angka berat |
| Pending review | `Menunggu pemeriksaan` | `Menunggu pemeriksaan`, dapat menuju antrean |
| Answer key | Tidak tersedia | Hanya saat membuka konteks review yang berwenang |
| Foto | Jawaban sendiri pada detail langkah | Hanya pada review privat, bukan di daftar program |

## Status visual

- `Selesai`: icon centang dan badge hijau.
- `Menunggu pemeriksaan`: icon jam dan badge kuning.
- `Perlu diperbaiki`: icon peringatan dan badge destructive.
- `Tersedia`: icon jenis konten dan chevron.
- `Terkunci`: icon gembok, warna netral, dan copy
  `Aktivitas belum tersedia.`

Status selalu memakai icon dan teks; warna tidak boleh menjadi satu-satunya
penanda.

## Sumber data pratinjau

- Program berasal langsung dari `AdminProgramDraft` melalui mapper published
  yang sama dengan proses terbit.
- Hari, langkah, pertanyaan, media, aturan akses, poin, dan answer key tidak
  dimapping ulang di View pratinjau.
- Progres, submission, review, dan enrollment hanya berupa
  `ProgramPreviewScenario` deterministik.
- Skenario tidak boleh ditulis ke repository produksi.

## Struktur implementasi yang disarankan

```text
AdminProgramPreviewView
├── PreviewRolePicker
├── PreviewExplanationBanner
└── SharedProgramActivityRenderer
    ├── ProgramActivityHeader
    ├── ProgramDayAccordion
    └── ProgramStepRow

ParticipantProgramActivityView
└── SharedProgramActivityRenderer

CoachProgramActivityView
├── MonitoredParticipantRow
└── SharedProgramActivityRenderer
```

Renderer menerima presentation model dan capability, bukan melakukan
pengecekan role di setiap row:

```text
ProgramActivityCapabilities
- canOpenStep
- canSubmitAnswer
- canOpenReview
- showsPrivateWeight
- showsAnswerKey
```

## State yang harus tersedia

- Draft tanpa hari.
- Draft dengan hari tetapi tanpa langkah aktif.
- Hari aktif dengan langkah tersedia.
- Hari mendatang terkunci.
- Langkah selesai.
- Menunggu pemeriksaan.
- Ditolak dan dapat diperbaiki.
- Kuis lulus dan gagal.
- Video belum mencapai ambang.
- Timbang awal/harian/final tercatat.
- Coach tanpa Peserta yang dipilih.
- Error mapper draft ke published preview.

## Acceptance criteria

- Judul, tanggal, urutan hari, dan urutan langkah sama pada Admin, Peserta,
  dan Coach.
- Perubahan draft langsung tercermin tanpa membuat mapping UI kedua.
- Status yang sama memakai copy, icon, dan semantic style yang sama.
- Admin tidak melihat kontrol yang tidak akan muncul pada peran terpilih.
- Coach tidak melihat nilai berat pada daftar aktivitas.
- Coach melihat nilai timbang awal/harian/akhir hanya di detail privat
  peserta, bukan pada renderer daftar program atau feed.
- Peserta tidak menerima answer key atau data Peserta lain.
- Tidak ada segmented control ukuran perangkat pada UI produksi.
- Layout tetap valid pada iPhone, iPad, dark mode, dan Dynamic Type.

## Artefak visual

- `admin-program-preview-participant-v2.png`
- `admin-program-preview-coach-v2.png`

Mockup dibuat dengan built-in GPT ImageGen menggunakan screenshot lama
sebagai referensi visual.

## Status implementasi

Selesai pada 3 Agustus 2026.

- `ProgramActivityRenderer`, header program, accordion hari, dan baris langkah
  berada di `SharedUI` dan dipakai langsung oleh runtime Peserta, detail
  progres Coach, serta pratinjau Admin.
- Wrapper Admin hanya menambahkan pemilih peran, banner penjelasan, dan
  peserta simulasi untuk konteks Coach.
- Sumber program pratinjau melewati mapper draft-ke-published yang sama dengan
  alur publikasi. Hanya submission dan akses hari yang disimulasikan secara
  lokal dan deterministik.
- Kontrol `Perangkat kecil/besar` sudah dihapus dari UI produksi.
- Runtime Coach menyembunyikan angka timbang pada daftar dan menampilkan
  status netral `Tercatat`.
- Draft baru memulai poin timbang dari nol agar draft non-timbang tidak gagal
  validasi tersembunyi; Admin mengaktifkannya secara eksplisit setelah
  menambahkan timbang awal dan akhir.
- Verifikasi awal: 130 unit/integration tests dan tiga perjalanan UI
  Admin/Peserta/Coach lulus; build/run Debug pada iPhone 17 iOS 26.5 juga
  lulus tanpa warning.
- Amendment cover dan timbang harian: 134 unit/integration tests lulus;
  perjalanan UI Admin dan Coach terkait juga lulus.
