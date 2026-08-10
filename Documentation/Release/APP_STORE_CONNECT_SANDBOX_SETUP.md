# App Store Connect Sandbox Setup

Dokumen ini adalah handoff manual Phase 13.1. Jangan menyimpan password Sandbox,
private key `.p8`, Supabase secret key, signed transaction, atau credential
lain di repository, chat, screenshot, dan log.

## 1. Periksa agreement dan app record

1. Buka App Store Connect → **Business** dan pastikan Paid Apps Agreement aktif,
   tax selesai, serta banking tidak berstatus action required.
2. Buka **Apps**. Pilih app MSC Body Transformation atau buat app record bila
   belum ada.
3. Gunakan bundle ID persis `com.ranggar.MSCBodyTransformation`.
4. Catat numeric Apple ID dari App Information. Nilai numerik ini akan menjadi
   secret `APPLE_APP_ID`; jangan tertukar dengan bundle ID atau Team ID.
5. Tidak perlu archive/upload build pada Phase 13.1.

## 2. Buat tiga akses Coach

Buka app → **Monetization → Subscriptions → Non-Renewing Subscriptions →
Manage → +**. Product ID bersifat permanen; masukkan persis:

| Price band backend | Reference name | Product ID | Harga keputusan produk |
|---|---|---|---:|
| `entry` | Akses Coach 3 Bulan — Entry | `com.ranggar.MSCBodyTransformation.coach.entry.3months` | Rp100.000 |
| `growth` | Akses Coach 3 Bulan — Growth | `com.ranggar.MSCBodyTransformation.coach.growth.3months` | Rp150.000 |
| `leadership` | Akses Coach 3 Bulan — Leadership | `com.ranggar.MSCBodyTransformation.coach.leadership.3months` | Rp200.000 |

Untuk masing-masing produk:

1. Pilih price point App Store terdekat dengan keputusan rupiah di atas.
2. Tambahkan localization Indonesia.
3. Display name: `Akses Coach 3 Bulan`.
4. Description: `Akses fitur dan QR Coach selama tiga bulan. Perpanjangan dilakukan secara manual.`
5. Aktifkan availability Indonesia dan storefront yang memang akan didukung.
6. Simpan. Metadata baru dapat memerlukan waktu sampai satu jam untuk muncul
   di Sandbox.

## 3. Buat produk program berbayar pertama

Setiap cohort berbayar mempunyai satu **Non-Consumable** unik. Buka app →
**Monetization → In-App Purchases → + → Non-Consumable**.

Gunakan konvensi:

```text
com.ranggar.MSCBodyTransformation.program.<cohort-slug-stabil>
```

Contoh bentuk saja, bukan ID yang boleh langsung dibuat:

```text
com.ranggar.MSCBodyTransformation.program.bali-2026-09-01
```

Sebelum membuat produk, finalkan nama cohort, tanggal mulai, harga, dan slug
stabil. Product ID tidak dapat digunakan ulang atau diubah setelah dibuat.
Localization yang disarankan:

- Display name: nama cohort yang dilihat peserta.
- Description: `Akses satu kali untuk mengikuti program <nama cohort>.`
- Availability: Indonesia dan storefront yang benar-benar didukung.

Program gratis tidak mempunyai produk StoreKit.

## 4. Buat In-App Purchase key

Hanya Account Holder/Admin yang dapat membuat key.

1. App Store Connect → **Users and Access → Integrations**.
2. Di sidebar Keys, buka **In-App Purchase**.
3. Pilih **Generate In-App Purchase Key** atau tombol `+`.
4. Nama yang disarankan: `MSC Hosted Commerce`.
5. Generate lalu download `.p8` satu kali.
6. Simpan Key ID dan Issuer ID bersama `.p8` di password manager/secure
   storage. Jangan pindahkan `.p8` ke repository.

Backend memerlukan:

- `APPLE_IAP_PRIVATE_KEY`: isi lengkap `.p8`.
- `APPLE_IAP_KEY_ID`: Key ID.
- `APPLE_IAP_ISSUER_ID`: Issuer ID.
- `APPLE_APP_ID`: numeric Apple ID app.
- `APPLE_ROOT_CERTIFICATES_BASE64`: Apple Root Certificates dari bagian
  Apple Root Certificates pada Apple PKI, sesuai petunjuk official App Store
  Server Library.
- `COMMERCE_APPLE_ENVIRONMENT=sandbox` selama Phase 13.1/device testing.

Berikan Codex hanya lokasi file `.p8` dan konfirmasi bahwa Key ID, Issuer ID,
numeric Apple ID, serta root certificates siap dimasukkan melalui prompt lokal.
Jangan kirim nilainya melalui chat.

## 5. App Store Server Notifications V2

Buka app → **App Information → General Information → App Store Server
Notifications**.

Masukkan sebagai **Sandbox Server URL**, pilih **Version 2**, lalu Save:

```text
https://uoymesmgsitdoxouvgca.supabase.co/functions/v1/commerce-apple-notifications
```

Production Server URL boleh memakai URL yang sama, tetapi backend harus
diganti ke `COMMERCE_APPLE_ENVIRONMENT=production` sebelum traffic production
dibuka. Phase 13.1 tetap memakai `sandbox`.

## 6. Buat Sandbox Apple Account

1. App Store Connect → **Users and Access → Sandbox → +**.
2. Gunakan email yang belum pernah menjadi Apple Account.
3. Pilih storefront Indonesia.
4. Simpan password di password manager; jangan kirim ke Codex.
5. Di iPhone development, buka Settings → Developer → Sandbox Apple Account
   dan login dengan tester tersebut. Tidak perlu logout dari Apple Account
   utama perangkat.

## 7. Handoff kembali ke Codex

Setelah selesai, cukup beritahu:

- Paid Apps Agreement/tax/banking: `done` atau blocker yang tampil.
- App record dengan bundle ID final dan numeric Apple ID: `done`.
- Tiga Coach product: `done`.
- Nama, slug, harga, dan Product ID cohort berbayar pertama.
- In-App Purchase key/root certificates: `siap`, tanpa mengirim secret.
- Notification V2 Sandbox URL: `done`.
- Sandbox Apple Account di iPhone: `done`.

Setelah handoff tersebut, Codex akan meminta approval production terpisah
untuk memasang server secrets, membuat product mapping hosted secara
idempoten, lalu menjalankan TEST notification dan purchase smoke.

## Referensi Apple

- https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/create-consumable-or-non-consumable-in-app-purchases
- https://developer.apple.com/help/app-store-connect/manage-subscriptions/create-non-renewing-subscriptions
- https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/generate-keys-for-in-app-purchases
- https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/enter-server-urls-for-app-store-server-notifications
- https://developer.apple.com/help/app-store-connect/test-in-app-purchases/create-a-sandbox-apple-account
- https://github.com/apple/app-store-server-library-node
