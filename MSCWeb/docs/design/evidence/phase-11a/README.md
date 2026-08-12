# Phase 11A rendered PWA evidence

This folder is the stable, privacy-screened rendered-evidence packet used for
local Phase 11A closure on 12 August 2026. The independent reviewer inspected
accepted PNGs at original detail; gallery baselines were updated only after the
reviewer authorized all 19 changed snapshots.

## Evidence map

- `landing/`: 12 default responsive Chromium/WebKit captures at 320, 390, 430,
  768, and 1440 CSS pixels; `landing/install/` adds nine install capability
  states.
- `guest-auth/`: Guest 390 light/dark, Guest 320/root-400%, login ready/error
  light/dark, register, and forgot-password in Chromium/WebKit.
- `participant/`: authenticated active-home 390 light/dark in Chromium/WebKit.
- `coach/`: dashboard light/dark and inline review in Chromium/WebKit.
- `admin/`: dashboard 390 light/dark, dashboard 1440 light, and editor
  forced-colors in Chromium/WebKit.
- `gallery-review/`: temporary audit packet for changed gallery actual/diff
  images. Files prefixed `fresh-`/`final-` are rendered product-component
  reviewer inputs, not authoritative actual-route release evidence or final
  source snapshots.

Final landing preview assets are code-rendered PWA crops at:

- `public/images/landing-participant-v1.jpg`
- `public/images/landing-coach-v1.jpg`
- `public/images/landing-admin-v1.jpg`

They are not iOS screenshots or ImageGen concepts.

## Privacy boundary

The evidence contains deterministic local fixtures and aggregate counts only.
Original-detail review confirmed no token, credential, real email/phone, raw
Coach QR identifier, body weight, transfer evidence, signed/private media URL,
or private evidence photo. Local fixture cleanup returned users/programs/media
objects to zero after role runners.

## Verification summary

- Guest/Auth: 18/18 Chromium/WebKit, retries 0.
- Shared shell: 18/18 Chromium/WebKit, retries 0.
- Peserta: 6/6 Chromium/WebKit, retries 0.
- Coach: 8/8 Chromium/WebKit, retries 0.
- Admin: 16/16 Chromium/WebKit, retries 0.
- Landing capability matrix: 16 pass, 2 intended engine-capability skips.
- Full gallery after reviewed snapshot update: 30/30 Chromium/WebKit.
- Final `scripts/test-phase11-local.sh`: PASS, including 207 unit tests,
  40/40 build pages, browser core 10 pass/2 intended WebKit skips, landing
  snapshot 5/5, and marketing captures 2/2.

The parity ledger deliberately leaves uncaptured state rows `Open`. Accepted
rows are representative and evidence-scoped; functional coverage for the
remaining states comes from the Phase 03–11 local regression, not invented
screenshots.

## Deferred external evidence

Physical installed-PWA checks on iPhone/Safari and Android Chrome are deferred
by owner instruction and are not a blocker for `SELESAI LOKAL`. They remain a
mandatory production-cutover gate and are not represented as passed here.
