# Phase 13.1: Release Hardening, Hosted Main, Sandbox, and Physical Testing

> Status: **seluruh pekerjaan otomatis/non-manual Phase 13.1 selesai. Source
> hardening, 20 migration, SSL enforcement, sembilan Edge Functions, recurring
> jobs, Google/Apple hosted provider, URL legal, Release build, dan audit
> otomatis sudah terverifikasi. Release terbaru sudah dibangun, dipasang, dan
> diluncurkan pada iPhone fisik.
>
> App Store Connect, credential Apple, product mapping yang bergantung pada
> produk final, test identity/data/QR, sandbox purchase, serta exploratory test
> owner berstatus `DEFERRED MANUAL`. Status selesai ini **bukan** klaim bahwa
> sandbox purchase sudah siap; langkah manual tersebut tetap wajib sebelum
> acceptance fisik/commerce dan izin Phase 13.2.
> Mutation hosted berikutnya tetap memerlukan persetujuan eksplisit sesuai
> jenis tindakannya**.
>
> Phase ini sengaja berhenti sebelum archive/upload. Tujuannya adalah memberi
> owner kesempatan memakai dan menguji aplikasi secara langsung terhadap
> backend production sebelum build didistribusikan melalui TestFlight.

## Batas selesai menurut owner

Sesuai keputusan owner pada 9 Agustus 2026, Phase 13.1 dianggap selesai ketika
seluruh pekerjaan yang dapat dikerjakan Codex tanpa input atau tindakan manual
owner sudah selesai dan terverifikasi. App Store Connect, credential Apple,
product final, test identity/data/QR, sandbox purchase, serta exploratory test
perangkat boleh memerlukan beberapa hari dan dicatat sebagai
`DEFERRED MANUAL`.

Deferral tersebut tidak menghalangi penutupan goal Phase 13.1, tetapi tetap
menjadi gate wajib sebelum purchase testing dinyatakan siap dan sebelum owner
memberi izin eksplisit untuk Phase 13.2.

## Tujuan

Menghasilkan aplikasi Release yang dapat diuji sendiri dan pada iPhone fisik:

- bundle, App Icon, privacy manifest, legal content, dan konfigurasi Release
  sudah layak production;
- hosted Supabase `main` telah dideploy dengan security boundary yang benar;
- Google dan Apple OAuth hosted berfungsi;
- StoreKit/App Store Connect sandbox serta Apple server integration berfungsi;
- lifecycle akun, commerce, authorization, retention, dan recurring jobs
  server-authoritative;
- checklist sandbox/physical tersedia dan build siap dijalankan owner;
- belum ada archive yang diupload ke App Store Connect atau TestFlight.

## Prasyarat

- Phase 12 lokal selesai dan tetap menjadi baseline.
- Baca `PROGRAM_END_TO_END_REMEDIATION_WORKPLAN.md`,
  `PROGRAM_END_TO_END_CONTRACT_MATRIX.md`, dan
  `PROGRAM_END_TO_END_IMPLEMENTATION_STATUS.md` bila kontrak program berubah.
- Phase 13 overview: `14_PHASE_13_SECURITY_RELEASE_AND_TESTFLIGHT.md`.

## Keputusan produk dan teknis final

- Bundle identifier: `com.ranggar.MSCBodyTransformation`.
- Minimum deployment target: iOS 17.
- Development memakai Supabase lokal; production memakai hosted Supabase
  `main`; tidak ada hosted staging atau Supabase branch.
- Login production hanya Google dan Apple. Email/password, SMTP, dan custom
  mail domain tetap **SKIPPED**.
- Google dan Apple identity yang berbeda tetap account terpisah; tidak ada
  automatic account linking.
- Program gratis tidak memakai StoreKit.
- Setiap cohort program berbayar memakai non-consumable production unik.
- Akses Coach tiga bulan memakai tiga non-renewing subscription untuk price
  band entry, growth, dan leadership.
- Pengajuan Coach awal: Admin menerima, applicant membayar, lalu entitlement
  aktif. Renewal manual tidak memerlukan acceptance ulang selama approval
  belum dicabut.
- Tidak ada refund sukarela. Refund/revocation Apple tetap authoritative.
- Reservation kapasitas 30 menit. Transaksi Apple sah yang terlambat tetap
  diterima sebagai rare audited over-capacity.
- Enrollment Participant hanya melalui QR Coach aktif, tanpa typed-code
  fallback.
- Privacy Policy dan Terms memerlukan URL HTTPS publik, tetapi custom domain
  tidak diwajibkan.

## Baseline audit

| Area | Kondisi terakhir | Tindakan Phase 13.1 |
|---|---|---|
| Phase 12 lokal | 17 migrations, 348 pgTAP assertions, 151 integration checks, 190 Swift/StoreKit tests lulus | Gunakan sebagai baseline |
| App Icon | Default/dark/tinted 1024×1024 tanpa alpha sudah dipasang; source dan Icon Composer tersedia | Pertahankan dan scan pada preflight Release |
| Privacy manifest | Ada tetapi declarations belum diaudit final | Rekonsiliasi dengan behavior nyata |
| Legal UI | Masih mempunyai placeholder/dead-end | Ganti dengan content dan URL production |
| Camera purpose | Copy lama belum menjelaskan QR Coach dan foto bukti | Perbaiki sebelum device test |
| Release backend config | Masih bergantung pada process environment | Embed public non-secret production config |
| Product mapping | Hanya local/Xcode seed | Provision production mapping idempoten |
| App Store verification | Local signed fixtures selesai | Aktifkan reconciliation nyata dan TEST notification |
| Apple account lifecycle | Token revoke/account events belum dibuktikan hosted | Implementasikan dan uji |
| Recurring operations | Belum dibuktikan hosted | Jadwalkan, observasi, dan uji retry |

## Input manual

Secret tidak boleh dikirim lewat chat, ditaruh di source, shared scheme,
committed `.env`, screenshot, fixture, atau log.

### Source dan legal

- [x] Artwork App Icon final 1024×1024 disetujui dan dipasang.
- [x] Sediakan teks final Privacy Policy, Terms, wellness disclaimer,
  retention, account deletion, Coach payment/expiry, serta contest rules bila
  leaderboard memberi hadiah.
- [x] Sediakan URL HTTPS publik Privacy Policy dan Terms of Use.

### Hosted Supabase `main`

- [x] Konfirmasi project ref hosted `main`, organization, dan region.
- [x] Temukan hosted URL dan publishable key modern untuk Release melalui
  preflight read-only; nilainya belum dipasang sampai key-rotation gate lulus.
- [x] Sediakan akses Dashboard/CLI yang berhak deploy tanpa membagikan database
  password atau service-role key di chat.
- [x] Konfirmasi backup/rollback plan dan maintenance window.
- [x] Berikan persetujuan production eksplisit yang menyebut hosted `main`
  untuk migration, delapan Function, dan database SSL enforcement yang sudah
  dijalankan. Auth/secret/cron/product mutation berikutnya tetap terpisah.
- [x] Nonaktifkan legacy `anon` dan `service_role` yang sempat tampil pada
  output CLI dan revoke legacy signing key. Publishable/secret key modern
  tersedia dan JWKS publik sudah membuktikan signing key asymmetric ES256
  aktif.

### App Store Connect dan sandbox

- [ ] **DEFERRED MANUAL:** Accept Paid Apps Agreement dan lengkapi tax/banking.
- [ ] **DEFERRED MANUAL:** Catat numeric `appAppleId`.
- [ ] **DEFERRED MANUAL:** Buat satu non-consumable untuk setiap cohort berbayar.
- [ ] **DEFERRED MANUAL:** Buat tiga non-renewing subscription Coach tiga bulan.
- [ ] **DEFERRED MANUAL:** Lengkapi display name/description Bahasa Indonesia,
  price, availability,
  dan tax category minimum agar product dapat diuji. Review screenshot serta
  final submission association diselesaikan pada Phase 13.3.
- [ ] **DEFERRED MANUAL:** Buat In-App Purchase/App Store Connect key bila Server API
  reconciliation membutuhkannya; `.p8`, issuer ID, dan key ID server-only.
- [ ] **DEFERRED MANUAL:** Siapkan Sandbox Apple Account.

### Physical-device gate

- [x] Sediakan iPhone fisik iOS 17+; iPad fisik sangat disarankan.
- [ ] **DEFERRED MANUAL:** Sediakan test account Google, Apple/private relay,
  Participant, Coach,
  dan Admin tanpa data pribadi nyata.
- [ ] **DEFERRED MANUAL:** Sediakan QR Coach aktif untuk enrollment.

## Approval boundary

Source, tests, local migrations, dan local Edge Function dapat dikerjakan tanpa
menyentuh production. Persetujuan eksplisit diperlukan sebelum:

- `supabase link`, migration push, atau SQL ke hosted `main`;
- Edge Function deploy, secret mutation, hosted Auth provider/config mutation;
- cron/schedule, Storage policy, network restriction, atau project setting;
- App Store Connect product atau notification URL mutation.

Persetujuan local reset sebelumnya tidak mengizinkan operasi hosted. Seed dan
data development tidak pernah dipush ke production.

## Urutan implementasi

### Slice 13.1.0 — Freeze baseline dan inventory

- [x] Pastikan working tree tidak mempunyai perubahan yang tidak dipahami.
- [x] Catat exact Phase 12 verification baseline.
- [x] Audit dependency/license dan pin official Apple server library yang
  sudah disetujui; jangan menambah dependency tanpa approval.
- [x] Rekonsiliasi OpenAPI, migration, Edge routes, Swift DTO, dan error map
  setelah source-only changes.
- [x] Inventarisasi public client config, server non-secret config, server
  secret, dan local-only values.
- [x] Buktikan tidak ada secret, local key, private URL, atau test-user PII di
  material yang akan masuk Release.

**Gate 13.1.0:** baseline dan external inputs terdokumentasi; belum ada
mutation hosted.

### Slice 13.1.1 — Bundle, privacy manifest, legal, dan Release config

- [x] Tambahkan App Icon production default, dark, dan tinted; periksa alpha
  dan rendering ukuran kecil.
- [x] Perbaiki `NSCameraUsageDescription` menjadi QR Coach dan foto bukti.
- [x] Audit photo-library purpose string berdasarkan API yang benar-benar
  dipakai; jangan menambahkan permission yang tidak diperlukan.
- [x] Ganti legal placeholder Participant/Coach dengan bundled content dan
  fallback bila URL gagal.
- [x] Isi `PrivacyInfo.xcprivacy` berdasarkan data nyata: nama, email, nomor HP,
  user ID, foto/user content, berat/fitness, purchase history, dan diagnostics.
- [x] Pertahankan `NSPrivacyTracking=false` karena tidak ada tracking.
- [x] Audit required-reason APIs dan deklarasikan hanya reason code resmi yang
  benar-benar relevan.
- [x] Buat mekanisme konfigurasi Release non-secret untuk hosted URL dan
  publishable key tanpa bergantung pada Xcode Run scheme environment; nilai
  hosted masih menunggu Gate 13.1.4.
- [x] Isi hosted URL dan publishable key modern setelah project production
  dikonfirmasi; Release device build sudah memakai hosted HTTPS.
- [x] Isi Privacy Policy URL dan Terms URL HTTPS final.
- [x] Release fail closed bila config kosong, bukan HTTPS, loopback, `.local`,
  atau LAN address.
- [x] Pastikan service-role/secret key, Apple `.p8`, OAuth secret, local key,
  `Products.storekit`, Debug selector, dan demo fixture tidak masuk Release.
- [x] Finalkan version/build awal `1.0 (1)`, launch experience, device families,
  dan orientation iPhone/iPad.
- [x] Jalankan Release build dan inspect built `.app` secara lokal. Archive dan
  upload secara sengaja ditunda ke Phase 13.2.

**Gate 13.1.1:** Release build lokal tidak mempunyai placeholder, invalid
config, local dependency, secret, atau privacy/bundle blocker.

### Slice 13.1.2 — Hosted Auth dan account lifecycle

- [x] Rekonsiliasi callback scheme aplikasi dan kontrak endpoint lifecycle.
- [x] Rekonsiliasi hosted redirect allowlist setelah project ref dikonfirmasi.
- [x] Konfigurasi Google provider hosted dengan production client ID/secret;
  endpoint publik Auth settings dan redirect 302 ke `accounts.google.com`
  sudah membuktikan provider aktif tanpa membaca secret.
- [x] Konfigurasi Apple provider/App ID hosted; public Auth settings
  membuktikan Apple aktif dan credential tetap server-side.
- [x] Pastikan email/password UI Release tidak menjadi jalur production.
- [x] Pastikan hosted email signup juga tetap nonaktif/tidak diekspos; public
  Auth settings membuktikan Email provider nonaktif sementara signup global
  tetap aktif untuk registrasi Google/Apple.
- [ ] **DEFERRED MANUAL:** Uji Google login/logout/relogin, force-close restore, expired session,
  refresh, cancel, provider error, dan account switch.
- [ ] **DEFERRED MANUAL:** Uji Apple login/logout/relogin, private relay, first-login name-only,
  revoked/not-found credential, restore, dan account switch.
- [x] Jangan merge Google dan Apple hanya karena email sama; kontrak dan test
  otomatis mempertahankan identity terpisah.
- [x] Tambahkan endpoint Sign in with Apple account events, terpisah dari App
  Store Server Notifications commerce.
- [x] Verifikasi secara lokal signature/payload, idempotency, audit minimum,
  forwarding change, dan Apple account deletion event.
- [x] Implementasikan revoke Apple token sebagai bagian deletion workflow
  dengan durable retry.
- [x] Verifikasi deletion lokal menghapus identity/private data/media dan
  menganonimkan record yang wajib dipertahankan.
- [x] Coach dengan participant aktif tetap diblok sampai Admin transfer.

**Gate 13.1.2:** hosted OAuth dan account lifecycle lulus tanpa provider secret
di client.

### Slice 13.1.3 — Hosted security preflight

- [x] Verifikasi Supabase CLI dan flags melalui `--help` pada hari preflight.
- [x] Verifikasi project ref, organization, DB version, migration history,
  extension, dan hosted schema.
- [x] Buat backup/snapshot dan forward-fix/rollback runbook.
- [x] Review migration lokal; larang seed, local product IDs, test account, dan
  destructive production rewrite.
- [x] Review source/local exposed schemas, grants, RLS, Storage policies,
  public views,
  `anon`, dan `authenticated`.
- [x] Review seluruh `security definer` lokal, fixed `search_path`, revoked PUBLIC,
  allowlist, authorization, dan audit.
- [x] Pastikan authorization tidak membaca editable metadata/client role.
- [x] Audit Guest projection lokal terhadap PII, weight, private media, raw QR,
  phone, answer, dan unpublished content leakage.
- [x] Audit Edge Function JWT, secret boundary, body limit, timeout,
  idempotency, replay, rate limiting, cache, dan sanitized errors.
- [x] Review Security/Performance Advisor, SSL, rate/capacity boundary, network
  restriction, backup, dan Storage posture. MFA/CAPTCHA/spend alert yang
  memerlukan keputusan Dashboard owner tidak menjadi blocker otomatis.
- [x] Aktifkan database SSL enforcement; post-deploy verification membuktikan
  `database=true`.
- [x] Putuskan allowlist koneksi database langsung; owner menerima akses
  IPv4/IPv6 yang masih terbuka sebagai temporary accepted risk. Data API
  publik tetap diamankan oleh RLS.
- [x] Catat SMTP sebagai intentional skip.

**Gate 13.1.3:** reviewed diff dan security report tersedia; minta approval
production sebelum deployment.

### Slice 13.1.4 — Deploy hosted `main` dan recurring operations

- [x] Link CLI hanya ke hosted `main` yang dikonfirmasi untuk read-only
  preflight; belum ada migration/function/config mutation.
- [x] Bandingkan migration history lalu push migration berurutan; jangan reset,
  seed, atau dashboard-edit schema.
- [ ] **DEFERRED MANUAL:** Provision product mapping production secara
  idempoten setelah Product ID final tersedia di App Store Connect.
- [x] Deploy `delete-account`, orphan cleanup, `commerce`, Apple commerce
  notifications, Apple account-events, dan reconciliation worker.
- [x] Set Edge secrets recurring operations melalui approved mechanism tanpa
  mencetak nilainya. Credential App Store Server tetap `DEFERRED MANUAL`.
- [x] Jadwalkan provisional identity cleanup, commerce reservation/entitlement
  expiry, orphan media cleanup, dan missed-event reconciliation.
- [x] Jangan taruh service key di URL/query scheduled job.
- [x] Jalankan hosted migration list, schema diff, lint, grants, RLS/Storage,
  function health, cron status, dan redaction-safe audit. Satu schema drift
  hanya helper platform `public.rls_auto_enable()`; execute `PUBLIC` tetap
  tercabut dan seluruh migration application cocok.
- [x] Jalankan Security/Performance Advisor, hosted Auth launch smoke, dan
  final artifact/log redaction scan. Login credential end-to-end tetap bagian
  exploratory manual owner.
- [x] Jalankan non-destructive rollback/failure drill.

**Gate 13.1.4:** hosted smoke lulus, jobs observable, tidak ada secret leak,
dan Release hanya memakai hosted URL + publishable key.

### Slice 13.1.5 — StoreKit/App Store Connect dan Apple server integration

- [ ] **DEFERRED MANUAL:** Pastikan app record memakai bundle ID final.
- [ ] **DEFERRED MANUAL:** Pastikan agreement, banking, tax, category, pricing,
  dan availability
  minimum untuk sandbox/product testing valid.
- [ ] **DEFERRED MANUAL:** Finalkan non-consumable per paid cohort dan tiga
  Coach products; product
  ID/type harus sama dengan mapping server.
- [x] Harga/currency UI berasal dari StoreKit pada implementasi dan
  StoreKitTest lokal; product sandbox final tetap `DEFERRED MANUAL`.
- [x] Implementasikan Server API reconciliation dengan official library dan
  server-only credential; tangani environment, pagination, retry, dan limit.
- [ ] **DEFERRED MANUAL:** Konfigurasi Notification V2 HTTPS endpoint.
- [ ] **DEFERRED MANUAL:** Kirim Request a Test Notification; verifikasi 2xx, signature, durable
  inbox tunggal, processed state, dan retry.
- [x] Uji otomatis duplicate, out-of-order, delayed, invalid signature, wrong
  app/product environment, refund, revoke, dan recovery contract.
- [ ] **DEFERRED MANUAL:** Uji sandbox purchase, pending/interrupted, unfinished relaunch, restore,
  cross-device restore, refund/revocation, dan Coach renewal.

**Gate 13.1.5:** products dapat dimuat, fulfillment server-authoritative, TEST
notification processed, dan reconciliation memulihkan event hilang.

### Slice 13.1.6 — Privacy, retention, security, dan abuse

- [x] Finalkan Privacy Policy, Terms, wellness disclaimer, retention, account
  deletion, Coach payment/expiry/no-voluntary-refund terms, dan contest rules.
- [x] Pastikan bundled privacy policy dan manifest konsisten dengan behavior.
  App Store
  privacy questionnaire diselesaikan pada Phase 13.3.
- [x] Verifikasi photo metadata stripping, private paths, short signed URLs,
  cache, dan temporary-file cleanup secara lokal. Private download memakai
  authenticated Storage policy; signed URL yang diuji berdurasi pendek.
- [x] Verifikasi source/log dan artifact tidak berisi password, token, service
  key, raw QR, weight,
  private URL/path, signed Apple payload, atau purchase credential.
- [x] Jalankan horizontal-access, escalation, forged metadata, replay,
  duplicate fulfillment, forged webhook, rate/capacity/cutoff race matrix.
- [x] Uji otomatis deletion/retention Participant, Coach, Admin restriction,
  winner, serta commerce/audit anonymization. Apple private relay nyata tetap
  `DEFERRED MANUAL`.
- [x] Dokumentasikan incident response, secret rotation, webhook outage,
  compromised tester, dan production rollback.

**Gate 13.1.6:** tidak ada critical/high privacy atau security blocker.

### Slice 13.1.7 — Sandbox dan physical-device readiness

Checklist berikut dilanjutkan owner setelah handoff. Item hasil pengujian yang
belum dicentang tidak menghalangi status readiness Phase 13.1, tetapi defect
critical tetap menghalangi izin Phase 13.2.

**Seluruh checkbox yang belum dicentang pada Slice 13.1.7 dan checklist owner
di bawah berstatus `DEFERRED MANUAL`.**

- [ ] VoiceOver order/label/hint/action untuk Auth, QR, media, purchase,
  leaderboard, Coach review, Admin CMS, dan account deletion.
- [ ] Dynamic Type accessibility sizes tanpa production truncation.
- [ ] Uji Reduce Motion/Transparency, Increase Contrast, Differentiate Without
  Color, dark/light, Liquid Glass iOS 26, dan iOS 17 fallback.
- [ ] Uji iOS 17 baseline, iOS 26+, iPhone kecil/besar, dan iPad bila tersedia.
- [ ] Uji camera denied/restricted, QR invalid/mismatch/inactive, PhotosPicker,
  interrupted upload, resize/metadata stripping, background/foreground.
- [ ] Uji offline/timeout/reconnect, session expiry, Realtime reconnect,
  pagination, empty/error state, transaction interruption, dan relaunch.
- [ ] Profile launch, image lists, upload memory, StoreKit listener, glass,
  leak, jank, dan crash blocker.
- [ ] Uji force-close setelah OAuth dan purchase sebelum fulfillment selesai.
- [ ] Owner menjalankan exploratory test sendiri terhadap hosted backend dan
  mencatat defect sebelum mengizinkan Phase 13.2.

**Gate 13.1.7 readiness:** build Release terbaru terpasang/dapat diluncurkan,
dependency sandbox dan test data minimum siap, serta checklist owner sudah
diserahkan. Critical sandbox/physical journey kemudian harus lulus sebelum
owner mengizinkan Phase 13.2.

## Checklist owner setelah Phase 13.1 ready

Checklist lengkap yang dapat diisi terdapat di
`Documentation/Release/PHASE_13_1_PHYSICAL_TEST_HANDOFF.md`. Ringkasan berikut
tetap menjadi acceptance minimum sebelum Phase 13.2.

### Guest dan Auth

- [x] Guest membuka tab publik tanpa Auth identity/private data.
- [ ] `Gabung program` menuju Login dan resume program yang benar.
- [ ] Google dan Apple register/login/logout/relogin/restore/cancel/error.
- [ ] Apple private relay dan first-name-only berfungsi.
- [ ] Google dan Apple identity tetap terpisah.
- [x] Email/password/reset tidak tampil dan **SKIPPED BY PRODUCT**.

### Participant dan program

- [ ] Provider name menjadi default profil dan tetap editable.
- [ ] QR Coach aktif/invalid/mismatch/inactive/expired, cutoff, capacity,
  duplicate, dan no typed-code fallback.
- [ ] Free enrollment serta paid purchase Participant/Coach-as-participant.
- [ ] Weigh-in, typed answer, quiz, photo evidence, retry, scoring,
  leaderboard, winners, dan poster.
- [ ] Weight/private answers/private media tidak bocor.

### Coach dan Admin

- [ ] Eligibility, attestations, Admin accept, initial payment, activation,
  expiry, QR inactive, renewal, refund/revocation, dan transfer teraudit.
- [ ] Admin CMS create/edit/publish/duplicate/closure/winner/poster.
- [ ] Manual enrollment tetap memvalidasi capacity, lifecycle, Coach active,
  entitlement, dan audit reason.

### Commerce dan deletion

- [ ] Product-not-ready, pending, interrupted, duplicate/replay, wrong account,
  wrong environment/product, restore, dan missed notification.
- [ ] Reservation 30 menit dan audited late over-capacity.
- [ ] Notification/refund/reconciliation idempoten dan observable.
- [ ] Google reauthentication lalu immediate deletion.
- [ ] Apple reauthentication, token revocation, lalu immediate deletion.
- [ ] Private data/media hilang; retained winner/audit/commerce anonim.
- [ ] Coach dengan participant aktif diblok sampai Admin transfer.

## Exit criteria readiness Phase 13.1

- [x] Gate source, hosted, Auth, security, dan Release config lulus atau
  mempunyai accepted exception.
- [x] Release build memakai bundle ID final, iOS 17+, final icon/legal/privacy,
  hosted HTTPS config, dan tidak membawa local/debug/secrets.
- [x] Hosted migrations/functions/jobs/Auth/security lulus.
- [ ] **DEFERRED MANUAL:** App Store Connect products, server secret, mapping,
  Notification V2 TEST, dan Sandbox Apple Account siap untuk pengujian.
- [ ] **DEFERRED MANUAL:** Google/Apple test identities, Admin bootstrap,
  minimal program test, dan QR Coach aktif tersedia.
- [x] Release terbaru berhasil dibangun, dipasang, dan diluncurkan pada iPhone
  fisik; checklist owner sudah diserahkan.
- [x] Belum ada archive/upload/TestFlight mutation.
- [x] Seluruh pekerjaan otomatis/non-manual yang dapat dilakukan Codex sudah
  selesai dan terverifikasi; goal Phase 13.1 boleh ditutup sesuai keputusan
  owner.

Goal engineering Phase 13.1 sudah selesai. Owner selanjutnya menyelesaikan
item `DEFERRED MANUAL` dan exploratory test. Phase 13.2 baru boleh dimulai bila
hasil critical journey lulus dan owner memberi persetujuan eksplisit.

## Referensi

- Apple IAP: https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/overview-for-configuring-in-app-purchases
- App Store Server Notifications V2: https://developer.apple.com/documentation/AppStoreServerNotifications/enabling-app-store-server-notifications
- App Store Server API: https://developer.apple.com/documentation/appstoreserverapi
- Privacy manifest: https://developer.apple.com/documentation/bundleresources/privacy-manifest-files
- Account deletion/token revoke: https://developer.apple.com/support/offering-account-deletion-in-your-app/
- Manual App Store Connect sandbox handoff:
  `Documentation/Release/APP_STORE_CONNECT_SANDBOX_SETUP.md`.
- Physical test handoff:
  `Documentation/Release/PHASE_13_1_PHYSICAL_TEST_HANDOFF.md`.
- Supabase production: https://supabase.com/docs/guides/deployment/going-into-prod
- Supabase migrations: https://supabase.com/docs/guides/deployment/database-migrations
- Supabase Edge deploy: https://supabase.com/docs/guides/functions/deploy

## Progress log

### 9 Agustus 2026 — Scope otomatis selesai; gate manual ditunda owner

- Owner menetapkan bahwa goal Phase 13.1 boleh selesai ketika seluruh
  pekerjaan non-manual selesai. App Store Connect, credential Apple, product
  mapping yang bergantung pada Product ID final, identity/data/QR test,
  sandbox purchase, dan exploratory test fisik dicatat sebagai
  `DEFERRED MANUAL`; status ini tidak mengklaim purchase testing sudah siap.
- Memperbaiki boundary autentikasi `commerce` agar request tanpa JWT selalu
  ditolak `401` sebelum konfigurasi Apple dibaca. Memperbaiki request-body
  limiter agar oversized body gagal cepat tanpa menunggu cancel stream yang
  dapat menyebabkan timeout Edge Runtime.
- Redeploy hosted `main` yang telah diizinkan menghasilkan `commerce` v3,
  `commerce-apple-notifications` v3, dan
  `cleanup-orphan-question-photos` v4; semuanya `ACTIVE` dengan verifikasi
  autentikasi/signature di handler. Hosted smoke menghasilkan kontrak yang
  diharapkan: commerce tanpa JWT `401`, cleanup tanpa JWT `401`, dan webhook
  oversized `422`.
- Verifikasi backend lokal lulus: 14 file/400 assertion pgTAP dan 171
  integration checks untuk Auth, Guest/authenticated reads, private Storage,
  enrollment/review races, Coach application, orphan cleanup, commerce, serta
  legal endpoint.
- Verifikasi native lulus: 194 Swift/StoreKit tests dalam 19 suite pada iOS
  Simulator 18.6. `supabase db lint`, Database Advisors, schema diff,
  localization catalog, `git diff --check`, source-secret scan, dan built-app
  artifact scan semuanya bersih.
- Files changed pada penutupan ini:
  `supabase/functions/commerce/index.ts`,
  `supabase/functions/_shared/http_safety.ts`,
  `supabase/tests/integration/phase12_commerce.mjs`, workplan ini, dan
  `Documentation/Release/PHASE_13_1_PHYSICAL_TEST_HANDOFF.md`.
- Tidak ada archive, upload, TestFlight, Git commit, atau Git push. Local
  Supabase, Colima, dan Edge Function serve dibiarkan berjalan sesuai aturan
  repository.

### 9 Agustus 2026 — Release terbaru terpasang dan handoff fisik disiapkan

- Xcode menemukan iPhone 17 dan iPad Pro fisik paired. Release `1.0 (1)`
  dibangun untuk destination iPhone dengan minimum target iOS 17 dan bundle ID
  final; build serta store-style bundle validation lulus.
- Build terbaru dipasang melalui CoreDevice lalu berhasil diluncurkan. Daftar
  proses perangkat membuktikan executable MSC Body Transformation tetap hidup
  setelah launch.
- Menambahkan
  `Documentation/Release/PHASE_13_1_PHYSICAL_TEST_HANDOFF.md` berisi status
  otomatis, input manual, identity/data bootstrap, seluruh journey owner, dan
  aturan pelaporan defect tanpa PII/credential.
- Build command: `xcodebuild -project MSCBodyTransformation.xcodeproj -scheme
  MSCBodyTransformation -configuration Release -destination
  'platform=iOS,id=00008150-00154D401499401C' -derivedDataPath
  /private/tmp/msc-phase13-physical-release build` — lulus.
- Blocker readiness tersisa: App Store Connect products/agreement/key,
  Notification V2, Sandbox Apple Account, commerce server secret/product
  mapping, TEST notification, test identities, Admin bootstrap, program test,
  dan QR Coach aktif. Tidak ada archive/upload/TestFlight mutation.

### 9 Agustus 2026 — Release hosted Guest dan OAuth launch smoke

- Smoke read-only Data API hosted membuktikan RPC public program, Coach, dan
  winner dapat dipanggil Guest tanpa Auth dan mengembalikan empty state yang
  aman. Percobaan SELECT Guest terhadap profile, weigh-in, jawaban privat,
  transaksi commerce, dan audit ditolak `401`/RLS; tidak ada data privat yang
  bocor.
- Release simulator memakai hosted HTTPS config dan berhasil membuka seluruh
  tab Guest. Beranda, Program, Peringkat, dan Coach menampilkan empty state
  Bahasa Indonesia; Profil hanya menawarkan Google/Apple serta legal content.
  Email/password/reset tidak tampil sesuai keputusan produk.
- Audit UI menemukan tombol informasi skenario Debug masih ikut dikompilasi
  pada Release dan dapat memperlihatkan localization key `scenario.guest_home`.
  Toolbar tersebut dibatasi dengan `#if DEBUG` pada shell Participant/Coach/
  Admin dan Guest, lalu clean Release rebuild membuktikan tombol serta key
  tidak lagi berada di UI/binary production.
- Google hosted OAuth mencapai halaman `accounts.google.com`. Apple hosted
  OAuth membuka lembar native `Sign in to your Apple Account`. Credential
  tidak dimasukkan pada simulator; lifecycle login penuh tetap menjadi bagian
  matriks akun nyata di iPhone fisik.
- Artifact Release tidak memuat `shell.scenario-info`, localhost/loopback,
  local test identity, `service_role`, `sb_secret_`, StoreKit test config,
  fixture, atau demo asset. `Info.plist`, `PrivacyInfo.xcprivacy`, localization
  catalog, dan `git diff --check` lulus. Tidak ada archive, upload, atau
  TestFlight mutation.
- Files changed untuk temuan ini:
  `Features/AppShell/ShellTabContentView.swift`,
  `Features/AppShell/RoleAppShellView.swift`, workplan ini, dan
  `Documentation/Release/PHASE_13_1_INVENTORY.md`. Asumsi: scenario tooling
  hanya untuk development dan tidak boleh tersedia pada konfigurasi Release.
- Build Release hosted simulator lulus melalui XcodeBuildMCP. Build regresi
  Debug juga lulus dengan `xcodebuild -project
  MSCBodyTransformation.xcodeproj -scheme MSCBodyTransformation
  -configuration Debug -destination 'platform=iOS
  Simulator,id=8246A128-74B4-4084-A17D-182A6BB0829F'
  -derivedDataPath /private/tmp/msc-phase13-debug-check build`.
  `scripts/check_localization_catalog.sh` dan `git diff --check` lulus.
  Tidak ada test akun yang dipakai; blocker berikutnya tetap App Store Connect
  sandbox/product mapping dan acceptance owner pada iPhone fisik.

### 9 Agustus 2026 — Hosted Google dan Release iPhone bootstrap

- Endpoint publik Auth settings membuktikan Google aktif. Authorization smoke
  memakai callback aplikasi menghasilkan HTTP 302 ke `accounts.google.com`
  tanpa menampilkan secret, OAuth state, atau token.
- Audit yang sama menemukan Apple belum aktif dan Email provider masih aktif;
  Email provider harus dimatikan tanpa mematikan signup global agar registrasi
  Google/Apple tetap dapat membuat akun.
- Hosted migration list cocok 18/18, lint `public,private` bersih, dan schema
  diff hanya memuat helper hosted `public.rls_auto_enable()`. Helper tersebut
  mempunyai fixed `search_path` dan tidak executable oleh pseudo-role PUBLIC,
  sehingga dicatat sebagai accepted platform-managed drift.
- Audit SELECT-only hosted membuktikan semua tabel `public` memakai RLS, tidak
  ada grant tabel `private` ke client, tidak ada `SECURITY DEFINER` tanpa fixed
  `search_path`/dengan PUBLIC execute, dan semua ordinary view memakai
  `security_invoker`.
- Dua SQL cron job aktif: provisional identity cleanup per jam dan commerce
  expiry tiap lima menit. Product mapping sandbox/production masih kosong;
  reconciliation Edge worker belum dijadwalkan.
- Release hosted berhasil dipasang dan diluncurkan pada iPhone 17 fisik dengan
  bundle ID `com.ranggar.MSCBodyTransformation`; proses tetap hidup setelah
  launch. OAuth/commerce acceptance belum dinyatakan lulus.

### 9 Agustus 2026 — Hosted Apple dan recurring operations lokal

- Public Auth settings hosted membuktikan Apple dan Google aktif, Email
  provider nonaktif, serta signup global tetap aktif. Nilai private key,
  client secret, token encryption key, dan credential lain tidak dibaca atau
  dicetak dalam verifikasi.
- Menambahkan migration ke-19 untuk tiga recurring Edge worker: orphan media
  cleanup harian, Apple identity reconciliation tiap 15 menit, dan Apple
  commerce reconciliation tiap 15 menit dengan offset terpisah.
- Cron command tidak memuat URL, API key, Authorization, atau nama Vault
  secret. Dispatcher private mengambil hosted URL dan modern secret key dari
  Supabase Vault saat runtime, mengirim key hanya melalui header `apikey`,
  membatasi worker dengan allowlist, dan gagal tertutup bila konfigurasi Vault
  hilang/tidak valid.
- Orphan cleanup sekarang menerima dua caller yang diaudit: Admin dengan
  session user atau scheduler dengan exact modern secret key. Participant
  tetap ditolak dan penghapusan object tetap melalui Storage API.
- `supabase db reset --local` berhasil menerapkan 19 migration. Seluruh 399
  assertion pgTAP dan integration orphan cleanup 4/4 lulus; lint
  `public,private` bersih dan schema diff lokal kosong.
- Migration/function update serta tiga schedule baru belum dideploy ke hosted
  `main`. Provision dua Vault secret dan deployment production tetap menunggu
  approval mutation terpisah.

### 9 Agustus 2026 — Recurring operations hosted dan forward fix

- Owner memprovision dua Vault input lalu memberi approval untuk migration
  ke-19, redeploy cleanup dengan `no-verify-jwt`, dan aktivasi tiga cron.
  Dry-run memuat tepat satu migration; push berhasil dan cleanup aktif sebagai
  versi 3 dengan `verify_jwt=false`.
- Read-only SQL membuktikan ketiga cron aktif, command tidak memuat credential,
  dan kedua Vault value mempunyai bentuk yang benar tanpa mengembalikan
  nilainya.
- Run pertama identity reconciliation gagal tertutup sebelum HTTP dispatch.
  Audit menemukan doubled backslash pada regex URL migration ke-19, bukan
  kesalahan nilai Vault atau secret leak.
- Menambahkan forward-fix migration ke-20 tanpa mengubah migration production
  yang sudah diterapkan. Test kini mencakup valid hosted URL/modern secret;
  seluruh 400 pgTAP assertion, lint, schema diff, dan OpenAPI parse lulus.
  Forward fix berhasil dideploy; run identity reconciliation berikutnya
  mencapai Edge Function dengan respons `200` tanpa timeout. Run commerce
  berikutnya juga berhasil dispatch dan gagal tertutup dengan
  `commerce_environment_missing`, sesuai credential App Store Server yang
  belum dipasang. Cron cleanup aktif dan menunggu run alami 03:12 UTC.
- Public legal Edge endpoint untuk Privacy Policy dan Terms lulus integration
  lokal 16/16 termasuk GET/HEAD, Bahasa Indonesia, security headers, 404, dan
  405. Function kesembilan kemudian dideploy dengan `verify_jwt=false`;
  kedua endpoint hosted mengembalikan `200` dan URL final dipasang pada
  konfigurasi Release.
- Build Release device terbaru setelah pemasangan URL legal berhasil dibangun,
  dipasang, dan diluncurkan pada iPhone fisik dengan bundle identifier final.
- Read-only operational audit membuktikan enam physical backup harian terakhir
  `COMPLETED`, WAL-G aktif, PITR nonaktif, SSL database aktif, dan network
  restriction masih terbuka pada IPv4/IPv6. Dashboard Project Overview
  menampilkan tidak ada Security/Performance Advisor issue.
- Menambahkan backup/forward-fix runbook yang merekam attended change window
  dan failure drill migration 19 → forward fix migration 20, serta hosted
  security posture tanpa credential.
- Menambahkan handoff manual App Store Connect dengan tiga Product ID Coach
  final, konvensi Product ID paid cohort, Notification V2 URL, sandbox tester,
  In-App Purchase key, dan daftar secret backend. Tidak ada secret yang
  ditulis ke repository.
- Regresi autentikasi Phase 10 lulus 17/17 pada simulator iOS 26.5. StoreKitTest
  pada runtime iOS 26.5 mengembalikan `SKInternalErrorDomain Code=3`, lalu suite
  commerce yang sama lulus 6/6 pada simulator bersih iOS 18.6. Ini
  mengonfirmasi konfigurasi produk lokal, urutan verifikasi sebelum finish,
  recovery transaksi, Ask to Buy, refund entitlement, dan kontrak Supabase.
  Perintah verifikasi: `xcodebuild -project MSCBodyTransformation.xcodeproj
  -scheme MSCBodyTransformation -configuration Debug -destination
  'platform=iOS Simulator,id=8246A128-74B4-4084-A17D-182A6BB0829F'
  -derivedDataPath /private/tmp/msc-phase13-storekit18 test
  -only-testing:MSCBodyTransformationTests/Phase12StoreKitCommerceTests`.

### 9 Agustus 2026 — Gate source-only dan preflight lokal

- Menambahkan Release fail-closed config, legal fallback, privacy manifest,
  camera copy, pemisahan demo assets, dan pembersihan seluruh fixture dari
  bundle Release; video fixture terakhir juga dikeluarkan.
- Menambahkan Sign in with Apple identity lifecycle/account-events, token
  revocation dengan durable retry, dan App Store Server API reconciliation
  memakai official library `3.1.0` yang dipin.
- Rekonsiliasi OpenAPI selesai; request Swift lifecycle memakai kontrak
  `authorization_code` dan mempunyai request-level test.
- Reset Supabase lokal berhasil: 18 migration, 385 assertion pgTAP, dan 151
  integration checks lulus. Lint database bersih dan schema diff kosong.
- Audit lokal membuktikan seluruh tabel `public` memakai RLS, klien tidak
  mempunyai grant ke tabel `private`, seluruh `SECURITY DEFINER` mempunyai
  fixed `search_path`, dan RPC commerce reconciliation hanya untuk
  `service_role`.
- Focused Phase 10 authentication tests lulus 17/17. Release simulator clean
  build dan built-app validation lulus; artifact tidak memuat fixture,
  StoreKit config, secret pattern, local endpoint, atau test-user PII.
- Focused native media tests lulus 11/11, termasuk metadata GPS stripping dan
  temporary-file cleanup. Private Storage integration membuktikan owner,
  assigned Coach, Admin, unrelated user, upload/upsert, dan signed URL 60 detik.
- Hosted URL/key dan legal URL sengaja masih kosong sehingga Release gagal
  tertutup. Tidak ada hosted mutation karena approval production belum
  diberikan.

### 9 Agustus 2026 — Hosted read-only preflight dan modern API keys

- CLI berhasil dilink ke hosted `main` yang dikonfirmasi owner hanya untuk
  preflight read-only. Project aktif/sehat, migration history masih kosong,
  dan dry-run menunjukkan tepat 18 migration lokal akan diterapkan.
- Backup fisik harian terakhir berstatus selesai; PITR belum aktif. Remote
  lint schema `public`/`private` bersih, Functions dan project secrets masih
  kosong.
- Preflight menemukan database SSL enforcement belum aktif dan koneksi
  database langsung masih terbuka untuk IPv4/IPv6; keduanya tetap gate
  production yang belum dimutasi.
- Legacy `anon`/`service_role` sempat tampil pada output CLI dan wajib dianggap
  terekspos. Nilainya tidak dipakai atau dicatat dalam dokumen. JWKS publik
  sudah membuktikan asymmetric signing ES256 aktif. Owner mengonfirmasi legacy
  API keys sudah dinonaktifkan dan legacy signing key sudah direvoke.
- Edge Functions dipindahkan ke publishable/secret key modern dengan fallback
  legacy hanya untuk Supabase lokal. JWT diverifikasi manual terhadap Auth,
  service requests memakai secret header, request body dibatasi, dan upstream
  fetch memiliki timeout.
- Reset lokal bersih, seluruh delapan Edge Functions berhasil dimuat, commerce
  lulus 31 assertion, orphan cleanup lulus 3 pemeriksaan, pgTAP lulus 385 tes,
  Auth lifecycle/immediate deletion lulus 22 pemeriksaan, lint bersih, dan
  schema diff kosong.
- Verifikasi read-only setelah tindakan owner membuktikan JWKS asymmetric ES256
  tetap aktif. CLI masih menampilkan metadata nama legacy keys tetapi tidak
  menyediakan field status enabled/disabled; state disable/revoke dibuktikan
  oleh konfirmasi Dashboard owner.
- Owner mengizinkan hosted deployment dan SSL. Tepat 18 migration berhasil
  dipush tanpa reset/seed, remote migration history cocok penuh dengan lokal,
  remote database lint bersih, dan SSL enforcement terverifikasi aktif.
- Deployment delapan Functions belum terjadi. Approval keamanan menahan
  `--no-verify-jwt`; flag ini diperlukan oleh publishable/secret API keys modern
  dan endpoint mengautentikasi user/service/signature di dalam handler.
- Setelah approval khusus owner, seluruh delapan Functions berhasil dideploy
  sebagai versi 1, berstatus `ACTIVE`, dan terverifikasi `verify_jwt=false`.
  Smoke tanpa credential membuktikan user endpoints menolak `401`, webhook
  menolak payload invalid, dan endpoint yang belum memiliki Apple/commerce
  config gagal tertutup dengan sanitized configuration error.

### 9 Agustus 2026 — Workplan dipisah

- Memindahkan source hardening, hosted deployment, hosted OAuth, StoreKit/App
  Store Connect sandbox, security, dan physical-device testing ke Phase 13.1.
- Menetapkan gate eksplisit bahwa archive/upload baru boleh dilakukan pada
  Phase 13.2 setelah owner selesai menguji aplikasi sendiri.

### 9 Agustus 2026 — App Icon production dan Icon Composer

- Memasang App Icon final default/dark/tinted 1024×1024 tanpa alpha.
- Menyimpan source, preview ukuran kecil, separated layers, dan dokumen native
  Icon Composer di `Design/AppIcon`.
- Generator typecheck, Debug build/run, Home Screen check, dan Release
  simulator build lulus.

### 8 Agustus 2026 — Audit dan handoff Phase 12

- Phase 12 local commerce/OpenAPI/backend verification diterima sebagai
  baseline; hosted main, sandbox, dan perangkat fisik tetap external gate.
- Audit menemukan privacy/legal/Release config, hosted lifecycle, recurring
  operations, dan real Apple reconciliation sebagai blocker Phase 13.1.
- SMTP/domain/email-password tetap skipped.
