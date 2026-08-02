# Workplan Perbaikan Program End-to-End

## Status dan otoritas dokumen

Status: direncanakan, belum diimplementasikan.

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
- Langkah dalam hari yang sama tidak linear dan dapat dikerjakan dalam urutan
  apa pun.
- Akses antarhari tetap mengikuti kebijakan hari lampau dan mendatang.
- Jenis konten:
  - Artikel.
  - Video.
  - Form atau pertanyaan.
  - Kuis.
  - Timbang awal.
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

- Timbang awal dan timbang akhir adalah jenis konten program.
- Timbang tidak lagi menjadi langkah onboarding global.
- Setiap enrollment mempunyai timbang awal dan akhir sendiri.
- Jika poin berat aktif, tepat satu timbang awal dan satu timbang akhir wajib
  tersedia.
- Timbang akhir harus berada setelah timbang awal.
- Timbang hanya dapat dikirim ketika kontennya tersedia.
- Koreksi timbang hanya dilakukan Admin dengan alasan dan audit.
- Konfigurasi poin berada di tingkat program:
  - `pointsPerActivity`
  - `pointsPerWeightLossKilogram`
  - `quizPassingPercentage`
- Tidak ada pengaturan poin per langkah.
- Artikel, video, dan form yang selesai memberi `pointsPerActivity` satu kali.
- Setiap jawaban kuis benar memberi `pointsPerActivity`.
- Konten timbang tidak memberi poin aktivitas.
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

- [ ] Hapus `AdminProgramAccess` dan seluruh pilihan akses non-publik.
- [ ] Hapus approval enrollment.
- [ ] Hapus program invite, typed invite code, dan redemption program invite.
- [ ] Hapus Coach wallet, seat credit, dan seat-pack commerce.
- [ ] Hapus `photoEvidence` sebagai requirement terpisah.
- [ ] Ubah file upload menjadi pertanyaan `photoUpload`.
- [ ] Hapus bukti opsional dan `isRequired` pada pertanyaan interaktif.
- [ ] Hapus poin dari setiap `ProgramStep`.
- [ ] Pindahkan poin ke `ProgramScoringConfiguration`.
- [ ] Hapus timbang global dari onboarding Peserta.
- [ ] Ubah timbang menjadi step content khusus.
- [ ] Ganti model pembayaran harga-only dengan platform product mapping.
- [ ] Ganti state Peserta satu-program menjadi state per enrollment.
- [ ] Hentikan otorisasi Coach berdasarkan enrollment yang berbeda dari
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
- title, summary, category, cover
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
- [ ] Rekonsiliasi Phase 01, 03, 04, 05, 07, 09, 11, 12, dan 14.
- [ ] Hapus requirement lama tentang invite program, wallet, seat credit, dan
  approval enrollment.
- [ ] Perbarui kamus istilah UI.
- [ ] Buat matriks field Admin → published contract → Peserta → Coach → server.
- [ ] Buat inventory tipe/model/use case/repository lama yang akan dimigrasikan.
- [ ] Catat fixture dan UI test yang masih bergantung pada konsep lama.
- [ ] Simpan baseline build dan test sebelum perubahan domain.

### Exit criteria

- [ ] Tidak ada dua dokumen aktif yang mendefinisikan aturan program berbeda.
- [ ] Seluruh field program mempunyai consumer yang jelas.
- [ ] Baseline build dan test tercatat.

---

## Phase E2E-01: Domain Contract dan Migration Lokal

### Tujuan

Membuat model platform-neutral lengkap tanpa mengubah seluruh UI sekaligus.

### Model target

- [ ] `ProgramScoringConfiguration`.
- [ ] `ProgramCommerceConfiguration`.
- [ ] `ProgramPlatformAvailability`.
- [ ] `ProgramContentKind`.
- [ ] `ProgramQuestionDefinition`.
- [ ] `ProgramQuestionOption`.
- [ ] `ProgramQuestionAnswerKey`.
- [ ] `ProgramStepCompletionPolicy`.
- [ ] `ProgramWeighInKind`.
- [ ] `ProgramEnrollmentContext`.
- [ ] `StepSubmissionAnswer`.
- [ ] `QuizAttemptResult`.
- [ ] `ProgramStoreProduct`.
- [ ] `ProgramPayment`.
- [ ] `ProgramEntitlement`.

### Tugas

- [ ] Satukan draft dan published program melalui satu mapping lossless.
- [ ] Pindahkan poin dari step ke scoring configuration.
- [ ] Tambahkan semua jenis pertanyaan dan answer payload.
- [ ] Ganti `fileUpload` menjadi `photoUpload`.
- [ ] Tambahkan timbang awal/akhir sebagai content kind.
- [ ] Modelkan scheduled-day dan enrollment-relative day.
- [ ] Modelkan satu Coach aktif pada Participant.
- [ ] Pertahankan snapshot Coach pada enrollment untuk audit.
- [ ] Modelkan beberapa enrollment aktif tanpa satu global active program.
- [ ] Tambahkan conversion fixture lama ke model baru.
- [ ] Tandai API lama deprecated sebelum dihapus.

### Tests

- [ ] Draft → published mapping mempertahankan semua field.
- [ ] JSON encode/decode stabil.
- [ ] Fixture lama dapat dimigrasikan.
- [ ] Tidak ada ID collision.
- [ ] Beberapa enrollment tidak saling membocorkan state.
- [ ] Domain tidak mengimpor SwiftUI, StoreKit, atau Play Billing.

### Exit criteria

- [ ] Published program contract lossless.
- [ ] Seluruh model dapat dipakai Swift dan Kotlin.
- [ ] Build iOS lulus dengan adapter kompatibilitas sementara.

---

## Phase E2E-02: Duplikasi Program dan Penjadwalan

### Tujuan

Membuat program cohort baru dengan konten yang sama dan tanggal yang bergeser
secara aman.

### UX Admin

- [ ] Tambahkan aksi `Duplikasikan sebagai draft`.
- [ ] Tampilkan nama program baru.
- [ ] Tampilkan tanggal mulai baru.
- [ ] Hitung tanggal selesai otomatis dari durasi inklusif.
- [ ] Izinkan Admin mengubah tanggal selesai sebelum konfirmasi.
- [ ] Tampilkan ringkasan pergeseran seluruh hari.
- [ ] Salin harga yang diinginkan sebagai nilai awal yang dapat diubah.

### Domain

- [ ] Buat `DuplicateProgramAsDraftUseCase`.
- [ ] Generate program ID baru.
- [ ] Generate day, step, question, dan option ID baru.
- [ ] Salin content metadata tanpa menyalin runtime state.
- [ ] Pertahankan media immutable melalui reference yang aman.
- [ ] Hitung offset tanggal dalam kalender program.
- [ ] Pertahankan jarak hari yang sengaja tidak berurutan.
- [ ] Gunakan timezone program.
- [ ] Jangan menyalin store product mapping.
- [ ] Tambahkan `sourceProgramID` untuk lineage dan audit.

### Tests

- [ ] 5–15 Juni menjadi 5–15 Juli.
- [ ] Jadwal dengan hari yang dilewati mempertahankan offset.
- [ ] Durasi melintasi akhir bulan dan tahun.
- [ ] Timezone tidak menggeser tanggal.
- [ ] Semua ID baru dan unik.
- [ ] Runtime data tidak tersalin.
- [ ] Harga tersalin, store product tidak tersalin.
- [ ] Perubahan draft baru tidak mengubah sumber.

### Exit criteria

- [ ] Program duplikat valid sebagai draft independen.
- [ ] Preview tanggal baru sama dengan hasil published contract.
- [ ] Tidak ada transaksi atau entitlement lama yang dapat terhubung.

---

## Phase E2E-03: Admin CMS Contract Lengkap

### Tujuan

Membuat seluruh keputusan program dapat dikonfigurasi tanpa kontrol redundant.

### Pengaturan program

- [ ] Judul, ringkasan, kategori, cover, dan alternative text.
- [ ] Scheduled atau self-paced.
- [ ] Durasi tetap atau tanggal spesifik yang kompatibel.
- [ ] Timezone.
- [ ] Kapasitas.
- [ ] Gratis atau berbayar.
- [ ] Harga yang diinginkan.
- [ ] Poin aktivitas.
- [ ] Poin per kilogram turun.
- [ ] Persentase kelulusan kuis.
- [ ] Kebijakan hari lampau dan mendatang.
- [ ] Hapus access-mode picker.
- [ ] Hapus approval dan invite settings.
- [ ] Hapus poin per langkah.
- [ ] Hapus weigh-in window global.

### Content builder

- [ ] Artikel.
- [ ] Video.
- [ ] Form.
- [ ] Kuis.
- [ ] Timbang awal.
- [ ] Timbang akhir.
- [ ] Semua jenis pertanyaan yang disepakati.
- [ ] Answer key editor untuk pertanyaan objektif.
- [ ] Photo picker untuk opsi gambar dan photo-upload preview.
- [ ] Hapus toggle bukti foto terpisah.
- [ ] Hapus optional requirement.

### Publish preflight

- [ ] Semua pertanyaan interaktif mempunyai prompt.
- [ ] Semua pilihan valid dan unik.
- [ ] Kuis mempunyai minimal satu pertanyaan objektif.
- [ ] Kuis mempunyai answer key lengkap.
- [ ] Persentase kelulusan valid.
- [ ] Timbang awal/akhir valid jika scoring berat aktif.
- [ ] Content order dan date policy valid.
- [ ] Scoring configuration valid.
- [ ] Program berbayar memeriksa platform readiness.
- [ ] Preview memakai published renderer.

### Tests

- [ ] Setiap field Admin bertahan setelah save/reload/publish.
- [ ] Kombinasi invalid diblokir dengan pesan Bahasa Indonesia.
- [ ] Preview sama dengan Participant renderer.
- [ ] Published program tetap read-only.
- [ ] Duplikasi published program menghasilkan draft.

### Exit criteria

- [ ] Tidak ada kontrol Admin yang tidak mempunyai efek runtime.
- [ ] Tidak ada field published yang hanya hidup di UI Admin.

---

## Phase E2E-04: Participant Multi-Program dan Coach Guard

### Tujuan

Mendukung beberapa program aktif dengan satu Coach yang konsisten.

### State

- [ ] Ganti snapshot satu active program dengan collection per enrollment.
- [ ] Simpan submission, timbang, skor, dan progress per enrollment.
- [ ] Tambahkan program-focus selection untuk Home.
- [ ] Program focus tidak membatasi program lain.
- [ ] Leaderboard selection memakai program/enrollment yang tepat.
- [ ] History dan active programs tidak berbagi submission.

### Enrollment

- [ ] Semua program tersedia bersifat publik.
- [ ] Peserta memilih program sebelum scanner dibuka.
- [ ] QR pertama menetapkan Coach jika belum ada.
- [ ] QR berikutnya wajib sama dengan Coach aktif.
- [ ] QR Coach lain ditolak sebelum purchase flow.
- [ ] Coach non-public tetapi approved tetap dapat divalidasi melalui server QR.
- [ ] Program gratis membuat enrollment dan leaderboard entry secara atomik.
- [ ] Program berbayar masuk purchase flow setelah QR valid.
- [ ] Duplicate enrollment mengembalikan enrollment lama secara idempoten.

### Coach transfer

- [ ] Hapus pergantian Coach bebas dari flow pendaftaran.
- [ ] Tambahkan operasi Admin dengan alasan.
- [ ] Update profil dan enrollment aktif/terjadwal atomik.
- [ ] Pertahankan Coach enrollment selesai.
- [ ] Audit actor, Coach lama, Coach baru, dan alasan.

### Tests

- [ ] QR pertama menetapkan Coach.
- [ ] QR Coach yang sama diterima pada program kedua.
- [ ] QR Coach berbeda ditolak sebelum pembayaran.
- [ ] Program A dan B mempunyai progres independen.
- [ ] Program A dan B memakai Coach aktif yang sama.
- [ ] Transfer Coach tidak mengubah histori selesai.
- [ ] Enrollment baru selalu mempunyai leaderboard entry.

### Exit criteria

- [ ] Peserta dapat membuka dan menjalankan lebih dari satu program aktif.
- [ ] Tidak ada state program yang berasal dari enrollment lain.

---

## Phase E2E-05: Renderer Konten, Form, Foto, dan Video

### Tujuan

Membuat seluruh konten yang disusun Admin dapat dijalankan Peserta.

### Renderer

- [ ] Artikel dan instruction media.
- [ ] Video dengan resume.
- [ ] Ambang wajib tonton.
- [ ] Autoplay dengan fallback manual.
- [ ] Jawaban pendek dan panjang.
- [ ] Angka dengan parsing locale Indonesia.
- [ ] Pilihan tunggal.
- [ ] Pilihan ganda.
- [ ] Pilihan gambar.
- [ ] Unggah foto melalui kamera dan PhotosPicker.
- [ ] Heading dan teks penjelas.
- [ ] Timbang awal dan akhir.

### Submission

- [ ] Jawaban disimpan berdasarkan `questionID`.
- [ ] Semua pertanyaan interaktif wajib.
- [ ] Submission kosong diblokir di client dan domain.
- [ ] Submission kosong diblokir lagi di server contract.
- [ ] Step pada hari yang sama tidak saling mengunci.
- [ ] Duplicate submit idempotent.
- [ ] Rejected submission dapat diperbaiki tanpa kehilangan histori.
- [ ] Upload foto mempunyai progress, retry, dan orphan cleanup.

### Tests

- [ ] Satu test untuk setiap question type.
- [ ] Jawaban kosong tidak dapat dikirim.
- [ ] Heading/text tidak dianggap kosong.
- [ ] Foto gagal upload dapat dicoba ulang.
- [ ] Video completion tidak diberikan dua kali.
- [ ] Langkah kedua dapat dikerjakan sebelum langkah pertama pada hari sama.
- [ ] Future-day policy tetap diterapkan.

### Exit criteria

- [ ] Setiap tipe konten Admin mempunyai renderer produksi.
- [ ] Tidak ada generic text/photo fallback yang menghilangkan arti pertanyaan.

---

## Phase E2E-06: Kuis Otomatis Satu Percobaan

### Tujuan

Menyelesaikan lifecycle kuis dan menjaga answer key tetap privat dari Peserta.

### Domain dan scoring

- [ ] Validasi semua jawaban tersedia sebelum submit.
- [ ] Evaluasi answer key server-compatible dan deterministic.
- [ ] Simpan satu attempt authoritative.
- [ ] Hitung correct count dan percentage.
- [ ] Terapkan `quizPassingPercentage` program-wide.
- [ ] Beri `pointsPerActivity` untuk setiap jawaban benar.
- [ ] Simpan status passed/failed.
- [ ] Kuis failed tidak mengunci step lain.
- [ ] Kuis failed tidak dihitung sebagai passed step.
- [ ] Jangan kirim answer key melalui Participant DTO.
- [ ] Sediakan Coach/Admin DTO dengan answer key sesuai izin.

### Admin override

- [ ] `Buka kembali percobaan kuis`.
- [ ] Alasan wajib.
- [ ] Attempt lama tetap tersimpan.
- [ ] Attempt baru mempunyai sequence baru.
- [ ] Poin attempt lama dibatalkan/direkonsiliasi secara idempoten.
- [ ] Audit lengkap.

### Tests

- [ ] Attempt kedua ditolak.
- [ ] Semua jawaban benar.
- [ ] Sebagian jawaban benar.
- [ ] Nilai tepat pada passing threshold.
- [ ] Nilai di bawah threshold.
- [ ] Poin per jawaban benar.
- [ ] Answer key tidak ada pada Participant payload.
- [ ] Answer key terlihat oleh Coach/Admin.
- [ ] Reopen attempt merekonsiliasi poin.

### Exit criteria

- [ ] Kuis berjalan end-to-end tanpa pemeriksaan manual.
- [ ] Peserta tidak dapat memperoleh answer key dari response participant.

---

## Phase E2E-07: Timbang sebagai Konten dan Scoring Program-Wide

### Tujuan

Menjadikan timbang sumber poin kedua yang konsisten dengan program dan
enrollment.

### Tugas

- [ ] Render timbang awal/akhir sebagai step khusus.
- [ ] Validasi availability berdasarkan scheduled/self-paced day.
- [ ] Simpan Decimal/numeric.
- [ ] Unik per enrollment dan kind.
- [ ] Blok timbang akhir sebelum timbang awal.
- [ ] Hitung poin berat ketika data lengkap.
- [ ] Weight gain menghasilkan nol poin.
- [ ] Artikel/video/form memberi poin aktivitas satu kali.
- [ ] Kuis memberi poin per jawaban benar.
- [ ] Timbang tidak memberi poin aktivitas.
- [ ] Pending Coach review tidak memberi poin.
- [ ] Approval/rejection merekonsiliasi poin idempoten.
- [ ] Admin correction memerlukan reason dan audit.

### Leaderboard

- [ ] Buat entry saat enrollment aktif.
- [ ] Pisahkan activity, quiz, weight, dan adjustment points.
- [ ] Rank recalculation deterministic.
- [ ] Equal-score tie-break terdokumentasi.
- [ ] Berat pribadi tidak pernah masuk public leaderboard.

### Tests

- [ ] Initial/final uniqueness.
- [ ] Final sebelum initial ditolak.
- [ ] Penurunan pecahan kilogram.
- [ ] Weight gain.
- [ ] Duplicate approval tidak menggandakan poin.
- [ ] Adjustment tetap terpisah.
- [ ] Multi-program score tidak tercampur.

### Exit criteria

- [ ] Satu enrollment baru dapat menghasilkan skor tanpa seed leaderboard.
- [ ] Semua sumber poin dapat dijelaskan dari audit input.

---

## Phase E2E-08: Coach Monitoring, Review, dan Program Closure Lokal

### Tujuan

Menyelesaikan sisi Coach dan penutupan Admin menggunakan local repository
sebelum backend produksi.

### Coach

- [ ] Roster memakai Coach aktif Peserta dan enrollment terkait.
- [ ] Filter program menghitung metrik enrollment yang dipilih.
- [ ] Dashboard hanya menghitung program terkait Peserta Coach.
- [ ] Expected progress menghitung hari yang seharusnya sudah tersedia.
- [ ] Future step tidak membuat Peserta terlihat tertinggal.
- [ ] Review queue memuat seluruh pending submission.
- [ ] Coach melihat jawaban, foto, dan context pertanyaan.
- [ ] Coach melihat hasil kuis dan answer key, tetapi tidak mengubah hasil.
- [ ] Approve/reject mempunyai state, retry, dan audit.

### Admin closure

- [ ] Pilih program selesai.
- [ ] Lihat pending review.
- [ ] Lihat timbang akhir yang belum lengkap.
- [ ] Lihat peserta dengan kuis failed.
- [ ] Terapkan score adjustment dengan alasan.
- [ ] Tutup perhitungan setelah blocker diselesaikan.
- [ ] Lock winner snapshot.
- [ ] Buat poster yang terkait `programID` dan `winnerSnapshotID`.
- [ ] Publikasikan poster ke Home.
- [ ] Poster program lain tidak tercampur.

### Tests

- [ ] Review approval memperbarui skor dan Participant.
- [ ] Review rejection tidak memberi poin.
- [ ] Expected progress date-aware.
- [ ] Winner lock tidak berubah diam-diam.
- [ ] Poster terkait snapshot yang benar.
- [ ] Penutupan diblokir ketika review masih pending.

### Exit criteria

- [ ] Siklus lokal Admin → Peserta → Coach → Admin selesai tanpa fixture siap
  jadi.

---

## Phase E2E-09: Vertical Slice dan Regression Suite Lokal

### Tujuan

Membuktikan kontrak lintas peran sebelum schema Supabase dikunci.

### Scenario wajib

- [ ] Admin membuat program baru dari kosong.
- [ ] Admin membuat artikel, video, form, kuis, dan timbang.
- [ ] Admin menerbitkan program.
- [ ] Peserta pertama menetapkan Coach melalui QR.
- [ ] Peserta mengikuti program gratis.
- [ ] Peserta mengikuti program kedua dengan Coach sama.
- [ ] QR Coach berbeda ditolak.
- [ ] Peserta mengisi semua question type.
- [ ] Peserta menyelesaikan kuis satu attempt.
- [ ] Coach mereview jawaban subjektif/foto.
- [ ] Timbang akhir menghitung weight points.
- [ ] Leaderboard terisi tanpa seed.
- [ ] Admin menutup dan mengunci pemenang.
- [ ] Admin menerbitkan poster.
- [ ] Admin menduplikasi program ke tanggal baru.

### Automation

- [ ] Domain integration test memakai repository kosong.
- [ ] UI tests tidak bergantung pada urutan test.
- [ ] Store purchase tetap memakai deterministic local store fixture.
- [ ] Loading, empty, error, offline, permission denied diuji.
- [ ] Non-Indonesian device locale tidak menampilkan localization key.
- [ ] Dark mode dan Dynamic Type diuji pada layar baru.

### Exit criteria

- [ ] Seluruh scenario lulus dari repository kosong.
- [ ] Tidak ada fixture yang membuat leaderboard/enrollment secara manual di
  tengah workflow.
- [ ] Contract dinyatakan stabil untuk Supabase schema.

---

## Phase E2E-10: Supabase Schema, RLS, Storage, dan Server Operations

### Tujuan

Membuat backend shared untuk iOS dan Android berdasarkan contract yang sudah
terbukti lokal.

### Schema

- [ ] Profiles dan satu current Coach.
- [ ] Programs dan lineage `source_program_id`.
- [ ] Program scoring configuration.
- [ ] Program days dan content steps.
- [ ] Questions, options, dan protected answer keys.
- [ ] Program enrollments.
- [ ] Submission attempts dan answers.
- [ ] Quiz attempts/results.
- [ ] Weigh-ins.
- [ ] Scores dan adjustments.
- [ ] Store products per platform.
- [ ] Commerce transactions.
- [ ] Entitlements.
- [ ] Winners dan poster relationship.
- [ ] Audit events.
- [ ] Jangan membuat invite, wallet, atau seat-credit table.

### Storage

- [ ] Public avatar/media buckets.
- [ ] Private question-photo bucket.
- [ ] Signed access untuk Coach/Admin terkait.
- [ ] MIME dan size allowlist.
- [ ] Image normalization dan metadata removal.
- [ ] Orphan cleanup.
- [ ] Tidak perlu weigh-in evidence bucket jika timbang tidak memakai foto.

### RLS

- [ ] Peserta membaca program publik.
- [ ] Peserta membaca enrollment dan answer miliknya.
- [ ] Peserta tidak membaca answer key.
- [ ] Coach membaca Participant dengan current Coach yang sama.
- [ ] Coach membaca enrollment/submission terkait.
- [ ] Coach membaca answer key untuk review context.
- [ ] Coach tidak membaca Participant Coach lain.
- [ ] Admin mempunyai operasi terkontrol.
- [ ] Role dan Coach tidak dapat diubah sendiri.

### Atomic server operations

- [ ] Publish program.
- [ ] Duplicate program.
- [ ] Assign first Coach from QR.
- [ ] Transfer Coach.
- [ ] Create free enrollment and leaderboard entry.
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
- [ ] Contract dapat digunakan Android tanpa Swift type.
- [ ] Tidak ada service role atau store credential di app.

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

- [ ] Load Product berdasarkan mapping program.
- [ ] Tampilkan `Product.displayPrice`.
- [ ] QR Coach valid sebelum payment sheet.
- [ ] Success, cancel, pending, unverified, interrupted.
- [ ] Transaction updates.
- [ ] Restore/relaunch recovery.
- [ ] Jangan membuat enrollment dari client-only state.

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

- [ ] OpenAPI/JSON contract seluruh program flow.
- [ ] Enum raw values stabil.
- [ ] Data dictionary.
- [ ] Error catalog.
- [ ] RLS/authorization matrix.
- [ ] Commerce and entitlement contract.
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

- [ ] Tidak ada answer key pada Participant response.
- [ ] Tidak ada berat/foto pada logs.
- [ ] Signed private media access.
- [ ] Store secrets hanya server-side.
- [ ] Transaction replay protection.
- [ ] Admin audit lengkap.
- [ ] Coach scope berdasarkan current Coach.
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
| Timbang | Konten khusus dan sumber weight points |
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

- [ ] Admin dapat membuat program dari repository kosong.
- [ ] Program yang diterbitkan mempertahankan seluruh konfigurasi.
- [ ] Peserta dapat mengikuti beberapa program dengan satu Coach.
- [ ] QR Coach berbeda selalu ditolak sebelum pembayaran.
- [ ] Seluruh content type dapat dijalankan.
- [ ] Seluruh question type dapat dijawab.
- [ ] Kuis dinilai otomatis satu kali tanpa membocorkan answer key.
- [ ] Timbang menghasilkan poin berat yang benar.
- [ ] Coach dapat memeriksa seluruh submission yang memerlukan tindakan.
- [ ] Enrollment baru otomatis mempunyai leaderboard entry.
- [ ] Admin dapat menutup program dan mengunci pemenang.
- [ ] Program dapat diduplikasi dengan tanggal dan ID baru.
- [ ] Program duplikat berbayar memakai store products baru.
- [ ] Pembayaran iOS terverifikasi server-side.
- [ ] Backend contract siap untuk Google Play Billing.
- [ ] Cross-platform entitlement diuji.
- [ ] Tidak ada invite, approval, wallet, seat credit, bukti foto terpisah,
  atau poin per langkah tersisa.

## Progress log

### Log

- 2026-08-02:
  - Dokumen workplan dibuat dari audit program end-to-end dan keputusan produk.
  - Belum ada source code, schema, StoreKit, Supabase, atau Android yang
    diubah.
  - Langkah berikutnya adalah Phase E2E-00, rekonsiliasi dokumen dan baseline.
