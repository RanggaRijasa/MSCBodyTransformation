# Phase 13: Production Hardening, Hosted Deployment, and TestFlight

> Status: **siap dimulai untuk source-only hardening; belum diotorisasi untuk
> mutation hosted `main` atau App Store Connect**.
>
> Audit 8 Agustus 2026 merekonsiliasi file ini terhadap source setelah Phase
> 12. Phase 12 lokal sudah lulus. Phase 13 bukan sekadar deployment: masih ada
> release blocker di bundle, legal/privacy UI, konfigurasi Release, lifecycle
> Sign in with Apple, recurring server jobs, dan real App Store reconciliation.

## Tujuan

Menghasilkan release candidate iOS/iPadOS yang:

- memakai hosted Supabase `main` tanpa credential server di app;
- mempertahankan authorization, commerce, dan scoring sebagai aturan server;
- memenuhi account lifecycle Google dan Sign in with Apple;
- memproses StoreKit, App Store Server Notifications V2, serta reconciliation
  Apple secara durable dan idempoten;
- mempunyai deklarasi privasi, legal copy, App Store metadata, dan aset final;
- lulus security, accessibility, reliability, iPhone fisik, dan TestFlight.

## Keputusan produk dan teknis yang sudah final

- Bundle identifier: `com.ranggar.MSCBodyTransformation`.
- Minimum deployment target: iOS 17.
- Development memakai Supabase lokal; production memakai hosted Supabase
  `main`; tidak ada Supabase branch atau hosted staging.
- Login production hanya Google dan Apple. Email/password, SMTP, serta custom
  mail domain tetap **SKIPPED** sampai keputusan produk berubah.
- Akun Google dan Apple yang berbeda tetap menjadi identity/account terpisah;
  Phase 13 tidak melakukan automatic account linking.
- Program gratis tidak memakai StoreKit.
- Setiap cohort program berbayar memakai satu non-consumable production yang
  unik. Participant maupun Coach boleh membelinya untuk mengikuti program.
- Akses fitur Coach tiga bulan memakai tiga non-renewing subscription terpisah
  untuk price band entry, growth, dan leadership.
- Pengajuan Coach awal: Admin menerima dahulu, lalu applicant membayar, lalu
  entitlement aktif tiga bulan. Renewal manual tidak memerlukan acceptance
  ulang selama approval belum dicabut.
- Tidak ada refund sukarela. Refund/revocation yang diberikan Apple tetap
  authoritative dan mencabut akses terkait.
- Reservation kapasitas berlangsung 30 menit. Transaksi Apple sah yang tiba
  terlambat tetap diterima sebagai rare audited over-capacity.
- Participant mendaftar melalui QR Coach aktif. Tidak ada invite code, input
  kode manual, atau fallback typed code.
- Custom web/mail domain tidak diperlukan untuk Phase 13. Privacy policy dan
  terms tetap membutuhkan URL HTTPS publik, tetapi boleh memakai hosting yang
  tidak menggunakan custom domain.

## Hasil audit repository sebelum implementasi

| Area | Kondisi saat audit | Tindakan Phase 13 |
|---|---|---|
| Phase 12 lokal | 17 migrations, 348 pgTAP assertions, 151 integration checks, 190 Swift/StoreKit tests, UI/build/lint/advisors/schema diff lulus | Jangan mengulang desain commerce; gunakan sebagai baseline |
| App Icon | Default, dark, dan tinted 1024×1024 tanpa alpha sudah dipasang; source, layer terpisah, dan dokumen native Icon Composer tersedia | Pertahankan aset final dan validasi ulang saat archive |
| Privacy manifest | `PrivacyInfo.xcprivacy` ada tetapi seluruh array kosong | Audit API dan isi data collection/tracking declarations yang benar |
| Legal UI | Privasi dan Ketentuan masih `ContentUnavailableView` dengan copy placeholder | Ganti dengan dokumen/URL production yang dapat dibuka |
| Camera purpose | Masih menyebut “QR undangan program” | Ubah menjadi QR Coach dan foto bukti |
| Release backend config | `AppConfiguration` hanya membaca process environment | Buat konfigurasi non-secret yang benar-benar masuk ke archive/TestFlight |
| StoreKit config | `Products.storekit` sudah dikecualikan dari Release | Pertahankan dan buktikan melalui archive scan |
| Product mapping | Migration hanya seed product environment `xcode` | Tambahkan provisioning production yang audited dan idempoten setelah product ID final |
| App Store verification | Signed JWS/Notification V2 lokal selesai; Server API recovery nyata belum tersedia | Tambahkan real reconciliation dan missed-notification recovery |
| Notification endpoint | Handler public lokal sudah durable; hosted URL belum ada | Deploy, kirim TEST notification, periksa inbox processed |
| Apple account deletion | Supabase identity/data dihapus, tetapi Apple token revocation belum terbukti | Implementasikan dan uji revocation sebelum final deletion |
| Apple account events | Belum ada endpoint Sign in with Apple server-to-server | Tambahkan endpoint terpisah dari App Store commerce webhook |
| Recurring operations | Provisional cleanup terjadwal; commerce expiry/reconciliation dan orphan cleanup belum terbukti terjadwal hosted | Tambahkan schedule, observability, dan retry |
| App Store/legal metadata | Belum dibuat/diverifikasi | Lengkapi App Store Connect, privacy responses, review notes, dan contest rules |

Temuan di atas adalah blocker nyata, bukan item kosmetik. Phase 13 tidak boleh
langsung melompat ke `supabase db push` atau upload TestFlight.

## Scope dan batasan

### Termasuk Phase 13

- source-only release hardening;
- migration/Edge Function tambahan yang diperlukan untuk production lifecycle;
- hosted Supabase security preflight dan deployment setelah approval;
- Google/Apple Auth hosted configuration;
- App Store Connect product provisioning dan Apple server integration;
- sandbox, physical-device, TestFlight, dan App Review preparation.

### Tidak termasuk

- SMTP, custom mail domain, email signup/reset/password;
- Android/Google Play Billing, yang tetap Phase 14;
- analytics/advertising SDK baru;
- Supabase staging/preview branch;
- perubahan produk atau UI besar di luar release blocker;
- automatic Google/Apple account linking.

## Input manual dan kapan dibutuhkan

Nilai rahasia tidak boleh dikirim lewat chat, ditaruh di source, Xcode scheme
shared, committed `.env`, screenshot, fixture, atau log.

### Sebelum Slice 13.1 selesai

- [x] Sediakan artwork App Icon final 1024×1024 atau setujui pembuatan aset.
- [ ] Sediakan teks final privacy policy, terms, wellness disclaimer, retention,
  account deletion, Coach payment/expiry, serta contest rules bila ada hadiah.
- [ ] Sediakan URL HTTPS publik Privacy Policy dan Terms of Use. Custom domain
  tidak diwajibkan.
- [ ] Konfirmasi nama aplikasi, subtitle, kategori, age rating, support URL,
  marketing URL bila dipakai, dan contact App Review.

### Sebelum Slice 13.4 hosted mutation

- [ ] Konfirmasi project ref hosted `main`, organization, dan region.
- [ ] Sediakan hosted URL dan publishable key untuk konfigurasi Release.
- [ ] Sediakan akses Dashboard/CLI yang berhak deploy tanpa membagikan database
  password atau service-role key di chat.
- [ ] Konfirmasi backup/rollback plan dan maintenance window.
- [ ] Berikan persetujuan production eksplisit yang menyebut hosted `main`.

### Sebelum Slice 13.5 commerce production

- [ ] Accept Paid Apps Agreement dan lengkapi tax/banking di App Store Connect.
- [ ] Catat numeric `appAppleId`.
- [ ] Buat satu non-consumable untuk setiap cohort program berbayar.
- [ ] Buat tiga non-renewing subscription Coach tiga bulan.
- [ ] Lengkapi Bahasa Indonesia display name/description, price, availability,
  tax category, review screenshot, dan review notes setiap produk.
- [ ] Buat In-App Purchase/App Store Connect key bila reconciliation Server API
  membutuhkannya: Issuer ID, Key ID, dan private `.p8` disimpan server-only.
- [ ] Siapkan Sandbox Apple Account dan internal TestFlight tester.

### Sebelum final physical-device gate

- [ ] Sediakan iPhone fisik iOS 17+; iPad fisik sangat disarankan.
- [ ] Sediakan test account Google, test Apple ID/private relay, Participant,
  Coach, dan Admin yang tidak memakai data pribadi nyata.
- [ ] Sediakan QR Coach aktif untuk enrollment dan App Review.

## Approval boundary production

Source, tests, local migrations, dan local Edge Function dapat dikerjakan tanpa
menyentuh production. Semua tindakan berikut memerlukan persetujuan production
eksplisit tepat sebelum dijalankan:

- `supabase link` ke hosted `main` jika belum tertaut;
- `supabase db push` atau SQL apa pun ke hosted;
- Edge Function deploy atau hosted secret mutation;
- hosted Auth provider/configuration mutation;
- cron/schedule hosted, Storage policy, network restriction, atau project
  setting mutation;
- App Store Connect product, notification URL, TestFlight, atau submission
  mutation.

Persetujuan `supabase db reset --local` sebelumnya tidak mengizinkan operasi
hosted. `seed.sql` dan data development tidak pernah dipush ke production.

## Urutan implementasi

### Slice 13.0 — Freeze baseline dan production inventory

- [ ] Pastikan working tree tidak mempunyai perubahan yang tidak dipahami.
- [ ] Catat exact local Phase 12 verification baseline tanpa mengubah hasilnya.
- [ ] Audit dependency/license dan pin official Apple server library yang sudah
  dipakai; jangan menambah package baru tanpa approval.
- [ ] Rekonsiliasi `Contracts/program-api-v1.openapi.yaml`, migration, Edge
  routes, Swift DTO, dan error mapping setelah source-only Phase 13 changes.
- [ ] Inventarisasi semua environment value menjadi:
  - public client config: hosted URL dan publishable key;
  - server non-secret config: appAppleId, bundle ID, environment, product IDs;
  - server secret: service/secret key, Apple `.p8`, issuer/key ID;
  - local-only: loopback URL, local publishable key, Xcode product IDs.
- [ ] Buktikan tidak ada secret, local key, private URL, atau test user PII di
  Git history yang akan dikirim dalam archive/repository release.

**Gate 13.0:** baseline terdokumentasi, external inputs teridentifikasi, dan
tidak ada mutation hosted.

### Slice 13.1 — Bundle, privacy, legal, dan Release configuration

- [x] Tambahkan App Icon production untuk default, dark, dan tinted appearance;
  periksa alpha/transparency dan rendering ukuran kecil.
- [ ] Perbaiki `NSCameraUsageDescription` menjadi QR Coach dan foto bukti.
- [ ] Audit kebutuhan photo-library purpose string. `PhotosPicker` tidak boleh
  diberi permission string yang tidak diperlukan, tetapi camera/photo save API
  yang benar-benar dipakai harus mempunyai purpose string yang tepat.
- [ ] Ganti legal placeholder Participant/Coach dengan privacy policy dan terms
  production yang konsisten dan dapat dibuka; sediakan fallback bila URL gagal.
- [ ] Isi `PrivacyInfo.xcprivacy` berdasarkan data nyata, sekurang-kurangnya
  audit nama, email, nomor HP, user ID, foto/user content, data berat/fitness,
  purchase history, dan diagnostics yang benar-benar dikumpulkan.
- [ ] Pertahankan `NSPrivacyTracking=false`; jangan mendeklarasikan data untuk
  tracking bila tidak ada tracking.
- [ ] Audit required-reason APIs dari source dan dependencies; deklarasikan
  hanya API yang benar-benar dipakai beserta reason code resmi.
- [ ] Buat konfigurasi Release non-secret yang masuk ke built app/archive untuk
  hosted URL dan publishable key. Release tidak boleh bergantung pada Xcode Run
  scheme environment variable.
- [ ] Release harus fail closed bila URL kosong, bukan HTTPS, loopback, `.local`,
  atau LAN address.
- [ ] Pastikan service-role/secret key, Apple private key, OAuth client secret,
  local publishable key, `Products.storekit`, Debug role/scenario selector, dan
  demo fixture tidak masuk archive.
- [ ] Finalkan version/build number, launch experience, device families, dan
  orientation behavior iPhone/iPad.
- [ ] Jalankan archive dan inspect exported `.app`: Info.plist, entitlements,
  privacy manifest, icon, embedded resources, minimum OS, bundle ID, dan
  signature.

**Gate 13.1:** archive Release dapat dibuat tanpa scheme-only environment,
tidak mempunyai placeholder/dead link, dan lulus privacy/archive scan.

### Slice 13.2 — Auth production dan account lifecycle

- [ ] Rekonsiliasi callback scheme app dan hosted redirect allowlist; allowlist
  hanya memuat callback yang benar-benar digunakan.
- [ ] Konfigurasi hosted Google provider dengan production client ID/secret dan
  callback hosted yang tepat.
- [ ] Konfigurasi hosted Apple provider/App ID; private credential hanya hosted.
- [ ] Pastikan email/password UI tetap tersembunyi dan hosted email signup tidak
  menjadi jalur registration yang tidak diuji.
- [ ] Uji Google login/logout/login ulang, force-close restore, expired session,
  refresh rotation, cancel, provider error, dan account switch.
- [ ] Uji Apple login/logout/login ulang, private relay, first-login name only,
  credential state revoked/not found, force-close restore, dan account switch.
- [ ] Jangan merge akun Google dan Apple hanya karena email sama.
- [ ] Tambahkan Sign in with Apple server-to-server endpoint khusus account
  events. Endpoint ini berbeda dari App Store Server Notifications commerce.
- [ ] Verifikasi signature/payload Apple account event, proses idempoten, simpan
  audit minimum, dan tangani email forwarding change serta Apple account delete.
- [ ] Saat user menghapus akun yang terhubung Apple, revoke token Apple sesuai
  flow resmi sebelum/dalam deletion workflow. Kegagalan network tidak boleh
  menghasilkan state ambigu tanpa durable retry/audit.
- [ ] Pastikan account deletion Google/Apple menghapus identity dan private
  media/data app, menganonimkan winner/audit/commerce yang wajib dipertahankan,
  serta tidak menghapus immutable purchase ledger yang diperlukan.
- [ ] Uji Coach dengan participant aktif tetap diblok sampai Admin transfer.

**Gate 13.2:** hosted-compatible Auth source dan account deletion lifecycle
lulus lokal/signed fixtures; provider secret tidak ada di client.

### Slice 13.3 — Hosted Supabase security preflight

- [ ] Verifikasi Supabase CLI version dan command flags melalui `--help` tepat
  sebelum deployment; jangan mengandalkan contoh lama secara buta.
- [ ] Verifikasi target project ref, organization, database version, migration
  history, extension availability, dan current hosted schema.
- [ ] Buat pre-deployment backup/snapshot sesuai plan yang tersedia dan tulis
  forward-fix/rollback runbook; jangan memakai destructive reset hosted.
- [ ] Review seluruh migration berurutan. Tidak boleh ada local seed, local
  product IDs, test account, atau destructive production data rewrite.
- [ ] Review Data API exposed schemas, explicit table/function grants, RLS,
  Storage policies, public views `security_invoker`, dan role `anon` versus
  `authenticated`.
- [ ] Review seluruh `security definer`: fixed `search_path`, revoked PUBLIC,
  explicit allowlist, caller authorization, dan audit.
- [ ] Pastikan authorization tidak membaca editable `user_metadata`, member
  level, atau client-claimed role.
- [ ] Review Guest public projections untuk PII, private media, raw Coach QR,
  phone, weight, answer, dan unpublished content leakage.
- [ ] Review Edge endpoints: JWT requirement, service/secret key boundary,
  CORS bila relevan, body limit, timeout, idempotency, replay, rate limiting,
  cache headers, dan sanitized errors.
- [ ] Review Supabase Security Advisor, Performance Advisor, SSL enforcement,
  organization MFA, Auth rate limits/CAPTCHA decision, network restrictions,
  backup/restore availability, Storage limits, and spend alerts.
- [ ] Catat SMTP production sebagai intentional skip; jangan menandai seluruh
  production checklist gagal hanya karena email/password memang disabled.

**Gate 13.3:** review diff dan security report tersedia. Agent meminta approval
production eksplisit sebelum melanjutkan.

### Slice 13.4 — Hosted deployment dan recurring operations

- [ ] Setelah approval, link hanya ke hosted `main` yang sudah dikonfirmasi.
- [ ] Bandingkan local/remote migration history lalu push migration secara
  berurutan. Jangan menjalankan `db reset`, seed, atau dashboard schema edit.
- [ ] Jalankan production product provisioning yang idempoten memakai product
  ID final; mapping harus mereferensikan cohort/price band yang benar dan tidak
  memakai prefix `local.`.
- [ ] Deploy setiap Edge Function dari source reviewed:
  - `delete-account`;
  - `cleanup-orphan-question-photos`;
  - `commerce`;
  - `commerce-apple-notifications`;
  - Sign in with Apple account-events endpoint;
  - reconciliation worker bila dipisahkan.
- [ ] Set hosted Edge secrets langsung melalui approved secret mechanism tanpa
  mencetak nilai. Gunakan nama yang benar-benar dibaca source final.
- [ ] Pasang recurring jobs dengan least privilege dan idempotency untuk:
  - provisional identity cleanup;
  - commerce reservation/Coach entitlement expiry;
  - orphan private-photo cleanup;
  - missed App Store event reconciliation.
- [ ] Jangan menjadwalkan endpoint public dengan service key di URL/query.
- [ ] Jalankan hosted migration list, schema diff, DB lint, advisors, grants,
  RLS/Storage/Auth smoke, function health, cron status, dan log-redaction scan.
- [ ] Jalankan rollback/failure drill non-destructive untuk function deploy dan
  forward migration failure.

**Gate 13.4:** hosted smoke lulus, jobs terjadwal dan observable, tidak ada
secret leak, dan Release hanya memakai hosted URL + publishable key.

### Slice 13.5 — App Store Connect products dan Apple server integration

- [ ] Pastikan app record terikat ke bundle ID final; bundle ID tidak diubah
  setelah build diupload.
- [ ] Pastikan agreement, banking, tax, age rating, app category, pricing, dan
  availability sudah valid.
- [ ] Buat/finalkan non-consumable per paid cohort dan tiga non-renewing Coach
  products; product type dan product ID harus sama persis dengan mapping server.
- [ ] Buktikan actual App Store price/currency yang tampil berasal dari StoreKit,
  bukan desired price Admin.
- [ ] Implementasikan App Store Server API recovery/reconciliation memakai
  official Apple server library dan server-only credential. Tangani sandbox,
  production, pagination/history, not-found, retry/backoff, dan rate limit.
- [ ] Konfigurasi App Store Server Notifications V2 HTTPS endpoint untuk
  production dan sandbox bila dipisah.
- [ ] Kirim Request a Test Notification; pastikan response 2xx, signed payload
  terverifikasi, durable inbox hanya satu row, processed status, retry aman,
  dan status test dapat diperiksa.
- [ ] Uji notification out-of-order, duplicate, delayed, invalid signature,
  wrong appAppleId/bundle/product/environment, refund, revoke, dan recovery
  setelah endpoint sempat gagal.
- [ ] Pastikan TestFlight diperlakukan sebagai sandbox commerce environment
  meskipun app memakai hosted backend.
- [ ] Jalankan sandbox purchase, pending/interrupted, relaunch unfinished,
  restore, cross-device restore, refund/revocation, serta renewal Coach sebelum
  dan sesudah expiry.
- [ ] Tunggu propagasi product bila baru dibuat; jangan mengubah logic untuk
  menyiasati status App Store Connect yang belum ready.

**Gate 13.5:** seluruh product dapat dimuat, fulfillment server-authoritative,
TEST notification processed, dan reconciliation memulihkan event yang hilang.

### Slice 13.6 — Privacy, retention, security, dan abuse final

- [ ] Finalkan privacy policy, terms, wellness disclaimer, retention schedule,
  account deletion policy, Coach payment/expiry/no-voluntary-refund terms, dan
  contest rules bila leaderboard memberi hadiah.
- [ ] App Privacy responses harus mencakup data app dan seluruh dependency,
  konsisten dengan privacy manifest serta privacy policy.
- [ ] Jelaskan bahwa Apple bukan sponsor contest bila memang diwajibkan oleh
  mekanisme hadiah/rules final.
- [ ] Verifikasi metadata foto dibuang, object path privat, signed URL minimum,
  cache tidak mengekspos media, dan temporary files dibersihkan.
- [ ] Verifikasi log tidak berisi password, token, service key, raw QR, berat,
  private URL/path, signed Apple payload, atau full purchase credential.
- [ ] Jalankan adversarial matrix: horizontal access, role escalation, forged
  metadata, replay transaction, duplicate fulfillment, forged webhook,
  rate-limit bypass, capacity race, cutoff race, and account-switch bleed.
- [ ] Uji deletion/retention untuk Participant, Coach, Admin restriction,
  winner snapshot, commerce/audit anonymization, serta private relay account.
- [ ] Dokumentasikan security incident, secret rotation, webhook outage,
  compromised tester, and production rollback runbook.

**Gate 13.6:** tidak ada critical/high privacy atau security blocker; seluruh
declaration cocok dengan behavior aktual.

### Slice 13.7 — Accessibility, reliability, performance, dan device matrix

- [ ] VoiceOver order/label/hint/action untuk Auth, QR, media, purchase,
  leaderboard, Coach review, Admin CMS, dan account deletion.
- [ ] Dynamic Type termasuk accessibility sizes tanpa truncation production.
- [ ] Reduce Motion, Reduce Transparency, Increase Contrast, Differentiate
  Without Color, dark mode, light mode, dan Liquid Glass iOS 26 fallback.
- [ ] Keyboard/iPad navigation pada form dan Admin CMS bila praktis.
- [ ] Error association dan retry action harus spesifik, tidak menampilkan raw
  server error.
- [ ] Uji iOS 17 baseline, iOS 26+, iPhone kecil/besar, dan iPad.
- [ ] Uji camera denied/restricted, QR invalid/mismatch/inactive, PhotosPicker,
  upload interruption, resize/metadata stripping, background/foreground.
- [ ] Uji offline/timeout/reconnect, session expiry, Realtime reconnect,
  pagination, empty/error states, transaction interruption, dan relaunch.
- [ ] Profile launch, image-heavy screens, long lists, upload memory, StoreKit
  listener ownership, and Liquid Glass. Perbaiki leak/jank/crash blocker.
- [ ] Uji force-close setelah Google/Apple login dan setelah purchase sebelum
  server fulfillment selesai.

**Gate 13.7:** critical physical-device journeys lulus tanpa crash, data leak,
accessibility blocker, atau unrecoverable transaction.

### Slice 13.8 — TestFlight dan App Review readiness

- [ ] Archive Release dengan production signing dan upload ke App Store Connect.
- [ ] Jalankan automated unit/integration/UI suite terhadap source yang sama
  dengan archive dan catat simulator/device/OS exact.
- [ ] Jalankan internal TestFlight end-to-end matrix di hosted backend.
- [ ] Siapkan review accounts untuk Participant, Coach, dan Admin dengan data
  aman, instruksi role, dan QR Coach aktif.
- [ ] Review notes menjelaskan Google/Apple login, paid/free program, QR Coach,
  Coach approval→payment→activation, manual three-month renewal, no voluntary
  refund, camera/photo purpose, wellness context, dan cara mengakses tiap role.
- [ ] Sediakan IAP review screenshot dan pastikan IAP dikaitkan ke app version
  sesuai status submission App Store Connect.
- [ ] Pastikan privacy/terms/support links hidup tanpa login.
- [ ] Pastikan tidak ada placeholder, dead CTA, demo-only outcome, Debug badge,
  atau dependency pada Mac/local Supabase.
- [ ] Lengkapi export compliance, content rights, age rating, privacy nutrition
  labels, DSA trader status bila berlaku, dan regulated-medical declaration
  yang akurat. App ini tidak boleh mengklaim diagnosis/medical device tanpa
  dasar dan deklarasi yang benar.
- [ ] Jalankan final pre-submission diff dan minta approval user sebelum submit.

**Gate 13.8:** TestFlight RC end-to-end lulus dan metadata/reviewer path siap.
Submission App Store adalah tindakan terpisah yang tetap meminta approval.

## Matriks acceptance TestFlight minimum

### Guest dan Auth

- [ ] Guest membuka seluruh tab publik tanpa Auth identity atau personal data.
- [ ] Guest `Gabung program` menuju Login dan resume program yang benar.
- [ ] Google register/login/logout/relogin/restore/cancel/error/account switch.
- [ ] Apple register/login/logout/relogin/private relay/first-name-only/restore.
- [ ] Google dan Apple identity terpisah walau email tampak sama.
- [ ] Email/password/reset tidak tampil dan dicatat **SKIPPED BY PRODUCT**.

### Participant dan program

- [ ] Profil default mengambil nama provider lalu tetap dapat diedit.
- [ ] QR Coach aktif, invalid, mismatch, inactive, expired Coach entitlement,
  cutoff, capacity full, duplicate enrollment, dan no typed-code fallback.
- [ ] Free program enrollment.
- [ ] Paid program purchase oleh Participant dan oleh Coach sebagai participant.
- [ ] Initial/daily/final weigh-in, typed answers, quiz, photo evidence, retry,
  scoring, leaderboard, winners, dan poster.
- [ ] Weight/private answers/private media tidak bocor ke Guest/leaderboard.

### Coach lifecycle

- [ ] Member ineligible; SC+ memerlukan HOM STS dan ICT attestations.
- [ ] Admin accept sebelum initial Coach purchase.
- [ ] Applicant tetap Participant sampai payment verified dan activation.
- [ ] Coach QR baru aktif setelah authoritative entitlement.
- [ ] Expiry menonaktifkan fitur/QR dan Participant tidak dapat membeli program
  melalui QR Coach yang inactive.
- [ ] Renewal manual sebelum expiry menambah dari expiry lama; setelah expiry
  mulai dari verified payment time; tidak memerlukan re-accept.
- [ ] Apple refund/revocation mencabut akses walau no voluntary refund.
- [ ] Coach monitoring/review dan Admin transfer participant teraudit.

### Admin dan commerce operations

- [ ] Admin CMS create/edit/publish/duplicate/closure/winner lock/poster.
- [ ] Admin manual enrollment melewati cutoff saja, tetap memvalidasi kapasitas,
  lifecycle, Coach aktif, entitlement, dan alasan audit.
- [ ] Product not ready, price mismatch, pending, interrupted, duplicate,
  replay, wrong account/environment/product, restore, and missed notification.
- [ ] Reservation 30 menit dan audited late over-capacity.
- [ ] Notification/refund/reconciliation idempoten serta observable.

### Account deletion dan retention

- [ ] Google reauthentication lalu immediate deletion.
- [ ] Apple reauthentication, Apple token revocation, lalu immediate deletion.
- [ ] Private media/profile/enrollment data hilang; winner/audit/commerce yang
  wajib disimpan sudah dianonimkan.
- [ ] Coach dengan participant aktif diblok sampai transfer Admin.
- [ ] Deleted user tidak dapat dipulihkan hanya dengan stale local session.

## Perintah deployment: aturan, bukan otorisasi

Exact flags harus diverifikasi melalui CLI `--help` pada hari deployment.
Urutan konseptual:

```text
1. Verify authenticated Supabase account and exact hosted project ref.
2. Link to confirmed hosted main only after explicit approval.
3. Compare local and remote migration history.
4. Push reviewed migrations; never push seed/reset production.
5. Deploy reviewed Edge Functions.
6. Set hosted secrets without echoing values.
7. Configure schedules and providers.
8. Run hosted smoke, advisors, logs, and TestFlight acceptance.
```

Jangan menyalin contoh placeholder dari workplan menjadi command nyata tanpa
menyelesaikan target resolution dan approval.

## Exit criteria Phase 13

- [ ] Seluruh Gate 13.0–13.8 lulus atau mempunyai explicit accepted exception.
- [ ] Release archive memakai bundle ID final, iOS 17+, icon/legal/privacy final,
  hosted HTTPS config, dan tidak membawa local/debug/secrets.
- [ ] Hosted migrations/functions/jobs/Auth/security lulus dan terdokumentasi.
- [ ] App Store products, Notification V2, Server API reconciliation, sandbox,
  restore/refund/revocation, dan TestFlight lulus.
- [ ] Google/Apple account lifecycle termasuk Apple token revoke dan account
  event notification lulus.
- [ ] Tidak ada critical/high security, privacy, accessibility, reliability,
  or App Review blocker.
- [ ] Reviewer dapat mengakses semua role dan QR/purchase path.
- [ ] Submission metadata lengkap dan user memberi approval terpisah untuk
  submit ke App Review.
- [ ] Workplan, implementation status, OpenAPI, runbook, dan progress log telah
  direkonsiliasi dengan hasil aktual.

## Referensi resmi yang wajib diverifikasi ulang saat implementasi

### Apple

- In-App Purchase types/configuration dan agreement:
  https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/overview-for-configuring-in-app-purchases
- Create non-consumable:
  https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/create-consumable-or-non-consumable-in-app-purchases
- App Store Server Notifications V2:
  https://developer.apple.com/documentation/AppStoreServerNotifications/enabling-app-store-server-notifications
- App Store Server Notifications changelog:
  https://developer.apple.com/documentation/appstoreservernotifications/app-store-server-notifications-changelog
- App Store Server API:
  https://developer.apple.com/documentation/appstoreserverapi
- TestFlight/Sandbox environment:
  https://developer.apple.com/documentation/appstoreservernotifications/environment
- Privacy manifest dan required-reason APIs:
  https://developer.apple.com/documentation/bundleresources/privacy-manifest-files
  https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
- App Privacy:
  https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy
- In-app account deletion dan Sign in with Apple token revocation:
  https://developer.apple.com/support/offering-account-deletion-in-your-app/
  https://developer.apple.com/documentation/technotes/tn3194-handling-account-deletions-and-revoking-tokens-for-sign-in-with-apple
- Sign in with Apple server-to-server notifications:
  https://developer.apple.com/help/account/capabilities/enabling-server-to-server-notifications/
- App Review Guidelines:
  https://developer.apple.com/app-store/review/guidelines/

### Supabase

- Production checklist:
  https://supabase.com/docs/guides/deployment/going-into-prod
- Database migrations:
  https://supabase.com/docs/guides/deployment/database-migrations
- Edge Function deployment:
  https://supabase.com/docs/guides/functions/deploy
- Edge Function secrets:
  https://supabase.com/docs/guides/functions/secrets
- Edge Function Auth headers:
  https://supabase.com/docs/guides/functions/auth-headers
- Edge Function limits:
  https://supabase.com/docs/guides/functions/limits

## Progress log

### 9 Agustus 2026 — App Icon production dan Icon Composer

- Memasang App Icon final yang disetujui ke `AppIcon.appiconset` dalam varian
  default, dark, dan tinted 1024×1024; ketiganya opaque tanpa alpha.
- Menyimpan source final, preview 180/120/60/40 piksel, layer background,
  orbit, MSC, BODY, TRANSFORMATION, serta artwork monokrom di `Design/AppIcon`.
- Membuat dan membuka ulang dokumen native
  `MSCBodyTransformation-AppIcon.icon` di Icon Composer 1.6. Background tidak
  memakai glass effect; layer artwork tetap menggunakan treatment native.
- Menambahkan generator native AppKit/CoreGraphics yang reproducible tanpa
  dependency pihak ketiga. Asumsi: artwork terpilih adalah master visual dan
  mask sudut tetap menjadi tanggung jawab sistem Apple.
- Build/test command: `swiftc -warnings-as-errors -typecheck
  scripts/generate_app_icon_assets.swift`; lulus tanpa warning.
- Build command: XcodeBuildMCP `build_run_sim` Debug pada iPhone 17 Pro Max
  iOS 26.5; lulus, aplikasi terpasang, dan icon tervalidasi di Home Screen.
- Build command: XcodeBuildMCP `build_sim` Release dengan
  `CODE_SIGNING_ALLOWED=NO`; lulus tanpa error Asset Catalog.
- Remaining blockers Slice 13.1: camera/photo purpose strings, legal content
  dan URL, privacy manifest, required-reason API audit, serta konfigurasi
  Release hosted. Archive/App Store validation tetap dilakukan pada gate
  archive final.

### 8 Agustus 2026 — Audit dan rekonsiliasi Phase 13

- Mengaudit source/bundle setelah Phase 12 dan menemukan App Icon kosong,
  privacy manifest kosong, camera purpose string lama, legal placeholder, serta
  konfigurasi Release yang masih environment-only.
- Menambahkan source-only gates sebelum hosted deployment, sehingga Phase 13
  tidak lagi dianggap sekadar external checklist.
- Memisahkan App Store Server Notifications commerce dari Sign in with Apple
  account-event notifications dan menambahkan Apple token revocation pada
  account deletion.
- Menambahkan App Store Server API recovery, recurring commerce/orphan jobs,
  production product provisioning, hosted security preflight, archive scan,
  serta urutan approval production eksplisit.
- Memperbaiki acceptance matrix: menghapus email reset, menempatkan Admin
  acceptance sebelum initial Coach payment, mempertahankan QR Coach tanpa
  fallback, dan menambah TestFlight sandbox/refund/reconciliation cases.
- Hosted `main`, App Store Connect, TestFlight, dan perangkat fisik tidak
  disentuh. SMTP/domain/email-password tetap skipped.

### 8 Agustus 2026 — Handoff Phase 12 lokal

- Menerima migration commerce, authenticated verify/restore/history Edge
  Function, public Notification V2 handler, StoreKit coordinator, serta
  provider-neutral OpenAPI yang sudah lulus local gate.
- Mencatat App Store Connect products, appAppleId/IAP key/root certificates,
  hosted deployment/secrets, webhook publik, sandbox, TestFlight, dan iPhone
  fisik sebagai external input tanpa merekam secret.

### 4 Agustus 2026 — Guest dan Coach access release matrix

- Menambahkan privacy Guest, escalation resistance, Coach application,
  payment, Admin decision, expiry/renewal/refund, dan reviewer scenarios.
- Menghapus referensi seat-credit/Coach invite yang tidak lagi berlaku.
