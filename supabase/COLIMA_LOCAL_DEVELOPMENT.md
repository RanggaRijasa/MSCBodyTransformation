# Colima dan Supabase lokal

Panduan ini menjelaskan cara memeriksa, menghidupkan, menggunakan, dan
mematikan runtime development lokal untuk MSC Body Transformation.

## Strategi environment

```text
Development → Supabase lokal melalui Supabase CLI, Docker, dan Colima
Production  → hosted Supabase main
Branching   → tidak digunakan
```

Mematikan Colima tidak memengaruhi hosted production. Hanya aplikasi Debug,
Supabase Studio, dan layanan lokal yang tidak dapat digunakan sampai Colima
dan Supabase lokal dihidupkan kembali.

## Konfigurasi Colima saat ini

- Profile: `default`.
- Architecture: `aarch64`.
- CPU: 6.
- Memory: 8 GiB.
- Disk capacity: 60 GiB.
- Runtime: Docker.
- VM: macOS Virtualization Framework.

Kapasitas CPU, memory, dan disk di atas adalah batas runtime. Pemakaian aktual
bergantung pada container dan proses yang sedang berjalan.

## Tempat mengontrol Colima

Colima tidak mempunyai aplikasi GUI utama. Gunakan Terminal untuk mengontrol
VM dan Docker runtime.

Supabase Studio adalah UI untuk database lokal, bukan UI untuk Colima. Saat
local stack aktif, buka:

<http://127.0.0.1:54323>

## Memeriksa status

Periksa Colima:

```bash
colima status
colima list
```

Periksa Docker daemon:

```bash
docker info
```

Periksa Supabase lokal dari root repository:

```bash
cd /Users/ranggarijasa/Documents/MSCBodyTransformation
supabase status
```

`supabase status` dapat menampilkan credential lokal. Jangan menyalin
output-nya ke issue, chat publik, dokumentasi, log, atau screenshot.

## Menghidupkan environment lokal

Jalankan Colima terlebih dahulu:

```bash
colima start
```

Kemudian jalankan Supabase dari root repository:

```bash
cd /Users/ranggarijasa/Documents/MSCBodyTransformation
supabase start
```

Pastikan keduanya siap:

```bash
colima status
supabase status
```

Setelah Mac direstart atau Colima sebelumnya dimatikan, selalu periksa status
sebelum menjalankan aplikasi Debug yang memakai Supabase lokal.

## Mematikan environment lokal dengan aman

Hentikan container Supabase terlebih dahulu:

```bash
cd /Users/ranggarijasa/Documents/MSCBodyTransformation
supabase stop
```

Kemudian hentikan Colima:

```bash
colima stop
```

`supabase stop` tanpa `--no-backup` dan `colima stop` mempertahankan state
lokal. Saat environment dihidupkan kembali, database dan Docker volume tetap
tersedia.

## Kapan harus hidup

Hidupkan Colima dan Supabase lokal ketika:

- Menjalankan aplikasi Debug yang memakai adapter Supabase lokal.
- Membuka Supabase Studio.
- Menjalankan migration atau database reset lokal.
- Menjalankan lint dan database advisors.
- Menjalankan pgTAP, RLS, Storage API, atau race tests.
- Mengembangkan backend Phase 09 dan phase berikutnya.

Biarkan hidup selama proses build, pengujian, debugging, atau aplikasi Debug
masih membutuhkan backend lokal.

## Kapan sebaiknya dimatikan

Matikan ketika:

- Selesai bekerja.
- Tidak sedang menggunakan backend lokal.
- Ingin menghemat CPU, memory, dan baterai.
- Mac akan dibawa, direstart, atau tidak digunakan lama.

Tidak perlu membiarkan Colima hidup hanya untuk menjaga hosted production.

## Perintah destruktif yang harus dihindari

Jangan jalankan perintah berikut kecuali memang ingin menghapus data lokal:

```bash
supabase stop --no-backup
colima delete
```

Konsekuensinya:

- `supabase stop --no-backup` menghapus data volume Supabase lokal setelah
  container dihentikan.
- `colima delete` menghapus VM Colima beserta runtime state terkait.

Jika data lokal terhapus, schema dapat dibangun ulang dari migration dengan:

```bash
colima start
cd /Users/ranggarijasa/Documents/MSCBodyTransformation
supabase start
supabase db reset --local
```

Reset hanya boleh dijalankan dengan target `--local`. Hosted `main` adalah
production dan tidak boleh dipakai untuk reset, seed percobaan, atau migration
iteration.

## Troubleshooting setelah database reset

Pada Colima, `supabase db reset --local` dapat me-restart container Storage
dengan alamat internal baru sementara gateway lokal masih menyimpan alamat
lama. Gejalanya adalah upload Storage menerima HTTP 502 walaupun Auth dan Data
API berfungsi.

Pastikan masalahnya memang terjadi pada stack lokal, lalu restart hanya
gateway Supabase:

```bash
docker restart supabase_kong_msc-body-transformation
```

Perintah ini tidak menghapus database atau Storage volume. Setelah gateway
aktif kembali, ulangi request upload. Jangan menambahkan retry tanpa batas di
aplikasi untuk menutupi HTTP 502; hosted production harus diperlakukan sebagai
gangguan layanan yang dapat dicoba kembali secara terbatas.

## Pemeriksaan cepat harian

Awal sesi:

```bash
colima start
cd /Users/ranggarijasa/Documents/MSCBodyTransformation
supabase start
```

Akhir sesi:

```bash
cd /Users/ranggarijasa/Documents/MSCBodyTransformation
supabase stop
colima stop
```

Jika hanya mengerjakan UI mock/offline dan tidak membutuhkan Supabase, Colima
boleh tetap mati.
