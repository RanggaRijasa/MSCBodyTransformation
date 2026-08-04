# Glosarium domain

| Istilah | Arti |
|---|---|
| Program | Cohort publik yang mempunyai kontrak konten, jadwal, scoring, dan commerce sendiri. |
| Draft | Program yang masih dapat diubah Admin. |
| Program diterbitkan | Snapshot read-only; perubahan dibuat melalui duplikasi sebagai draft. |
| Enrollment | Partisipasi satu akun pada satu program. Semua progres dan skor dipisahkan dengan `enrollmentID`. |
| Coach aktif | Satu Coach yang terikat pada profil Peserta. Semua enrollment aktif memakai Coach ini. |
| QR Coach | Identifier opaque untuk menetapkan atau memvalidasi Coach; bukan undangan program. |
| Konten | Artikel, video, form, kuis, timbang awal, timbang harian, atau timbang akhir. |
| Timbang harian | Langkah timbang per hari untuk memantau progres; tidak menambah poin aktivitas dan tidak mengubah perhitungan poin penurunan berat. |
| Pertanyaan interaktif | Pertanyaan yang selalu wajib dijawab sebelum submission. |
| Unggah foto | Jawaban untuk pertanyaan `photo_upload`; tidak ada model bukti terpisah. |
| Submission | Pengiriman lengkap untuk satu langkah pada satu enrollment. |
| Percobaan kuis | Hasil kuis otomatis. Default satu percobaan; Admin dapat membuka sequence baru dengan alasan. |
| Pemeriksaan Coach | Approval/rejection untuk jawaban subjektif atau foto. |
| Scoring program | `pointsPerActivity`, `pointsPerWeightLossKilogram`, dan `quizPassingPercentage` yang berlaku program-wide. |
| Timbang | Konten enrollment-scoped, bukan bagian onboarding global. |
| Entitlement | Hak akun terhadap program berbayar setelah transaksi store diverifikasi backend. |
| Store product | Mapping unik satu cohort ke App Store atau Play Store. |
| Winner snapshot | Hasil final immutable yang menjadi sumber poster pemenang. |
| Poster pemenang | Konten Home yang wajib terkait `programID` dan `winnerSnapshotID`. |
