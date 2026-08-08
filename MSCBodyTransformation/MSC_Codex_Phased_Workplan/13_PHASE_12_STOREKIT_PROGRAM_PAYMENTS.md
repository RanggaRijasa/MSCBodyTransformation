# Phase 12: StoreKit 2 and Authoritative Commerce

> Status: diaudit dan direkonsiliasi pada 8 Agustus 2026 setelah seluruh
> Slice Phase 11 selesai lokal. Seluruh keputusan produk Gate 12.0 telah
> dikonfirmasi dan Phase 12 siap diimplementasikan mulai dari contract
> reconciliation serta verifier feasibility sebelum migration commerce
> pertama dibuat. Seluruh development tetap memakai Supabase lokal. Hosted
> main, App Store sandbox, TestFlight, notification URL publik, dan perangkat
> fisik tetap Phase 13.

## Tujuan

Menyelesaikan commerce iOS secara server-authoritative untuk dua jenis akses
yang berbeda:

- Account eligible, baik Participant maupun Coach yang juga ingin mengikuti
  program, membeli akses satu cohort berbayar setelah program, batas
  pendaftaran, kapasitas, dan QR Coach tervalidasi server.
- Applicant Coach yang sudah diterima Admin membeli akses fitur Coach manual
  tiga bulan tanpa memperoleh role atau capability dari state client.

Hasil pembelian yang dipercaya selalu berasal dari transaksi Apple yang
ditandatangani, diverifikasi server, direkonsiliasi ke ledger provider-neutral,
dan dipenuhi secara idempoten. Harga, product mapping, enrollment, payment
verified, entitlement, role, expiry, refund, revocation, dan audit tidak boleh
ditentukan oleh client.

Tidak ada wallet Coach, paket kuota peserta, seat credit, typed invite code,
atau fallback pembayaran demo pada mode Supabase.

## Keputusan hasil audit

### Fondasi yang sudah tersedia dan tidak boleh dibuat ulang

| Area | Baseline setelah Phase 11 |
|---|---|
| Program commerce | Program pricing mode, desired price, platform availability, dan program_store_products |
| Participant commerce | commerce_transactions, program_entitlements, paid-enrollment guard, dan atomic enrollment foundation |
| Coach commerce | coach_applications, coach_payment_records, coach_access_entitlements, protected Admin decision, dan entitlement guard pada seluruh Coach operation |
| Auth dan identity | Supabase session JWT, protected profile, Google/Apple identity, Keychain restore, dan account deletion retention |
| Enrollment context | QR Coach opaque, current-Coach guard, program cutoff, capacity, duplicate protection, dan paid handoff |
| iOS StoreKit seam | StoreKitProgramPurchaseService dapat load Product, menampilkan displayPrice, memulai purchase, membaca Transaction.updates/currentEntitlements, mengirim JWS, lalu finish setelah verifier berhasil |
| UI seam | Program payment step, Coach application payment screen, pending state, Admin payment read model, dan local-demo fake purchase |
| Server runtime | Supabase Edge Functions lokal, Deno 2.1 compatible runtime, explicit secrets boundary, RLS/grant hardening, pgTAP/integration harness |
| Contract | OpenAPI Apple/Google verification endpoint draft dan platform-neutral commerce models |

### Gap nyata yang harus diselesaikan

- StoreKitProgramPurchaseService belum di-assemble ke feature production dan
  belum mempunyai focused StoreKit tests.
- Adapter lama masih menerima participantID dan coachID dari client. Server
  harus memperoleh participant dari JWT serta program/Coach/application dari
  server-owned purchase intent dan mapping.
- Product.purchase belum mengirim appAccountToken untuk korelasi akun.
- Transaction update/recovery masih memerlukan context dari caller dan
  mengabaikan verification error dengan try?.
- Belum ada purchase-intent/reservation aggregate untuk menutup race antara
  QR validation, cutoff, capacity, purchase sheet, dan fulfillment.
- Environment mapping lama memakai staging, padahal strategi repository tidak
  memiliki staging. Commerce membutuhkan xcode/local_testing, sandbox, dan
  production yang eksplisit.
- commerce_transactions belum menyimpan original transaction ID,
  appAccountToken, product type, storefront/currency snapshot, revocation,
  expiry, dan decoded allowlisted verification fields.
- coach_payment_records satu-per-application dan entitlement langsung active
  belum cukup untuk renewal berulang atau pending activation saat menunggu
  Admin.
- Belum ada server verifier Apple, notification inbox V2, retry/dead-letter,
  reconciliation job, ataupun executable expiry reconciliation.
- Product loader program dan Coach belum membaca product mapping
  authoritative dari server.
- Products.storekit dan StoreKitTest automation belum tersedia.
- OpenAPI masih mengirim raw coachQrPayload pada verification request dan
  belum memodelkan purchase intent, appAccountToken, history, reconciliation,
  atau Coach purchase.
- Google verification belum boleh diimplementasikan tanpa Android/Play
  environment; Phase 12 hanya menjaga shared ledger dan kontraknya.

### Koreksi terhadap workplan lama

- App Store Connect bukan prasyarat untuk implementation lokal. Xcode StoreKit
  Testing memakai local StoreKit configuration tanpa store credential.
- App Store Connect product provisioning, sandbox account, public notification
  URL, TestFlight, dan physical-device validation dipindahkan ke Phase 13.
- Google Play Billing client dan live purchase-token verification dipindahkan
  ke Phase 14. Phase 12 hanya membuat provider-neutral schema dan acceptance
  contract agar Android tidak menyalin business rule.
- App Store Server Notifications V2 handler boleh dibuat dan diuji lokal
  dengan signed fixtures, tetapi TEST notification nyata memerlukan hosted
  HTTPS endpoint di Phase 13.
- Receipt validation lama tidak digunakan. Server memverifikasi StoreKit 2
  JWS transaction dan Notification V2 signedPayload.
- Restore normal membaca Transaction.currentEntitlements. AppStore.sync hanya
  dipanggil dari aksi pengguna "Pulihkan pembelian" karena memunculkan prompt
  autentikasi App Store.
- Interrupted purchase adalah kondisi testing/error-recovery, bukan
  PurchaseResult terminal tambahan. State machine memetakan error StoreKit,
  unfinished transaction, dan transaction update secara eksplisit.
- Transaction hanya di-finish setelah server mencatat event dan fulfillment
  secara durable atau mengembalikan hasil idempoten yang sudah ada.
- Refund bukan keputusan client. Refund/revocation berasal dari JWS terbaru,
  Notification V2, atau server reconciliation.
- Payment verified, entitlement, dan role Coach tetap state terpisah.
- Hosted main tidak boleh dipakai untuk iterasi migration atau fixture.

## Batas scope

### Termasuk Phase 12 lokal

- Keputusan product type dan lifecycle policy.
- Local Products.storekit untuk program dan Coach products.
- StoreKit 2 product loading, localized display price, purchase state machine,
  appAccountToken, updates, unfinished/current entitlement recovery, dan
  explicit restore.
- Server-owned purchase intent/preflight untuk program dan Coach.
- Provider-neutral transaction ledger, entitlement state, event history, dan
  idempotency.
- Apple JWS transaction verifier pada Supabase Edge Function lokal.
- Atomic paid-program fulfillment.
- Coach payment verification, pending activation, approval activation,
  expiry, manual renewal, revocation, dan rejection disposition.
- Notification V2 inbox/processor dan reconciliation logic yang dapat diuji
  dengan deterministic local fixtures.
- Participant/Coach payment history read models.
- OpenAPI dan Android-compatible commerce contract.
- RLS, explicit grants, function privileges, audit, replay, race, deletion,
  pgTAP, Edge Function integration, Swift, StoreKitTest, dan focused UI tests.

### Ditunda ke Phase 13

- Membuat produk nyata di App Store Connect.
- App Store Connect In-App Purchase key, issuer ID, key ID, appAppleId, dan
  production/sandbox secrets.
- Deployment migration/functions/config ke hosted main.
- Hosted sandbox dan production product mapping.
- Public HTTPS App Store Server Notifications V2 URL.
- Request a Test Notification dan notification-history recovery terhadap
  Apple.
- Sandbox Apple Account, StoreKit sandbox, TestFlight, physical device, dan
  App Review metadata.
- Production Security/Performance Advisor sign-off.
- Hosted refund/revocation and account-retention acceptance.

### Ditunda ke Phase 14

- Android Play Billing client.
- Google Play Console product provisioning dan test track.
- Live Google purchase-token verification.
- Real-time Developer Notifications.
- Cross-device iOS/Android acceptance terhadap hosted backend.

## Keputusan produk Gate 12.0

Keputusan berikut direkam dari konfirmasi pengguna pada 8 Agustus 2026.
Istilah product type di sini berarti perilaku produk pada StoreKit, bukan cara
Admin menandai program berbayar.

1. **Program berbayar — diputuskan.** Program dianggap berbayar ketika Admin
   menetapkan pricing mode berbayar dan harga. Pada Apple, aksesnya dimodelkan
   sebagai non-consumable unik per cohort: satu kali beli untuk satu cohort,
   tidak kedaluwarsa sebagai transaksi Apple, tetapi akses kegiatan tetap
   mengikuti tanggal cohort. Participant maupun Coach boleh membeli dan
   mengikuti program selama memenuhi rule enrollment dan QR Coach yang sama.
2. **Akses fitur Coach — diputuskan.** Ini bukan pembayaran program. Produk
   ini memberi masa aktif fitur/QR Coach selama tiga bulan dan dimodelkan
   sebagai non-renewing subscription per price band, sehingga renewal manual
   dan tidak memperpanjang otomatis.
3. **Aktivasi awal Coach — diputuskan.** Pengajuan baru diperiksa Admin lebih
   dulu. Setelah diterima, applicant masuk status accepted_pending_payment.
   Tiga bulan dimulai segera ketika pembayaran terverifikasi. Dengan urutan
   ini, waktu review tidak mengurangi masa aktif dan applicant yang ditolak
   tidak sempat ditagih.
4. **Kebijakan refund — diputuskan dengan batas provider.** Produk tidak
   menawarkan refund sukarela dan penolakan awal terjadi sebelum pembayaran.
   Namun keputusan refund/revocation Apple atau kewajiban hukum tetap
   authoritative: server wajib mencatatnya dan mencabut akses terkait. Copy UI
   tidak boleh menjanjikan bahwa refund mustahil dalam semua kondisi.
5. **Renewal Coach — diputuskan.** Renewal dilakukan manual dan tidak
   memerlukan approval ulang selama protected approval belum dicabut. Jika
   dibayar saat masih aktif, tiga bulan ditambahkan setelah expiry yang ada
   agar sisa hari tidak hilang; jika sudah expired, periode baru dimulai pada
   waktu pembayaran terverifikasi. Saat expired, seluruh fitur Coach dan QR
   Coach nonaktif. Participant tidak dapat memakai QR tersebut untuk memulai
   pembayaran/enrollment program sampai entitlement Coach aktif kembali.
6. **Program refund — diputuskan dengan batas provider.** Tidak ada refund
   sukarela setelah pembelian atau aktivitas dimulai. Jika Apple kemudian
   mengeluarkan refund/revocation, entitlement dan akses baru dihentikan,
   enrollment ditandai refunded, history/audit privat dipertahankan, dan entry
   publik dikeluarkan.
7. **Capacity/cutoff reservation — diputuskan.** Reservation
   adalah kursi sementara yang dikunci server ketika pengguna menekan beli,
   agar dua orang tidak membeli kursi terakhir bersamaan. TTL adalah berapa
   lama kursi sementara itu ditahan sebelum dilepas otomatis. Rekomendasi:
   30 menit, diperbarui selama purchase sheet aktif. Jika transaksi Apple sah
   selesai setelah TTL dan kapasitas sudah penuh, pembelian tetap harus
   dipenuhi sebagai exception over-capacity yang diaudit karena kebijakan
   tanpa refund tidak boleh menghasilkan pembayaran tanpa layanan.
8. **Bundle identifier — terdeteksi dan dianggap final.** Target aplikasi saat
   ini memakai com.ranggar.MSCBodyTransformation. Nilai ini adalah identitas
   unik aplikasi di Xcode, Apple Developer, App Store Connect, Sign in with
   Apple, dan allowlist verifikasi StoreKit. Ubah hanya sebelum produk App
   Store dibuat; setelah itu perubahan berarti identitas aplikasi berbeda.

Tidak diperlukan sekarang: private key App Store, issuer ID, appAppleId,
Sandbox Apple Account, hosted URL, atau TestFlight credential. Semua itu baru
diminta pada Phase 13.

Tidak ada resource eksternal yang harus dibuat manual oleh pengguna untuk
memulai Phase 12. Agent dapat membuat local StoreKit configuration, local
product IDs, migration, Edge Functions, fixtures, dan tests. Pengguna hanya
akan dimintai persetujuan tepat saat:

- destructive supabase db reset --local diperlukan;
- official Apple server-library dependency perlu ditambahkan setelah
  compatibility spike; atau
- Xcode tidak dapat memasang local StoreKit configuration ke test scheme
  secara aman melalui file repository dan membutuhkan satu langkah UI manual.

## Product intent

### Program berbayar

- Satu product ID unik per cohort, platform, dan environment.
- Eligibility pembeli tidak dibatasi pada role Participant. Account Coach juga
  boleh mengikuti dan membayar program sebagai peserta, tetapi tetap harus
  memenuhi onboarding, QR Coach, cutoff, capacity, dan duplicate rule yang
  sama.
- Pembelian program tidak memperpanjang akses fitur Coach, dan pembayaran
  akses Coach tidak otomatis mendaftarkan account ke program.
- Product mapping server berstatus ready sebelum CTA pembayaran aktif.
- Admin desired price hanya intent provisioning; UI selalu memakai
  Product.displayPrice.
- Product yang dibeli harus cocok dengan program, environment, bundle,
  purchase intent, dan current authenticated account.
- Cohort lama tidak dapat membuka cohort baru walau harganya sama.
- Free program tetap memakai operasi enrollment Phase 11 dan tidak melewati
  StoreKit.

### Akses Coach

| Level | Price band intent | Harga intent | Durasi |
|---|---|---:|---:|
| Member | Tidak tersedia | — | — |
| SC, SB | entry | Rp100.000 | 3 bulan |
| Supervisor, World Team | growth | Rp150.000 | 3 bulan |
| TAB, GET, Millionaire, President’s Team | leadership | Rp200.000 | 3 bulan |

- Product ID berasal dari server mapping price band, bukan enum client saja.
- Harga runtime berasal dari StoreKit dan transaction signed data.
- Pengajuan baru harus diterima Admin sebelum CTA pembayaran tersedia.
- Pembayaran verified setelah acceptance mengaktifkan role/capability dan
  entitlement tiga bulan secara atomik.
- Renewal verified tidak memerlukan acceptance baru selama protected approval
  belum dicabut.
- Expired Coach tetap tidak dapat memakai operation protected walaupun role
  atau UI tercache.
- Renewal menambah period berdasarkan server clock dan entitlement history,
  bukan menghitung dari jam perangkat.

## Authority boundaries

- Client mengirim JWS transaction dan opaque purchaseIntentID; client tidak
  mengirim authoritative participantID, coachID, application state, price,
  currency, product mapping, entitlement dates, role, atau enrollment status.
- Server memperoleh user dari verified Supabase JWT.
- appAccountToken adalah UUID server-controlled yang terikat ke application
  account dan harus cocok dengan signed transaction.
- Purchase intent menyimpan server-resolved subject, product, program atau
  application, Coach context, environment, expiry, dan idempotency key.
- JWS harus diverifikasi cryptographically sebelum field payload dipercaya.
- Server memvalidasi bundle ID, environment, product ID, transaction ID,
  original transaction ID, appAccountToken, ownership, dates, revocation,
  dan mapping.
- Signed payload mentah tidak boleh dicetak ke log. Simpan hash dan decoded
  allowlisted fields; simpan payload mentah hanya bila retention/security
  review secara eksplisit membutuhkannya.
- Transaction replay untuk account, program, application, product, atau
  environment berbeda harus ditolak.
- Secret/privileged write hanya berada di Edge Function/server transaction.
- Table grants, RLS, function EXECUTE, dan Edge Function auth adalah boundary
  terpisah dan semuanya wajib diuji.
- Webhook Notification V2 tidak memakai user JWT; akses publik hanya mencapai
  signature verification dan durable inbox, bukan arbitrary mutation.
- Semua fulfillment, refund, revocation, expiry, dan renewal menulis audit
  dalam transaction yang sama dengan state change.
- Account deletion menganonimkan retained financial/audit data sesuai Phase
  10 dan menghapus active personal entitlement linkage yang tidak wajib
  dipertahankan.

## Authoritative flow

### Paid program

1. Authenticated Participant memilih published paid program.
2. Server preflight memvalidasi profile/onboarding, current Coach, program,
   cutoff, capacity, mapping, dan existing enrollment/entitlement.
3. Server membuat atau mengembalikan idempotent purchase intent/reservation.
4. Client memuat Product dari product ID yang dikembalikan server.
5. Client menampilkan Product.displayPrice dan memulai purchase dengan
   appAccountToken.
6. Verified StoreKit result dikirim sebagai JWS + purchaseIntentID.
7. Edge Function memverifikasi JWS dan memanggil satu database fulfillment
   transaction.
8. Transaction ledger, entitlement, enrollment, score row, reservation, dan
   audit dibuat atau direkonsiliasi atomik.
9. Client finish transaction hanya setelah server success/idempotent success.
10. App memuat ulang authoritative enrollment, bukan membuat state lokal.

### Coach access

1. Applicant mempunyai application submitted dan eligibility server valid.
2. Admin menerima atau menolak pengajuan. Applicant yang ditolak tidak dapat
   membuka payment sheet.
3. Application yang diterima masuk accepted_pending_payment.
4. Server preflight menentukan price band, product mapping, dan purchase
   intent; Member atau approval yang sudah dicabut ditolak.
5. Client memuat product dan membeli dengan appAccountToken.
6. Server memverifikasi JWS, menulis payment transaction idempoten, lalu
   mengaktifkan entitlement tiga bulan dan capability Coach secara atomik.
7. Protected Coach operation memeriksa approval dan entitlement aktif.
8. Expiry/revocation mengunci fitur serta QR Coach. Manual renewal tidak
   memerlukan approval ulang dan membuat period baru tanpa tanggal dari client.

### Recovery dan notification

1. Listener Transaction.updates dimiliki app-level commerce coordinator dan
   hidup satu kali selama session.
2. Relaunch memproses Transaction.unfinished dan current entitlements.
3. Aksi user Pulihkan pembelian memanggil AppStore.sync, lalu reconciliation.
4. Server endpoint menerima Notification V2 signedPayload, memverifikasi JWS,
   dan insert notificationUUID ke inbox unik sebelum response success.
5. Processor idempoten merekonsiliasi transaction/entitlement/enrollment.
6. Retry, duplicate notification, dan out-of-order event menghasilkan state
   yang sama.
7. Phase 13 menguji TEST notification nyata dan recovery history pada hosted
   endpoint.

## Urutan implementasi

Setiap slice harus mencakup contract, production code, focused tests, build,
dan progress log sebelum slice berikutnya.

### 12.0 — Product decisions dan contract reconciliation

- [x] Phase 11 local final gate lulus dan hosted main tidak disentuh.
- [x] Inventarisasi schema, OpenAPI, StoreKit adapter, feature payment seam,
  Coach application, enrollment guard, dan account-deletion retention.
- [x] Pisahkan scope local Phase 12, external Phase 13, dan Android Phase 14.
- [x] Rekam product type program non-consumable per cohort dan Coach
  non-renewing subscription tiga bulan.
- [x] Tetapkan lifecycle initial Coach approval → payment → activation dan
  renewal manual tanpa approval ulang.
- [x] Tetapkan no-voluntary-refund policy dengan Apple/legal
  refund/revocation tetap authoritative.
- [x] Konfirmasi current bundle identifier
  com.ranggar.MSCBodyTransformation sebagai final working value.
- [x] Konfirmasi TTL reservation 30 menit dan rare paid over-capacity
  fulfillment policy.
- [ ] Tetapkan stable commerce error catalog:
  product_not_ready, purchase_intent_expired, reservation_conflict,
  payment_pending, purchase_unverified, transaction_replayed,
  transaction_mismatch, fulfillment_failed, refunded, revoked, dan unknown.
- [ ] Rekonsiliasi OpenAPI: hapus raw Coach QR dan client identity dari verify
  request; tambahkan preflight, verify, history, restore/reconcile, Coach
  purchase, dan notification contract.
- [ ] Tandai setiap endpoint implemented-phase11, new-phase12-local,
  deferred-phase13, atau deferred-phase14.

#### Gate 12.0

- [ ] Tidak ada product/lifecycle policy yang masih ambigu.
- [ ] Tidak ada hosted credential yang diperlukan untuk memulai local slice.
- [ ] Client/server authority dan idempotency key sudah eksplisit.

### 12.1 — Apple verifier feasibility dan local StoreKit harness

- [ ] Verifikasi installed Xcode/SDK StoreKit API signatures; jangan menebak.
- [ ] Tambahkan local Products.storekit dengan product IDs deterministic yang
  tidak sama dengan production.
- [ ] Aktifkan StoreKit configuration hanya pada Debug/test scheme yang
  disetujui; Release tidak boleh memakai local configuration.
- [ ] Tambahkan StoreKitTest harness untuk product load, localized price,
  success, cancel, pending/Ask to Buy, interrupted, unverified, refund,
  revocation, unfinished transaction, dan relaunch.
- [ ] Uji official Apple App Store Server Library Node yang dipin terhadap
  Supabase Edge Runtime Deno 2.1 dan Xcode signed transaction.
- [ ] Dependency official Apple hanya ditambahkan setelah persetujuan
  eksplisit sesuai dependency rules repository.
- [ ] Bila library tidak kompatibel dengan Edge Runtime, hentikan slice dan
  pilih secara eksplisit: isolated Node verification service atau vetted
  standards-native verifier. Jangan membuat crypto verifier ad hoc.
- [ ] Pastikan Apple root/test certificate loading tidak memakai path atau
  secret client.
- [ ] Catat exact local verification environment dan limitation sandbox.

#### Gate 12.1

- [ ] StoreKit scenario dapat direproduksi deterministic di simulator.
- [ ] JWS Xcode transaction dapat diverifikasi server-side atau architecture
  blocker telah diputuskan pengguna.
- [ ] Tidak ada secret atau production product ID di repository.

### 12.2 — Provider-neutral commerce schema dan protected operations

- [ ] Tambahkan purchase intents/reservations dengan owner, subject kind,
  program/application, Coach snapshot, product mapping, TTL, status, dan
  idempotency.
- [ ] Ganti commerce environment staging menjadi explicit xcode/local_testing,
  sandbox, dan production migration strategy.
- [ ] Perluas transaction ledger dengan provider, product type,
  transaction/original transaction IDs, appAccountToken, signed payload hash,
  purchased/signed/expiry/revocation dates, currency/price snapshot, dan
  last-event ordering.
- [ ] Pastikan unique constraints menolak replay lintas account/environment.
- [ ] Tambahkan immutable transaction event/notification inbox untuk
  duplicate dan out-of-order processing.
- [ ] Perluas program entitlement menjadi current projection dengan retained
  history/event source.
- [ ] Ubah Coach payment menjadi transaction-backed dan mendukung renewal
  history; jangan overwrite pembelian lama.
- [ ] Tambahkan pending-activation/active/expired/revoked/refunded states
  sesuai keputusan Gate 12.0.
- [ ] Tambahkan protected preflight dan fulfillment database operations
  memakai server clock dan fixed search_path.
- [ ] Explicit revoke/grant, RLS, indexes, function privileges, audit, dan
  account-deletion retention untuk setiap object baru.
- [ ] Update OpenAPI dan platform-neutral domain tanpa mengimpor StoreKit.

#### Gate 12.2

- [ ] Client tidak dapat insert/update payment, transaction, entitlement,
  reservation result, notification, atau role secara langsung.
- [ ] Replay, ownership, expiry, cutoff, dan capacity constraints diuji.
- [ ] Fresh local reset, pgTAP, lint, advisors, migration list, dan schema
  diff hijau.

### 12.3 — Apple purchase verification Edge Functions

- [ ] Buat authenticated program preflight endpoint.
- [ ] Buat authenticated Coach preflight endpoint.
- [ ] Verifikasi JWT dan derive caller server-side.
- [ ] Return hanya purchaseIntentID, productID, appAccountToken, expiry, dan
  non-authoritative presentation metadata yang diperlukan.
- [ ] Buat authenticated Apple verification endpoint menerima
  purchaseIntentID + signedTransaction.
- [ ] Cryptographically verify transaction JWS.
- [ ] Validate bundle ID, environment, product ID, appAccountToken,
  transaction/original IDs, dates, and revocation.
- [ ] Jalankan atomic database fulfillment dan return authoritative aggregate.
- [ ] Map sandbox-on-production verification retry hanya di server dan jangan
  menerima environment dari client.
- [ ] Jangan log JWS, token, raw QR, private key, atau provider payload.
- [ ] Rate-limit/replay-limit endpoint secara terukur.
- [ ] Finish/retry contract mengembalikan hasil sama untuk transaction sama.
- [ ] Tambahkan deterministic Edge Function integration tests untuk tampered
  signature, wrong bundle/product/account/intent/environment, expired intent,
  duplicate, replay, cutoff, capacity, dan unauthorized caller.

#### Gate 12.3

- [ ] Satu Apple JWS valid menghasilkan satu ledger result.
- [ ] JWS invalid atau mismatched tidak membuat state parsial.
- [ ] Edge Function secret boundary dan database privileges minimum lulus.

### 12.4 — StoreKit client coordinator dan repository assembly

- [ ] Refactor StoreKitProgramPurchaseService agar tidak menerima
  participantID/coachID authoritative.
- [ ] Tambahkan purchase option appAccountToken dari preflight.
- [ ] Product loader selalu memakai mapping preflight dan Product.displayPrice.
- [ ] Model loading, ready, purchasing, pending, verifying, fulfilled,
  cancelled, failed, refunded, dan revoked secara eksplisit.
- [ ] Bedakan user cancellation, pending Ask to Buy, unverified transaction,
  StoreKit error, network/offline, session expiry, verifier conflict, dan
  unknown error dengan copy Bahasa Indonesia.
- [ ] Commerce coordinator app-level mempunyai tepat satu cancellable
  Transaction.updates listener.
- [ ] Relaunch memproses unfinished transaction sebelum menampilkan success.
- [ ] currentEntitlements/all transaction reconciliation tidak membuka akses
  tanpa server response.
- [ ] Aksi Pulihkan pembelian memanggil AppStore.sync hanya setelah user tap.
- [ ] Finish transaction hanya setelah durable server success/idempotent
  success.
- [ ] Logout/account switch membatalkan listener context dan membersihkan
  private commerce state.
- [ ] Assemble real commerce repository hanya pada Supabase mode; local demo
  tetap memakai deterministic fake dan diberi label demo.
- [ ] Tambahkan focused Swift tests untuk state machine, cancellation,
  recovery, mapping, and finish ordering.

#### Gate 12.4

- [ ] Tidak ada enrollment, payment verified, entitlement, role, atau expiry
  yang dibuat dari client-only state.
- [ ] Pending/relaunch/account-switch behavior deterministic.
- [ ] Simulator build dan focused Swift tests lulus.

### 12.5 — Paid program end-to-end

- [ ] Hubungkan paid CTA setelah QR/current-Coach confirmation ke program
  preflight.
- [ ] Free CTA tetap tidak membuka StoreKit.
- [ ] Tampilkan program title, duration, Coach, dan Product.displayPrice
  sebelum system purchase sheet.
- [ ] Tangani product unavailable/action required tanpa fallback desired price.
- [ ] Fulfillment membuat transaction, entitlement, enrollment, score row,
  reservation result, dan audit atomik.
- [ ] Duplicate verification/update/relaunch mengembalikan enrollment sama.
- [ ] Cohort/product ID mismatch dan wrong-Coach intent ditolak.
- [ ] Capacity/cutoff race mengikuti policy Gate 12.0 tanpa membuat pembelian
  client-only tampak berhasil.
- [ ] Backend payment history dan entitlement tampil read-only.
- [ ] Refund/revocation state mengubah akses sesuai policy tanpa menghapus
  retained private history/audit.
- [ ] Add pgTAP, HTTP integration, StoreKitTest, Swift, dan focused UI journey.

#### Gate 12.5

- [ ] Verified purchase membuat tepat satu entitlement dan enrollment.
- [ ] Program dan Coach berasal dari purchase intent server.
- [ ] Pembelian cohort lama tidak membuka cohort baru.
- [ ] Refund/revocation tidak meninggalkan public or protected access yang
  tidak semestinya.

### 12.6 — Coach access purchase, approval, expiry, dan renewal

- [ ] Hubungkan submitted eligible application ke Admin review tanpa
  menampilkan payment sheet.
- [ ] Setelah Admin accept, ubah application ke accepted_pending_payment dan
  tampilkan Coach preflight/payment CTA.
- [ ] Product ID/price band dihitung server dari immutable application
  snapshot dan mapping.
- [ ] Member, ineligible, incomplete attestation, atau terminal application
  ditolak sebelum payment sheet.
- [ ] Verified transaction setelah acceptance mengaktifkan payment,
  entitlement tiga bulan, dan capability Coach secara atomik/idempoten.
- [ ] Admin detail memuat accepted_pending_payment, verified transaction, dan
  entitlement disposition read-only.
- [ ] Rejection sebelum payment mengunci preflight dan tidak membuat
  transaction/refund state.
- [ ] Expiry reconciliation memakai server clock dan mengunci Coach operation.
- [ ] Manual renewal membuat transaction/period baru dan tidak overwrite
  history.
- [ ] Renewal sebelum/ setelah expiry tidak meminta approval ulang selama
  protected Admin acceptance belum dicabut.
- [ ] Refund/revocation terhadap purchase aktif merekonsiliasi capability dan
  audit.
- [ ] Add pgTAP, Edge integration, StoreKitTest, Swift, dan focused UI journey.

#### Gate 12.6

- [ ] Purchase success hanya dapat mengaktifkan Coach jika protected Admin
  acceptance masih valid.
- [ ] Coach access memerlukan protected approval + active entitlement.
- [ ] Tiga bulan, expiry, renewal, rejection, refund, dan revocation
  deterministic serta server-authoritative.

### 12.7 — Notification V2 inbox dan reconciliation

- [ ] Buat public webhook endpoint khusus signedPayload dengan verify_jwt
  disabled hanya untuk Apple webhook path.
- [ ] Reject body yang tidak mempunyai signedPayload valid.
- [ ] Verify outer notification JWS dan nested signedTransactionInfo/
  signedRenewalInfo bila tersedia.
- [ ] Validate bundle, appAppleId when production, environment, signedDate,
  product mapping, and transaction ownership.
- [ ] Insert notificationUUID unik ke durable inbox sebelum response success.
- [ ] Duplicate notification bersifat no-op idempoten.
- [ ] Process ONE_TIME_CHARGE, REFUND, REVOKE, TEST, dan event relevan sesuai
  product type final; unknown type disimpan aman untuk observability.
- [ ] Out-of-order event memakai signed/event time dan tidak menghidupkan
  entitlement yang sudah direvoke/refund oleh event lebih baru.
- [ ] Durable processor mempunyai retry count, last error code, processed_at,
  dan dead-letter/manual retry boundary tanpa menyimpan secret di log.
- [ ] Tambahkan reconciliation operation untuk transaction history/current
  server state saat notification terlewat.
- [ ] Local tests memakai signed deterministic fixtures. Request a Test
  Notification nyata tetap unchecked sampai Phase 13.

#### Gate 12.7

- [ ] Invalid webhook tidak mengubah state.
- [ ] Valid duplicate/out-of-order webhook menghasilkan state stabil.
- [ ] Refund, revocation, expiry, dan renewal merekonsiliasi program/Coach
  entitlement sesuai policy.

### 12.8 — Final local verification dan Phase 13 handoff

- [ ] Hapus Phase 12 placeholder/fake path dari Supabase production assembly;
  fake tetap Debug local-demo/test only.
- [ ] Pastikan Release tidak menunjuk Products.storekit lokal, localhost, atau
  local secret.
- [ ] Jalankan full Swift tests dan simulator build.
- [ ] Jalankan focused UI tests paid Participant, Coach purchase, Admin
  approval, pending, restore, refund/revocation state, dan account switch.
- [ ] Jalankan localization catalog check.
- [ ] Jalankan fresh supabase db reset --local setelah persetujuan destructive.
- [ ] Jalankan seluruh pgTAP, integration, Edge Function, lint, advisors,
  migration list, dan schema diff.
- [ ] Audit app/repository/log untuk service role, Apple private key, JWS,
  transaction ID, raw QR, dan private payment data.
- [ ] Update OpenAPI, contract matrix, implementation status, Supabase README,
  Phase 12 checklist, dan Phase 13 exact external-input guide.
- [ ] Siapkan daftar product IDs, environment mapping, hosted secrets, webhook
  URL, sandbox account, and TestFlight tests tanpa mengisi secret.
- [ ] Hosted main tetap tidak disentuh.

## Test matrix minimum

### Product dan preflight

- [ ] Free versus paid program.
- [ ] Product mapping ready, unavailable, retired, wrong environment.
- [ ] Desired price berbeda dari store display price.
- [ ] Wrong product untuk program/cohort/price band.
- [ ] Wrong Coach, inactive Coach, expired Coach entitlement.
- [ ] Cutoff exact boundary.
- [ ] Capacity available, full, dan concurrent last reservation.
- [ ] Purchase intent duplicate, expired, cancelled, fulfilled, dan replayed.

### Apple verification

- [ ] Valid Xcode signed transaction.
- [ ] Tampered JWS/signature/certificate chain.
- [ ] Wrong bundle, environment, product, appAccountToken, transaction ID.
- [ ] Revoked/refunded transaction.
- [ ] Duplicate transaction dan original transaction lineage.
- [ ] Same transaction untuk account/program/application lain.
- [ ] Sandbox/production mismatch handling server-only.
- [ ] Server verification timeout/retry.

### Paid program

- [ ] Success, cancel, pending/Ask to Buy, interrupted, unverified, offline.
- [ ] Duplicate callback, updates, unfinished, relaunch, restore.
- [ ] Enrollment/score row exactly once.
- [ ] Cohort same price but different product ID.
- [ ] Refund/revocation before and after activity.
- [ ] Account deletion retention/anonymization.

### Coach access

- [ ] Member and incomplete eligibility rejected.
- [ ] Three price bands.
- [ ] Purchase sebelum Admin acceptance ditolak.
- [ ] Admin accept/revoke versus purchase race.
- [ ] Entitlement starts according to approved policy.
- [ ] Three-month calendar boundary and server timezone.
- [ ] Expiry at exact timestamp.
- [ ] Renewal before/after expiry.
- [ ] Refund/revocation of current and historical purchase.
- [ ] Protected Coach operation with cached role but inactive entitlement.

### Notification and reliability

- [ ] TEST, ONE_TIME_CHARGE, REFUND, REVOKE, unknown.
- [ ] Duplicate notificationUUID.
- [ ] Out-of-order and older signedDate.
- [ ] Durable response and retry/dead-letter.
- [ ] Missed-notification reconciliation.
- [ ] No JWS, secret, transaction identifier, account token, or private
  commerce context in logs/errors.

### iOS and presentation

- [ ] Product.displayPrice and locale id-ID presentation.
- [ ] Loading, unavailable, pending, verifying, fulfilled, failed, refund,
  revoked, expired, and renewal states.
- [ ] Dynamic Type, VoiceOver, Reduce Motion, dark mode, and offline.
- [ ] AppStore.sync only from explicit Restore action.
- [ ] Transaction listener lifecycle and cancellation.
- [ ] Logout/account switch clears private state.
- [ ] No visible localization key on non-Indonesian device locale.

## Verification strategy

Exact CLI flags and StoreKit APIs must be confirmed against installed tool
help/SDK when implementation begins.

Readiness order for slices that need backend:

1. colima status
2. docker info
3. supabase status
4. supabase --version and relevant command --help

Local database gate:

- supabase db reset --local, only after fresh destructive approval.
- supabase migration list --local.
- supabase test db --local supabase/tests/database.
- supabase db lint --local --level warning --fail-on error.
- supabase db advisors --local --type all --level warn --fail-on error.
- supabase db diff --local.

Edge integration gate:

- Load local environment at runtime from supabase status -o env without
  printing or persisting credentials.
- Run existing integration scripts plus Phase 12 commerce/verifier/
  notification scripts after those files exist.
- Test tampered and replay payloads without logging signed fixtures.

iOS gate:

- Use XcodeBuildMCP build_sim and test_sim.
- Use StoreKitTest with the Debug StoreKit configuration.
- Run the smallest focused suite after each slice, then full
  MSCBodyTransformationTests and focused UI matrix at 12.8.
- Run scripts/check_localization_catalog.sh for every runtime copy change.

No command in Phase 12 may deploy to hosted main, set production secrets, or
invoke real App Store sandbox/production unless the user explicitly moves the
task into the Phase 13 production gate.

## Exit criteria lokal Phase 12

- [ ] All Gate 12.0–12.8 local items selesai.
- [ ] Product and lifecycle decisions documented.
- [ ] StoreKit local program and Coach journeys are deterministic.
- [ ] Apple JWS verification is server-side and replay-safe.
- [ ] Paid program fulfillment creates one entitlement/enrollment atomically.
- [ ] Coach payment, approval, activation, expiry, renewal, refund, and
  revocation are separated and server-authoritative.
- [ ] Notification V2 handler/inbox/reconciliation passes local signed-fixture
  tests.
- [ ] No client-authoritative price, payment, entitlement, role, date, or
  enrollment path.
- [ ] No real repository uses fake commerce in Supabase mode.
- [ ] Local demo and previews remain deterministic without StoreKit/Supabase.
- [ ] Fresh reset, pgTAP, integration, Edge, Swift, StoreKitTest, UI,
  localization, lint, advisors, and schema diff gates are green.
- [ ] OpenAPI and Android contract describe the same provider-neutral ledger.
- [ ] Hosted main and real App Store environment remain untouched.

## External gates yang sengaja belum menutup Phase 12 lokal

Item ini harus tetap unchecked dan dipindahkan ke Phase 13 acceptance:

- [ ] App Store Connect product records approved/ready.
- [ ] In-App Purchase key, issuer ID, appAppleId, dan Apple root certificates
  configured as hosted secrets.
- [ ] Hosted migration/functions/config deployed with explicit approval.
- [ ] Sandbox Apple Account and physical-device purchase.
- [ ] TestFlight purchase/restore/refund/revocation.
- [ ] Public Notification V2 endpoint and TEST notification.
- [ ] Production product availability, currency, tax, and review metadata.
- [ ] Hosted retention/security/advisor sign-off.

## Referensi resmi yang diverifikasi saat audit

- Apple In-App Purchase types:
  https://developer.apple.com/help/app-store-connect/reference/in-app-purchases-and-subscriptions/in-app-purchase-types
- Apple StoreKit Testing in Xcode:
  https://developer.apple.com/documentation/xcode/setting-up-storekit-testing-in-xcode
- Apple Transaction and JWS:
  https://developer.apple.com/documentation/storekit/transaction
- Apple purchase options and appAccountToken:
  https://developer.apple.com/documentation/storekit/product/purchase(options:)
- Apple currentEntitlements and AppStore.sync:
  https://developer.apple.com/documentation/storekit/transaction/currententitlements
  https://developer.apple.com/documentation/storekit/appstore/sync()
- Apple App Store Server API and Server Library:
  https://developer.apple.com/documentation/appstoreserverapi
  https://github.com/apple/app-store-server-library-node
- Apple App Store Server Notifications V2:
  https://developer.apple.com/documentation/appstoreservernotifications
- Supabase Edge Functions secrets/auth:
  https://supabase.com/docs/guides/functions/secrets
  https://supabase.com/docs/guides/functions/auth
- Supabase 2026 explicit Data API grants change:
  https://supabase.com/changelog/45329-breaking-change-tables-not-exposed-to-data-and-graphql-api-automatically

Referensi harus diverifikasi kembali ketika implementation dimulai karena
StoreKit, Apple server APIs, official server library, Supabase CLI, dan Edge
Runtime dapat berubah.

## Handoff setelah Phase 12

1. Phase 13 meminta persetujuan production eksplisit.
2. Buat App Store Connect products dan hosted secrets.
3. Review migration/function/config diff sebelum hosted deployment.
4. Deploy ke hosted main.
5. Configure hosted Apple/Google Auth dan App Store Server Notifications.
6. Jalankan sandbox/TestFlight/physical-device/security matrix.
7. Phase 14 memakai shared commerce contract untuk Play Billing Android.
8. SMTP/domain tetap skipped sampai keputusan produk berubah.

## Progress log

### 4 Agustus 2026 — Coach access handoff

- Menambahkan tiga price band dan manual three-month intent.
- Mencatat intent awal bahwa payment dan Admin approval adalah state terpisah;
  urutan finalnya kemudian direkonsiliasi pada audit 8 Agustus 2026.
- Phase 09.5 fake purchase tetap demo-only.

### 8 Agustus 2026 — Audit pasca-Phase 11

- Membaca Phase 11 final workplan, contract matrix, implementation status,
  OpenAPI, StoreKit adapter, Participant/Coach payment UI, commerce schema,
  Coach decision/entitlement operations, account deletion retention, dan
  Phase 13 boundary.
- Menetapkan existing StoreKitProgramPurchaseService sebagai seam yang harus
  di-hardening, bukan implementasi Phase 12 yang sudah selesai.
- Menemukan client identity/Coach parameters, missing appAccountToken,
  missing purchase intent, environment staging, one-record Coach payment,
  direct-active Coach entitlement, dan notification/reconciliation gap.
- Memisahkan local StoreKit/JWS implementation dari App Store Connect,
  sandbox, hosted webhook, TestFlight, dan physical-device external gates.
- Memindahkan live Google verification ke Phase 14 sambil mempertahankan
  provider-neutral ledger/OpenAPI di Phase 12.
- Menambahkan Gate 12.0 product policy decisions, Slice 12.1 verifier
  feasibility, Slice 12.2–12.7 vertical implementation, Slice 12.8 final
  verification, minimum test matrix, security boundary, dan Phase 13 handoff.
- Mengacu pada official Apple StoreKit/App Store Server documentation dan
  current Supabase Edge Functions/changelog.
- Merekam keputusan pengguna: program berharga memakai non-consumable unik per
  cohort dan boleh dibeli Participant/Coach; akses Coach memakai non-renewing
  subscription tiga bulan; initial acceptance sebelum payment; renewal manual
  tanpa acceptance ulang; expired Coach menonaktifkan fitur dan QR; serta
  tidak ada voluntary refund dengan Apple/legal refund tetap authoritative.
- Mengidentifikasi com.ranggar.MSCBodyTransformation sebagai current final
  working bundle identifier.
- Pengguna mengonfirmasi TTL reservation 30 menit, refresh selama purchase
  sheet aktif, dan fulfillment rare paid over-capacity yang diaudit bila
  transaksi Apple sah selesai setelah reservation dilepas. Seluruh input
  manual product policy Gate 12.0 kini lengkap.
- Tidak menjalankan Colima, Supabase, database reset, build, test, Xcode,
  App Store Connect, atau hosted deployment karena pekerjaan ini hanya audit
  dokumentasi.
