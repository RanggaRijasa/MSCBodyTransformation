# Phase 13.2: Archive, App Store Connect Upload, and TestFlight

> Status: **blocked sampai Phase 13.1 selesai dan owner menyatakan hasil
> exploratory test layak dilanjutkan**.
>
> Archive/upload dan TestFlight adalah mutation App Store Connect. Masing-masing
> hanya dilakukan setelah persetujuan eksplisit pada saat eksekusi.

## Tujuan

- Membuat archive Release dari source yang sama dengan hasil Phase 13.1.
- Memeriksa archive agar tidak membawa secret, local config, fixture, atau
  Debug-only behavior.
- Mengupload build ke App Store Connect.
- Mendistribusikan build kepada internal TestFlight tester.
- Menjalankan validasi TestFlight end-to-end terhadap hosted `main`.
- Berhenti sebelum metadata final dan submission App Review.

## Prasyarat wajib

- [ ] Seluruh exit criteria
  `14A_PHASE_13_1_RELEASE_HARDENING_HOSTED_AND_PHYSICAL_TESTING.md` lulus.
- [ ] Owner sudah menguji aplikasi pada iPhone fisik dan menyetujui lanjut.
- [ ] Working tree/source revision yang akan diarchive sudah diidentifikasi.
- [ ] Hosted `main`, OAuth hosted, StoreKit products, Notification V2, Server
  API reconciliation, sandbox purchase, dan recurring jobs sehat.
- [ ] Version dan build number final untuk candidate ini sudah ditetapkan.
- [ ] Distribution certificate/profile atau automatic signing tersedia.
- [ ] Internal tester dan Sandbox Apple Account tersedia.
- [ ] Persetujuan eksplisit diberikan sebelum upload serta sebelum distribusi.

## Approval boundary

Tindakan berikut terpisah dan tidak boleh diinferensikan dari approval hosted:

1. Membuat archive dengan production signing.
2. Mengupload archive ke App Store Connect.
3. Menambahkan build ke internal TestFlight group.
4. Mengundang/menambahkan tester baru.

Phase 13.2 tidak mengizinkan submission App Review atau public release.

## Urutan implementasi

### Slice 13.2.0 — Freeze release candidate

- [ ] Rekonsiliasi workplan, implementation status, OpenAPI, migration, Edge
  Function, StoreKit products, dan runbook terhadap source aktual.
- [ ] Catat exact Git state tanpa melakukan commit/push kecuali diminta user.
- [ ] Jalankan localization catalog check.
- [ ] Jalankan unit, integration, StoreKit, dan critical UI suite yang relevan.
- [ ] Catat Xcode, SDK, simulator/device, OS, scheme, configuration, dan command.
- [ ] Pastikan tidak ada unreviewed source/config change setelah test.

**Gate 13.2.0:** candidate immutable secara operasional dan test baseline lulus.

### Slice 13.2.1 — Production archive dan bundle inspection

- [ ] Buat Archive Release dengan production signing dan bundle ID final.
- [ ] Validasi archive melalui Xcode Organizer sebelum upload.
- [ ] Inspect exported `.app`/archive:
  - `Info.plist`, version/build, minimum OS, device families, dan orientation;
  - entitlements dan signing/provisioning;
  - App Icon default/dark/tinted;
  - `PrivacyInfo.xcprivacy` dan required-reason declarations;
  - hosted HTTPS URL dan publishable key non-secret;
  - tidak ada localhost/LAN/`.local`, local Supabase key, service-role key,
    OAuth secret, Apple `.p8`, database password, atau signed test payload;
  - tidak ada `Products.storekit`, Debug role/scenario selector, demo fixture,
    placeholder legal, atau dead URL.
- [ ] Jalankan App Store validation dan selesaikan warning/error yang relevan.
- [ ] Simpan checksum/path/log archive secara aman tanpa merekam secret.

**Gate 13.2.1:** archive valid, reproducible, production-only, dan siap upload.

### Slice 13.2.2 — Upload ke App Store Connect

- [ ] Minta persetujuan eksplisit untuk upload candidate yang telah disebutkan
  version/build number-nya.
- [ ] Upload melalui Xcode Organizer atau approved Apple tooling.
- [ ] Tunggu processing selesai; jangan membuat build baru hanya karena
  processing membutuhkan waktu.
- [ ] Periksa processing issue, missing compliance, signing, entitlement,
  privacy manifest, symbol, icon, dan IAP association warning.
- [ ] Pastikan build muncul pada app record/bundle ID yang benar.
- [ ] Jangan memilih `Submit for Review`.

**Gate 13.2.2:** build diproses App Store Connect tanpa blocking error.

### Slice 13.2.3 — Distribusi internal TestFlight

- [ ] Minta persetujuan eksplisit sebelum menambahkan build ke tester group.
- [ ] Lengkapi beta-only compliance minimum yang diperlukan untuk distribusi.
- [ ] Tambahkan build hanya ke internal TestFlight group yang disetujui.
- [ ] Pastikan tester memakai account/data aman, bukan data pribadi nyata.
- [ ] Pastikan build TestFlight memakai hosted `main`, bukan Mac/local backend.
- [ ] Catat bahwa TestFlight StoreKit berjalan pada sandbox commerce meskipun
  backend yang dipakai hosted production.

**Gate 13.2.3:** internal tester dapat menginstal dan membuka build yang benar.

### Slice 13.2.4 — TestFlight validation

- [ ] Fresh install, upgrade dari prior candidate bila ada, launch, background,
  force-close, dan session restore.
- [ ] Guest browsing dan auth gate tidak membuat anonymous/private identity.
- [ ] Google dan Apple login/logout/relogin/cancel/error/account switch.
- [ ] Apple private relay, first-login name-only, dan profile edit.
- [ ] QR Coach active/invalid/mismatch/inactive/expired serta no typed fallback.
- [ ] Free enrollment dan paid purchase Participant/Coach-as-participant.
- [ ] Product load, pending/interrupted, unfinished relaunch, duplicate/replay,
  wrong account/product/environment, restore, dan cross-device restore.
- [ ] Refund/revocation serta missed-notification reconciliation.
- [ ] Coach application, Admin accept, payment, activation, expiry, renewal,
  inactive QR, monitoring, review, dan Admin transfer.
- [ ] Participant weigh-in, content, quiz, photo evidence, score, leaderboard,
  winners, dan poster.
- [ ] Admin CMS create/edit/publish/duplicate/closure/winner lock.
- [ ] Google immediate deletion dan Apple revoke-then-delete.
- [ ] Offline/timeout/reconnect, permission denied, upload interruption,
  Realtime reconnect, session expiry, and recoverable error copy.
- [ ] VoiceOver, Dynamic Type, dark/light, Increase Contrast, Reduce Motion,
  iPhone kecil/besar, dan iPad bila tersedia.
- [ ] Monitor hosted logs, webhook inbox, reconciliation, cron, Storage, Auth,
  security advisor, crash, hang, and redaction selama test.
- [ ] Triage setiap defect; source change mengharuskan build number baru,
  regression suite, archive baru, dan upload approval baru.

**Gate 13.2.4:** TestFlight RC end-to-end lulus tanpa critical/high security,
privacy, commerce, accessibility, reliability, atau data-integrity blocker.

## Hasil yang harus diserahkan ke owner

- Version/build dan tanggal candidate.
- Archive validation result.
- App Store Connect processing result.
- Daftar internal tester/group yang dipakai tanpa password/PII sensitif.
- TestFlight matrix dengan pass/fail, device/OS, defect, dan retest status.
- Hosted health/log summary tanpa token, raw QR, private media, weight, atau
  purchase credential.
- Daftar known issue/accepted exception untuk keputusan lanjut.

## Exit criteria Phase 13.2

- [ ] Archive Release production valid dan telah diupload dengan approval.
- [ ] Build selesai processing dan dapat diinstal melalui internal TestFlight.
- [ ] TestFlight end-to-end hosted matrix lulus.
- [ ] Tidak ada dependency pada Mac, local Supabase, scheme env, atau fixture.
- [ ] Tidak ada critical/high blocker atau ada explicit accepted exception.
- [ ] Owner meninjau hasil TestFlight dan menyetujui lanjut ke Phase 13.3.
- [ ] Build belum disubmit ke App Review.

## Referensi

- TestFlight overview:
  https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview
- Upload builds:
  https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds
- App Store build status:
  https://developer.apple.com/help/app-store-connect/reference/app-build-statuses
- TestFlight/Sandbox environment:
  https://developer.apple.com/documentation/appstoreservernotifications/environment

## Progress log

### 9 Agustus 2026 — Workplan dipisah

- Memisahkan archive, upload, internal TestFlight distribution, dan TestFlight
  validation dari hosted/device work Phase 13.1.
- Menambahkan hard stop agar tidak ada App Review submission dari file ini.
