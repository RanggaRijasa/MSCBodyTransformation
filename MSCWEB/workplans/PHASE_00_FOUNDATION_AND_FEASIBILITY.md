# MSCWEB W00 — Foundation and feasibility

Status: `Complete`
Autonomy: `A` after one-time dependency-install authorization; package-network/device/OAuth setup may also require user action  
Depends on: approved specs and ADR-0001/0002/0003

## Objective

Create an independently buildable Expo/React Native Web project inside `MSCWEB` and prove the platform risks before feature implementation. This phase must not deploy externally or modify iOS source.

## Required references

- `README.md`
- `01_ARCHITECTURE.md`
- `03_DESIGN_SYSTEM.md`
- `06_PWA_HOSTING.md`
- `07_TESTING_ACCEPTANCE.md`
- `decisions/0001-web-platform-and-styling.md`
- `decisions/0002-icons-and-pwa-icon.md`

## Deliverables

- strict TypeScript Expo project and lockfile;
- local development/build/test scripts;
- dependency/version compatibility record;
- proven Expo Router web export and Cloudflare Static Assets shape;
- minimal static landing route plus authenticated-app shell route;
- design token and responsive-navigation spike;
- Phosphor SVG wrapper/tree-shaking spike;
- PWA icon derivatives from approved iOS source;
- QR camera and image-normalization feasibility adapters/tests;
- local Google OAuth callback/redirect feasibility spike;
- local/private Supabase signed-media feasibility note or spike;
- accepted ADRs for any choice not already locked.

## Checklist

### Repository and toolchain

- [x] Confirm Node minimum from current Expo SDK documentation and record exact versions.
- [x] Scaffold into `MSCWEB` without deleting specs, references, or workplans.
- [x] Enable TypeScript strict and path aliases without leaking framework types into domain.
- [x] Obtain explicit authorization to modify `package.json`/lockfiles and install the architecturally approved baseline dependencies.
- [x] After authorization, add approved baseline dependencies only; pin compatible versions and create lockfile.
- [x] Add scripts for `dev`, `build/export`, `serve`, `lint`, `typecheck`, `test`, and `e2e`.
- [x] Add `.env.example` with names only; no real values or secrets.

### Web/export feasibility

- [x] Prove `/`, `/app`, nested routes, refresh, browser Back/Forward, and 404 behavior.
- [x] Compare Expo `static`/SPA output options and document the selected mode.
- [x] Serve production output locally with Cloudflare-compatible SPA fallback behavior.
- [x] Verify public landing code is not coupled to authenticated/admin bundles.

### UI/platform spikes

- [x] Implement primitive tokens and compact/medium/wide detection.
- [x] Prove compact bottom navigation and wide rail/sidebar in one shared route model.
- [x] Implement `MSCIcon` with three semantic mappings and verify unused glyphs are absent from the main bundle.
- [x] Test reduced motion, dark mode, focus-visible, safe-area values, and 320 px width.

### PWA/icon spikes

- [x] Generate `192`, `512`, `maskable-192`, `maskable-512`, Apple touch, and favicon derivatives.
- [x] Validate maskable safe area and confirm no baked rounded corners.
- [x] Add draft manifest and service-worker strategy with public shell only.

### Risk spikes

- [x] Configure a local Google OAuth test client/provider and prove callback, exact redirect, PKCE/session handoff, cancelled/error handling, and safe internal return route.
- [x] Test QR scanning on Safari iOS and Chrome Android physical/emulated-device browser; keep scanner behind an adapter.
- [x] Test image decode, orientation, resize, metadata stripping, JPEG output, and 8 MiB rejection.
- [x] Prove private image upload/download and short-lived authorized URL behavior through local Supabase.
- [x] Record Safari/iOS limitations and fallback states; do not add manual Coach code entry.

## Sub-agent plan

- `msc_explorer`: map Expo/Cloudflare current official constraints and existing Supabase/media contracts; read-only.
- `msc_implementer`: own the scaffold and feasibility code after versions are settled; sole writer.
- `msc_reviewer`: verify dependency scope, build output, browser routing, secret absence, and spike conclusions.

The primary agent owns `package.json`, lockfile, route root, config, and ADR integration.

## Verification

Exact commands are finalized after scaffold. Minimum evidence:

```text
npm run typecheck
npm run lint
npm test
npm run build
npm run serve
npm run e2e -- feasibility
```

Also inspect output for service-role keys, secrets, unused full icon packs, and private data.

## Exit criteria

- Project installs/builds/tests/serves from `MSCWEB` alone.
- Refresh/deep link/browser history work on local production output.
- Rendering/export, QR adapter, image pipeline, versions, and icon strategy are documented.
- Local OAuth callback and private signed-media behavior are proven, not deferred.
- Safari iOS and Chrome Android QR behavior is proven on the target device/browser categories.
- No source import from Swift/iOS runtime paths.
- No production service was mutated.
- A failure in rendering/export, OAuth callback, QR, image normalization, or private signed media blocks W00 until resolved or the user explicitly changes scope.

## User input or authorization

- One explicit authorization to modify package manifests/lockfile and install the approved baseline, plus network approval if the environment prompts.
- Local Google OAuth client/provider values and redirect registration.
- Access to Safari iOS and Chrome Android emulated-device camera testing. If unavailable, W00 remains incomplete rather than silently deferring the risk.
- No business/payment input is required.

## Progress log

Append dated entries with files, assumptions, commands/results, sub-agents, risks, and next unchecked item.

### 12 August 2026 — baseline, export, adapters, and target-gate evidence

- Requirement IDs: `ARCH-001`, `ARCH-004`, `ARCH-007`, `ARCH-009`, `ARCH-010`, `ARCH-AUTH-001`, `ARCH-AUTH-002`, `ARCH-AUTH-004`, `ARCH-ERR-001…003`, `ARCH-NAV-002`, `ARCH-WEB-001…004`; `DS-001…004`, `DS-TKN-001…003`, `DS-ICO-001…007`, `DS-APPICON-001…003`; `UX-NAV-001…003`, `UX-RSP-001`, `UX-RSP-002`, `UX-RSP-005`, `UX-GST-002`, `UX-GST-005`; `PWA-HST-001`, `PWA-HST-003`, `PWA-MAN-001`, `PWA-MAN-002`, `PWA-OFF-001`, `PWA-OFF-002`, `PWA-OFF-004`, `PWA-LND-001`, `PWA-PERF-002`, `PWA-PERF-003`; `SEC-STO-001…004`, `SEC-PRV-001`; `QA-001…003`. `PWA-HST-004` and `PWA-HST-005` are only partially exercised here and remain assigned to their hosting/configuration phase.
- Files: scaffold/config/package lock; route shell and feasibility page; design, icon, QR, image, OAuth, and private-media adapters; unit/E2E tests; PWA assets/scripts; Worker routing; ADR-0004; `feasibility/W00_FEASIBILITY_REPORT.md`; local web callback allowlist in root `supabase/config.toml`.
- Assumptions: local Supabase only; no hosted deployment; `web.output: single` plus deterministic static landing split; Node 22.23.2 baseline; no manual Coach-code fallback.
- Commands/results: Expo compatibility check passed; `npm run typecheck`, `npm run lint`, and `npm test` passed (36 tests; local-only integration skipped without env); focused browser-adapter local Storage integration passed; export and bundle/PWA verification passed; 14 Playwright production-output checks passed; existing local private-media integration passed 16 assertions; XcodeBuildMCP `build_run_sim` passed for scheme `MSCBodyTransformation`, Debug, iPhone 17 Pro/iOS 26.4, launch args `-DemoRole participant -DemoScenario participant_active -SkipDemoLanding`.
- Sub-agents: `msc_explorer` mapped official Expo/Cloudflare/Supabase constraints; `msc_implementer` owned the risk adapters and 27 focused tests. Primary integrated scaffold, routes, hosting, UI, PWA, browser/device evidence, and documentation.
- Risks/blockers: local Google OAuth plus Chrome Android and physical Safari iPhone QR scanning are proven. Supabase does not enforce the adapter's 60-second signed-URL request as a server ceiling; the limitation and later hardening path are recorded. The reviewed Expo transitive dependency audit is recorded in the feasibility report.
- Next unchecked item: none in W00; proceed to W01.

### 12 August 2026 — Chrome Android camera acceptance

- Requirement IDs: partial evidence for `ARCH-AUTH-001`, `ARCH-AUTH-002`, `ARCH-AUTH-004`; Chrome Android evidence for the W00 QR target gate.
- Files: `feasibility/W00_FEASIBILITY_REPORT.md`; this progress entry. No production source, package, lockfile, migration, or secret file changed.
- Assumptions at this entry: the deterministic QR payload is a non-production test value; Safari physical-device testing was still pending and was subsequently resolved by the acceptance entry below.
- Commands/results: local Supabase and production output started; Android `adb reverse` established for ports `4173` and `54321`; Pixel 8 API 36/37 emulator launched with a fixed-image back camera; Chrome camera origin/app permissions accepted under the user's test authorization; the scanner decoded the QR and rendered `QR terdeteksi` without displaying the payload. Google PKCE reached the signed-in account chooser and final `Lanjutkan` screen.
- Remaining blocker at this entry: Safari QR scan required a physical iPhone; subsequently resolved.
- Next unchecked item at this entry: run the physical Safari QR test.

### 12 August 2026 — local Google OAuth acceptance

- Requirement IDs: `ARCH-AUTH-001`, `ARCH-AUTH-002`, `ARCH-AUTH-004`, `ARCH-ERR-001…003`; W00 local OAuth target gate.
- Files: this workplan and `feasibility/W00_FEASIBILITY_REPORT.md`. No production source, package, lockfile, migration, or secret file changed.
- Assumptions: local Supabase only; the signed-in Google account is test evidence, not a production account provisioning decision; no token, browser storage, email, or user identifier was inspected or recorded.
- Commands/results: after the initial consent attempt expired while awaiting user action, a fresh Chrome Android flow requested `/auth/v1/authorize`, returned through the exact `http://127.0.0.1:4173/auth/callback`, exchanged the PKCE code through local `/auth/v1/token`, and navigated to the sanitized `/app/feasibility` return route. Read-only aggregate local Postgres checks confirmed one Google identity and a newly created Auth session at the acceptance time.
- Remaining blocker at this entry: actual QR scanning in physical Safari on iPhone; subsequently resolved by the physical-device acceptance entry below.
- Next unchecked item at this entry: run the physical Safari QR test.

### 12 August 2026 — physical Safari QR acceptance and W00 completion

- Requirement IDs: W00 Safari/iOS target gate; `UX-GST-002`, `UX-GST-005`, and QR feasibility portions of `QA-001…003`.
- Files: this workplan and `feasibility/W00_FEASIBILITY_REPORT.md`. User-supplied evidence remains outside the repository at `/Users/ranggarijasa/Downloads/ScreenRecording_08-12-2026 16-59-59_1.MP4`.
- Assumptions: a temporary random `trycloudflare.com` Quick Tunnel supplied the trusted HTTPS origin required by physical Safari; it was not a Cloudflare project deployment, DNS change, or production endpoint and was closed immediately after verification.
- Commands/results: Apple `devicectl` confirmed a paired physical iPhone 17 (`iPhone18,3`) on iOS 26.6. Safari opened the W00 production output over temporary HTTPS, received real camera input, decoded the deterministic test QR, and rendered `QR terdeteksi. Payload diteruskan ke boundary validasi tanpa ditampilkan.` The supplied 1206 × 2622 HEVC screen recording visually confirms the live camera frame, success state, close action, compact navigation, and absence of a manual-code field or displayed payload.
- Result: W00 exit criteria are satisfied. Google OAuth, Android Chrome QR, physical Safari QR, image normalization, export/hosting, icons/PWA, and local private-media feasibility are proven; no production service was mutated.
- Remaining blockers: none for W00.
- Next unchecked item: start W01 and complete its repository-split decision before W02 begins.
