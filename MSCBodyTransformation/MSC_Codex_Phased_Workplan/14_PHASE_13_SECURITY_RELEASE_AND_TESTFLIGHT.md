# Phase 13: Security, Privacy, Reliability, and App Store Release

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
- [ ] Review explanation for seat-credit model.
- [ ] Camera/photo explanation.
- [ ] Wellness purpose explanation.
- [ ] No placeholder screen or dead link.
- [ ] Contest rules supplied when applicable.

## TestFlight matrix

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
- [ ] Coach purchase.
- [ ] Coach invite.
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
- [ ] TestFlight end-to-end passes.
- [ ] App submission metadata ready.

## Progress log

### Log
