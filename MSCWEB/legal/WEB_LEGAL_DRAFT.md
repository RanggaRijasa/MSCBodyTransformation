# Legal web — MSC Body Transformation

Status: `DISETUJUI UNTUK PUBLIKASI WEB`

Tanggal berlaku: 21 Agustus 2026  
Nama pengelola: MSC Body Transformation
Email dukungan: ranggarijasa2005@gmail.com 
WhatsApp dukungan: 085241997304

Dokumen ini mengadaptasi struktur legal aplikasi iOS untuk produk web/PWA dan
telah disetujui owner untuk publikasi. Pengelola berkedudukan di Indonesia.

## Draft kebijakan privasi

### Kebijakan privasi MSC Body Transformation

Kebijakan ini menjelaskan bagaimana MSC Body Transformation memproses data saat
Anda menggunakan situs dan PWA MSC Body Transformation.

#### Data yang diproses

Kami dapat memproses nama, alamat email, nomor HP, ID akun, foto profil, peran,
informasi pengajuan Coach, keikutsertaan program, jawaban, berat badan, foto
bukti aktivitas, skor, bukti pembayaran manual, keputusan pemeriksaan, serta
data teknis terbatas yang diperlukan untuk keamanan dan penyelesaian gangguan.
Data teknis tidak boleh berisi password, token, raw QR Coach, berat badan, path
media privat, atau isi bukti pembayaran.

#### Tujuan penggunaan

Data digunakan untuk autentikasi, membuat dan menjaga profil, menghubungkan
Peserta dengan Coach, menjalankan program, memeriksa kiriman, menghitung skor,
menampilkan papan peringkat tanpa berat badan, memproses akses berbayar,
meninjau pengajuan Coach, mencegah penyalahgunaan, serta menjaga keamanan dan
keandalan layanan.

#### Google Auth dan Supabase

Login web menggunakan Google melalui Supabase Auth. Google memproses proses
identitas sesuai kebijakannya, sementara Supabase menyediakan autentikasi,
database, fungsi server, dan penyimpanan media aplikasi. MSC Body
Transformation tidak meminta atau menyimpan password Google Anda. Informasi
yang diterima dari Google dibatasi pada data yang diperlukan untuk membuat dan
menghubungkan akun aplikasi.

#### Pembayaran manual

Pembayaran program web atau akses Coach dapat dilakukan melalui transfer bank
atau QRIS statis yang ditampilkan aplikasi. Bukti pembayaran diunggah ke
penyimpanan privat dan diperiksa Admin secara manual. Pengunggahan bukti tidak
berarti pembayaran telah disetujui atau akses langsung aktif. Aplikasi tidak
meminta PIN, password perbankan, OTP, atau data kartu pembayaran.

File gambar bukti pembayaran dihapus 30 hari setelah diunggah. Jika bukti
masih berstatus dalam pemeriksaan pada hari ke-30, file dipertahankan sampai
keputusan Admin dicatat dan kemudian dihapus. Metadata non-gambar yang
diperlukan untuk transaksi, ledger, audit, pencegahan penyalahgunaan, atau
kewajiban hukum dapat dipertahankan lebih lama sesuai kebijakan retensi yang
disetujui.

#### Foto, berat badan, dan data wellness

Foto bukti aktivitas dan berat badan merupakan data pribadi sensitif. Data ini
hanya diproses untuk kebutuhan program, pemeriksaan, skor, dan dukungan Coach
yang berwenang. Metadata gambar yang tidak diperlukan, termasuk lokasi, dihapus
sebelum unggah bila didukung. Layanan ini berfokus pada wellness dan tidak
memberikan diagnosis atau saran medis.

#### Analisis makanan melalui OpenRouter

Jika pertanyaan program mengaktifkan insight makanan, foto makanan yang dipilih
dapat dikirim oleh fungsi server ke OpenRouter dan model AI yang dikonfigurasi
untuk menghasilkan perkiraan makronutrien dan rating informatif. API key tetap
berada di server dan tidak dikirim ke browser. Hasil AI dapat tidak akurat,
bukan diagnosis, dan tidak boleh digunakan sebagai pengganti saran tenaga
profesional.

Pemrosesan AI hanya berjalan setelah pengguna melihat disclosure pada langkah
foto dan secara sukarela memilih mengunggah foto makanan. Fungsi server hanya
mengirim byte gambar yang telah dinormalisasi dan rubrik program minimum; nama,
email, berat badan, object path, signed URL, serta identitas akun tidak dikirim.
Konfigurasi production menggunakan Gemma 4 26B A4B sebagai model utama dan
Gemma 3 12B sebagai fallback melalui OpenRouter. Provider hosting aktual dapat
berubah sesuai ketersediaan endpoint vision dan batas harga. Pemrosesan, retensi,
logging, dan penggunaan data oleh OpenRouter/provider mengikuti pengaturan
privasi akun production serta kebijakan endpoint yang dipilih; Zero Data
Retention tidak dipaksakan oleh aplikasi. OpenRouter dapat menyimpan metadata
operasional non-isi seperti jumlah token dan latensi. Jika provider tidak
tersedia, insight gagal aman dan tidak memengaruhi kiriman, approval, poin, atau
leaderboard.

#### Pembagian dan penjualan data

Data dibagikan hanya kepada penyedia yang diperlukan untuk menjalankan layanan,
termasuk Google, Supabase, dan—bila fitur insight makanan digunakan—OpenRouter
serta penyedia model yang dipilih. Kami tidak menjual data pribadi untuk
periklanan dan tidak menggunakan data untuk pelacakan lintas situs milik pihak
lain.

#### Penyimpanan, penghapusan, dan keamanan

Data disimpan selama akun, program, keamanan, audit, transaksi, atau kewajiban
hukum masih memerlukannya. Saat akun dihapus, sesi dan akses dicabut dan data
pribadi/media dihapus sesuai kontrak produk. Catatan transaksi, audit, atau
snapshot pemenang yang wajib dipertahankan dapat disimpan dalam bentuk yang
meminimalkan identitas. Media privat tidak boleh berada di cache publik atau
dibagikan melalui URL permanen.

#### Hak dan kontak

Anda dapat memperbarui profil, keluar, atau meminta penghapusan akun melalui
fitur yang tersedia. Pertanyaan privasi atau dukungan dapat dikirim ke:

- Pengelola: MSC Body Transformation
- Email: ranggarijasa2005@gmail.com
- WhatsApp: 085241997304

Hak lain mengikuti hukum yang berlaku di Indonesia.

## Draft ketentuan penggunaan

### Ketentuan penggunaan MSC Body Transformation

Ketentuan ini mengatur penggunaan situs dan PWA MSC Body Transformation yang
dikelola oleh MSC Body Transformation.

#### Penggunaan layanan dan akun Google

Gunakan layanan secara jujur, aman, dan sesuai program. Login web memakai akun
Google melalui Supabase Auth. Anda bertanggung jawab menjaga keamanan akun
Google dan perangkat serta dilarang memakai identitas orang lain atau
mengunggah konten tanpa izin.

#### Informasi wellness

Program berfokus pada kebiasaan dan wellness, bukan layanan medis, diagnosis,
atau pengganti konsultasi profesional. Hentikan aktivitas dan cari bantuan
profesional bila Anda merasa tidak aman atau mengalami keluhan kesehatan.

#### Program, Coach, dan bukti aktivitas

Pendaftaran Peserta memerlukan QR Coach aktif. Kapasitas, jadwal, cutoff,
langkah, bukti, pemeriksaan, skor, dan aturan pemenang mengikuti program yang
dipublikasikan. Kiriman yang belum disetujui tidak memperoleh poin
authoritative. Pemalsuan bukti atau penyalahgunaan akses dapat menyebabkan
kiriman ditolak atau akun dibatasi.

#### Pembayaran manual web

Program web dan akses Coach dapat memakai transfer bank atau QRIS statis.
Gunakan hanya tujuan pembayaran yang sedang ditampilkan di aplikasi. Jangan
mengirim dana ke rekening, nomor, atau QR yang diterima dari sumber lain.

Pembayaran diperiksa Admin secara manual. Bukti yang dikirim dapat disetujui,
ditolak, atau diminta koreksi. Akses baru aktif setelah keputusan authoritative
tercatat; bukti transfer saja tidak menjamin aktivasi. Pengajuan Coach tetap
berstatus Peserta sampai kelayakan, pembayaran, dan persetujuan Admin lengkap.

Pesanan menunggu bukti selama periode yang ditampilkan aplikasi dan menerima
maksimal tiga upaya bukti. Penolakan menyertakan alasan dan, bila tersedia,
kesempatan koreksi. Tidak ada janji SLA pemeriksaan tetap; status authoritative
ditampilkan di aplikasi setelah Admin menyelesaikan pemeriksaan.

Pembayaran yang telah disetujui tidak dapat dibatalkan atau dikembalikan secara
sukarela. Koreksi atau pengembalian dapat diproses bila terjadi pembayaran
duplikat, kesalahan teknis atau rekonsiliasi, penyalahgunaan yang terverifikasi,
atau bila diwajibkan hukum. Sengketa diajukan melalui email atau WhatsApp dukungan
dengan ID pesanan dan kronologi, tanpa mengirim PIN, OTP, password, atau data
perbankan rahasia. Pengajuan sengketa tidak otomatis mengubah status akses sampai
keputusan authoritative dicatat.

#### Insight makanan berbantuan AI

Insight makanan dibuat secara asynchronous melalui OpenRouter/model AI yang
dikonfigurasi. Hasilnya hanya perkiraan informatif, dapat terlambat atau gagal,
dan tidak menentukan skor authoritative. Jangan memakai hasil AI sebagai
diagnosis, resep, atau dasar keputusan medis.

#### Peringkat dan pemenang

Skor authoritative dihitung server dari kiriman yang disetujui, berat badan,
dan penyesuaian yang teraudit. Papan peringkat tidak menampilkan berat badan.
Pemenang mengikuti snapshot final yang dikunci Admin dan syarat hadiah yang
dipublikasikan untuk program terkait.

#### Ketersediaan dan perubahan layanan

Fitur dapat tidak tersedia saat pemeliharaan, gangguan jaringan, kegagalan
provider, atau pemeriksaan keamanan. Perubahan penting pada ketentuan akan
ditampilkan melalui versi terbaru dokumen sebelum atau saat berlaku sesuai
kewajiban hukum.

#### Penegakan dan penghentian akun

Kami dapat membatasi akun atau kiriman yang melanggar aturan, memalsukan bukti,
menyalahgunakan pembayaran, mengganggu layanan, atau membahayakan pengguna
lain. Coach dengan Peserta aktif mungkin perlu menyelesaikan pengalihan sebelum
penghapusan akun dapat diselesaikan.

#### Hukum, sengketa, dan kontak

Ketentuan ini tunduk pada hukum Republik Indonesia. Keluhan diselesaikan terlebih
dahulu melalui dukungan dan musyawarah. Bila tidak terselesaikan, sengketa dapat
diajukan melalui mekanisme penyelesaian sengketa atau pengadilan yang berwenang
di Indonesia sesuai hukum yang berlaku. Pengelola berkedudukan di Indonesia.

- Pengelola: MSC Body Transformation
- Email dukungan: ranggarijasa2005@gmail.com
- WhatsApp dukungan: 085241997304

## Catatan persetujuan owner

- [x] Nama pengelola, kedudukan, email, dan WhatsApp disetujui.
- [x] Disclosure, minimisasi data, Gemma 4 26B A4B dengan fallback Gemma 3 12B, dan tanpa enforcement ZDR disetujui.
- [x] Refund, koreksi, sengketa, serta tanpa janji SLA tetap disetujui.
- [x] Yurisdiksi Indonesia dan mekanisme keluhan disetujui.
- [x] Retensi file bukti 30 hari dan retensi metadata transaksi/audit disetujui.
- [x] Copy disetujui untuk route web production pada 21 Agustus 2026.
