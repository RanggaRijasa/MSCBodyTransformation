# MSCWEB W00 — Foundation and feasibility

Status: `Not started`  
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

- [ ] Confirm Node minimum from current Expo SDK documentation and record exact versions.
- [ ] Scaffold into `MSCWEB` without deleting specs, references, or workplans.
- [ ] Enable TypeScript strict and path aliases without leaking framework types into domain.
- [ ] Obtain explicit authorization to modify `package.json`/lockfiles and install the architecturally approved baseline dependencies.
- [ ] After authorization, add approved baseline dependencies only; pin compatible versions and create lockfile.
- [ ] Add scripts for `dev`, `build/export`, `serve`, `lint`, `typecheck`, `test`, and `e2e`.
- [ ] Add `.env.example` with names only; no real values or secrets.

### Web/export feasibility

- [ ] Prove `/`, `/app`, nested routes, refresh, browser Back/Forward, and 404 behavior.
- [ ] Compare Expo `static`/SPA output options and document the selected mode.
- [ ] Serve production output locally with Cloudflare-compatible SPA fallback behavior.
- [ ] Verify public landing code is not coupled to authenticated/admin bundles.

### UI/platform spikes

- [ ] Implement primitive tokens and compact/medium/wide detection.
- [ ] Prove compact bottom navigation and wide rail/sidebar in one shared route model.
- [ ] Implement `MSCIcon` with three semantic mappings and verify unused glyphs are absent from the main bundle.
- [ ] Test reduced motion, dark mode, focus-visible, safe-area values, and 320 px width.

### PWA/icon spikes

- [ ] Generate `192`, `512`, `maskable-192`, `maskable-512`, Apple touch, and favicon derivatives.
- [ ] Validate maskable safe area and confirm no baked rounded corners.
- [ ] Add draft manifest and service-worker strategy with public shell only.

### Risk spikes

- [ ] Configure a local Google OAuth test client/provider and prove callback, exact redirect, PKCE/session handoff, cancelled/error handling, and safe internal return route.
- [ ] Test QR scanning on Safari iOS and Chrome Android physical/emulated-device browser; keep scanner behind an adapter.
- [ ] Test image decode, orientation, resize, metadata stripping, JPEG output, and 8 MiB rejection.
- [ ] Prove private image upload/download and short-lived authorized URL behavior through local Supabase.
- [ ] Record Safari/iOS limitations and fallback states; do not add manual Coach code entry.

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
- Access to Safari iOS and Chrome Android physical/emulated-device camera testing. If unavailable, W00 remains incomplete rather than silently deferring the risk.
- No business/payment input is required.

## Progress log

Append dated entries with files, assumptions, commands/results, sub-agents, risks, and next unchecked item.
