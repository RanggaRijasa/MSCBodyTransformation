# MSC Body Transformation

Aplikasi native iOS/iPadOS untuk program transformasi tubuh dengan tiga peran:
Peserta, Coach, dan Admin. Implementasi lokal sekarang mengikuti kontrak
program end-to-end yang sama untuk iOS, backend Supabase, dan port Android
mendatang.

## Alur produk

1. Admin menyusun pengaturan, konten, scoring, dan harga program.
2. Peserta memilih program publik lalu memindai QR Coach.
3. QR pertama menetapkan satu Coach aktif; QR Coach lain ditolak.
4. Program gratis langsung membuat enrollment. Program berbayar menunggu
   transaksi store yang terverifikasi server.
5. Peserta menjalankan artikel, video, form, kuis, serta timbang
   awal/harian/akhir.
6. Coach memeriksa jawaban subjektif dan unggah foto.
7. Skor dihitung per enrollment; Admin menyelesaikan blocker, mengunci
   pemenang, lalu menerbitkan poster yang terkait snapshot.

Tidak ada invite program, kode manual, approval enrollment, wallet Coach,
seat credit, bukti foto paralel, poin per langkah, atau timbang onboarding
global.

## Implementasi saat ini

- SwiftUI dan Swift 6 dengan repository protocol serta adapter lokal actor.
- Admin CMS tiga tahap: Pengaturan, Konten, Tinjau & terbitkan.
- Duplikasi program dengan semua ID baru dan pergeseran tanggal berbasis
  kalender/zona waktu.
- State Peserta per enrollment untuk beberapa program aktif.
- Semua tipe pertanyaan typed, termasuk pilihan gambar dan unggah foto.
- Kuis otomatis satu percobaan; Admin dapat membuka satu percobaan baru
  dengan alasan dan audit.
- Timbang awal/harian/akhir sebagai konten program; scoring `Decimal` memakai
  selisih awal-akhir.
- Review Coach, transfer Coach Admin, koreksi timbang, winner lock, dan poster.
- StoreKit 2 program/akses Coach memakai purchase intent server,
  `appAccountToken`, verifikasi JWS server-side, durable transaction ledger,
  dan finish ordering setelah fulfillment berhasil.
- Schema/RLS Supabase dan kontrak OpenAPI lintas platform tersedia sebagai
  artefak integrasi.
- Phase 12 selesai lokal: program berbayar, akses Coach tiga bulan, renewal,
  refund/revocation reconciliation, history/restore, serta Notification V2
  inbox sudah server-authoritative. Hosted/App Store tetap Phase 13.

Status rinci dan external gate dicatat di
`MSCBodyTransformation/MSC_Codex_Phased_Workplan/PROGRAM_END_TO_END_IMPLEMENTATION_STATUS.md`.

## Build

```bash
xcodebuild \
  -project MSCBodyTransformation.xcodeproj \
  -scheme MSCBodyTransformation \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' \
  build
```

Build generik tanpa signing:

```bash
xcodebuild \
  -project MSCBodyTransformation.xcodeproj \
  -scheme MSCBodyTransformation \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Test

```bash
xcodebuild test \
  -project MSCBodyTransformation.xcodeproj \
  -scheme MSCBodyTransformation \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' \
  -parallel-testing-enabled NO \
  -only-testing:MSCBodyTransformationTests
```

`-parallel-testing-enabled NO` dipakai karena suite Swift Testing berbagi satu
adapter lokal deterministik pada beberapa skenario.

## Data dan demo lokal

Fixture berada di `MSCBodyTransformation/Resources/Fixtures`. Debug launcher
menyediakan role switcher dan skenario deterministik. QR Coach berisi
identifier opaque; tidak ada field kode manual. Foto hanya dipilih melalui
PhotosPicker atau kamera native.

## Integrasi eksternal

- `supabase/` berisi migration, RLS, storage policy, dan seed aman.
- `Contracts/program-api-v1.openapi.yaml` adalah kontrak iOS/Android.
- Kredensial App Store Connect dan Google Play harus berada di backend.
- Harga aktual harus berasal dari StoreKit/Play Billing, bukan nilai client.
- Google dan Apple OAuth sudah diverifikasi terhadap Supabase lokal. Hosted
  Supabase, StoreKit sandbox/TestFlight, Google Play, dan Android belum dapat
  diklaim terverifikasi tanpa project/credential serta environment eksternal.
- `Products.storekit` hanya untuk Debug/test dan dikecualikan dari Release.
  Hosted `main` tidak pernah dipakai untuk eksperimen lokal.

## Dokumentasi sumber kebenaran

1. `AGENTS.md`
2. `MSCBodyTransformation/MSC_Codex_Phased_Workplan/00_START_HERE.md`
3. `MSCBodyTransformation/MSC_Codex_Phased_Workplan/UI_REFERENCE_SHEET.md`
4. `MSCBodyTransformation/MSC_Codex_Phased_Workplan/PROGRAM_END_TO_END_REMEDIATION_WORKPLAN.md`
5. `MSCBodyTransformation/MSC_Codex_Phased_Workplan/PROGRAM_END_TO_END_CONTRACT_MATRIX.md`

Dokumen fase lama adalah catatan historis apabila bertentangan dengan kontrak
end-to-end di atas.
