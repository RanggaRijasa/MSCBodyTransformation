# Phase 13: Security, Privacy, Reliability, and App Store Release

> Status: external release gate. Review memakai commerce program per cohort;
> checklist seat credit dan invite dari baseline lama tidak berlaku.
> Amendment 4 Agustus 2026 memasukkan Guest dan lifecycle Coach access.
> Phase 12 local gate lulus 8 Agustus 2026; hosted `main` dan App Store
> Connect belum disentuh.

## Tujuan

Mengeraskan aplikasi dan backend untuk TestFlight dan App Store submission.

## Input manual yang harus disiapkan pengguna

Jangan menaruh nilai rahasia di chat, source, Xcode scheme, `.env` committed,
fixture, screenshot, atau log. Nilai rahasia dimasukkan langsung sebagai
hosted Supabase Edge Function secrets ketika deployment Phase 13 disetujui.

### App Store Connect

- [ ] Pastikan app memakai final bundle ID
  `com.ranggar.MSCBodyTransformation` dan catat numeric `appAppleId`.
- [ ] Buat satu **non-consumable** unik untuk setiap cohort program berbayar.
  Product ID production tidak boleh memakai prefix local; contoh pola:
  `com.ranggar.msc.program.<cohort-stabil>`.
- [ ] Buat tiga **non-renewing subscription** akses Coach tiga bulan:
  entry Rp100.000, growth Rp150.000, leadership Rp200.000. Product ID harus
  stabil dan berbeda dari `local.msc.coach.*`.
- [ ] Lengkapi nama/deskripsi Bahasa Indonesia, harga, availability, review
  screenshot, tax category, dan status submission setiap produk.
- [ ] Buat In-App Purchase key dan simpan aman: Issuer ID, Key ID, serta file
  private `.p8`. Private key hanya untuk backend.
- [ ] Siapkan Sandbox Apple Account dan akses App Store Connect yang dapat
  mengirim Request a Test Notification.

### Hosted Supabase

- [ ] Catat project ref hosted `main`, hosted URL, publishable key, dan
  service-role key. Hanya URL + publishable key boleh masuk konfigurasi
  Release app; service-role tetap server-only.
- [ ] Siapkan Edge secrets: `COMMERCE_APPLE_ENVIRONMENT=production`,
  `APPLE_APP_ID`, `APPLE_ROOT_CERTIFICATES_BASE64`, dan credential App Store
  Server API/IAP key yang akan dipakai reconciliation server. Nama secret
  final harus direkonsiliasi dengan source sebelum deployment.
- [ ] Siapkan public Notification V2 URL:
  `https://<PROJECT_REF>.supabase.co/functions/v1/commerce-apple-notifications`.
- [ ] Siapkan production product mapping per program/cohort dan tiga price
  band Coach; desired price Admin bukan pengganti harga App Store.
- [ ] Konfirmasi hosted Google/Apple Auth provider tetap aktif. SMTP/domain dan
  email/password production tetap **SKIPPED**.

### Perangkat dan distribusi

- [ ] Sediakan iPhone fisik yang memenuhi minimum iOS 17, Apple ID sandbox,
  signing team/certificate, dan TestFlight internal tester.
- [ ] Siapkan QR Coach aktif untuk enrollment Participant dan reviewer; tidak
  ada invite code atau fallback kode manual.

## Urutan deployment yang membutuhkan persetujuan eksplisit

1. Review migration, Edge Function, `config.toml`, OpenAPI, dan product mapping
   diff; pastikan target adalah hosted `main`.
2. Minta persetujuan production eksplisit sebelum `supabase db push`, function
   deploy, secret set, atau perubahan hosted apa pun.
3. Deploy migration lalu Edge Functions; set secret langsung pada hosted
   backend tanpa mencetak nilainya.
4. Jalankan hosted lint/advisors/grants/RLS smoke dan verifikasi Release hanya
   berisi hosted URL + publishable key.
5. Masukkan Notification V2 URL di App Store Connect dan jalankan TEST
   notification sampai durable inbox berstatus processed.
6. Jalankan sandbox purchase/restore/pending/relaunch/refund/revocation untuk
   program dan Coach, termasuk renewal sebelum/sesudah expiry.
7. Jalankan matriks iPhone fisik, TestFlight, privacy, accessibility, dan
   reviewer accounts sebelum App Store submission.

Tidak satu pun langkah hosted di atas diotorisasi hanya karena Phase 12 lokal
selesai. Setiap mutation production tetap memerlukan persetujuan eksplisit.

## Security audit

- [ ] Full RLS matrix.
- [ ] Storage access matrix.
- [ ] Database advisors.
- [ ] No service-role key in client or repository.
- [ ] No OAuth client secret in client.
- [ ] No App Store private key in client.
- [ ] Redirect allowlist minimal.
- [ ] Role authorization server-controlled.
- [ ] Private evidence URLs expire or require authorization.
- [ ] Security-definer functions reviewed.
- [ ] Audit records for privileged action.
- [ ] Rate limiting or abuse controls where needed.
- [ ] Logs contain no weight, token, password, or private URL.
- [ ] Guest/anon hanya dapat membaca public-safe projection.
- [ ] Guest tidak membuat anonymous Auth account.
- [ ] Member level/application metadata tidak dapat menaikkan role.
- [ ] Applicant tidak dapat menulis payment verified, approval, role, QR,
  atau entitlement.
- [ ] Coach operation memerlukan approved role dan active entitlement.
- [ ] Application approve/reject dan payment reconciliation teraudit.

## Privacy

Weight and evidence photos are sensitive.

- [ ] Privacy policy.
- [ ] Terms.
- [ ] Wellness disclaimer.
- [ ] Data minimization.
- [ ] Retention policy.
- [ ] Account deletion.
- [ ] Media metadata stripping.
- [ ] Camera/photo purpose strings.
- [ ] App Privacy responses.
- [ ] Privacy manifest.
- [ ] No advertising use of health-related data.
- [ ] Contest rules when leaderboard has prizes.
- [ ] State that Apple is not contest sponsor where required.
- [ ] Coach terms version, rejection/refund policy, expiry, dan manual renewal
  dijelaskan.
- [ ] Nomor HP applicant tidak muncul pada public/Guest surface.

## Accessibility final audit

- [ ] VoiceOver.
- [ ] Dynamic Type.
- [ ] Reduce Motion.
- [ ] Reduce Transparency.
- [ ] Increase Contrast.
- [ ] Differentiate Without Color.
- [ ] Keyboard navigation iPad where practical.
- [ ] Error association.
- [ ] Purchase flow accessibility.
- [ ] OAuth web session accessibility sanity.

## Reliability

- [ ] Session expiry recovery.
- [ ] Upload interruption.
- [ ] Transaction interruption.
- [ ] Realtime reconnect.
- [ ] Pagination.
- [ ] Empty states.
- [ ] Offline states.
- [ ] Background/foreground.
- [ ] Memory profiling.
- [ ] Image-heavy screen profiling.
- [ ] Liquid Glass profiling iOS 26.
- [ ] Crash-free critical flows.

## App Store requirements

- [ ] Final bundle identifier.
- [ ] Signing.
- [ ] App icons.
- [ ] Launch experience.
- [ ] Privacy and terms links.
- [ ] Google login plus Sign in with Apple unless valid exemption.
- [ ] IAP products submitted.
- [ ] App Store Server Notifications endpoints.
- [ ] Demo participant account.
- [ ] Demo coach account.
- [ ] Demo admin account.
- [ ] Review sample QR.
- [ ] Review explanation untuk program payment dan manual Coach access tiga
  bulan.
- [ ] Camera/photo explanation.
- [ ] Wellness purpose explanation.
- [ ] No placeholder screen or dead link.
- [ ] Contest rules supplied when applicable.

## TestFlight matrix

- [ ] Guest membuka seluruh tab publik tanpa personal-data leakage.
- [ ] Guest `Gabung program` membuka Login dan resume destination benar.
- [ ] Participant registration.
- [ ] Google login.
- [ ] Apple login.
- [ ] Email reset.
- [ ] QR Coach scan dan enrollment tanpa fallback kode manual.
- [ ] Initial weigh-in.
- [ ] Evidence upload.
- [ ] Step completion.
- [ ] Final weigh-in.
- [ ] Leaderboard.
- [ ] Coach application Member ineligible.
- [ ] Coach application SC+ memerlukan HOM STS dan ICT.
- [ ] Coach purchase manual tiga bulan.
- [ ] Coach tetap Participant saat menunggu Admin.
- [ ] Admin approval/rejection dan reason.
- [ ] Coach expiry, renewal, restore, refund/revocation.
- [ ] Coach QR baru tersedia setelah activation authoritative.
- [ ] Coach review.
- [ ] Admin CMS.
- [ ] Manual enrollment.
- [ ] Account deletion.
- [ ] Refund/reconciliation.

## Exit criteria

- [ ] Release candidate passes physical-device critical flows.
- [ ] No critical security or accessibility blocker.
- [ ] Reviewer can access all roles.
- [ ] IAP review path documented.
- [ ] Reviewer dapat membedakan fake Debug preview dari flow production.
- [ ] TestFlight end-to-end passes.
- [ ] App submission metadata ready.

## Progress log

### 8 Agustus 2026 — Exact handoff dari Phase 12

- Menerima migration commerce, authenticated verify/restore/history Edge
  Function, public Notification V2 handler, StoreKit coordinator, serta
  provider-neutral OpenAPI yang sudah lulus local gate.
- Mencatat App Store Connect products, appAppleId/IAP key/root certificates,
  hosted deployment/secrets, webhook publik, sandbox, TestFlight, dan iPhone
  fisik sebagai external input. Tidak ada nilai secret yang direkam.
- SMTP/domain dan email/password production tetap skipped; Google/Apple Auth
  tetap diperlukan pada hosted Release.

### 4 Agustus 2026 — Guest dan Coach access release matrix

- Menambahkan privacy Guest, escalation resistance, Coach application,
  payment, Admin decision, expiry/renewal/refund, dan reviewer scenarios.
- Menghapus referensi seat-credit/Coach invite yang tidak lagi berlaku.
