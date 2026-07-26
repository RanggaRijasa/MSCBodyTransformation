# Panduan Data Mock

## Sumber data

Fixture berada di `MSCBodyTransformation/Resources/Fixtures`. `MockSeedData`
memuat dan memvalidasi seluruh file dengan decoder ISO 8601. Identifier,
tanggal, relasi, dan urutan dibuat tetap agar test dapat diulang.

Data meliputi:

- pengguna serta profil Peserta dan Coach;
- program, hari, langkah, dan persyaratan bukti;
- pendaftaran, timbang badan, submission, dan papan peringkat;
- wallet Coach, ledger kuota, undangan, konten, pemenang, dan audit.

## Repository lokal

`InMemoryAppRepository` adalah actor tunggal yang memenuhi protocol per
domain. Setiap proses aplikasi memulai seed baru; perubahan tidak ditulis ke
backend atau database perangkat permanen.

## Skenario Debug

`AppDemoScenario` memilih state awal. Skenario dapat:

- menghapus enrollment Peserta untuk pengenalan;
- menyembunyikan program aktif;
- memindahkan clock efektif ke hari pertama, tengah, atau akhir;
- melengkapi hari sebelumnya;
- mengatur kuota Coach menjadi nol;
- memfilter draft atau program aktif Admin;
- mengunci snapshot pemenang;
- menampilkan loading, offline, izin ditolak, atau repository error.

Semua mutasi memakai fixture dan clock yang sama sehingga launch baru
menghasilkan state identik.

## Reset

Alat Debug Peserta menghapus enrollment, submission, timbang, dan skor lokal
Peserta terpilih. Admin dapat mereset snapshot pemenang hanya pada Debug.
Menutup lalu menjalankan ulang aplikasi juga membuat repository dari seed
awal.

## Menambah fixture

1. Gunakan UUID tetap dan tanggal ISO 8601.
2. Jaga raw value enum yang sudah dipersist.
3. Jangan gunakan nama, foto, berat, atau token milik orang nyata.
4. Perbarui relasi pada semua file terkait.
5. Jalankan suite fixture, domain, repository, dan UI scenario terkait.
6. Jangan menambahkan URL privat atau network call.
