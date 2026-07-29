# Panduan Demo Lokal

## Menjalankan

1. Buka `MSCBodyTransformation.xcodeproj`.
2. Pilih scheme `MSCBodyTransformation` dengan konfigurasi Debug.
3. Jalankan pada simulator iPhone atau iPad.
4. Pilih peran dan skenario, tunggu status sesi siap, lalu pilih **Masuk ke demo**.

Demo tidak membutuhkan internet, akun eksternal, API key, Supabase, OAuth,
atau transaksi App Store.

## Launch argument

Skenario dapat dibuka langsung untuk demo dan UI test:

```text
-AppleLanguages (id)
-AppleLocale id_ID
-DemoRole participant|coach|admin
-DemoScenario <nama_skenario>
-SkipDemoLanding
```

Skenario bersama:

- `logged_out`
- `loading`
- `offline`
- `permission_denied`
- `repository_error`

Skenario Peserta:

- `participant_onboarding`
- `participant_no_program`
- `participant_active`
- `participant_day_1`
- `participant_mid_program`
- `participant_final_weigh_in`
- `participant_final_leaderboard`

Skenario Coach:

- `coach_wallet_zero`
- `coach_active_participants`
- `coach_review_queue`

Skenario Admin:

- `admin_draft_cms`
- `admin_active_program`
- `admin_winner_lock`

Nama lama `admin_draft_editor` dan `error` tetap diterima agar UI test lama
tidak terputus. Skenario `participant_active` mengikuti tanggal aktif saat
aplikasi dijalankan.

## Alur demo

Peserta:

1. Gunakan skenario pengenalan.
2. Masuk, isi profil, setujui informasi kebugaran, dan pindai QR demo.
3. Gabung program, isi berat awal, lalu gunakan foto contoh lokal.
4. Selesaikan langkah dan lihat progres serta papan peringkat.
5. Buka skenario penimbangan akhir dan peringkat final.

Coach:

1. Lihat ringkasan dan daftar peserta.
2. Buka antrean pemeriksaan, lihat bukti, lalu setujui atau tolak.
3. Buat undangan dan bagikan QR lokal.
4. Buka pratinjau kuota. Konfirmasi hanya menambah data lokal.

Admin:

1. Buat draft, atur tanggal, hari, langkah, skor, dan pratinjau.
2. Simulasikan publikasi.
3. Buka Orang untuk persetujuan Coach dan pendaftaran manual.
4. Kelola papan peringkat, kunci pemenang, lalu buat banner pemenang.

## Batasan perangkat

Pemilih foto, foto contoh, video lokal, QR demo, dan input manual berfungsi
di simulator. Kamera dan pemindaian nyata memerlukan perangkat fisik serta
`NSCameraUsageDescription` pada target Xcode. Kunci tersebut sudah tersedia;
uji kestabilan kamera tetap dilakukan pada perangkat fisik multi-camera.

Gunakan data yang tidak sensitif. Seluruh nilai berat dan bukti pada demo
adalah fixture lokal dan tidak diverifikasi layanan pusat.
