# Glosarium Domain

| Istilah | Makna |
| --- | --- |
| Peserta | Pengguna yang mengikuti program dan mengirim bukti. |
| Coach | Pengguna yang mengundang, memantau, dan memeriksa Peserta. |
| Admin | Pengguna istimewa yang mengelola program, orang, konten, skor, dan pemenang. |
| Program | Rangkaian hari transformasi dengan aturan, jadwal, dan skor. |
| Pola program | Cara langkah diselesaikan: mandiri atau mengikuti tanggal terjadwal. |
| Akses program | Aturan bergabung: publik, perlu persetujuan, atau khusus undangan. |
| Kapasitas program | Batas maksimal Peserta; kosong berarti tanpa batas pada draft lokal. |
| Hari program | Satu hari terjadwal yang berisi banyak langkah terurut. |
| Langkah | Aktivitas terurut dengan materi, poin, persyaratan bukti, dan nol atau lebih pertanyaan. |
| Pertanyaan | Input atau elemen informasi terurut yang menjadi anak langsung Langkah. |
| Kuis | Jenis Langkah yang mewajibkan minimal satu pertanyaan. |
| Susunan program | Hierarki terurut Hari program → Langkah → Pertanyaan. |
| Artikel | Langkah berisi petunjuk atau materi teks. |
| Video | Langkah berisi referensi video dan aturan pemutaran. |
| Kuis | Langkah berisi pertanyaan terurut dan elemen penjelas. |
| Bukti | Foto lokal atau jawaban teks yang menyertai penyelesaian langkah. |
| Submission | Catatan pengiriman bukti untuk satu langkah. Di UI disebut pengiriman atau bukti. |
| Menunggu pemeriksaan | Bukti sudah dikirim tetapi belum disetujui Coach. |
| Kuota peserta | Saldo Coach yang terpakai ketika pendaftaran baru berhasil. |
| Undangan | Kode atau QR yang menghubungkan Peserta ke program dan Coach. |
| Pendaftaran | Hubungan Peserta dengan satu program. |
| Berat badan awal/akhir | Nilai privat untuk perhitungan poin berat. |
| Poin langkah | Jumlah poin dari langkah unik yang disetujui. |
| Poin berat | Hasil pembulatan penurunan berat × pengali program. |
| Penyesuaian poin | Koreksi Admin yang disimpan terpisah dari poin lain. |
| Total poin | Poin langkah + poin berat + penyesuaian. |
| Papan peringkat | Urutan Peserta tanpa menampilkan berat badan privat. |
| Snapshot pemenang | Maksimal lima hasil final yang tetap setelah dikunci. |
| Konten aplikasi | Disclaimer atau banner yang memiliki jadwal visibilitas. |
| Fixture | Data JSON deterministik untuk demo dan test lokal. |
| Adapter | Implementasi repository untuk sumber data tertentu. |

Nilai skor di Track A adalah pratinjau lokal. Adapter layanan pusat harus
menjadikan otorisasi dan skor produksi sebagai aturan server-side.
