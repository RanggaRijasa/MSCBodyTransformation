# Phase 11A iOS reference capture

This folder contains read-only Simulator captures from the existing iOS app.
The canonical machine-readable record is `manifest.json`.

## Outcome

- Primary reference: iPhone 17, iOS 26.5, 402 x 874 points, 3x scale.
- Fallback comparator: iPhone 16, iOS 18.6, 393 x 852 points, 3x scale.
- App mode: `MSC_APP_MODE=local_demo`.
- Locale: Indonesian (`-AppleLanguages (id) -AppleLocale id_ID`).
- Representative iOS 26 light/dark pairs: Guest, Auth login, Peserta active,
  Coach review queue dashboard, and Admin winner-lock dashboard.
- iOS 18 light/dark fallback pair: Guest home.
- All 12 PNGs were visually inspected after appearance verification and passed
  the privacy screen described in the manifest.

The exact 390 x 844 iOS 26 simulator requested by the acceptance guidance was
not installed. The 402 x 874 iOS 26 device is therefore the Liquid Glass
baseline, while the installed 393 x 852 iOS 18 device provides the closest
viewport and native fallback comparison.

The orchestrator/PM and independent reviewer accepted this packet on 2026-08-11
as the representative iOS constraint for Phase 11A production work. It does not
replace the complete rendered-PWA acceptance matrix.

## Reproduction recipe

1. Build and launch the existing `MSCBodyTransformation` Debug scheme on the
   simulator recorded in `manifest.json`.
2. Set `MSC_APP_MODE=local_demo` in the launched process environment.
3. Pass the shared locale arguments, `-DemoRole`, `-DemoScenario`, and
   `-SkipDemoLanding` exactly as recorded per artifact.
4. Verify the expected accessibility identifier before capture.
5. Set and query the Simulator appearance, wait for the UI to settle, then run
   `xcrun simctl io <UDID> screenshot --type=png <path>`.
6. Do not crop, retouch, or use production credentials/data.

## Coverage boundary

This bounded packet satisfies the representative actor/light/dark handoff.
It does not claim the complete visual acceptance matrix. The un-captured Auth,
role-detail, error/offline, accessibility, and lifecycle states are enumerated
under `coverage.notCapturedInThisBoundedPacket` in the manifest. PM/owner
accepted the exception to cover those states in the deterministic
Chromium/WebKit PWA matrix while using this packet for iOS hierarchy,
appearance, and role parity.

No iOS source, Xcode project, scheme, signing setting, asset, fixture, backend,
or file outside this folder was changed.
