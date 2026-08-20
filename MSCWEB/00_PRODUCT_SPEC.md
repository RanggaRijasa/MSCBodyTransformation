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
- `PROD-CCH-006` Coach aktif MUST dapat memublikasikan profil yang dapat dibagikan dengan foto profil, nama, dan badge `Coach terverifikasi` yang berasal dari data server-controlled.
- `PROD-CCH-007` Foto profil awal SHOULD berasal dari foto akun Google; Coach MAY menggantinya dengan foto profil yang telah dinormalisasi. Jika Google tidak menyediakan foto, Coach MUST mengunggah foto sebelum profil dapat dipublikasikan. Nama mengikuti profil akun yang berwenang, sedangkan badge MUST NOT dapat diedit oleh Coach.
- `PROD-CCH-008` Headline profesional, cerita/biografi, kota atau area layanan, Instagram, TikTok, website, WhatsApp, nomor telepon, testimoni, dan galeri before–after MUST bersifat opsional.
- `PROD-CCH-009` Setiap field kontak opsional MUST memiliki kontrol publikasi tersendiri. Nilai yang tidak dipublikasikan MUST tidak ikut berada pada public read model, HTML, metadata sosial, atau response Guest.
- `PROD-CCH-010` Semua testimoni/before–after MUST melewati moderation state. Jika konten menampilkan atau mengutip orang lain, Coach juga MUST menyatakan memiliki izin subjek; konten diri sendiri tidak memerlukan attestation pihak ketiga. Bukti program privat MUST NOT dipakai ulang sebagai media profil publik.
- `PROD-CCH-011` Profil publik MUST memakai handle publik stabil dan tombol `Bagikan profil`; raw QR Coach, user UUID privat, dan enrollment identifier MUST NOT berada pada URL atau metadata berbagi.
- `PROD-CCH-012` Badge terverifikasi MUST mengikuti entitlement Coach aktif. Entitlement kedaluwarsa/dicabut MUST menghapus badge dan menutup publikasi profil sampai authority dipulihkan.
- `PROD-CCH-013` Coach aktif MUST tetap dapat mengikuti program sebagai peserta program. Tab Program Coach MUST memakai katalog `Diikuti`, `Tersedia`, dan `Riwayat` serta detail, QR enrollment, pembayaran, aktivitas, dan seluruh limitasi yang sama dengan Participant. Saat mendaftar, Coach MUST memindai QR Coach miliknya sendiri dan MUST NOT memakai QR Coach lain. Program yang Coach dampingi tidak boleh menjadi katalog terpisah; cakupan pendampingan tetap berada pada `Peserta saya`, aktivitas, review, dan leaderboard Coach.

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

### 4.5 Analisis foto makanan dan bintang AI

- `PROD-AI-001` Analisis AI MUST hanya berjalan untuk pertanyaan foto yang secara eksplisit dikonfigurasi sebagai foto makanan/minuman; upload foto lain MUST tidak dikirim ke provider AI.
- `PROD-AI-002` Submission, approval, dan pemberian poin authoritative MUST tidak menunggu hasil AI. Hasil AI adalah feedback sekunder dan MUST NOT mengubah poin, enrollment, role, atau status approval.
- `PROD-AI-003` Untuk foto makanan, sistem MAY menghasilkan estimasi energi, protein, karbohidrat, lemak, insight non-diagnostik dalam Bahasa Indonesia, dan rating 1–5 bintang secara asynchronous.
- `PROD-AI-004` Rating AI MUST menggunakan rubric pertanyaan/program yang dipublikasikan dan kalibrasi favorable: 4 adalah default untuk makanan/minuman yang tampak wajar tanpa pelanggaran jelas; 5 untuk kecocokan kuat; 3 untuk hasil campuran/tidak cukup jelas; 1–2 hanya untuk ketidaksesuaian berat yang terlihat jelas dan confidence tinggi.
- `PROD-AI-005` Policy server `food_rating_policy_v1` MUST mensyaratkan confidence `>= 0.90`, rubric eksplisit, serta reason `not_food_for_required_food` untuk rating 1 atau `severe_explicit_rubric_mismatch` untuk rating 2. Semua outcome 1–2 lain MUST dinaikkan menjadi minimal 3/`uncertain`. AI MUST tidak menilai disiplin, karakter, bentuk tubuh, diagnosis, atau keamanan makanan yang tidak dapat dipastikan secara visual.
- `PROD-AI-006` Rating utama berasal dari AI sehingga Coach tidak perlu memberi bintang pada alur normal. Sistem MUST menyediakan koreksi sekunder untuk assigned Coach dan authorized Admin ketika hasil jelas salah; koreksi memerlukan alasan/audit dan tetap tidak memengaruhi poin.
- `PROD-AI-007` UI MUST membedakan state `Menganalisis`, `Analisis tersedia`, `Tidak dapat dianalisis`, dan `Analisis gagal`; kegagalan/provider outage MUST tidak membuat submission gagal.
- `PROD-AI-008` Provider vision MUST berada di belakang interface internal dan konfigurasi environment. Provider yang kompatibel dengan kontrak OpenAI dapat diganti melalui base URL, API key, model, dan provider ID tanpa mengubah feature/domain code; provider yang tidak kompatibel memerlukan adapter baru.
- `PROD-AI-009` Credential provider MUST hanya berada server-side. Browser MUST NOT menerima API key, raw provider request/response, atau instruksi sistem.
- `PROD-AI-010` Sebelum submit foto makanan, UI MUST menampilkan disclosure singkat bahwa foto akan dianalisis otomatis oleh layanan AI. Baseline tidak memerlukan checkbox consent terpisah, ZDR khusus, DPIA terpisah, atau tombol withdraw khusus.
- `PROD-AI-011` Seluruh insight, alasan rating, label hasil, dan fallback AI yang ditampilkan kepada pengguna MUST menggunakan Bahasa Indonesia yang ramah, ringkas, tidak menghakimi, dan tidak diagnostik. Raw output provider berbahasa lain MUST tidak ditampilkan langsung.
- `PROD-AI-012` Insight utama MUST terdiri dari satu atau dua kalimat Bahasa Indonesia. Setiap kalimat MUST utuh dan tidak lebih dari 80 karakter; gabungan insight MUST tidak lebih dari 160 karakter.
- `PROD-AI-013` Provider baseline MUST OpenRouter dengan model default `google/gemma-4-31b-it:free` dan reasoning dimatikan. Model slug MUST berasal dari konfigurasi server sehingga model OpenRouter lain yang kompatibel dapat dipilih tanpa mengubah feature/domain code.

### 4.6 Ringkasan penjualan Admin

- `PROD-SLS-001` Admin MUST dapat membuka `Ringkasan penjualan` dari `Akses cepat` Dashboard tanpa menambah destination baru pada bottom navigation/sidebar utama.
- `PROD-SLS-002` Penjualan web manual MUST dihitung dari ledger uang authoritative: `verified` sebagai penjualan terverifikasi dan revenue `reversal` yang terhubung ke verified entry sebagai pengurang revenue. Status order `approved` tanpa ledger MUST NOT dihitung sebagai revenue.
- `PROD-SLS-003` Ringkasan minimum MUST menampilkan penjualan terverifikasi bruto, pembalikan, penjualan bersih, jumlah order terverifikasi, rata-rata nilai order bruto, tren harian, jenis pembelian, program terlaris, dan pelanggan teratas.
- `PROD-SLS-004` Baseline MUST mencakup pembelian program dan akses Coach dengan filter `Semua`, `Program`, dan `Akses Coach`. Data StoreKit/Google Play atau commerce channel lain MUST tidak dicampur sampai contract lintas-channel dinormalisasi melalui keputusan terpisah.
- `PROD-SLS-005` Nilai `Menunggu pemeriksaan` MAY ditampilkan sebagai pipeline order terpisah, tetapi MUST NOT dijumlahkan sebagai penjualan atau revenue.
- `PROD-SLS-006` Breakdown sumber pembayaran MUST NOT dibuat dari `declared_method` karena rekening dan QRIS ditampilkan bersama dan field tersebut bukan bukti cara transfer aktual. Gunakan dimensi jenis pembelian/program yang authoritative.
- `PROD-SLS-007` Periode default MUST 30 hari dalam `Asia/Makassar`, dengan pilihan 7/30/90 hari dan rentang khusus maksimal 366 hari. Batas waktu memakai inclusive start dan exclusive end serta selalu menampilkan zona laporan.
- `PROD-SLS-008` Pelanggan teratas hanya menampilkan nama tampilan, jumlah order, dan nilai bersih pada permukaan Admin. Email, nomor HP, member level, rekening, bukti, dan reconciliation reference MUST tidak masuk response overview.
- `PROD-SLS-009` Revenue reversal MAY terdiri dari beberapa entry parsial, tetapi cumulative reversal MUST tidak melebihi verified amount dan setiap entry MUST terkait ke verified ledger entry serta idempotency key. Reversal diakui pada timestamp entry reversal, sehingga net suatu periode MAY negatif.
- `PROD-SLS-010` Pengembalian transfer yang tidak pernah menjadi revenue—late/rejected-but-paid, duplicate transfer, atau overpayment difference—MUST dicatat sebagai exceptional cash adjustment terpisah dan MUST NOT mengurangi sales net. Approved voluntary cancellation yang non-refundable juga tidak membuat reversal.
- `PROD-SLS-011` Setiap order MUST memiliki privacy-safe `customer_reporting_key` server-controlled yang bertahan setelah profile deletion tanpa menyimpan contact snapshot. Sales groups by key; `person_id` hanya dikembalikan bila profil masih ada. Legacy null-owner order yang tidak dapat direkonstruksi MUST dipisah per order dan ditandai unknown, tidak digabung menjadi satu pelanggan.

### 4.7 Pengelolaan gambar unggahan pengguna

- `PROD-MED-001` Admin MUST dapat membuka `Penyimpanan gambar` dari `Akses cepat` Dashboard dan melihat penggunaan gambar pengguna yang dikelola MSC, bukan angka paket/quota Supabase yang di-hardcode.
- `PROD-MED-002` Baseline inventory MUST mencakup bucket user-uploaded `question-photos`, `payment-evidence`, dan `coach-public-media`. Manual Trash/restore/purge hanya untuk eligible `question-photos` dan `coach-public-media`; `payment-evidence` inventory bersifat read-only dan tetap dihapus otomatis oleh kontrak retensi pembayaran. `public-media`, `payment-destination-assets`, PWA/brand assets, video, dan file non-gambar berada di luar scope deletion baseline.
- `PROD-MED-003` Browser MUST menerima opaque media ID dan metadata aman; raw object path, signed URL, bucket-internal namespace, isi gambar, berat, atau reconciliation data MUST tidak muncul pada URL, log, analytics, atau audit response.
- `PROD-MED-004` Admin MUST dapat memindahkan gambar eligible ke `Sampah`, memulihkannya sebelum purge, dan meminta `Hapus permanen` melalui operation beralasan, terkonfirmasi, idempotent, dan diaudit.
- `PROD-MED-005` Memindahkan ke Sampah MUST segera menutup akses Participant/Coach/public melalui private/controlled delivery boundary, tetapi byte Storage tetap dihitung sampai purge berhasil. UI MUST membedakan `Digunakan`, `Dapat dibebaskan`, dan `Sudah dibebaskan`.
- `PROD-MED-006` Gambar MUST dilindungi dari deletion saat pembayaran/evidence masih diperiksa, correction/dispute aktif, food insight masih queued/processing/retry, account cleanup berjalan, atau reference state belum dapat diklasifikasikan dengan aman.
- `PROD-MED-007` Penghapusan gambar bukti yang sudah eligible MUST mempertahankan submission, keputusan, poin, transaction metadata, dan audit. Viewer mengganti media dengan tombstone `Gambar telah dihapus oleh Admin`; poin tidak dihitung ulang.
- `PROD-MED-008` Media Coach yang masih dipublikasikan MUST di-unpublish/didetach secara authoritative sebelum quarantine. Confirmation MUST menjelaskan profil/item publik yang terdampak.
- `PROD-MED-009` Permanent purge MUST dilakukan worker server melalui Supabase Storage API setelah reference/protected-state recheck. SQL `DELETE` terhadap `storage.objects` dan service-role credential di browser MUST dilarang.
- `PROD-MED-010` Batch purge UI hanya MAY untuk item yang sudah berada di Sampah atau orphan/superseded yang tervalidasi, maksimal 100 item per request, dengan impact summary dan reason. Unknown/unclassified media MUST fail closed.
- `PROD-MED-011` `coach-public-media` MUST dimigrasikan menjadi private dan dilayani melalui controlled opaque media gateway sebelum Trash tersedia. Public profile/API MUST memakai opaque media ID, bukan raw Storage path; known legacy direct URL MUST gagal setelah cutover.

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
- Menggunakan analisis foto makanan untuk diagnosis, rekomendasi medis, keputusan poin, atau approval bukti.
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
- `PROD-SUC-007` Coach dapat memublikasikan dan membagikan profil publik yang tetap aman ketika semua field opsional kosong.
- `PROD-SUC-008` Foto makanan menerima feedback macro dan bintang AI secara asynchronous tanpa memperlambat poin/approval, dan provider dapat diganti tanpa mengubah feature code.
- `PROD-SUC-009` Admin dapat merekonsiliasi Ringkasan penjualan manual web ke payment ledger untuk periode WITA tanpa pending/rejected/double-counted commerce atau private payment data.
- `PROD-SUC-010` Admin dapat melihat penggunaan gambar pengguna dan trash/restore/purge media eligible melalui Storage API, sementara protected/shared/unknown media tetap utuh dan domain history/poin/ledger tetap tersedia.
