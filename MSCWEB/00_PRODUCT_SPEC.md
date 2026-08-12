# 00 — Product specification

## 1. Visi

MSCWEB adalah web app/PWA Bahasa Indonesia yang memindahkan pengalaman dan kemampuan aplikasi iPhone MSC Body Transformation ke browser modern. Pada layar ponsel, produk harus terasa seperti aplikasi mobile yang sengaja dirancang—bukan situs desktop yang diperkecil. Pada tablet dan desktop, produk harus memanfaatkan ruang tambahan tanpa mengubah aturan bisnis.

Target produk:

- dapat dibuka melalui landing page pada domain milik MSC;
- dapat dipasang ke Home Screen sebagai PWA;
- mendukung Guest, Participant, Coach, dan Admin sesuai authority model aplikasi iOS;
- menggunakan Google sebagai satu-satunya metode autentikasi web pada baseline ini;
- menggunakan transfer bank atau QRIS statis dengan upload bukti dan pemeriksaan visual Admin;
- menggunakan Supabase untuk database, Auth, Storage, dan operasi server-authoritative;
- menggunakan Cloudflare Workers Static Assets untuk hosting frontend dan domain.

## 2. Prinsip produk

- `PROD-001` Web MUST mempertahankan aturan program, eligibility, scoring, enrollment, review bukti, dan role authority dari kontrak produk iOS kecuali dokumen web ini menyatakan adaptasi eksplisit.
- `PROD-002` UI produksi MUST berbahasa Indonesia, menggunakan locale `id-ID`, dan memakai istilah dari UI reference iOS.
- `PROD-003` Guest MUST tetap merupakan keadaan logged-out, bukan role keempat dan bukan anonymous Supabase user.
- `PROD-004` UI client MUST NOT menjadi sumber kebenaran untuk role, pembayaran, enrollment, entitlement, approval bukti, atau skor.
- `PROD-005` PWA MUST menyediakan pengalaman yang berguna pada browser biasa; instalasi PWA adalah enhancement, bukan syarat pemakaian.
- `PROD-006` Web MUST jelas membedakan tindakan yang masih menunggu pemeriksaan, disetujui, ditolak, kedaluwarsa, atau gagal.
- `PROD-007` Data berat badan, foto bukti program, foto bukti pembayaran, dan identitas QR Coach MUST diperlakukan sebagai data privat.
- `PROD-008` Semua perubahan product contract MUST memiliki requirement, acceptance criteria, serta ADR bila mengubah keputusan arsitektur.

## 3. Pengguna dan authority

### 3.1 Guest

Guest dapat membuka landing page dan shell Participant publik, melihat program yang memang dipublikasikan, leaderboard/pemenang yang aman untuk publik, dan profil Coach publik. Guest tidak boleh menerima data privat/cached milik akun lain.

- `PROD-GST-001` Setiap mutasi personal MUST melewati centralized authentication gate.
- `PROD-GST-002` Tujuan auth default MUST halaman `Masuk dengan Google`, lalu kembali ke intent awal setelah login berhasil.
- `PROD-GST-003` Guest MUST NOT menerima profile, enrollment, berat badan, submission, media privat, pembayaran, atau current-Coach data.

### 3.2 Participant

Participant dapat memilih program, memindai QR Coach, membayar program berbayar, mengikuti aktivitas harian, mengunggah bukti, mengisi berat, melihat status review, poin, leaderboard, pemenang, Coach saat ini, dan profil.

- `PROD-PTC-001` Participant MUST memilih program aktif yang terlihat sebelum enrollment.
- `PROD-PTC-002` Enrollment MUST memvalidasi QR unik Coach. Tidak boleh ada input kode manual, copyable raw identifier, atau fallback invite code.
- `PROD-PTC-003` Program gratis MUST dapat lanjut dari QR valid ke enrollment atomik tanpa payment request.
- `PROD-PTC-004` Program berbayar MUST menunggu approval bukti pembayaran sebelum entitlement/enrollment aktif.
- `PROD-PTC-005` Completion dan poin authoritative MUST mengikuti aturan program yang dipublikasikan dan tidak boleh terduplikasi.

### 3.3 Coach

Coach memiliki dashboard, QR pendaftaran unik, peserta yang ditangani, antrian review, aktivitas terbaru, program, leaderboard yang diizinkan, dan profil.

- `PROD-CCH-001` Pendaftaran Coach selalu dimulai dari akun Participant.
- `PROD-CCH-002` Applicant MUST memenuhi level minimal SC serta attestasi HOM STS dan ICT yang disyaratkan.
- `PROD-CCH-003` Pembayaran terverifikasi tidak otomatis sama dengan approval Coach; activation tetap membutuhkan keputusan Admin authoritative.
- `PROD-CCH-004` Coach MUST hanya dapat mengakses participant/submission yang berada dalam scope relasi dan programnya.
- `PROD-CCH-005` Keputusan bukti aktivitas MUST idempotent, diaudit, dan penolakan MUST memiliki alasan.

### 3.4 Admin

Admin mengelola program, orang, konten, review pembayaran, eligibility Coach, koreksi skor, enrollment fallback yang memang diotorisasi kontrak, dan pemenang.

- `PROD-ADM-001` Role Admin MUST berasal dari data server-controlled, bukan metadata profil yang dapat diedit pengguna.
- `PROD-ADM-002` Admin MUST dapat menyaring payment request yang perlu tindakan, membuka bukti ukuran penuh, lalu menyetujui atau menolak.
- `PROD-ADM-003` Semua keputusan sensitif MUST mencatat actor, waktu, target, before/after status, dan alasan jika ditolak/dikoreksi.
- `PROD-ADM-004` Client Admin MUST NOT menulis role, entitlement, enrollment, atau skor secara langsung ke tabel.

## 4. Kemampuan produk

### 4.1 Landing dan akuisisi

- `PROD-LND-001` Root domain MUST memiliki landing page cepat, responsif, indexable, dan konsisten dengan brand hitam-merah-kuning.
- `PROD-LND-002` CTA utama MUST membawa pengguna ke aplikasi/Google login; CTA sekunder MAY menampilkan program aktif publik.
- `PROD-LND-003` Landing MUST menjelaskan bahwa pembayaran diperiksa manual dan aktivasi tidak instan.
- `PROD-LND-004` Landing MUST memiliki tautan kebijakan privasi, ketentuan, bantuan pembayaran, dan install-app guidance.

### 4.2 Program Participant

- `PROD-PRG-001` Katalog MUST memiliki `Diikuti`, `Tersedia`, dan `Riwayat` seperti aplikasi iOS.
- `PROD-PRG-002` Detail program MUST menampilkan poster, jadwal, timezone, harga, status, Coach terkait, dan CTA yang sesuai state.
- `PROD-PRG-003` Aktivitas MUST mendukung artikel, video, form, quiz satu percobaan, pertanyaan teks/pilihan/foto, serta timbang awal/harian/akhir sesuai published definition.
- `PROD-PRG-004` Daftar aktivitas MUST memakai day accordion, membuka hari relevan, dan menjelaskan locked/pending/rejected state tanpa mengandalkan warna saja.
- `PROD-PRG-005` Bukti foto program MUST memakai upload/picker nyata, dinormalisasi, dikecilkan, dan dibersihkan metadata lokasi sebelum penyimpanan.

### 4.3 Leaderboard dan pemenang

- `PROD-LDB-001` Leaderboard publik MUST NOT menampilkan berat badan privat.
- `PROD-LDB-002` Poin authoritative berasal dari approved step points, weight points, dan adjustment points.
- `PROD-LDB-003` Winner lock MUST menghasilkan snapshot stabil; UI MUST menangani seri dan kurang dari lima pemenang.

### 4.4 Coach dan Admin

- `PROD-OPS-001` Coach dashboard MUST mempertahankan quick actions utama iOS: periksa bukti, peserta saya, aktivitas terbaru, peringkat, program saya, dan QR pendaftaran.
- `PROD-OPS-002` Review bukti aktivitas MUST menampilkan konteks Participant/program/hari/step, media atau jawaban, riwayat, serta tindakan `Tolak` dan `Setujui` yang jelas.
- `PROD-OPS-003` Admin navigation MUST mempertahankan Dashboard, Program, Orang, Konten, dan Pengaturan.
- `PROD-OPS-004` Admin People MUST mempertahankan segment Peserta, Coach, dan Admin serta pending-application workflow.
- `PROD-OPS-005` Preview program Admin MUST memakai renderer yang sama dengan experience Participant agar preview tidak menyimpang dari hasil publikasi.

## 5. Adaptasi web yang disengaja

| Area | iPhone | MSCWEB |
|---|---|---|
| Pembayaran | StoreKit/provider commerce pada fase iOS | transfer bank atau QRIS statis, bukti foto, review Admin |
| Auth | kontrak dapat mencakup Apple/Google/email sesuai fase | Google saja pada baseline web |
| Back navigation | NavigationStack dan edge gesture native | browser history sebagai authority; tombol Back dan gesture browser menghasilkan state yang sama |
| Tab compact | native bottom tab/Liquid Glass | bottom tab app-like dengan safe area dan fallback visual non-glass |
| Wide screen | iPad adaptation | navigation rail/sidebar dan layout dua kolom bila membantu |
| Camera QR | native camera | `getUserMedia` bila tersedia; file/image scan MAY menjadi fallback hanya bila tidak mengekspos raw code |
| Install | App Store | browser install prompt / Add to Home Screen |

## 6. Non-goals baseline

- Meniru API atau visual Liquid Glass secara palsu pada browser yang tidak mendukung efek terkait.
- Menjanjikan offline mutation atau upload saat koneksi tidak ada.
- Auto-verification transfer dari screenshot.
- Payment gateway, VA dinamis, atau QRIS dinamis.
- Mengganti backend Supabase dengan Cloudflare D1/KV.
- Membuat ulang icon menggunakan `div`, CSS drawing, emoji, atau icon family acak.
- Menyalin SF Symbols ke web.

## 7. Success criteria

- `PROD-SUC-001` Seluruh capability iPhone yang in-scope memiliki baris parity dan acceptance test.
- `PROD-SUC-002` Pengguna baru dapat membuka landing, login Google, scan QR Coach, mengirim bukti bayar, menerima approval, dan masuk program tanpa jalur manual di luar sistem.
- `PROD-SUC-003` Applicant Coach dapat mengirim bukti dan hanya menjadi Coach setelah satu operasi Admin authoritative yang berhasil.
- `PROD-SUC-004` UI compact lulus visual comparison pada ukuran target iPhone dan tidak terlihat seperti desktop cards yang dipadatkan.
- `PROD-SUC-005` Tidak ada akses silang terhadap foto bukti, bukti pembayaran, berat, atau raw QR identifier dalam pengujian RLS.
- `PROD-SUC-006` PWA dapat dipasang, membuka route yang benar, dan memberi shell/status offline yang jujur.

