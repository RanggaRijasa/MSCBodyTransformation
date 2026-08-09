# Phase 13.1: Release Hardening, Hosted Main, Sandbox, and Physical Testing

> Status: **siap dimulai untuk source-only hardening; mutation hosted `main`
> dan App Store Connect tetap memerlukan persetujuan eksplisit tepat sebelum
> tindakan tersebut dijalankan**.
>
> Phase ini sengaja berhenti sebelum archive/upload. Tujuannya adalah memberi
> owner kesempatan memakai dan menguji aplikasi secara langsung terhadap
> backend production sebelum build didistribusikan melalui TestFlight.

## Tujuan

Menghasilkan aplikasi Release yang dapat diuji sendiri dan pada iPhone fisik:

- bundle, App Icon, privacy manifest, legal content, dan konfigurasi Release
  sudah layak production;
- hosted Supabase `main` telah dideploy dengan security boundary yang benar;
- Google dan Apple OAuth hosted berfungsi;
- StoreKit/App Store Connect sandbox serta Apple server integration berfungsi;
- lifecycle akun, commerce, authorization, retention, dan recurring jobs
  server-authoritative;
- critical sandbox dan physical-device journey lulus;
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
- [ ] Sediakan teks final Privacy Policy, Terms, wellness disclaimer,
  retention, account deletion, Coach payment/expiry, serta contest rules bila
  leaderboard memberi hadiah.
- [ ] Sediakan URL HTTPS publik Privacy Policy dan Terms of Use.

### Hosted Supabase `main`

- [ ] Konfirmasi project ref hosted `main`, organization, dan region.
- [ ] Sediakan hosted URL dan publishable key untuk Release.
- [ ] Sediakan akses Dashboard/CLI yang berhak deploy tanpa membagikan database
  password atau service-role key di chat.
- [ ] Konfirmasi backup/rollback plan dan maintenance window.
- [ ] Berikan persetujuan production eksplisit yang menyebut hosted `main`.

### App Store Connect dan sandbox

- [ ] Accept Paid Apps Agreement dan lengkapi tax/banking.
- [ ] Catat numeric `appAppleId`.
- [ ] Buat satu non-consumable untuk setiap cohort berbayar.
- [ ] Buat tiga non-renewing subscription Coach tiga bulan.
- [ ] Lengkapi display name/description Bahasa Indonesia, price, availability,
  dan tax category minimum agar product dapat diuji. Review screenshot serta
  final submission association diselesaikan pada Phase 13.3.
- [ ] Buat In-App Purchase/App Store Connect key bila Server API
  reconciliation membutuhkannya; `.p8`, issuer ID, dan key ID server-only.
- [ ] Siapkan Sandbox Apple Account.

### Physical-device gate

- [ ] Sediakan iPhone fisik iOS 17+; iPad fisik sangat disarankan.
- [ ] Sediakan test account Google, Apple/private relay, Participant, Coach,
  dan Admin tanpa data pribadi nyata.
- [ ] Sediakan QR Coach aktif untuk enrollment.

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

- [ ] Pastikan working tree tidak mempunyai perubahan yang tidak dipahami.
- [ ] Catat exact Phase 12 verification baseline.
- [ ] Audit dependency/license dan pin official Apple server library yang
  sudah disetujui; jangan menambah dependency tanpa approval.
- [ ] Rekonsiliasi OpenAPI, migration, Edge routes, Swift DTO, dan error map
  setelah source-only changes.
- [ ] Inventarisasi public client config, server non-secret config, server
  secret, dan local-only values.
- [ ] Buktikan tidak ada secret, local key, private URL, atau test-user PII di
  material yang akan masuk Release.

**Gate 13.1.0:** baseline dan external inputs terdokumentasi; belum ada
mutation hosted.

### Slice 13.1.1 — Bundle, privacy manifest, legal, dan Release config

- [x] Tambahkan App Icon production default, dark, dan tinted; periksa alpha
  dan rendering ukuran kecil.
- [ ] Perbaiki `NSCameraUsageDescription` menjadi QR Coach dan foto bukti.
- [ ] Audit photo-library purpose string berdasarkan API yang benar-benar
  dipakai; jangan menambahkan permission yang tidak diperlukan.
- [ ] Ganti legal placeholder Participant/Coach dengan content production dan
  fallback bila URL gagal.
- [ ] Isi `PrivacyInfo.xcprivacy` berdasarkan data nyata: nama, email, nomor HP,
  user ID, foto/user content, berat/fitness, purchase history, dan diagnostics.
- [ ] Pertahankan `NSPrivacyTracking=false` bila memang tidak ada tracking.
- [ ] Audit required-reason APIs dan deklarasikan hanya reason code resmi yang
  benar-benar relevan.
- [ ] Buat konfigurasi Release non-secret untuk hosted URL dan publishable key;
  jangan bergantung pada Xcode Run scheme environment.
- [ ] Release fail closed bila config kosong, bukan HTTPS, loopback, `.local`,
  atau LAN address.
- [ ] Pastikan service-role/secret key, Apple `.p8`, OAuth secret, local key,
  `Products.storekit`, Debug selector, dan demo fixture tidak masuk Release.
- [ ] Finalkan version/build number, launch experience, device families, dan
  orientation iPhone/iPad.
- [ ] Jalankan Release build dan inspect built `.app` secara lokal. Archive dan
  upload secara sengaja ditunda ke Phase 13.2.

**Gate 13.1.1:** Release build lokal tidak mempunyai placeholder, invalid
config, local dependency, secret, atau privacy/bundle blocker.

### Slice 13.1.2 — Hosted Auth dan account lifecycle

- [ ] Rekonsiliasi callback scheme dan hosted redirect allowlist.
- [ ] Konfigurasi Google provider hosted dengan production client ID/secret.
- [ ] Konfigurasi Apple provider/App ID hosted; credential hanya server-side.
- [ ] Pastikan email/password UI dan hosted signup tetap tidak menjadi jalur
  production yang tidak diuji.
- [ ] Uji Google login/logout/relogin, force-close restore, expired session,
  refresh, cancel, provider error, dan account switch.
- [ ] Uji Apple login/logout/relogin, private relay, first-login name-only,
  revoked/not-found credential, restore, dan account switch.
- [ ] Jangan merge Google dan Apple hanya karena email sama.
- [ ] Tambahkan endpoint Sign in with Apple account events, terpisah dari App
  Store Server Notifications commerce.
- [ ] Verifikasi signature/payload, idempotency, audit minimum, forwarding
  change, dan Apple account deletion event.
- [ ] Revoke Apple token sebagai bagian deletion workflow dengan durable retry.
- [ ] Verifikasi deletion menghapus identity/private data/media dan
  menganonimkan record yang wajib dipertahankan.
- [ ] Coach dengan participant aktif tetap diblok sampai Admin transfer.

**Gate 13.1.2:** hosted OAuth dan account lifecycle lulus tanpa provider secret
di client.

### Slice 13.1.3 — Hosted security preflight

- [ ] Verifikasi Supabase CLI dan flags melalui `--help` pada hari deployment.
- [ ] Verifikasi project ref, organization, DB version, migration history,
  extension, dan hosted schema.
- [ ] Buat backup/snapshot dan forward-fix/rollback runbook.
- [ ] Review migration; larang seed, local product IDs, test account, dan
  destructive production rewrite.
- [ ] Review exposed schemas, grants, RLS, Storage policies, public views,
  `anon`, dan `authenticated`.
- [ ] Review seluruh `security definer`, fixed `search_path`, revoked PUBLIC,
  allowlist, authorization, dan audit.
- [ ] Pastikan authorization tidak membaca editable metadata/client role.
- [ ] Audit Guest projection terhadap PII, weight, private media, raw QR,
  phone, answer, dan unpublished content leakage.
- [ ] Audit Edge Function JWT, secret boundary, body limit, timeout,
  idempotency, replay, rate limiting, cache, dan sanitized errors.
- [ ] Review Security/Performance Advisor, SSL, MFA, rate limit/CAPTCHA,
  network restriction, backup, Storage limit, dan spend alert.
- [ ] Catat SMTP sebagai intentional skip.

**Gate 13.1.3:** reviewed diff dan security report tersedia; minta approval
production sebelum deployment.

### Slice 13.1.4 — Deploy hosted `main` dan recurring operations

- [ ] Setelah approval, link hanya ke hosted `main` yang dikonfirmasi.
- [ ] Bandingkan migration history lalu push migration berurutan; jangan reset,
  seed, atau dashboard-edit schema.
- [ ] Provision product mapping production secara idempoten.
- [ ] Deploy `delete-account`, orphan cleanup, `commerce`, Apple commerce
  notifications, Apple account-events, dan reconciliation worker.
- [ ] Set Edge secrets melalui approved mechanism tanpa mencetak nilainya.
- [ ] Jadwalkan provisional identity cleanup, commerce reservation/entitlement
  expiry, orphan media cleanup, dan missed-event reconciliation.
- [ ] Jangan taruh service key di URL/query scheduled job.
- [ ] Jalankan hosted migration list, schema diff, lint, advisors, grants,
  RLS/Storage/Auth smoke, function health, cron status, dan redaction scan.
- [ ] Jalankan non-destructive rollback/failure drill.

**Gate 13.1.4:** hosted smoke lulus, jobs observable, tidak ada secret leak,
dan Release hanya memakai hosted URL + publishable key.

### Slice 13.1.5 — StoreKit/App Store Connect dan Apple server integration

- [ ] Pastikan app record memakai bundle ID final.
- [ ] Pastikan agreement, banking, tax, category, pricing, dan availability
  minimum untuk sandbox/product testing valid.
- [ ] Finalkan non-consumable per paid cohort dan tiga Coach products; product
  ID/type harus sama dengan mapping server.
- [ ] Harga/currency UI harus berasal dari StoreKit.
- [ ] Implementasikan Server API reconciliation dengan official library dan
  server-only credential; tangani environment, pagination, retry, dan limit.
- [ ] Konfigurasi Notification V2 HTTPS endpoint.
- [ ] Kirim Request a Test Notification; verifikasi 2xx, signature, durable
  inbox tunggal, processed state, dan retry.
- [ ] Uji duplicate, out-of-order, delayed, invalid signature, wrong app/product
  environment, refund, revoke, dan recovery setelah outage.
- [ ] Uji sandbox purchase, pending/interrupted, unfinished relaunch, restore,
  cross-device restore, refund/revocation, dan Coach renewal.

**Gate 13.1.5:** products dapat dimuat, fulfillment server-authoritative, TEST
notification processed, dan reconciliation memulihkan event hilang.

### Slice 13.1.6 — Privacy, retention, security, dan abuse

- [ ] Finalkan Privacy Policy, Terms, wellness disclaimer, retention, account
  deletion, Coach payment/expiry/no-voluntary-refund terms, dan contest rules.
- [ ] Pastikan privacy policy dan manifest konsisten dengan behavior. App Store
  privacy questionnaire diselesaikan pada Phase 13.3.
- [ ] Verifikasi photo metadata stripping, private paths, short signed URLs,
  cache, dan temporary-file cleanup.
- [ ] Verifikasi log tidak berisi password, token, service key, raw QR, weight,
  private URL/path, signed Apple payload, atau purchase credential.
- [ ] Jalankan horizontal-access, escalation, forged metadata, replay,
  duplicate fulfillment, forged webhook, rate/capacity/cutoff race matrix.
- [ ] Uji deletion/retention Participant, Coach, Admin restriction, winner,
  commerce/audit anonymization, dan private relay.
- [ ] Dokumentasikan incident response, secret rotation, webhook outage,
  compromised tester, dan production rollback.

**Gate 13.1.6:** tidak ada critical/high privacy atau security blocker.

### Slice 13.1.7 — Sandbox dan physical-device matrix

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

**Gate 13.1.7:** critical sandbox dan physical-device journeys lulus tanpa
crash, leak, accessibility blocker, atau unrecoverable transaction.

## Acceptance minimum sebelum Phase 13.2

### Guest dan Auth

- [ ] Guest membuka tab publik tanpa Auth identity/private data.
- [ ] `Gabung program` menuju Login dan resume program yang benar.
- [ ] Google dan Apple register/login/logout/relogin/restore/cancel/error.
- [ ] Apple private relay dan first-name-only berfungsi.
- [ ] Google dan Apple identity tetap terpisah.
- [ ] Email/password/reset tidak tampil dan **SKIPPED BY PRODUCT**.

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

## Exit criteria Phase 13.1

- [ ] Seluruh Gate 13.1.0–13.1.7 lulus atau mempunyai accepted exception.
- [ ] Release build memakai bundle ID final, iOS 17+, final icon/legal/privacy,
  hosted HTTPS config, dan tidak membawa local/debug/secrets.
- [ ] Hosted migrations/functions/jobs/Auth/security lulus.
- [ ] Products, Notification V2, Server API reconciliation, sandbox,
  restore/refund/revocation lulus.
- [ ] Google/Apple lifecycle termasuk Apple revoke/account events lulus.
- [ ] Owner menyelesaikan exploratory test pada iPhone fisik dan menyetujui
  lanjut ke Phase 13.2.
- [ ] Belum ada archive/upload/TestFlight mutation.

## Referensi

- Apple IAP: https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/overview-for-configuring-in-app-purchases
- App Store Server Notifications V2: https://developer.apple.com/documentation/AppStoreServerNotifications/enabling-app-store-server-notifications
- App Store Server API: https://developer.apple.com/documentation/appstoreserverapi
- Privacy manifest: https://developer.apple.com/documentation/bundleresources/privacy-manifest-files
- Account deletion/token revoke: https://developer.apple.com/support/offering-account-deletion-in-your-app/
- Supabase production: https://supabase.com/docs/guides/deployment/going-into-prod
- Supabase migrations: https://supabase.com/docs/guides/deployment/database-migrations
- Supabase Edge deploy: https://supabase.com/docs/guides/functions/deploy

## Progress log

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
