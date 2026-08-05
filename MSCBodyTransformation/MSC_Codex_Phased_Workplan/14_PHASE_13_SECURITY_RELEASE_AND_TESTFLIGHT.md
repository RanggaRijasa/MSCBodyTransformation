# Phase 13: Security, Privacy, Reliability, and App Store Release

> Status: external release gate. Review memakai commerce program per cohort;
> checklist seat credit dan invite dari baseline lama tidak berlaku.
> Amendment 4 Agustus 2026 memasukkan Guest dan lifecycle Coach access.

## Tujuan

Mengeraskan aplikasi dan backend untuk TestFlight dan App Store submission.

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
- [ ] Invite scan.
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

### 4 Agustus 2026 — Guest dan Coach access release matrix

- Menambahkan privacy Guest, escalation resistance, Coach application,
  payment, Admin decision, expiry/renewal/refund, dan reviewer scenarios.
- Menghapus referensi seat-credit/Coach invite yang tidak lagi berlaku.
