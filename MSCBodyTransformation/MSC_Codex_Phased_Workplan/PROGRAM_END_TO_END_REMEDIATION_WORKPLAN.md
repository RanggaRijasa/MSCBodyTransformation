# Workplan Perbaikan Program End-to-End

## Status dan otoritas dokumen

Status: implementasi lokal iOS dan kontrak lintas platform selesai; integrasi
produksi menunggu external gate.

Hasil rinci, command verifikasi, dan batas yang belum dapat diuji terdapat di
`PROGRAM_END_TO_END_IMPLEMENTATION_STATUS.md`. Checklist E2E-10 sampai E2E-14
tidak boleh dicentang tanpa Supabase staging, store credential, Android
project, dan perangkat fisik yang relevan.

| Phase | Status eksekusi |
|---|---|
| E2E-00–E2E-08 | Selesai pada local iOS vertical slice dan focused tests |
| E2E-09 | Unit/integration regression selesai; UI kritis dijalankan, full release matrix tetap gate |
| E2E-10 | Schema, RLS dasar, storage, dan dua RPC tersedia; deployment serta operasi server penuh menunggu staging |
| E2E-11 | Contract provisioning tersedia; live store API menunggu credential |
| E2E-12 | StoreKit 2 client adapter tersedia; sandbox dan server verification menunggu environment |
| E2E-13 | OpenAPI shared contract tersedia; implementasi Android menunggu project |
| E2E-14 | Belum selesai; reliability/security/release membutuhkan sistem produksi |

Dokumen ini menjadi sumber keputusan produk dan urutan implementasi
authoritative untuk seluruh siklus program:

```text
Admin membuat dan menerbitkan program
    ↓
Peserta memilih program, memindai QR Coach, dan membayar
    ↓
Peserta menjalankan konten dan mengirim jawaban
    ↓
Coach memantau dan memeriksa submission
    ↓
Server menghitung skor dan progres
    ↓
Admin menutup program, mengunci pemenang, dan menerbitkan poster
```

Jika ada konflik, keputusan dalam dokumen ini menggantikan bagian lama pada:

- `02_PHASE_01_DOMAIN_MODELS_AND_MOCKS.md`
- `04_PHASE_03_PARTICIPANT_EXPERIENCE_UI.md`
- `05_PHASE_04_COACH_EXPERIENCE_UI.md`
- `06_PHASE_05_ADMIN_CMS_UI.md`
- `08_PHASE_07_LOCAL_SCORING_AND_LEADERBOARD.md`
- `10_PHASE_09_SUPABASE_FOUNDATION.md`
- `12_PHASE_11_REAL_DATA_AND_SERVER_OPERATIONS.md`
- `13_PHASE_12_STOREKIT_PROGRAM_PAYMENTS.md`
- `15_PHASE_14_ANDROID_HANDOFF.md`
- `99_SOURCE_MASTER_WORKPLAN.md`

Dokumen fase tersebut harus direkonsiliasi sebelum implementasi fase terkait.
Jangan membangun schema produksi dari konsep lama yang sudah digantikan.

## Keputusan produk yang sudah dikunci

### Coach dan enrollment

- Satu Peserta hanya mempunyai satu Coach aktif.
- QR pertama yang valid menetapkan Coach jika Peserta belum memiliki Coach.
- Setiap pendaftaran program tetap wajib memindai QR Coach.
- Setelah Coach ditetapkan, QR Coach lain harus ditolak sebelum pembayaran.
- Peserta boleh mengikuti beberapa program aktif.
- Semua enrollment aktif memakai Coach aktif Peserta yang sama.
- State program tetap dipisahkan berdasarkan `enrollmentID`.
- Pergantian Coach hanya melalui operasi Admin yang memiliki alasan dan audit.
- Pergantian Coach memperbarui enrollment aktif dan terjadwal secara atomik.
- Enrollment selesai mempertahankan Coach historisnya.

### Akses program

- Semua program yang dapat diikuti bersifat publik di katalog.
- Tidak ada mode persetujuan Admin.
- Tidak ada mode undangan program.
- Tidak ada kode undangan program.
- QR Coach hanya menentukan dan memvalidasi Coach, bukan membuka program.
- Program gratis aktif setelah QR Coach berhasil divalidasi.
- Program berbayar aktif setelah QR Coach dan pembayaran terverifikasi.

### Program dan konten

- Peserta dapat mengikuti beberapa program aktif sekaligus.
- Program mendukung pola terjadwal dan mandiri.
- Program mendukung durasi tetap dan tanggal spesifik yang valid.
- Cover program selalu berupa gambar dengan alternative text; tidak ada
  pemilih jenis cover video.
- Langkah dalam hari yang sama tidak linear dan dapat dikerjakan dalam urutan
  apa pun.
- Akses antarhari tetap mengikuti kebijakan hari lampau dan mendatang.
  Hari mendatang dapat tersedia lebih awal, terkunci, atau disembunyikan.
- Jenis konten:
  - Artikel.
  - Video.
  - Form atau pertanyaan.
  - Kuis.
  - Timbang awal.
  - Timbang harian.
  - Timbang akhir.
- Jenis pertanyaan:
  - Jawaban pendek.
  - Jawaban panjang.
  - Angka.
  - Pilihan tunggal.
  - Pilihan ganda.
  - Pilihan gambar.
  - Unggah foto.
  - Heading.
  - Teks penjelas.
- Tidak ada requirement `photoEvidence` terpisah.
- Tidak ada unggah file umum; `Unggah foto` adalah jawaban foto.
- Tidak ada bukti opsional.
- Semua pertanyaan interaktif wajib diisi.
- Heading dan teks penjelas tidak memerlukan jawaban.
- Submission kosong tidak boleh dibuat.

### Kuis

- Kuis mempunyai answer key.
- Kuis dinilai otomatis.
- Setiap kuis hanya mempunyai satu percobaan.
- Semua pertanyaan harus dijawab sebelum dikirim.
- Jawaban tidak dapat diubah setelah dikirim.
- Peserta melihat jumlah benar, persentase, dan status lulus.
- Peserta tidak melihat answer key atau pertanyaan mana yang salah.
- Coach dan Admin dapat melihat jawaban Peserta dan answer key.
- Nilai minimum kuis ditetapkan di tingkat program.
- Nilai minimum yang sama berlaku untuk seluruh kuis program.
- Poin diberikan untuk setiap jawaban benar.
- Kuis gagal tidak mengunci langkah lain.
- Kuis gagal tidak dihitung sebagai langkah lulus untuk progres penuh.
- Admin dapat membuka satu percobaan baru dengan alasan dan audit.
- Coach tidak dapat membuka percobaan baru.

### Pemeriksaan

- Kelengkapan jawaban divalidasi sebelum mode pemeriksaan diterapkan.
- Artikel tanpa pertanyaan dapat ditandai selesai.
- Video wajib tonton selesai setelah ambang tontonan terpenuhi.
- Video tidak wajib tonton dapat ditandai selesai.
- Kuis selalu diperiksa otomatis.
- Jawaban objektif dapat diperiksa otomatis.
- Jawaban subjektif dan unggah foto dapat diperiksa Coach.
- Submission untuk pemeriksaan Coach hanya dibuat setelah seluruh jawaban
  lengkap.
- Submission pending harus selalu muncul dalam antrean Coach.
- Poin untuk submission Coach diberikan tepat satu kali setelah approval.
- Rejection memungkinkan Peserta memperbaiki dan mengirim ulang.

### Timbang dan scoring

- Timbang awal, timbang harian, dan timbang akhir adalah jenis konten program.
- Timbang tidak lagi menjadi langkah onboarding global.
- Setiap enrollment mempunyai tepat satu timbang awal, satu timbang akhir,
  dan satu timbang harian untuk setiap langkah timbang harian yang selesai.
- Jika poin berat aktif, tepat satu timbang awal dan satu timbang akhir wajib
  tersedia.
- Timbang akhir harus berada setelah timbang awal.
- Timbang hanya dapat dikirim ketika kontennya tersedia.
- Koreksi timbang hanya dilakukan Admin dengan alasan dan audit.
- Coach dapat membaca seluruh riwayat timbang peserta yang ditugaskan pada
  detail privat peserta. Nilai berat tidak tampil di feed atau leaderboard.
- Konfigurasi poin berada di tingkat program:
  - `pointsPerActivity`
  - `pointsPerWeightLossKilogram`
  - `quizPassingPercentage`
- Tidak ada pengaturan poin per langkah.
- Artikel, video, dan form yang selesai memberi `pointsPerActivity` satu kali.
- Setiap jawaban kuis benar memberi `pointsPerActivity`.
- Konten timbang tidak memberi poin aktivitas. Timbang harian hanya memantau
  progres dan tidak menjadi input tambahan untuk poin penurunan berat.
- Poin timbang menggunakan:

```text
weight_loss_kg = max(initial_weight_kg - final_weight_kg, 0)
weight_points = rounded(weight_loss_kg × points_per_weight_loss_kilogram)
```

- Scoring configuration dikunci setelah program mempunyai enrollment.

### Duplikasi program

- `Duplikasikan sebagai draft` membuat program/cohort baru.
- Program baru mendapat ID baru.
- Seluruh day, step, question, option, dan content metadata mendapat ID baru.
- Konten, media, answer key, scoring, kapasitas, dan harga yang diinginkan
  disalin.
- Enrollment, submission, jawaban, timbang, leaderboard, pemenang,
  pembayaran, entitlement, dan store product tidak disalin.
- Tanggal hari baru dihitung berdasarkan offset kalender dari tanggal mulai
  lama ke tanggal mulai baru.
- Perhitungan memakai kalender dan zona waktu program.
- Durasi inklusif dipertahankan secara default.
- Store Product ID tidak dibuat ketika draft baru diduplikasi.

### Commerce lintas platform

- Backend bersama menggunakan Supabase.
- iOS dan Android memakai program, akun, Coach, enrollment, dan entitlement
  yang sama.
- App Store dan Google Play hanya menjadi adapter pembayaran platform.
- Program gratis tidak mempunyai store product.
- Program berbayar mempunyai satu produk unik per program/cohort per platform.
- Product ID lama tidak boleh dipetakan ulang ke program baru.
- Harga program duplikat boleh sama, tetapi Product ID harus baru.
- Admin memilih harga yang diinginkan dari aplikasi.
- Backend memetakan harga ke price point store dan menyediakan produk.
- Private App Store Connect key dan Google service-account credential hanya
  berada di server.
- Harga aktual yang dilihat Peserta berasal dari StoreKit atau Play Billing.
- Pembelian yang terverifikasi memberikan entitlement ke akun aplikasi.
- Entitlement akun berlaku lintas iOS dan Android.
- Refund atau revocation dari platform asal direkonsiliasi oleh backend.

## Hal yang harus dihapus atau dimigrasikan

Jangan mempertahankan konsep lama hanya untuk kompatibilitas UI.

- [x] Hapus `AdminProgramAccess` dan seluruh pilihan akses non-publik.
- [x] Hapus approval enrollment.
- [x] Hapus program invite, typed invite code, dan redemption program invite.
- [x] Hapus Coach wallet, seat credit, dan seat-pack commerce.
- [x] Hapus `photoEvidence` sebagai requirement terpisah.
- [x] Ubah file upload menjadi pertanyaan `photoUpload`.
- [x] Hapus bukti opsional dan `isRequired` pada pertanyaan interaktif.
- [x] Hapus poin dari setiap `ProgramStep`.
- [x] Pindahkan poin ke `ProgramScoringConfiguration`.
- [x] Hapus timbang global dari onboarding Peserta.
- [x] Ubah timbang menjadi step content khusus.
- [x] Ganti model pembayaran harga-only dengan platform product mapping.
- [x] Ganti state Peserta satu-program menjadi state per enrollment.
- [x] Hentikan otorisasi Coach berdasarkan enrollment yang berbeda dari
  `ParticipantProfile.coachID`.

Sebelum menghapus tipe lama, tambahkan migration atau fixture conversion yang
eksplisit. Tidak boleh ada data yang diam-diam berubah arti.

## Arsitektur target

### Dependency direction

```text
SwiftUI / Jetpack Compose
    ↓
Feature State
    ↓
Use Case
    ↓
Repository Protocol
    ↓
Local Adapter atau Supabase Adapter
    ↓
Postgres / Edge Functions / Storage
    ↓
App Store Connect / StoreKit atau Google Play / Play Billing
```

### Aggregate utama

```text
Participant
 ├─ currentCoachID
 └─ Enrollments[]
     ├─ Program
     ├─ coachID snapshot
     ├─ commerce entitlement
     ├─ step submissions
     ├─ quiz attempts
     ├─ weigh-ins
     ├─ score
     └─ progress
```

### Published program contract

Published contract harus memuat seluruh data yang diperlukan Admin, Peserta,
Coach, backend scoring, dan Android:

```text
Program
- identity and lifecycle
- title, summary, category, image cover, alternative text
- pace and duration
- start/end/timezone
- capacity
- past/future day policy
- pricing intent
- platform availability
- scoring configuration
- days
  - relative and/or absolute schedule
  - content steps
    - content kind
    - instructions and media
    - video completion policy
    - verification policy
    - questions
      - type
      - prompt
      - options/media
      - answer key when objective
```

Admin preview dan Peserta runtime wajib menggunakan contract dan renderer yang
sama. Preview tidak boleh membaca field yang hilang ketika program diterbitkan.

### State machine program

```text
draft
→ preparing_commerce
→ scheduled
→ active
→ completed
→ archived
```

Program gratis dapat melewati `preparing_commerce`.

Kesiapan store disimpan terpisah per platform agar iOS dapat diluncurkan lebih
dulu:

```text
not_required
not_requested
provisioning
waiting_for_store
ready
action_required
retired
```

### State machine enrollment

```text
initiated
→ waiting_for_payment
→ active
→ completed
→ cancelled_or_refunded
```

Program gratis berpindah dari `initiated` langsung ke `active` setelah QR Coach
valid.

Enrollment berbayar hanya menjadi aktif setelah transaksi store terverifikasi
server-side. Status lokal perangkat tidak authoritative.

### Commerce mapping

```text
Program internal ID
 ├─ StoreProduct(platform: appStore, unique product ID)
 └─ StoreProduct(platform: playStore, unique product ID)
```

Satu store product hanya boleh dimiliki satu program. Gunakan constraint unik
untuk pasangan platform dan external product ID.

## Urutan implementasi

Setiap fase harus diselesaikan, dibangun, dan diuji sebelum fase berikutnya.
Jangan memulai schema Supabase produksi sebelum Phase E2E-01 sampai E2E-08
menstabilkan domain dan local vertical slice.

---

## Phase E2E-00: Rekonsiliasi Dokumen dan Baseline

### Tujuan

Menghapus ambiguitas sebelum source code dan schema diubah.

### Tugas

- [x] Tandai dokumen ini authoritative pada `00_START_HERE.md`.
- [x] Rekonsiliasi Phase 01, 03, 04, 05, 07, 09, 11, 12, dan 14.
- [x] Hapus requirement lama tentang invite program, wallet, seat credit, dan
  approval enrollment.
- [x] Perbarui kamus istilah UI.
- [x] Buat matriks field Admin → published contract → Peserta → Coach → server.
- [x] Buat inventory tipe/model/use case/repository lama yang akan dimigrasikan.
- [x] Catat fixture dan UI test yang masih bergantung pada konsep lama.
- [x] Simpan baseline build dan test sebelum perubahan domain.

### Exit criteria

- [x] Tidak ada dua dokumen aktif yang mendefinisikan aturan program berbeda.
- [x] Seluruh field program mempunyai consumer yang jelas.
- [x] Baseline build dan test tercatat.

---

## Phase E2E-01: Domain Contract dan Migration Lokal

### Tujuan

Membuat model platform-neutral lengkap tanpa mengubah seluruh UI sekaligus.

### Model target

- [x] `ProgramScoringConfiguration`.
- [x] `ProgramCommerceConfiguration`.
- [x] `ProgramPlatformAvailability`.
- [x] `ProgramContentKind`.
- [x] `ProgramQuestionDefinition`.
- [x] `ProgramQuestionOption`.
- [x] `ProgramQuestionAnswerKey`.
- [x] `ProgramStepCompletionPolicy`.
- [x] `ProgramWeighInKind`.
- [x] `ProgramEnrollmentContext`.
- [x] `StepSubmissionAnswer`.
- [x] `QuizAttemptResult`.
- [x] `ProgramStoreProduct`.
- [x] `ProgramPayment`.
- [x] `ProgramEntitlement`.

### Tugas

- [x] Satukan draft dan published program melalui satu mapping lossless.
- [x] Pindahkan poin dari step ke scoring configuration.
- [x] Tambahkan semua jenis pertanyaan dan answer payload.
- [x] Ganti `fileUpload` menjadi `photoUpload`.
- [x] Tambahkan timbang awal/harian/akhir sebagai content kind.
- [x] Modelkan scheduled-day dan enrollment-relative day.
- [x] Modelkan satu Coach aktif pada Participant.
- [x] Pertahankan snapshot Coach pada enrollment untuk audit.
- [x] Modelkan beberapa enrollment aktif tanpa satu global active program.
- [x] Tambahkan conversion fixture lama ke model baru.
- [x] Tandai API lama deprecated sebelum dihapus.

### Tests

- [x] Draft → published mapping mempertahankan semua field.
- [x] JSON encode/decode stabil.
- [x] Fixture lama dapat dimigrasikan.
- [x] Tidak ada ID collision.
- [x] Beberapa enrollment tidak saling membocorkan state.
- [x] Domain tidak mengimpor SwiftUI, StoreKit, atau Play Billing.

### Exit criteria

- [x] Published program contract lossless.
- [x] Seluruh model dapat dipakai Swift dan Kotlin.
- [x] Build iOS lulus dengan adapter kompatibilitas sementara.

---

## Phase E2E-02: Duplikasi Program dan Penjadwalan

### Tujuan

Membuat program cohort baru dengan konten yang sama dan tanggal yang bergeser
secara aman.

### UX Admin

- [x] Tambahkan aksi `Duplikasikan sebagai draft`.
- [x] Tampilkan nama program baru.
- [x] Tampilkan tanggal mulai baru.
- [x] Hitung tanggal selesai otomatis dari durasi inklusif.
- [x] Izinkan Admin mengubah tanggal selesai sebelum konfirmasi.
- [x] Tampilkan ringkasan pergeseran seluruh hari.
- [x] Salin harga yang diinginkan sebagai nilai awal yang dapat diubah.

### Domain

- [x] Buat `DuplicateProgramAsDraftUseCase`.
- [x] Generate program ID baru.
- [x] Generate day, step, question, dan option ID baru.
- [x] Salin content metadata tanpa menyalin runtime state.
- [x] Pertahankan media immutable melalui reference yang aman.
- [x] Hitung offset tanggal dalam kalender program.
- [x] Pertahankan jarak hari yang sengaja tidak berurutan.
- [x] Gunakan timezone program.
- [x] Jangan menyalin store product mapping.
- [x] Tambahkan `sourceProgramID` untuk lineage dan audit.

### Tests

- [x] 5–15 Juni menjadi 5–15 Juli.
- [x] Jadwal dengan hari yang dilewati mempertahankan offset.
- [x] Durasi melintasi akhir bulan dan tahun.
- [x] Timezone tidak menggeser tanggal.
- [x] Semua ID baru dan unik.
- [x] Runtime data tidak tersalin.
- [x] Harga tersalin, store product tidak tersalin.
- [x] Perubahan draft baru tidak mengubah sumber.

### Exit criteria

- [x] Program duplikat valid sebagai draft independen.
- [x] Preview tanggal baru sama dengan hasil published contract.
- [x] Tidak ada transaksi atau entitlement lama yang dapat terhubung.

---

## Phase E2E-03: Admin CMS Contract Lengkap

### Tujuan

Membuat seluruh keputusan program dapat dikonfigurasi tanpa kontrol redundant.

### Pengaturan program

- [x] Judul, ringkasan, kategori, upload cover gambar, dan alternative text.
- [x] Scheduled atau self-paced.
- [x] Durasi tetap atau tanggal spesifik yang kompatibel.
- [x] Timezone.
- [x] Kapasitas.
- [x] Gratis atau berbayar.
- [x] Harga yang diinginkan.
- [x] Poin aktivitas.
- [x] Poin per kilogram turun.
- [x] Persentase kelulusan kuis.
- [x] Kebijakan hari lampau dan mendatang, termasuk tersedia lebih awal.
- [x] Hapus access-mode picker.
- [x] Hapus approval dan invite settings.
- [x] Hapus poin per langkah.
- [x] Hapus weigh-in window global.

### Content builder

- [x] Salin deskripsi dan seluruh langkah dari satu hari ke satu atau beberapa
  hari tujuan tanpa mengubah nama, nomor, atau tanggal hari tujuan.
- [x] Artikel.
- [x] Video.
- [x] Form.
- [x] Kuis.
- [x] Timbang awal.
- [x] Timbang harian.
- [x] Timbang akhir.
- [x] Semua jenis pertanyaan yang disepakati.
- [x] Answer key editor untuk pertanyaan objektif.
- [x] Photo picker untuk opsi gambar dan photo-upload preview.
- [x] Hapus toggle bukti foto terpisah.
- [x] Hapus optional requirement.

### Publish preflight

- [x] Semua pertanyaan interaktif mempunyai prompt.
- [x] Semua pilihan valid dan unik.
- [x] Kuis mempunyai minimal satu pertanyaan objektif.
- [x] Kuis mempunyai answer key lengkap.
- [x] Persentase kelulusan valid.
- [x] Timbang awal/akhir valid jika scoring berat aktif.
- [x] Content order dan date policy valid.
- [x] Scoring configuration valid.
- [x] Program berbayar memeriksa platform readiness.
- [x] Preview memakai published renderer.

### Tests

- [x] Setiap field Admin bertahan setelah save/reload/publish.
- [x] Kombinasi invalid diblokir dengan pesan Bahasa Indonesia.
- [x] Preview sama dengan Participant renderer.
- [x] Published program tetap read-only.
- [x] Duplikasi published program menghasilkan draft.

### Exit criteria

- [x] Tidak ada kontrol Admin yang tidak mempunyai efek runtime.
- [x] Tidak ada field published yang hanya hidup di UI Admin.

---

## Phase E2E-04: Participant Multi-Program dan Coach Guard

### Tujuan

Mendukung beberapa program aktif dengan satu Coach yang konsisten.

### State

- [x] Ganti snapshot satu active program dengan collection per enrollment.
- [x] Simpan submission, timbang, skor, dan progress per enrollment.
- [x] Tambahkan program-focus selection untuk Home.
- [x] Program focus tidak membatasi program lain.
- [x] Leaderboard selection memakai program/enrollment yang tepat.
- [x] History dan active programs tidak berbagi submission.

### Enrollment

- [x] Semua program tersedia bersifat publik.
- [x] Peserta memilih program sebelum scanner dibuka.
- [x] QR pertama menetapkan Coach jika belum ada.
- [x] QR berikutnya wajib sama dengan Coach aktif.
- [x] QR Coach lain ditolak sebelum purchase flow.
- [x] Coach non-public tetapi approved tetap dapat divalidasi melalui server QR.
- [x] Program gratis membuat enrollment dan leaderboard entry secara atomik.
- [x] Program berbayar masuk purchase flow setelah QR valid.
- [x] Duplicate enrollment mengembalikan enrollment lama secara idempoten.

### Coach transfer

- [x] Hapus pergantian Coach bebas dari flow pendaftaran.
- [x] Tambahkan operasi Admin dengan alasan.
- [x] Update profil dan enrollment aktif/terjadwal atomik.
- [x] Pertahankan Coach enrollment selesai.
- [x] Audit actor, Coach lama, Coach baru, dan alasan.

### Tests

- [x] QR pertama menetapkan Coach.
- [x] QR Coach yang sama diterima pada program kedua.
- [x] QR Coach berbeda ditolak sebelum pembayaran.
- [x] Program A dan B mempunyai progres independen.
- [x] Program A dan B memakai Coach aktif yang sama.
- [x] Transfer Coach tidak mengubah histori selesai.
- [x] Enrollment baru selalu mempunyai leaderboard entry.

### Exit criteria

- [x] Peserta dapat membuka dan menjalankan lebih dari satu program aktif.
- [x] Tidak ada state program yang berasal dari enrollment lain.

---

## Phase E2E-05: Renderer Konten, Form, Foto, dan Video

### Tujuan

Membuat seluruh konten yang disusun Admin dapat dijalankan Peserta.

### Renderer

- [x] Artikel dan instruction media.
- [x] Video dengan resume.
- [x] Ambang wajib tonton.
- [x] Autoplay dengan fallback manual.
- [x] Jawaban pendek dan panjang.
- [x] Angka dengan parsing locale Indonesia.
- [x] Pilihan tunggal.
- [x] Pilihan ganda.
- [x] Pilihan gambar.
- [x] Unggah foto melalui kamera dan PhotosPicker.
- [x] Heading dan teks penjelas.
- [x] Timbang awal, harian, dan akhir.

### Submission

- [x] Jawaban disimpan berdasarkan `questionID`.
- [x] Semua pertanyaan interaktif wajib.
- [x] Submission kosong diblokir di client dan domain.
- [x] Submission kosong diblokir lagi di server contract.
- [x] Step pada hari yang sama tidak saling mengunci.
- [x] Duplicate submit idempotent.
- [x] Rejected submission dapat diperbaiki tanpa kehilangan histori.
- [x] Upload foto mempunyai progress, retry, dan orphan cleanup.

### Tests

- [x] Satu test untuk setiap question type.
- [x] Jawaban kosong tidak dapat dikirim.
- [x] Heading/text tidak dianggap kosong.
- [x] Foto gagal upload dapat dicoba ulang.
- [x] Video completion tidak diberikan dua kali.
- [x] Langkah kedua dapat dikerjakan sebelum langkah pertama pada hari sama.
- [x] Future-day policy tetap diterapkan.

### Exit criteria

- [x] Setiap tipe konten Admin mempunyai renderer produksi.
- [x] Tidak ada generic text/photo fallback yang menghilangkan arti pertanyaan.

---

## Phase E2E-06: Kuis Otomatis Satu Percobaan

### Tujuan

Menyelesaikan lifecycle kuis dan menjaga answer key tetap privat dari Peserta.

### Domain dan scoring

- [x] Validasi semua jawaban tersedia sebelum submit.
- [x] Evaluasi answer key server-compatible dan deterministic.
- [x] Simpan satu attempt authoritative.
- [x] Hitung correct count dan percentage.
- [x] Terapkan `quizPassingPercentage` program-wide.
- [x] Beri `pointsPerActivity` untuk setiap jawaban benar.
- [x] Simpan status passed/failed.
- [x] Kuis failed tidak mengunci step lain.
- [x] Kuis failed tidak dihitung sebagai passed step.
- [x] Jangan kirim answer key melalui Participant DTO.
- [x] Sediakan Coach/Admin DTO dengan answer key sesuai izin.

### Admin override

- [x] `Buka kembali percobaan kuis`.
- [x] Alasan wajib.
- [x] Attempt lama tetap tersimpan.
- [x] Attempt baru mempunyai sequence baru.
- [x] Poin attempt lama dibatalkan/direkonsiliasi secara idempoten.
- [x] Audit lengkap.

### Tests

- [x] Attempt kedua ditolak.
- [x] Semua jawaban benar.
- [x] Sebagian jawaban benar.
- [x] Nilai tepat pada passing threshold.
- [x] Nilai di bawah threshold.
- [x] Poin per jawaban benar.
- [x] Answer key tidak ada pada Participant payload.
- [x] Answer key terlihat oleh Coach/Admin.
- [x] Reopen attempt merekonsiliasi poin.

### Exit criteria

- [x] Kuis berjalan end-to-end tanpa pemeriksaan manual.
- [x] Peserta tidak dapat memperoleh answer key dari response participant.

---

## Phase E2E-07: Timbang sebagai Konten dan Scoring Program-Wide

### Tujuan

Menjadikan timbang sumber poin kedua yang konsisten dengan program dan
enrollment.

### Tugas

- [x] Render timbang awal/harian/akhir sebagai step khusus.
- [x] Validasi availability berdasarkan scheduled/self-paced day.
- [x] Simpan Decimal/numeric.
- [x] Timbang awal/akhir unik per enrollment; timbang harian unik per
  enrollment dan step.
- [x] Blok timbang akhir sebelum timbang awal.
- [x] Hitung poin berat ketika data lengkap.
- [x] Weight gain menghasilkan nol poin.
- [x] Artikel/video/form memberi poin aktivitas satu kali.
- [x] Kuis memberi poin per jawaban benar.
- [x] Timbang tidak memberi poin aktivitas.
- [x] Timbang harian tidak memengaruhi poin penurunan berat.
- [x] Pending Coach review tidak memberi poin.
- [x] Approval/rejection merekonsiliasi poin idempoten.
- [x] Admin correction memerlukan reason dan audit.

### Leaderboard

- [x] Buat entry saat enrollment aktif.
- [x] Pisahkan activity, quiz, weight, dan adjustment points.
- [x] Rank recalculation deterministic.
- [x] Equal-score tie-break terdokumentasi.
- [x] Berat pribadi tidak pernah masuk public leaderboard.

### Tests

- [x] Initial/final uniqueness.
- [x] Beberapa timbang harian tersimpan per langkah tanpa duplikasi.
- [x] Final sebelum initial ditolak.
- [x] Penurunan pecahan kilogram.
- [x] Weight gain.
- [x] Duplicate approval tidak menggandakan poin.
- [x] Adjustment tetap terpisah.
- [x] Multi-program score tidak tercampur.

### Exit criteria

- [x] Satu enrollment baru dapat menghasilkan skor tanpa seed leaderboard.
- [x] Semua sumber poin dapat dijelaskan dari audit input.

---

## Phase E2E-08: Coach Monitoring, Review, dan Program Closure Lokal

### Tujuan

Menyelesaikan sisi Coach dan penutupan Admin menggunakan local repository
sebelum backend produksi.

### Coach

- [x] Roster memakai Coach aktif Peserta dan enrollment terkait.
- [x] Filter program menghitung metrik enrollment yang dipilih.
- [x] Dashboard hanya menghitung program terkait Peserta Coach.
- [x] Expected progress menghitung hari yang seharusnya sudah tersedia.
- [x] Future step tidak membuat Peserta terlihat tertinggal.
- [x] Review queue memuat seluruh pending submission.
- [x] Coach melihat jawaban, foto, dan context pertanyaan.
- [x] Coach melihat hasil kuis dan answer key, tetapi tidak mengubah hasil.
- [x] Coach melihat timbang awal, harian, dan akhir di detail privat peserta.
- [x] Feed Coach dan leaderboard tidak menampilkan nilai berat.
- [x] Approve/reject mempunyai state, retry, dan audit.

### Admin closure

- [x] Pilih program selesai.
- [x] Lihat pending review.
- [x] Lihat timbang akhir yang belum lengkap.
- [x] Lihat peserta dengan kuis failed.
- [x] Terapkan score adjustment dengan alasan.
- [x] Tutup perhitungan setelah blocker diselesaikan.
- [x] Lock winner snapshot.
- [x] Buat poster yang terkait `programID` dan `winnerSnapshotID`.
- [x] Publikasikan poster ke Home.
- [x] Poster program lain tidak tercampur.

### Tests

- [x] Review approval memperbarui skor dan Participant.
- [x] Review rejection tidak memberi poin.
- [x] Expected progress date-aware.
- [x] Winner lock tidak berubah diam-diam.
- [x] Poster terkait snapshot yang benar.
- [x] Penutupan diblokir ketika review masih pending.

### Exit criteria

- [x] Siklus lokal Admin → Peserta → Coach → Admin selesai tanpa fixture siap
  jadi.

---

## Phase E2E-09: Vertical Slice dan Regression Suite Lokal

### Tujuan

Membuktikan kontrak lintas peran sebelum schema Supabase dikunci.

### Scenario wajib

- [x] Admin membuat program baru dari kosong.
- [x] Admin membuat artikel, video, form, kuis, timbang awal, timbang harian,
  dan timbang akhir.
- [x] Admin menerbitkan program.
- [x] Peserta pertama menetapkan Coach melalui QR.
- [x] Peserta mengikuti program gratis.
- [x] Peserta mengikuti program kedua dengan Coach sama.
- [x] QR Coach berbeda ditolak.
- [x] Peserta mengisi semua question type.
- [x] Peserta menyelesaikan kuis satu attempt.
- [x] Coach mereview jawaban subjektif/foto.
- [x] Timbang akhir menghitung weight points.
- [x] Timbang harian tersimpan per langkah tanpa mengubah weight points.
- [x] Leaderboard terisi tanpa seed.
- [x] Admin menutup dan mengunci pemenang.
- [x] Admin menerbitkan poster.
- [x] Admin menduplikasi program ke tanggal baru.

### Automation

- [x] Domain integration test memakai repository kosong.
- [x] UI tests tidak bergantung pada urutan test.
- [ ] Store purchase tetap memakai deterministic local store fixture.
- [ ] Loading, empty, error, offline, permission denied diuji.
- [x] Non-Indonesian device locale tidak menampilkan localization key.
- [ ] Dark mode dan Dynamic Type diuji pada layar baru.

### Exit criteria

- [x] Seluruh scenario lulus dari repository kosong.
- [x] Tidak ada fixture yang membuat leaderboard/enrollment secara manual di
  tengah workflow.
- [x] Contract dinyatakan stabil untuk Supabase schema.

---

## Phase E2E-10: Supabase Schema, RLS, Storage, dan Server Operations

### Tujuan

Membuat backend shared untuk iOS dan Android berdasarkan contract yang sudah
terbukti lokal.

### Schema

- [x] Profiles dan satu current Coach.
- [x] Programs dan lineage `source_program_id`.
- [x] Program scoring configuration.
- [x] Program days dan content steps.
- [x] Questions, options, dan protected answer keys.
- [x] Program enrollments.
- [x] Submission attempts dan answers.
- [x] Quiz attempts/results.
- [x] Weigh-ins.
- [x] Scores dan adjustments.
- [x] Store products per platform.
- [x] Commerce transactions.
- [x] Entitlements.
- [x] Winners dan poster relationship.
- [x] Audit events.
- [x] Jangan membuat invite, wallet, atau seat-credit table.

### Storage

- [x] Public avatar/media buckets.
- [x] Private question-photo bucket.
- [ ] Signed access untuk Coach/Admin terkait.
- [ ] MIME dan size allowlist.
- [ ] Image normalization dan metadata removal.
- [ ] Orphan cleanup.
- [x] Tidak perlu weigh-in evidence bucket jika timbang tidak memakai foto.

### RLS

- [x] Peserta membaca program publik.
- [x] Peserta membaca enrollment dan answer miliknya.
- [x] Peserta tidak membaca answer key.
- [x] Coach membaca Participant dengan current Coach yang sama.
- [x] Coach membaca enrollment/submission terkait.
- [x] Coach membaca answer key untuk review context.
- [x] Coach tidak membaca Participant Coach lain.
- [x] Admin mempunyai operasi terkontrol.
- [x] Role dan Coach tidak dapat diubah sendiri.

### Atomic server operations

- [ ] Publish program.
- [ ] Duplicate program.
- [ ] Assign first Coach from QR.
- [x] Transfer Coach.
- [x] Create free enrollment and leaderboard entry.
- [ ] Initiate paid enrollment.
- [ ] Submit step answers.
- [ ] Submit quiz attempt.
- [ ] Reopen quiz attempt.
- [ ] Review submission.
- [ ] Submit/correct weigh-in.
- [ ] Recalculate score.
- [ ] Lock winners.
- [ ] Publish winner poster.

### Tests

- [ ] Fresh database migration.
- [ ] RLS matrix.
- [ ] Wrong-Coach QR race.
- [ ] Capacity race.
- [ ] Duplicate enrollment.
- [ ] Duplicate submission.
- [ ] Quiz attempt race.
- [ ] Score reconciliation.
- [ ] Evidence privacy.
- [ ] Winner lock.

### Exit criteria

- [ ] iOS staging menjalankan vertical slice dengan Supabase.
- [x] Contract dapat digunakan Android tanpa Swift type.
- [x] Tidak ada service role atau store credential di app.

---

## Phase E2E-11: Store Catalog Provisioning Backend

### Tujuan

Memungkinkan Admin mobile menyiapkan produk App Store dan Google Play melalui
backend yang aman.

### Backend

- [ ] Simpan App Store Connect API credential sebagai server secret.
- [ ] Simpan Google Play service-account credential sebagai server secret.
- [ ] Generate platform Product ID dari program UUID, bukan tanggal/judul.
- [ ] Product ID unik dan tidak dapat dipetakan ulang.
- [ ] Map desired price ke Apple price point.
- [ ] Map desired price ke Google regional pricing.
- [ ] Buat/update metadata store.
- [ ] Simpan external store product internal ID.
- [ ] Poll atau reconcile provisioning/review status.
- [ ] Pisahkan sandbox/staging/production.
- [ ] Jangan menghapus product yang sudah pernah dijual.

### Admin

- [ ] Aksi `Siapkan pembayaran`.
- [ ] Desired price.
- [ ] Actual localized/base price.
- [ ] Product ID per platform.
- [ ] Provisioning status per platform.
- [ ] Review/availability status.
- [ ] Actionable error.
- [ ] Retry yang idempoten.
- [ ] Publish gate per platform.

### Duplikasi

- [ ] Harga desired disalin.
- [ ] Store mapping tidak disalin.
- [ ] Provisioning membuat product baru.
- [ ] Product baru boleh memakai price point sama.

### Tests

- [ ] Fake App Store Connect adapter.
- [ ] Fake Google Play Developer adapter.
- [ ] Same-price duplicate mendapat Product ID berbeda.
- [ ] Retry tidak membuat produk ganda.
- [ ] Price point tidak tersedia menghasilkan actionable error.
- [ ] Secret tidak muncul di response/log.

### Exit criteria

- [ ] Admin dapat memulai provisioning tanpa mengakses store console.
- [ ] Program berbayar tidak publish sebelum platform target siap.

Referensi resmi yang harus diverifikasi kembali saat fase dimulai:

- Apple App Store Connect API, managing in-app purchases.
- Apple In-App Purchase pricing and price schedules.
- Google Play `monetization.onetimeproducts`.
- Google Play regional pricing and product availability.

---

## Phase E2E-12: StoreKit 2 Purchase, Verification, dan Entitlement

### Tujuan

Menjalankan pembelian iOS yang aman dan mengaktifkan enrollment tepat satu
kali.

### Client

- [x] Load Product berdasarkan mapping program.
- [x] Tampilkan `Product.displayPrice`.
- [x] QR Coach valid sebelum payment sheet.
- [x] Success, cancel, pending, unverified, interrupted.
- [x] Transaction updates.
- [x] Restore/relaunch recovery.
- [x] Jangan membuat enrollment dari client-only state.

### Backend

- [ ] Verifikasi Apple-signed transaction.
- [ ] Validasi bundle, environment, participant, program, dan Product ID.
- [ ] Pastikan QR Coach sama dengan current Coach.
- [ ] Insert transaction idempoten.
- [ ] Grant cross-platform entitlement.
- [ ] Create enrollment dan leaderboard entry atomik.
- [ ] App Store Server Notifications V2.
- [ ] Refund dan revocation reconciliation.
- [ ] Audit.

### Tests

- [ ] StoreKit local configuration.
- [ ] Sandbox physical device.
- [ ] Purchase program pertama.
- [ ] Purchase program duplikat harga sama.
- [ ] Product ID berbeda.
- [ ] Duplicate callback.
- [ ] Pending dan recovery.
- [ ] Refund/revocation.
- [ ] Wrong-Coach guard sebelum purchase.

### Exit criteria

- [ ] Verified purchase membuat satu entitlement dan satu enrollment.
- [ ] Harga tidak pernah authoritative dari client.
- [ ] Pembelian cohort lama tidak membuka cohort baru.

---

## Phase E2E-13: Android Contract dan Google Play Billing

### Tujuan

Memastikan port Android memakai backend dan product contract yang sama tanpa
menyalin aturan bisnis ke client.

### Shared contract

- [x] OpenAPI/JSON contract seluruh program flow.
- [x] Enum raw values stabil.
- [x] Data dictionary.
- [x] Error catalog.
- [x] RLS/authorization matrix.
- [x] Commerce and entitlement contract.
- [ ] Sample payload untuk semua question type.
- [ ] Sample scheduled dan self-paced programs.

### Android

- [ ] Kotlin domain mapping.
- [ ] Enrollment-scoped state.
- [ ] Same-Coach QR guard.
- [ ] Semua content renderer native.
- [ ] Photo capture/upload.
- [ ] Quiz one-attempt UI.
- [ ] Weigh-in content.
- [ ] Google Play Billing one-time product.
- [ ] Purchase token dikirim ke backend.
- [ ] Backend verification dan acknowledgement.
- [ ] Real-time developer notifications.
- [ ] Cross-platform entitlement check sebelum menawarkan pembelian.

### Tests

- [ ] Purchase Android memberi entitlement yang terlihat iOS.
- [ ] Purchase iOS memberi entitlement yang terlihat Android.
- [ ] User tidak ditagih dua kali ketika entitlement sudah ada.
- [ ] Google refund mencabut entitlement sesuai policy.
- [ ] Program duplikat memakai Google Product ID baru.

### Exit criteria

- [ ] Android dapat diimplementasikan tanpa membaca SwiftUI untuk business rule.
- [ ] Satu backend entitlement berlaku konsisten pada kedua platform.

---

## Phase E2E-14: Reliability, Security, dan Release Gate

### Tujuan

Menutup failure mode yang hanya muncul pada produksi mobile dan store.

### Reliability

- [ ] Durable upload queue.
- [ ] Background/relaunch recovery.
- [ ] Idempotency key pada semua mutation.
- [ ] Push notification untuk review dan rejection.
- [ ] Deep link ke program/submission terkait.
- [ ] Realtime reconnect dan manual refresh.
- [ ] Store provisioning monitoring.
- [ ] Commerce notification dead-letter/retry.

### Security dan privacy

- [x] Tidak ada answer key pada Participant response.
- [x] Tidak ada berat/foto pada logs.
- [ ] Signed private media access.
- [x] Store secrets hanya server-side.
- [ ] Transaction replay protection.
- [ ] Admin audit lengkap.
- [x] Coach scope berdasarkan current Coach.
- [ ] Account deletion dan data retention review.

### Release gate

- [ ] Full local E2E.
- [ ] Supabase staging E2E.
- [ ] StoreKit sandbox E2E.
- [ ] Google Play test-track E2E ketika Android tersedia.
- [ ] Physical camera/photo tests.
- [ ] Refund and revocation tests.
- [ ] Accessibility audit.
- [ ] Indonesian localization audit.
- [ ] App Review/Play review metadata akurat.

### Exit criteria

- [ ] Tidak ada jalur enrollment atau poin yang hanya dipercaya dari client.
- [ ] Tidak ada konsep lama yang masih dapat dipakai dari UI atau API.
- [ ] Seluruh critical end-to-end tests lulus.

## Matriks acceptance end-to-end

| Flow | Acceptance |
|---|---|
| Program baru | Admin-created program dapat dijalankan tanpa fixture khusus |
| Duplikasi | Konten sama, seluruh ID baru, tanggal bergeser, runtime kosong |
| Coach pertama | QR valid menetapkan Coach sebelum enrollment |
| Coach berbeda | Ditolak sebelum payment sheet |
| Multi-program | Progres, submission, timbang, dan skor terisolasi |
| Form | Semua jawaban interaktif wajib dan typed |
| Foto | Menjadi question answer, bukan evidence terpisah |
| Kuis | Satu attempt, auto-score, answer key privat |
| Timbang | Awal/harian/akhir adalah konten; hanya selisih awal-akhir menjadi weight points |
| Hari mendatang | Dapat tersedia lebih awal, terkunci, atau disembunyikan |
| Cover | Upload gambar tampil pada runtime Peserta dan Coach |
| Scoring | Poin program-wide, idempoten, dapat diaudit |
| Free enrollment | QR → enrollment + leaderboard atomik |
| Paid enrollment | QR → store purchase → verify → entitlement → enrollment |
| Same-price duplicate | Product ID baru, price point boleh sama |
| Cross-platform | Purchase salah satu store membuka entitlement akun |
| Coach review | Pending lengkap terlihat dan keputusan memperbarui skor |
| Closure | Pending blocker selesai sebelum winner lock |
| Poster | Terkait program dan winner snapshot yang benar |
| Refund | Entitlement dan enrollment direkonsiliasi server-side |

## Definition of done keseluruhan

Workplan selesai hanya jika:

- [x] Admin dapat membuat program dari repository kosong.
- [x] Program yang diterbitkan mempertahankan seluruh konfigurasi.
- [x] Peserta dapat mengikuti beberapa program dengan satu Coach.
- [x] QR Coach berbeda selalu ditolak sebelum pembayaran.
- [x] Seluruh content type dapat dijalankan.
- [x] Seluruh question type dapat dijawab.
- [x] Kuis dinilai otomatis satu kali tanpa membocorkan answer key.
- [x] Timbang awal/akhir menghasilkan poin berat yang benar dan timbang
  harian hanya mencatat progres.
- [x] Coach dapat memeriksa seluruh submission yang memerlukan tindakan.
- [x] Enrollment baru otomatis mempunyai leaderboard entry.
- [x] Admin dapat menutup program dan mengunci pemenang.
- [x] Program dapat diduplikasi dengan tanggal dan ID baru.
- [x] Program duplikat berbayar tidak mewarisi store product; provisioning
  contract mewajibkan Product ID baru.
- [ ] Pembayaran iOS terverifikasi server-side.
- [x] Backend contract siap untuk Google Play Billing.
- [ ] Cross-platform entitlement diuji.
- [x] Tidak ada invite, approval enrollment, wallet, seat credit, bukti foto terpisah,
  atau poin per langkah tersisa.

## Progress log

### Log

- 2026-08-02:
  - Dokumen workplan dibuat dari audit program end-to-end dan keputusan produk.
  - Domain, fixture, repository, Admin CMS, Participant renderer, Coach
    review, scoring, closure, duplikasi, StoreKit adapter, OpenAPI, dan
    migration Supabase diremediasi.
  - Konsep invite program, approval enrollment, wallet/seat, evidence
    paralel, poin per langkah, dan timbang onboarding dihapus dari source
    aktif.
  - Build generic iOS dan build iOS Simulator eksplisit lulus.
  - Unit/integration suite lulus: 128 tests dalam 13 suites.
  - Empat UI regression kritis lulus tanpa kegagalan dalam 61,774 detik:
    fixed Program header, fixed Konten header, Indonesian runtime fallback,
    dan Admin default Dashboard.
  - Fixture/localization JSON dan OpenAPI YAML tervalidasi.
  - Supabase CLI/Docker, credential store, Android project, dan device
    production tidak tersedia; E2E-10 sampai E2E-14 tetap external gate.
- 2026-08-03:
  - Cover program dikunci sebagai gambar dan memakai `PhotosPicker`; renderer
    bersama menampilkannya pada Admin preview, Peserta, dan Coach.
  - Label konfigurasi membedakan poin langkah dari poin penurunan berat.
  - Kebijakan hari mendatang ditambah `available` dan diterapkan oleh
    calculator runtime, bukan hanya disimpan oleh Admin.
  - `daily_weigh_in` ditambahkan end-to-end. Record harian terikat ke step,
    tidak memberi poin aktivitas, dan tidak mengubah weight points.
  - Detail privat Coach menampilkan riwayat timbang awal, harian, dan akhir;
    feed serta leaderboard tetap menyembunyikan nilai berat.
  - OpenAPI, draft migration Supabase, fixture, localization, unit test, dan
    UI regression kritis diselaraskan dengan amendment ini.
  - Simulator Debug build/run lulus tanpa warning source; 134
    unit/integration tests lulus.
  - UI journey Admin create/publish dan Coach critical journey dengan timbang
    harian `78,1 kg` lulus.
  - Aksi pilih/ganti dan hapus cover dirapikan menjadi baris aksi native
    dengan target sentuh 44 poin; separator otomatis disembunyikan agar tidak
    muncul garis parsial mengikuti alignment label. Simulator build/run dan
    UI journey Admin create/publish kembali lulus tanpa warning atau failure.
  - Segmented control peran pada pratinjau Admin mengikuti struktur Program
    Peserta: kontrol native `large` berada di luar `ScrollView`, sedangkan
    hanya renderer program di bawahnya yang bergulir. UI regression
    memverifikasi tinggi efektif minimal 48 poin dan posisi vertikal tetap.
  - Mode Edit pada daftar hari hanya dipakai untuk mengatur urutan. Hari
    dihapus langsung melalui swipe ke kiri tanpa dialog. Aksi trailing
    memakai bidang merah seamless tanpa gap dan hanya menampilkan ikon
    sampah. Gerak kartu mengikuti jari lalu settle dengan spring; ikon
    muncul bertahap dengan scale dan opacity. Seluruh konten ikut dihapus,
    urutan dinormalkan, dan tanggal selesai disesuaikan.
  - State swipe hari sekarang direset dalam transaksi yang sama sebelum
    penghapusan. Hari yang ditambahkan kembali tidak mewarisi offset baris
    lama meskipun ID deterministiknya digunakan ulang oleh draft lokal.
    Warna destructive memakai merah `#C62828` yang identik pada light dan
    dark mode. Reset state gesture dilakukan sebelum animasi spring
    penghapusan daftar, sehingga transisi tetap terlihat tanpa mewariskan
    offset lama. Simulator Debug build lulus tanpa warning; UI regression
    `testAdminSwipeDeletesDayWithoutConfirmation` yang mencakup alur hapus
    lalu tambah kembali lulus, 1 test tanpa kegagalan.
  - Editor hari menyediakan `Salin isi ke hari lain` dengan multi-select.
    Deskripsi, langkah, pertanyaan, media reference, dan answer key disalin;
    nama, nomor, serta tanggal hari tujuan dipertahankan. Seluruh ID konten
    hasil salinan dibuat ulang, dan target yang sudah berisi konten meminta
    konfirmasi sebelum diganti. Simulator Debug build lulus tanpa warning,
    suite `Phase05AdminCMSTests` lulus 24 tests, dan UI regression
    `testAdminCopiesDayContentToAnotherDay` lulus tanpa kegagalan.
