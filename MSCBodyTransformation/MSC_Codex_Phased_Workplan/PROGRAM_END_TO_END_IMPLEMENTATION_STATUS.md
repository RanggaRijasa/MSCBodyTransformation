# Status Implementasi Program End-to-End

Tanggal audit: 8 Agustus 2026

## Ringkasan

Vertical slice lokal iOS dan kontrak lintas platform sudah diremediasi.
Integrasi produksi yang membutuhkan project, credential, console store,
perangkat fisik, atau implementasi Android tetap menjadi external gate dan
tidak diklaim selesai.

## Selesai di source iOS lokal

### Batas pendaftaran program

- Admin dapat mengaktifkan cutoff tanggal dan jam pada `Jadwal dan peserta`.
- Cutoff bertahan pada draft, published mapping, duplikasi program, DTO
  Supabase, dan kontrak platform-neutral.
- Peserta tetap dapat melihat program yang ditutup, tetapi CTA join,
  scanner QR, deep-link enrollment, dan local enrollment use case menolak
  pendaftaran tepat pada atau setelah cutoff.
- Detail Orang Admin tetap menyediakan pendaftaran manual dengan deadline
  terlihat dan alasan audit wajib.
- Migration lokal menegakkan cutoff memakai server clock setelah row program
  dikunci. RPC Admin memverifikasi role Admin, lifecycle program, kapasitas,
  Coach approved, dan entitlement program berbayar; hanya deadline yang
  dikecualikan.

### Phase 09.5 — Guest, Auth UI, dan Coach application

- Guest menjadi default Debug demo dan memakai logged-out Participant shell
  tanpa membuat `AppUser`, profil, atau anonymous Supabase user.
- Seluruh tab Peserta dapat dijelajahi dengan public-safe snapshot; personal
  state tidak diisi dari fixture.
- Home Guest mempunyai CTA `Masuk`/`Daftar`; `Gabung program` melewati
  centralized auth gate dan mempertahankan program ID tanpa menyimpan QR.
- Login, Register, Forgot Password, Apple, Google, dan email/password
  tersedia sebagai UI dengan deterministic fake outcomes.
- Semua fake registration membuat Participant dan menuju onboarding yang
  sama: nama, nomor HP, sembilan level, dan tujuan akun.
- Eligibility, tiga price band, pembayaran manual tiga bulan, dan status
  menunggu Admin berada di domain/repository lokal, bukan View.
- Applicant tetap Participant setelah payment verified. Admin melihat
  eligibility/payment read-only; approval/rejection idempoten dan teraudit.
- Fixture lama yang memberi role Coach sebelum approval sudah diremediasi.
- Tidak ada Supabase Auth, OAuth callback, StoreKit transaction, secret, atau
  migration backend baru dalam Phase 09.5.

### Phase 10 — fondasi Auth lokal

- Migration lokal membuat tepat satu profile provisional dengan role literal
  Participant untuk setiap identity Auth dan mengabaikan metadata role/status.
- Nama, nomor HP, level member, tujuan akun, finalisasi QR Coach, handoff
  applicant, pembatalan provisional, dan expiry cleanup melalui RPC/helper
  dengan privilege minimum.
- App membedakan local demo, Debug Supabase lokal, dan hosted production;
  kombinasi build/endpoint invalid gagal tertutup.
- Session disimpan di Keychain device-only dan dimiliki satu actor yang
  mengoordinasikan refresh rotation, restore, expiry, logout, dan auth-state
  stream.
- Root route berasal dari session, protected profile, serta onboarding status;
  role tidak pernah diambil dari provider metadata.
- Email signup/recovery memakai PKCE one-time code; callback typed memvalidasi
  URL, kind, environment, TTL, dan state OAuth. Verification, reset password,
  provisional resume, serta typed error copy tersedia dalam Bahasa Indonesia.
- Pending program intent disimpan aman dengan TTL/nonce/environment untuk
  dipulihkan setelah auth, lalu direvalidasi terhadap status, cutoff server,
  dan kapasitas; raw Coach QR hanya berada di secure registration draft dan
  server validation boundary.
- Google browser OAuth (`ASWebAuthenticationSession`) dan native Sign in with
  Apple adapter tersedia di source tanpa third-party package atau secret.
- Custom callback scheme dan Sign in with Apple capability terpasang pada
  target Xcode; provider credential serta konfigurasi hosted belum tersedia.
- Penghapusan akun langsung tersedia setelah reauthentication melalui Edge
  Function server-side. Storage privat dan data program dibersihkan, session
  lokal dihapus, sedangkan transaksi/audit dipertahankan tanpa identitas.
- Email/password tetap tersembunyi sampai SMTP/domain production siap.
- Stack restart, lint, advisors, 139 pgTAP assertions, 22 Auth lifecycle
  checks, simulator build/run, 173 Swift tests, 7 UI tests, dan localization
  check lulus. Seluruh rantai migration termasuk immediate deletion juga
  lulus fresh reset lokal.
- Status yang benar: **fondasi lokal, immediate deletion, dan Google/Apple
  OAuth lokal selesai; hosted provider configuration/deployment, retention
  review, dan perangkat fisik tetap gate aktif. Hanya SMTP/domain dan
  email/password production yang berstatus SKIPPED SAAT INI**.

### Phase 11 — real data dan server operations lokal

- Public Guest reads tidak membuat Auth identity dan tidak membuka PII.
- Participant, Coach, dan Admin memakai typed Supabase repository pada mode
  lokal; production assembly tidak mempunyai silent fixture fallback.
- Coach application dan protected decision, QR/free enrollment, submission,
  quiz, weigh-in, score, monitoring/review, Admin CMS/correction/closure,
  immutable winners, poster publication, dan orphan cleanup authoritative di
  server serta diuji untuk authorization/idempotency/race.
- Payment verification dan entitlement lifecycle tetap tidak dapat dibuat
  client; flow menampilkan handoff Phase 12.
- Fresh reset 16 migration, 285 pgTAP assertions, seluruh integration suite,
  184 Swift tests, simulator build, dan empat journey UI kritis lulus.
- Hosted `main` tidak disentuh.

### Phase 12 — StoreKit dan commerce authoritative lokal

- Program berbayar memakai non-consumable unik per cohort; Participant maupun
  Coach dapat mengikuti program melalui alur QR/current Coach yang sama.
- Akses fitur Coach memakai non-renewing subscription tiga bulan terpisah.
  Pengajuan awal harus diterima Admin sebelum pembayaran; renewal manual tidak
  meminta approval ulang selama acceptance belum dicabut.
- iOS meminta opaque purchase intent server, memuat harga melalui
  `Product.displayPrice`, memakai `appAccountToken`, dan baru menyelesaikan
  transaksi setelah fulfillment server durable atau idempoten berhasil.
- StoreKit coordinator app-level menangani pending, unfinished recovery,
  explicit restore, transaction updates, logout/account switch, dan history
  read-only tanpa membuat entitlement dari state client.
- Backend menegakkan product/environment/ownership, reservation 30 menit,
  cutoff/capacity, replay protection, atomic enrollment/score/entitlement,
  expiry/renewal, refund/revocation, dan account-deletion retention.
- Apple JWS diverifikasi di Edge Function memakai official pinned
  `@apple/app-store-server-library` `3.1.0`. Notification V2 memakai public
  signed-payload endpoint dengan durable unique inbox dan idempotent ordering.
- Fresh reset 17 migration, 348 pgTAP assertions, 151 integration
  checks/assertions, 190 Swift/StoreKitTest tests, tiga UI journeys,
  Debug/Release builds, localization, lint, advisors, dan schema diff lulus.
- `Products.storekit` hanya Debug/test dan dikecualikan dari Release. Hosted
  `main`, App Store Connect, sandbox/TestFlight, public Apple webhook, dan
  perangkat fisik belum disentuh dan tetap Phase 13.

- Model program typed untuk scoring, commerce, content, questions, answer
  keys, submissions, quiz, payment, entitlement, dan store product.
- Migrasi fixture dari requirement/evidence lama ke typed question/answer.
- Penghapusan source aktif untuk program invite, wallet Coach, seat credit,
  akses non-publik, bukti terpisah, poin per langkah, dan timbang onboarding.
- Admin CMS tiga tahap, fixed public access, scoring program-wide, desired
  price, semua content/question type, pilihan gambar melalui PhotosPicker,
  publish validation, read-only published program, dan duplicate-as-draft.
- Editor hari dapat menyalin deskripsi dan seluruh konten ke beberapa hari
  tujuan sekaligus dengan ID nested baru; identitas dan jadwal target tetap.
- Duplikasi membuat seluruh ID nested baru, mempertahankan offset tanggal dan
  timezone, menyalin desired price, serta tidak menyalin store mapping/runtime.
- Peserta multi-program dengan state per enrollment dan same-Coach QR guard.
- Renderer typed, required-answer validation, kamera/PhotosPicker, retry dan
  orphan cleanup.
- Video resume, autoplay configuration, progress, dan watch threshold.
- Kuis otomatis satu percobaan, poin per jawaban benar, hasil privat yang
  sesuai peran, serta reopen Admin dengan alasan, sequence, history, dan audit.
- Cover program selalu gambar, dipilih melalui PhotosPicker, dan dirender
  oleh komponen bersama pada Peserta, Coach, serta pratinjau Admin.
- Timbang awal/harian/akhir sebagai content; awal/akhir unik per enrollment,
  harian unik per step, final-after-initial, scoring Decimal, dan koreksi
  Admin beralasan.
- Hari mendatang mendukung tersedia lebih awal, terkunci, atau disembunyikan.
- Poin langkah dan poin penurunan berat diberi label terpisah; timbang harian
  hanya mencatat progres dan tidak memengaruhi poin berat.
- Review Coach, queue pending, answer/photo context, answer key, idempotent
  score reconciliation.
- Detail privat Coach menampilkan riwayat timbang awal, harian, dan akhir;
  feed serta leaderboard tetap tidak menampilkan nilai berat.
- Transfer Coach Admin yang mempertahankan histori enrollment selesai.
- Closure preflight, pending/missing-final blockers, failed quiz visibility,
  winner lock immutable, dan poster terkait snapshot.
- Adapter StoreKit 2 terisolasi dari domain.
- Admin default membuka Dashboard; menu dan quick action tidak diduplikasi.
- Pratinjau Admin untuk Peserta/Coach memakai renderer aktivitas yang sama
  dengan runtime: identitas, progres, accordion hari, langkah, dan status
  tidak lagi memiliki implementasi khusus Admin.

## Artefak backend dan Android contract

- `Contracts/program-api-v1.openapi.yaml`
- `supabase/config.toml`
- `supabase/seed.sql`
- `supabase/migrations/20260802000000_program_end_to_end.sql`
- `supabase/migrations/20260805044617_phase10_auth_profile_and_session_foundation.sql`
- `supabase/migrations/20260808040841_phase11_server_operations_completion.sql`
- `supabase/migrations/20260808040935_phase11_participant_operations.sql`
- `supabase/migrations/20260808040939_phase11_coach_admin_operations.sql`
- `supabase/migrations/20260808084038_phase12_authoritative_commerce.sql`
- `supabase/functions/cleanup-orphan-question-photos/index.ts`
- `supabase/functions/commerce/index.ts`
- `supabase/functions/commerce-apple-notifications/index.ts`
- `PROGRAM_END_TO_END_CONTRACT_MATRIX.md`

Schema mencakup profile/current Coach, program/content/question/answer key,
enrollment, submission/answer, quiz, weigh-in, score, commerce, entitlement,
winner, poster, audit, storage, dan RLS dasar. Tidak ada tabel invite,
wallet, atau seat credit.

Seluruh migration Phase 09 dan Phase 10, termasuk immediate account deletion,
lulus fresh reset lokal pada 5 Agustus 2026. Lint dan advisors lulus tanpa
issue, 139 pgTAP assertions lulus, dan Auth lifecycle lulus 22 checks.

Simulator Debug build/run lulus tanpa warning. Empat focused Swift suite
terkait lulus dengan 65 tests, validator deadline tambahan lulus, dan
perjalanan UI Admin create → setting deadline → preview → publish lulus pada
locale perangkat `en_US` tanpa localization key terlihat.

## External gate

Keputusan produk 5 Agustus 2026 mempertahankan Google OAuth, Sign in with
Apple, hosted deployment, dan pengujian perangkat fisik sebagai gate aktif.
Hanya SMTP/domain dan email/password production yang di-skip.

| Gate | Status | Yang diperlukan |
|---|---|---|
| Google/Apple Auth production | AKTIF | Provider credential, hosted callback, dan perangkat fisik |
| SMTP/domain dan email/password production | SKIPPED SAAT INI | Diaktifkan kembali hanya bila keputusan produk berubah |
| Coach application backend | SELESAI LOKAL | Phase 11 migration, RLS, public Guest reads, atomic approve/reject; deployment hosted tetap Phase 13 |
| Coach access payment | SELESAI LOKAL | Phase 12 StoreKit/JWS, entitlement, expiry/renewal/refund; sandbox/hosted tetap Phase 13 |
| Hosted Supabase deployment | AKTIF | Review migration dan persetujuan eksplisit sebelum menyentuh hosted `main` |
| Server operations | SELESAI LOKAL | RPC/Edge Function dan race/retry tests lulus lokal; deployment/secrets production tetap Phase 13 |
| Store catalog provisioning | EXTERNAL PHASE 13 | App Store Connect key, appAppleId, root certificates, dan app/product records |
| StoreKit verification | SELESAI LOKAL | Xcode StoreKit/JWS/Notification fixture lulus; sandbox/TestFlight/webhook publik tetap Phase 13 |
| Google Play Billing | BELUM SELESAI | Android project, Play Console test track, purchase-token verification |
| Cross-platform entitlement | KONTRAK SELESAI LOKAL | Provider-neutral ledger/OpenAPI selesai; Android Play Billing tetap Phase 14 |
| Physical media/Auth | AKTIF | iPhone/iPad fisik untuk Auth, kamera, permission, memory, background/relaunch |
| Release/security | BELUM SELESAI | OAuth, retention/deletion, advisors, TestFlight/review |

Rincian input user dan urutan eksekusi tersedia di workplan Phase 10 bagian
“External gate dan manual configuration”.

## Verifikasi lokal

Verifikasi terakhir pada 3 Agustus 2026:

```bash
xcodebuild \
  -project MSCBodyTransformation.xcodeproj \
  -scheme MSCBodyTransformation \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  -derivedDataPath /private/tmp/MSCBodyTransformation-remediation-generic \
  CODE_SIGNING_ALLOWED=NO \
  build
```

- Hasil: **lulus**.
- Peringatan tunggal berasal dari metadata processor karena target tidak
  memakai `AppIntents.framework`; tidak ada warning source Swift.

```bash
xcodebuild test \
  -project MSCBodyTransformation.xcodeproj \
  -scheme MSCBodyTransformation \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=8DC6E4ED-CC5F-4E20-8556-F4E23ABF5DB9' \
  -parallel-testing-enabled NO \
  -only-testing:MSCBodyTransformationTests
```

- Hasil: **lulus, 134 tests**.

```bash
xcodebuild \
  -project MSCBodyTransformation.xcodeproj \
  -scheme MSCBodyTransformation \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=8DC6E4ED-CC5F-4E20-8556-F4E23ABF5DB9' \
  -derivedDataPath /private/tmp/MSCBodyTransformation-remediation-final-derived \
  CODE_SIGNING_ALLOWED=NO \
  build
```

- Hasil: **lulus**.

Empat UI regression kritis juga lulus:

- Header Konten tetap diam saat poster digulir.
- Header Program tetap diam saat kartu program digulir.
- Copy aplikasi tetap Bahasa Indonesia ketika device memakai bahasa Inggris.
- Peran Admin membuka Dashboard sebagai tab default.

Hasil: **4 tests, 0 failures dalam 61,774 detik**.

Verifikasi konsistensi pratinjau dan runtime pada 3 Agustus 2026 juga
menjalankan tiga perjalanan UI penuh:

- Admin membuat draft, menambah hari/langkah, memeriksa mode Peserta dan
  Coach, lalu menerbitkan program.
- Peserta menyelesaikan perjalanan lokal dari onboarding sampai aktivitas
  program.
- Coach memeriksa submission dan membuka detail progres peserta.

Hasil: **3 tests, 0 failures dalam 125,2 detik**. Build/run Debug pada iPhone
17 iOS 26.5 dengan device locale `en_US` juga lulus tanpa warning atau key
localization yang terlihat.

Amendment cover, future access, dan timbang harian pada 3 Agustus 2026
diverifikasi ulang:

- Simulator Debug build/run: **lulus tanpa warning source**.
- Unit/integration: **134 tests, 0 failure**.
- UI Admin create/publish: **lulus**, termasuk cover picker, label poin,
  pilihan timbang harian, shared preview, serta locale perangkat `en_US`
  tanpa localization key terlihat.
- UI Coach critical journey: **lulus**, termasuk riwayat privat timbang
  harian `78,1 kg`.
- Fixture JSON, localization JSON, OpenAPI YAML, dan `git diff --check`:
  **valid**.

Penyalinan isi antarhari pada 3 Agustus 2026 juga diverifikasi:

- Simulator Debug build: **lulus tanpa warning**.
- `Phase05AdminCMSTests`: **24 tests, 0 failure**.
- UI `testAdminCopiesDayContentToAnotherDay`: **1 test, 0 failure**.
- Salinan multi-target mempertahankan metadata hari tujuan dan membuat ulang
  ID langkah, pertanyaan, opsi, serta referensi answer key.

Full UI release matrix, perangkat fisik, Supabase staging, dan store sandbox
tetap termasuk external gate; hasil mock lokal tidak menggantikannya.

Verifikasi Phase 09.5 pada 4 Agustus 2026:

- Simulator Debug build/run Guest Home pada iPhone 17: lulus tanpa warning.
- Full Swift Testing: 157 tests, 0 failure.
- Swift Testing Phase 09.5: 13 tests, 0 failure.
- Focused Guest/Auth/Coach application UI: 5 tests, 0 failure, dengan device
  locale `en_US` dan copy aplikasi tetap Bahasa Indonesia.
- Admin Coach approval + existing manual enrollment regression: 1 test,
  0 failure.
- Participant, Coach, dan Admin CMS critical UI journeys: masing-masing
  1 test, 0 failure.
- iPad mini Register build/run pada locale `en_US`: lulus dan dynamic outcome
  menampilkan `Berhasil`, bukan localization key.
- Local fake flow berjalan tanpa Colima; backend production tetap external
  gate.
