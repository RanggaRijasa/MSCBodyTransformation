# Panduan data lokal

Fixture JSON berada di `MSCBodyTransformation/Resources/Fixtures` dan dimuat
oleh `MockSeedData` ke `InMemoryAppRepository`.

## Kontrak fixture

- `programs.json`: scoring dan commerce program-wide, typed content, typed
  questions, answer key, serta timbang awal/harian/akhir sebagai langkah.
- `enrollments.json`: enrollment dan timbang per enrollment; timbang harian
  membawa `stepID`.
- `submissions.json`: typed answers; foto berada di
  `localPhotoReference`, bukan array evidence.
- `coaches.json`: profil dan QR identifier saja; tidak ada wallet/invite.
- `leaderboard.json`: baseline demo; mutation baru direkonsiliasi oleh service
  scoring yang sama.
- `managed_content.json`: poster pemenang terkait program dan snapshot.

Fixture harus deterministik, tidak memuat token/credential, tidak meniru data
pribadi produksi, dan tetap dapat di-decode tanpa internet.

## Menambah skenario

1. Gunakan UUID stabil.
2. Tambahkan program, enrollment, submission, dan score dengan ID yang cocok.
3. Pastikan satu Peserta hanya mempunyai satu `coachID` aktif.
4. Gunakan semua pertanyaan interaktif sebagai required.
5. Jalankan `jq empty` untuk JSON dan suite `MSCBodyTransformationTests`.

Media deterministik untuk test berada pada test fixture. Jangan menambahkan
tombol “gunakan foto demo” ke UI produksi.
