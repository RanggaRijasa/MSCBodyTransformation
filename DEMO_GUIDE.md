# Panduan demo

Demo Debug berjalan lokal tanpa akun eksternal. Pilih peran dan skenario dari
launcher.

## Admin

1. Buka Dashboard (tab default Admin).
2. Buka Program dan pilih `Buat program baru`.
3. Isi Pengaturan, Konten, lalu Tinjau & terbitkan.
4. Tambahkan artikel, video, form, kuis, serta timbang awal/harian/akhir.
5. Buka program published untuk duplikasi, status publikasi, closure, reopen
   kuis, winner lock, dan poster.

## Peserta

1. Pilih program publik.
2. Pindai QR Coach. QR pertama menetapkan Coach; QR berbeda ditolak.
3. Program gratis aktif langsung pada demo lokal.
4. Kerjakan langkah dalam hari yang sama dengan urutan bebas.
5. Isi seluruh pertanyaan, unggah foto bila diminta, selesaikan kuis sekali,
   dan kirim timbang melalui langkah program.
6. Ganti fokus program untuk membuktikan progres tidak tercampur.

## Coach

1. Dashboard menampilkan peserta yang terikat pada Coach aktif.
2. Program menampilkan program terkait.
3. QR identifier berada di profil/alur identifier Coach.
4. Antrean pemeriksaan menampilkan konteks pertanyaan, jawaban, foto, hasil
   kuis, dan answer key yang diizinkan.
5. Approve/reject merekonsiliasi skor; Coach tidak dapat membuka kuis.

## Skenario penting

- `participant_active`
- `participant_no_program`
- `participant_final_weigh_in`
- `participant_final_leaderboard`
- `coach_identifier`
- `coach_active_participants`
- `coach_review_queue`
- `admin_dashboard`
- `admin_draft_cms`
- `admin_active_program`
- `admin_winner_lock`
- loading, offline, permission denied, dan repository error

Live purchase, Supabase staging, dan StoreKit sandbox memerlukan environment
eksternal dan bukan bagian dari demo lokal.
